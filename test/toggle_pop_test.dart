import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/toggle_pop.dart';

/// F77.3-1: yıldız/iğne değişince 1 → 1,15 → 1 atar; hareket azaltılmışsa
/// atmaz; ağaç şekli değişmez (alt öğe durumu korunur).
void main() {
  Widget host(bool on, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: TogglePop(on: on, child: const Icon(Icons.star)),
    ),
  );

  double scale(WidgetTester t) =>
      t.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

  testWidgets('değişince atar, sonra 1e oturur', (tester) async {
    await tester.pumpWidget(host(false));
    final icon = tester.element(find.byType(Icon));
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(milliseconds: 75));
    expect(scale(tester), greaterThan(1.1));
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
    expect(tester.element(find.byType(Icon)), same(icon));
  });

  testWidgets('hareketi azalt: atmaz', (tester) async {
    await tester.pumpWidget(host(false, reduced: true));
    await tester.pumpWidget(host(true, reduced: true));
    await tester.pump(const Duration(milliseconds: 75));
    expect(scale(tester), 1);
  });
}
