import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/local_file.dart';
import '../../data/scan/scan_ocr.dart';
import '../editor/note_images.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'image_crop.dart';
import 'ink_layer.dart';
import 'text_recognize_screen.dart';

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
    this.onRotate,
  });

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  /// Kırpma dikdörtgenini (görsel oranında, 0–1) uygulayacak taraf. Kırpma
  /// dosyanın kendisini yeniden yazdığı için ek deposu ve not kimliği gerekir;
  /// ikisi de bu ekranda yok, o yüzden iş çağırana bırakılır. null ise kırpma
  /// düğmesi hiç çizilmez.
  final Future<void> Function(Attachment, Rect)? onCrop;

  /// Görseli 90°'nin katıyla döndürüp KALICI olarak yeniden yazacak taraf
  /// ([onCrop] ile aynı gerekçe). null ise döndürme düğmeleri çizilmez.
  ///
  /// GÜNCELLENMİŞ eki döndürür (null = başarısız): ekran döndürdükten sonra
  /// KAPANMIYOR, yeni ekle kendini tazeliyor. Kullanıcı bulgusu 2026-08-16:
  /// "her döndürme işleminden sonra düzenleme ekranı kapanıyor ama işlem
  /// başarılı" — arka arkaya iki tur atmak için ekranı yeniden açmak
  /// gerekiyordu.
  final Future<Attachment?> Function(Attachment, int)? onRotate;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  /// EKRANIN GÖSTERDİĞİ ek. Döndürme dosyayı yeniden yazdığı için
  /// `_attachment` o andan sonra bayat: boyutlar takas olmuş, bulut
  /// kopyası silinmiş olur. Yerel kopya döndürme sonrası tazelenir.
  late Attachment _attachment = widget.attachment;

  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onChanged?.call(_attachment.copyWith(ink: strokes)),
  );
  final _zoom = TransformationController();
  bool _editing = false;

  /// Döndürme sürerken (dosya yeniden kodlanıyor) düğmeler kilitlenir:
  /// iki döndürme üst üste binerse ikincisi birincinin ESKİ baytlarını okur
  /// ve ilk tur kaybolurdu.
  bool _busy = false;

  // ── Görseldeki METNİ TANI ────────────────────────────────────────────
  // Tanıma ve seçim BU EKRANDA DEĞİL, ortak "Metni Tanı" ekranında
  // (bkz. text_recognize_screen.dart). Burada bir satır seçim katmanı vardı;
  // uygulamada metin tanımanın üç ayrı görünümü oluşmuştu ve bu ekrandaki
  // yalnız SATIR seçebiliyordu (kullanıcı: "harf harf seçebilmeliyiz").

  /// Metin tanıma bu ekte mümkün mü: ML Kit yalnız mobilde var, OCR da
  /// dosyanın YEREL kopyasını okur (buluttaki kopya indirilmeden olmaz) ve
  /// kutuları yerleştirmek için görselin piksel ölçüsü gerekir.
  bool get _ocrAvailable {
    final a = _attachment;
    return ScanOcr.supported &&
        a.localPath.isNotEmpty &&
        localFileExists(a.localPath) &&
        (a.width ?? 0) > 0 &&
        (a.height ?? 0) > 0;
  }

  Future<void> _openRecognizer() async {
    final a = _attachment;
    // Çizim açıkken yarım kalan çizgi kaybolmasın.
    if (_editing) _ink.save();
    await Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => TextRecognizeScreen(
          imagePath: a.localPath,
          imageWidth: a.width ?? 0,
          imageHeight: a.height ?? 0,
          title: a.fileName,
        ),
      ),
    );
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
    await widget.onCrop!(_attachment, rect);
    if (mounted) Navigator.of(context).pop();
  }

  /// Görseli çeyrek tur döndürür ve EKRANDA KALIR.
  ///
  /// Kırpmadan ([_crop]) farkı burada: kırpma yeni bir çerçeve seçtirir ve
  /// sonuç notun tuvalinde görülmek istenir; döndürme ise arka arkaya
  /// yapılan bir ayardır ("bir tur daha"). Ekranı her turda kapatmak
  /// kullanıcıyı görseli yeniden açmaya zorluyordu.
  ///
  /// Döndürme dosyayı AYNI yola yeniden yazdığı için Flutter'ın görsel
  /// önbelleği temizlenmezse eski kare gösterilmeye devam eder; temizlik
  /// çağıranda yapılıyor (bkz. `_rotateImage`). Buradaki `_reloadKey` ise
  /// widget ağacındaki `Image`'ı yeni bir öğe yapıp çözdürmeyi zorlar.
  Future<void> _rotate(int quarterTurns) async {
    if (_busy) return;
    // Çizim açıkken yarım kalan çizgi kaybolmasın.
    if (_editing) _ink.save();
    setState(() => _busy = true);
    try {
      final updated = await widget.onRotate!(_attachment, quarterTurns);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (updated != null) {
          _attachment = updated;
          _reloadKey++;
          // Çizim de döndü; denetleyici yeni oranlı noktalarla tazelenir.
          _ink.replace(updated.ink);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Her döndürmede artar; `Image`'ın anahtarına girer ki aynı yoldaki yeni
  /// dosya gerçekten yeniden çözülsün.
  int _reloadKey = 0;

  /// Görselin kaynağı: yerel kopya → indirme adresi. Kırpma ekranı da aynı
  /// kaynağı kullanır ki seçilen alan gösterilenle birebir örtüşsün.
  ImageProvider _provider() {
    final a = _attachment;
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      return FileImage(File(a.localPath));
    }
    return CachedNetworkImageProvider(a.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = _attachment;
    Widget image;
    if (a.localPath.isNotEmpty && localFileExists(a.localPath)) {
      // Çözünürlük kovası: ekler 1600 px'e kadar olabiliyor ve tam
      // çözünürlük çözmek ~10 MB'lık bir bitmap demek. Yakınlaştırma için pay
      // bırakılır (2×), gerisi boşuna bellek.
      image = Image.file(
        File(a.localPath),
        // Döndürme dosyayı AYNI yola yazıyor; anahtar değişmezse Flutter
        // eski kareyi göstermeye devam eder (bkz. [_rotate]).
        key: ValueKey('${a.localPath}#$_reloadKey'),
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
                onPressed: _busy ? null : () => _crop(aspect),
              ),
            // Döndürme (kullanıcı isteği 2026-08-16). Kırpmayla aynı kural:
            // çizim MODUNDA gizlenir, o an araç çubuğu kalem/silgi için.
            if (widget.onRotate != null && !_editing) ...[
              IconButton(
                tooltip: l10n.imageRotateLeft,
                icon: const Icon(Icons.rotate_left),
                onPressed: _busy ? null : () => _rotate(-1),
              ),
              IconButton(
                tooltip: l10n.imageRotateRight,
                icon: const Icon(Icons.rotate_right),
                onPressed: _busy ? null : () => _rotate(1),
              ),
            ],
            if (widget.onChanged != null)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : Center(
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
        // Metni tanı düğmesi: çizim kipinde gizlenir (o an araç çubuğu
        // kalem/silgi için kullanılıyor).
        floatingActionButton: !_ocrAvailable || _editing
            ? null
            : FloatingActionButton.extended(
                heroTag: 'image-ocr',
                tooltip: l10n.imageOcrTitle,
                onPressed: _openRecognizer,
                icon: const Icon(Icons.text_fields),
                label: Text(l10n.imageOcrShort),
              ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : null,
      ),
    );
  }
}
