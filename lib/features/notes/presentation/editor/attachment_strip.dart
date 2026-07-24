import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../viewers/slide_viewer_screen.dart';

/// Editörde gövdenin üstünde duran yatay ek şeridi.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
    this.onChanged,
  });

  final List<Attachment> attachments;
  final ValueChanged<Attachment> onRemove;

  /// PDF üzerine yapılan çizim kaydedilirken çağrılır; verilmezse PDF salt
  /// görüntülenir.
  final ValueChanged<Attachment>? onChanged;

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
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Ses eki: oynat/durdur düğmeli kompakt oynatıcı.
class _AudioTile extends StatefulWidget {
  const _AudioTile({required this.attachment});

  final Attachment attachment;

  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  final _player = AudioPlayer();
  bool _loaded = false;

  Future<void> _toggle() async {
    try {
      if (!_loaded) {
        final a = widget.attachment;
        if (a.localPath.isNotEmpty && File(a.localPath).existsSync()) {
          await _player.setFilePath(a.localPath);
        } else if (a.isUploaded) {
          await _player.setUrl(a.downloadUrl);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.attachmentNotSynced)),
            );
          }
          return;
        }
        _loaded = true;
      }
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.genericError(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              final completed =
                  snapshot.data?.processingState == ProcessingState.completed;
              return IconButton.filledTonal(
                onPressed: _toggle,
                icon: Icon(
                  playing && !completed ? Icons.pause : Icons.play_arrow,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            widget.attachment.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.onRemove,
    this.onChanged,
  });

  final Attachment attachment;
  final VoidCallback onRemove;
  final ValueChanged<Attachment>? onChanged;

  bool get _hasLocal =>
      attachment.localPath.isNotEmpty &&
      File(attachment.localPath).existsSync();

  void _open(BuildContext context) {
    // Ses eki için satır içi görüntüleyici yok (kompakt oynatıcıdan çalınır).
    if (attachment.kind == AttachmentKind.audio) return;
    if (!_hasLocal && !attachment.isUploaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.attachmentNotSynced)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (attachment.kind) {
          AttachmentKind.pdf => PdfViewerScreen(
            attachment: attachment,
            onChanged: onChanged,
          ),
          AttachmentKind.slide => SlideViewerScreen(
            attachment: attachment,
            onChanged: onChanged,
          ),
          _ => ImageViewerScreen(attachment: attachment),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget content;
    if (attachment.kind == AttachmentKind.audio) {
      content = _AudioTile(attachment: attachment);
    } else if (attachment.kind == AttachmentKind.pdf) {
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
    } else if (attachment.kind == AttachmentKind.slide) {
      content = Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.slideshow_outlined, color: scheme.tertiary, size: 28),
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
        // 140 dp'lik önizleme için tam boy çözdürme (bellek/CPU).
        cacheWidth: 420,
      );
    } else if (attachment.isUploaded) {
      content = CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        width: 140,
        fit: BoxFit.cover,
        memCacheWidth: 420,
      );
    } else {
      content = Container(
        width: 140,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
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
