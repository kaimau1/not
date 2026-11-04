import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/note_open_route.dart';

/// F23.1 (AKICILIK_PLANI, K5): sayfa geçişinde Hero taraması yapılmaz.
void main() {
  testWidgets('withoutHeroWalk içindeki Hero sayfalar arasında uçmaz', (
    tester,
  ) async {
    var flights = 0;
    Widget page(String label) => withoutHeroWalk(
      Scaffold(
        body: Hero(
          tag: 'fab',
          flightShuttleBuilder: (_, _, _, _, to) {
            flights++;
            return to.widget;
          },
          child: Text(label),
        ),
      ),
    );
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(navigatorKey: nav, home: page('A')));
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => page('B')));
    await tester.pumpAndSettle();
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(flights, 0);
  });

  test(
    'lib içinde elle Hero yok (yeni Hero geçiş taramasını geri getirir)',
    () {
      final offenders = <String>[];
      final pattern = RegExp(r'(?<![A-Za-z_])Hero\(');
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (pattern.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
      expect(offenders, isEmpty);
    },
  );
}
