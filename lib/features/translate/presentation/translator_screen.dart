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
import '../../notes/data/device_speech.dart';
import '../../notes/presentation/editor/audio_recorder_sheet.dart';
import '../../settings/settings_providers.dart';
import '../data/live_translate_session.dart';
import '../data/offline_translator.dart';

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
    required this.targetCode,
  });

  final String transcript;
  final String translation;
  final String language;

  /// Çevirinin dili — tekrar seslendirilirken doğru sesle okunsun diye.
  final String targetCode;
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

  /// Cihaz tanımasıyla konuşma yakalama. Hangi dilin dinlendiği baştan
  /// bilinmek zorunda (tanıyıcı yerel ayar ister), bu yüzden her dilin ayrı
  /// düğmesi var — konuşan kendi düğmesini kullanır.
  StreamSubscription<({String? text, double? level})>? _captureSub;
  String _captureText = '';
  String? _captureLang;
  bool get _capturing => _captureLang != null;

  /// Cihazda konuşma tanıma var mı (Windows'ta yok → eski ses yolu).
  bool _deviceSpeechAvailable = false;

  String _langName(String code) =>
      _languages.firstWhere((l) => l.$2 == code, orElse: () => ('?', code)).$1;

  @override
  void initState() {
    super.initState();
    DeviceSpeech.isAvailable().then((available) {
      if (mounted) setState(() => _deviceSpeechAvailable = available);
    });
  }

  @override
  void dispose() {
    _stopLive(updateState: false);
    _captureSub?.cancel();
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

  /// Verilen dili dinlemeye başlar (cihaz tanıması). Hangi dilin dinleneceği
  /// düğmeden gelir; tanıyıcı yerel ayarı baştan bilmek zorunda.
  Future<void> _startCapture(String sourceCode) async {
    if (_capturing || _processing) return;
    _captureText = '';
    setState(() => _captureLang = sourceCode);
    _captureSub =
        DeviceSpeech.listen(
          locale: SpeechOutputController.localeFor(sourceCode),
        ).listen(
          (event) {
            final text = event.text;
            if (text != null && mounted) setState(() => _captureText = text);
          },
          onError: (Object _) {
            // Tanıma düşse de biriken metin korunur; bitişte çevrilir.
          },
        );
  }

  /// Dinlemeyi bitirir ve yakalanan metni çevirir.
  Future<void> _stopCaptureAndTranslate() async {
    final source = _captureLang;
    if (source == null) return;
    await DeviceSpeech.stop();
    // Son sonucun gelmesi için kısa bekleme (tanıyıcı stop sonrası yazar).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _captureSub?.cancel();
    _captureSub = null;
    final text = _captureText.trim();
    _captureText = '';
    if (!mounted) return;
    setState(() => _captureLang = null);
    if (text.isEmpty) {
      _showSnack(context.l10n.nothingHeard);
      return;
    }
    await _translateAndAdd(text, from: source);
  }

  /// Metni çevirir ve listeye ekler. Önce CİHAZDA (ML Kit) denenir: bedava,
  /// çevrimdışı, kota yakmaz. Dil çifti desteklenmiyorsa (ör. Azerbaycanca)
  /// ya da kullanıcı kaliteyi seçtiyse Gemini'ye düşülür.
  Future<void> _translateAndAdd(String text, {required String from}) async {
    final l10n = context.l10n;
    final to = from == _langA ? _langB : _langA;
    setState(() => _processing = true);
    try {
      final preferGemini = ref.read(preferGeminiTranslateProvider);
      String translated;
      if (!preferGemini && OfflineTranslator.supportsPair(from, to)) {
        const offline = OfflineTranslator();
        if (!await offline.isModelReady(from) ||
            !await offline.isModelReady(to)) {
          if (mounted) _showSnack(l10n.translateDownloadingModel);
          // Mobil veriyle de insin: kullanıcı çeviriyi ŞİMDİ istiyor ve
          // model bir kereliktir.
          await offline.downloadModel(from, wifiOnly: false);
          await offline.downloadModel(to, wifiOnly: false);
        }
        translated = await offline.translate(text: text, from: from, to: to);
      } else {
        translated = await ref
            .read(geminiServiceProvider)
            .translateText(text, _langName(to));
      }
      if (!mounted) return;
      setState(() {
        _entries.add(
          _TalkEntry(
            transcript: text,
            translation: translated,
            language: _langName(from),
            targetCode: to,
          ),
        );
      });
      if (_autoSpeak && translated.isNotEmpty) {
        await _speak(translated, languageCode: to);
      }
    } on GeminiException catch (e) {
      _showSnack(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message));
    } catch (e) {
      _showSnack(l10n.aiError(e.toString()));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Cihaz tanıması yoksa (Windows) eski yol: ses kaydedilip Gemini'ye
  /// gönderilir, dil tespitini de model yapar.
  Future<void> _pushToTalkViaAudio() async {
    final l10n = context.l10n;
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    setState(() => _processing = true);
    try {
      final bytes = await File(result.path).readAsBytes();
      File(result.path).delete().ignore();
      final translation = await ref
          .read(geminiServiceProvider)
          .translateSpeech(
            bytes: bytes,
            mimeType: 'audio/mp4',
            languageA: _langName(_langA),
            languageB: _langName(_langB),
          );
      if (!mounted) return;
      final spokenA = translation.detectedLanguage.toLowerCase().contains(
        _langName(_langA).toLowerCase(),
      );
      final target = spokenA ? _langB : _langA;
      setState(() {
        _entries.add(
          _TalkEntry(
            transcript: translation.transcript,
            translation: translation.translation,
            language: translation.detectedLanguage,
            targetCode: target,
          ),
        );
      });
      if (_autoSpeak && translation.translation.isNotEmpty) {
        await _speak(translation.translation, languageCode: target);
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
                                onPressed: () => _speak(
                                  entry.translation,
                                  languageCode: entry.targetCode,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(top: false, child: _talkControls(context)),
      ],
    );
  }

  /// Konuşma düğmeleri. Cihaz tanıması varsa HER DİL İÇİN AYRI düğme
  /// (tanıyıcı yerel ayarı baştan bilmek zorunda; kim konuşacaksa kendi
  /// düğmesini kullanır — "sıra sıra" mod da bu). Yoksa tek düğmeyle eski
  /// ses yoluna düşülür ve dili model tespit eder.
  Widget _talkControls(BuildContext context) {
    final l10n = context.l10n;
    if (!_deviceSpeechAvailable) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _processing ? null : _pushToTalkViaAudio,
          icon: _processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mic),
          label: Text(_processing ? l10n.aiThinking : l10n.pushToTalk),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_capturing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _captureText.isEmpty ? l10n.listening : _captureText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Row(
            children: [
              Expanded(child: _talkButton(_langA)),
              const SizedBox(width: 10),
              Expanded(child: _talkButton(_langB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _talkButton(String code) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hold = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold;
    final active = _captureLang == code;
    // Diğer dil dinlenirken bu düğme kapalı: iki tanıyıcı aynı anda mikrofonu
    // paylaşamaz.
    final disabled = _processing || (_capturing && !active);

    void toggleTap() {
      if (active) {
        _stopCaptureAndTranslate();
      } else {
        _startCapture(code);
      }
    }

    return GestureDetector(
      onLongPressStart: hold && !disabled ? (_) => _startCapture(code) : null,
      onLongPressEnd: hold && active ? (_) => _stopCaptureAndTranslate() : null,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: active ? scheme.errorContainer : null,
          foregroundColor: active ? scheme.onErrorContainer : null,
        ),
        // Basılı-tut modunda düz dokunuş yalnızca ipucu gösterir; kayıt uzun
        // basışla başlar (sesli asistandaki davranışın aynısı).
        onPressed: disabled
            ? null
            : hold
            ? (active
                  ? _stopCaptureAndTranslate
                  : () => _showSnack(l10n.voiceHoldHint))
            : toggleTap,
        icon: Icon(active ? Icons.stop : Icons.mic, size: 20),
        label: Text(
          _langName(code),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
