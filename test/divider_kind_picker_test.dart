import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/divider_kind_picker.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.5, §5.4 birinci madde): tepside ve
/// levhada aynı tür seçici; beş tür, hücre başına tek çizim.
void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 360, child: child)),
    ),
  );

  List<DividerSamplePainter> painters(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<DividerSamplePainter>()
      .toList();

  testWidgets('beş tür anahtarı; dokunuş onPick(tür)', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      host(DividerKindPicker(selected: '', onPick: picked.add, compact: true)),
    );
    for (final kind in ItemDivider.kinds) {
      expect(find.byKey(ValueKey('format-divider-$kind')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('format-divider-wavy')));
    await tester.tap(find.byKey(const ValueKey('format-divider-solid')));
    expect(picked, ['wavy', 'solid']);
    expect(painters(tester), hasLength(5));
  });

  testWidgets('seçili hücre primaryContainer zeminli', (tester) async {
    await tester.pumpWidget(
      host(DividerKindPicker(selected: 'dashed', onPick: (_) {})),
    );
    final scheme = Theme.of(tester.element(find.byType(DividerKindPicker)))
        .colorScheme;
    final boxes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();
    expect(boxes[1], scheme.primaryContainer);
    expect(boxes.where((c) => c == scheme.primaryContainer), hasLength(1));
    final p = painters(tester);
    expect(p[1].fallbackColor, scheme.onPrimaryContainer);
    expect(p[0].fallbackColor, scheme.onSurfaceVariant);
  });

  testWidgets('renk/kalınlık boyamaya ulaşır; tepside kalınlık ≤ 1.5', (
    tester,
  ) async {
    const style = ItemDivider('solid', color: 0xFF1E88E5, weight: 2.5);
    await tester.pumpWidget(
      host(
        DividerKindPicker(
          selected: 'solid',
          onPick: (_) {},
          style: style,
          compact: true,
        ),
      ),
    );
    for (final p in painters(tester)) {
      expect(p.style.color, 0xFF1E88E5);
      expect(p.style.weight, 1.5);
    }
    expect(find.text('Düz'), findsNothing, reason: 'tepside ad yok');

    await tester.pumpWidget(
      host(
        DividerKindPicker(
          selected: 'solid',
          onPick: (_) {},
          style: style,
          keyPrefix: 'divider-sheet-kind-',
        ),
      ),
    );
    for (final p in painters(tester)) {
      expect(p.style.weight, 2.5);
    }
    expect(find.text('Düz'), findsOneWidget);
    expect(find.text('Dalgalı'), findsOneWidget);
    expect(find.byKey(const ValueKey('divider-sheet-kind-double')), findsOne);
  });
}
