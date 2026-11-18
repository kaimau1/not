import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';

/// U5 (kullanıcı bulgusu 2026-11-18): bildirimin geri sayım çizgisi
/// "takılarak" ilerliyordu — saniyede 8 adımlık `Timer.periodic`, vsync'e
/// bağlı değildi. Çizgi HER KAREDE ilerlemeli, ama widget yeniden kurulmamalı.
void main() {
  testWidgets('çizgi kare başına monoton azalır, yeniden kurulum yok', (
    tester,
  ) async {
    var ended = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SteppedCountdown(
          duration: const Duration(seconds: 2),
          color: const Color(0xFF000000),
          onEnd: () => ended++,
        ),
      ),
    );
    final paintFinder = find.descendant(
      of: find.byType(SteppedCountdown),
      matching: find.byType(CustomPaint),
    );
    final first = tester.widget<CustomPaint>(paintFinder);
    final painter = first.painter! as CountdownPainter;
    var last = painter.remaining;
    expect(last, 1);
    // 1,5 sn boyunca 60 Hz kare: her kare bir öncekinden KESİN küçük.
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = painter.remaining;
      expect(now, lessThan(last), reason: 'kare $i ilerlemedi (takılma)');
      last = now;
    }
    // Aynı widget örneği: her karede kurulum yok, yalnız boyama.
    expect(identical(tester.widget<CustomPaint>(paintFinder), first), isTrue);
    expect(ended, 0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(painter.remaining, 0);
    expect(ended, 1);
  });
}
