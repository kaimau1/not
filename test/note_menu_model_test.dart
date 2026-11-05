import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_menu_model.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **TEK NOT MENÜSÜ** (F38.1, K2): kart ⋮ ve not ⋮ aynı katalog.
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));
  const note = Note(
    id: 'n',
    type: NoteType.checklist,
    title: 'Başlık',
    items: [NoteItem(id: 'a', text: 'madde')],
    attachments: [
      Attachment(
        id: 'g',
        kind: AttachmentKind.image,
        fileName: 'g.png',
        mimeType: 'image/png',
      ),
    ],
  );

  ActionMenu menu(
    NoteMenuSurface surface, {
    Set<String> elsewhere = const {},
  }) => noteMenuModel(
    l10n,
    note,
    surface: surface,
    visibleElsewhere: elsewhere,
    canPinHome: true,
    localOnlyAvailable: true,
    bubbleView: false,
    canRemoveParts: true,
  );

  // (grup, kimlik) sırasıyla; hızlı satır grup 'quick'.
  List<(String, String)> flat(ActionMenu m) => [
    for (final a in m.quick) ('quick', a.id),
    for (final s in m.sections)
      for (final a in s.actions) (s.title, a.id),
    if (m.danger case final d?) ('danger', d.id),
  ];

  test('ortak işler iki yüzeyde aynı grupta, aynı sırada', () {
    final card = flat(menu(NoteMenuSurface.card));
    final editor = flat(menu(NoteMenuSurface.editor));
    final cardIds = card.map((e) => e.$2).toSet();
    final editorIds = editor.map((e) => e.$2).toSet();
    final common = cardIds.intersection(editorIds);
    // A6: eskiden ayrı yerde/tek yüzeyde duranlar artık ortak.
    expect(
      common,
      containsAll([
        'listen',
        'color',
        'frame',
        'cardMedia',
        'pinHome',
        'share',
      ]),
    );
    expect(
      card.where((e) => common.contains(e.$2)).toList(),
      editor.where((e) => common.contains(e.$2)).toList(),
    );
    expect(cardIds.difference(editorIds), {'select'});
  });

  test('gruplar aynı ad ve sırada', () {
    expect(
      menu(NoteMenuSurface.card).sections.map((s) => s.title),
      menu(NoteMenuSurface.editor).sections.map((s) => s.title),
    );
  });

  test('başka yerde görünen düşer, görünmeyen geri gelir', () {
    final ids = flat(
      menu(
        NoteMenuSurface.editor,
        elsewhere: const {'pin', 'color', 'search', 'share'},
      ),
    ).map((e) => e.$2);
    for (final id in ['pin', 'color', 'search', 'share']) {
      expect(ids, isNot(contains(id)), reason: id);
    }
    final all = flat(menu(NoteMenuSurface.editor)).map((e) => e.$2);
    for (final id in ['pin', 'color', 'search', 'share']) {
      expect(all, contains(id), reason: id);
    }
  });

  test('salt okunurda görünüm işleri yok', () {
    final ids = flat(
      noteMenuModel(
        l10n,
        note,
        surface: NoteMenuSurface.editor,
        readOnly: true,
      ),
    ).map((e) => e.$2);
    for (final id in ['color', 'frame', 'cardMedia']) {
      expect(ids, isNot(contains(id)), reason: id);
    }
  });

  test('her işin yüzeyinde karşılığı var (ölü düğme yok)', () {
    final cardSource = File(
      'lib/features/notes/presentation/note_actions_sheet.dart',
    ).readAsStringSync();
    final editorSource = File(
      'lib/features/notes/presentation/editor/note_editor_actions.dart',
    ).readAsStringSync();
    for (final (_, id) in flat(menu(NoteMenuSurface.card))) {
      expect(cardSource, contains("case '$id':"), reason: 'kart: $id');
    }
    final editor = menu(NoteMenuSurface.editor);
    for (final id in [
      ...flat(editor).map((e) => e.$2),
      ...editor.footer.map((a) => a.id),
    ]) {
      expect(editorSource, contains("case '$id':"), reason: 'editör: $id');
    }
  });

  test('üst çubuk başlığı metnin sol kenarında (F38.2)', () {
    // Telefon: geri okuyla bitişik, geri yokken 16 dp.
    expect(editorTitleSpacing(412, hasLeading: true), 0);
    expect(editorTitleSpacing(412, hasLeading: false), 16);
    // Geniş bölme: okuma sütununun kenarı.
    expect(editorTitleSpacing(1160, hasLeading: false), 216);
    expect(editorTitleSpacing(1160, hasLeading: true), 160);
  });
}
