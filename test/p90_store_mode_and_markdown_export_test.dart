import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/markdown_export.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/shopping_summary_bar.dart';
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

  group('AL-5 Doğrudan Not Üzerinde Alışveriş Kipi', () {
    testWidgets(
      'reyon başlıkları, satır içi miktar adımı, işaretleme ve canlı özet çubuğu çalışır',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var items = <NoteItem>[
          const NoteItem(id: '1', text: 'Ekmek', price: 15),
          const NoteItem(id: '2', text: 'Elma', quantity: 1, unit: 'kg', price: 40),
          const NoteItem(id: '3', text: 'Süt', price: 35),
        ];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (ctx, setState) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              locale: const Locale('tr'),
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ItemsEditor(
                        items: items,
                        showCheckboxes: true,
                        listMode: ListMode.shopping,
                        groupByAisle: true,
                        onChanged: (next) => setState(() => items = next),
                      ),
                    ),
                    ShoppingSummaryBar(items: items),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('aisle-header-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('aisle-header-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('aisle-header-2')), findsOneWidget);
        expect(find.text('0/3 alındı'), findsOneWidget);
        expect(find.text('Toplam: 90 ₺'), findsOneWidget);

        // Kural 5: Gruplu görünümde ID ile miktar artırma (Elma 1 kg -> 1.5 kg, fiyat 40 -> 60 ₺, toplam 110 ₺).
        await tester.tap(find.byKey(const ValueKey('shop-qty-inc-2')));
        await tester.pumpAndSettle();
        final apple = items.firstWhere((i) => i.id == '2');
        expect(apple.quantity, 1.5);
        expect(find.text('Toplam: 110 ₺'), findsOneWidget);
      },
    );
  });
}
