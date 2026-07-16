import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/pdf_viewer_screen.dart';

/// Editörde gövdenin üstünde duran yatay ek şeridi.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<Attachment> attachments;
  final ValueChanged<Attachment> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _AttachmentTile(
          attachment: attachments[index],
          onRemove: () => onRemove(attachments[index]),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onRemove});

  final Attachment attachment;
  final VoidCallback onRemove;

  bool get _hasLocal =>
      attachment.localPath.isNotEmpty &&
      File(attachment.localPath).existsSync();

  void _open(BuildContext context) {
    if (!_hasLocal && !attachment.isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.attachmentNotSynced)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => attachment.kind == AttachmentKind.pdf
            ? PdfViewerScreen(attachment: attachment)
            : ImageViewerScreen(attachment: attachment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget content;
    if (attachment.kind == AttachmentKind.pdf) {
      content = Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: scheme.error, size: 28),
            const SizedBox(height: 6),
            Text(
              attachment.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    } else if (_hasLocal) {
      content = Image.file(
        File(attachment.localPath),
        width: 140,
        fit: BoxFit.cover,
      );
    } else if (attachment.isUploaded) {
      content = CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        width: 140,
        fit: BoxFit.cover,
      );
    } else {
      content = Container(
        width: 140,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 22, color: scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              context.l10n.attachmentNotSynced,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context),
            child: SizedBox(height: 98, child: content),
          ),
        ),
        // Yükleme sürüyor göstergesi
        if (!attachment.isUploaded && _hasLocal)
          Positioned(
            left: 6,
            bottom: 6,
            child: Tooltip(
              message: context.l10n.attachmentUploading,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 2,
          top: 2,
          child: IconButton(
            tooltip: context.l10n.removeAttachment,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.cancel, size: 18),
            color: Colors.white,
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
