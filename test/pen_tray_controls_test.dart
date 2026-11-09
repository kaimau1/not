import 'package:flutter/gestures.dart';
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

  // Kullanıcı bulgusu 2026-11-02: "kalem seçildikten sonra yazmaya başlayınca
  // otomatik kapanmıyor" — renk paneli açıkken çekmece inmiyordu.
  testWidgets('çekmecede yazmaya başlayınca panel kapanır, tepsi iner', (
    tester,
  ) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    ink.setEditing(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(children: [PenTray(controller: ink, dock: true)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pen-tray-color')));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(2));
    ink.pointerDown(1, const Offset(10, 10), const Size(400, 400));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
    expect(find.byKey(const ValueKey('pen-dock-peek')), findsOneWidget);
    ink.pointerUp();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 7));
  });

  // Tablet bulgusu 2026-11-07 (MatePad 11): aşağıdaki tutamak sistem gezinme
  // çubuğunun içine iniyordu; dokunuş sisteme gidiyor, tepsi açılmıyordu.
  testWidgets('aşağıdaki tutamak gezinme çubuğunun üstünde kalır', (
    tester,
  ) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    ink.setEditing(true);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1024, 640),
          padding: EdgeInsets.only(bottom: 16),
          viewPadding: EdgeInsets.only(bottom: 16),
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Stack(children: [PenTray(controller: ink, dock: true)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    ink.pointerDown(1, const Offset(10, 10), const Size(400, 400));
    ink.pointerUp();
    await tester.pumpAndSettle();
    final peek = tester.getRect(find.byKey(const ValueKey('pen-dock-peek')));
    final screen = tester.getSize(find.byType(Stack).first).height;
    expect(peek.bottom, lessThanOrEqualTo(screen - 16));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 7));
  });

  // Kullanıcı bulgusu 2026-11-02: "fareyle tıkladığım yerin biraz üzerine
  // yazıyor". Çizgi tam tıklanan noktada başlar; imleç artıdır.
  testWidgets('fareyle çizgi tıklanan noktada başlar, imleç artı', (
    tester,
  ) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    ink.setEditing(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Stack(
          children: [
            Positioned(
              left: 30,
              top: 120,
              width: 400,
              height: 900,
              child: InkPageLayer(controller: ink, page: 1, uniform: true),
            ),
          ],
        ),
      ),
    );
    final mouse = await tester.startGesture(
      const Offset(130, 320),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(40, 0));
    await mouse.up();
    await tester.pump();
    final p = ink.ink.single.points;
    expect(p[0] * 400, closeTo(100, 0.01));
    expect(p[1] * 400, closeTo(200, 0.01));
    final cursors = tester
        .widgetList<MouseRegion>(
          find.descendant(
            of: find.byType(InkPageLayer),
            matching: find.byType(MouseRegion),
          ),
        )
        .map((r) => r.cursor);
    expect(cursors, contains(SystemMouseCursors.precise));
  });

  testWidgets('renk/kalınlık kartı dışarı dokununca kapanır', (tester) async {
    await pump(tester, controls: false);
    // Seçili kaleme yeniden dokunmak kartı açar.
    await tester.tap(find.byKey(const ValueKey('pen-tray-pen')));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsWidgets);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
  });
}
