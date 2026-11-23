import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/notes/data/backup_files.dart';
import 'package:notlar/features/notes/data/backup_service.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/presentation/backup_ui.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P91: Parolalı tam yedek (AES-256 ZIP dışa aktarma, otomatik algılama ve
/// parola penceresiyle geri yükleme; parolasız geriye dönük uyumluluk).
void main() {
  group('Parolalı tam yedek (AES-256)', () {
    test(
      'MemoryBackupSink: şifreli yedek başlığı tanınır, düz metin görünmez, doğru parolayla geri yüklenir',
      () async {
        final dbExport = FakeFirebaseFirestore();
        final repoExport = NotesRepository(dbExport, 'u1');
        final serviceExport = BackupService(
          notes: repoExport,
          attachments: null,
        );
        const secretBody = 'COK_GIZLI_PAROLALI_YEDEK_METNI_2026';
        final note = Note(
          id: 'n1',
          type: NoteType.text,
          title: 'Gizli Günlük',
          body: secretBody,
          tags: const ['özel'],
          createdAt: DateTime.utc(2026, 11, 21),
        );

        final sink = MemoryBackupSink(password: 'parola-123!');
        await serviceExport.export(sink, allNotes: [note]);
        final bytes = sink.bytes!;

        // 1. İlk 8 bayt şifreli ZIP olarak tanınır; düz metin ham baytlarda yoktur.
        expect(isEncryptedZipHead(bytes), isTrue);
        expect(latin1.decode(bytes, allowInvalid: true), isNot(contains(secretBody)));

        // 2. Yanlış parola ile çözülemez.
        expect(
          () {
            final bad = ZipDecoder().decodeBytes(bytes, password: 'yanlis');
            for (final f in bad) {
              f.content;
            }
          },
          throwsA(isA<Object>()),
        );

        // 3. Doğru parola ile eksiksiz geri yüklenir.
        final dbRestore = FakeFirebaseFirestore();
        final repoRestore = NotesRepository(dbRestore, 'u2');
        final serviceRestore = BackupService(
          notes: repoRestore,
          attachments: null,
        );
        final archive = ZipDecoder().decodeBytes(
          bytes,
          password: 'parola-123!',
        );
        final result = await serviceRestore.restore(archive, existing: const []);
        expect(result.restored, 1);
        final docs = await dbRestore.collection('users/u2/notes').get();
        expect(docs.docs.single.data()['body'], secretBody);
      },
    );

    test('parolasız yedekte isEncryptedZipHead false döner', () async {
      final db = FakeFirebaseFirestore();
      final service = BackupService(
        notes: NotesRepository(db, 'u1'),
        attachments: null,
      );
      final sink = MemoryBackupSink();
      await service.export(
        sink,
        allNotes: const [Note(id: 'n1', type: NoteType.text, title: 'Açık')],
      );
      expect(isEncryptedZipHead(sink.bytes!), isFalse);
    });

    test('FileBackupSink + openBackupFile parola ile dosya gidiş-dönüşü', () async {
      final tmp = await Directory.systemTemp.createTemp('notlar_p91_');
      addTearDown(() => tmp.delete(recursive: true));
      final path = '${tmp.path}/sifreli.notyedek';

      final dbExport = FakeFirebaseFirestore();
      final serviceExport = BackupService(
        notes: NotesRepository(dbExport, 'u1'),
        attachments: null,
      );
      await serviceExport.export(
        FileBackupSink(path, password: 'dosya-sifresi'),
        allNotes: const [
          Note(
            id: 'f1',
            type: NoteType.text,
            title: 'Dosya Notu',
            body: 'Diskten şifreli geri yükleme.',
          ),
        ],
      );

      final head = await File(path).openRead(0, 16).expand((b) => b).toList();
      expect(isEncryptedZipHead(head), isTrue);

      final dbRestore = FakeFirebaseFirestore();
      final serviceRestore = BackupService(
        notes: NotesRepository(dbRestore, 'u2'),
        attachments: null,
      );
      final archive = openBackupFile(path, password: 'dosya-sifresi');
      final res = await serviceRestore.restore(archive, existing: const []);
      expect(res.restored, 1);
      final docs = await dbRestore.collection('users/u2/notes').get();
      expect(docs.docs.single.data()['title'], 'Dosya Notu');
    });

    testWidgets(
      'showBackupExportPasswordDialog uyuşmazlığı yakalar ve parolalı/parolasız döner',
      (tester) async {
        ({String? password})? result;
        // Pencere PL6 kapısını (proFeatureProvider) okur → ProviderScope; kapı
        // açık verilir (Play derlemesinde de parola alanları görünsün).
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              proFeatureProvider(
                ProFeature.encryptedBackup,
              ).overrideWithValue(true),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              locale: const Locale('tr'),
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await showBackupExportPasswordDialog(context);
                    },
                    child: const Text('Aç'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Aç'));
        await tester.pumpAndSettle();

        // Eşleşmeyen parolada hata verir, pencere kapanmaz.
        await tester.enterText(
          find.byKey(const ValueKey('backup-export-pass')),
          'sifre1',
        );
        await tester.enterText(
          find.byKey(const ValueKey('backup-export-pass-confirm')),
          'sifre2',
        );
        await tester.tap(find.byKey(const ValueKey('backup-export-with-pass')));
        await tester.pumpAndSettle();
        expect(find.text('Parolalar eşleşmiyor'), findsOneWidget);
        expect(result, isNull);

        // Eşleşince şifreli parola döner.
        await tester.enterText(
          find.byKey(const ValueKey('backup-export-pass-confirm')),
          'sifre1',
        );
        await tester.tap(find.byKey(const ValueKey('backup-export-with-pass')));
        await tester.pumpAndSettle();
        expect(result?.password, 'sifre1');

        // Tek dokunuşla "Parolasız yedekle" null parola döner.
        result = null;
        await tester.tap(find.text('Aç'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('backup-export-no-pass')));
        await tester.pumpAndSettle();
        expect(result, isNotNull);
        expect(result!.password, isNull);
      },
    );
  });
}
