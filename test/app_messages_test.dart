import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';

/// F8.3: ortak bildirim yardımcısı.
void main() {
  testWidgets('düz bildirim metni gösterir, eylemli olan geri sayımlı', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showAppMessage(ctx, 'Kaydedildi');
    await tester.pump();
    expect(find.text('Kaydedildi'), findsOneWidget);
    expect(find.byKey(const ValueKey('snack-countdown')), findsNothing);

    var tapped = false;
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showMessage(
        'Silindi',
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => tapped = true,
        ),
      );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('snack-countdown')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('snack-action')));
    expect(tapped, isTrue);
  });

  testWidgets('şerit varken ileti şeritte; eylemli geri sayımlı (P62 PA5)', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showAppMessage(ctx, 'Kaydedildi');
    await tester.pump();
    expect(find.text('Kaydedildi'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byKey(const ValueKey('notice-countdown')), findsNothing);

    var tapped = false;
    ScaffoldMessenger.of(ctx).showMessage(
      'Silindi',
      action: SnackBarAction(label: 'Geri al', onPressed: () => tapped = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Kaydedildi'), findsNothing, reason: 'en yeni kazanır');
    expect(find.byKey(const ValueKey('notice-countdown')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notice-action')));
    expect(tapped, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(appNotice.current, isNull);
  });
}
