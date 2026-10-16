import 'package:flutter/widgets.dart';

import '../../../../core/utils/video_time.dart';

/// Editörün [NoteVideoHub]'ını alt ağaca (sayfa tuvali, sabit bölme, video
/// kutuları) taşır. Merkezin KİMLİĞİ editör boyunca sabit olduğundan
/// bağımlılık kurulmaz (`getInheritedWidgetOfExactType`) — oynatıcı
/// kayıtları hiçbir yeniden çizim tetiklemez.
class VideoHubScope extends InheritedWidget {
  const VideoHubScope({super.key, required this.hub, required super.child});

  final NoteVideoHub hub;

  static NoteVideoHub? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<VideoHubScope>()?.hub;

  @override
  bool updateShouldNotify(VideoHubScope oldWidget) =>
      !identical(hub, oldWidget.hub);
}
