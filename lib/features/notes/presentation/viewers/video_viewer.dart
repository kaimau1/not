import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// Süreyi `s:sn` (bir saatten uzunsa `s:dd:sn`) olarak yazar.
String formatVideoPosition(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final hours = total.inHours;
  final minutes = total.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = total.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Görüntülü notu uygulama içinde oynatır. Video yalnızca cihazda saklandığı
/// için kaynak her zaman yerel dosyadır (buluta yüklenmez — bkz.
/// [AttachmentRepository.prepareVideo]); dosya yoksa net bir uyarı gösterilir.
class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({super.key, required this.attachment});

  final Attachment attachment;

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  VideoPlayerController? _controller;
  Object? _error;

  /// Sürükleme sırasındaki geçici konum (ms). Sürüklerken oynatıcının kendi
  /// konumunu kullanmak kaydırıcıyı parmağın altından kaçırıyordu: her kare
  /// gelen `position` değeri, henüz uygulanmamış sürükleme değerinin üstüne
  /// yazıyordu. Parmak kalkınca [_seekTo] ile bir kez uygulanır.
  double? _dragMs;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final path = widget.attachment.localPath;
    if (path.isEmpty || !File(path).existsSync()) {
      setState(() => _error = 'missing');
      return;
    }
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _seekTo(VideoPlayerController controller, Duration target) async {
    final duration = controller.value.duration;
    var clamped = target;
    if (clamped < Duration.zero) clamped = Duration.zero;
    if (duration > Duration.zero && clamped > duration) clamped = duration;
    await controller.seekTo(clamped);
  }

  /// ±10 sn atlama düğmeleri: kaydırıcıyla hassas nokta bulmak zor, kısa
  /// atlamalar en sık istenen hareket.
  Future<void> _skip(VideoPlayerController controller, int seconds) =>
      _seekTo(controller, controller.value.position + Duration(seconds: seconds));

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.attachmentNotSynced,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : controller == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio == 0
                          ? 16 / 9
                          : controller.value.aspectRatio,
                      child: GestureDetector(
                        // Görüntüye dokunmak oynat/durdur — en sık istenen
                        // hareket için düğmeye uzanmak gerekmesin.
                        onTap: () => controller.value.isPlaying
                            ? controller.pause()
                            : controller.play(),
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  _Controls(
                    controller: controller,
                    dragMs: _dragMs,
                    onDragChanged: (ms) => setState(() => _dragMs = ms),
                    onDragEnd: (ms) async {
                      await _seekTo(
                        controller,
                        Duration(milliseconds: ms.round()),
                      );
                      if (mounted) setState(() => _dragMs = null);
                    },
                    onSkip: (seconds) => _skip(controller, seconds),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Oynatıcı çubuğu: geçen süre / toplam süre, sürüklenebilir konum kaydırıcısı
/// ve ±10 sn + oynat/durdur düğmeleri. Eskiden yalnızca ince bir
/// [VideoProgressIndicator] vardı — dakika seçmek, geri sarmak ya da kalan
/// süreyi görmek mümkün değildi.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.dragMs,
    required this.onDragChanged,
    required this.onDragEnd,
    required this.onSkip,
  });

  final VideoPlayerController controller;
  final double? dragMs;
  final ValueChanged<double> onDragChanged;
  final ValueChanged<double> onDragEnd;
  final ValueChanged<int> onSkip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final durationMs = value.duration.inMilliseconds;
        // Süresi bilinmeyen/0 olan videoda Slider min==max ile çökerdi.
        final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
        final positionMs = (dragMs ?? value.position.inMilliseconds.toDouble())
            .clamp(0.0, maxMs)
            .toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  trackHeight: 3,
                ),
                child: Slider(
                  value: positionMs,
                  max: maxMs,
                  onChanged: durationMs > 0 ? onDragChanged : null,
                  onChangeEnd: durationMs > 0 ? onDragEnd : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      formatVideoPosition(
                        Duration(milliseconds: positionMs.round()),
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      formatVideoPosition(value.duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: context.l10n.videoBack10,
                    color: Colors.white,
                    iconSize: 30,
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => onSkip(-10),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    iconSize: 34,
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () =>
                        value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: context.l10n.videoForward10,
                    color: Colors.white,
                    iconSize: 30,
                    icon: const Icon(Icons.forward_10),
                    onPressed: () => onSkip(10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
