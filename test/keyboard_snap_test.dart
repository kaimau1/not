import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';

/// [KeyboardSnap] klavye yüksekliğini KADEMELİ verir: klavye animasyonunun
/// her karesinde değil, kademe atlandıkça yeniden kurar. Kasmanın kök nedeni
/// buydu (bkz. widget'ın kendi açıklaması).
void main() {
  Widget host(double inset, Widget child) => MediaQuery(
    data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: inset)),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );

  testWidgets('ara karelerde çocuk YENİDEN KURULMAZ, kademe atlayınca kurulur', (
    tester,
  ) async {
    var builds = 0;
    final snap = KeyboardSnap(
      builder: (context, inset) {
        builds++;
        return SizedBox(height: inset);
      },
    );

    await tester.pumpWidget(host(0, snap));
    expect(builds, 1);

    // Aynı kademe (0–96) içinde kalan üç ara kare: tek kurulum.
    for (final live in [12.0, 40.0, 90.0]) {
      await tester.pumpWidget(host(live, snap));
    }
    expect(builds, 2, reason: '0 → 96 kademesi bir kez kurulur');

    // Kademe atlandı.
    await tester.pumpWidget(host(140, snap));
    expect(builds, 3);
  });

  testWidgets('animasyon durunca TAM klavye yüksekliğine iner', (tester) async {
    late double seen;
    final snap = KeyboardSnap(
      builder: (context, inset) {
        seen = inset;
        return const SizedBox.shrink();
      },
    );

    await tester.pumpWidget(host(0, snap));
    await tester.pumpWidget(host(300, snap));
    // Kademe yukarı yuvarlar: 300 → 384.
    expect(seen, 384);

    // Zamanlayıcı dolunca gerçek değere iner; ekranın altında kademe payı
    // kalmaz.
    await tester.pump(const Duration(milliseconds: 200));
    expect(seen, 300);
  });

  testWidgets('üst ekran yeniden kurulunca önbellek düşer (bayat ağaç yok)', (
    tester,
  ) async {
    var label = 'ilk';
    Widget build() => host(
      0,
      KeyboardSnap(builder: (context, inset) => Text(label)),
    );

    await tester.pumpWidget(build());
    expect(find.text('ilk'), findsOneWidget);

    label = 'ikinci';
    await tester.pumpWidget(build());
    expect(find.text('ikinci'), findsOneWidget);
  });
}
