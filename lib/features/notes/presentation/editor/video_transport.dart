import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/video_time.dart';
import '../../domain/attachment.dart';
import 'video_hub_scope.dart';

/// VİDEONUN ALTINDAKİ DENETİM: ⏪ 10 sn · ▶/⏸ · 10 sn ⏩ (+ "1:23 / 4:56").
///
/// Kullanıcı isteği 2026-10-16: "videolarda hemen altındaki çubukta oynatma,
/// durdurma, 10 sn sarma butonları olsun". Eskiden notun içindeki videoda
/// yalnız ortada bir oynat/durdur vardı; YouTube'da sarmak için oynatıcının
/// kendi küçük düğmeleri, yerel videoda ise tam ekran gerekiyordu.
///
/// Oynatıcıya notun video merkezinden ([NoteVideoHub]) ulaşılır: oynatıcı
/// kutusu hazır olunca kendini kaydeder, çubuk kaydı ([NoteVideoHub.revision])
/// ve oynatıcının durumunu ([VideoTimeSource.changes]) dinler — yalnız bu
/// küçük satır tazelenir, video kutusu yeniden kurulmaz.
///
/// YouTube kapağı henüz oynatılmadıysa (oynatıcı yok) ▶ oynatıcıyı kurar
/// ([NoteVideoHub.requestStart]); sarma düğmeleri o zamana dek kapalı.
class VideoTransportControls extends StatelessWidget {
  const VideoTransportControls({
    super.key,
    required this.video,
    this.showTime = true,
    this.onDark = false,
    this.iconSize = 22,
    this.showSpeed = false,
  });

  /// Oynatma hızı düğmesi ("1×" → 1.25× → 1.5× → 2× → 0.5× → 0.75×).
  final bool showSpeed;

  final Attachment video;

  /// Konum/süre yazısı (dar yerde kapatılır).
  final bool showTime;

  /// Koyu zemin üstünde (videonun içindeki şerit): beyaz simgeler.
  final bool onDark;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: hub.revision,
      builder: (context, _, _) {
        final source = hub.sourceFor(video.id);
        if (source == null) return _row(context, hub, null);
        return ListenableBuilder(
          listenable: source.changes,
          builder: (context, _) => _row(context, hub, source),
        );
      },
    );
  }

  Widget _row(BuildContext context, NoteVideoHub hub, VideoTimeSource? source) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = onDark ? Colors.white : scheme.onSurface;
    final playing = source?.isPlaying ?? false;
    // Oynatıcısı olmayan YouTube'u ▶ kurar; dosyası olmayan yerel video
    // (başka cihazda yer tutucu) için düğmeler kapalı.
    final canStart = source != null || video.isWebVideo;
    final position = source?.lastPosition;
    final duration = source?.duration;
    Widget button({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      Key? key,
      bool primary = false,
    }) => IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: iconSize + (primary ? 22 : 16),
        height: iconSize + 16,
      ),
      iconSize: primary ? iconSize + 4 : iconSize,
      color: color,
      disabledColor: color.withValues(alpha: 0.35),
      icon: Icon(icon),
      onPressed: onPressed,
    );

    void seek(int seconds) {
      final s = source;
      if (s == null) return;
      hub.touch(s);
      s.seekBy(Duration(seconds: seconds));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          key: const ValueKey('video-back-10'),
          icon: Icons.replay_10_rounded,
          tooltip: l10n.videoBack10,
          onPressed: source == null ? null : () => seek(-10),
        ),
        button(
          key: const ValueKey('video-play-pause'),
          icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          tooltip: playing ? l10n.mediaPause : l10n.mediaPlay,
          primary: true,
          onPressed: !canStart
              ? null
              : () {
                  final s = source;
                  if (s == null) {
                    hub.requestStart(video.id, null);
                    return;
                  }
                  hub.touch(s);
                  playing ? s.pause() : s.play();
                },
        ),
        button(
          key: const ValueKey('video-forward-10'),
          icon: Icons.forward_10_rounded,
          tooltip: l10n.videoForward10,
          onPressed: source == null ? null : () => seek(10),
        ),
        if (showSpeed && source != null)
          Tooltip(
            message: l10n.videoSpeed,
            child: InkWell(
              key: const ValueKey('video-speed'),
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                hub.touch(source);
                source.setSpeed(nextVideoSpeed(source.speed));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  formatVideoSpeed(source.speed),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: source.speed == 1
                        ? color.withValues(alpha: 0.8)
                        : (onDark ? Colors.amberAccent : scheme.primary),
                  ),
                ),
              ),
            ),
          ),
        if (showTime && position != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 2),
            child: Text(
              duration == null
                  ? formatVideoTimestamp(position)
                  : '${formatVideoTimestamp(position)} / '
                        '${formatVideoTimestamp(duration)}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.85),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

/// Videonun ilerleme çizgisi (yalnız gösterir): denetim çubuğunun üst
/// kenarında ince bir şerit. Oynatıcı yoksa ya da süre bilinmiyorsa boş.
class VideoProgressLine extends StatelessWidget {
  const VideoProgressLine({super.key, required this.video, this.height = 2});

  final Attachment video;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return SizedBox(height: height);
    final color = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<int>(
      valueListenable: hub.revision,
      builder: (context, _, _) {
        final source = hub.sourceFor(video.id);
        if (source == null) return SizedBox(height: height);
        return ListenableBuilder(
          listenable: source.changes,
          builder: (context, _) {
            final p = source.lastPosition;
            final d = source.duration;
            final fraction = p == null || d == null || d <= Duration.zero
                ? 0.0
                : (p.inMilliseconds / d.inMilliseconds).clamp(0.0, 1.0);
            return SizedBox(
              height: height,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  child: ColoredBox(color: color),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
