import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/arrow.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';

/// OK aracı (kullanıcı isteği 2026-08-08: "bir de ok işareti çekme
/// istiyorum"): parmağın bastığı yer kuyruk, kaldırdığı yer uçtur.
///
/// Ok, serbest çizgiyle AYNI veri yapısında yaşıyor ([InkStroke.arrow]) —
/// böylece kaydetme, senkron, geri al, silgi ve paylaşılan PDF damgası tek
/// yoldan çalışıyor. Buradaki testler o tek yolun uçlarını tutuyor.
void main() {
  group('kayıt', () {
    test('ok bayrağı gidiş-dönüşte korunur, düz çizgide YAZILMAZ', () {
      const arrow = InkStroke(
        page: 2,
        color: 0xFFE53935,
        width: 0.005,
        points: [0.1, 0.2, 0.6, 0.7],
        arrow: true,
      );
      expect(arrow.toMap()['a'], isTrue);
      expect(InkStroke.fromMap(arrow.toMap()).arrow, isTrue);

      const plain = InkStroke(
        page: 1,
        color: 0,
        width: 0.004,
        points: [0, 0, 0.1, 0.1],
      );
      // Eski çizimlerin şeması büyümesin: alan yalnız true iken yazılır.
      expect(plain.toMap().containsKey('a'), isFalse);
      expect(InkStroke.fromMap(plain.toMap()).arrow, isFalse);
    });

    test('kırpma okluğu korur', () {
      final out = cropInk(
        const [
          InkStroke(
            page: 1,
            color: 0,
            width: 0.01,
            points: [0.2, 0.2, 0.6, 0.6],
            arrow: true,
          ),
        ],
        left: 0.1,
        top: 0.1,
        right: 0.9,
        bottom: 0.9,
      );
      expect(out.single.arrow, isTrue);
    });
  });

  group('geometri', () {
    test('başlık okun UCUNDA ve eksene göre simetrik', () {
      const tail = Offset(20, 100);
      const head = Offset(120, 100);
      final geo = arrowGeometry(tail, head, 3);
      // Gövde başlığın dibinde biter: ucun sivriliğini bozmasın.
      expect(geo.lineEnd.dx, lessThan(head.dx));
      expect(geo.lineEnd.dx, greaterThan(tail.dx));
      // Yatay okta kanatlar uçtan geride ve eksenin iki yanında.
      expect(geo.left.dx, lessThan(head.dx));
      expect(geo.right.dx, lessThan(head.dx));
      expect(geo.left.dy - 100, closeTo(-(geo.right.dy - 100), 1e-9));
      expect(geo.left.dy, isNot(closeTo(geo.right.dy, 0.5)));
    });

    test('başlık KISA okta okun kendisini yutmaz', () {
      final geo = arrowGeometry(const Offset(0, 0), const Offset(10, 0), 20);
      // Kalem 20 px olsa da başlık okun yarısını geçmez.
      expect(geo.left.dx, greaterThan(0));
      expect(geo.right.dx, greaterThan(0));
    });

    test('sıfır uzunlukta ok çökmez', () {
      final geo = arrowGeometry(const Offset(5, 5), const Offset(5, 5), 3);
      expect(geo.lineEnd, const Offset(5, 5));
    });
  });

  group('denetleyici', () {
    InkController controller() =>
        InkController(initial: const [], onChanged: (_) {});

    test('ok aracı İKİ noktalı çizgi üretir, ucu parmakla taşınır', () {
      final c = controller()..setArrow(true);
      const size = Size(200, 400);
      c
        ..pointerDown(1, const Offset(20, 40), size)
        ..pointerMove(1, const Offset(60, 80), size)
        ..pointerMove(1, const Offset(120, 200), size);
      final stroke = c.ink.single;
      expect(stroke.arrow, isTrue);
      // Serbest çizgi olsaydı nokta EKLENİRDİ; okta uç taşınır.
      expect(stroke.points, hasLength(4));
      expect(stroke.points[0], closeTo(0.1, 1e-9));
      expect(stroke.points[2], closeTo(0.6, 1e-9));
      expect(stroke.points[3], closeTo(0.5, 1e-9));
      c.pointerUp();
      expect(c.ink, hasLength(1));
    });

    test('sürüklenmeden bırakılan ok atılır (yönü olmayan kırıntı)', () {
      final c = controller()..setArrow(true);
      const size = Size(200, 400);
      c
        ..pointerDown(1, const Offset(20, 40), size)
        ..pointerUp();
      expect(c.ink, isEmpty);
    });

    test('kalem seçmek ok aracını kapatır, ok silgiyi kapatır', () {
      final c = controller()..setArrow(true);
      expect(c.arrow, isTrue);
      c.setEraser(true);
      expect(c.arrow, isFalse);
      c.setArrow(true);
      expect(c.eraser, isFalse);
      c.setPen(InkPen.marker);
      expect(c.arrow, isFalse);
    });

    test('silgi okun GÖVDESİNE dokununca da siler', () {
      final c = InkController(
        initial: const [
          InkStroke(
            page: 1,
            color: 0,
            width: 0.01,
            points: [0.1, 0.1, 0.9, 0.9],
            arrow: true,
          ),
        ],
        onChanged: (_) {},
      )..setEraser(true);
      // Okun tam ortası: iki uçtan da uzak.
      c.pointerDown(1, const Offset(100, 200), const Size(200, 400));
      expect(c.ink, isEmpty);
    });
  });
}
