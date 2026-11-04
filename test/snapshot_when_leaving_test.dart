import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/snapshot_when_leaving.dart';

/// F26.4 (AKICILIK_PLANI, K9): segment geçişinde ayrılan ızgara donmuş
/// görüntüdür; sarmalayıcı yapıyı değiştirmez (durum korunur).
void main() {
  testWidgets('ayrılırken görüntü + dokunuş yok; durum korunur', (
    tester,
  ) async {
    var taps = 0;
    Widget build(bool leaving) => MaterialApp(
      home: Material(
        child: SnapshotWhenLeaving(
          leaving: leaving,
          child: ListView(
            children: [
              for (var i = 0; i < 50; i++)
                ListTile(title: Text('satır $i'), onTap: () => taps++),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(build(false));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final offset = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(offset, greaterThan(0));
    SnapshotController ctl() =>
        tester.widget<SnapshotWidget>(find.byType(SnapshotWidget)).controller;
    expect(ctl().allowSnapshotting, isFalse);

    await tester.pumpWidget(build(true));
    expect(ctl().allowSnapshotting, isTrue);
    await tester.tap(find.text('satır 8'), warnIfMissed: false);
    expect(taps, 0);
    // Aynı Scrollable durumu (yeniden kurulmadı): konum yerinde.
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      offset,
    );

    await tester.pumpWidget(build(false));
    expect(ctl().allowSnapshotting, isFalse);
    await tester.tap(find.text('satır 8'));
    expect(taps, 1);
  });
}
