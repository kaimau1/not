import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
