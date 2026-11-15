import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
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

  // Kullanıcı isteği 2026-11-15 (G4 kapsülü): geri al ve × / ✓ kalktı, seçim
  // anında uygulanır; silgi mürekkep varken belirgin; "tüm yazıları kaldır"
  // geri alınabilir.
  group('kapsül (2026-11-15)', () {
    Future<InkController> dock(
      WidgetTester tester, {
      bool showUndo = false,
    }) async {
      final ink = InkController(initial: const [], onChanged: (_) {});
      addTearDown(ink.dispose);
      ink.setEditing(true);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                PenTray(controller: ink, dock: true, showUndo: showUndo),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ink;
    }

    void stroke(InkController ink, double y) {
      ink
        ..pointerDown(1, Offset(20, y), const Size(400, 400))
        ..pointerMove(1, Offset(120, y), const Size(400, 400))
        ..pointerUp();
    }

    Future<void> end(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 7));
    }

    Color eraserColor(WidgetTester tester) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(const ValueKey('pen-tray-eraser')),
            matching: find.byType(Icon),
          ),
        )
        .color!;

    testWidgets('onay/geri al düğmesi yok, kalem seçimi anında uygulanır', (
      tester,
    ) async {
      final ink = await dock(tester);
      expect(find.byKey(const ValueKey('pen-tray-undo')), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pen-tray-marker')));
      await tester.pump();
      expect(ink.pen, InkPen.marker);
      // Silgi kalem sırasında değil, tek düğmesinde.
      expect(find.byKey(const ValueKey('pen-tray-eraser')), findsOneWidget);
      await end(tester);
    });

    testWidgets('üst çubuk yokken (showUndo) geri al kapsülde', (tester) async {
      await dock(tester, showUndo: true);
      expect(find.byKey(const ValueKey('pen-tray-undo')), findsOneWidget);
      await end(tester);
    });

    testWidgets(
      'silgi mürekkep yokken soluk, varken belirgin; dokununca seçer',
      (tester) async {
        final ink = await dock(tester);
        final faint = eraserColor(tester);
        stroke(ink, 50);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
        await tester.pumpAndSettle();
        final strong = eraserColor(tester);
        expect(faint.a, lessThan(strong.a));
        await tester.tap(find.byKey(const ValueKey('pen-tray-eraser')));
        await tester.pump();
        expect(ink.eraser, isTrue);
        await end(tester);
      },
    );

    testWidgets('silgiye basılı tut: tümü silinir, "Geri al" geri getirir', (
      tester,
    ) async {
      final ink = await dock(tester);
      stroke(ink, 50);
      stroke(ink, 100);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('pen-tray-eraser')));
      await tester.pump();
      expect(ink.ink, isEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Çizimler temizlendi'), findsOneWidget);
      await tester.tap(find.text('Geri al'));
      await tester.pump();
      expect(ink.ink, hasLength(2));
      await end(tester);
    });

    testWidgets('⋯ menüsünde "Çizimleri temizle"', (tester) async {
      final ink = await dock(tester);
      stroke(ink, 50);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pen-tray-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pen-tray-clear')));
      await tester.pumpAndSettle();
      expect(ink.ink, isEmpty);
      ink.undo();
      expect(ink.ink, hasLength(1));
      await end(tester);
    });
  });
}
