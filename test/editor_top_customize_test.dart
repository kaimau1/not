import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// P50 — "her şey düzenlenebilsin": editör üst çubuğunda sarmasız kalan
/// düğmeler (geniş ekranda Ana sayfa, tablette Tam ekran) da gizlenebilir.
void main() {
  tearDown(Personalize.debugReset);
  const note = Note(id: 'n', type: NoteType.text, title: 'T', body: 'yazı');
  const home = ValueKey('editor-home');
  const full = ValueKey('note-fullscreen');

  testWidgets('Ana sayfa ve Tam ekran gizlenir; düzenleme modunda çerçeveli', (
    tester,
  ) async {
    await pumpEditor(tester, note, size: const Size(1280, 800));
    expect(find.byKey(home), findsOneWidget);
    expect(find.byKey(full), findsOneWidget);

    Personalize.update(
      (p) => p
          .withVisible(UiItem.topHome, false)
          .withVisible(UiItem.topFullscreen, false),
    );
    await tester.pump();
    expect(find.byKey(home), findsNothing);
    expect(find.byKey(full), findsNothing);
    // ⋮ kapıdır, hiç gizlenmez.
    expect(find.byKey(const ValueKey('editor-more')), findsOneWidget);

    Personalize.startEditing();
    await tester.pump();
    for (final key in [home, full]) {
      expect(
        find.ancestor(
          of: find.byKey(key),
          matching: find.byType(CustomizeFrame),
        ),
        findsOneWidget,
      );
    }
    Personalize.done();
    await tester.pump();
    await endEditor(tester);
  });
  testWidgets('kayıtlı üst çubuk sırası uygulanır, ⋮ hep sonda (P20 M8)', (
    tester,
  ) async {
    await pumpEditor(tester, note, size: const Size(1280, 800));
    double x(Key k) => tester.getCenter(find.byKey(k)).dx;
    expect(x(home), lessThan(x(full)));

    Personalize.update(
      (p) => p.copyWith(topOrder: [UiItem.topFullscreen, UiItem.topHome]),
    );
    await tester.pump();
    expect(x(full), lessThan(x(home)));
    const more = ValueKey('editor-more');
    expect(x(more), greaterThan(x(home)));
    expect(x(more), greaterThan(x(full)));
    await endEditor(tester);
  });
}
