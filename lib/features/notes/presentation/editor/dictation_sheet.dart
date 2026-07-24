import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/l10n_ext.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../settings/settings_providers.dart';
import '../../data/device_speech.dart';

/// Sesli yazdırma alt sayfası.
///
/// Cihazın YERLEŞİK konuşma tanıması varsa (Android) onu kullanır: metin
/// konuşuldukça anlık akar, ücretsizdir ve Gemini kotası harcamaz. Yerleşik
/// tanıma yoksa (Windows) ses kaydedilir ve bitişte tek seferde yazıya
/// dökülür.
///
/// [onPartial] verilirse metin biriktikçe o ana kadarki TAM metinle çağrılır;
/// editör bunu nota anında yansıtır.
Future<String?> showDictationSheet(
  BuildContext context, {
  ValueChanged<String>? onPartial,
}) => showModalBottomSheet<String>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  builder: (_) => _DictationSheet(onPartial: onPartial),
);

/// idle yalnızca "basılı tut" modunda görülür: kullanıcı düğmeyi tutana dek
/// dinleme başlamaz.
enum _Phase { idle, listening, processing, error }

class _DictationSheet extends ConsumerStatefulWidget {
  const _DictationSheet({this.onPartial});

  final ValueChanged<String>? onPartial;

  @override
  ConsumerState<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends ConsumerState<_DictationSheet> {
  AudioRecorder? _recorder;
  StreamSubscription<({String? text, double? level})>? _speechSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String _text = '';
  String? _recordPath;
  _Phase _phase = _Phase.idle;
  String _errorMessage = '';

  /// Yerleşik tanıma kullanılıyor mu (yoksa kayıt + toplu döküm).
  bool _useSpeech = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    _useSpeech = await DeviceSpeech.isAvailable();
    if (!mounted) return;
    setState(() => _ready = true);
    // Dokunmalı modda sayfa açılır açılmaz dinlemeye başla; basılı-tut
    // modunda kullanıcı düğmeyi tutana dek bekle.
    if (ref.read(voiceButtonModeProvider) == VoiceButtonMode.tap) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_phase == _Phase.listening) return;
    setState(() {
      _phase = _Phase.listening;
      _errorMessage = '';
    });
    final micDenied = context.l10n.micPermissionDenied;
    try {
      if (_useSpeech) {
        // İzin yokken SpeechRecognizer sormadan hata verir; önce iste.
        if (!await DeviceSpeech.ensureMicPermission()) {
          _fail(micDenied);
          return;
        }
        _speechSub = DeviceSpeech.listen().listen(
          (event) {
            // Dikte sayfasında ses seviyesi kullanılmaz; yalnız metin akar.
            final text = event.text;
            if (text == null) return;
            _text = text;
            widget.onPartial?.call(text);
            if (mounted) setState(() {});
          },
          onError: (Object e) {
            // Biriken metin korunur; kullanıcı "Bitir ve ekle" ile
            // kaydedebilsin diye hata yalnızca gösterilir.
            if (mounted) setState(() => _errorMessage = e.toString());
          },
        );
      } else {
        await _startRecording();
      }
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Yerleşik tanıma yoksa: dosyaya kaydet, bitince toplu döküm.
  Future<void> _startRecording() async {
    final micDenied = context.l10n.micPermissionDenied;
    final recorder = AudioRecorder();
    _recorder = recorder;
    if (!await recorder.hasPermission()) {
      _fail(micDenied);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = p.join(
      dir.path,
      'dikte_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _recordPath!,
    );
  }

  Future<void> _finish() async {
    if (_phase != _Phase.listening) return;
    final l10n = context.l10n;
    _ticker?.cancel();

    if (_useSpeech) {
      // Son sonucu al, akışı kapat.
      await DeviceSpeech.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _speechSub?.cancel();
      _speechSub = null;
      if (!mounted) return;
      final text = _text.trim();
      Navigator.pop(context, text.isEmpty ? null : text);
      return;
    }

    setState(() => _phase = _Phase.processing);
    try {
      final path = await _recorder?.stop();
      if (path == null) throw StateError(l10n.voiceNothingHeard);
      final bytes = await File(path).readAsBytes();
      File(path).delete().ignore();
      final text = await ref
          .read(geminiServiceProvider)
          .transcribeAudio(bytes, 'audio/mp4');
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
    await _teardown();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _speechSub?.cancel();
    _speechSub = null;
    try {
      final path = await _recorder?.stop();
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;
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
    _speechSub?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final holdMode = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: switch (_phase) {
          _ when !_ready => const Padding(
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
          // Basılı-tut modu: mikrofon düğmesi idle ve listening evrelerinde
          // AYNI ağaçta kalmalı — aksi hâlde parmak basılıyken düğme
          // ağaçtan kalkar ve bırakma olayı (onLongPressEnd) hiç gelmez.
          _ when holdMode => _holdView(l10n, scheme),
          _Phase.idle => const SizedBox.shrink(),
          _Phase.listening => Column(
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
                _useSpeech ? l10n.dictationListening : l10n.dictationNoKeyInfo,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (_useSpeech) ...[
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
                    child: Text(_text.isEmpty ? '…' : _text),
                  ),
                ),
              ],
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
              const SizedBox(height: 16),
              // Basılı-tut modunda kullanıcı düğmeyi bırakınca zaten biter;
              // yine de elle bitirme/iptal düğmeleri durur.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(onPressed: _cancel, child: Text(l10n.cancel)),
                  const SizedBox(width: 8),
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

  /// "Basılı tut" modu: tek düğme, parmak boyunca dinler. Düğme her iki
  /// evrede de aynı ağaçta kaldığı için bırakma olayı güvenle yakalanır.
  Widget _holdView(AppLocalizations l10n, ColorScheme scheme) {
    final listening = _phase == _Phase.listening;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startListening(),
          onLongPressEnd: (_) => _finish(),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: listening ? scheme.error : scheme.primaryContainer,
            child: Icon(
              Icons.mic,
              size: 36,
              color: listening ? scheme.onError : scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          listening ? _format(_elapsed) : l10n.dictationHoldHint,
          textAlign: TextAlign.center,
          style: listening ? Theme.of(context).textTheme.headlineSmall : null,
        ),
        if (listening && _useSpeech) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72, maxHeight: 180),
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
              child: Text(_text.isEmpty ? '…' : _text),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _cancel, child: Text(l10n.cancel)),
      ],
    );
  }
}
