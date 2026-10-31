import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F13.3 (2026-10-31): PDF/sunum/görsel üstünde de kalem tepsisi. Belgede
/// üst çubuk olmadığı için tepsinin denetim satırı (ipucu · geri al ·
/// yinele · yalnız kalem · ayarlar) vardır; çizim ekranında yoktur.
void main() {
  setUp(InkToolMemory.reset);

  Future<InkController> pump(
    WidgetTester tester, {
    required bool controls,
  }) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: PenTray(
            controller: ink,
            controls: controls,
            hint: 'iki parmakla kaydır',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ink;
  }

  testWidgets('belge üstünde denetim satırı ve ipucu var', (tester) async {
    final ink = await pump(tester, controls: true);
    expect(find.byKey(const ValueKey('pen-tray-undo')), findsOneWidget);
    expect(find.text('iki parmakla kaydır'), findsOneWidget);
    expect(find.byKey(const ValueKey('pen-tray-pen')), findsOneWidget);
    // Yalnız kalem düğmesi denetleyiciyi değiştirir.
    final before = ink.penOnly;
    await tester.tap(find.byIcon(Icons.touch_app_outlined));
    await tester.pumpAndSettle();
    expect(ink.penOnly, !before);
  });

  testWidgets('çizim ekranı kipinde denetim satırı yok', (tester) async {
    await pump(tester, controls: false);
    expect(find.byKey(const ValueKey('pen-tray-undo')), findsNothing);
  });
}
