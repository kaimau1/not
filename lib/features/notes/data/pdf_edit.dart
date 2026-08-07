import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' show Offset, Size;

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
