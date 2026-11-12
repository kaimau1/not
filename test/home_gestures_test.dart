import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// TUTARLILIK F39: ana ekran bölüm başlığı, iki parmak zoom, yana kaydırma,
/// boş durumlar.
void main() {
  Widget host(Widget child, {TextDirection? dir, bool reduced = false}) =>
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            disableAnimations: reduced,
          ),
          child: Directionality(
            textDirection: dir ?? TextDirection.ltr,
            child: Scaffold(body: child),
          ),
        ),
      );

  group('F39.1 bölüm başlığı', () {
    testWidgets('sayı başlığın yanında, çizgi sonra ve sınırlı', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: HomeSectionHeader(text: 'Sabit', count: 3),
          ),
        ),
      );
      final label = tester.getTopRight(find.text('Sabit')).dx;
      final count = tester.getTopLeft(find.text('· 3')).dx;
      expect(count - label, lessThan(12));
      final line = tester.getRect(find.byType(Divider));
      expect(line.left, greaterThan(count));
      expect(line.right, lessThanOrEqualTo(14 + kSectionHeaderMaxWidth));
    });
  });

  group('F39.2 iki parmak zoom', () {
    test('hedef sütun: her %25 bir adım, uçlarda durur', () {
      expect(pinchTargetColumns(2, 1), 2);
      expect(pinchTargetColumns(2, 1.2), 2);
      expect(pinchTargetColumns(2, 1.3), 1);
      expect(pinchTargetColumns(2, 3), 1);
      expect(pinchTargetColumns(2, 0.75), 3);
      expect(pinchTargetColumns(2, 0.6), 4);
      expect(pinchTargetColumns(4, 0.2), 4);
      expect(pinchTargetColumns(3, 0), 3);
    });

    double scaleOf(WidgetTester t) => t
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(ClipRect),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];

    Future<(TestGesture, TestGesture)> down(WidgetTester t) async {
      final a = await t.startGesture(const Offset(150, 400), pointer: 1);
      final b = await t.startGesture(const Offset(250, 400), pointer: 2);
      await a.moveBy(const Offset(-1, 0));
      await t.pump();
      return (a, b);
    }

    testWidgets('jest boyunca yalnız ölçek; bırakınca TEK değişim', (
      tester,
    ) async {
      final commits = <int>[];
      var builds = 0;
      await tester.pumpWidget(
        host(
          PinchColumns(
            columns: 2,
            onCommit: commits.add,
            child: Builder(
              builder: (_) {
                builds++;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      final (a, b) = await down(tester);
      final built = builds;
      await a.moveBy(const Offset(-60, 0));
      await tester.pump();
      await b.moveBy(const Offset(60, 0));
      await tester.pump();
      // Oran ~2,2: ölçek tavanda, ızgara yeniden kurulmadı, henüz sütun yok.
      expect(scaleOf(tester), 1.15);
      expect(builds, built);
      expect(commits, isEmpty);
      expect(find.byKey(const ValueKey('pinch-columns-1')), findsOneWidget);
      await a.up();
      await tester.pump();
      expect(commits, [1]);
      await b.up();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(scaleOf(tester), 1);
      expect(commits, [1]);
      expect(find.byKey(const ValueKey('pinch-columns-1')), findsNothing);
    });

    group('F44.5 fare ve dokunmatik yüzey', () {
      Future<List<int>> zoomHost(WidgetTester tester, int columns) async {
        final commits = <int>[];
        await tester.pumpWidget(
          host(
            PinchColumns(
              columns: columns,
              onCommit: commits.add,
              child: const SizedBox.expand(),
            ),
          ),
        );
        return commits;
      }

      const at = Offset(200, 400);

      testWidgets('Ctrl+tekerlek: çentik başına bir sütun, yukarı = az sütun', (
        tester,
      ) async {
        final commits = await zoomHost(tester, 3);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendEventToBinding(
          const PointerScrollEvent(
            position: at,
            scrollDelta: Offset(0, -100),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(commits, isEmpty, reason: 'jest sürüyor');
        await tester.pump(const Duration(milliseconds: 200));
        expect(commits, [2]);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      });

      testWidgets('Ctrl+tekerlek iki çentik aşağı: iki sütun artar', (
        tester,
      ) async {
        final commits = await zoomHost(tester, 2);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        for (var i = 0; i < 2; i++) {
          await tester.sendEventToBinding(
            const PointerScrollEvent(position: at, scrollDelta: Offset(0, 100)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(commits, [4]);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      });

      testWidgets('Ctrl yokken tekerlek ızgarayı kaydırır, sütun değişmez', (
        tester,
      ) async {
        final commits = await zoomHost(tester, 3);
        await tester.sendEventToBinding(
          const PointerScrollEvent(
            position: at,
            scrollDelta: Offset(0, -100),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(commits, isEmpty);
      });

      testWidgets('web kıstırması (ölçek olayı) ince adımlarla birikir', (
        tester,
      ) async {
        final commits = await zoomHost(tester, 3);
        for (var i = 0; i < 4; i++) {
          await tester.sendEventToBinding(
            const PointerScaleEvent(position: at, scale: 1.08),
          );
          await tester.pump(const Duration(milliseconds: 30));
        }
        await tester.pump(const Duration(milliseconds: 200));
        expect(commits, [2]);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      });

      testWidgets('dokunmatik yüzey kıstırması: bırakınca bir kez', (
        tester,
      ) async {
        final commits = await zoomHost(tester, 3);
        final g = await tester.createGesture(
          kind: PointerDeviceKind.trackpad,
        );
        await g.panZoomStart(at);
        await g.panZoomUpdate(at, scale: 1.4);
        await tester.pump();
        expect(commits, isEmpty);
        await g.panZoomEnd();
        await tester.pump();
        expect(commits, [2]);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      });
    });

    testWidgets('iki parmakla düz kaydırma ölçeklemez, sütun değişmez', (
      tester,
    ) async {
      final commits = <int>[];
      await tester.pumpWidget(
        host(
          PinchColumns(
            columns: 2,
            onCommit: commits.add,
            child: const SizedBox.expand(),
          ),
        ),
      );
      final (a, b) = await down(tester);
      // Gerçek parmaklar neredeyse birlikte hareket eder: küçük adımlar.
      for (var i = 0; i < 8; i++) {
        await a.moveBy(const Offset(0, -5));
        await b.moveBy(const Offset(0, -5));
      }
      await tester.pump();
      expect(scaleOf(tester), 1);
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
    });

    testWidgets('hareketi azaltta ölçek yok, sütun yine değişir', (
      tester,
    ) async {
      final commits = <int>[];
      await tester.pumpWidget(
        host(
          PinchColumns(
            columns: 2,
            onCommit: commits.add,
            child: const SizedBox.expand(),
          ),
          reduced: true,
        ),
      );
      final (a, b) = await down(tester);
      await a.moveBy(const Offset(-60, 0));
      await b.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(scaleOf(tester), 1);
      await a.up();
      await b.up();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(commits, [1]);
    });
  });

  group('F39.3 yana kaydırma', () {
    late List<int> commits;
    setUp(() => commits = []);

    Widget swipe({
      String? Function(int)? label,
      bool enabled = true,
      TextDirection? dir,
    }) => host(
      FolderSwipe(
        enabled: enabled,
        nextLabel: label ?? (d) => d > 0 ? 'Genel' : 'Tümü',
        onCommit: commits.add,
        child: const SizedBox.expand(
          key: ValueKey('grid'),
          child: ColoredBox(color: Colors.white),
        ),
      ),
      dir: dir,
    );

    testWidgets('F44.5 yatay dokunmatik yüzey kaydırması geçer, atalet geçmez', (
      tester,
    ) async {
      await tester.pumpWidget(swipe());
      const at = Offset(200, 400);
      Future<void> wheel(double dx, [double dy = 0]) =>
          tester.sendEventToBinding(
            PointerScrollEvent(position: at, scrollDelta: Offset(dx, dy)),
          );

      // Kısa: eşiğe varmaz.
      await wheel(30);
      await tester.pump(const Duration(milliseconds: 200));
      expect(commits, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));

      // Dikey ağırlıklı: geçiş değil.
      await wheel(100, 300);
      await tester.pump(const Duration(milliseconds: 500));
      expect(commits, isEmpty);

      // Sağa kaydırma = sonraki durak (parmakla sola çekiş gibi).
      await wheel(110);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(const ValueKey('swipe-next-label')), findsOneWidget);
      // Dolum çubuğu (2026-11-09): eşiğe doğru dolmaya başladı.
      final bar = tester.widget<FractionallySizedBox>(
        find.byKey(const ValueKey('swipe-progress')),
      );
      expect(bar.widthFactor, greaterThan(0));
      await wheel(110);
      await tester.pump(const Duration(milliseconds: 200));
      expect(commits, [1]);

      // Atalet: hemen ardından gelen olay ikinci geçiş sayılmaz.
      await wheel(200);
      await tester.pump(const Duration(milliseconds: 200));
      expect(commits, [1]);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    Future<TestGesture> dragTo(WidgetTester t, double dx) async {
      final g = await t.startGesture(const Offset(200, 400));
      await t.pump();
      await g.moveBy(Offset(dx > 0 ? 30 : -30, 0));
      await t.pump();
      await g.moveBy(Offset(dx, 0));
      await t.pump();
      return g;
    }

    double offsetOf(WidgetTester t) =>
        t.getTopLeft(find.byKey(const ValueKey('grid'))).dx;

    testWidgets('ızgara parmağı izler, sonraki durağın adı görünür', (
      tester,
    ) async {
      await tester.pumpWidget(swipe());
      final g = await dragTo(tester, -60);
      expect(offsetOf(tester), lessThan(-40));
      expect(find.text('Genel'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await g.moveBy(const Offset(-120, 0));
      await tester.pump(const Duration(seconds: 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(commits, [1]);
      expect(offsetOf(tester), 0);
      expect(find.text('Genel'), findsNothing);
    });

    testWidgets('yerinde geçişte ızgara geri sekmez, bırakılan yer bildirilir', (
      tester,
    ) async {
      final released = <double>[];
      await tester.pumpWidget(
        host(
          FolderSwipe(
            enabled: true,
            nextLabel: (d) => 'Genel',
            onCommit: commits.add,
            continuesInPlace: (d, at) {
              released.add(at);
              return true;
            },
            child: const SizedBox.expand(
              key: ValueKey('grid'),
              child: ColoredBox(color: Colors.white),
            ),
          ),
        ),
      );
      final g = await dragTo(tester, -150);
      await g.up();
      // Aynı karede: geri dönüş animasyonu yok, görünüm çağırana devredildi.
      await tester.pump();
      expect(commits, [1]);
      expect(released.single, lessThan(-0.2));
      expect(offsetOf(tester), 0);
    });

    testWidgets('eşik aşılmazsa yerine döner', (tester) async {
      await tester.pumpWidget(swipe());
      final g = await dragTo(tester, -20);
      await tester.pump(const Duration(seconds: 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(offsetOf(tester), 0);
    });

    testWidgets('kısa hızlı fiske geçer', (tester) async {
      await tester.pumpWidget(swipe());
      await tester.fling(
        find.byKey(const ValueKey('grid')),
        const Offset(70, 0),
        900,
      );
      await tester.pumpAndSettle();
      expect(commits, [-1]);
    });

    testWidgets('durak yoksa lastik, geçiş yok', (tester) async {
      await tester.pumpWidget(swipe(label: (_) => null));
      final g = await dragTo(tester, -200);
      expect(offsetOf(tester), greaterThan(-70));
      await g.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      expect(offsetOf(tester), 0);
    });

    testWidgets('sağdan sola dilde yön ters', (tester) async {
      await tester.pumpWidget(swipe(dir: TextDirection.rtl));
      final g = await dragTo(tester, 200);
      await tester.pump(const Duration(seconds: 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(commits, [1]);
    });

    testWidgets('kapalıyken çekiş yok sayılır', (tester) async {
      await tester.pumpWidget(swipe(enabled: false));
      final g = await dragTo(tester, -200);
      expect(offsetOf(tester), 0);
      await g.up();
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
    });
  });

  group('F39.5 boş durumlar', () {
    Widget empty(
      ProviderContainer c, {
      bool search = false,
      VoidCallback? add,
    }) => UncontrolledProviderScope(
      container: c,
      child: host(
        HomeEmptyNotes(
          searchActive: search,
          onClearSearch: () {},
          onNewNote: add ?? () {},
        ),
      ),
    );

    testWidgets('arama: temizle', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(empty(c, search: true));
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
      expect(find.text('Aramayı temizle'), findsOneWidget);
    });

    testWidgets('süzgeç: kaldır, süzgeç gerçekten kalkar', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(noteFilterProvider.notifier).set(NoteFilter.starred);
      await tester.pumpWidget(empty(c));
      expect(find.text('Bu süzgeçle not yok'), findsOneWidget);
      await tester.tap(find.text('Süzgeci kaldır'));
      await tester.pump();
      expect(c.read(noteFilterProvider), NoteFilter.all);
      expect(find.text('Bu süzgeçle not yok'), findsNothing);
    });

    testWidgets('klasör ve ana ekran: tek eylem not ekle', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      var added = 0;
      await tester.pumpWidget(empty(c, add: () => added++));
      expect(find.text('Henüz not yok'), findsOneWidget);
      // F74.6: hiç not yokken tek düğme "İlk notunu yaz" (Metin notu işi).
      await tester.tap(find.text('İlk notunu yaz'));
      expect(added, 1);
      c.read(selectedFolderProvider.notifier).set('k1');
      await tester.pump();
      expect(find.text('Bu klasör boş'), findsOneWidget);
      await tester.tap(find.text('Not ekle'));
      expect(added, 2);
    });
  });
}
