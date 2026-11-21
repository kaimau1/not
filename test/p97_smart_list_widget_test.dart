import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/widget_service.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// P97 / AL-6: Akıllı liste ana ekran aracı verisi + Android kaynak bekçisi.
void main() {
  test('P97 smartListWidgetData kilitli, arşivli ve gizli listeleri sızdırmaz', () {
    final notes = [
      Note(
        id: 'locked',
        type: NoteType.checklist,
        title: 'Kilitli liste',
        listKind: 'market',
        locked: true,
        updatedAt: DateTime(2026, 11, 21, 12),
        items: const [NoteItem(id: '1', text: 'Gizli ürün')],
      ),
      Note(
        id: 'hidden',
        type: NoteType.checklist,
        title: 'Gizli klasör listesi',
        listKind: 'market',
        folderId: 'secret-folder',
        updatedAt: DateTime(2026, 11, 21, 11),
        items: const [NoteItem(id: '2', text: 'Sızmamalı')],
      ),
      Note(
        id: 'archived',
        type: NoteType.checklist,
        title: 'Arşiv liste',
        listKind: 'market',
        archivedAt: DateTime(2026, 11, 20),
        items: const [NoteItem(id: '3', text: 'Eski')],
      ),
      Note(
        id: 'text-only',
        type: NoteType.text,
        title: 'Düz metin',
        body: 'Liste değil',
      ),
    ];

    final empty = smartListWidgetData(
      notes,
      hiddenFolders: const {'secret-folder'},
    );
    expect(empty.noteId, isEmpty);
    expect(empty.items, isEmpty);
    expect(empty.remaining, 0);
    expect(empty.total, 0);
  });

  test('P97 smartListWidgetData açık akıllı listeyi önceliklendirir, başlıkları atlar ve 5 maddede sınırlar', () {
    final notes = [
      Note(
        id: 'plain-newer',
        type: NoteType.checklist,
        title: 'Düz liste',
        updatedAt: DateTime(2026, 11, 21, 15),
        items: const [NoteItem(id: 'p1', text: 'Rastgele iş')],
      ),
      Note(
        id: 'done-smart',
        type: NoteType.checklist,
        title: 'Biten eczane',
        listKind: 'eczane',
        updatedAt: DateTime(2026, 11, 21, 16),
        items: const [NoteItem(id: 'd1', text: 'Vitamin', checked: true)],
      ),
      Note(
        id: 'market',
        type: NoteType.checklist,
        title: 'Haftalık Market',
        listKind: 'market',
        updatedAt: DateTime(2026, 11, 21, 14),
        items: const [
          NoteItem(id: 'h1', text: 'Süt ürünleri', header: true),
          NoteItem(id: 'm1', text: '2 süt'),
          NoteItem(id: 'm2', text: 'Yoğurt', checked: true),
          NoteItem(id: 'm3', text: 'Ekmek\ttaze'),
          NoteItem(id: 'm4', text: 'Domates'),
          NoteItem(id: 'm5', text: 'Salatalık'),
          NoteItem(id: 'm6', text: 'Elma'),
          NoteItem(id: 'm7', text: 'Armut'),
        ],
      ),
    ];

    final snap = smartListWidgetData(notes);
    expect(snap.noteId, 'market');
    expect(snap.title, 'Haftalık Market');
    expect(snap.total, 7); // Ara başlık sayılmaz
    expect(snap.remaining, 6); // 1 işaretli (Yoğurt) hariç
    expect(snap.items, ['2 süt', 'Ekmek taze', 'Domates', 'Salatalık', 'Elma']);
  });

  test('P97 SmartListWidgetProvider kayıtlı ve Android kaynakları mevcut', () {
    expect(kHomeWidgetProviders, contains('SmartListWidgetProvider'));
    expect(
      File(
        'android/app/src/main/kotlin/dev/kaimau/notlar/SmartListWidgetProvider.kt',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/layout/smart_list_widget.xml')
          .existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/xml/smart_list_widget_info.xml')
          .existsSync(),
      isTrue,
    );
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:name=".SmartListWidgetProvider"'));
  });
}
