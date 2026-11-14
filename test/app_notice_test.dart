// P62 ortak tasarım dili iskeleti (docs/plan_tasarim_A.md §1, §5): bildirim
// şeridinin sıra kuralları, şeridin çizimi, ton/yüzey/kaydırma belirteçleri.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_design.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/widgets/app_banner.dart';
import 'package:notlar/core/widgets/app_notice.dart';

const _tip = AppNoticeData(text: 'ipucu', kind: AppNoticeKind.tip);
const _news = AppNoticeData(text: 'yenilikler', kind: AppNoticeKind.announce);
const _saved = AppNoticeData(text: 'kaydedildi');

Future<void> _pump(
  WidgetTester tester,
  AppNoticeController c, {
  Widget? child,
}) => tester.pumpWidget(
  MaterialApp(
    home: AppNoticeHost(
      controller: c,
      child: Scaffold(body: child ?? const SizedBox.expand()),
    ),
  ),
);

void main() {
  group('AppNoticeController', () {
    late AppNoticeController c;
    setUp(() => c = AppNoticeController());
    tearDown(() => c.dispose());

    test('ipucu yalnız şerit boşken çıkar', () {
      expect(c.show(_saved), isTrue);
      expect(c.show(_tip), isFalse);
      expect(c.current, _saved);
    });

    test('ileti ipucunun yerine geçer (en yeni kazanır)', () {
      expect(c.show(_tip), isTrue);
      expect(c.show(_saved), isTrue);
      expect(c.current, _saved);
      c.dismiss();
      expect(c.current, isNull, reason: 'ipucu geri gelmez');
    });

    test('duyuru sırasını bekler; yarıda kesilirse kaybolmaz', () {
      c.show(_saved);
      c.show(_news);
      expect(c.current, _saved);
      c.dismiss();
      expect(c.current, _news);
      c.show(_saved);
      expect(c.current, _saved);
      c.dismiss();
      expect(c.current, _news);
      c.dismiss();
      expect(c.current, isNull);
    });

    test('dismiss(only) başka bildirimi kaldırmaz', () {
      c.show(_saved);
      c.dismiss(_tip);
      expect(c.current, _saved);
    });
  });

  testWidgets('şerit tek bildirim çizer, süre dolunca kalkar', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.show(_saved);
    c.show(const AppNoticeData(text: 'silindi'));
    await tester.pumpAndSettle();
    expect(find.text('kaydedildi'), findsNothing);
    expect(find.text('silindi'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('silindi'), findsNothing);
  });

  testWidgets('eylem: basınca çağrılır ve bildirim kalkar', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    var undone = 0;
    await _pump(tester, c);
    c.show(
      AppNoticeData(
        text: 'silindi',
        actionLabel: 'Geri al',
        onAction: () => undone++,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('notice-countdown')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notice-action')));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(c.current, isNull);
  });

  testWidgets('ipucu dokunuşu engellemez, ilk dokunuşta kalkar', (
    tester,
  ) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    var taps = 0;
    await _pump(
      tester,
      c,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => taps++,
        child: const SizedBox.expand(),
      ),
    );
    c.show(_tip);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('ipucu')).dy,
      lessThan(300),
      reason: 'ipucu üstte, üst kromun altında',
    );
    expect(
      tester.getTopLeft(find.text('ipucu')).dy,
      greaterThan(kToolbarHeight),
    );
    await tester.tap(find.text('ipucu'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'dokunuş alttaki düğmeye geçti');
    expect(c.current, isNull);
    expect(find.text('ipucu'), findsNothing);
  });

  testWidgets('dip bildirimi yüzen düğme bölgesine girmez', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    // Alt-son köşe: 144 × 72 dp (ana ekranın mikrofon / "+" satırı).
    const zone = Rect.fromLTRB(
      412 - AppNoticeHost.fabReserve,
      915 - AppNoticeHost.fabRow,
      412,
      915,
    );
    Rect card(String text) => tester.getRect(
      find
          .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
          .first,
    );

    c.show(const AppNoticeData(text: 'silindi'));
    await tester.pumpAndSettle();
    expect(card('silindi').overlaps(zone), isFalse, reason: 'ileti YANINDA');
    expect(card('silindi').left, AppSpace.m);

    c.show(
      const AppNoticeData(
        text: 'yenilikler',
        kind: AppNoticeKind.announce,
        details: ['bir', 'iki'],
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final news = card('yenilikler');
    expect(news.overlaps(zone), isFalse, reason: 'duyuru ÜSTÜNDE');
    expect(news.width, 412 - 2 * AppSpace.m, reason: 'duyuru tam genişlik');
  });

  testWidgets('şerit sökülünce bekleyen bildirim ve zamanlayıcı kalmaz', (
    tester,
  ) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    expect(c.hosted, isFalse);
    await _pump(tester, c);
    expect(c.hosted, isTrue);
    c.show(_saved);
    c.show(_news);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(c.hosted, isFalse);
    expect(c.current, isNull);
    // Zamanlayıcı kalsaydı test "Timer is still pending" ile düşerdi.
  });

  testWidgets('AppBanner: ton rengi, başlık, ilerleme', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBanner(
            title: 'Yeni sürüm',
            icon: Icons.system_update,
            tone: AppTone.action,
            progress: 0.4,
          ),
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(AppBanner))).colorScheme;
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppBanner),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, scheme.primaryContainer);
    expect(find.text('Yeni sürüm'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  test('AppSwipe: eşik ya da aynı yönde fiske geçirir', () {
    bool c(double d, double v) =>
        AppSwipe.commits(dragged: d, extent: 400, velocity: v);
    expect(c(-90, 0), isTrue, reason: '%22 = 88 dp aşıldı');
    expect(c(-40, 0), isFalse);
    expect(c(-40, -500), isTrue, reason: 'aynı yönde fiske');
    expect(c(-40, 500), isFalse, reason: 'ters yönde fiske');
    expect(c(0, 900), isFalse);
  });

  test('AppSwipe.settleFor sınırlar içinde; exitOf 2/3', () {
    expect(AppSwipe.settleFor(distance: 5), AppSwipe.settleMin);
    expect(AppSwipe.settleFor(distance: 4000), AppSwipe.settleMax);
    expect(
      AppSwipe.settleFor(distance: 200, velocity: 1000),
      const Duration(milliseconds: 200),
    );
    expect(
      AppMotion.exitOf(AppMotion.medium),
      const Duration(milliseconds: 200),
    );
  });

  test('yüzen yüzey bulanıksız', () {
    final theme = ThemeData();
    for (final s in AppSurface.floatingShadow(theme)) {
      expect(s.blurRadius, 0);
    }
    expect(AppSurface.floating(theme).border, isNotNull);
  });
}
