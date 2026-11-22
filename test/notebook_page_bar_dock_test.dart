import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/notebook_paper.dart';

import 'support/editor_harness.dart';

/// Kullanıcı isteği 2026-11-22: defterin sayfa çubuğu alt panelin hemen
/// üstünde SABİT (kaydırılan içeriğin dışında); kâğıt deseni (çizgiler,
/// kenar çizgisi, cilt gölgesi ve sarı bloknot tonu) üst ve alt alanla
/// kesintisiz bir bütün; sayfa çubuğu ve alt kapsüller kâğıt tonunda.
void main() {
  setUpAll(disableFontRuntimeFetching);

  testWidgets(
    'sayfa çubuğu kaydırılan içeriğin dışında, alt panelin üstünde; kâğıt ve çizgiler tüm ekranı kaplar',
    (tester) async {
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

      // Tam ekran defter kâğıdı Scaffold'ı sarar (üst çubuk + gövde + alt
      // panel aynı kâğıt yüzeyinde; çift legalTint dikişi yok).
      expect(
        find.ancestor(
          of: find.byType(Scaffold),
          matching: find.byType(NotebookPaper),
        ),
        findsOneWidget,
      );
      // Çizgili bloknotta alt panelin arkasında yatay satır çizgileri sürer.
      expect(
        find.ancestor(
          of: find.byType(BottomAppBar),
          matching: find.byType(NotebookRuledBand),
        ),
        findsOneWidget,
      );
      // Alt çubuk şeffaf: arkadaki kâğıt tonu, kenar çizgisi ve yatay çizgiler
      // kesintisiz görünür.
      final appBar = tester.widget<BottomAppBar>(find.byType(BottomAppBar));
      expect(appBar.color, Colors.transparent);
      expect(appBar.elevation, 0);

      // Sayfa çubuğu ve alt kapsüller soğuk beyaz/adaçayı değil, sıcak bloknot
      // tonunda.
      Color boxColor(String key) =>
          (tester.widget<DecoratedBox>(find.byKey(ValueKey(key))).decoration
                  as BoxDecoration)
              .color!;
      for (final key in const [
        'page-bar-surface',
        'editor-tool-capsule',
        'editor-ai-capsule',
      ]) {
        final c = boxColor(key);
        expect(c, isNot(equals(Colors.white)), reason: key);
        expect(c.r, greaterThan(c.b), reason: '$key sıcak sarı/kehribar tonunda');
      }
      await endEditor(tester);
      await tester.pump();
    },
  );
}
