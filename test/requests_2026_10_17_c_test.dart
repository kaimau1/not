import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_sheet.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// 2026-10-17 (4. tur): "olmamış hissi" — levhaların ortak hareketi ve
/// silinen kartın küçülerek çıkışı.
void main() {
  test('silinen kart önce çıkar, sonra silinir', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(leavingNotesProvider.notifier);
    var deleted = false;
    final done = notifier.leave(['a', 'b'], () => deleted = true);
    // Hareket sürerken kartlar "çıkıyor" kümesinde, silme henüz yok.
    expect(container.read(leavingNotesProvider), {'a', 'b'});
    expect(deleted, isFalse);
    await done;
    expect(deleted, isTrue);
    expect(container.read(leavingNotesProvider), isEmpty);
  });

  testWidgets('ortak levha açılır ve kendi hareketiyle gelir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 200, child: Text('L')),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    // Varsayılan 250 ms'den uzun: 250 ms'de henüz yerine oturmamış olmalı.
    await tester.pump(const Duration(milliseconds: 250));
    final mid = tester.getTopLeft(find.text('L')).dy;
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.text('L')).dy;
    expect(mid, greaterThan(end));
    expect(kAppSheetAnimation.duration, const Duration(milliseconds: 340));
  });
}
