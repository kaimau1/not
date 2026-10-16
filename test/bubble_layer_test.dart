import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Balonlu kipin SAYFA katmanı (2026-10-15 yenilemesi — kullanıcı isteği:
/// "balonlu mod baştan aşağı yenilenmeli; balon görüntüsü, performansı,
/// genel hatlar").
void main() {
  const size = 400.0;

  Future<void> pump(
    WidgetTester tester,
    BubbleController controller, {
    List<int> pages = const [1],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            // Sayfalar YAN YANA: 800×600 sınama ekranına iki sayfa sığsın.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final page in pages)
                  SizedBox(
                    width: size,
                    height: size,
                    child: BubblePageLayer(controller: controller, page: page),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Offset origin(WidgetTester tester) =>
      tester.getTopLeft(find.byType(BubblePageLayer).first);

  group('tutamaç bir konuşma balonu: sivri köşesi NOKTADA', () {
    testWidgets('serbest balonun gövdesi noktanın ÜSTÜNE açılır', (
      tester,
    ) async {
      final controller = BubbleController(
        initial: const [
          PageBubble(id: 'b', page: 1, x: 0.5, y: 0.5, text: 'not'),
        ],
        onChanged: (_) {},
      );
      addTearDown(controller.dispose);
      await pump(tester, controller);
      final rect = tester.getRect(find.byKey(const ValueKey('b')));
      final o = origin(tester);
      // Eski yuvarlak tutamaç noktanın TAM ÜSTÜNE ortalanıyor, işaret
      // ettiği kelimeyi kapatıyordu.
      expect(rect.bottomLeft - o, const Offset(200, 200));
    });

    testWidgets('vurgunun tutamacı satırın ALTINA açılır (yazıyı örtmez)', (
      tester,
    ) async {
      final controller = BubbleController(
        initial: const [
          PageBubble(
            id: 'h',
            page: 1,
            x: 0.5,
            y: 0.3,
            rects: [PageBubbleRect(0.2, 0.25, 0.8, 0.3)],
          ),
        ],
        onChanged: (_) {},
      );
      addTearDown(controller.dispose);
      await pump(tester, controller);
      final rect = tester.getRect(find.byKey(const ValueKey('h')));
      expect(rect.topLeft - origin(tester), const Offset(200, 120));
    });

    testWidgets('sağ kenardaki balon SOLA döner, sayfadan taşmaz', (
      tester,
    ) async {
      final controller = BubbleController(
        initial: const [
          PageBubble(
            id: 'r',
            page: 1,
            x: 0.98,
            y: 0.5,
            title: 'Uzun başlık',
            text: 'x',
          ),
        ],
        onChanged: (_) {},
      );
      addTearDown(controller.dispose);
      await pump(tester, controller);
      final rect = tester.getRect(find.byKey(const ValueKey('r')));
      final o = origin(tester);
      expect(rect.right - o.dx, closeTo(size * 0.98, 0.01));
      expect(rect.left, greaterThanOrEqualTo(o.dx));
    });
  });

  testWidgets(
    'başka sayfadaki değişiklik bu sayfanın balonlarını yeniden KURMAZ',
    (tester) async {
      // KÖK NEDEN (kasma): katman denetleyicinin HER bildirimini dinliyordu;
      // başka sayfada bir balonu yıldızlamak görünen bütün sayfaları baştan
      // kuruyordu.
      final controller = BubbleController(
        initial: const [
          PageBubble(id: 'p1', page: 1, x: 0.5, y: 0.5, text: 'bir'),
          PageBubble(id: 'p2', page: 2, x: 0.5, y: 0.5, text: 'iki'),
        ],
        onChanged: (_) {},
      );
      addTearDown(controller.dispose);
      await pump(tester, controller, pages: const [1, 2]);

      final before = tester.widget(find.byKey(const ValueKey('p1')));
      controller.toggleStar('p2');
      await tester.pump();
      expect(
        identical(tester.widget(find.byKey(const ValueKey('p1'))), before),
        isTrue,
        reason: '1. sayfa yeniden kurulmamalı',
      );

      controller.toggleStar('p1');
      await tester.pump();
      expect(
        identical(tester.widget(find.byKey(const ValueKey('p1'))), before),
        isFalse,
        reason: 'kendi balonu değişince sayfa tazelenmeli',
      );
    },
  );

  testWidgets('okuma kartında YAZILI "Düzenle" yazmaya geçirir', (
    tester,
  ) async {
    final controller = BubbleController(
      initial: const [
        PageBubble(id: 'b', page: 1, x: 0.3, y: 0.3, text: 'merhaba'),
      ],
      onChanged: (_) {},
    );
    addTearDown(controller.dispose);
    await pump(tester, controller);

    await tester.tap(find.byKey(const ValueKey('b')));
    await tester.pump();
    expect(find.text('merhaba'), findsOneWidget);
    expect(controller.editMode, isFalse, reason: 'önce yalnız okunur');

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    expect(controller.editMode, isTrue);
  });
}
