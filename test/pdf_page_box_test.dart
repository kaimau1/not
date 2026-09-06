import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';

/// **SAYFAYA GÖMÜLÜ PDF** (kullanıcı isteği 2026-09-06: "PDF'yi sayfaya
/// entegre etme, aynı görsel gibi sayfaya yerleşir ancak sayfa
/// değiştirilebilir").
///
/// Kutunun kendisi pdfium'a (yani gerçek bir cihaza) muhtaç; ölçülebilen —
/// ve bozulunca kullanıcının canını yakan — kısım kutunun MANTIĞI: sayfa
/// sınırları, yer imleri, otomatik geçişin başa dönmesi, döndürülmüş kutunun
/// en-boyu ve ekin sayfada mı şeritte mi durduğu.
void main() {
  Attachment pdf({
    bool onPage = false,
    int page = 1,
    List<int> marks = const [],
    int turns = 0,
  }) => Attachment(
    id: 'a1',
    kind: AttachmentKind.pdf,
    fileName: 'sozlesme.pdf',
    mimeType: 'application/pdf',
    onPage: onPage,
    pdfPage: page,
    pdfMarks: marks,
    pdfTurns: turns,
  );

  group('clampPdfPage', () {
    test('belge açılmadan (sayfa sayısı bilinmezken) numara korunur', () {
      expect(clampPdfPage(7, 0), 7);
      // Numara yine de 1'in altına inemez.
      expect(clampPdfPage(0, 0), 1);
    });

    test('sınırların dışı kırpılır', () {
      expect(clampPdfPage(0, 10), 1);
      expect(clampPdfPage(11, 10), 10);
      expect(clampPdfPage(4, 10), 4);
    });

    test('silinen sayfalardan sonra numara sona düşer', () {
      // Belge 20 sayfaydı, kullanıcı 12. sayfadaydı; sayfalar silinip 5'e
      // indiyse kutu boş bir sayfa değil SON sayfayı gösterir.
      expect(clampPdfPage(12, 5), 5);
    });
  });

  group('autoPlayNext', () {
    test('sonuncudan sonra BAŞA döner', () {
      expect(autoPlayNext(3, 3), 1);
      expect(autoPlayNext(1, 3), 2);
    });

    test('tek sayfalık belgede yerinde kalır', () {
      expect(autoPlayNext(1, 1), 1);
    });

    test('belge açılmadan ilerlemez', () {
      expect(autoPlayNext(2, 0), 2);
    });
  });

  group('togglePdfMark', () {
    test('yer imi ekler ve liste SIRALI kalır', () {
      expect(togglePdfMark(const [7, 2], 4), [2, 4, 7]);
    });

    test('var olan yer imi kaldırılır', () {
      expect(togglePdfMark(const [2, 4, 7], 4), [2, 7]);
    });

    test('aynı sayfa iki kez eklenmez', () {
      final once = togglePdfMark(const [], 3);
      expect(togglePdfMark(togglePdfMark(once, 3), 3), [3]);
    });
  });

  group('pdfBoxAspect', () {
    test('döndürülmemiş kutu sayfanın oranını alır', () {
      expect(pdfBoxAspect(600, 800, 0), closeTo(0.75, 0.0001));
    });

    test('90° ve 270°de en-boy TAKAS olur', () {
      expect(pdfBoxAspect(600, 800, 1), closeTo(800 / 600, 0.0001));
      expect(pdfBoxAspect(600, 800, 3), closeTo(800 / 600, 0.0001));
      expect(pdfBoxAspect(600, 800, 2), closeTo(0.75, 0.0001));
    });

    test('ölçüsü bilinmeyen belge KARE sayılır', () {
      expect(pdfBoxAspect(0, 0, 0), 1);
    });
  });

  group('Attachment.floatsOnPage', () {
    test('PDF yalnız onPage ile sayfaya çıkar', () {
      expect(pdf().floatsOnPage, isFalse);
      expect(pdf(onPage: true).floatsOnPage, isTrue);
    });

    test('ESKİ PDF ekleri şeritte kalır (asFile: false olsa da)', () {
      // Kök neden: `asFile` anlamını PDF için tersine çevirmek, var olan
      // bütün notların PDF'ini bir anda sayfanın ortasına taşırdı.
      final old = Attachment.fromMap({
        'id': 'a1',
        'kind': 'pdf',
        'fileName': 'eski.pdf',
        'mimeType': 'application/pdf',
        'asFile': false,
      });
      expect(old.floatsOnPage, isFalse);
      expect(old.onPage, isFalse);
      expect(old.pdfPage, 1);
    });

    test('görselin yeri hâlâ asFile ile belirlenir', () {
      final image = Attachment(
        id: 'i1',
        kind: AttachmentKind.image,
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
      );
      expect(image.floatsOnPage, isTrue);
      expect(image.copyWith(asFile: true).floatsOnPage, isFalse);
    });
  });

  group('kayıt (toMap/fromMap)', () {
    test('varsayılan değerler kayda YAZILMAZ (eski şema büyümez)', () {
      final map = pdf().toMap();
      expect(map.containsKey('onPage'), isFalse);
      expect(map.containsKey('pdfPage'), isFalse);
      expect(map.containsKey('pdfTurns'), isFalse);
      expect(map.containsKey('pdfMarks'), isFalse);
    });

    test('sayfa, yer imleri ve döndürme gidip geri gelir', () {
      final map = pdf(
        onPage: true,
        page: 12,
        marks: const [3, 12],
        turns: 1,
      ).toMap()
        // `createdAt` sunucu damgası olarak yazılıyor; okuma yolunda
        // Timestamp bekleniyor (kayda giren gerçek belgede de öyle olur).
        ..remove('createdAt');
      final back = Attachment.fromMap(Map<String, dynamic>.from(map));
      expect(back.onPage, isTrue);
      expect(back.pdfPage, 12);
      expect(back.pdfMarks, [3, 12]);
      expect(back.pdfTurns, 1);
      expect(back.floatsOnPage, isTrue);
    });

    test('uzaktan gelen anlık görüntü YEREL sayfayı ezmez', () {
      // Editör açıkken gelen her Firestore anlık görüntüsü ekleri olduğu gibi
      // benimsiyor; kullanıcının az önce çevirdiği sayfa geri sıçramamalı
      // (aynı kural konum/boyut için de geçerli — bkz. withLayoutOf).
      final remote = pdf(onPage: true);
      final local = pdf(onPage: true, page: 9, marks: const [9], turns: 2);
      final merged = remote.withLayoutOf(local);
      expect(merged.pdfPage, 9);
      expect(merged.pdfMarks, [9]);
      expect(merged.pdfTurns, 2);
      expect(merged.onPage, isTrue);
    });
  });
}
