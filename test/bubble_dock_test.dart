import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Balon YAZMA kartı (klavyenin üstündeki kart).
///
/// KİLİT: eylemler (yıldız/acil/renk/sil) kartın İÇİNDE açılır, menü ya da
/// levha rotası itmez. Kök neden (kullanıcı bulgusu 2026-08-08: "balondaki
/// yazıyı düzenlerken 3 noktaya basılınca klavye kapanıyor, kullanımı
/// bozuyor"): itilen rota kendi odak kapsamını alır, `TextField` odağı düşer
/// ve klavye kapanır — menü kapansa da geri gelmez.
void main() {
  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  /// Kartın gövde alanı (başlık alanı ilk, gövde ikinci).
  bool bodyHasFocus(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).last).focusNode?.hasFocus ??
      false;

  testWidgets('⋮ eylemleri kartın içinde açar, YAZI ALANI ODAKTA KALIR', (
    tester,
  ) async {
    final controller = BubbleController(initial: const [], onChanged: (_) {});
    addTearDown(controller.dispose);
    // Yeni balon doğrudan yazmaya açılır (editMode) — kart görünür.
    controller.add(1, 0.5, 0.5);

    await tester.pumpWidget(host(BubbleDock(controller: controller)));
    await tester.pumpAndSettle();
    expect(bodyHasFocus(tester), isTrue, reason: 'kart klavyeyi açmış olmalı');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Eylemler kartın içinde: yıldız, acil, renk, sil.
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    // ASIL KİLİT: odak düşmedi, yani klavye kapanmadı.
    expect(bodyHasFocus(tester), isTrue);
  });

  testWidgets('renk şeridi de kartın içinde — levha açılmaz, odak korunur', (
    tester,
  ) async {
    final controller = BubbleController(initial: const [], onChanged: (_) {});
    addTearDown(controller.dispose);
    controller.add(2, 0.5, 0.5);

    await tester.pumpWidget(host(BubbleDock(controller: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(bodyHasFocus(tester), isTrue);

    // Şeritten renk seçmek balonu günceller (modal dönüşü beklenmez).
    final second = BubbleController.palette[1];
    await tester.tap(find.byKey(ValueKey('bubble-color-$second')));
    await tester.pumpAndSettle();
    expect(controller.bubbles.single.color, second);
    expect(bodyHasFocus(tester), isTrue);
  });
}
