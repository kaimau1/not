import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/image_layout.dart';

/// Sayfadaki görsel yerleşiminin matematiği: yeni görselin boş yeri, kenar
/// yapışması/çarpışması ve satıra sığdırma.
void main() {
  group('packSlot', () {
    test('ilk görsel çapanın hizasına, sol kenara oturur', () {
      final slot = packSlot(
        occupied: const [],
        columnWidth: 300,
        width: 96,
        height: 128,
        anchorTop: 120,
        topLimit: 80,
      );
      expect(slot.left, 0);
      expect(slot.top, 120);
    });

    test('çapa üst sınırın üstündeyse üst sınıra çekilir', () {
      final slot = packSlot(
        occupied: const [],
        columnWidth: 300,
        width: 96,
        height: 128,
        anchorTop: 10,
        topLimit: 80,
      );
      expect(slot.top, 80);
    });

    test('ikinci görsel birincinin YANINA gider, üstüne değil', () {
      final first = Rect.fromLTWH(0, 100, 96, 128);
      final slot = packSlot(
        occupied: [first],
        columnWidth: 300,
        width: 96,
        height: 128,
        anchorTop: 100,
        topLimit: 80,
      );
      expect(slot.top, 100);
      expect(slot.left, 96 + kImageGap);
      expect(
        Rect.fromLTWH(slot.left, slot.top, 96, 128).overlaps(first),
        isFalse,
      );
    });

    test('satır dolunca alta iner ve hiçbirine binmez', () {
      // 300 dp'lik sütuna 96 dp'lik üç görsel sığar (2×8 dp boşlukla 304 > 300
      // olduğu için üçüncüsü tam sığmaz): üçüncü görsel alt satıra düşmeli.
      final boxes = <Rect>[
        Rect.fromLTWH(0, 100, 96, 128),
        Rect.fromLTWH(104, 100, 96, 128),
        Rect.fromLTWH(208, 100, 96, 128),
      ];
      final slot = packSlot(
        occupied: boxes,
        columnWidth: 300,
        width: 96,
        height: 128,
        anchorTop: 100,
        topLimit: 80,
      );
      expect(slot.top, 100 + 128 + kImageGap);
      for (final b in boxes) {
        expect(
          Rect.fromLTWH(slot.left, slot.top, 96, 128).overlaps(b),
          isFalse,
        );
      }
    });

    test('üst üste eklenen beş görselin hiçbiri çakışmaz', () {
      // KÖK NEDEN TESTİ: eskiden ölçüsüz yolda hepsi aynı çizgiye biniyordu.
      final placed = <Rect>[];
      for (var i = 0; i < 5; i++) {
        final slot = packSlot(
          occupied: placed,
          columnWidth: 300,
          width: 96,
          height: 128,
          anchorTop: 100,
          topLimit: 80,
        );
        final rect = Rect.fromLTWH(slot.left, slot.top, 96, 128);
        for (final other in placed) {
          expect(rect.overlaps(other), isFalse, reason: '$i. görsel çakıştı');
        }
        placed.add(rect);
      }
      // İlk üçü aynı satırda değil (300 dp'ye iki tane sığıyor), ama en az iki
      // görsel yan yana durmalı — yığın artık yalnız dikey değil.
      expect(placed.where((r) => r.top == placed.first.top).length, 2);
    });
  });

  group('snapMove', () {
    test('sayfanın sağ kenarına yapışır ve kılavuz bildirir', () {
      final res = snapMove(
        rect: const Rect.fromLTWH(196, 200, 100, 80),
        others: const [],
        columnWidth: 300,
        topLimit: 0,
      );
      expect(res.left, 200);
      expect(res.guides, contains(const AlignGuide(vertical: true, pos: 300)));
    });

    test('komşunun sol kenarıyla hizalanır', () {
      final res = snapMove(
        rect: const Rect.fromLTWH(46, 400, 100, 80),
        others: const [Rect.fromLTWH(50, 100, 120, 90)],
        columnWidth: 300,
        topLimit: 0,
      );
      expect(res.left, 50);
      expect(res.guides, contains(const AlignGuide(vertical: true, pos: 50)));
    });

    test('hafif temasta komşunun kenarında durur, iç içe geçmez', () {
      final other = const Rect.fromLTWH(0, 100, 120, 100);
      // Parmak komşunun 6 dp içine girdi: engel devrede.
      final res = snapMove(
        rect: const Rect.fromLTWH(114, 100, 100, 100),
        others: [other],
        columnWidth: 400,
        topLimit: 0,
      );
      expect(
        Rect.fromLTWH(res.left, res.top, 100, 100).overlaps(other),
        isFalse,
      );
    });

    test('zorlanınca (derin itişte) üst üste binmeye izin verilir', () {
      final other = const Rect.fromLTWH(0, 100, 120, 100);
      // Parmak komşunun 60 dp içinde: kullanıcı bilerek üstüne koyuyor.
      final res = snapMove(
        rect: const Rect.fromLTWH(60, 100, 100, 100),
        others: [other],
        columnWidth: 400,
        topLimit: 0,
      );
      expect(res.left, 60);
      expect(
        Rect.fromLTWH(res.left, res.top, 100, 100).overlaps(other),
        isTrue,
      );
    });

    test('üst sınırın üstüne çıkamaz', () {
      final res = snapMove(
        rect: const Rect.fromLTWH(10, -40, 100, 80),
        others: const [],
        columnWidth: 300,
        topLimit: 64,
      );
      expect(res.top, 64);
    });

    test('yakınında hiçbir hiza yoksa parmağın yerinde kalır', () {
      final res = snapMove(
        rect: const Rect.fromLTWH(37, 211, 100, 80),
        others: const [],
        columnWidth: 300,
        topLimit: 0,
      );
      expect(res.left, 37);
      expect(res.top, 211);
      expect(res.guides, isEmpty);
    });
  });

  group('snapWidth', () {
    test('sağ kenar sayfanın kenarına yapışır', () {
      final res = snapWidth(
        left: 100,
        width: 194,
        others: const [],
        columnWidth: 300,
      );
      expect(res.width, 200);
      expect(res.guides, contains(const AlignGuide(vertical: true, pos: 300)));
    });

    test('komşuyla EŞİT genişliğe oturur (kılavuz çizilmez)', () {
      final res = snapWidth(
        left: 0,
        width: 124,
        others: const [Rect.fromLTWH(160, 0, 120, 90)],
        columnWidth: 300,
      );
      expect(res.width, 120);
      expect(res.guides, isEmpty);
    });
  });

  group('fitRowsLayout', () {
    test('üç görsel satırı tam doldurur, kenarları yapışır', () {
      final fits = fitRowsLayout(
        aspects: const [0.5, 0.5, 0.5],
        columnWidth: 300,
        top: 100,
      );
      expect(fits.length, 3);
      for (final f in fits) {
        expect(f.widthFrac, closeTo(1 / 3, 0.0001));
        expect(f.top, 100);
      }
      expect(fits[0].leftFrac, closeTo(0, 0.0001));
      expect(fits[1].leftFrac, closeTo(1 / 3, 0.0001));
      // Son görselin sağ kenarı sayfanın sağ kenarına yapışır.
      expect(fits[2].leftFrac + fits[2].widthFrac, closeTo(1, 0.0001));
    });

    test('farklı oranlarda satırdaki yükseklikler eşitlenir', () {
      const columnWidth = 300.0;
      final fits = fitRowsLayout(
        aspects: const [2, 0.5],
        columnWidth: columnWidth,
        top: 0,
      );
      final h0 = fits[0].widthFrac * columnWidth / 2;
      final h1 = fits[1].widthFrac * columnWidth / 0.5;
      expect(h0, closeTo(h1, 0.0001));
      expect(fits[0].widthFrac + fits[1].widthFrac, closeTo(1, 0.0001));
    });

    test('altı görsel iki satıra bölünür (3 + 3)', () {
      final fits = fitRowsLayout(
        aspects: const [1, 1, 1, 1, 1, 1],
        columnWidth: 300,
        top: 50,
      );
      expect(fits.length, 6);
      expect(fits.take(3).every((f) => f.top == 50), isTrue);
      final secondTop = fits[3].top;
      expect(secondTop, greaterThan(50));
      expect(fits.skip(3).every((f) => f.top == secondTop), isTrue);
      expect(fits[3].leftFrac, closeTo(0, 0.0001));
      expect(fits[5].leftFrac + fits[5].widthFrac, closeTo(1, 0.0001));
    });

    test('boşluk verilince satır yine tam doldurulur', () {
      const columnWidth = 300.0;
      final fits = fitRowsLayout(
        aspects: const [1, 1],
        columnWidth: columnWidth,
        top: 0,
        gap: 10,
      );
      expect(fits[0].widthFrac * columnWidth, closeTo(145, 0.0001));
      expect(fits[1].leftFrac * columnWidth, closeTo(155, 0.0001));
      expect(fits[1].leftFrac + fits[1].widthFrac, closeTo(1, 0.0001));
    });

    test('boş seçim boş liste döndürür', () {
      expect(fitRowsLayout(aspects: const [], columnWidth: 300, top: 0), []);
    });
  });

  group('equalWidthFrac', () {
    test('ortalamayı alır', () {
      expect(equalWidthFrac(const [0.2, 0.4]), closeTo(0.3, 0.0001));
    });

    test('en küçük genişliğin altına inmez', () {
      expect(equalWidthFrac(const [0.01, 0.01]), 0.15);
    });

    test('boş listede varsayılana döner', () {
      expect(equalWidthFrac(const []), 0.5);
    });
  });

  group('fitRowsLayout — uç durumlar', () {
    test('satırdaki görseller en az genişliğin altına düşmez', () {
      final fits = fitRowsLayout(
        aspects: const [1, 1, 1, 1, 1, 1],
        columnWidth: 300,
        top: 0,
        maxPerRow: 6,
      );
      for (final f in fits) {
        expect(f.widthFrac, greaterThanOrEqualTo(0.15));
      }
    });

    test('tek görselde satır tam genişlik olur', () {
      final fits = fitRowsLayout(
        aspects: const [1.5],
        columnWidth: 300,
        top: 40,
      );
      expect(fits.length, 1);
      expect(fits.first.widthFrac, closeTo(1, 0.0001));
      expect(fits.first.leftFrac, 0);
      expect(fits.first.top, 40);
    });

    test('oranı bilinmeyen (0) görsel kare sayılır, bölme hatası olmaz', () {
      final fits = fitRowsLayout(
        aspects: const [0, 1],
        columnWidth: 300,
        top: 0,
      );
      expect(fits.length, 2);
      for (final f in fits) {
        expect(f.widthFrac.isFinite, isTrue);
        expect(f.widthFrac, greaterThan(0));
      }
    });
  });
}
