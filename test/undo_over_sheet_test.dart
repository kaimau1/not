import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/core/widgets/app_sheet.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';

void main() {
  testWidgets('levhadan silince "Geri al" levhanın ÜSTÜNDE, dokunulabilir', (
    tester,
  ) async {
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        // Uygulamadaki gibi bildirim şeridi Navigator'ın üstünde (P62 PA5).
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showAppSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SizedBox(
                    height: 500,
                    child: Center(
                      child: TextButton(
                        onPressed: () => showUndoSnackBar(
                          ctx,
                          message: 'Silindi',
                          undoLabel: 'Geri al',
                          onUndo: () => undone = true,
                        ),
                        child: const Text('sil'),
                      ),
                    ),
                  ),
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('sil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('notice-action')), findsOneWidget);
    // warnIfMissed varsayılan: levha düğmeyi örterse test kırmızı.
    await tester.tap(find.byKey(const ValueKey('notice-action')));
    expect(undone, isTrue);
    await tester.pump(const Duration(seconds: 1));
  });
}
