import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note_type.dart';
import '../../settings/settings_providers.dart';
import '../data/ai_cache.dart';
import '../data/ai_speech.dart';
import '../data/gemini_service.dart';

/// Bir belgeyi sesli dinleme ekranı. Üç mod var:
///
/// - **Belgeyi oku**: metin çıkarılır ve cihaz sesiyle okunur. Bedava,
///   çevrimdışı, anında.
/// - **Tam podcast**: metin Gemini'ye verilip akıcı bir anlatıya çevrilir.
///   Bir model çağrısı harcar ama dinlenebilirliği asıl bu sağlar — ham belge
///   metni sesli okunduğunda tablo kırıntıları ve dipnotlar da okunur.
/// - **Özet podcast**: aynı çağrı, "kısalt" talimatıyla.
///
/// Seslendirmeyi kim yapacağı ayrı bir tercihtir: cihazın yerleşik TTS'i
/// (bedava, çevrimdışı) ya da **AI ile dinle** — Gemini'nin seslendirme
/// modeli (belirgin daha doğal, her paragraf bir model çağrısı). Varsayılan
/// Ayarlar'dan gelir; bu ekrandaki anahtar o okumaya özel değiştirir.
///
/// Ekran metnin nereden geldiğini bilmez; [loadText] ne verirse onu okur.
/// PDF, Word, PowerPoint ve düz metin aynı ekranı kullanıyor.
class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({
    super.key,
    required this.title,
    required this.loadText,
    this.allowCache = true,
  });

  final String title;
  final Future<String> Function() loadText;

  /// KİLİTLİ nottan açılan belgede false: üretilen podcast metni düz metin
  /// dosyası olarak diske yazılır, kilitli içerik önbellekten okunabilirdi.
  final bool allowCache;

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  String? _text;
  String? _original;
  String? _error;
  bool _busy = true;
  bool _generating = false;
  bool _isPodcast = false;

  /// Ses dosyasi URETILIYOR mu (disa aktarma) ve kacinci parcada.
  bool _rendering = false;
  int _renderDone = 0;
  int _renderTotal = 0;

  /// Gosterilen metin onbellekten mi geldi (yeniden uret secenegi icin).
  bool _fromCache = false;
  bool _lastSummarize = false;

  /// Bu okumada YAPAY ZEKÂ sesi kullanılsın mı?
  ///
  /// Karar TEK yerden gelir: Ayarlar → Ses → Seslendirme (kullanıcı isteği
  /// 2026-08-08: "1 özellik 1 ayara bağlanmalı, çok ayar karışıklık
  /// yapıyor"). Bu ekranda ayrıca bir anahtar VARDI; ayarda yapay zekâ
  /// seçiliyken bile burada kapalı kalabiliyor ve okuma sessizce cihaz
  /// sesiyle yapılıyordu ("AI seçince çalışmıyor, hâlâ android sesiyle
  /// okuyor"). Anahtar kaldırıldı.
  ///
  /// Yapay zekâ sesi kullanıcının KENDİ Gemini anahtarını ister; yoksa
  /// okuma cihaz sesiyle yapılır ve sebebi ekranda YAZAR.
  bool? _aiVoice;

  bool get _aiAvailable => ref.read(aiSpeechProvider.notifier).isAvailable;

  bool get _useAiVoice =>
      _aiAvailable &&
      (_aiVoice ?? (ref.read(ttsEngineProvider) == TtsEngine.gemini));

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  /// dispose'da `ref` kullanılamaz (Riverpod "widget unmounted" hatası atar ve
  /// okuma DURMAZ); denetleyiciler build'de alana alınır.
  SpeechOutputController? _speech;
  AiSpeechController? _aiSpeech;

  @override
  void dispose() {
    // Ekrandan çıkınca okuma sürmesin (hangisi konuşuyorsa o dursun).
    _speech?.stop();
    _aiSpeech?.stop();
    super.dispose();
  }

  /// Oynat/duraklat/devam düğmesi. Yapay zekâ sesinde model çağrısı
  /// başarısız olursa (kota, anahtar, ağ) hata gösterilir ve okuma CİHAZ
  /// sesiyle sürer — sessizce hiçbir şey olmaması en kötü sonuç olurdu.
  Future<void> _togglePlay(SpeechOutputState speech, String text) async {
    final aiVoice = _useAiVoice;
    final device = ref.read(speechOutputProvider.notifier);
    final ai = ref.read(aiSpeechProvider.notifier);
    if (speech.state == SpeechState.speaking) {
      await (aiVoice ? ai.pause() : device.pause());
      return;
    }
    if (speech.state == SpeechState.paused) {
      await (aiVoice ? ai.resume() : device.resume());
      return;
    }
    if (!aiVoice) {
      await device.speak(text);
      return;
    }
    try {
      await ai.speak(text);
    } catch (e) {
      if (!mounted) return;
      final message = e is GeminiException ? e.message : '$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.listenAiVoiceFailed(message))),
      );
      setState(() => _aiVoice = false);
      await device.speak(text);
    }
  }

  Future<void> _loadDocument() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await widget.loadText();
      if (!mounted) return;
      if (text.trim().length < 40) {
        // Taranmış PDF ya da yalnız görsel içeren sunum: okunacak metin yok.
        // OCR ayrı bir iş; sessizce boş ekran göstermektense sebebini söyle.
        setState(() {
          _error = context.l10n.listenNoText;
          _busy = false;
        });
        return;
      }
      setState(() {
        _text = text;
        _original = text;
        _isPodcast = false;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.aiError(e.toString());
        _busy = false;
      });
    }
  }

  /// [force] true ise önbellek atlanır ve yeni metin üretilir.
  Future<void> _makePodcast({
    required bool summarize,
    bool force = false,
  }) async {
    final source = _original;
    if (source == null) return;
    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(aiSpeechProvider.notifier).stop();

    // Aynı belgeyi ikinci kez açmak binlerce token'a mal olmasın: üretilen
    // metin içerik özetine göre saklanıyor, belge değişirse anahtar da değişir.
    final key = AiCache.keyFor(
      summarize ? 'podcast_summary' : 'podcast_full',
      source,
    );
    if (!force && widget.allowCache) {
      final cached = await AiCache.read(key);
      if (cached != null && cached.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _text = cached;
          _isPodcast = true;
          _fromCache = true;
          _lastSummarize = summarize;
        });
        return;
      }
    }

    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final script = await ref
          .read(geminiServiceProvider)
          .podcastScript(source, title: widget.title, summarize: summarize);
      if (widget.allowCache) await AiCache.write(key, script);
      if (!mounted) return;
      setState(() {
        _text = script;
        _isPodcast = true;
        _fromCache = false;
        _lastSummarize = summarize;
        _generating = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _generating = false;
      });
    } catch (e) {
      // HER hata yakalanır (yalnız GeminiException değil): güvenli depo,
      // dosya sistemi ya da eklenti kaynaklı bir istisnada `_generating`
      // true kalıyor ve ekran sonsuza dek dönen çarkta takılıyordu.
      if (!mounted) return;
      setState(() {
        _error = context.l10n.aiError('$e');
        _generating = false;
      });
    }
  }

  /// Podcast SESİNİ tek bir WAV dosyasına döker ve paylaşım levhasını açar.
  ///
  /// Ses üretimi kotadan düşüyor ve dinlerken üretilen parçalar okuma bitince
  /// siliniyor — bu yüzden dışa aktarma metni BAŞTAN seslendirir ve maliyeti
  /// önce kullanıcıya sorar.
  Future<void> _exportAudio() async {
    final text = _text;
    if (text == null || text.trim().isEmpty) return;
    final l10n = context.l10n;
    if (!ref.read(aiSpeechProvider.notifier).isAvailable) {
      _snack(l10n.ttsEngineAiUnavailable);
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.podcastExportAudio),
        content: Text(l10n.podcastExportAudioCost),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.podcastExportAudio),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(aiSpeechProvider.notifier).stop();
    setState(() {
      _rendering = true;
      _renderDone = 0;
      _renderTotal = 0;
    });
    try {
      final path = await ref
          .read(aiSpeechProvider.notifier)
          .renderToFile(
            text,
            fileName: widget.title,
            onProgress: (done, total) {
              if (!mounted) return;
              setState(() {
                _renderDone = done;
                _renderTotal = total;
              });
            },
          );
      if (!mounted) return;
      setState(() => _rendering = false);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: widget.title),
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _rendering = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _rendering = false);
      _snack(context.l10n.aiError('$e'));
    }
  }

  /// Podcast METNİNİ paylaşır (ses değil — kota harcamaz).
  Future<void> _shareText() async {
    final text = _text;
    if (text == null || text.trim().isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(text: text, subject: widget.title),
    );
  }

  /// Podcast metnini YENİ NOT olarak kaydeder ve o notu açar.
  Future<void> _saveAsNote() async {
    final text = _text;
    if (text == null || text.trim().isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    try {
      final id = await repo.createNote(NoteType.text, body: text);
      repo.updateFields(id, {'title': widget.title});
      if (!mounted) return;
      _snack(context.l10n.podcastSavedAsNote);
      context.push(noteRoutePath(id));
    } catch (e) {
      if (!mounted) return;
      _snack(context.l10n.aiError('$e'));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showOriginal() async {
    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(aiSpeechProvider.notifier).stop();
    if (!mounted) return;
    setState(() {
      _text = _original;
      _isPodcast = false;
      _fromCache = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Hangi ses konuşuyorsa ONUN durumu izlenir: oynat/duraklat düğmesi ve
    // ilerleme çubuğu iki motorda da aynı `SpeechOutputState`i okur.
    final aiVoice = _useAiVoice;
    final speech = aiVoice
        ? ref.watch(aiSpeechProvider)
        : ref.watch(speechOutputProvider);
    final controller = ref.read(speechOutputProvider.notifier);
    _speech = controller;
    _aiSpeech = ref.read(aiSpeechProvider.notifier);
    final text = _text;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (_isPodcast)
            TextButton(
              onPressed: _generating ? null : _showOriginal,
              child: Text(l10n.listenOriginalText),
            ),
          // DIŞA AKTARMA (kullanıcı isteği 2026-08-16). Yalnız podcast
          // metninde anlamlı: ham belge metni zaten kaynağında duruyor.
          if (_isPodcast && !_generating && !_rendering)
            PopupMenuButton<String>(
              tooltip: l10n.exportTitle,
              onSelected: (action) => switch (action) {
                'audio' => _exportAudio(),
                'text' => _shareText(),
                'note' => _saveAsNote(),
                _ => null,
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'audio',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.audio_file_outlined),
                    title: Text(l10n.podcastExportAudio),
                  ),
                ),
                PopupMenuItem(
                  value: 'text',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.ios_share),
                    title: Text(l10n.podcastShareText),
                  ),
                ),
                PopupMenuItem(
                  value: 'note',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.note_add_outlined),
                    title: Text(l10n.podcastSaveAsNote),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _busy || _generating || _rendering
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    // Ses üretiminde kaçıncı parçada olduğumuz biliniyor:
                    // belirsiz çark yerine gerçek ilerleme gösterilir.
                    value: _rendering && _renderTotal > 0
                        ? _renderDone / _renderTotal
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _rendering
                        ? l10n.podcastRenderingAudio(_renderDone, _renderTotal)
                        : (_generating
                              ? l10n.generating
                              : l10n.listenReadingPdf),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                if (_isPodcast)
                  Container(
                    width: double.infinity,
                    color: scheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fromCache
                                ? l10n.listenPodcastCached
                                : l10n.listenPodcastReady,
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                        ),
                        if (_fromCache)
                          TextButton(
                            onPressed: () => _makePodcast(
                              summarize: _lastSummarize,
                              force: true,
                            ),
                            child: Text(l10n.listenRegenerate),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      text ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (speech.isActive)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LinearProgressIndicator(
                              // Parça HAZIRLANIRKEN belirsiz (akan) çubuk:
                              // hoparlörden ses çıkmadığı o birkaç saniyede
                              // ekranda hiçbir şey kıpırdamıyordu (kullanıcı
                              // isteği 2026-08-16 — bkz. SpeechOutputState).
                              value: speech.loading ? null : speech.progress,
                            ),
                          ),
                        if (speech.loading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.listenPreparingVoice,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: scheme.primary),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                onPressed: () =>
                                    _togglePlay(speech, text ?? ''),
                                icon: Icon(switch (speech.state) {
                                  SpeechState.speaking => Icons.pause,
                                  SpeechState.paused => Icons.play_arrow,
                                  SpeechState.idle => Icons.headphones,
                                }),
                                label: Text(switch (speech.state) {
                                  SpeechState.speaking => l10n.speechPause,
                                  SpeechState.paused => l10n.speechResume,
                                  SpeechState.idle => l10n.listenPlay,
                                }),
                              ),
                            ),
                            if (speech.isActive) ...[
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: l10n.speechStop,
                                onPressed: aiVoice
                                    ? ref.read(aiSpeechProvider.notifier).stop
                                    : controller.stop,
                                icon: const Icon(Icons.stop),
                              ),
                            ],
                          ],
                        ),
                        // Hangi sesin okuduğu TEK satırda; seçim Ayarlar'da
                        // (bkz. _useAiVoice). Ayarda yapay zekâ seçili ama
                        // anahtar yoksa sebebi burada yazar.
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                aiVoice ? Icons.auto_awesome : Icons.smartphone,
                                size: 15,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  aiVoice
                                      ? l10n.listenAiVoice
                                      : (ref.read(ttsEngineProvider) ==
                                                TtsEngine.gemini
                                            ? l10n.ttsEngineAiUnavailable
                                            : l10n.ttsEngineDevice),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isPodcast) ...[
                          const SizedBox(height: 10),
                          Text(
                            l10n.listenConvertWithAi,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _makePodcast(summarize: false),
                                  icon: const Icon(Icons.podcasts, size: 18),
                                  label: Text(l10n.listenMakePodcast),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _makePodcast(summarize: true),
                                  icon: const Icon(Icons.compress, size: 18),
                                  label: Text(l10n.listenMakePodcastSummary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
