import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Tek bir PDF sayfasının görüntüsü — pdfrx'in `PdfPageView`'ının YERİNE.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-09-29: "PDF sayfaya eklediğimde 2.
/// sayfadan sonrası görülmüyor, numara değişiyor ama görüntü aynı
/// kalıyor"): pdfrx 1.3.5'teki `PdfPageView`, sayfayı yeniden çizip
/// çizmeyeceğine YALNIZ hedef ÖLÇÜYE bakarak karar veriyor
/// (`if (pageSize == _pageSize) return;`). Sayfa numarası değişip ölçü
/// aynı kalınca — çoğu belgede bütün sayfalar aynı boyda — eski görüntü
/// ekranda kalıyor. 1. sayfa kapak gibi farklı boydaysa 1→2 geçişi
/// çalışıyor, sonrası hiç değişmiyordu; gösterge ise doğru sayıyordu.
///
/// Burada çizim anahtarı (sayfa numarası, sayfa ölçüsü/yüklenme durumu ve
/// hedef piksel ölçüsü) değişince yeniden çizilir. Yeni sayfa hazırlanırken
/// ÖNCEKİ görüntü yerinde kalır — beyaz bir kare yanıp sönmez.
class PdfPageImage extends StatefulWidget {
  const PdfPageImage({
    super.key,
    required this.document,
    required this.pageNumber,
    this.maximumDpi = 300,
    this.background = Colors.white,
    this.overlay,
  });

  /// Sayfanın TAM ÜSTÜNE (sayfanın kendi en-boy kutusuna) konan katman —
  /// balonlar sayfa oranlı konumla çizildiği için sayfanın kenarlarıyla
  /// birebir hizalı olmalı; kutu ile sayfanın oranı farklıysa (karışık
  /// boylu belge) kenar boşluğuna taşmasın.
  final Widget? overlay;

  final PdfDocument document;

  /// 1'den başlar.
  final int pageNumber;

  /// Görüntünün piksel tavanı: küçük resimlerde düşük tutulur (bellek).
  final double maximumDpi;

  final Color background;

  @override
  State<PdfPageImage> createState() => _PdfPageImageState();
}

class _PdfPageImageState extends State<PdfPageImage> {
  ui.Image? _image;

  /// Ekrandaki görüntünün anahtarı ve sürmekte olan çizimin anahtarı.
  String? _shownKey;
  String? _pendingKey;
  PdfPageRenderCancellationToken? _token;

  @override
  void dispose() {
    _token?.cancel();
    _image?.dispose();
    super.dispose();
  }

  PdfPage? get _page {
    final pages = widget.document.pages;
    final n = widget.pageNumber;
    if (n < 1 || n > pages.length) return null;
    return pages[n - 1];
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page == null) return ColoredBox(color: widget.background);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final aspect = page.height <= 0 ? 1.0 : page.width / page.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kutu ölçüsü 128 px'lik ADIMLARA yukarı yuvarlanır (görsellerdeki
        // `decodeWidthBucket`ın karşılığı). KÖK NEDEN (kullanıcı 2026-10-16:
        // "görseller sürüklenirken aşırı kasma"): sayfaya gömülü PDF köşe
        // tutamacıyla ya da kaydırıcıyla boyutlandırılırken kutu HER KAREDE
        // bir piksel değişiyor, her değişim yeni bir anahtar ve sayfanın
        // baştan çizimi (PDFium + görüntü oluşturma) demekti. Görüntü kutuya
        // `fill` ile oturduğundan biraz büyük çizim fark edilmez.
        double bucket(double v) =>
            v.isFinite && v > 0 ? (v / 128).ceil() * 128.0 : v;
        final target = pdfRenderSize(
          pageWidth: page.width,
          pageHeight: page.height,
          boxWidth: bucket(constraints.maxWidth * dpr),
          boxHeight: bucket(constraints.maxHeight * dpr),
          maximumDpi: widget.maximumDpi,
        );
        if (target != null) {
          final key = pdfRenderKey(
            documentId: identityHashCode(widget.document),
            pageNumber: widget.pageNumber,
            pageWidth: page.width,
            pageHeight: page.height,
            loaded: page.isLoaded,
            target: target,
          );
          if (key != _pendingKey && key != _shownKey) {
            _pendingKey = key;
            // Çizim kare DIŞINDA başlar: build içinde setState yok.
            scheduleMicrotask(() => _render(page, target, key));
          }
        }
        final image = _image;
        return Center(
          child: AspectRatio(
            aspectRatio: aspect,
            child: ColoredBox(
              color: widget.background,
              child: widget.overlay == null
                  ? (image == null
                        ? const SizedBox.expand()
                        : RawImage(image: image, fit: BoxFit.fill))
                  : Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        if (image != null)
                          RawImage(image: image, fit: BoxFit.fill),
                        widget.overlay!,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _render(PdfPage page, Size target, String key) async {
    if (!mounted || _pendingKey != key) return;
    _token?.cancel();
    final token = page.createCancellationToken();
    _token = token;
    PdfImage? rendered;
    try {
      rendered = await page.render(
        fullWidth: target.width,
        fullHeight: target.height,
        backgroundColor: widget.background,
        cancellationToken: token,
      );
    } catch (_) {
      rendered = null;
    }
    // Bu arada başka bir sayfa istendiyse sonuç atılır.
    if (!mounted || _pendingKey != key) {
      rendered?.dispose();
      return;
    }
    if (rendered == null) {
      // Başarısız çizim: ÖNCEKİ sayfanın görüntüsü yanlış sayfada kalmasın.
      _pendingKey = null;
      _shownKey = key;
      final old = _image;
      setState(() => _image = null);
      old?.dispose();
      return;
    }
    try {
      final image = await rendered.createImage();
      if (!mounted || _pendingKey != key) {
        image.dispose();
        return;
      }
      final old = _image;
      setState(() {
        _image = image;
        _shownKey = key;
        _pendingKey = null;
      });
      old?.dispose();
    } catch (_) {
      if (mounted && _pendingKey == key) _pendingKey = null;
    } finally {
      rendered.dispose();
    }
  }
}

// ── SAF MANTIK (ölçülebilir; pdfium gerektirmez) ────────────────────────────

/// Sayfanın kutuya sığan piksel ölçüsü ([maximumDpi] tavanıyla). Kutu ya da
/// sayfa ölçüsüzse null — çizilecek bir şey yok.
Size? pdfRenderSize({
  required double pageWidth,
  required double pageHeight,
  required double boxWidth,
  required double boxHeight,
  double maximumDpi = 300,
}) {
  if (pageWidth <= 0 || pageHeight <= 0) return null;
  if (!boxWidth.isFinite || !boxHeight.isFinite) return null;
  if (boxWidth <= 0 || boxHeight <= 0) return null;
  final scale = math.min(
    maximumDpi / 72,
    math.min(boxWidth / pageWidth, boxHeight / pageHeight),
  );
  return Size(
    (pageWidth * scale).roundToDouble(),
    (pageHeight * scale).roundToDouble(),
  );
}

/// Çizim anahtarı. SAYFA NUMARASI anahtarın parçası — pdfrx'in kendi
/// görünümünde eksik olan tam da buydu (bkz. [PdfPageImage]). Sayfanın
/// gerçek ölçüsü ilerlemeli yüklemede sonradan geldiğinden yüklenme durumu
/// da anahtarda: tahmini ölçüyle çizilen sayfa, gerçeği gelince yenilenir.
String pdfRenderKey({
  required int documentId,
  required int pageNumber,
  required double pageWidth,
  required double pageHeight,
  required bool loaded,
  required Size target,
}) =>
    '$documentId:$pageNumber:${pageWidth.round()}x${pageHeight.round()}:'
    '${loaded ? 1 : 0}:${target.width.round()}x${target.height.round()}';
