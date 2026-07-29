import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'ink_layer.dart';

/// Tam ekran görsel görüntüleyici (yakınlaştırma/kaydırma destekli).
///
/// [onChanged] verilirse PDF/slaytta olduğu gibi görselin ÜZERİNE elle
/// yazılabilir: çizim görsel dosyasına gömülmez, ekin `ink` alanında görsel
/// oranlı (0–1) vektör olarak saklanır — notla birlikte senkronlanır, her
/// açılışta yeniden düzenlenebilir, silinebilir.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.attachment,
    this.onChanged,
  });

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onChanged?.call(widget.attachment.copyWith(ink: strokes)),
  );
  final _zoom = TransformationController();
  bool _editing = false;

  @override
  void dispose() {
    _ink.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = widget.attachment;
    Widget image;
    if (a.localPath.isNotEmpty && File(a.localPath).existsSync()) {
      image = Image.file(File(a.localPath), fit: BoxFit.contain);
    } else if (a.isUploaded) {
      image = CachedNetworkImage(
        imageUrl: a.downloadUrl,
        fit: BoxFit.contain,
        progressIndicatorBuilder: (context, url, progress) =>
            Center(child: CircularProgressIndicator(value: progress.progress)),
      );
    } else {
      image = const Icon(Icons.broken_image_outlined, size: 64);
    }

    // Çizim katmanı görselin KUTUSUYLA birebir aynı olmalı: oranlı noktalar
    // ancak o zaman yakınlaştırmada da görselin üstünde kalır. Bu yüzden
    // görsel, kendi en-boy oranındaki bir kutuya yerleştirilir.
    // ponytail: oranı bilinmeyen (eski) ekte kare varsayılır — not tuvali de
    // aynı varsayımı kullanıyor.
    final aspect = (a.width != null && a.height != null && a.height! > 0)
        ? a.width! / a.height!
        : 1.0;

    return PopScope(
      onPopInvokedWithResult: (_, _) => _ink.save(),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(a.fileName, style: const TextStyle(fontSize: 14)),
          actions: [
            if (widget.onChanged != null)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: aspect,
            // Çizimde InteractiveViewer'ın kendi jestleri kapalı: tek parmak
            // çizer, iki parmak yakınlaştırma/kaydırmayı InkNavLayer matrise
            // uygular (IV iki parmağın birlikte hareketini "pan" sayıp
            // panEnabled:false'ta yutuyor — bkz. ink_layer.dart).
            child: InkNavLayer(
              enabled: _editing,
              controller: _ink,
              getMatrix: () => _zoom.value,
              setMatrix: (m) => _zoom.value = m,
              minScale: 1,
              maxScale: 8,
              clampToBounds: true,
              child: InteractiveViewer(
                transformationController: _zoom,
                maxScale: 8,
                panEnabled: !_editing,
                scaleEnabled: !_editing,
                child: Stack(
                  children: [
                    Positioned.fill(child: image),
                    Positioned.fill(
                      child: InkPageLayer(controller: _ink, page: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : null,
      ),
    );
  }
}
