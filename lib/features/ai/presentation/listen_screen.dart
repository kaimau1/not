import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
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

  /// Gosterilen metin onbellekten mi geldi (yeniden uret secenegi icin).
  bool _fromCache = false;
  bool _lastSummarize = false;

  /// Bu okumada YAPAY ZEKÂ sesi kullanılsın mı? Başlangıç değeri Ayarlar'daki
  /// tercih; kullanıcı ekrandaki anahtarla o okuma için değiştirebilir.
  bool? _aiVoice;

  bool get _useAiVoice =>
      _aiVoice ?? (ref.read(ttsEngineProvider) == TtsEngine.gemini);

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
    final aiAvailable = ref.read(aiSpeechProvider.notifier).isAvailable;
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
        ],
      ),
      body: _busy || _generating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_generating ? l10n.generating : l10n.listenReadingPdf),
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
                              value: speech.progress,
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
                        // "AI ile dinle": okumayı cihaz sesi yerine Gemini'nin
                        // seslendirme modeline yaptırır. Kendi Gemini anahtarı
                        // yoksa seçenek gösterilmez — dahili yol ses
                        // döndürmüyor, açık bir düğmenin hep hata vermesi
                        // yanıltıcı olurdu.
                        if (aiAvailable)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: aiVoice,
                            title: Text(
                              l10n.listenAiVoice,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              l10n.listenAiVoiceInfo,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            onChanged: (value) async {
                              // Motor değişiyor: konuşan varsa sussun, yoksa
                              // iki ses üst üste biner.
                              await ref
                                  .read(speechOutputProvider.notifier)
                                  .stop();
                              await ref.read(aiSpeechProvider.notifier).stop();
                              if (mounted) setState(() => _aiVoice = value);
                            },
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
