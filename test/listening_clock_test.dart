import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/listening_visuals.dart';

/// Dikte süre sayacı saniye değişince DİZİLMEZ, yalnız boyanır
/// (2026-11-17, S46 CI kök nedeni: `Text` her saniye kartı diziyordu; CI'da
/// gerçek saniye geçince `kart_acik_fazla_dizilme` 0 → 22).
void main() {
  testWidgets('saniye değişimi dizilme üretmez, süre okunur', (tester) async {
    final base = DateTime.now();
    Widget host(DateTime start) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [ListeningClock(start: start, active: false)],
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(base.subtract(const Duration(seconds: 3))));
    expect(
      find.bySemanticsLabel(RegExp(r'^0:0[3-5]$')),
      findsOneWidget,
      reason: 'süre ekran okuyucuya okunur',
    );
    final before = tester.getSize(find.byType(CustomPaint).last);

    var layouts = 0;
    final oldPrint = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) {
      if (m != null && m.startsWith('Laying out')) layouts++;
    };
    debugPrintLayouts = true;
    try {
      // Aynı hane sayısında farklı saniye (0:03 → 0:47).
      await tester.pumpWidget(host(base.subtract(const Duration(seconds: 47))));
    } finally {
      debugPrintLayouts = false;
      debugPrint = oldPrint;
    }
    expect(layouts, 0, reason: 'saniye değişti, yalnız boyanmalı');
    expect(tester.getSize(find.byType(CustomPaint).last), before);
  });
}
