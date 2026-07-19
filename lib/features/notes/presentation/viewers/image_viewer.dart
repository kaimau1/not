import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/attachment.dart';

/// Tam ekran görsel görüntüleyici (yakınlaştırma/kaydırma destekli).
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync()) {
      image = Image.file(File(attachment.localPath), fit: BoxFit.contain);
    } else if (attachment.isUploaded) {
      image = CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        fit: BoxFit.contain,
        progressIndicatorBuilder: (context, url, progress) =>
            Center(child: CircularProgressIndicator(value: progress.progress)),
      );
    } else {
      image = const Icon(Icons.broken_image_outlined, size: 64);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(attachment.fileName, style: const TextStyle(fontSize: 14)),
      ),
      body: InteractiveViewer(maxScale: 8, child: Center(child: image)),
    );
  }
}
