import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// KALEM ↔ SİLGİ HIZLI DÜĞMESİ (kullanıcı isteği 2026-11-19): çizgi bitince
/// yanında saydam küçük düğme; dokununca silgi ↔ kalem; hareketsizlikte
/// solar; çizim sırasında dokunuşu yutmaz.
void main() {
  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  group('yer', () {
    const area = Size(400, 600);
    test('boşlukta çizgi kutusunun sol üstünde, kutuya yakın', () {
      const stroke = Rect.fromLTRB(200, 300, 320, 330);
      final at = inkQuickSwapPlace(stroke, area);
      expect(at.dx + kInkQuickSwapSize, lessThanOrEqualTo(stroke.left - 16));
      expect(at.dy + kInkQuickSwapSize, lessThanOrEqualTo(stroke.top - 16));
      // "bazen çok uzakta" olmasın.
      expect(stroke.left - (at.dx + kInkQuickSwapSize), lessThan(30));
    });

    test('sol kenarda sağa sıçramaz: kenara kıstırılır; tepede altta', () {
      final left = inkQuickSwapPlace(
        const Rect.fromLTRB(10, 300, 100, 320),
        area,
      );
      expect(left.dx, 0);
      expect(left.dy + kInkQuickSwapSize, lessThanOrEqualTo(300));
      final below = inkQuickSwapPlace(
        const Rect.fromLTRB(200, 10, 300, 30),
        area,
      );
      expect(below.dy, greaterThan(30));
      expect(below.dx, lessThan(200));
      final clamped = inkQuickSwapPlace(
        const Rect.fromLTRB(0, 0, 400, 600),
        area,
      );
      expect(clamped.dx, 0);
    });

    test('yapışkan: satır boyunca yazarken düğme yerinde kalır', () {
      final first = inkQuickSwapPlace(
        const Rect.fromLTRB(100, 300, 130, 330),
        area,
      );
      // Aynı satırda sağa doğru birkaç harf daha.
      var at = first;
      for (final x in [140.0, 180.0, 220.0]) {
        at = inkQuickSwapPlace(
          Rect.fromLTRB(x, 296, x + 30, 334),
          area,
          previous: at,
        );
        expect(at, first);
      }
      // Yeni çizgi düğmenin üstüne gelirse yer değişir.
      final over = inkQuickSwapPlace(
        Rect.fromLTRB(first.dx, first.dy, first.dx + 30, first.dy + 30),
        area,
        previous: first,
      );
      expect(over, isNot(first));
      // Çok uzağa yazılınca da yeni yazının yanına gelir.
      final far = inkQuickSwapPlace(
        const Rect.fromLTRB(200, 540, 260, 570),
        area,
        previous: first,
      );
      expect(far, isNot(first));
      expect(far.dy, greaterThan(400));
    });
  });

  Future<InkController> pump(WidgetTester tester) async {
    final ink = InkController(initial: const [], onChanged: (_) {})
      ..setEditing(true);
    addTearDown(ink.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: InkPageLayer(controller: ink, page: 1),
          ),
        ),
      ),
    );
    return ink;
  }

  Future<void> stroke(WidgetTester tester, Offset from, Offset to) async {
    final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await g.moveTo(Offset.lerp(from, to, 0.5)!);
    await g.moveTo(to);
    await g.up();
    await tester.pump();
  }

  double opacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(const ValueKey('ink-quick-swap')))
      .opacity;

  testWidgets('çizgi bitince yakında belirir, dokununca silgi ↔ kalem, '
      'hareketsizlikte solar', (tester) async {
    final ink = await pump(tester);
    expect(find.byKey(const ValueKey('ink-quick-swap')), findsNothing);
    await stroke(tester, const Offset(200, 300), const Offset(320, 330));
    expect(ink.ink, hasLength(1));
    final button = find.byKey(const ValueKey('ink-quick-swap'));
    expect(button, findsOneWidget);
    expect(opacity(tester), kInkQuickSwapIdleOpacity);
    final r = tester.getRect(button);
    expect(r.right, lessThan(200), reason: 'çizginin solunda');
    expect(r.bottom, lessThan(300), reason: 'çizginin üstünde');
    expect((const Offset(200, 300) - r.bottomRight).distance, lessThan(90));

    await tester.tapAt(r.center, kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(ink.eraser, isTrue);
    expect(ink.ink, hasLength(1), reason: 'dokunuş çizmedi');
    expect(find.byKey(const ValueKey('ink-quick-swap-pen')), findsOneWidget);
    await tester.tapAt(r.center, kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(ink.eraser, isFalse);

    await tester.pump(kInkQuickSwapIdle + const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(tester), 0);
  });

  testWidgets('yeni çizgi başlayınca gizlenir; gizliyken yerine dokunmak '
      'çizer (dokunuşu yutmaz)', (tester) async {
    final ink = await pump(tester);
    await stroke(tester, const Offset(200, 300), const Offset(320, 330));
    final r = tester.getRect(find.byKey(const ValueKey('ink-quick-swap')));
    final g = await tester.startGesture(
      const Offset(250, 450),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(opacity(tester), 0, reason: 'çizgi sürerken görünmez');
    await g.moveTo(const Offset(300, 470));
    await g.up();
    await tester.pump(kInkQuickSwapIdle + const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(ink.ink, hasLength(2));
    // Solmuş düğmenin yerinden başlayan çizgi çizilir, araç değişmez.
    await stroke(tester, r.center, r.center + const Offset(0, 60));
    expect(ink.eraser, isFalse);
    expect(ink.ink, hasLength(3));
  });

  testWidgets('ayar kapalıyken düğme çıkmaz', (tester) async {
    InkToolMemory.quickSwap = false;
    await pump(tester);
    await stroke(tester, const Offset(200, 300), const Offset(320, 330));
    expect(find.byKey(const ValueKey('ink-quick-swap')), findsNothing);
  });
}
