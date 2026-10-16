import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/local_file.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/utils/pip.dart';
import '../../../../core/utils/video_time.dart';
import '../../domain/attachment.dart';
import '../editor/video_transport.dart' show SeekIcon;
import 'youtube_viewer.dart';

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
///
/// YouTube eki ([Attachment.isWebVideo]) gömülü oynatıcıya gider — videoyu
/// açan her yer (sayfa, şerit, liste) aynı tek girişi kullanır.
class VideoViewerScreen extends StatelessWidget {
  const VideoViewerScreen({
    super.key,
    required this.attachment,
    this.start,
    this.onNoteAt,
  });

  final Attachment attachment;

  /// Açılış konumu (nottaki zaman damgasına dokunulduysa).
  final Duration? start;

  /// "Bu ana not al": verilirse üst çubukta düğme çıkar; basınca ekran
  /// kapanır ve not o anın damgasıyla açılır (bkz. editör `_noteAtVideoTime`).
  final ValueChanged<Duration>? onNoteAt;

  @override
  Widget build(BuildContext context) => attachment.isWebVideo
      ? YouTubeViewerScreen(
          attachment: attachment,
          start: start,
          onNoteAt: onNoteAt,
        )
      : _LocalVideoViewer(
          attachment: attachment,
          start: start,
          onNoteAt: onNoteAt,
        );
}

/// Tam ekran oynatıcıların üst çubuğundaki "Bu ana not al" düğmesi.
class NoteAtTimeButton extends StatelessWidget {
  const NoteAtTimeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Customizable(
    // Kişiselleştirmede gizlenebilir (bkz. UiItem.videoNoteAt).
    id: UiItem.videoNoteAt,
    child: _button(context),
  );

  Widget _button(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.more_time, size: 18),
      label: Text(context.l10n.videoNoteAtTime),
    ),
  );
}

class _LocalVideoViewer extends StatefulWidget {
  const _LocalVideoViewer({required this.attachment, this.start, this.onNoteAt});

  final Attachment attachment;
  final Duration? start;
  final ValueChanged<Duration>? onNoteAt;

  @override
  State<_LocalVideoViewer> createState() => _LocalVideoViewerState();
}

class _LocalVideoViewerState extends State<_LocalVideoViewer> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _pipSupported = false;

  /// Videonun en-boy oranı (PiP penceresi buna göre açılır).
  Size get _aspect {
    final size = _controller?.value.size;
    return size == null || size.isEmpty ? const Size(16, 9) : size;
  }

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
    if (path.isEmpty || !localFileExists(path)) {
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
      final start = widget.start;
      if (start != null && start > Duration.zero) {
        await controller.seekTo(start);
      }
      setState(() => _controller = controller);
      // Oynarken ana ekrana çıkmak küçük pencereye alır (bkz. youtube_viewer).
      unawaited(PictureInPicture.setAuto(true, aspect: _aspect));
      final pip = await PictureInPicture.supported();
      if (mounted) setState(() => _pipSupported = pip);
      await controller.play();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    PictureInPicture.setAuto(false);
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

  /// Geri/ileri atlama düğmeleri (süreler kişiselleştirmeden — bkz.
  /// Personalize): kaydırıcıyla hassas nokta bulmak zor, kısa atlamalar en
  /// sık istenen hareket.
  Future<void> _skip(VideoPlayerController controller, int seconds) =>
      _seekTo(controller, controller.value.position + Duration(seconds: seconds));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: PictureInPicture.active,
    builder: (context, inPip, _) => _build(context, inPip),
  );

  Widget _build(BuildContext context, bool inPip) {
    final controller = _controller;
    // KÜÇÜK PENCEREDE yalnız video: çubuklar dokunulamaz ve yer kaplar.
    if (inPip && controller != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (widget.onNoteAt != null && controller != null)
            NoteAtTimeButton(
              onPressed: () {
                final position = controller.value.position;
                controller.pause();
                Navigator.of(context).pop();
                widget.onNoteAt!(position);
              },
            ),
          if (_pipSupported && controller != null)
            IconButton(
              tooltip: context.l10n.pictureInPicture,
              icon: const Icon(Icons.picture_in_picture_alt),
              onPressed: () => PictureInPicture.enter(aspect: _aspect),
            ),
        ],
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
                  // HIZ (0.5×–2×): dokundukça sıradakine geçer.
                  SizedBox(
                    width: 56,
                    child: TextButton(
                      key: const ValueKey('viewer-video-speed'),
                      style: TextButton.styleFrom(
                        foregroundColor: value.playbackSpeed == 1
                            ? Colors.white70
                            : Colors.amberAccent,
                      ),
                      onPressed: () => controller.setPlaybackSpeed(
                        nextVideoSpeed(value.playbackSpeed),
                      ),
                      child: Text(
                        formatVideoSpeed(value.playbackSpeed),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('viewer-video-back'),
                    tooltip: context.l10n.videoBackSeconds(
                      Personalize.current.seekBack,
                    ),
                    color: Colors.white,
                    iconSize: 30,
                    icon: SeekIcon(
                      seconds: Personalize.current.seekBack,
                      forward: false,
                      size: 30,
                    ),
                    onPressed: () => onSkip(-Personalize.current.seekBack),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: value.isPlaying
                        ? context.l10n.mediaPause
                        : context.l10n.mediaPlay,
                    iconSize: 34,
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () =>
                        value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey('viewer-video-forward'),
                    tooltip: context.l10n.videoForwardSeconds(
                      Personalize.current.seekForward,
                    ),
                    color: Colors.white,
                    iconSize: 30,
                    icon: SeekIcon(
                      seconds: Personalize.current.seekForward,
                      forward: true,
                      size: 30,
                    ),
                    onPressed: () => onSkip(Personalize.current.seekForward),
                  ),
                  // DÖNGÜ: video bitince baştan.
                  SizedBox(
                    width: 56,
                    child: IconButton(
                      key: const ValueKey('viewer-video-loop'),
                      tooltip: context.l10n.videoLoop,
                      isSelected: value.isLooping,
                      color: Colors.white70,
                      selectedIcon: const Icon(
                        Icons.repeat_on_rounded,
                        color: Colors.amberAccent,
                      ),
                      icon: const Icon(Icons.repeat_rounded),
                      onPressed: () => controller.setLooping(!value.isLooping),
                    ),
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
