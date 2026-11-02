import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/backup_service.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F18.4: tam yedek gidiş-dönüşü — ek baytı, çizim, balon, sayfa, klasör
/// korunur; ikinci yükleme çoğaltmaz; eski JSON okunur.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;
  late FoldersRepository folders;
  late _MemAttachments files;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
    folders = FoldersRepository(db, 'u1');
    files = _MemAttachments();
  });

  Future<List<Note>> allNotes() => repo.watchNotes().first;

  Future<Uint8List> buildBackup(BackupService s) async {
    final sink = MemoryBackupSink();
    await s.export(
      sink,
      allNotes: await allNotes(),
      folderList: await folders.watchFolders().first,
    );
    return sink.bytes!;
  }

  test('gidiş-dönüş: ek, çizim, balon, sayfa ve klasör korunur', () async {
    final folderId = await folders.createFolder('İş');
    final id = await repo.createNote(NoteType.text, folderId: folderId);
    final source = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    final att = Attachment(
      id: 'a1',
      kind: AttachmentKind.pdf,
      fileName: 'rapor.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 3,
      createdAt: DateTime(2026, 11, 2),
      ink: const [InkStroke(page: 1, color: 0xFF000000, width: 2, points: [0, 0, 1, 1])],
      bubbles: const [PageBubble(id: 'b1', page: 1, x: 0.5, y: 0.5, text: 'balon')],
    );
    files.store['a1'] = Uint8List.fromList([1, 2, 3]);
    await repo.updateNote(
      source.copyWith(
        title: 'Başlık',
        body: 'gövde',
        attachments: [att],
        textPages: const [
          NoteTextPage(id: ''),
          NoteTextPage(id: 'p2', body: 'ikinci sayfa'),
        ],
        pinned: true,
      ),
    );

    final service = BackupService(
      notes: repo,
      attachments: files,
      folders: folders,
    );
    final bytes = await buildBackup(service);
    expect(sniffBackup(bytes), BackupFormat.full);

    // Başka hesaba geri yükle.
    final db2 = FakeFirebaseFirestore();
    final repo2 = NotesRepository(db2, 'u2');
    final folders2 = FoldersRepository(db2, 'u2');
    final files2 = _MemAttachments();
    final service2 = BackupService(
      notes: repo2,
      attachments: files2,
      folders: folders2,
    );
    final result = await service2.restore(
      ZipDecoder().decodeBytes(bytes),
      existing: const [],
    );
    expect(result.restored, 1);
    final restored = (await repo2.watchNotes().first).single;
    expect(restored.title, 'Başlık');
    expect(restored.pinned, isTrue);
    expect(restored.textPages.map((p) => p.body), contains('ikinci sayfa'));
    final a = restored.attachments.single;
    expect(a.ink.single.points, [0, 0, 1, 1]);
    expect(a.bubbles.single.text, 'balon');
    expect(files2.store['a1'], [1, 2, 3]);
    final f2 = await folders2.watchFolders().first;
    expect(f2.single.name, 'İş');
    expect(restored.folderId, f2.single.id);

    // İkinci yükleme: hiçbir şey çoğalmaz (klasör dahil).
    final again = await service2.restore(
      ZipDecoder().decodeBytes(bytes),
      existing: await repo2.watchNotes().first,
      existingFolders: f2,
    );
    expect(again.restored, 0);
    expect(again.skipped, 1);
    expect(await repo2.watchNotes().first, hasLength(1));
    expect(await folders2.watchFolders().first, hasLength(1));
  });

  test('aynı hesaba geri yükleme kimlikten tanır', () async {
    await repo.createNote(NoteType.text, title: 'tek');
    final service = BackupService(notes: repo, attachments: files);
    final bytes = await buildBackup(service);
    final r = await service.restore(
      ZipDecoder().decodeBytes(bytes),
      existing: await allNotes(),
    );
    expect(r.restored, 0);
    expect(await allNotes(), hasLength(1));
  });

  test('eski JSON yedeği okunur, ikinci kez çoğaltmaz', () async {
    final legacy = {
      'app': 'notlar',
      'notes': [
        {
          'id': 'old1',
          'type': 'checklist',
          'title': 'Alışveriş',
          'body': '',
          'items': [
            {'text': 'süt', 'checked': true},
          ],
          'tags': ['ev'],
        },
      ],
    };
    final service = BackupService(notes: repo, attachments: null);
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(legacy)));
    expect(sniffBackup(bytes), BackupFormat.legacyJson);
    final r1 = await service.restoreLegacyJson(legacy, existing: const []);
    expect(r1.restored, 1);
    final n = (await allNotes()).single;
    expect(n.items.single.text, 'süt');
    expect(n.items.single.checked, isTrue);
    expect(n.tags, ['ev']);
    final r2 = await service.restoreLegacyJson(
      legacy,
      existing: await allNotes(),
    );
    expect(r2.restored, 0);
    expect(await allNotes(), hasLength(1));
  });

  test('özet kimlik ve tarihten bağımsız', () {
    const a = Note(
      id: 'x',
      type: NoteType.checklist,
      title: 'T',
      items: [NoteItem(id: '1', text: 'a')],
    );
    const b = Note(
      id: 'y',
      type: NoteType.checklist,
      title: 'T ',
      items: [NoteItem(id: '2', text: 'a')],
    );
    expect(noteDigest(a), noteDigest(b));
    expect(noteDigest(a), isNot(noteDigest(a.copyWith(title: 'U'))));
  });

  test('iptal yarıda keser', () async {
    await repo.createNote(NoteType.text, title: 'bir');
    final service = BackupService(notes: repo, attachments: files);
    expect(
      () => service.export(
        MemoryBackupSink(),
        allNotes: const [Note(id: 'z', type: NoteType.text)],
        cancelled: () => true,
      ),
      throwsA(isA<BackupCancelled>()),
    );
  });
}

class _MemAttachments implements AttachmentRepository {
  final store = <String, Uint8List>{};

  @override
  Future<Uint8List?> readBytes(Attachment attachment) async =>
      store[attachment.id];

  @override
  Future<Attachment> importAttachment({
    required String noteId,
    required Attachment meta,
    required Uint8List bytes,
  }) async {
    store[meta.id] = bytes;
    return meta;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
