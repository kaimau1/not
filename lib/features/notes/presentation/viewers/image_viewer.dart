import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'image_crop.dart';
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
    this.onCrop,
  });

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  /// Kırpma dikdörtgenini (görsel oranında, 0–1) uygulayacak taraf. Kırpma
  /// dosyanın kendisini yeniden yazdığı için ek deposu ve not kimliği gerekir;
  /// ikisi de bu ekranda yok, o yüzden iş çağırana bırakılır. null ise kırpma
  /// düğmesi hiç çizilmez.
  final Future<void> Function(Attachment, Rect)? onCrop;

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

  /// Kırpma ekranını açar, seçilen alanı çağırana uygular ve tam ekrandan
  /// ÇIKAR: kırpma dosyayı yeniden yazdığından bu ekrandaki ek nesnesi (ve
  /// çizim denetleyicisi) anında bayatlar. Nota dönmek, kırpılmış hâli
  /// notun kendi tuvalinden göstermenin en kısa yolu.
  Future<void> _crop(double aspect) async {
    // Çizim açıkken kırpmaya geçilirse yarım kalan çizgi kaybolur.
    if (_editing) _ink.save();
    final rect = await Navigator.of(context).push<Rect>(
      MaterialPageRoute<Rect>(
        builder: (_) => ImageCropScreen(image: _provider(), aspect: aspect),
      ),
    );
    if (rect == null || !mounted) return;
    // Tüm görsel bir kez daha seçildiyse dosyayı boşuna yeniden yazma.
    if (rect.left <= 0 && rect.top <= 0 && rect.right >= 1 && rect.bottom >= 1) {
      Navigator.of(context).pop();
      return;
    }
    await widget.onCrop!(widget.attachment, rect);
    if (mounted) Navigator.of(context).pop();
  }

  /// Görselin kaynağı: yerel kopya → indirme adresi. Kırpma ekranı da aynı
  /// kaynağı kullanır ki seçilen alan gösterilenle birebir örtüşsün.
  ImageProvider _provider() {
    final a = widget.attachment;
    if (a.localPath.isNotEmpty && File(a.localPath).existsSync()) {
      return FileImage(File(a.localPath));
    }
    return CachedNetworkImageProvider(a.downloadUrl);
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
            // Kırpma çizim MODUNDA gizlenir: o an araç çubuğu kalem/silgi
            // için kullanılıyor, iki kip aynı anda anlamlı değil.
            if (widget.onCrop != null && !_editing)
              IconButton(
                tooltip: l10n.crop,
                icon: const Icon(Icons.crop),
                onPressed: () => _crop(aspect),
              ),
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
