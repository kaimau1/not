import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_heavy.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/note_version.dart';

/// VERİ KATMANI (F4.9): depo, bellekteki sahte Firestore'a karşı.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  Future<Note> noteNow(String id) async =>
      (await repo.watchNote(id).firstWhere((n) => n != null))!;

  test('oluştur → güncelle → akışta görünür', () async {
    final id = await repo.createNote(NoteType.text, title: 'İlk');
    final note = await noteNow(id);
    await repo.updateNote(note.copyWith(body: 'gövde'));
    final again = await repo
        .watchNote(id)
        .firstWhere((n) => n != null && n.body == 'gövde');
    expect(again!.title, 'İlk');
    final all = await repo.watchNotes().first;
    expect(all.map((n) => n.id), contains(id));
  });

  test(
    'sürüm: açıldığı hâl ilk değişiklikte saklanır, sonra 30 dk aralık',
    () async {
      final id = await repo.createNote(NoteType.text, body: 'dünkü hâl');
      final opened = await noteNow(id);
      repo.rememberVersionBase(opened);
      await repo.updateNote(opened.copyWith(body: 'bugün 1'));
      await repo.updateNote(opened.copyWith(body: 'bugün 2'));
      await Future<void>.delayed(Duration.zero);
      final versions = await repo.listVersions(id);
      expect(versions, hasLength(1), reason: '30 dk dolmadan ikinci sürüm yok');
      expect(versions.single.body, 'dünkü hâl');
      expect(versions.single.reason, 'open');
      // Geri dönüş: sürüm yalnız metni uygular.
      final restored = versions.single.applyTo(opened.copyWith(body: 'x'));
      expect(restored.body, 'dünkü hâl');
    },
  );

  test('yalnız renk değişince sürüm üretilmez', () async {
    final id = await repo.createNote(NoteType.text, body: 'metin');
    final opened = await noteNow(id);
    repo.rememberVersionBase(opened);
    await repo.updateNote(opened.copyWith(pinned: true));
    await Future<void>.delayed(Duration.zero);
    expect(await repo.listVersions(id), isEmpty);
  });

  test('sürümler en çok $kMaxVersions tutulur (sahip budar)', () async {
    final id = await repo.createNote(NoteType.text);
    final note = await noteNow(id);
    for (var i = 0; i < kMaxVersions + 5; i++) {
      await repo.saveVersion(note.copyWith(body: 'v$i'), reason: 'auto');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final snap = await db
        .collection('users/u1/notes/$id/$kVersionsCollection')
        .get();
    expect(snap.docs.length, kMaxVersions);
  });

  test('ağır not iki belgeye yazılır, okurken birleşir (F3.13)', () async {
    final id = await repo.createNote(NoteType.text);
    final note = await noteNow(id);
    final points = [for (var i = 0; i < 20000; i++) (i % 97) / 97];
    final heavyNote = note.copyWith(
      attachments: [
        Attachment(
          id: 'a1',
          kind: AttachmentKind.pdf,
          fileName: 'x.pdf',
          mimeType: 'application/pdf',
          ink: [
            InkStroke(page: 1, color: 0xFF000000, width: 0.01, points: points),
          ],
        ),
      ],
    );
    await repo.updateNote(heavyNote);
    final main = await db.doc('users/u1/notes/$id').get();
    expect(main.data()!['heavyRef'], isTrue);
    final atts = main.data()!['attachments'] as List;
    expect((atts.first as Map).containsKey('ink'), isFalse);
    final heavy = await db
        .doc('users/u1/notes/$id/$kHeavyCollection/$kHeavyDocId')
        .get();
    expect(heavy.exists, isTrue);
  });
}
