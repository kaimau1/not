import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../../../core/utils/local_file.dart';
import '../../data/scan/scan_ocr.dart';
import '../editor/note_images.dart';

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

  // ── Görseldeki METNİ TANI (kullanıcı isteği 2026-08-09) ──────────────────
  // Görsele bakarken üzerindeki yazıyı seçip kopyalamanın tek yolu, notun
  // gövdesine OCR metni yazdıran "Metni al" akışıydı: model çağırıyor, AI
  // puanı yakıyor ve sonucu notun İÇİNE döküyordu — sadece bir telefon
  // numarasını kopyalamak isteyen kullanıcı için fazlasıyla ağır. Buradaki
  // yol tamamen CİHAZ İÇİ (ML Kit, bkz. [ScanOcr]): internet gerekmez, puan
  // harcamaz; tanınan satırlar görselin üstünde kutu kutu belirir, dokunulan
  // satır seçilir ve panoya kopyalanır.

  /// Tanınan satırlar (kutular GÖRSEL PİKSEL uzayında).
  List<OcrLine>? _ocrLines;

  /// Tanıma sürüyor mu (çip gösterilir).
  bool _ocrBusy = false;

  /// Katman açık mı — düğme aç/kapa yapar.
  bool _ocrOn = false;

  /// Seçili satırların [_ocrLines] içindeki indeksleri.
  final _ocrSelected = <int>{};

  /// Metin tanıma bu ekte mümkün mü: ML Kit yalnız mobilde var, OCR da
  /// dosyanın YEREL kopyasını okur (buluttaki kopya indirilmeden olmaz) ve
  /// kutuları yerleştirmek için görselin piksel ölçüsü gerekir.
  bool get _ocrAvailable {
    final a = widget.attachment;
    return ScanOcr.supported &&
        a.localPath.isNotEmpty &&
        localFileExists(a.localPath) &&
        (a.width ?? 0) > 0 &&
        (a.height ?? 0) > 0;
  }

  Future<void> _toggleOcr() async {
    if (_ocrOn) {
      setState(() {
        _ocrOn = false;
        _ocrSelected.clear();
      });
      return;
    }
    if (_ocrLines != null) {
      setState(() => _ocrOn = true);
      return;
    }
    setState(() => _ocrBusy = true);
    List<OcrLine> lines;
    try {
      lines = await ScanOcr.recognizeImageLines(widget.attachment.localPath);
    } catch (_) {
      lines = const [];
    }
    if (!mounted) return;
    setState(() {
      _ocrBusy = false;
      _ocrLines = lines;
      _ocrOn = true;
    });
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.imageOcrNone)));
    }
  }

  /// Seçili satırlar (hiçbiri seçili değilse TÜMÜ) — okuma sırasına göre.
  String _ocrText() {
    final lines = _ocrLines ?? const <OcrLine>[];
    final indexes = _ocrSelected.isEmpty
        ? [for (var i = 0; i < lines.length; i++) i]
        : (_ocrSelected.toList()..sort());
    return [for (final i in indexes) lines[i].text].join('\n');
  }

  Future<void> _copyOcr() async {
    final text = _ocrText();
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

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
    if (rect.left <= 0 &&
        rect.top <= 0 &&
        rect.right >= 1 &&
        rect.bottom >= 1) {
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
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      return FileImage(File(a.localPath));
    }
    return CachedNetworkImageProvider(a.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = widget.attachment;
    Widget image;
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      // Çözünürlük kovası: ekler 1600 px'e kadar olabiliyor ve tam
      // çözünürlük çözmek ~10 MB'lık bir bitmap demek. Yakınlaştırma için pay
      // bırakılır (2×), gerisi boşuna bellek.
      image = Image.file(
        File(a.localPath),
        fit: BoxFit.contain,
        cacheWidth: decodeWidthBucket(
          MediaQuery.sizeOf(context).width * 2,
          MediaQuery.devicePixelRatioOf(context),
        ),
      );
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
                    // Tanınan metin katmanı görselin KUTUSUNUN İÇİNDE:
                    // yakınlaştırıldığında kutular yazının üstünde kalsın
                    // diye InteractiveViewer'ın çocuğu olarak duruyor.
                    if (_ocrOn && (_ocrLines?.isNotEmpty ?? false))
                      Positioned.fill(
                        child: _OcrTextLayer(
                          lines: _ocrLines!,
                          imageSize: Size(
                            (a.width ?? 1).toDouble(),
                            (a.height ?? 1).toDouble(),
                          ),
                          selected: _ocrSelected,
                          onToggle: (i) => setState(() {
                            if (!_ocrSelected.remove(i)) _ocrSelected.add(i);
                          }),
                        ),
                      ),
                    Positioned.fill(
                      child: InkPageLayer(controller: _ink, page: 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Metni tanı düğmesi: çizim kipinde gizlenir (o an araç çubuğu
        // kalem/silgi için kullanılıyor).
        floatingActionButton: !_ocrAvailable || _editing
            ? null
            : FloatingActionButton(
                heroTag: 'image-ocr',
                tooltip: l10n.imageOcrTitle,
                onPressed: _ocrBusy ? null : _toggleOcr,
                child: _ocrBusy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(
                        _ocrOn
                            ? Icons.text_fields
                            : Icons.text_fields_outlined,
                      ),
              ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : (_ocrOn && (_ocrLines?.isNotEmpty ?? false)
                  ? _ocrBar(l10n)
                  : null),
      ),
    );
  }

  /// Tanınan metnin alt çubuğu: kaç satır seçili, tümünü seç, kopyala.
  Widget _ocrBar(AppLocalizations l10n) {
    final total = _ocrLines?.length ?? 0;
    final selected = _ocrSelected.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected == 0
                    ? l10n.imageOcrHint(total)
                    : l10n.imageOcrSelected(selected),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (selected == total) {
                  _ocrSelected.clear();
                } else {
                  _ocrSelected
                    ..clear()
                    ..addAll([for (var i = 0; i < total; i++) i]);
                }
              }),
              child: Text(
                selected == total ? l10n.cancel : l10n.selectAllItems,
              ),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: _copyOcr,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(l10n.copy),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görselin üzerine tanınan metin satırlarını KUTU KUTU çizen katman.
///
/// Kutular ML Kit'ten GÖRSEL PİKSEL koordinatında geliyor; katmanın kendi
/// kutusu ise ekrandaki (ölçekli) boyut. İkisi arasındaki oran her yerleşimde
/// yeniden hesaplanır — görsel `BoxFit.contain` ile kendi en-boy oranındaki
/// bir kutuya oturduğu için tek bir ölçek katsayısı yeterlidir.
class _OcrTextLayer extends StatelessWidget {
  const _OcrTextLayer({
    required this.lines,
    required this.imageSize,
    required this.selected,
    required this.onToggle,
  });

  final List<OcrLine> lines;
  final Size imageSize;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (imageSize.width <= 0 || imageSize.height <= 0) {
          return const SizedBox.shrink();
        }
        final sx = constraints.maxWidth / imageSize.width;
        final sy = constraints.maxHeight / imageSize.height;
        return Stack(
          children: [
            for (var i = 0; i < lines.length; i++)
              Positioned(
                left: lines[i].box.left * sx,
                top: lines[i].box.top * sy,
                width: lines[i].box.width * sx,
                height: lines[i].box.height * sy,
                child: GestureDetector(
                  onTap: () => onToggle(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected.contains(i)
                          ? scheme.primary.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: selected.contains(i)
                            ? scheme.primary
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
