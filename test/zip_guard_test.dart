import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/backup_service.dart';
import 'package:notlar/features/notes/data/note_package.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/zip_guard.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

void main() {
  group('ZipGuard — ZIP bombası koruması (Faz 0 / P1-3)', () {
    test('varsayılan tavanlar: 5000 dosya ve 250 MB', () {
      expect(ZipGuard.maxFiles, 5000);
      expect(ZipGuard.maxUncompressedBytes, 250 * 1024 * 1024);
    });

    test('dosya sayısı tavanını aşan arşiv FormatException fırlatır', () {
      final archive = Archive();
      for (var i = 0; i < 6; i++) {
        archive.addFile(ArchiveFile('f$i.txt', 1, [65]));
      }
      expect(
        () => ZipGuard.validateArchive(archive, maxFileCount: 5),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ZipGuard.validateArchive(archive, maxFileCount: 6),
        returnsNormally,
      );
    });

    test('açılmış toplam boyut tavanını aşan arşiv reddedilir', () {
      final archive = Archive();
      archive.addFile(ArchiveFile('a.bin', 60, Uint8List(60)));
      archive.addFile(ArchiveFile('b.bin', 60, Uint8List(60)));
      expect(
        () => ZipGuard.validateArchive(archive, maxBytes: 100),
        throwsA(isA<FormatException>()),
      );
    });

    test('readNotePackage tavan aşımında FormatException fırlatır', () {
      final note = Note(id: 'n1', type: NoteType.text, title: 'Test');
      final bytes = buildNotePackage(note, {
        'ek1': Uint8List(512),
        'ek2': Uint8List(512),
      });
      // 3 dosya (not.json + 2 ek) → maxFiles: 2 reddeder.
      expect(
        () => readNotePackage(bytes, maxFiles: 2),
        throwsA(isA<FormatException>()),
      );
      // 1024+ bayt → maxUncompressedBytes: 500 reddeder.
      expect(
        () => readNotePackage(bytes, maxUncompressedBytes: 500),
        throwsA(isA<FormatException>()),
      );
      // Yeterli tavanla sorunsuz açılır.
      final pkg = readNotePackage(
        bytes,
        maxFiles: 5,
        maxUncompressedBytes: 4096,
      );
      expect(pkg.note.title, 'Test');
      expect(pkg.files['ek1']?.length, 512);
    });

    test('BackupService.restore dosya ve boyut tavanını uygular', () async {
      final db = FakeFirebaseFirestore();
      final repo = NotesRepository(db, 'u1');
      final service = BackupService(notes: repo, attachments: null);

      final archive = Archive();
      final json = utf8.encode(
        jsonEncode({
          'app': 'notlar',
          'kind': 'full-backup',
          'v': BackupService.formatVersion,
          'folders': <Object>[],
          'notes': <Object>[],
        }),
      );
      archive.addFile(ArchiveFile('yedek.json', json.length, json));
      for (var i = 0; i < 4; i++) {
        archive.addFile(ArchiveFile('dosyalar/n1/e$i', 100, Uint8List(100)));
      }

      await expectLater(
        () => service.restore(archive, existing: const [], maxFiles: 3),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        () => service.restore(
          archive,
          existing: const [],
          maxUncompressedBytes: 200,
        ),
        throwsA(isA<FormatException>()),
      );
      final ok = await service.restore(
        archive,
        existing: const [],
        maxFiles: 10,
        maxUncompressedBytes: 10000,
      );
      expect(ok.restored, 0);
    });
  });
}
