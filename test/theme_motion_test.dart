import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/widgets/app_sheet.dart';
import 'package:notlar/core/widgets/color_fade.dart';
import 'package:notlar/core/widgets/press_scale.dart';
import 'package:notlar/core/widgets/skeleton.dart';
import 'package:notlar/features/notes/presentation/editor/page_swipe.dart';

/// TEMA_PLANI F34: hareket belirteçleri, azaltılmış hareket, renk solması,
/// sayfa çevirme.
void main() {
  Widget host(Widget child, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(body: child),
    ),
  );

  group('F34.7 hareketi azalt', () {
    // F77.4: P38 hareketleri (quick, long dahil) azaltılmışta ≤ 150 ms.
    for (final d in [
      AppMotion.instant,
      AppMotion.quick,
      AppMotion.short,
      AppMotion.medium,
      AppMotion.long,
    ]) {
      testWidgets('$d → en çok 150 ms, doğrusal', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
            reduced: true,
          ),
        );
        expect(AppMotion.of(ctx, d).inMilliseconds, lessThanOrEqualTo(150));
        expect(AppMotion.curveOf(ctx, AppMotion.enter), Curves.linear);
      });
    }

    test('levha stili kısa', () {
      expect(kAppSheetAnimationReduced.duration, AppMotion.reduced);
      expect(kAppSheetAnimationReduced.reverseDuration, AppMotion.reduced);
    });

    testWidgets('levha 150 ms içinde açılır', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showAppSheet<void>(
                context: c,
                builder: (_) =>
                    const SizedBox(height: 200, child: Text('levha')),
              ),
              child: const Text('aç'),
            ),
          ),
          reduced: true,
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pump();
      await tester.pump(AppMotion.reduced);
      final y = tester.getTopLeft(find.text('levha')).dy;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('levha')).dy, y);
    });

    testWidgets('kart basınca çökmez', (tester) async {
      await tester.pumpWidget(
        host(
          const PressScale(child: SizedBox.square(dimension: 80)),
          reduced: true,
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(PressScale)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('F31.4 basılı kart 0,98', (tester) async {
    await tester.pumpWidget(
      host(const PressScale(child: SizedBox.square(dimension: 80))),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final s = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(s.scale, 0.98);
    expect(s.duration, AppMotion.instant);
    await g.up();
    await tester.pumpAndSettle();
  });

  group('F34.4 renk solması', () {
    Widget fade(Color c, Object id) => host(
      ColorFade(
        color: c,
        identity: id,
        builder: (_, color, child) => ColoredBox(color: color, child: child),
        child: const SizedBox.square(dimension: 10),
      ),
    );
    Color shown(WidgetTester t) =>
        t.widget<ColoredBox>(find.byType(ColoredBox).last).color;

    testWidgets('aynı notta 200 ms soluklaşır', (tester) async {
      await tester.pumpWidget(fade(const Color(0xFF000000), 'a'));
      await tester.pumpWidget(fade(const Color(0xFFFFFFFF), 'a'));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = shown(tester);
      expect(mid, isNot(const Color(0xFF000000)));
      expect(mid, isNot(const Color(0xFFFFFFFF)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(shown(tester), const Color(0xFFFFFFFF));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('kimlik değişirse (tema, başka not) anında', (tester) async {
      await tester.pumpWidget(fade(const Color(0xFF000000), 'a'));
      await tester.pumpWidget(fade(const Color(0xFFFFFFFF), 'b'));
      expect(shown(tester), const Color(0xFFFFFFFF));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('F33.6 sayfa çevirme', () {
    Widget turn(int i, {int count = 5, bool reduced = false}) => host(
      PageTurn(index: i, count: count, child: const SizedBox.expand()),
      reduced: reduced,
    );
    double pillOpacity(WidgetTester t) =>
        t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

    testWidgets('değişince kayar, hap görünür ve söner', (tester) async {
      await tester.pumpWidget(turn(0));
      expect(pillOpacity(tester), 0);
      await tester.pumpWidget(turn(1));
      await tester.pump(const Duration(milliseconds: 16));
      final moved = tester.widget<Transform>(find.byType(Transform).first);
      expect(moved.transform.getTranslation().x, greaterThan(0));
      expect(find.text('2 / 5'), findsOneWidget);
      expect(pillOpacity(tester), 1);
      await tester.pump(PageTurn.pillDuration);
      await tester.pumpAndSettle();
      expect(pillOpacity(tester), 0);
    });

    testWidgets('hareketi azaltta kaymaz', (tester) async {
      await tester.pumpWidget(turn(0, reduced: true));
      await tester.pumpWidget(turn(1, reduced: true));
      await tester.pump(const Duration(milliseconds: 16));
      final moved = tester.widget<Transform>(find.byType(Transform).first);
      expect(moved.transform.getTranslation().x, 0);
      await tester.pump(PageTurn.pillDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('sayfasız notta hap yok', (tester) async {
      await tester.pumpWidget(turn(0, count: 1));
      expect(find.byType(AnimatedOpacity), findsNothing);
    });
  });

  group('F31.7 iskeletten geçiş', () {
    Widget sliver({required bool play}) => host(
      CustomScrollView(
        slivers: [
          SliverRevealFade(
            play: play,
            sliver: const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ),
        ],
      ),
    );

    testWidgets('iskelet görünmüşse solarak, yoksa anında', (tester) async {
      await tester.pumpWidget(sliver(play: true));
      expect(
        tester
            .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
            .opacity
            .value,
        0,
      );
      await tester.pump(AppMotion.short);
      await tester.pump();
      expect(
        tester
            .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
            .opacity
            .value,
        1,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(sliver(play: false));
      expect(
        tester
            .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
            .opacity
            .value,
        1,
      );
    });
  });
}
