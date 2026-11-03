import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/freeze_when_hidden.dart';
import 'package:notlar/core/widgets/note_route_closing.dart';

/// Örtülü ana ekran yeniden kurulmaz (kullanıcı isteği 2026-09-26:
/// "performans ve akıcılık").
void main() {
  testWidgets('opak rota altındayken çocuk yeniden kurulmaz', (tester) async {
    var builds = 0;
    final label = ValueNotifier('a');
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: ValueListenableBuilder<String>(
          valueListenable: label,
          builder: (context, value, _) => FreezeWhenHidden(
            child: Builder(
              builder: (context) {
                builds++;
                return Text(value, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      ),
    );
    expect(builds, 1);

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
    await tester.pumpAndSettle();
    final before = builds;

    // Örtülüyken veri üç kez değişir: alt ağaç HİÇ kurulmaz.
    for (final v in ['b', 'c', 'd']) {
      label.value = v;
      await tester.pump();
    }
    expect(builds, before);

    // Üstteki rota kapanınca: geri dönüş animasyonu sırasında ESKİ görüntü
    // kalır (animasyonun ilk karesinde ağır kurulum olmasın), bekleme
    // bitince en son veriyle bir kez kurulur.
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(builds, before);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(builds, before + 1);
    expect(find.text('d'), findsOneWidget);
  });

  testWidgets('yarı saydam levha altında canlı kalır', (tester) async {
    final label = ValueNotifier('a');
    late BuildContext root;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            root = context;
            return ValueListenableBuilder<String>(
              valueListenable: label,
              builder: (context, value, _) =>
                  FreezeWhenHidden(child: Text(value)),
            );
          },
        ),
      ),
    );
    unawaited(
      showModalBottomSheet<void>(
        context: root,
        builder: (_) => const SizedBox(height: 100),
      ),
    );
    await tester.pumpAndSettle();
    label.value = 'z';
    await tester.pump();
    expect(find.text('z'), findsOneWidget);
  });

  // Kullanıcı bulgusu 2026-11-03: "klavye açılırken kasma, not kapanırken
  // kasma". Örtülü ana ekran klavyenin her karesini MediaQuery'den alıyordu;
  // karttan küçülen kapanışta yetişme animasyonun son karesine biniyordu.
  group('klavye ve kapanış', () {
    tearDown(() => noteRouteClosing.value = false);

    Future<(GlobalKey<NavigatorState>, List<double>, ValueNotifier<String>)>
    pumpHome(WidgetTester tester) async {
      final insets = <double>[];
      final label = ValueNotifier('a');
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: ValueListenableBuilder<String>(
            valueListenable: label,
            builder: (context, value, _) => FreezeWhenHidden(
              child: Builder(
                builder: (context) {
                  insets.add(MediaQuery.viewInsetsOf(context).bottom);
                  return Text(value);
                },
              ),
            ),
          ),
        ),
      );
      return (navigator, insets, label);
    }

    testWidgets('örtülüyken klavye kareleri alt ağaca inmez', (tester) async {
      addTearDown(tester.view.reset);
      final (navigator, insets, _) = await pumpHome(tester);
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();
      final before = insets.length;
      for (var i = 1; i <= 10; i++) {
        tester.view.viewInsets = FakeViewPadding(bottom: 30.0 * i);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(insets.length, before, reason: 'klavye her karede uyarmamalı');

      // Klavye kapanıp rota inince yetişmede canlı değere döner.
      tester.view.viewInsets = FakeViewPadding.zero;
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(insets.last, 0);
    });

    testWidgets('karttan kapanış sürerken yetişmez, bitince ayrı karede', (
      tester,
    ) async {
      final (navigator, _, label) = await pumpHome(tester);
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();
      label.value = 'yeni';
      await tester.pump();

      // Not kartına küçülerek kapanıyor (bkz. note_open_route.dart).
      noteRouteClosing.value = true;
      navigator.currentState!.pop();
      await tester.pump();
      // Eski 380 ms'lik bekleme dolsa da kapanış sürüyor: eski görüntü.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('a'), findsOneWidget);

      noteRouteClosing.value = false;
      await tester.pump();
      expect(find.text('a'), findsOneWidget, reason: 'rotanın söküldüğü kare');
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('yeni'), findsOneWidget);
    });
  });
}
