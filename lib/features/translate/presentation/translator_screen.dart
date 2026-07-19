import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/pcm_player.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/gemini_service.dart';
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../data/live_translate_session.dart';

/// Desteklenen diller (ad + BCP-47 kodu).
const _languages = <(String, String)>[
  ('Türkçe', 'tr'),
  ('İngilizce', 'en'),
  ('Almanca', 'de'),
  ('Fransızca', 'fr'),
  ('İspanyolca', 'es'),
  ('İtalyanca', 'it'),
  ('Arapça', 'ar'),
  ('Rusça', 'ru'),
  ('Farsça', 'fa'),
  ('Hollandaca', 'nl'),
  ('Portekizce', 'pt'),
  ('Yunanca', 'el'),
  ('Japonca', 'ja'),
  ('Korece', 'ko'),
  ('Çince', 'zh'),
  ('Azerbaycanca', 'az'),
];

enum _TranslatorMode { live, pushToTalk }

class _TalkEntry {
  const _TalkEntry({
    required this.transcript,
    required this.translation,
    required this.language,
  });

  final String transcript;
  final String translation;
  final String language;
}

/// Konuşma Çevirmeni: Gemini 3.5 Live Translate ile kesintisiz canlı çeviri
/// (iki paralel oturumla tam çift yönlü) + her ortamda çalışan bas-konuş modu.
class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  _TranslatorMode _mode = _TranslatorMode.live;
  String _langA = 'tr';
  String _langB = 'en';

  // --- Canlı mod durumu ---
  bool _liveActive = false;
  bool _connecting = false;
  final _heardBuffer = StringBuffer();
  final _translatedBuffer = StringBuffer();
  LiveTranslateSession? _sessionToB;
  LiveTranslateSession? _sessionToA;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSub;
  final _pcmPlayer = PcmSegmentPlayer();

  // --- Bas-konuş modu durumu ---
  final _entries = <_TalkEntry>[];
  bool _processing = false;
  bool _autoSpeak = true;

  String _langName(String code) =>
      _languages.firstWhere((l) => l.$2 == code, orElse: () => ('?', code)).$1;

  @override
  void dispose() {
    _stopLive(updateState: false);
    _pcmPlayer.dispose();
    super.dispose();
  }

  // ---- Canlı mod ------------------------------------------------------

  Future<void> _startLive() async {
    final l10n = context.l10n;
    final apiKey = await ref.read(apiKeyStoreProvider).read();
    if (apiKey == null || apiKey.isEmpty) {
      _showSnack(l10n.aiNoApiKey);
      return;
    }
    setState(() {
      _connecting = true;
      _heardBuffer.clear();
      _translatedBuffer.clear();
    });
    try {
      // İki paralel oturum: hedef dili B olan oturum A dilini çevirir ve
      // tersi. Girdi zaten hedef dildeyse oturum sessiz kalır; böylece iki
      // kişi kendi dilinde konuşurken tek mikrofonla çift yönlü çeviri olur.
      _sessionToB = LiveTranslateSession(
        targetLanguageCode: _langB,
        onAudio: _pcmPlayer.addPcm,
        onInputTranscript: (text) => setState(() => _heardBuffer.write(text)),
        onOutputTranscript: (text) =>
            setState(() => _translatedBuffer.write(text)),
        onError: _onLiveError,
      );
      _sessionToA = LiveTranslateSession(
        targetLanguageCode: _langA,
        onAudio: _pcmPlayer.addPcm,
        // Girdi dökümü tek oturumdan alınır; ikisinden almak metni çiftler.
        onInputTranscript: (_) {},
        onOutputTranscript: (text) =>
            setState(() => _translatedBuffer.write(text)),
        onError: _onLiveError,
      );
      await Future.wait([
        _sessionToB!.connect(apiKey),
        _sessionToA!.connect(apiKey),
      ]);

      _recorder = AudioRecorder();
      if (!await _recorder!.hasPermission()) {
        throw StateError(l10n.micPermissionDenied);
      }
      final micStream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _micSub = micStream.listen((chunk) {
        _sessionToB?.sendAudio(chunk);
        _sessionToA?.sendAudio(chunk);
      });

      setState(() {
        _connecting = false;
        _liveActive = true;
      });
    } catch (e) {
      await _stopLive();
      if (mounted) {
        _showSnack(context.l10n.liveTranslateError(e.toString()));
      }
    }
  }

  void _onLiveError(Object error) {
    if (!_liveActive) return;
    _stopLive();
    _showSnack(context.l10n.liveTranslateError(error.toString()));
  }

  Future<void> _stopLive({bool updateState = true}) async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;
    await _sessionToB?.close();
    await _sessionToA?.close();
    _sessionToB = null;
    _sessionToA = null;
    _pcmPlayer.flush();
    if (updateState && mounted) {
      setState(() {
        _liveActive = false;
        _connecting = false;
      });
    }
  }

  // ---- Bas-konuş modu -------------------------------------------------

  Future<void> _pushToTalk() async {
    final l10n = context.l10n;
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    setState(() => _processing = true);
    try {
      final bytes = await File(result.path).readAsBytes();
      File(result.path).delete().ignore();
      final service = ref.read(geminiServiceProvider);
      final translation = await service.translateSpeech(
        bytes: bytes,
        mimeType: 'audio/mp4',
        languageA: _langName(_langA),
        languageB: _langName(_langB),
      );
      if (!mounted) return;
      setState(() {
        _entries.add(
          _TalkEntry(
            transcript: translation.transcript,
            translation: translation.translation,
            language: translation.detectedLanguage,
          ),
        );
      });
      if (_autoSpeak && translation.translation.isNotEmpty) {
        // Çeviri, konuşulan dilin KARŞISINDAKİ dildedir. Hedef dil
        // söylenmezse metin Türkçe sesle, Türkçe okunuşuyla okunuyordu.
        final spokenA = translation.detectedLanguage.toLowerCase().contains(
          _langName(_langA).toLowerCase(),
        );
        await _speak(
          translation.translation,
          languageCode: spokenA ? _langB : _langA,
        );
      }
    } on GeminiException catch (e) {
      _showSnack(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message));
    } catch (e) {
      _showSnack(l10n.aiError(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Çeviriyi seslendirir. Eskiden Gemini TTS'e gidiyordu ve ham API
  /// ANAHTARI istiyordu — anahtarı olmayanda sessizce hiç ses çıkmıyordu
  /// ("seslendirme yapılmıyor" sorununun kökü buydu). Artık cihazın kendi
  /// seslendirmesi: bedava, anında, çevrimdışı ve ses tipi Ayarlar'dan
  /// seçilebiliyor.
  Future<void> _speak(String text, {String? languageCode}) async {
    try {
      await ref
          .read(speechOutputProvider.notifier)
          .speak(text, languageCode: languageCode);
    } catch (e) {
      debugPrint('TTS başarısız: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Arayüz ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasKey = (ref.watch(geminiApiKeyProvider).value ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translatorTitle)),
      body: !hasKey
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.aiNoApiKey),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.push('/settings'),
                    child: Text(l10n.settings),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: _languageDropdown(isA: true)),
                      IconButton(
                        tooltip: l10n.swapLanguages,
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: _liveActive
                            ? null
                            : () => setState(() {
                                final tmp = _langA;
                                _langA = _langB;
                                _langB = tmp;
                              }),
                      ),
                      Expanded(child: _languageDropdown(isA: false)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SegmentedButton<_TranslatorMode>(
                    segments: [
                      ButtonSegment(
                        value: _TranslatorMode.live,
                        label: Text(l10n.liveMode),
                        icon: const Icon(Icons.graphic_eq),
                      ),
                      ButtonSegment(
                        value: _TranslatorMode.pushToTalk,
                        label: Text(l10n.pushToTalkMode),
                        icon: const Icon(Icons.mic_none),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: _liveActive
                        ? null
                        : (selection) =>
                              setState(() => _mode = selection.first),
                  ),
                ),
                Expanded(
                  child: _mode == _TranslatorMode.live
                      ? _buildLiveBody(context)
                      : _buildPushToTalkBody(context),
                ),
              ],
            ),
    );
  }

  Widget _languageDropdown({required bool isA}) {
    return DropdownButtonFormField<String>(
      initialValue: isA ? _langA : _langB,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true),
      items: [
        for (final (name, code) in _languages)
          DropdownMenuItem(value: code, child: Text(name)),
      ],
      onChanged: _liveActive
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                if (isA) {
                  _langA = value;
                  if (_langB == value) _langB = value == 'tr' ? 'en' : 'tr';
                } else {
                  _langB = value;
                  if (_langA == value) _langA = value == 'tr' ? 'en' : 'tr';
                }
              });
            },
    );
  }

  Widget _buildLiveBody(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            l10n.liveTranslateInfo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _transcriptPanel(
                    title: l10n.heardLabel,
                    text: _heardBuffer.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _transcriptPanel(
                    title: l10n.translationLabel,
                    text: _translatedBuffer.toString(),
                    highlighted: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SafeArea(
            top: false,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: _liveActive ? scheme.errorContainer : null,
                foregroundColor: _liveActive ? scheme.onErrorContainer : null,
              ),
              onPressed: _connecting
                  ? null
                  : _liveActive
                  ? () => _stopLive()
                  : _startLive,
              icon: _connecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_liveActive ? Icons.stop : Icons.play_arrow),
              label: Text(
                _connecting
                    ? l10n.connecting
                    : _liveActive
                    ? l10n.stopLive
                    : l10n.startLive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcriptPanel({
    required String title,
    required String text,
    bool highlighted = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                text.isEmpty ? '…' : text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPushToTalkBody(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          title: Text(l10n.autoSpeak),
          value: _autoSpeak,
          onChanged: (value) => setState(() => _autoSpeak = value),
        ),
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.pushToTalkHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.language,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(entry.transcript),
                          const Divider(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.translation,
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.speakTranslation,
                                icon: const Icon(
                                  Icons.volume_up_outlined,
                                  size: 18,
                                ),
                                onPressed: () => _speak(entry.translation),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _processing ? null : _pushToTalk,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic),
              label: Text(_processing ? l10n.aiThinking : l10n.pushToTalk),
            ),
          ),
        ),
      ],
    );
  }
}
