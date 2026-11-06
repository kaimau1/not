import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/back_closes.dart';

/// Geri tuşu önce açık paneli (son açılanı) kapatır, ekran sonra kapanır;
/// tek geri iki paneli birden kapatmaz.
void main() {
  testWidgets('geri: önce son açılan panel, sonra öteki, sonra ekran', (
    tester,
  ) async {
    final open = {'a': false, 'b': false};
    var screenHandled = 0;
    late StateSetter setOuter;
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('kök')),
        routes: {
          '/not': (_) => StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return PopScope(
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && !BackCloses.handling(context)) {
                    screenHandled++;
                  }
                },
                child: Scaffold(
                  body: Column(
                    children: [
                      for (final k in ['a', 'b'])
                        BackCloses(
                          open: open[k]!,
                          onClose: () => setState(() => open[k] = false),
                          child: Text(k),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        },
      ),
    );
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/not');
    await tester.pumpAndSettle();
    // b önce, a sonra açıldı → geri önce a'yı (son açılan) kapatır.
    setOuter(() => open['b'] = true);
    await tester.pump();
    setOuter(() => open['a'] = true);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(open, {'a': false, 'b': true});
    expect(find.text('a'), findsOneWidget, reason: 'ekran açık kalmalı');
    expect(screenHandled, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(open, {'a': false, 'b': false});
    expect(find.text('b'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('kök'), findsOneWidget);
    expect(BackCloses.openCount, 0);
  });
}
