import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../domain/attachment.dart';

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final hasLocal = attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync();

    Widget viewer;
    if (hasLocal) {
      viewer = PdfViewer.file(attachment.localPath);
    } else if (attachment.isUploaded) {
      viewer = PdfViewer.uri(Uri.parse(attachment.downloadUrl));
    } else {
      viewer = const Center(child: Icon(Icons.picture_as_pdf_outlined, size: 64));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(attachment.fileName, style: const TextStyle(fontSize: 14)),
      ),
      body: viewer,
    );
  }
}
