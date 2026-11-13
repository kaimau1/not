import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';
import 'package:notlar/features/notes/presentation/editor/stylus_toggle.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **KALEM İPUÇLARI ALT PANELİ ÖRTMEZ, SÜREKLİ ÇIKMAZ** (P49 (d), kullanıcı
/// 2026-11-12: "'kalem yazar, parmak dokunur' gibi ipuçları alt kalem
/// panelini KAPATMASIN, sürekli çıkmasın").
void main() {
  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  Widget app(Widget body) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  );

  testWidgets('alttaki panel açıkken bildirim panelin ÜSTÜNDE çıkar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final panel = GlobalKey();
    await tester.pumpWidget(
      app(
        Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SnackBarObstacle(child: SizedBox(key: panel, height: 140)),
            ),
          ],
        ),
      ),
    );
    expect(snackBarBottomObstacle.value, 140);
    final context = tester.element(find.byKey(panel));
    ScaffoldMessenger.of(context).showMessage('kalem yazar');
    await tester.pumpAndSettle();
    // SnackBar'ın kendi kutusu kenar boşluğunu da kapsar: yüzeye bak.
    final snack = tester.getRect(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    final top = tester.getRect(find.byKey(panel)).top;
    expect(snack.bottom, lessThanOrEqualTo(top));

    // Panel kalkınca engel de kalkar.
    await tester.pumpWidget(app(const SizedBox()));
    expect(snackBarBottomObstacle.value, 0);
  });

  testWidgets('yüzen kalem düğmesi: her durumun yazısı oturumda bir kez', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(const StylusToggleOverlay(child: SizedBox.expand())),
    );
    final toggle = find.byKey(const ValueKey('stylus-toggle'));
    final shown = <bool>[];
    for (var i = 0; i < 4; i++) {
      await tester.tap(toggle);
      await tester.pump();
      shown.add(find.byType(SnackBar).evaluate().isNotEmpty);
      // Bildirim süresini doldurup kalksın.
      ScaffoldMessenger.of(tester.element(toggle)).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    }
    // kapalı (ilk) · açık (ilk) · kapalı (yine) · açık (yine).
    expect(shown, [true, true, false, false]);
    expect(InkToolMemory.autoStylus, isTrue);
  });
}
