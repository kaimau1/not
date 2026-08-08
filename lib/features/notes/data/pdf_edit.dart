import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/attachment.dart';

/// PDF **yazma** yolu: sayfa sil / döndür / sırala ve çizimi belgeye GÖM.
///
/// **MİMARİ (dosya-okuyucu uygulamasından port edildi, 2026-07-23 kararı):**
/// görüntüleme pdfrx/pdfium'da KALIR — yüksek sadakatli ve hızlı, ama
/// SALT-RENDER. Var olan bir PDF'e yazmanın tek yolu Syncfusion: burada yalnız
/// yeni PDF **baytı üretilir** (işle → yeni bayt → dosyaya yaz → pdfrx'te
/// yeniden aç). İki PDF yığını bilinçli yan yana duruyor.
///
/// 2026-08-06'da "çizimi paylaşılan PDF'in içine gömmek pdfrx+pdf ile
/// yapılamıyor" diye kaydedilen engel BUDUR ve böyle aşıldı: `pdf` paketi
/// var olan bir belgeyi açamıyor (yalnız sıfırdan üretiyor).
///
/// Hepsi saf Syncfusion + Dart: Flutter kanalına dokunmaz, testte cihazsız
/// koşar ve isolate'e taşınabilir.
class PdfEditException implements Exception {
  const PdfEditException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PdfEdit {
  const PdfEdit._();

  /// Belgenin sayfa sayısı.
  static int pageCount(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      return doc.pages.count;
    } finally {
      doc.dispose();
    }
  }

  /// [pageIndexes] (0 tabanlı) sayfalarını **yerinde** siler.
  ///
  /// Yerinde silme, [reorderPages]'in aksine sayfayı KOPYALAMAZ; belgedeki
  /// annotation'lar (varsa vurgular, form alanları) yerinde kalır. Bu yüzden
  /// "yalnız sil" ayrı bir yol olarak tutuluyor.
  static Uint8List deletePages(Uint8List bytes, Iterable<int> pageIndexes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final targets = pageIndexes.toSet().toList()..sort();
      if (targets.isEmpty) throw const PdfEditException('empty-selection');
      if (targets.length >= doc.pages.count) {
        throw const PdfEditException('all-pages');
      }
      // SONDAN BAŞA: baştan silmek kalan indeksleri kaydırır ve yanlış
      // sayfalar gider.
      for (final i in targets.reversed) {
        if (i < 0 || i >= doc.pages.count) {
          throw const PdfEditException('out-of-range');
        }
        doc.pages.removeAt(i);
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  /// Sayfaları [order] sırasıyla yeni bir belgeye alır (sıralama).
  ///
  /// **KAYIP UYARISI:** sayfalar `createTemplate()` ile KOPYALANIR;
  /// annotation'lar ayrı nesneler oldukları için yeni belgeye GELMEZ. Bizde
  /// çizimler PDF'in içinde değil ekin `ink` alanında durduğu için kullanıcının
  /// el yazısı bu yoldan etkilenmez — ama belgenin KENDİ vurguları giderse
  /// bu bilinçli bedeldir. Yalnız silmek için [deletePages] kullanılır.
  static Uint8List reorderPages(Uint8List bytes, List<int> order) {
    if (order.isEmpty) throw const PdfEditException('empty-selection');
    final src = PdfDocument(inputBytes: bytes);
    final out = PdfDocument();
    try {
      final count = src.pages.count;
      for (final i in order) {
        if (i < 0 || i >= count) throw const PdfEditException('out-of-range');
      }
      // Varsayılan kenar boşluğu SIFIRLANIR: şablon sayfanın tamamını
      // kaplamalı, yoksa her sayfa küçülüp ortalanmış görünür.
      out.pageSettings.margins.all = 0;
      for (final i in order) {
        final page = src.pages[i];
        final size = page.size;
        out.pageSettings.size = size;
        out.pages.add().graphics.drawPdfTemplate(
          page.createTemplate(),
          Offset.zero,
          size,
        );
      }
      return Uint8List.fromList(out.saveSync());
    } finally {
      src.dispose();
      out.dispose();
    }
  }

  /// Sayfaları çeyrek tur döndürür ([quarterTurns] 1 = 90° saat yönü).
  ///
  /// Sayfa içeriği yeniden ÇİZİLMEZ, yalnız PDF'in `/Rotate` girdisi güncellenir
  /// — kayıpsız ve hızlı.
  static Uint8List rotatePages(
    Uint8List bytes, {
    required Iterable<int> pageIndexes,
    required int quarterTurns,
  }) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      for (final i in pageIndexes) {
        if (i < 0 || i >= doc.pages.count) {
          throw const PdfEditException('out-of-range');
        }
        final page = doc.pages[i];
        final next = (page.rotation.index + quarterTurns) % 4;
        page.rotation = PdfPageRotateAngle.values[next];
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  /// Not balonlarını ve vurguları belgenin İÇİNE basar (düzleştirme).
  ///
  /// Neden gerekli (kullanıcı isteği 2026-08-08: "PDF modunda balonlu PDF'yi
  /// balonlarıyla beraber atabilmeliyim"): balonlar ekin `bubbles` alanında
  /// yaşıyor, yani PDF dosyası olduğu gibi paylaşıldığında karşı taraf boş
  /// belgeyi görüyordu. Not uygulaması olan bir alıcıya `.notpaket` gönderilir
  /// (balonlar DÜZENLENEBİLİR gelir); bu yol ise **herkese** açılabilen bir PDF
  /// üretir — balon ve vurgular sayfaya çizilmiş olarak.
  ///
  /// Ekranla aynı görüntü: vurgu = soluk zemin + ortasından geçen uçları
  /// yuvarlak kalın iz (fosforlu kalem), balon = ucundaki renkli nokta + not
  /// kutusu (belge rengi zemin, solda balonun renginde şerit). Kutu tasarımı
  /// uygulamadaki yazma kartıyla (BubbleDock) aynı dili konuşur.
  ///
  /// [fontBytes] gömülecek TTF: `pdf` paketindeki gibi burada da hazır
  /// Helvetica WinAnsi kodludur ve içinde ı ğ ş İ YOKTUR — Türkçe not olduğu
  /// gibi bozuk çıkardı. Font baytları ANA izolede okunur (rootBundle izolede
  /// yok, bkz. NotePdf).
  ///
  /// [bubbles] koordinatları SAYFA ORANIDIR (0–1, sol-ÜST orijinli); sayfa
  /// `/Rotate` taşıyorsa damga [stampTransform] ile sayfanın GÖRÜNEN hâline
  /// çevrilir — çizimlerdeki kuralın aynısı.
  static Uint8List burnBubbles(
    Uint8List bytes,
    List<PageBubble> bubbles, {
    required Uint8List fontBytes,
  }) {
    if (bubbles.isEmpty) throw const PdfEditException('no-bubbles');
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final byPage = <int, List<PageBubble>>{};
      for (final b in bubbles) {
        final index = b.page - 1;
        if (index < 0 || index >= doc.pages.count) continue;
        if (!b.isHighlight && b.text.trim().isEmpty && b.title.trim().isEmpty) {
          continue; // boş serbest balon: sayfada gösterecek bir şeyi yok
        }
        (byPage[index] ??= []).add(b);
      }
      if (byPage.isEmpty) throw const PdfEditException('no-bubbles');
      final title = PdfTrueTypeFont(fontBytes, 9, style: PdfFontStyle.bold);
      final body = PdfTrueTypeFont(fontBytes, 8.5);
      for (final entry in byPage.entries) {
        final page = doc.pages[entry.key];
        final turns = page.rotation.index;
        final t = stampTransform(page.size, turns);
        final visible = turns.isOdd
            ? Size(page.size.height, page.size.width)
            : page.size;
        final g = page.graphics;
        final state = g.save();
        try {
          if (t.angle != 0) {
            g.translateTransform(t.translate.dx, t.translate.dy);
            g.rotateTransform(t.angle);
          }
          for (final bubble in entry.value) {
            _drawHighlight(g, bubble, visible);
          }
          // Kutular vurguların ÜSTÜNE çizilir: iki balon aynı satırdaysa yazı
          // fosforlu izin altında kalmasın.
          for (final bubble in entry.value) {
            _drawBubbleNote(g, bubble, visible, title: title, body: body);
          }
        } finally {
          g.restore(state);
        }
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  /// Vurgu izleri: soluk zemin + ortasından geçen kalın iz (uçları yuvarlak).
  /// Ekrandaki `_HighlightPainter` ile aynı oranlar (%20 / %42, satırın %58'i).
  static void _drawHighlight(PdfGraphics g, PageBubble bubble, Size page) {
    if (bubble.rects.isEmpty) return;
    final wash = _brush(bubble.color, 0.20);
    final stroke = _brush(bubble.color, 0.42);
    for (final r in bubble.rects) {
      final rect = Rect.fromLTRB(
        r.left * page.width,
        r.top * page.height,
        r.right * page.width,
        r.bottom * page.height,
      );
      if (rect.width <= 0 || rect.height <= 0) continue;
      g.drawRectangle(brush: wash, bounds: rect);
      final band = rect.height * 0.58;
      final top = rect.center.dy - band / 2;
      g.drawRectangle(
        brush: stroke,
        bounds: Rect.fromLTWH(rect.left, top, rect.width, band),
      );
      // Uçlardaki yarım daireler: "kalem izi" hissi düz dikdörtgende kayboluyor.
      for (final cx in [rect.left, rect.right]) {
        g.drawEllipse(
          Rect.fromLTWH(cx - band / 2, top, band, band),
          brush: stroke,
        );
      }
    }
  }

  /// Balonun notu: ucundaki renkli nokta + kâğıda iliştirilmiş fiş görünümlü
  /// kutu. Kutu sayfanın içine KISTIRILIR — kenardaki balonun notu sayfanın
  /// dışına taşıp görünmez olmasın.
  static void _drawBubbleNote(
    PdfGraphics g,
    PageBubble bubble,
    Size page, {
    required PdfFont title,
    required PdfFont body,
  }) {
    final anchorX = (bubble.x * page.width).clamp(0.0, page.width);
    final anchorY = (bubble.y * page.height).clamp(0.0, page.height);
    // Ucundaki nokta her balonda var: not kutusu kaydırılsa bile balonun
    // sayfada NEREYİ gösterdiği belli olsun.
    g.drawEllipse(
      Rect.fromLTWH(anchorX - 3, anchorY - 3, 6, 6),
      brush: _brush(bubble.color, 1),
      pen: PdfPen(PdfColor(255, 255, 255), width: 0.8),
    );

    final head = bubble.title.trim();
    // Çok uzun not sayfanın yarısını kaplayan bir kutuya dönüşürdü: damgaya
    // ilk 400 karakter girer, tamamı uygulamada (ve `.notpaket` paylaşımında)
    // durmaya devam eder.
    final full = bubble.text.trim();
    // Kesme RUNE sınırında: `substring` çok baytlı bir karakterin ortasından
    // kesip yarım bir kod noktası bırakabilir.
    final runes = full.runes.toList();
    final text = runes.length > 400
        ? '${String.fromCharCodes(runes.take(400))}…'
        : full;
    if (head.isEmpty && text.isEmpty) return;

    const pad = 5.0;
    final width = math.min(200.0, math.max(90.0, page.width * 0.42));
    final inner = width - pad * 2 - 4; // 4 = soldaki renk şeridi
    final headHeight = head.isEmpty ? 0.0 : _blockHeight(title, head, inner);
    final bodyHeight = text.isEmpty ? 0.0 : _blockHeight(body, text, inner);
    final height =
        pad * 2 +
        headHeight +
        (head.isEmpty || text.isEmpty ? 0 : 2) +
        bodyHeight;

    // Kutu balonun ucunun ALTINA açılır; sığmıyorsa üstüne alınır.
    var left = anchorX - width / 2;
    var top = anchorY + 8;
    if (top + height > page.height) top = anchorY - 8 - height;
    left = left.clamp(0.0, math.max(0.0, page.width - width));
    top = top.clamp(0.0, math.max(0.0, page.height - height));
    final box = Rect.fromLTWH(left, top, width, height);

    g
      ..drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 255, 255, 242)),
        pen: PdfPen(_color(bubble.color, 0.45), width: 0.6),
        bounds: box,
      )
      // Soldaki renk şeridi (uygulamadaki yazma kartının aynısı).
      ..drawRectangle(
        brush: _brush(bubble.color, 1),
        bounds: Rect.fromLTWH(box.left, box.top, 4, box.height),
      );

    var y = box.top + pad;
    if (head.isNotEmpty) {
      g.drawString(
        head,
        title,
        brush: PdfSolidBrush(PdfColor(20, 20, 20)),
        bounds: Rect.fromLTWH(box.left + 4 + pad, y, inner, headHeight),
      );
      y += headHeight + (text.isEmpty ? 0 : 2);
    }
    if (text.isNotEmpty) {
      g.drawString(
        text,
        body,
        brush: PdfSolidBrush(PdfColor(35, 35, 35)),
        bounds: Rect.fromLTWH(box.left + 4 + pad, y, inner, bodyHeight),
      );
    }
  }

  /// [width] genişliğine sarılan metnin yüksekliği.
  ///
  /// Syncfusion'ın sarmalı `drawString` içinde yapılıyor ama ölçümü dışarıya
  /// yalnız tek satır olarak veriyor; kutu yüksekliğini önceden bilmek
  /// gerektiği için satır sayısı buradan çıkarılır. Ölçüm KABA (kelime kırma
  /// noktasını birebir bilmiyoruz) olduğundan bir satır PAY bırakılır — eksik
  /// hesap son satırı kırpardı, fazlası yalnız birkaç boş piksel demek.
  static double _blockHeight(PdfFont font, String text, double width) {
    final line = font.measureString('Ag').height;
    var lines = 0;
    for (final paragraph in text.split('\n')) {
      final w = font.measureString(paragraph).width;
      lines += math.max(1, (w / width).ceil());
    }
    return (lines + 0.5) * line;
  }

  static PdfColor _color(int argb, double alpha) => PdfColor(
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
    (((argb >> 24) & 0xFF) * alpha).round().clamp(0, 255),
  );

  static PdfBrush _brush(int argb, double alpha) =>
      PdfSolidBrush(_color(argb, alpha));

  /// El yazısı çizimlerini belgenin İÇİNE **vektör olarak** basar.
  ///
  /// Bugüne kadar çizimler yalnız ekin `ink` alanında yaşıyordu: uygulamada
  /// görünüyor ama PDF paylaşıldığında ya da başka bir programda açıldığında
  /// YOK oluyorlardı (2026-08-06 kaydı). Bu yol onları belgeye gömer.
  ///
  /// Neden resim değil vektör: her yakınlaştırmada keskin kalır, dosya küçük
  /// olur ve PNG saydamlığının PDF'e doğru gömülüp gömülmediğine bağlı kalmayız.
  ///
  /// [strokes] koordinatları SAYFA ORANIDIR (0–1, bkz. [InkStroke]); kalınlık
  /// da sayfa genişliğinin oranıdır. Sayfa `/Rotate` taşıyorsa çizim, sayfanın
  /// GÖRÜNEN hâline göre yapıldığı için aynı dönüşüm damgaya da uygulanır —
  /// yoksa döndürülmüş sayfada çizgi 90° kaymış çıkardı.
  static Uint8List burnInk(Uint8List bytes, List<InkStroke> strokes) {
    if (strokes.isEmpty) throw const PdfEditException('no-ink');
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final byPage = <int, List<InkStroke>>{};
      for (final s in strokes) {
        if (s.points.length < 4) continue; // en az iki nokta
        final index = s.page - 1;
        if (index < 0 || index >= doc.pages.count) continue;
        (byPage[index] ??= []).add(s);
      }
      if (byPage.isEmpty) throw const PdfEditException('no-ink');
      for (final entry in byPage.entries) {
        final page = doc.pages[entry.key];
        final turns = page.rotation.index;
        final t = stampTransform(page.size, turns);
        // Çizim, sayfanın GÖRÜNEN kutusuna oranlıdır: 90/270 derecede görünen
        // genişlik ile yükseklik yer değiştirir.
        final visible = turns.isOdd
            ? Size(page.size.height, page.size.width)
            : page.size;
        final g = page.graphics;
        final state = g.save();
        try {
          if (t.angle != 0) {
            g.translateTransform(t.translate.dx, t.translate.dy);
            g.rotateTransform(t.angle);
          }
          for (final stroke in entry.value) {
            final color = stroke.color;
            final pen = PdfPen(
              PdfColor(
                (color >> 16) & 0xFF,
                (color >> 8) & 0xFF,
                color & 0xFF,
                // Fosforlu kalemin saydamlığı çizgide taşınıyor; PdfColor
                // alfayı destekliyor, düz renge indirgemek fosforluyu opak
                // yapardı ve altındaki metni kapatırdı.
                (color >> 24) & 0xFF,
              ),
              width: (stroke.width * visible.width).clamp(0.1, 100.0),
              lineCap: PdfLineCap.round,
              lineJoin: PdfLineJoin.round,
            );
            final path = PdfPath()..startFigure();
            Offset at(int i) => Offset(
              stroke.points[i] * visible.width,
              stroke.points[i + 1] * visible.height,
            );
            // Nokta nokta `addLine`: `addPolygon` şekli KAPATIR (son noktadan
            // ilkine çizgi çeker), el yazısında yanlış olur.
            for (var i = 0; i + 3 < stroke.points.length; i += 2) {
              path.addLine(at(i), at(i + 2));
            }
            g.drawPath(path, pen: pen);
          }
        } finally {
          g.restore(state);
        }
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  // ---- Arka plan (isolate) sarmalayıcıları ------------------------------
  //
  // Syncfusion belgeyi TÜMÜYLE belleğe açıp yeniden yazıyor: yüz sayfalık bir
  // ders notunda bu saniyeler sürer ve UI iş parçacığında yapılırsa uygulama
  // donar. `Isolate.run` kapanışı yalnız GÖNDERİLEBİLİR değerleri yakalayabilir
  // — bu yüzden kapanışlar sınıf durumuna değil, yalnız yerel değişkenlere
  // bakar.
  //
  // Hata metne çevrilerek yeniden atılır: isolate sınırından Syncfusion'ın iç
  // hata tipleri geçemez ve kullanıcı "Instance of ..." görürdü.

  static Future<Uint8List> deletePagesInBackground(
    Uint8List bytes,
    List<int> pageIndexes,
  ) => _bg(() => deletePages(bytes, pageIndexes));

  static Future<Uint8List> reorderPagesInBackground(
    Uint8List bytes,
    List<int> order,
  ) => _bg(() => reorderPages(bytes, order));

  static Future<Uint8List> rotatePagesInBackground(
    Uint8List bytes, {
    required List<int> pageIndexes,
    required int quarterTurns,
  }) => _bg(
    () => rotatePages(
      bytes,
      pageIndexes: pageIndexes,
      quarterTurns: quarterTurns,
    ),
  );

  static Future<Uint8List> burnInkInBackground(
    Uint8List bytes,
    List<InkStroke> strokes,
  ) {
    // InkStroke isolate sınırından geçmez (sınıf gönderilebilir ama bağımlılığı
    // olmayan sade veri olarak taşımak daha güvenli); haritaya çevrilip
    // karşıda yeniden kurulur.
    final maps = [for (final s in strokes) s.toMap()];
    return _bg(
      () => burnInk(bytes, [
        for (final m in maps)
          InkStroke.fromMap(Map<String, dynamic>.from(m as Map)),
      ]),
    );
  }

  /// Balonları gömer. [PageBubble] de çizgi gibi düz veriye çevrilip izoleye
  /// geçer (bkz. [burnInkInBackground]).
  static Future<Uint8List> burnBubblesInBackground(
    Uint8List bytes,
    List<PageBubble> bubbles, {
    required Uint8List fontBytes,
  }) {
    final maps = [for (final b in bubbles) b.toMap()];
    return _bg(
      () => burnBubbles(bytes, [
        for (final m in maps) PageBubble.fromMap(Map<String, dynamic>.from(m)),
      ], fontBytes: fontBytes),
    );
  }

  static Future<Uint8List> _bg(Uint8List Function() task) =>
      Isolate.run(() {
        try {
          return task();
        } catch (e) {
          throw PdfEditException('$e');
        }
      });
}

/// Sayfa `/Rotate` taşıyorsa damgayı sayfanın GÖRÜNEN yönüne çeviren dönüşüm.
///
/// Syncfusion'ın grafik uzayı HAM (döndürülmemiş) sayfadır; kullanıcı ise
/// döndürülmüş hâlin üzerine çizer. Çeviri + döndürme bu ikisini hizalar.
({Offset translate, double angle}) stampTransform(
  Size pageSize,
  int quarterTurns,
) {
  final w = pageSize.width;
  final h = pageSize.height;
  return switch (quarterTurns % 4) {
    1 => (translate: Offset(w, 0), angle: 90),
    2 => (translate: Offset(w, h), angle: 180),
    3 => (translate: Offset(0, h), angle: -90),
    _ => (translate: Offset.zero, angle: 0),
  };
}
