import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/import_service.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F18.15: Keep Takeout, Markdown ve Evernote içe aktarma.
void main() {
  const root = 'test/fixtures/import';

  Archive zipOf(String dir) {
    final archive = Archive();
    for (final f in Directory(dir).listSync(recursive: true)) {
      if (f is! File) continue;
      // Zip girdisi hep `/`: Windows'ta `listSync` `\` verir (girdi bulunmaz).
      final name = f.path.substring(root.length + 1).replaceAll(r'\', '/');
      final bytes = f.readAsBytesSync();
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    return ZipDecoder().decodeBytes(ZipEncoder().encode(archive));
  }

  test('Keep Takeout: liste, renk, sabit, arşiv, etiket, görsel, tarih', () {
    final archive = zipOf('$root/Takeout');
    expect(looksLikeKeepTakeout(archive), isTrue);
    final notes = parseKeepTakeout(archive);
    expect(notes, hasLength(2));
    final list = notes.firstWhere((n) => n.note.title == 'Alışveriş');
    expect(list.note.type, NoteType.checklist);
    expect(list.note.items.map((i) => (i.text, i.checked)), [
      ('Süt', true),
      ('Ekmek', false),
    ]);
    expect(list.note.color, NoteColor.amber);
    expect(list.pinned, isTrue);
    expect(list.note.tags, ['ev']);
    expect(
      list.createdAt,
      DateTime.fromMicrosecondsSinceEpoch(1690000000000000),
    );
    final idea = notes.firstWhere((n) => n.note.title == 'Fikir');
    expect(idea.archived, isTrue);
    expect(idea.note.body, contains('ikinci satır'));
    expect(idea.note.attachments.single.kind, AttachmentKind.image);
    expect(idea.files.values.single, 'PNGDATA'.codeUnits);
  });

  test('Markdown: başlık, satır içi biçim, onay kutuları', () {
    final text = File('$root/notlar.md').readAsStringSync();
    final n = parseMarkdownNote('notlar.md', text)!;
    expect(n.note.title, 'Toplantı');
    expect(n.note.type, NoteType.text);
    expect(n.note.body, contains('**önemli**'));
    expect(n.note.body, contains('_acil_'));
    expect(n.note.body, contains('☑ Bütçe'));
    expect(n.note.body, contains('☐ Takvim'));
    final todo = parseMarkdownNote(
      'yapilacaklar.md',
      File('$root/yapilacaklar.md').readAsStringSync(),
    )!;
    expect(todo.note.type, NoteType.checklist);
    expect(todo.note.items.map((i) => i.checked), [false, true]);
  });

  test('başlıksız txt dosya adını başlık alır', () {
    final n = parseMarkdownNote('klasor/gunluk.txt', 'bugün güzeldi')!;
    expect(n.note.title, 'gunluk');
    expect(n.note.body, 'bugün güzeldi');
  });

  test('Evernote: başlık, kalın, onay kutusu, etiket, tarih', () {
    final notes = parseEnex(File('$root/ornek.enex').readAsStringSync());
    final n = notes.single;
    expect(n.note.title, 'Evernote notu');
    expect(n.note.body, contains('**Kalın** metin'));
    expect(n.note.body, contains('☑ Bitti'));
    expect(n.note.tags, ['iş']);
    expect(n.createdAt!.toUtc(), DateTime.utc(2024, 1, 15, 9, 30));
  });

  test('yazım: özet, ikinci kez çoğaltmaz; özet', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'u1');
    final service = ImportService(notes: repo, attachments: _Mem());
    final items = parseKeepTakeout(zipOf('$root/Takeout'));
    final r1 = await service.importAll(items, existing: const []);
    expect(r1.imported, 2);
    final all = await repo.watchNotes().first;
    final idea = all.firstWhere((n) => n.title == 'Fikir');
    expect(idea.archivedAt, isNotNull);
    expect(idea.attachments, hasLength(1));
    final again = parseKeepTakeout(zipOf('$root/Takeout'));
    final r2 = await service.importAll(again, existing: all);
    expect(r2.imported, 0);
    expect(r2.skipped, 2);
  });

  // KÖK NEDEN (P60, 2026-11-14: taze kurulumda 240 notluk Keep içe
  // aktarmasından 67'si sessizce kayboldu). Android eklentisi her yazımı
  // ayrı iş parçacığında başlatır (`cachedThreadPool`), yani beklenmeyen bir
  // yazım SONRA verilen yazımdan sonra düşebilir. Eskiden not önce boş
  // `createNote` ile (beklenmeden) doğuyor, içerik ayrı yazımla geliyordu:
  // boş yazım geç düşünce içerik silinir, boş not 2 dk sonra temizlenirdi.
  test(
    'içe aktarma: geç düşen ilk yazım içeriği ve bayrakları silmez',
    () async {
      final inner = FakeFirebaseFirestore();
      final repo = NotesRepository(_LateFirstWrite(inner), 'u1');
      final created = DateTime.utc(2024, 3, 1, 10);
      final r = await ImportService(notes: repo, attachments: _Mem()).importAll(
        [
          ImportedNote(
            note: const Note(
              id: '',
              type: NoteType.text,
              title: 'Kalıcı',
              body: 'gövde',
            ),
            pinned: true,
            createdAt: created,
          ),
        ],
        existing: const [],
      );
      expect(r.imported, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final docs = (await inner.collection('users/u1/notes').get()).docs;
      expect(docs, hasLength(1));
      final note = Note.fromDoc(docs.single);
      expect(note.title, 'Kalıcı');
      expect(note.body, 'gövde');
      expect(note.pinned, isTrue);
      expect(note.createdAt!.toUtc(), created);
    },
  );
}

/// Bir belgeye verilen İLK yazımı geciktirir (eklentinin sırasız iş
/// parçacığı); sonraki yazımlar hemen düşer.
// ignore: subtype_of_sealed_class
class _LateFirstWrite implements FirebaseFirestore {
  _LateFirstWrite(this.inner);
  final FakeFirebaseFirestore inner;
  final seen = <String>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Col(this, inner.collection(path));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Col implements CollectionReference<Map<String, dynamic>> {
  _Col(this.fs, this.inner);
  final _LateFirstWrite fs;
  final CollectionReference<Map<String, dynamic>> inner;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Doc(fs, inner.doc(path));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Doc implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.fs, this.inner);
  final _LateFirstWrite fs;
  final DocumentReference<Map<String, dynamic>> inner;

  @override
  String get id => inner.id;

  @override
  String get path => inner.path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Col(fs, inner.collection(path));

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (fs.seen.add(inner.path)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    await inner.set(data, options);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mem implements AttachmentRepository {
  @override
  Future<Attachment> importAttachment({
    required String noteId,
    required Attachment meta,
    required Uint8List bytes,
  }) async => meta;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
