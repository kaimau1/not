import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

/// Kalem (stylus) özellikleri (kullanıcı isteği 2026-10-23: "tablet modunda
/// kalem desteği, parmakla basınca yazmayıp kalemle yazması, Samsung
/// Notes'tan geri kalmamalıyız"): yalnız kalem kipi, basınç, şekiller,
/// geri al/yinele ve kalem hafızası.
void main() {
  const size = Size(200, 400);

  setUp(InkToolMemory.reset);

  InkController controller({List<InkStroke> initial = const []}) =>
      InkController(initial: initial, onChanged: (_) {});

  group('yalnız kalem', () {
    test('açıkken parmak çizmez, kalem çizer', () {
      final c = controller()..setPenOnly(true);
      c
        ..pointerDown(1, const Offset(10, 10), size, pointer: 1)
        ..pointerMove(1, const Offset(50, 50), size, pointer: 1)
        ..pointerUp(pointer: 1);
      expect(c.ink, isEmpty, reason: 'parmak iz bırakmamalı');
      c
        ..pointerDown(
          1,
          const Offset(10, 10),
          size,
          pointer: 2,
          kind: PointerDeviceKind.stylus,
        )
        ..pointerMove(1, const Offset(60, 80), size, pointer: 2)
        ..pointerUp(pointer: 2, kind: PointerDeviceKind.stylus);
      expect(c.ink, hasLength(1));
    });

    test('kalem yazarken değen parmak (avuç) çizgiyi bozmaz', () {
      final c = controller()..setPenOnly(true);
      c
        ..pointerDown(
          1,
          const Offset(10, 10),
          size,
          pointer: 1,
          kind: PointerDeviceKind.stylus,
        )
        // Avuç içi: yalnız kalem kipinde sayılmaz, çizgi iptal edilmez.
        ..pointerDown(1, const Offset(150, 300), size, pointer: 2)
        ..pointerMove(1, const Offset(60, 80), size, pointer: 1)
        ..pointerUp(pointer: 2)
        ..pointerUp(pointer: 1, kind: PointerDeviceKind.stylus);
      expect(c.ink, hasLength(1));
      expect(c.ink.single.points, hasLength(4));
    });

    test('ilk kalem dokunuşu "yalnız kalem"i kendiliğinden açar', () {
      final c = controller();
      expect(c.penOnly, isFalse);
      c.pointerDown(
        1,
        const Offset(10, 10),
        size,
        pointer: 1,
        kind: PointerDeviceKind.stylus,
      );
      expect(c.penOnly, isTrue);
      expect(InkToolMemory.penOnly, isTrue);
    });

    test('kullanıcı kapattıysa kalem dokunuşu yeniden AÇMAZ', () {
      final c = controller()..setPenOnly(false);
      c.pointerDown(
        1,
        const Offset(10, 10),
        size,
        pointer: 1,
        kind: PointerDeviceKind.stylus,
      );
      expect(c.penOnly, isFalse);
    });
  });

  group('basınç ve silgi', () {
    test('kalem basıncı nokta başına kaydedilir ve gidiş-dönüşte korunur', () {
      final c = controller();
      c
        ..pointerDown(
          1,
          const Offset(10, 10),
          size,
          pointer: 1,
          kind: PointerDeviceKind.stylus,
          pressure: 0.2,
        )
        ..pointerMove(1, const Offset(60, 80), size, pointer: 1, pressure: 0.9)
        ..pointerUp(pointer: 1, kind: PointerDeviceKind.stylus);
      final stroke = c.ink.single;
      expect(stroke.hasPressure, isTrue);
      expect(stroke.pressures, [0.2, 0.9]);
      final back = InkStroke.fromMap(stroke.toMap());
      expect(back.hasPressure, isTrue);
      expect(back.pressures![1], closeTo(0.9, 1e-6));
    });

    test('parmakla çizgide basınç YAZILMAZ (şema büyümez)', () {
      final c = controller();
      c
        ..pointerDown(1, const Offset(10, 10), size)
        ..pointerMove(1, const Offset(60, 80), size)
        ..pointerUp();
      expect(c.ink.single.toMap().containsKey('q'), isFalse);
    });

    test('kalemin yan düğmesi o çizgi boyunca SİLER', () {
      final c = controller(
        initial: const [
          InkStroke(page: 1, color: 0, width: 0.01, points: [0.5, 0.5]),
        ],
      );
      c
        ..pointerDown(
          1,
          const Offset(100, 200),
          size,
          pointer: 1,
          kind: PointerDeviceKind.stylus,
          stylusEraser: true,
        )
        ..pointerUp(pointer: 1, kind: PointerDeviceKind.stylus);
      expect(c.ink, isEmpty);
      expect(c.eraser, isFalse, reason: 'araç kalıcı olarak değişmez');
    });
  });

  group('şekiller', () {
    test('dikdörtgen köşeden köşeye beş noktalı kapalı çizgi', () {
      final c = controller()..setShape(InkShape.rectangle);
      c
        ..pointerDown(1, const Offset(20, 40), size)
        ..pointerMove(1, const Offset(60, 80), size)
        ..pointerMove(1, const Offset(100, 200), size)
        ..pointerUp();
      final p = c.ink.single.points;
      expect(p, hasLength(10));
      expect(p.first, closeTo(0.1, 1e-9));
      expect(p[4], closeTo(0.5, 1e-9));
      expect(p[5], closeTo(0.5, 1e-9));
      expect(c.ink.single.arrow, isFalse);
    });

    test('sürüklenmeden bırakılan şekil atılır', () {
      final c = controller()..setShape(InkShape.ellipse);
      c
        ..pointerDown(1, const Offset(20, 40), size)
        ..pointerUp();
      expect(c.ink, isEmpty);
    });

    test('silgi düz çizginin ORTASINA dokununca da siler', () {
      final c = controller()..setShape(InkShape.line);
      c
        ..pointerDown(1, const Offset(0, 0), size)
        ..pointerMove(1, const Offset(200, 400), size)
        ..pointerUp()
        ..setEraser(true)
        ..pointerDown(1, const Offset(100, 200), size)
        ..pointerUp();
      expect(c.ink, isEmpty);
    });

    test('kalem seçmek şekli kapatır', () {
      final c = controller()..setShape(InkShape.line);
      c.setPen(InkPen.marker);
      expect(c.shape, isNull);
    });
  });

  group('geri al / yinele ve hafıza', () {
    test('silinen çizgi geri al ile döner, yinele ile yeniden silinir', () {
      final c = controller();
      c
        ..pointerDown(1, const Offset(10, 10), size)
        ..pointerMove(1, const Offset(60, 80), size)
        ..pointerUp()
        ..setEraser(true)
        ..pointerDown(1, const Offset(10, 10), size)
        ..pointerUp();
      expect(c.ink, isEmpty);
      c.undo();
      expect(c.ink, hasLength(1));
      expect(c.canRedo, isTrue);
      c.redo();
      expect(c.ink, isEmpty);
    });

    test('şeffaflık tükenmeze uygulanır, fosforlu sabit kalır', () {
      final c = controller()..setOpacity(0.5);
      expect((c.penColor.a * 255).round(), closeTo(128, 1));
      c.setPen(InkPen.highlighter);
      expect((c.penColor.a * 255).round(), InkPen.highlighter.alpha);
    });

    test('yeni denetleyici son kalemi hatırlar', () {
      controller()
        ..setPen(InkPen.marker)
        ..setColor(const Color(0xFF1E88E5))
        ..setWidth(15);
      final next = controller();
      expect(next.pen, InkPen.marker);
      expect(next.color.toARGB32(), 0xFF1E88E5);
      expect(next.widthPx, 15);
    });
  });
}
