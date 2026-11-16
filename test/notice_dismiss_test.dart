// Kullanıcı bulgusu 2026-11-16: "bildirimleri kapatmak zor, bayağı
// kapanmıyor" + "bildirimler varken kasma var".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';

Future<void> _pump(WidgetTester tester, AppNoticeController c) =>
    tester.pumpWidget(
      MaterialApp(
        home: AppNoticeHost(
          controller: c,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

void main() {
  testWidgets('bildirime dokununca kapanır', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.show(const AppNoticeData(text: 'kaydedildi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('kaydedildi'));
    await tester.pumpAndSettle();
    expect(c.current, isNull);
  });

  testWidgets('yana itince kapanır, az itince yerine döner', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    var undone = 0;
    c.show(
      AppNoticeData(
        text: 'silindi',
        actionLabel: 'Geri al',
        onAction: () => undone++,
      ),
    );
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.text('silindi'),
      const Offset(20, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump();
    expect(c.current, isNotNull, reason: 'kısa itiş kapatmaz');
    await tester.drag(find.text('silindi'), const Offset(160, 0));
    await tester.pump();
    expect(c.current, isNull);
    expect(undone, 0, reason: 'kapatmak geri almaz');
  });

  testWidgets('aşağı itince kapanır', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.show(const AppNoticeData(text: 'kaydedildi'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('kaydedildi'), const Offset(0, 120));
    await tester.pump();
    expect(c.current, isNull);
  });

  testWidgets('geri sayım her karede değil, kademeli ilerler', (tester) async {
    final c = AppNoticeController();
    addTearDown(c.dispose);
    await _pump(tester, c);
    c.show(
      AppNoticeData(text: 'silindi', actionLabel: 'Geri al', onAction: () {}),
    );
    await tester.pumpAndSettle();
    // Karede bir zamanlayıcı gibi değil: 16 ms'lik pompada kare istenmez.
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(SteppedCountdown), findsOneWidget);
  });
}
