import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/attachment_reset_migration.dart';
import 'package:notlar/features/notes/data/attachment_sync_service.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

Attachment att(
  String id, {
  AttachmentKind kind = AttachmentKind.image,
  String storagePath = '',
  Map<String, dynamic> sync = const {},
}) => Attachment.fromMap({
  'id': id,
  'kind': kind.name,
  'fileName': '$id.jpg',
  'mimeType': 'image/jpeg',
  'storagePath': storagePath,
  'x': 0.3,
  if (sync.isNotEmpty) 'sync': sync,
});

Note note(String id, List<Attachment> a) =>
    Note(id: id, type: NoteType.text, attachments: a);

void main() {
  group('motor', () {
    late List<String> uploaded;
    late List<String> saved;
    AttachmentSyncEngine engine({
      bool fail = false,
      Set<String> skip = const {},
    }) => AttachmentSyncEngine(
      uploadFile: (a, _) async {
        if (fail) throw StateError('ağ yok');
        uploaded.add(a.id);
        return 'drive-${a.id}';
      },
      uploadThumb: (a, _) async => 'thumb-${a.id}',
      readLocal: (_) async => Uint8List(3),
      saveSync: (n, id, m) async => saved.add('$n/$id/${m['driveFileId']}'),
      hasLocalFile: (_) => true,
      skipNote: (n) => skip.contains(n.id),
      clock: () => DateTime.utc(2026, 11, 5),
    );

    setUp(() {
      uploaded = [];
      saved = [];
    });

    test(
      'yerel ek yüklenir, sonuç kayda yazılır; ikinci geçiş dokunmaz',
      () async {
        final e = engine();
        expect(
          await e.pass([
            note('n', [att('a')]),
          ]),
          1,
        );
        expect(saved, ['n/a/drive-a']);
        // Kayıtta artık Drive kimliği var.
        final synced = att(
          'a',
          sync: {'phase': 'synced', 'driveFileId': 'drive-a'},
        );
        expect(attachmentDriveFileId(synced), 'drive-a');
        expect(
          await e.pass([
            note('n', [synced]),
          ]),
          0,
        );
        expect(uploaded, ['a']);
      },
    );

    test(
      'hata beklemeye girer, buluta yazmaz, hemen yeniden denemez',
      () async {
        final e = engine(fail: true);
        expect(
          await e.pass([
            note('n', [att('a')]),
          ]),
          0,
        );
        expect(
          await e.pass([
            note('n', [att('a')]),
          ]),
          0,
        );
        expect(saved, isEmpty);
      },
    );

    test('yalnız-bu-cihaz not ve metin eki Drive\'a gitmez', () async {
      final e = engine(skip: {'gizli'});
      await e.pass([
        note('gizli', [att('a')]),
        note('n', [att('t', kind: AttachmentKind.text)]),
      ]);
      expect(uploaded, isEmpty);
    });
  });

  group('sıfırlama', () {
    final notes = [
      note('n1', [att('a', storagePath: 'users/u/attachments/a')]),
      note('n2', [att('b')]),
    ];

    test('işaretçi temizlenir; kayıt, düzen ve sync kalır; idempotent', () {
      final n = note('n', [
        att(
          'a',
          storagePath: 'x',
          sync: {'phase': 'synced', 'driveFileId': 'd'},
        ),
      ]);
      final next = resetAttachmentPointers(n)!;
      expect(next.single.storagePath, isEmpty);
      expect(next.single.x, 0.3);
      expect(attachmentDriveFileId(next.single), 'd');
      expect(resetAttachmentPointers(note('n', next)), isNull);
    });

    Future<List<String>> run({
      bool test = true,
      int? done,
      Future<bool> Function()? backup,
    }) async {
      final log = <String>[];
      await runAttachmentReset(
        isTestAccount: test,
        completedSchema: done,
        backup: backup ?? () async => true,
        notes: notes,
        writeNote: (id, _) async => log.add('yaz $id'),
        deleteOldStorage: () async => log.add('storage'),
        markDone: (v) async => log.add('işaret $v'),
      );
      return log;
    }

    test(
      'sıra: yedek, kayıt, storage, işaret; işlenmeyen not yazılmaz',
      () async {
        expect(await run(), ['yaz n1', 'storage', 'işaret $kAttachSchema']);
      },
    );

    test('yedek başarısızsa hiçbir şey yazılmaz', () async {
      await expectLater(
        run(backup: () async => false),
        throwsA(isA<AttachmentResetAborted>()),
      );
      await expectLater(
        run(backup: () async => throw StateError('disk dolu')),
        throwsA(isA<AttachmentResetAborted>()),
      );
    });

    test('test hesabı değilse durur; tamamlanmışsa dokunmaz', () async {
      await expectLater(
        run(test: false),
        throwsA(isA<AttachmentResetAborted>()),
      );
      expect(await run(done: kAttachSchema), isEmpty);
    });
  });
}
