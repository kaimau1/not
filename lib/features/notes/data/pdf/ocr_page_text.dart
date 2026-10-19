import 'dart:ui' show Rect;

import 'package:pdfrx/pdfrx.dart';

/// OCR'ın tanıdığı TEK SÖZCÜK: metin + görüntü **piksel** koordinatında kutu
/// (sol-üst köşe orijinli, y aşağı doğru — ML Kit'in verdiği hâliyle).
///
/// Bilerek ML Kit tipi değil: bu dosya saf Dart kalsın diye (birim testleri
/// Linux'ta ML Kit olmadan koşar). `ScanOcr` ML Kit öğelerini buna çevirir.
class OcrWordBox {
  const OcrWordBox(this.text, this.box);

  final String text;
  final Rect box;
}

/// Taranmış sayfanın OCR sonucu, pdfrx'in metin katmanıyla AYNI tipte
/// ([PdfPageText]): seçim katmanı (`PdfSelectLayer`) metnin yazılmış mı
/// taranmış mı olduğunu hiç bilmeden çalışır — tek seçim yolu.
typedef OcrPageText = PdfPageText;

/// ML Kit sözcük satırlarından seçilebilir sayfa metni kurar; sözcük yoksa
/// null döner.
///
/// [lines]: satır başına sözcük listesi (görüntü piksel koordinatında).
/// [imageScale]: görüntü pikseli / PDF punto oranı (sayfa `scale` katıyla
/// çizildiyse aynı `scale`). [pageHeight] PDF puntosu — y ekseni ÇEVRİLİR:
/// PDF'te orijin sol-ALT köşedir ve `PdfRect.top > bottom` olmalıdır.
///
/// Yapı: satır başına BİR fragment. Fragment metni sözcüklerin tek boşlukla
/// birleşimi + satır sonunda satır sonu karakteri. `charRects` metinle birebir
/// aynı uzunlukta:
/// * sözcük karakterleri → sözcük kutusunun eşit dilimleri (OCR karakter
///   kutusu vermez; eşit bölme, seçim tutamaçlarının sözcük içinde makul
///   konumlanması için yeter),
/// * sözcük arası boşluk → iki kutu ARASINDAKİ aralık (seçim vurgusu
///   kesintisiz görünsün),
/// * satır sonu → sıfır genişlikli kutu.
///
/// Satır sırası ML Kit'in blok/satır sırasıdır (kabaca okuma sırası).
/// BİLİNÇLİ olarak yeniden SIRALANMAZ: çok sütunlu sayfada salt y-koordinat
/// sıralaması sütunları birbirine karıştırır, ML Kit'in blok gruplaması ise
/// sütunu bütün tutar.
OcrPageText? buildOcrPageText({
  required int pageNumber,
  required double pageHeight,
  required double imageScale,
  required List<List<OcrWordBox>> lines,
}) {
  if (imageScale <= 0) return null;

  PdfRect toPdf(Rect px) => PdfRect(
    px.left / imageScale,
    pageHeight - px.top / imageScale,
    px.right / imageScale,
    pageHeight - px.bottom / imageScale,
  );

  final buffer = StringBuffer();
  // Parçalar sahip sayfa metnini gösterir (pdfrx 2): sayfa nesnesi önce
  // kurulur, listeler sonra doldurulur.
  final fragments = <PdfPageTextFragment>[];
  final allRects = <PdfRect>[];
  final lineParts = <({int start, int length, List<PdfRect> rects})>[];

  for (final line in lines) {
    final words = [
      for (final w in line)
        if (w.text.isNotEmpty && !w.box.isEmpty) w,
    ];
    if (words.isEmpty) continue;

    final lineStart = buffer.length;
    final lineText = StringBuffer();
    final charRects = <PdfRect>[];

    for (var wi = 0; wi < words.length; wi++) {
      final w = words[wi];
      if (wi > 0) {
        // Sözcük arası boşluk: önceki kutunun sağından bu kutunun soluna.
        final prev = words[wi - 1].box;
        final left = prev.right;
        final right = w.box.left > left ? w.box.left : left;
        lineText.write(' ');
        charRects.add(
          toPdf(
            Rect.fromLTRB(
              left,
              prev.top < w.box.top ? prev.top : w.box.top,
              right,
              prev.bottom > w.box.bottom ? prev.bottom : w.box.bottom,
            ),
          ),
        );
      }
      lineText.write(w.text);
      final n = w.text.length;
      final sliceW = w.box.width / n;
      for (var ci = 0; ci < n; ci++) {
        charRects.add(
          toPdf(
            Rect.fromLTRB(
              w.box.left + sliceW * ci,
              w.box.top,
              ci == n - 1 ? w.box.right : w.box.left + sliceW * (ci + 1),
              w.box.bottom,
            ),
          ),
        );
      }
    }

    // Satır sonu: sıfır genişlik, satırın sağ ucunda.
    final last = words.last.box;
    lineText.write('\n');
    charRects.add(
      toPdf(Rect.fromLTRB(last.right, last.top, last.right, last.bottom)),
    );

    final text = lineText.toString();
    buffer.write(text);
    allRects.addAll(charRects);
    lineParts.add((start: lineStart, length: text.length, rects: charRects));
  }

  if (lineParts.isEmpty) return null;
  final page = PdfPageText(
    pageNumber: pageNumber,
    fullText: buffer.toString(),
    charRects: allRects,
    fragments: fragments,
  );
  for (final part in lineParts) {
    fragments.add(
      PdfPageTextFragment(
        pageText: page,
        index: part.start,
        length: part.length,
        bounds: part.rects.boundingRect(),
        charRects: part.rects,
        direction: PdfTextDirection.ltr,
      ),
    );
  }
  return page;
}
