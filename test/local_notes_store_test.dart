import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/local_notes_store.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Yalnız bu cihazda tutulan notlar (kullanıcı isteği 2026-09-26:
/// "senkronizasyon kapatma nota özel").
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('local_notes'));
  tearDown(() => dir.deleteSync(recursive: true));

  const note = Note(
    id: 'n1',
    type: NoteType.checklist,
    title: 'Market',
    items: [NoteItem(id: 'a', text: 'Süt')],
    reminderAt: null,
  );

  test('konulan not okunur, localOnly işaretli', () {
    final store = LocalNotesStore.atPath('${dir.path}/s.json');
    store.put(note.id, note.toMap());
    final read = store.note('n1')!;
    expect(read.title, 'Market');
    expect(read.items.single.text, 'Süt');
    expect(read.localOnly, isTrue);
    // Sunucu damgası yerelde ŞİMDİ'ye çözülür.
    expect(read.updatedAt, isNotNull);
    expect(store.notes(), hasLength(1));
  });

  test('merge alanları üstüne yazar, delete alanı siler', () {
    final store = LocalNotesStore.atPath('${dir.path}/s.json');
    store.put(note.id, {...note.toMap(), 'fontFamily': 'Lora'});
    store.merge('n1', {'pinned': true, 'fontFamily': FieldValue.delete()});
    final read = store.note('n1')!;
    expect(read.pinned, isTrue);
    expect(read.fontFamily, isNull);
    // Var olmayan nota merge yeni kayıt açmaz.
    store.merge('yok', {'pinned': true});
    expect(store.contains('yok'), isFalse);
  });

  test('çöpe atılan not yalnız silinenlerde', () {
    final store = LocalNotesStore.atPath('${dir.path}/s.json');
    store.put(note.id, note.toMap());
    store.merge('n1', {'deletedAt': Timestamp.now()});
    expect(store.notes(), isEmpty);
    expect(store.notes(deleted: true).single.id, 'n1');
  });

  test('diske yazılır ve yeni örnekte geri okunur (tarihler dahil)', () async {
    final path = '${dir.path}/s.json';
    final store = LocalNotesStore.atPath(path);
    final when = DateTime(2026, 9, 26, 10, 30);
    store.put(note.id, note.copyWith(reminderAt: when).toMap());
    store.clearFolder('yok');
    await store.flush();
    final again = LocalNotesStore.atPath(path);
    final read = again.note('n1')!;
    expect(read.reminderAt, when);
    expect(read.items.single.text, 'Süt');
  });

  test('bozuk dosya yedeklenir, depo boş başlar', () {
    final path = '${dir.path}/s.json';
    File(path).writeAsStringSync('{bozuk');
    final store = LocalNotesStore.atPath(path);
    expect(store.isEmpty, isTrue);
    expect(File('$path.bozuk').existsSync(), isTrue);
  });

  test('klasör silinince yerel notlardan düşer', () {
    final store = LocalNotesStore.atPath('${dir.path}/s.json');
    store.put(note.id, note.copyWith(folderId: 'f1').toMap());
    store.clearFolder('f1');
    expect(store.note('n1')!.folderId, isNull);
  });

  group('madde kopyalama', () {
    const items = [
      NoteItem(id: '1', text: '**Süt**'),
      NoteItem(id: '2', text: 'Ekmek', checked: true),
      NoteItem(id: '3', text: ' '),
    ];
    test('çok madde: ☐/☑, boşlar atlanır', () {
      expect(itemsCopyText(items, checkboxes: true), '☐ Süt\n☑ Ekmek');
      expect(itemsCopyText(items, checkboxes: false), '1. Süt\n2. Ekmek');
    });
    test('tek madde: yalnız metin', () {
      expect(itemsCopyText(items.take(1).toList(), checkboxes: true), 'Süt');
    });
  });
}
