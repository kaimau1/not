import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/arrow.dart';
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
          _drawStrokes(g, entry.value, visible);
        } finally {
          g.restore(state);
        }
      }
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  static void _drawStrokes(
    PdfGraphics g,
    List<InkStroke> strokes,
    Size visible,
  ) {
    for (final stroke in strokes) {
      if (stroke.points.length < 4) continue;
      final color = stroke.color;
      final width = (stroke.width * visible.width).clamp(0.1, 100.0);
      final pdfColor = PdfColor(
        (color >> 16) & 0xFF,
        (color >> 8) & 0xFF,
        color & 0xFF,
        // Fosforlu kalemin saydamlığı çizgide taşınıyor; PdfColor alfayı
        // destekliyor, düz renge indirgemek fosforluyu opak yapardı ve
        // altındaki metni kapatırdı.
        (color >> 24) & 0xFF,
      );
      final pen = PdfPen(
        pdfColor,
        width: width,
        lineCap: PdfLineCap.round,
        lineJoin: PdfLineJoin.round,
      );
      Offset at(int i) => Offset(
        stroke.points[i] * visible.width,
        stroke.points[i + 1] * visible.height,
      );
      // OK: gövde + ucundaki DOLU başlık. Geometri ekrandakiyle tek kopya
      // (bkz. arrowBody) — paylaşılan PDF'teki ok ekrandakinin aynısı olmalı.
      if (stroke.arrow) {
        final tail = at(0);
        final head = at(2);
        final geo = arrowGeometry(tail, head, width);
        g
          ..drawLine(pen, tail, geo.lineEnd)
          ..drawPath(
            PdfPath()
              ..startFigure()
              ..addPolygon([head, geo.left, geo.right]),
            brush: PdfSolidBrush(pdfColor),
          );
        continue;
      }
      final path = PdfPath()..startFigure();
      // Nokta nokta `addLine`: `addPolygon` şekli KAPATIR (son noktadan
      // ilkine çizgi çeker), el yazısında yanlış olur — okun başlığında ise
      // kapanması TAM İSTENEN şeydir (üçgen dolu boyanır).
      for (var i = 0; i + 3 < stroke.points.length; i += 2) {
        path.addLine(at(i), at(i + 2));
      }
      g.drawPath(path, pen: pen);
    }
  }

  /// Paylaşılan PDF'te damganın konduğu KATMANIN adı.
  ///
  /// Damga sayfanın kendi içeriğine değil, adlandırılmış bir PDF katmanına
  /// (optional content group) çizilir: başka bir görüntüleyici onu normal
  /// içerik gibi gösterir, Notlar ise açarken katmanı SÖKÜP atabilir (bkz.
  /// [readSharedPdf]).
  static const shareLayerName = 'Notlar balonlari';

  /// Balon/çizim verisinin PDF'e iliştirildiği dosya adı.
  static const sharePayloadName = 'notlar-balonlar.json';

  /// **Paylaşılabilir ama Notlar'da DÜZENLENEBİLİR kalan** PDF üretir.
  ///
  /// Kullanıcı isteği (2026-08-08): "gönderilen PDF'yi PDF görüntüleyicilerde
  /// açabiliyorum ama Notlar'da açıp aynı şekilde düzenlemeye devam etmek
  /// istiyorum." Damgalanmış (düzleştirilmiş) bir PDF'te balonlar sayfanın
  /// içeriğine karışır, yani karşı tarafta artık taşınamaz/silinemezdi.
  ///
  /// Çözüm İKİ parça:
  /// * Damga adlandırılmış bir **katmana** çizilir ([shareLayerName]) — her
  ///   PDF okuyucu görür, Notlar ise katmanı grafiğiyle birlikte kaldırabilir.
  /// * Balonların ve çizimlerin KENDİ VERİSİ, PDF'e **ek dosya** olarak
  ///   iliştirilir ([sharePayloadName], JSON) — başka programlar için görünmez
  ///   bir eklentidir, Notlar için notun kaynağıdır.
  ///
  /// Alıcı Notlar'da açınca: katman silinir, veri okunur ve balonlar ilk
  /// günkü gibi düzenlenebilir olarak geri gelir. Alıcının Notlar'ı yoksa
  /// dosya sıradan bir PDF'tir. Bu yüzden belgenin İKİ kopyası taşınmaz
  /// (dosya boyutu iki katına çıkmaz).
  ///
  /// **TUZAK**: bir `PdfLayer` grafiğini İLK sayfa için kurup önbelleğe
  /// alıyor; aynı katman ikinci sayfada kullanılırsa çizim yanlış sayfaya
  /// gider. Bu yüzden her sayfaya AYNI ADLA ayrı bir katman açılıyor —
  /// silme de ada göre çalıştığı için hepsi tek çağrıda kalkıyor.
  static Uint8List burnForSharing(
    Uint8List bytes, {
    required List<PageBubble> bubbles,
    required List<InkStroke> ink,
    required Uint8List fontBytes,
  }) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final bubblesByPage = <int, List<PageBubble>>{};
      for (final b in bubbles) {
        final index = b.page - 1;
        if (index < 0 || index >= doc.pages.count) continue;
        if (!b.isHighlight && b.text.trim().isEmpty && b.title.trim().isEmpty) {
          continue;
        }
        (bubblesByPage[index] ??= []).add(b);
      }
      final inkByPage = <int, List<InkStroke>>{};
      for (final s in ink) {
        if (s.points.length < 4) continue;
        final index = s.page - 1;
        if (index < 0 || index >= doc.pages.count) continue;
        (inkByPage[index] ??= []).add(s);
      }
      final pages = {...bubblesByPage.keys, ...inkByPage.keys}.toList()..sort();
      if (pages.isEmpty) throw const PdfEditException('no-layers');

      final title = PdfTrueTypeFont(fontBytes, 9, style: PdfFontStyle.bold);
      final body = PdfTrueTypeFont(fontBytes, 8.5);
      for (final index in pages) {
        final page = doc.pages[index];
        final turns = page.rotation.index;
        final t = stampTransform(page.size, turns);
        final visible = turns.isOdd
            ? Size(page.size.height, page.size.width)
            : page.size;
        final layer = doc.layers.add(name: shareLayerName, visible: true);
        final g = layer.createGraphics(page);
        final state = g.save();
        try {
          if (t.angle != 0) {
            g.translateTransform(t.translate.dx, t.translate.dy);
            g.rotateTransform(t.angle);
          }
          _drawStrokes(g, inkByPage[index] ?? const [], visible);
          for (final bubble in bubblesByPage[index] ?? const <PageBubble>[]) {
            _drawHighlight(g, bubble, visible);
          }
          for (final bubble in bubblesByPage[index] ?? const <PageBubble>[]) {
            _drawBubbleNote(g, bubble, visible, title: title, body: body);
          }
        } finally {
          g.restore(state);
        }
      }

      doc.attachments.add(
        PdfAttachment(
          sharePayloadName,
          utf8.encode(
            jsonEncode({
              'v': 1,
              'b': [for (final b in bubbles) b.toMap()],
              'i': [for (final s in ink) s.toMap()],
            }),
          ),
          mimeType: 'application/json',
          description: 'Notlar balon ve çizim verisi',
        ),
      );
      return Uint8List.fromList(doc.saveSync());
    } finally {
      doc.dispose();
    }
  }

  /// Notlar'ın ürettiği bir paylaşım PDF'ini **düzenlenebilir hâline** çevirir.
  ///
  /// Damga katmanı grafiğiyle birlikte silinir, iliştirilen veri okunur ve
  /// temizlenmiş belge + balonlar/çizimler döner. Payload yoksa `null` döner:
  /// dosya sıradan bir PDF'tir, olduğu gibi eklenir.
  ///
  /// Katman silinmeseydi balonlar İKİ KEZ görünürdü — bir kez sayfaya basılmış
  /// damga, bir kez de üstteki canlı katman olarak.
  static ({Uint8List bytes, List<PageBubble> bubbles, List<InkStroke> ink})?
  readSharedPdf(Uint8List bytes) {
    PdfDocument? doc;
    try {
      doc = PdfDocument(inputBytes: bytes);
      final attachments = doc.attachments;
      var found = -1;
      for (var i = 0; i < attachments.count; i++) {
        if (attachments[i].fileName == sharePayloadName) {
          found = i;
          break;
        }
      }
      if (found < 0) return null;
      final map =
          jsonDecode(utf8.decode(attachments[found].data)) as Map<String, dynamic>;
      final parsed = (
        bubbles: [
          for (final e in (map['b'] as List?) ?? const [])
            PageBubble.fromMap(Map<String, dynamic>.from(e as Map)),
        ],
        ink: [
          for (final e in (map['i'] as List?) ?? const [])
            InkStroke.fromMap(Map<String, dynamic>.from(e as Map)),
        ],
      );
      attachments.removeAt(found);
      try {
        doc.layers.remove(
          name: shareLayerName,
          isRemoveGraphicalContent: true,
        );
      } catch (_) {
        // Katman bulunamazsa (elle düzenlenmiş dosya) veri yine de kurtarılır.
      }
      return (
        bytes: Uint8List.fromList(doc.saveSync()),
        bubbles: parsed.bubbles,
        ink: parsed.ink,
      );
    } catch (_) {
      // Bozuk/şifreli PDF paylaşımı düşürmez: normal ek yoluna dönülür.
      return null;
    } finally {
      doc?.dispose();
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

  /// [burnForSharing]'in arka plan sürümü.
  static Future<Uint8List> burnForSharingInBackground(
    Uint8List bytes, {
    required List<PageBubble> bubbles,
    required List<InkStroke> ink,
    required Uint8List fontBytes,
  }) {
    final bubbleMaps = [for (final b in bubbles) b.toMap()];
    final inkMaps = [for (final s in ink) s.toMap()];
    return _bg(
      () => burnForSharing(
        bytes,
        bubbles: [
          for (final m in bubbleMaps)
            PageBubble.fromMap(Map<String, dynamic>.from(m)),
        ],
        ink: [
          for (final m in inkMaps)
            InkStroke.fromMap(Map<String, dynamic>.from(m)),
        ],
        fontBytes: fontBytes,
      ),
    );
  }

  /// [readSharedPdf]'in arka plan sürümü. Sonuç düz haritayla döner: isolate
  /// sınırından yalnız sade veri geçirmek (çizim/balon nesneleri değil) bu
  /// dosyadaki genel kural.
  static Future<Map<String, dynamic>?> readSharedPdfInBackground(
    Uint8List bytes,
  ) => Isolate.run(() {
    final result = readSharedPdf(bytes);
    if (result == null) return null;
    return <String, dynamic>{
      'bytes': result.bytes,
      'b': [for (final b in result.bubbles) b.toMap()],
      'i': [for (final s in result.ink) s.toMap()],
    };
  });

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
