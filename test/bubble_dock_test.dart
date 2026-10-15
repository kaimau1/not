import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Balon YAZMA kartı (klavyenin üstündeki kart).
///
/// KİLİT: eylemler (renk/yıldız/acil/sil) kartın İÇİNDE, menü ya da levha
/// rotası itmez. Kök neden (kullanıcı bulgusu 2026-08-08: "balondaki yazıyı
/// düzenlerken 3 noktaya basılınca klavye kapanıyor, kullanımı bozuyor"):
/// itilen rota kendi odak kapsamını alır, `TextField` odağı düşer ve klavye
/// kapanır — menü kapansa da geri gelmez.
///
/// 2026-10-15 yenilemesi: eylemler artık "⋮"nin arkasında DEĞİL, kartta hep
/// görünür ("balonlu mod baştan aşağı yenilenmeli").
void main() {
  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  /// Kartın gövde alanı (başlık alanı ilk, gövde ikinci).
  bool bodyHasFocus(WidgetTester tester) =>
      tester
          .widget<TextField>(find.byType(TextField).last)
          .focusNode
          ?.hasFocus ??
      false;

  testWidgets('eylemler kartta HEP görünür, dokunmak odağı DÜŞÜRMEZ', (
    tester,
  ) async {
    final controller = BubbleController(initial: const [], onChanged: (_) {});
    addTearDown(controller.dispose);
    // Yeni balon doğrudan yazmaya açılır (editMode) — kart görünür.
    controller.add(1, 0.5, 0.5);

    await tester.pumpWidget(host(BubbleDock(controller: controller)));
    await tester.pumpAndSettle();
    expect(bodyHasFocus(tester), isTrue, reason: 'kart klavyeyi açmış olmalı');

    // Menü yok; renk, yıldız, acil ve sil doğrudan kartta.
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byKey(const ValueKey('bubble-color-toggle')), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();
    expect(controller.bubbles.single.starred, isTrue);
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

    await tester.tap(find.byKey(const ValueKey('bubble-color-toggle')));
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

  testWidgets('"Bitti" balonu kapatır ve kart kaybolur', (tester) async {
    final saved = <List<PageBubble>>[];
    final controller = BubbleController(
      initial: const [],
      onChanged: saved.add,
    );
    addTearDown(controller.dispose);
    controller.add(1, 0.3, 0.3);

    await tester.pumpWidget(host(BubbleDock(controller: controller)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'oku');
    await tester.tap(find.text('Bitti'));
    await tester.pumpAndSettle();

    expect(controller.openBubble, isNull);
    expect(find.byType(TextField), findsNothing);
    expect(saved.last.single.text, 'oku', reason: 'yazılan kaydedilmeli');
  });
}
