import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/pdf_edit.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/page_notes.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF DÜZENLEME (dosya-okuyucu uygulamasından port).
///
/// 2026-08-06'da "çizimi paylaşılan PDF'in içine gömmek pdfrx+pdf ile
/// yapılamıyor" diye kaydedilen engel Syncfusion ile aşıldı: görüntüleme
/// pdfrx/pdfium'da kalıyor, YAZMA burada yeni bayt üretiyor.
///
/// Testler cihazsız koşar (saf Dart + Syncfusion) — sayfa işlemlerinin
/// gerçekten doğru sayfayı etkilediği METİN ÇIKARARAK doğrulanır, sayfa
/// sayısına bakmakla yetinilmez.
void main() {
  /// İçeriği "P1", "P2"... olan [count] sayfalık belge.
  Uint8List sample(int count) {
    final doc = PdfDocument();
    doc.pageSettings.margins.all = 0;
    final font = PdfStandardFont(PdfFontFamily.helvetica, 24);
    for (var i = 1; i <= count; i++) {
      final page = doc.pages.add();
      page.graphics.drawString(
        'P$i',
        font,
        bounds: const Rect.fromLTWH(40, 40, 200, 60),
      );
    }
    final bytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
    return bytes;
  }

  /// Sayfaların metin içeriği, sırayla.
  List<String> pageTexts(Uint8List bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(doc);
      return [
        for (var i = 0; i < doc.pages.count; i++)
          extractor
              .extractText(startPageIndex: i, endPageIndex: i)
              .replaceAll(RegExp(r'\s+'), ''),
      ];
    } finally {
      doc.dispose();
    }
  }

  int rotationOf(Uint8List bytes, int index) {
    final doc = PdfDocument(inputBytes: bytes);
    try {
      return doc.pages[index].rotation.index;
    } finally {
      doc.dispose();
    }
  }

  group('sayfa sayısı', () {
    test('okunur', () {
      expect(PdfEdit.pageCount(sample(3)), 3);
    });
  });

  group('deletePages', () {
    test('DOĞRU sayfayı siler, kalanların sırası bozulmaz', () {
      final out = PdfEdit.deletePages(sample(4), [1]);
      // KÖK NEDEN kilidi: silme sondan başa yapılmazsa indeksler kayar ve
      // yanlış sayfalar gider.
      expect(pageTexts(out), ['P1', 'P3', 'P4']);
    });

    test('birden çok sayfa aynı anda silinir', () {
      final out = PdfEdit.deletePages(sample(5), [0, 2, 4]);
      expect(pageTexts(out), ['P2', 'P4']);
    });

    test('tüm sayfaları silmeye izin verilmez', () {
      expect(
        () => PdfEdit.deletePages(sample(2), [0, 1]),
        throwsA(isA<PdfEditException>()),
      );
    });

    test('boş seçim ve olmayan sayfa reddedilir', () {
      expect(
        () => PdfEdit.deletePages(sample(2), const []),
        throwsA(isA<PdfEditException>()),
      );
      expect(
        () => PdfEdit.deletePages(sample(2), [5]),
        throwsA(isA<PdfEditException>()),
      );
    });
  });

  group('reorderPages', () {
    test('verilen sırayla dizer', () {
      final out = PdfEdit.reorderPages(sample(3), [2, 0, 1]);
      expect(pageTexts(out), ['P3', 'P1', 'P2']);
    });

    test('alt küme seçilebilir (sayfa çıkarma)', () {
      final out = PdfEdit.reorderPages(sample(4), [3, 1]);
      expect(pageTexts(out), ['P4', 'P2']);
    });

    test('olmayan sayfa reddedilir', () {
      expect(
        () => PdfEdit.reorderPages(sample(2), [0, 7]),
        throwsA(isA<PdfEditException>()),
      );
    });
  });

  group('rotatePages', () {
    test('yalnız seçili sayfayı döndürür ve mevcut açıya EKLER', () {
      final once = PdfEdit.rotatePages(
        sample(2),
        pageIndexes: [1],
        quarterTurns: 1,
      );
      expect(rotationOf(once, 0), 0);
      expect(rotationOf(once, 1), 1);

      final twice = PdfEdit.rotatePages(
        once,
        pageIndexes: [1],
        quarterTurns: 1,
      );
      expect(rotationOf(twice, 1), 2);
    });

    test('dört çeyrek tur başa döner', () {
      final out = PdfEdit.rotatePages(
        sample(1),
        pageIndexes: [0],
        quarterTurns: 4,
      );
      expect(rotationOf(out, 0), 0);
    });

    test('döndürme metni SİLMEZ (içerik yeniden çizilmez)', () {
      final out = PdfEdit.rotatePages(
        sample(2),
        pageIndexes: [0],
        quarterTurns: 1,
      );
      expect(pageTexts(out), ['P1', 'P2']);
    });
  });

  group('burnInk', () {
    InkStroke stroke({int page = 1, int color = 0xFF112233}) => InkStroke(
      page: page,
      color: color,
      width: 0.01,
      points: const [0.1, 0.1, 0.5, 0.5, 0.9, 0.2],
    );

    test('çizim belgeye GÖMÜLÜR (bayt büyür, sayfa sayısı değişmez)', () {
      final before = sample(2);
      final after = PdfEdit.burnInk(before, [stroke(), stroke(page: 2)]);
      expect(PdfEdit.pageCount(after), 2);
      expect(after.length, greaterThan(before.length));
      // Sayfa metni yerinde: damga içeriğin ÜZERİNE çizilir, yerine değil.
      expect(pageTexts(after), ['P1', 'P2']);
    });

    test('belgede olmayan sayfanın çizimi atlanır, iş düşmez', () {
      final out = PdfEdit.burnInk(sample(1), [stroke(), stroke(page: 9)]);
      expect(PdfEdit.pageCount(out), 1);
    });

    test('tek noktalı çizgi ve boş liste reddedilir', () {
      expect(
        () => PdfEdit.burnInk(sample(1), const []),
        throwsA(isA<PdfEditException>()),
      );
      expect(
        () => PdfEdit.burnInk(sample(1), [
          const InkStroke(
            page: 1,
            color: 0xFF000000,
            width: 0.01,
            points: [0.1, 0.1],
          ),
        ]),
        throwsA(isA<PdfEditException>()),
      );
    });

    test('döndürülmüş sayfada da çalışır (damga dönüşümü uygulanır)', () {
      final rotated = PdfEdit.rotatePages(
        sample(1),
        pageIndexes: [0],
        quarterTurns: 1,
      );
      final out = PdfEdit.burnInk(rotated, [stroke()]);
      expect(PdfEdit.pageCount(out), 1);
      expect(rotationOf(out, 0), 1);
    });
  });

  group('burnForSharing / readSharedPdf', () {
    // Font ANA izolede okunur (uygulamada rootBundle, testte diskten): hazır
    // Helvetica WinAnsi kodlu ve içinde ı ğ ş İ yok.
    final font = Uint8List.fromList(
      File('assets/fonts/PTSans-Regular.ttf').readAsBytesSync(),
    );

    PageBubble bubble({
      int page = 1,
      String title = 'Kaynak?',
      String text = 'burayı düzelt: ışığı göster',
      List<PageBubbleRect> rects = const [],
    }) => PageBubble(
      id: 'b$page$title',
      page: page,
      x: 0.5,
      y: 0.4,
      title: title,
      text: text,
      color: 0xFF66BB6A,
      rects: rects,
    );

    Uint8List burn(Uint8List bytes, List<PageBubble> bubbles) =>
        PdfEdit.burnForSharing(
          bytes,
          bubbles: bubbles,
          ink: const [],
          fontBytes: font,
        );

    test('balonun yazısı BELGENİN İÇİNE girer (Türkçe harfler bozulmadan)', () {
      final after = burn(sample(2), [
        bubble(),
        bubble(page: 2, title: 'Sunum', text: 'şunu göster'),
      ]);
      expect(PdfEdit.pageCount(after), 2);
      final texts = pageTexts(after);
      // Sayfanın kendi metni yerinde: damga içeriğin ÜZERİNE basılır.
      expect(texts[0], contains('P1'));
      expect(texts[0], contains('Kaynak?'));
      expect(texts[0], contains('ışığı'));
      expect(texts[1], contains('şunu'));
      // Balon YALNIZ kendi sayfasına basılır.
      expect(texts[0], isNot(contains('şunu')));
    });

    test('vurgu (yazısız) da basılır — bayt büyür, metin bozulmaz', () {
      final before = sample(1);
      final after = burn(before, [
        bubble(
          title: '',
          text: '',
          rects: const [PageBubbleRect(0.1, 0.2, 0.9, 0.24)],
        ),
      ]);
      expect(after.length, greaterThan(before.length));
      expect(pageTexts(after), ['P1']);
    });

    test('boş balon ve olmayan sayfa atlanır', () {
      // Yazısı ve vurgusu olmayan serbest balon: basılacak bir şeyi yok.
      expect(
        () => burn(sample(1), [bubble(title: '', text: '')]),
        throwsA(isA<PdfEditException>()),
      );
      expect(
        () => burn(sample(1), const []),
        throwsA(isA<PdfEditException>()),
      );
      // Belgede olmayan sayfanın balonu işi düşürmez.
      final out = burn(sample(1), [bubble(), bubble(page: 9, title: 'Yok')]);
      expect(pageTexts(out).single, isNot(contains('Yok')));
    });

    test('döndürülmüş sayfada da çalışır (damga dönüşümü uygulanır)', () {
      final rotated = PdfEdit.rotatePages(
        sample(1),
        pageIndexes: [0],
        quarterTurns: 1,
      );
      final out = burn(rotated, [bubble()]);
      expect(PdfEdit.pageCount(out), 1);
      expect(rotationOf(out, 0), 1);
    });

    // ASIL KİLİT: paylaşılan dosya Notlar'da DÜZENLENEBİLİR açılmalı. Damga
    // katmanı sökülünce sayfa ilk hâline döner ve balonlar veriden gelir;
    // sökülmeseydi balonlar iki kez (basılı + canlı) görünürdü.
    test('gidiş-dönüş: katman sökülür, balonlar veri olarak geri gelir', () {
      final source = sample(2);
      final shared = PdfEdit.burnForSharing(
        source,
        bubbles: [bubble(), bubble(page: 2, title: 'Sunum', text: 'şunu')],
        ink: const [
          InkStroke(
            page: 1,
            color: 0xFFEF5350,
            width: 0.01,
            points: [0.1, 0.1, 0.5, 0.5, 0.9, 0.2],
          ),
        ],
        fontBytes: font,
      );
      expect(pageTexts(shared)[0], contains('Kaynak?'));

      final back = PdfEdit.readSharedPdf(shared)!;
      expect(back.bubbles, hasLength(2));
      expect(back.bubbles.first.title, 'Kaynak?');
      expect(back.bubbles.first.text, contains('ışığı'));
      expect(back.bubbles.last.page, 2);
      expect(back.ink.single.color, 0xFFEF5350);
      expect(back.ink.single.points, hasLength(6));
      // Damga sayfadan KALKMIŞ olmalı; belgenin kendi metni durmalı.
      final cleaned = pageTexts(back.bytes);
      expect(cleaned[0], contains('P1'));
      expect(cleaned[1], contains('P2'));
      expect(cleaned[0], isNot(contains('Kaynak?')));
      expect(cleaned[1], isNot(contains('şunu')));
      // Veri de sökülür: aynı dosya ikinci kez okunursa balonlar çiftlenmesin.
      expect(PdfEdit.readSharedPdf(back.bytes), isNull);
    });

    test('sıradan PDF null döner (normal ek yolu)', () {
      expect(PdfEdit.readSharedPdf(sample(1)), isNull);
    });
  });

  group('stampTransform', () {
    test('döndürmesiz sayfada birim dönüşüm', () {
      final t = stampTransform(const Size(600, 800), 0);
      expect(t.angle, 0);
      expect(t.translate, Offset.zero);
    });

    test('çeyrek turlarda köşe ve açı eşleşir', () {
      const size = Size(600, 800);
      expect(stampTransform(size, 1).angle, 90);
      expect(stampTransform(size, 1).translate, const Offset(600, 0));
      expect(stampTransform(size, 2).translate, const Offset(600, 800));
      expect(stampTransform(size, 3).angle, -90);
      expect(stampTransform(size, 3).translate, const Offset(0, 800));
    });
  });

  group('sayfa kimliği bakımı (notlar sayfasıyla taşınır)', () {
    Attachment doc({List<String> pageIds = const []}) => Attachment(
      id: 'a1',
      kind: AttachmentKind.pdf,
      fileName: 'ders.pdf',
      mimeType: 'application/pdf',
      pageIds: pageIds,
    );

    test(
      'kimlikler türetilmiş hâlleriyle somutlaşır (eski notlar sahipsiz kalmaz)',
      () {
        // Bugüne kadar liste BOŞTU ve kimlik `p<N>` olarak türetiliyordu; ilk
        // düzenlemede rastgele yeni kimlikler üretilseydi `a1#p3` anahtarıyla
        // kayıtlı notlar sahipsiz kalırdı.
        expect(materializePageIds(doc(), 3), ['p1', 'p2', 'p3']);
        expect(materializePageIds(doc(pageIds: ['x', 'y']), 3), [
          'x',
          'y',
          'p3',
        ]);
      },
    );

    test('sıralama kimlikleri taşır, notlar sayfasını izler', () {
      final ids = materializePageIds(doc(), 3);
      final next = reorderPageIds(ids, [2, 0, 1]);
      expect(next, ['p3', 'p1', 'p2']);
      // 3. sayfanın notu artık 1. sayfanın notudur; anahtar DEĞİŞMEDİ.
      final after = doc(pageIds: next);
      expect(pageNoteKey(after, 1), 'a1#p3');
    });

    test('silinen sayfanın kimliği listeden düşer', () {
      final ids = materializePageIds(doc(), 4);
      final next = reorderPageIds(ids, [0, 2, 3]);
      expect(next, ['p1', 'p3', 'p4']);
      // Silinen sayfanın notu artık bir sayfaya çözülmez (ama kayıtta kalır).
      expect(pageNumberOfId(doc(pageIds: next), 'p2'), isNull);
      expect(pageNumberOfId(doc(pageIds: next), 'p3'), 2);
    });

    test('silme sonrası kalan notlar KAYMAZ (kök senaryo)', () {
      // 1-2-3-4 sayfalı belgede 4. sayfaya not var; 2. sayfa siliniyor.
      // Kimlik olmasaydı not "4. sayfa" diye kayıtlıyken belge 3 sayfaya
      // düşer ve not görünmez ya da 3. sayfaya kayardı.
      final before = doc();
      final key = pageNoteKey(before, 4);
      final after = doc(
        pageIds: reorderPageIds(materializePageIds(before, 4), [0, 2, 3]),
      );
      expect(key, 'a1#p4');
      expect(pageNoteKey(after, 3), key);
      final notes = {key: 'dorduncu sayfanin notu'};
      final ordered = orderedPageNotes(attachment: after, pageNotes: notes);
      expect(ordered.single.page, 3);
      expect(ordered.single.text, 'dorduncu sayfanin notu');
    });
  });
}
