import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';

/// Notta gövdenin üstünde görselleri SATIR İÇİ gösterir; her görselin
/// genişliği ve yatay hizası elle ayarlanabilir. Bir görsele dokununca
/// düzenleme çubuğu açılır: sol/orta/sağ hiza, genişlik kaydırıcısı, tam
/// ekran ve kaldır. Tekrar dokununca kapanır.
class NoteImages extends StatefulWidget {
  const NoteImages({
    super.key,
    required this.images,
    required this.onRemove,
    required this.onChanged,
  });

  final List<Attachment> images;

  /// Görseli nottan kaldırır.
  final ValueChanged<Attachment> onRemove;

  /// Genişlik/hiza değişince güncellenmiş eki bildirir.
  final ValueChanged<Attachment> onChanged;

  @override
  State<NoteImages> createState() => _NoteImagesState();
}

class _NoteImagesState extends State<NoteImages> {
  /// Düzenleme çubuğu açık olan görselin id'si (null = hiçbiri).
  String? _editingId;

  /// Kaydırma sırasındaki canlı genişlik (akıcı önizleme); bırakınca kaydedilir.
  double? _liveWidth;

  Alignment _alignment(String a) => switch (a) {
    'left' => Alignment.centerLeft,
    'right' => Alignment.centerRight,
    _ => Alignment.center,
  };

  void _toggle(String id) {
    setState(() {
      if (_editingId == id) {
        _editingId = null;
      } else {
        _editingId = id;
      }
      _liveWidth = null;
    });
  }

  void _openViewer(Attachment img) {
    final hasLocal =
        img.localPath.isNotEmpty && File(img.localPath).existsSync();
    if (!hasLocal && !img.isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.attachmentNotSynced)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerScreen(attachment: img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final img in widget.images) _block(context, img)],
      ),
    );
  }

  Widget _block(BuildContext context, Attachment img) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _editingId == img.id;
    final double factor =
        (editing && _liveWidth != null
                ? _liveWidth!
                : (img.displayWidth ?? 1.0))
            .clamp(0.3, 1.0)
            .toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth * factor;
              return Align(
                alignment: _alignment(img.align),
                child: GestureDetector(
                  onTap: () => _toggle(img.id),
                  child: Container(
                    width: w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: editing
                          ? Border.all(color: scheme.primary, width: 2)
                          : Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _image(context, img),
                  ),
                ),
              );
            },
          ),
          if (editing) _controls(context, img, factor),
        ],
      ),
    );
  }

  Widget _image(BuildContext context, Attachment img) {
    final scheme = Theme.of(context).colorScheme;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : null;
    final hasLocal =
        img.localPath.isNotEmpty && File(img.localPath).existsSync();
    Widget raw;
    if (hasLocal) {
      raw = Image.file(File(img.localPath), fit: BoxFit.cover);
    } else if (img.isUploaded) {
      raw = CachedNetworkImage(imageUrl: img.downloadUrl, fit: BoxFit.cover);
    } else {
      raw = Container(
        height: 120,
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      );
    }
    if (aspect != null) return AspectRatio(aspectRatio: aspect, child: raw);
    return raw;
  }

  Widget _controls(BuildContext context, Attachment img, double factor) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _alignBtn(img, 'left', Icons.format_align_left),
          _alignBtn(img, 'center', Icons.format_align_center),
          _alignBtn(img, 'right', Icons.format_align_right),
          Expanded(
            child: Slider(
              value: factor,
              min: 0.3,
              max: 1,
              onChanged: (v) => setState(() => _liveWidth = v),
              onChangeEnd: (v) {
                widget.onChanged(img.copyWith(displayWidth: v));
                setState(() => _liveWidth = null);
              },
            ),
          ),
          IconButton(
            tooltip: 'Tam ekran',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.fullscreen, size: 20),
            onPressed: () => _openViewer(img),
          ),
          IconButton(
            tooltip: l10n.removeAttachment,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: scheme.error,
            onPressed: () => widget.onRemove(img),
          ),
        ],
      ),
    );
  }

  Widget _alignBtn(Attachment img, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final selected = img.align == value;
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20),
      color: selected ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => widget.onChanged(img.copyWith(align: value)),
    );
  }
}
