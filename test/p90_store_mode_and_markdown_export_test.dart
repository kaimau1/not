import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/markdown_export.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/editor/store_mode_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P90: Kolay dışa aktarma (Markdown .zip) + Akıllı liste AL-5 (Mağaza kipi).
void main() {
  group('Markdown (.zip) dışa aktarma', () {
    test(
      'klasör düzeninde .md dosyaları üretir, çöpü atlar, ad çakışmasını çözer',
      () {
        const folders = [
          NoteFolder(id: 'f-is', name: 'İş / Proje', ownerId: 'u1'),
        ];
        final notes = [
          Note(
            id: 'n1',
            type: NoteType.text,
            title: 'Toplantı',
            body: 'Bütçe onaylandı.',
            tags: const ['önemli', '2026'],
            folderId: 'f-is',
            pinned: true,
            createdAt: DateTime.utc(2026, 11, 21, 9),
          ),
          const Note(
            id: 'n2',
            type: NoteType.text,
            title: 'Toplantı',
            body: 'İkinci toplantı notu.',
            folderId: 'f-is',
          ),
          const Note(
            id: 'n3',
            type: NoteType.checklist,
            title: 'Market',
            items: [
              NoteItem(id: 'h1', text: 'Manav', header: true),
              NoteItem(id: 'i1', text: 'Elma', checked: true),
              NoteItem(id: 'i2', text: 'Süt'),
            ],
            attachments: [
              Attachment(
                id: 'a1',
                kind: AttachmentKind.image,
                fileName: 'fis.jpg',
                mimeType: 'image/jpeg',
              ),
            ],
          ),
          Note(
            id: 'n4',
            type: NoteType.ordered,
            title: 'Arşivli',
            items: const [
              NoteItem(id: 'o1', text: 'Birinci adım'),
              NoteItem(id: 'o2', text: 'İkinci adım'),
            ],
            archivedAt: DateTime.utc(2026, 11, 20),
          ),
          Note(
            id: 'n5',
            type: NoteType.text,
            title: 'Çöpteki',
            body: 'Dışa aktarılmamalı',
            deletedAt: DateTime.utc(2026, 11, 21),
          ),
        ];

        final res = buildMarkdownZip(notes, folders: folders);
        expect(res.exportedCount, 4);

        final zip = ZipDecoder().decodeBytes(res.bytes);
        final byName = {
          for (final f in zip) f.name: utf8.decode(f.content as List<int>),
        };
        expect(
          byName.keys,
          unorderedEquals([
            'İş Proje/Toplantı.md',
            'İş Proje/Toplantı-2.md',
            'Market.md',
            'Arşiv/Arşivli.md',
          ]),
        );

        final meetingMd = byName['İş Proje/Toplantı.md']!;
        expect(meetingMd, contains('title: "Toplantı"'));
        expect(meetingMd, contains('tags: ["önemli", "2026"]'));
        expect(meetingMd, contains('pinned: true'));
        expect(meetingMd, contains('Bütçe onaylandı.'));

        final marketMd = byName['Market.md']!;
        expect(marketMd, contains('## Manav'));
        expect(marketMd, contains('- [x] Elma'));
        expect(marketMd, contains('- [ ] Süt'));
        expect(marketMd, contains('## Ekler'));
        expect(marketMd, contains('`fis.jpg` (image)'));

        final orderedMd = byName['Arşiv/Arşivli.md']!;
        expect(orderedMd, contains('archived: true'));
        expect(orderedMd, contains('1. Birinci adım'));
        expect(orderedMd, contains('2. İkinci adım'));
      },
    );

    test('PDF sayfa notlarını sayfa sırasıyla yazar', () {
      const note = Note(
        id: 'p1',
        type: NoteType.pdf,
        title: 'Ders Notu',
        pageNotes: {'3': 'Üçüncü sayfa özeti', '1': 'İlk sayfa notu'},
      );
      final md = noteToMarkdown(note);
      final p1Idx = md.indexOf('## Sayfa 1');
      final p3Idx = md.indexOf('## Sayfa 3');
      expect(p1Idx, greaterThan(0));
      expect(p3Idx, greaterThan(p1Idx));
      expect(md, contains('İlk sayfa notu'));
      expect(md, contains('Üçüncü sayfa özeti'));
    });
  });

  group('AL-5 Mağaza kipi (StoreModeScreen)', () {
    testWidgets(
      'işaretleme, alınanları gizleme, reyona sıralama, hızlı ekleme ve tamamlama çalışır',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var items = <NoteItem>[
          const NoteItem(id: '1', text: 'Ekmek'),
          const NoteItem(id: '2', text: 'Elma'),
          const NoteItem(id: '3', text: 'Süt'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            home: StoreModeScreen(
              title: 'Market',
              initialItems: items,
              onToggleItem: (id) {
                items = [
                  for (final i in items)
                    if (i.id == id) i.copyWith(checked: !i.checked) else i,
                ];
                return items;
              },
              onAddItem: (raw) {
                items = insertItemsBySmartGroup(
                  items,
                  [NoteItem(id: 'added-${items.length}', text: raw)],
                  kind: SmartListKind.shopping,
                  locale: 'tr',
                );
                return items;
              },
              onSortByGroup: () {
                items = sortItemsBySmartGroup(
                  items,
                  kind: SmartListKind.shopping,
                  locale: 'tr',
                );
                return items;
              },
              onFinishChecked: () {
                items = [
                  for (final i in items)
                    if (!i.checked) i,
                ];
                return items;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 / 3 kaldı'), findsOneWidget);
        expect(find.byKey(const ValueKey('store-mode-finish')), findsNothing);

        // 1. Elma'yı işaretle → 2 / 3 kaldı, Alınanları tamamla (1) belirir.
        await tester.tap(find.byKey(const ValueKey('store-item-2')));
        await tester.pumpAndSettle();
        expect(find.text('2 / 3 kaldı'), findsOneWidget);
        expect(find.byKey(const ValueKey('store-mode-finish')), findsOneWidget);

        // 2. Alınanları gizle → Elma listeden gizlenir.
        await tester.tap(find.byKey(const ValueKey('store-mode-hide-checked')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('store-item-2')), findsNothing);
        expect(find.byKey(const ValueKey('store-item-1')), findsOneWidget);

        // 3. Hızlı ekleme: "Domates" ekle → 3 / 4 kaldı.
        await tester.enterText(
          find.byKey(const ValueKey('store-mode-add-field')),
          'Domates',
        );
        await tester.tap(find.byKey(const ValueKey('store-mode-add-submit')));
        await tester.pumpAndSettle();
        expect(find.text('3 / 4 kaldı'), findsOneWidget);
        expect(find.text('Domates'), findsOneWidget);

        // 4. Reyona sırala düğmesi çalışır (hata/taşma yok).
        await tester.tap(find.byKey(const ValueKey('store-mode-sort')));
        await tester.pumpAndSettle();

        // 5. Alınanları tamamla → işaretli Elma temizlenir, 3 / 3 kaldı.
        await tester.tap(find.byKey(const ValueKey('store-mode-finish')));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3 kaldı'), findsOneWidget);
        expect(items.any((i) => i.id == '2'), isFalse);
      },
    );
  });
}
