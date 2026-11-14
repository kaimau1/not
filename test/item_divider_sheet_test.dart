import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/divider_kind_picker.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/item_divider_style.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P63 PB6 (plan_tasarim_B §5.4): çizgi tepsisinde ve levhasında beş tür,
/// levhanın sonuçları ve dar ekranda taşmasızlık.
void main() {
  Widget app(Widget home, {double scale = 1}) => MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  );

  testWidgets('tepside beş tür; seçim onDivider\'a gider', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FormatBar(
              onFormat: (format, {colorIndex}) {},
              onClearFormat: () {},
              onRemoveFormat: (_) {},
              fontFamily: null,
              fontScale: 1,
              textOpacity: 1,
              hasSelection: () => false,
              onFontChanged: (_) {},
              onScaleChanged: (_) {},
              onScaleEnd: (_) {},
              onOpacityChanged: (_) {},
              onOpacityEnd: (_) {},
              onClose: () {},
              dividerKind: 'dashed',
              dividerStyle: const ItemDivider('dashed', weight: 3),
              onDivider: picked.add,
              onDividerStyle: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('format-divider-menu')));
    await tester.pumpAndSettle();
    for (final kind in ItemDivider.kinds) {
      expect(find.byKey(ValueKey('format-divider-$kind')), findsOneWidget);
    }
    final picker = tester.widget<DividerKindPicker>(
      find.byType(DividerKindPicker),
    );
    expect(picker.compact, isTrue);
    expect(picker.selected, 'dashed');
    expect(picker.style?.weight, 3, reason: 'renk/kalınlık tepsiye ulaşır');
    await tester.tap(find.byKey(const ValueKey('format-divider-wavy')));
    expect(picked, ['wavy']);
  });

  Future<ItemDividerChoice?> run(
    WidgetTester tester,
    Future<void> Function() act, {
    Size size = const Size(412, 915),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ItemDividerChoice? result;
    var done = false;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showItemDividerSheet(
                    context,
                    initial: const ItemDivider('solid'),
                  );
                  done = true;
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
        scale: scale,
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    expect(done, isTrue, reason: 'levha kapandı');
    return result;
  }

  testWidgets('levha sonuçları: Tamam, Tüm çizgilere, kaldır, dışına dokun', (
    tester,
  ) async {
    var r = await run(tester, () async {
      await tester.tap(find.byKey(const ValueKey('divider-sheet-kind-wavy')));
      await tester.pumpAndSettle();
      // Önizleme (seçici) o türde.
      expect(
        tester
            .widget<DividerKindPicker>(find.byType(DividerKindPicker))
            .selected,
        'wavy',
      );
      await tester.tap(find.byKey(const ValueKey('divider-sheet-ok')));
    });
    expect(r?.style?.kind, 'wavy');
    expect(r?.applyAll, isFalse);

    r = await run(
      tester,
      () => tester.tap(find.byKey(const ValueKey('divider-sheet-all'))),
    );
    expect(r?.style?.kind, 'solid');
    expect(r?.applyAll, isTrue);

    r = await run(
      tester,
      () => tester.tap(find.byKey(const ValueKey('divider-sheet-remove'))),
    );
    expect(r, isNotNull);
    expect(r!.style, isNull);

    r = await run(tester, () => tester.tapAt(const Offset(200, 20)));
    expect(r, isNull);
  });

  testWidgets('360 dp + yazı 1.3: taşma yok', (tester) async {
    await run(
      tester,
      () => tester.tap(find.byKey(const ValueKey('divider-sheet-ok'))),
      size: const Size(360, 640),
      scale: 1.3,
    );
    expect(tester.takeException(), isNull);
  });
}
