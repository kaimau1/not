import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note_type.dart';
import '../../settings/settings_providers.dart';
import '../data/ai_cache.dart';
import '../data/ai_speech.dart';
import '../data/antalia/antalia_engine.dart';
import '../data/antalia/antalia_speech.dart';
import '../data/speech_service.dart';
import '../data/gemini_service.dart';
import '../../../core/friendly_error.dart';

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

  /// Motor TEK yerden gelir: Ayarlar → Ses → Seslendirme (bkz.
  /// [SpeechService]). Yapay zekâ sesi başarısız olursa okuma cihaz sesiyle
  /// sürer ve sebebi ekranda yazar.
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  /// dispose'da `ref` kullanılamaz (Riverpod "widget unmounted" hatası atar ve
  /// okuma DURMAZ); servis build'de alana alınır.
  SpeechService? _speechService;

  @override
  void dispose() {
    // Ekrandan çıkınca okuma sürmesin.
    _speechService?.stop();
    super.dispose();
  }

  Future<void> _togglePlay(SpeechOutputState speech, String text) async {
    final service = ref.read(speechProvider.notifier);
    if (speech.state == SpeechState.speaking) {
      await service.pause();
      return;
    }
    if (speech.state == SpeechState.paused) {
      await service.resume();
      return;
    }
    await service.speak(
      text,
      onAiFailed: (message) {
        if (!mounted) return;
        showAppMessage(context, context.l10n.listenAiVoiceFailed(message));
        setState(() {});
      },
    );
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
        _error = context.l10n.aiError(friendlyError(context.l10n, e));
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
    await ref.read(speechProvider.notifier).stop();

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
        _error = context.l10n.aiError(friendlyError(context.l10n, e));
        _generating = false;
      });
    }
  }

  /// Podcast SESİNİ tek bir WAV dosyasına döker ve paylaşım levhasını açar.
  ///
  /// Ses üretimi kotadan düşüyor ve dinlerken üretilen parçalar okuma bitince
  /// siliniyor — bu yüzden dışa aktarma metni BAŞTAN seslendirir ve maliyeti
  /// önce kullanıcıya sorar.
  ///
  /// Ayar Antalia Türkçe sesindeyse (ve uygulama Türkçe) dosyayı o üretir:
  /// cihazda, kotasız — maliyet sorusu yok.
  Future<void> _exportAudio() async {
    final text = _text;
    if (text == null || text.trim().isEmpty) return;
    final l10n = context.l10n;
    final service = ref.read(speechProvider.notifier);
    final local =
        !service.prefersAi &&
        service.prefersLocal &&
        Localizations.localeOf(context).languageCode == 'tr';
    if (!local && !service.aiAvailable) {
      _snack(l10n.ttsEngineAiUnavailable);
      return;
    }
    if (!local) {
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
    }

    await service.stop();
    setState(() {
      _rendering = true;
      _renderDone = 0;
      _renderTotal = 0;
    });
    void onProgress(int done, int total) {
      if (!mounted) return;
      setState(() {
        _renderDone = done;
        _renderTotal = total;
      });
    }

    try {
      final path = local
          ? await ref
                .read(antaliaSpeechProvider.notifier)
                .renderToFile(
                  text,
                  fileName: widget.title,
                  onProgress: onProgress,
                )
          : await ref
                .read(aiSpeechProvider.notifier)
                .renderToFile(
                  text,
                  fileName: widget.title,
                  onProgress: onProgress,
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
      _snack(context.l10n.aiError(friendlyError(context.l10n, e)));
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
      unawaited(context.pushNote(noteRoutePath(id)));
    } catch (e) {
      if (!mounted) return;
      _snack(context.l10n.aiError(friendlyError(context.l10n, e)));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(message);
  }

  Future<void> _showOriginal() async {
    await ref.read(speechProvider.notifier).stop();
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
    final speech = ref.watch(speechProvider);
    final service = ref.read(speechProvider.notifier);
    _speechService = service;
    // Model denetimi/indirmesi bitince "hangi ses" satırı güncellensin.
    ref.watch(antaliaModelProvider.select((m) => m.status));
    final aiVoice = speech.isActive ? service.usingAi : service.prefersAi;
    final localVoice = speech.isActive
        ? service.usingLocal
        : !aiVoice && service.prefersLocal;
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
                                onPressed: service.stop,
                                icon: const Icon(Icons.stop),
                              ),
                            ],
                          ],
                        ),
                        // Hangi sesin okuduğu TEK satırda; seçim Ayarlar'da
                        // (bkz. SpeechService). Ayarda yapay zekâ seçili ama
                        // anahtar yoksa sebebi burada yazar.
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                aiVoice
                                    ? Icons.auto_awesome
                                    : localVoice
                                    ? Icons.record_voice_over
                                    : Icons.smartphone,
                                size: 15,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  aiVoice
                                      ? l10n.listenAiVoice
                                      : localVoice
                                      ? l10n.listenLocalVoice
                                      : switch (ref.read(ttsEngineProvider)) {
                                          TtsEngine.gemini =>
                                            l10n.ttsEngineAiUnavailable,
                                          TtsEngine.antalia =>
                                            AntaliaModelFiles.supported
                                                ? l10n.ttsLocalMissing
                                                : l10n.ttsLocalUnsupported,
                                          TtsEngine.device =>
                                            l10n.ttsEngineDevice,
                                        },
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
