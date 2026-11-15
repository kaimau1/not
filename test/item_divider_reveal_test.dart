import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// P63 PB6 (plan_tasarim_B §5.4 "Beliriş"): çizgi eklenince bir kez soldan
/// sağa çizilir ve durur; not AÇILIRKEN çizgiler tam (ticker yok); hareketi
/// azalt açıkken tek kare.
void main() {
  Note list({bool dividers = false}) => Note(
    id: 'n',
    type: NoteType.checklist,
    title: 'Liste',
    items: [
      for (var i = 0; i < 12; i++)
        NoteItem(
          id: 'i$i',
          text: 'madde $i',
          divider: dividers && i < 10 ? 'dashed' : '',
        ),
    ],
  );

  /// Satırların çizgi boyayıcıları (özel tür: adla bulunur).
  List<dynamic> painters(WidgetTester tester) => [
    for (final w in tester.widgetList<CustomPaint>(find.byType(CustomPaint)))
      if (w.foregroundPainter?.runtimeType.toString() == '_ItemDividerPainter')
        w.foregroundPainter,
  ];

  Future<void> addSolid(WidgetTester tester) async {
    await tester.tap(find.text('madde 3'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Biçim'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('format-divider-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('format-divider-solid')));
    await tester.pump();
  }

  testWidgets('not açılırken çizgiler tam, beliriş denetleyicisi yok', (
    tester,
  ) async {
    await pumpEditor(tester, list(dividers: true));
    final ps = painters(tester);
    expect(ps, hasLength(10));
    for (final p in ps) {
      expect(p.reveal, isNull, reason: 'açılışta oynamaz');
    }
    await endEditor(tester);
  });

  testWidgets('boş → çizgili: beliriş bir kez oynar ve durur', (tester) async {
    await pumpEditor(tester, list());
    expect(painters(tester), isEmpty);
    await addSolid(tester);
    final p = painters(tester).single;
    final Animation<double> reveal = p.reveal as Animation<double>;
    await tester.pump(const Duration(milliseconds: 50));
    expect(reveal.value, inExclusiveRange(0, 1), reason: 'oynuyor');
    await tester.pump(const Duration(milliseconds: 400));
    expect(reveal.value, 1);
    expect(reveal.isAnimating, isFalse, reason: 'durdu');
    await endEditor(tester);
  });

  testWidgets('hareketi azalt: çizgi tek karede tam', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpEditor(tester, list());
    await addSolid(tester);
    expect(painters(tester).single.reveal, isNull);
    await endEditor(tester);
  });
}
