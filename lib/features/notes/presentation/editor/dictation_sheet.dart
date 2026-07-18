import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/l10n_ext.dart';
import '../../../ai/data/api_key_store.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/data/live_dictation_session.dart';

/// Sesli yazdırma alt sayfası. Gemini API anahtarı varsa konuşma Gemini
/// Live üzerinden ANLIK olarak yazıya dökülür ve ekranda akar; anahtar
/// yoksa kayıt bitince tek seferde dökülür. "Bitir ve ekle" dökümü döner,
/// iptalde null.
Future<String?> showDictationSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => const _DictationSheet(),
    );

enum _Phase { starting, live, recording, processing, error }

class _DictationSheet extends ConsumerStatefulWidget {
  const _DictationSheet();

  @override
  ConsumerState<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends ConsumerState<_DictationSheet> {
  final _recorder = AudioRecorder();
  final _transcript = StringBuffer();
  LiveDictationSession? _session;
  StreamSubscription<Uint8List>? _micSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _recordPath;
  _Phase _phase = _Phase.starting;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final l10n = context.l10n;
    try {
      if (!await _recorder.hasPermission()) {
        _fail(l10n.micPermissionDenied);
        return;
      }
      final apiKey = await ref.read(apiKeyStoreProvider).read();
      if (!mounted) return;
      if (apiKey != null && apiKey.isNotEmpty) {
        await _startLive(apiKey);
      } else {
        await _startFallbackRecording();
      }
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Canlı yol: mikrofon PCM akışı Gemini Live'a gider, döküm anlık akar.
  Future<void> _startLive(String apiKey) async {
    final session = LiveDictationSession(
      onTranscript: (text) {
        _transcript.write(text);
        if (mounted) setState(() {});
      },
      onError: (e) {
        // Bağlantı düşse de o ana dek biriken metin kaybolmasın: hata
        // gösterilir ama "Bitir ve ekle" çalışmaya devam eder.
        if (mounted) setState(() => _errorMessage = e.toString());
      },
    );
    await session.connect(apiKey);
    _session = session;
    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _micSub = micStream.listen(session.sendAudio);
    if (mounted) setState(() => _phase = _Phase.live);
  }

  /// Anahtarsız yol: dosyaya kaydet, bitince toplu transkripsiyon.
  Future<void> _startFallbackRecording() async {
    final dir = await getTemporaryDirectory();
    _recordPath =
        p.join(dir.path, 'dikte_${DateTime.now().millisecondsSinceEpoch}.m4a');
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _recordPath!,
    );
    if (mounted) setState(() => _phase = _Phase.recording);
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    _ticker?.cancel();
    if (_phase == _Phase.live) {
      await _micSub?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {}
      await _session?.close();
      _session = null;
      if (!mounted) return;
      final text = _transcript.toString().trim();
      Navigator.pop(context, text.isEmpty ? null : text);
      return;
    }
    // Kayıt yolu: durdur, tek seferde yazıya dök.
    setState(() => _phase = _Phase.processing);
    try {
      final path = await _recorder.stop();
      if (path == null) throw StateError(l10n.voiceNothingHeard);
      final bytes = await File(path).readAsBytes();
      File(path).delete().ignore();
      final text =
          await ref.read(geminiServiceProvider).transcribeAudio(bytes, 'audio/mp4');
      if (!mounted) return;
      if (text.trim().isEmpty) {
        _fail(l10n.voiceNothingHeard);
        return;
      }
      Navigator.pop(context, text.trim());
    } on GeminiException catch (e) {
      _fail(e.isAuthError ? l10n.aiNoApiKey : e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    await _micSub?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    await _session?.close();
    _session = null;
    if (mounted) Navigator.pop(context);
  }

  void _fail(String message) {
    _ticker?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _micSub?.cancel();
    _session?.close();
    _recorder.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final transcript = _transcript.toString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: switch (_phase) {
          _Phase.starting => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          _Phase.processing => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.dictationProcessing),
                ],
              ),
            ),
          _Phase.error => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: scheme.error),
                const SizedBox(height: 12),
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ],
            ),
          _Phase.live || _Phase.recording => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: scheme.error),
                    const SizedBox(width: 8),
                    Text(
                      _format(_elapsed),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _phase == _Phase.live
                      ? l10n.dictationListening
                      : l10n.dictationNoKeyInfo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (_phase == _Phase.live) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 96,
                      maxHeight: 200,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(transcript.isEmpty ? '…' : transcript),
                    ),
                  ),
                ],
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _cancel,
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.stop),
                      label: Text(l10n.stopAndSave),
                    ),
                  ],
                ),
              ],
            ),
        },
      ),
    );
  }
}
