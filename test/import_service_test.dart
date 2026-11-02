import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
      final name = f.path.substring(root.length + 1);
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
