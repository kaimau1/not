import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_sheet.dart';

/// KT-20 (tablet turu 2026-11-18): dikey tablette (640 dp) alt levhalar tam
/// genişliğe yayılıyordu ("Uygulama" levhası, kart ⋮, "Görünüm ve süz").
/// KÖK NEDEN: KT-2'nin 560 dp kuralı yalnız kendi `constraints`'ini veren
/// levhadaydı; geri kalanı M3'ün varsayılan 640 dp sınırını alıyordu — 640
/// dp'lik dikey tablet ekranı tam o kadar. Kural artık `showAppSheet`'te:
/// her levha en çok [kSheetMaxWidth], ortada; dar telefonda değişiklik yok.
void main() {
  Future<Rect> openSheet(
    WidgetTester tester,
    Size size, {
    BoxConstraints? constraints,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSheet<void>(
                context: context,
                constraints: constraints,
                builder: (_) =>
                    const SizedBox(height: 200, width: double.infinity),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return tester.getRect(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('KT-20: dikey tablette (640 dp) levha en çok 560 dp, ortada', (
    tester,
  ) async {
    final r = await openSheet(tester, const Size(640, 1024));
    expect(r.width, kSheetMaxWidth);
    expect(r.center.dx, closeTo(320, 0.5));
  });

  testWidgets('KT-20: yalnız maxHeight veren levha da genişliği aşmaz', (
    tester,
  ) async {
    final r = await openSheet(
      tester,
      const Size(1280, 800),
      constraints: const BoxConstraints(maxHeight: 500),
    );
    expect(r.width, kSheetMaxWidth);
  });

  testWidgets('KT-20: telefonda levha tam genişlik (değişmedi)', (
    tester,
  ) async {
    final r = await openSheet(tester, const Size(400, 800));
    expect(r.width, 400);
  });

  testWidgets('KT-20: daha dar sınır veren levha kendi sınırını korur', (
    tester,
  ) async {
    final r = await openSheet(
      tester,
      const Size(1280, 800),
      constraints: const BoxConstraints(maxWidth: 520),
    );
    expect(r.width, 520);
  });
}
