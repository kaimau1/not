import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
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
/// Ekran metnin nereden geldiğini bilmez; [loadText] ne verirse onu okur.
/// PDF, Word, PowerPoint ve düz metin aynı ekranı kullanıyor.
class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({
    super.key,
    required this.title,
    required this.loadText,
  });

  final String title;
  final Future<String> Function() loadText;

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

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    // Ekrandan çıkınca okuma sürmesin.
    ref.read(speechOutputProvider.notifier).stop();
    super.dispose();
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

  Future<void> _makePodcast({required bool summarize}) async {
    final source = _original;
    if (source == null) return;
    await ref.read(speechOutputProvider.notifier).stop();
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final script = await ref
          .read(geminiServiceProvider)
          .podcastScript(source, title: widget.title, summarize: summarize);
      if (!mounted) return;
      setState(() {
        _text = script;
        _isPodcast = true;
        _generating = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _generating = false;
      });
    }
  }

  Future<void> _showOriginal() async {
    await ref.read(speechOutputProvider.notifier).stop();
    if (!mounted) return;
    setState(() {
      _text = _original;
      _isPodcast = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final speech = ref.watch(speechOutputProvider);
    final controller = ref.read(speechOutputProvider.notifier);
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
                    child: Text(
                      l10n.listenPodcastReady,
                      style: TextStyle(color: scheme.onPrimaryContainer),
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
                                onPressed: () {
                                  if (speech.state == SpeechState.speaking) {
                                    controller.pause();
                                  } else if (speech.state ==
                                      SpeechState.paused) {
                                    controller.resume();
                                  } else {
                                    controller.speak(text ?? '');
                                  }
                                },
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
                                onPressed: controller.stop,
                                icon: const Icon(Icons.stop),
                              ),
                            ],
                          ],
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
