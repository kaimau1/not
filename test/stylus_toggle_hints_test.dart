import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/stylus_toggle.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Yüzen kalem düğmesi (kullanıcı 2026-11-13): ilk görünüşte bir kez yanıp
/// söner; "yalnız kalem" kapalıyken yanında "parmakla da yazılıyor" hapı,
/// dokununca yalnız kaleme geçer.
void main() {
  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('tr'),
      home: Scaffold(body: StylusToggleOverlay(child: SizedBox.expand())),
    ),
  );

  testWidgets('ilk görünüşte bir kez yanıp söner ve biter', (tester) async {
    InkToolMemory.toggleBlinked = false;
    await pump(tester);
    expect(InkToolMemory.toggleBlinked, isTrue);
    expect(find.byType(Transform), findsWidgets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('parmak da yazıyorken hap görünür, dokununca yalnız kalem', (
    tester,
  ) async {
    await pump(tester);
    final chip = find.byKey(const ValueKey('finger-writes-chip'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump();
    expect(InkToolMemory.penOnly, isTrue);
    expect(chip, findsNothing);
  });

  testWidgets('parmak Siler kipindeyken hap "parmak siliyor" der (K34)', (
    tester,
  ) async {
    InkToolMemory.saveFingerTool(FingerTool.erase);
    await pump(tester);
    expect(find.textContaining('Parmak siliyor'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('finger-writes-chip')));
    await tester.pump();
    expect(InkToolMemory.fingerTool, FingerTool.scroll);
    // Yalnız kalem kapanınca son seçilen öbür hâle (Siler) döner.
    InkToolMemory.savePenOnly(false, chosen: true);
    expect(InkToolMemory.fingerTool, FingerTool.erase);
  });
}
