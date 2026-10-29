import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constants.dart';
import '../../../../core/error_log.dart';
import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// Kaydedicinin evresi.
enum VoiceRecordPhase { starting, recording, paused, finishing }

/// Biten kaydın sonucu: dosya, süre ve [Attachment.wave] için dalga.
typedef VoiceRecording = ({String path, Duration duration, List<int> wave});

/// **NOTUN İÇİNDE SESLİ NOT** (kullanıcı isteği 2026-10-28: "sesli not kısmı
/// güzel eklenebilir" — örnek uygulamada kayıt notun içinde, canlı dalgayla
/// sürüyor).
///
/// Eskiden kayıt ekranı örten bir levhaydı: kayıt sürerken nota yazılamıyor,
/// ne kaydedildiği görünmüyordu. Artık kayıt editörün alt şeridinde bir
/// HAP olarak sürer ([VoiceRecordPanel]); kullanıcı kayıt sürerken yazmaya
/// devam eder. Mikrofon genliği ~14 kez/sn ölçülür: hem canlı dalgayı çizer
/// hem bitince ekin kalıcı dalgası olur ([Attachment.compactWave]).
class VoiceNoteRecorder extends ChangeNotifier {
  VoiceNoteRecorder({AudioRecorder? recorder}) : _given = recorder;

  /// Kayıt tavanı: hap açık unutulursa mikrofon + kodlayıcı süresiz
  /// çalışmasın; o ana kadarki kayıt KAYDEDİLEREK biter ([onLimit]).
  static const maxDuration = Duration(minutes: 10);

  /// Genlik örnekleme aralığı.
  static const sampleEvery = Duration(milliseconds: 70);

  /// Eklenti kaydedicisi TEMBEL kurulur (kurucusu platform kanalına gider;
  /// hap çizilip kayıt başlamadan önce gerek yok).
  final AudioRecorder? _given;
  AudioRecorder? _created;
  AudioRecorder get _recorder => _created ??= _given ?? AudioRecorder();
  final Stopwatch _clock = Stopwatch();
  StreamSubscription<Amplitude>? _amplitude;
  Timer? _ticker;
  String? _path;
  bool _disposed = false;

  /// Tavana ulaşılınca çağrılır (editör kaydı bitirip ekler).
  VoidCallback? onLimit;

  VoiceRecordPhase _phase = VoiceRecordPhase.starting;
  VoiceRecordPhase get phase => _phase;

  /// Ölçülen genlikler (0–1), en eskisi başta.
  final List<double> levels = [];

  Duration get elapsed => _clock.elapsed;

  bool get isPaused => _phase == VoiceRecordPhase.paused;

  /// Kaydı başlatır. İzin yoksa ya da mikrofon açılamazsa hata METNİ döner
  /// (çağıran gösterir); başarıda null.
  Future<String?> start(BuildContext context) async {
    final l10n = context.l10n;
    try {
      if (!await _recorder.hasPermission()) return l10n.micPermissionDenied;
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'kayit_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      // Ayar ses kaydı levhasıyla aynı (bkz. AppConstants.audioBitRate):
      // tek kanal 32 kbps konuşmada duyulur fark yaratmaz.
      await _recorder.start(
        const RecordConfig(
          bitRate: AppConstants.audioBitRate,
          sampleRate: AppConstants.audioSampleRate,
          numChannels: 1,
        ),
        path: path,
      );
      if (_disposed) {
        await _recorder.stop();
        File(path).delete().ignore();
        return null;
      }
      _path = path;
      _clock.start();
      _phase = VoiceRecordPhase.recording;
      _amplitude = _recorder
          .onAmplitudeChanged(sampleEvery)
          .listen(_onAmplitude, onError: (_) {});
      // Süre yazısı genlik gelmese de (bazı cihazlar sessizlikte olay
      // yollamıyor) saniyede birkaç kez tazelenir.
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (_clock.elapsed >= maxDuration) {
          _ticker?.cancel();
          onLimit?.call();
          return;
        }
        notifyListeners();
      });
      notifyListeners();
      unawaited(HapticFeedback.mediumImpact());
      return null;
    } catch (e, s) {
      ErrorLog.record('voice note start', e, s);
      return l10n.attachmentFailed('$e');
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (_phase != VoiceRecordPhase.recording) return;
    levels.add(levelOfDb(amp.current));
    notifyListeners();
  }

  /// dBFS → 0–1. Konuşma kabaca −45…−8 dB arasında gezer; altı sessizlik.
  /// Kök alma alçak sesleri biraz kaldırır (fısıltı da dalgada görünsün).
  @visibleForTesting
  static double levelOfDb(double db) {
    if (db.isNaN || db.isInfinite) return 0;
    final v = ((db + 48) / 42).clamp(0.0, 1.0);
    return math.sqrt(v);
  }

  Future<void> togglePause() async {
    try {
      if (_phase == VoiceRecordPhase.recording) {
        await _recorder.pause();
        _clock.stop();
        _phase = VoiceRecordPhase.paused;
      } else if (_phase == VoiceRecordPhase.paused) {
        await _recorder.resume();
        _clock.start();
        _phase = VoiceRecordPhase.recording;
      }
      unawaited(HapticFeedback.selectionClick());
      notifyListeners();
    } catch (e, s) {
      ErrorLog.record('voice note pause', e, s);
    }
  }

  /// Kaydı bitirir; sonuç yoksa (hiç başlamadı, dosya yazılmadı) null.
  Future<VoiceRecording?> stop() async {
    if (_phase == VoiceRecordPhase.finishing) return null;
    _phase = VoiceRecordPhase.finishing;
    _ticker?.cancel();
    await _amplitude?.cancel();
    _amplitude = null;
    _clock.stop();
    notifyListeners();
    try {
      final path = await _recorder.stop() ?? _path;
      if (path == null) return null;
      return (
        path: path,
        duration: _clock.elapsed,
        wave: Attachment.compactWave(levels),
      );
    } catch (e, s) {
      ErrorLog.record('voice note stop', e, s);
      return null;
    }
  }

  /// Kaydı ATAR (dosya silinir).
  Future<void> cancel() async {
    _phase = VoiceRecordPhase.finishing;
    _ticker?.cancel();
    await _amplitude?.cancel();
    _amplitude = null;
    _clock.stop();
    try {
      final path = await _recorder.stop() ?? _path;
      if (path != null) File(path).delete().ignore();
    } catch (e, s) {
      ErrorLog.record('voice note cancel', e, s);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _amplitude?.cancel();
    final recorder = _created;
    if (recorder != null) unawaited(recorder.dispose());
    super.dispose();
  }
}

/// `00:04` biçimi (saat varsa `1:02:03`).
String formatClock(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// Kayıt sürerken editörün alt şeridindeki HAP: kırmızı durdur, süre, canlı
/// dalga, duraklat ve at. Hap kendi kendine yeniden çizilir (kaydedicinin
/// her genlik olayında yalnız bu parça).
class VoiceRecordPanel extends StatelessWidget {
  const VoiceRecordPanel({
    super.key,
    required this.recorder,
    required this.onStop,
    required this.onCancel,
  });

  final VoiceNoteRecorder recorder;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    const red = Color(0xFFE5483B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Material(
        key: const ValueKey('voice-record-panel'),
        color: Color.alphaBlend(
          red.withValues(alpha: 0.05),
          scheme.surfaceContainerHigh,
        ),
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 64,
          child: ListenableBuilder(
            listenable: recorder,
            builder: (context, _) {
              final paused = recorder.isPaused;
              final busy = recorder.phase == VoiceRecordPhase.finishing;
              return Row(
                children: [
                  const SizedBox(width: 10),
                  // DURDUR: kırmızı halka içinde kare — örnek uygulamadaki
                  // gibi "kaydı bitir" tek bakışta anlaşılır.
                  Tooltip(
                    message: l10n.stopAndSave,
                    child: InkResponse(
                      onTap: busy ? null : onStop,
                      radius: 26,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: red, width: 2.2),
                        ),
                        alignment: Alignment.center,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: red,
                                ),
                              )
                            : Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _BlinkDot(active: !paused && !busy, color: red),
                  const SizedBox(width: 6),
                  Text(
                    formatClock(recorder.elapsed),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: paused
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(double.infinity, 40),
                        painter: LiveWavePainter(
                          levels: recorder.levels,
                          length: recorder.levels.length,
                          color: paused
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          dotColor: scheme.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: paused ? l10n.voiceRecordResume : l10n.mediaPause,
                    onPressed: busy ? null : recorder.togglePause,
                    icon: Icon(
                      paused ? Icons.mic_rounded : Icons.pause_rounded,
                      color: paused ? red : scheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.voiceRecordDiscard,
                    onPressed: busy ? null : onCancel,
                    icon: Icon(
                      Icons.close_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Kayıt sürerken yanıp sönen küçük kırmızı nokta.
class _BlinkDot extends StatefulWidget {
  const _BlinkDot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BlinkDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.25, end: 1).animate(_c),
    child: Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// Canlı kayıt dalgası: geçmiş genlikler soldan sağa çubuk, kalan yer nokta.
/// Hap dolunca en yeni örnekler görünür (dalga sola akar).
class LiveWavePainter extends CustomPainter {
  LiveWavePainter({
    required this.levels,
    required this.length,
    required this.color,
    required this.dotColor,
  });

  final List<double> levels;

  /// Liste yerinde büyüdüğü için yeniden çizim kararı uzunluktan verilir.
  final int length;
  final Color color;
  final Color dotColor;

  static const double _step = 5.5;
  static const double _bar = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final slots = (size.width / _step).floor();
    if (slots <= 0) return;
    final mid = size.height / 2;
    final bar = Paint()
      ..color = color
      ..strokeWidth = _bar
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = dotColor;
    final quiet = Paint()..color = color;
    final shown = math.min(slots, length);
    final from = length - shown;
    for (var i = 0; i < slots; i++) {
      final x = i * _step + _bar / 2;
      if (i < shown) {
        final v = levels[from + i];
        final half = math.max(1.4, v * (size.height / 2 - 2));
        if (half <= 1.6) {
          canvas.drawCircle(Offset(x, mid), 1.4, quiet);
        } else {
          canvas.drawLine(Offset(x, mid - half), Offset(x, mid + half), bar);
        }
      } else {
        canvas.drawCircle(Offset(x, mid), 1.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(LiveWavePainter old) =>
      old.length != length || old.color != color || old.dotColor != dotColor;
}

/// Kaydedilmiş sesin dalgası: [wave] (0–100) genişliğe sığacak çubuklara
/// yeniden örneklenir; [progress]in solu dolu renkte, sağı soluk.
class WaveformBarsPainter extends CustomPainter {
  WaveformBarsPainter({
    required this.wave,
    required this.progress,
    required this.active,
    required this.inactive,
  });

  final List<int> wave;
  final double progress;
  final Color active;
  final Color inactive;

  static const double _step = 6.0;
  static const double _bar = 2.8;

  @override
  void paint(Canvas canvas, Size size) {
    if (wave.isEmpty) return;
    final slots = (size.width / _step).floor();
    if (slots <= 0) return;
    final mid = size.height / 2;
    final on = Paint()
      ..color = active
      ..strokeWidth = _bar
      ..strokeCap = StrokeCap.round;
    final off = Paint()
      ..color = inactive
      ..strokeWidth = _bar
      ..strokeCap = StrokeCap.round;
    // Kalan genişlik iki yana bölünür: dalga hapın ortasında dursun.
    final pad = (size.width - (slots - 1) * _step - _bar) / 2;
    for (var i = 0; i < slots; i++) {
      final from = (i * wave.length / slots).floor();
      final to = math.max(from + 1, ((i + 1) * wave.length / slots).ceil());
      var peak = 0;
      for (var j = from; j < to && j < wave.length; j++) {
        if (wave[j] > peak) peak = wave[j];
      }
      final v = peak / 100;
      final half = math.max(_bar / 2, (0.16 + 0.84 * v) * (mid - 1));
      final x = pad + _bar / 2 + i * _step;
      final played = (i + 0.5) / slots <= progress;
      canvas.drawLine(
        Offset(x, mid - half),
        Offset(x, mid + half),
        played ? on : off,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformBarsPainter old) =>
      old.progress != progress ||
      !identical(old.wave, wave) ||
      old.active != active ||
      old.inactive != inactive;
}
