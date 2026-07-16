import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/data/assistant_service.dart';
import '../../ai/data/gemini_service.dart';
import '../data/notes_repository.dart';
import '../domain/note_type.dart';

/// Sesli hızlı not: ekran açılır açılmaz kayıt başlar; durdurunca konuşma
/// yazıya dökülür ve AI uygun notu (metin/alışveriş listesi, gerekirse
/// hatırlatıcılı) kendisi oluşturur. "Hey Google, Notlar'ı aç" + widget'taki
/// mikrofon bu ekrana çıkar.
class VoiceCaptureScreen extends ConsumerStatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  ConsumerState<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

enum _Phase { recording, processing, done, error }

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;

  /// Anlık ses seviyesi, 0 (sessiz) – 1 (yüksek). Mikrofon halkasını büyütür;
  /// kullanıcı sesinin algılandığını buradan görür.
  double _level = 0;
  Duration _elapsed = Duration.zero;
  String? _path;
  _Phase _phase = _Phase.recording;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          setState(() {
            _phase = _Phase.error;
            _message = context.l10n.micPermissionDenied;
          });
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      _path = p.join(dir.path, 'sesli_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _recorder.start(
        // 64 kbps konuşma için yeterli; küçük dosya = hızlı yükleme = az bekleme.
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: _path!,
      );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((a) {
        // dBFS: 0 en yüksek, -50 ve altı sessizlik sayılır.
        final level = ((a.current + 50) / 50).clamp(0.0, 1.0);
        if (mounted) setState(() => _level = level);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e.toString();
        });
      }
    }
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    _ticker?.cancel();
    _ampSub?.cancel();
    setState(() => _phase = _Phase.processing);
    try {
      final path = await _recorder.stop();
      if (path == null) throw StateError(l10n.genericError('kayıt yok'));
      final bytes = await File(path).readAsBytes();
      File(path).delete().ignore();

      final service = ref.read(geminiServiceProvider);
      final assistant = ref.read(assistantServiceProvider);
      final notes = ref.read(notesStreamProvider).value ?? const [];
      String reply;
      try {
        // Tek çağrı: ses doğrudan asistana gider (ayrı transkripsiyon yok).
        reply = await service.assistantVoiceNote(
          notesContext: assistant.buildNotesContext(notes),
          audioBytes: bytes,
          mimeType: 'audio/mp4',
          onToolCall: assistant.execute,
        );
      } on GeminiException {
        // Asistan başarısız olursa eski yol: yazıya dök, düz not kaydet.
        final transcript = await service.transcribeAudio(bytes, 'audio/mp4');
        if (transcript.trim().isEmpty) {
          throw StateError(l10n.voiceNothingHeard);
        }
        final repo = ref.read(notesRepositoryProvider);
        if (repo == null) rethrow;
        final id = await repo.createNote(NoteType.text);
        repo.updateFields(id, {'body': transcript.trim()});
        reply = l10n.voiceNoteSaved;
      }

      if (mounted) {
        setState(() {
          _phase = _Phase.done;
          _message = reply;
        });
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e.isAuthError ? l10n.aiNoApiKey : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e.toString();
        });
      }
    }
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    _ampSub?.cancel();
    try {
      final path = await _recorder.stop();
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.voiceNoteTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_phase) {
            _Phase.recording => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Halka ses seviyesiyle büyür: konuşma algılanıyor demektir.
                  SizedBox(
                    width: 144,
                    height: 144,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 96 + 48 * _level,
                        height: 96 + 48 * _level,
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mic, size: 44, color: scheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _format(_elapsed),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.voiceCaptureHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
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
                        icon: const Icon(Icons.check),
                        label: Text(l10n.voiceFinish),
                      ),
                    ],
                  ),
                ],
              ),
            _Phase.processing => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.voiceProcessing),
                ],
              ),
            _Phase.done => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 56, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(_message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () => context.go('/'),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            _Phase.error => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 56, color: scheme.error),
                  const SizedBox(height: 16),
                  Text(_message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () => context.go('/'),
                    child: Text(l10n.close),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
