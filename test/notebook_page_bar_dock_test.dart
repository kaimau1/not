import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// Kullanıcı isteği 2026-11-22: defterin sayfa çubuğu alt panelin hemen
/// üstünde SABİT (kaydırılan içeriğin dışında); sarı bloknotta alt panel
/// kâğıt tonunda.
void main() {
  testWidgets('sayfa çubuğu kaydırılan içeriğin dışında, alt panelin üstünde', (
    tester,
  ) async {
    final note = Note(
      id: 'n',
      type: NoteType.checklist,
      title: 'Defter',
      paged: true,
      archivePaper: ArchivePaper.legal,
      items: [
        for (var i = 0; i < 40; i++) NoteItem(id: 'i$i', text: 'madde $i'),
      ],
    );
    await pumpEditor(tester, note);
    final dock = find.byKey(const ValueKey('page-bar-dock'));
    expect(dock, findsOneWidget);
    // Uzun listede bile ekranda (kaydırmadan) ve bir Scrollable'ın içinde
    // değil.
    expect(
      find.ancestor(of: dock, matching: find.byType(Scrollable)),
      findsNothing,
    );
    final bar = tester.getRect(dock);
    final bottomBar = tester.getRect(find.byType(BottomAppBar));
    expect(bar.bottom, lessThanOrEqualTo(bottomBar.top + 1));
    expect(bar.bottom, greaterThan(bottomBar.top - 4));
    // Alt panel kâğıt tonunda (beyaz değil).
    final color = tester.widget<BottomAppBar>(find.byType(BottomAppBar)).color;
    expect(color, isNot(equals(Colors.white)));
    expect(color!.r, greaterThan(color.b));
    await endEditor(tester);
  });
}
