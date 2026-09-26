import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/freeze_when_hidden.dart';

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
}
