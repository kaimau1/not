import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/color_dot.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.6): tek renk noktası. Seçim halkası
/// yalnız renk değiştirir — nokta seçilince boyu OYNAMAZ.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('seçili ve seçisiz aynı boyut: size + 8', (tester) async {
    for (final selected in [false, true]) {
      await tester.pumpWidget(
        host(ColorDot(color: Colors.red, selected: selected)),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ColorDot)), const Size(36, 36));
    }
    await tester.pumpWidget(
      host(const ColorDot(color: Colors.red, selected: true, size: 26)),
    );
    expect(tester.getSize(find.byType(ColorDot)), const Size(34, 34));
  });

  testWidgets('dokunuş onTap çağırır; ipucu erişilebilirlik adı olur', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        ColorDot(
          color: Colors.blue,
          selected: false,
          tooltip: 'Mavi',
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(ColorDot));
    expect(taps, 1);
    expect(find.byTooltip('Mavi'), findsOneWidget);
  });

  testWidgets('child noktanın ortasında', (tester) async {
    await tester.pumpWidget(
      host(
        const ColorDot(
          color: Colors.green,
          selected: true,
          child: Icon(Icons.brightness_auto_rounded, size: 14),
        ),
      ),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.brightness_auto_rounded)),
      tester.getCenter(find.byType(ColorDot)),
    );
  });

  testWidgets('seçili nokta primary halka çizer, seçisiz çizmez', (
    tester,
  ) async {
    Color ring() =>
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration!
                as BoxDecoration)
            .border!
            .top
            .color;
    await tester.pumpWidget(
      host(const ColorDot(color: Colors.red, selected: false)),
    );
    expect(ring().a, 0);
    await tester.pumpWidget(
      host(const ColorDot(color: Colors.red, selected: true)),
    );
    final scheme = Theme.of(tester.element(find.byType(ColorDot))).colorScheme;
    expect(ring(), scheme.primary);
  });
}
