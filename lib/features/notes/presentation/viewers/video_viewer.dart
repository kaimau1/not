import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

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
            : AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(controller),
                    VideoProgressIndicator(controller, allowScrubbing: true),
                  ],
                ),
              ),
      ),
      floatingActionButton: controller == null
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              }),
              child: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
    );
  }
}
