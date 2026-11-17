import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/calculator_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart' show BuildCounter;

/// T7 / K-57 (kasma envanteri): hesap makinesinde her tuş `setState` ile
/// BÜTÜN levhayı (20 tuşluk takım dahil) yeniden kuruyordu. Artık yalnız
/// ifade satırı ve sonuca bağlı düğmeler dinler.
void main() {
  Future<void> open(WidgetTester tester, void Function(String?) done) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async => done(await showCalculatorSheet(context)),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('tuş takımı tuş başına yeniden kurulmaz; hesap doğru', (
    tester,
  ) async {
    String? result;
    await open(tester, (r) => result = r);
    final counter = BuildCounter()..start();
    for (final k in ['1', '2', '×', '3']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    counter.stop();
    final keys =
        (counter.counts['OutlinedButton'] ?? 0) +
        (counter.counts['FilledButton'] ?? 0);
    // 4 dokunuş: tuşların kendi basılma boyaması dışında takım kurulmaz.
    // Eski yol: dokunuş başına 20 tuş + 2 eylem düğmesi.
    expect(keys, lessThanOrEqualTo(8), reason: '${counter.counts}');
    expect(find.text('= 36'), findsOneWidget);
    await tester.tap(find.text('Nota ekle'));
    await tester.pumpAndSettle();
    expect(result, '12×3 = 36');
  });

  testWidgets('C, ⌫ ve = ifadeyi günceller', (tester) async {
    await open(tester, (_) {});
    for (final k in ['9', '⌫', '7', '+', '1', '=']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    expect(find.widgetWithText(TextField, '8'), findsOneWidget);
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(find.widgetWithText(TextField, '8'), findsNothing);
  });
}
