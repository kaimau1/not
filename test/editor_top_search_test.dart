import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/in_note_find.dart';

import 'support/editor_harness.dart';

/// Kullanıcı bulguları 2026-11-16: "Notta ara butonu yarım saniye sonra
/// beliriyor"; "arama üst menünün altında yeni satırda olsun, alt panelimin
/// yerini almasın"; "klavye açıkken + ve ⋮ kasarak açılıyor".
void main() {
  const text = Note(id: 'n', type: NoteType.text, title: 'Kısa', body: 'yazı');

  testWidgets('Notta ara düğmesi açılışın ilk karelerinde var', (tester) async {
    await pumpEditor(tester, text);
    expect(find.byKey(const ValueKey('editor-top-search')), findsOneWidget);
    await endEditor(tester);
  });

  testWidgets('arama satırı üst çubuğun altında; alt çubuk yerinde', (
    tester,
  ) async {
    await pumpEditor(tester, text);
    final add = find.byKey(const ValueKey('editor-add-button'));
    expect(add, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-top-search')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final bar = find.byType(NoteFindBar);
    expect(bar, findsOneWidget);
    expect(add, findsOneWidget, reason: 'alt çubuk arama açıkken de duruyor');
    final more = tester.getRect(find.byKey(const ValueKey('editor-more')));
    final barRect = tester.getRect(bar);
    expect(barRect.top, greaterThanOrEqualTo(more.bottom - 1));
    expect(barRect.top, lessThan(200), reason: 'üst çubuğun hemen altında');
    expect(barRect.bottom, lessThan(tester.getRect(add).top));
    // Kapat: satır kalkar.
    await tester.tap(
      find.descendant(of: bar, matching: find.byIcon(Icons.close)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(NoteFindBar), findsNothing);
    await endEditor(tester);
  });

  testWidgets('klavye açıkken ⋮: levha önce kurulur, klavye sonra iner', (
    tester,
  ) async {
    await pumpEditor(tester, text);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final field = FocusManager.instance.primaryFocus!;
    // Yazı alanı odağı bıraktığında levha çoktan kurulmuş olmalı.
    bool? sheetBuiltAtBlur;
    void onFocus() {
      if (!field.hasFocus && sheetBuiltAtBlur == null) {
        sheetBuiltAtBlur = find.byType(BottomSheet).evaluate().isNotEmpty;
      }
    }

    field.addListener(onFocus);
    await tester.tap(find.byKey(const ValueKey('editor-more')));
    expect(field.hasPrimaryFocus, isTrue, reason: 'dokunuşta klavye inmez');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    field.removeListener(onFocus);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(field.hasFocus, isFalse, reason: 'klavye indi');
    expect(sheetBuiltAtBlur, isTrue, reason: 'önce levha, sonra klavye');
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 500));
    await endEditor(tester);
  });
}
