import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';

/// Çocuğun KAÇ KEZ yerleştiğini sayar.
class _CountingBox extends SingleChildRenderObjectWidget {
  const _CountingBox({required this.counter, super.child});

  final _LayoutCounter counter;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCountingBox(counter);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderCountingBox).counter = counter;
}

class _LayoutCounter {
  int layouts = 0;
}

class _RenderCountingBox extends RenderProxyBox {
  _RenderCountingBox(this.counter);

  _LayoutCounter counter;

  @override
  void performLayout() {
    counter.layouts++;
    super.performLayout();
  }
}

void main() {
  // KÖK NEDEN (kullanıcı: "yeni öğe ekleyince klavye açılırken kasma devam
  // ediyor ve kasma birikip artıyor sanki"): sayfanın en az yüksekliği
  // `ConstrainedBox` ile veriliyordu ve o, değeri ÇOCUĞUN KISITINA yazar.
  // Klavye açılırken bu değer her karede değiştiği için not sayfasının
  // tamamı — `shrinkWrap` olduğundan her madde satırı tek tek — her karede
  // yeniden yerleşiyordu. Bedel madde sayısıyla orantılıydı; "birikip
  // artıyor" hissi buradan geliyordu.
  testWidgets('en az yükseklik DEĞİŞİNCE çocuk yeniden yerleşmez', (
    tester,
  ) async {
    final counter = _LayoutCounter();
    Future<void> pump(double minHeight) => tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: PageMinHeight(
            minHeight: minHeight,
            child: _CountingBox(
              counter: counter,
              child: const SizedBox(height: 120, width: 300),
            ),
          ),
        ),
      ),
    );

    await pump(600);
    final before = counter.layouts;
    expect(before, greaterThan(0));

    // Klavye açılıyor: gövde kısalıyor, en az yükseklik her karede düşüyor.
    for (final h in [560.0, 480.0, 400.0, 330.0, 300.0]) {
      await pump(h);
    }

    expect(
      counter.layouts,
      before,
      reason: 'en az yükseklik çocuğun kısıtına yazılmamalı',
    );
  });

  testWidgets('sayfa yine de en az verilen kadar uzar', (tester) async {
    Future<void> pump(double minHeight) => tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: PageMinHeight(
            minHeight: minHeight,
            child: const SizedBox(height: 120, width: 300),
          ),
        ),
      ),
    );

    await pump(600);
    expect(tester.getSize(find.byType(PageMinHeight)).height, 600);

    // Çocuk daha uzunsa çocuk kazanır (görselli uzun sayfa).
    await pump(80);
    expect(tester.getSize(find.byType(PageMinHeight)).height, 120);
  });

  // KÖK NEDEN (kullanıcı: "görsel ekleyince sayfaya kasma artıyor", "kasma
  // birikip artıyor sanki"): `cacheWidth` doğrudan kutu genişliğinden
  // hesaplanıyordu, yani bir piksellik değişimde bile BAŞKA bir önbellek
  // anahtarı çıkıyor ve dosya diskten yeniden çözülüyordu. Boyutlandırma
  // sırasında kare başına bir çözdürme, üstelik her kopya görsel önbelleğine
  // ayrı ayrı giriyor ve önbellek dolunca başka görselleri atıyordu.
  group('decodeWidthBucket', () {
    test('yakın genişlikler AYNI kovaya düşer', () {
      const dpr = 3.0;
      final a = decodeWidthBucket(120, dpr);
      final b = decodeWidthBucket(127.4, dpr);
      expect(a, b);
      expect(a! % kDecodeWidthStep, 0);
    });

    test('gösterilen boyuttan asla düşük çözünürlük vermez', () {
      const dpr = 2.0;
      for (final width in [10.0, 99.0, 128.0, 300.5, 1024.0]) {
        expect(
          decodeWidthBucket(width, dpr),
          greaterThanOrEqualTo((width * dpr).ceil()),
          reason: '$width dp',
        );
      }
    });

    test('kova sayısı makul kalır (önbellek şişmesin)', () {
      const dpr = 3.0;
      final buckets = {
        for (var w = 40.0; w <= 420.0; w += 1) decodeWidthBucket(w, dpr),
      };
      expect(buckets.length, lessThanOrEqualTo(6));
    });

    test('ölçülemeyen genişlikte çözdürme sınırı verilmez', () {
      expect(decodeWidthBucket(double.infinity, 3), isNull);
      expect(decodeWidthBucket(0, 3), isNull);
    });
  });
}
