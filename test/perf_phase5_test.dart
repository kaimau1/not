import 'dart:io';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/drive_store.dart';
import 'package:notlar/features/notes/data/local_notes_store.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/pptx_render.dart';
import 'package:notlar/features/notes/data/reminder_service.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/image_prepare_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/viewers/slide_canvas.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 5 (PERFORMANS_TOPARLAMA_PLANI.md): doğrulanmış hatalar ve bellek
/// sızıntıları.
void main() {
  group('F5.1 tek nota bağlı akışlar dinleyen gidince yok edilir', () {
    test('noteStreamProvider kapanınca dispose olur', () async {
      var disposed = 0;
      final c = ProviderContainer(
        overrides: [
          noteStreamProvider.overrideWith((ref, id) {
            ref.onDispose(() => disposed++);
            return Stream.value(Note(id: id, type: NoteType.text));
          }),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(noteStreamProvider('n1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(c.exists(noteStreamProvider('n1')), isTrue);
      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(disposed, 1);
      expect(c.exists(noteStreamProvider('n1')), isFalse);
    });

    test('folderNotesProvider ve kutusu kapanınca yok edilir', () async {
      final c = ProviderContainer(
        overrides: [
          notesStreamProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(folderNotesProvider('f1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(c.exists(folderNotesProvider('f1')), isFalse);
    });
  });

  group('F5.2 görseller gösterildiği boyda çözülür', () {
    testWidgets('çoklu seçimin küçük resim şeridi ve önizleme', (t) async {
      final dir = Directory.systemTemp.createTempSync('prep');
      addTearDown(() => dir.deleteSync(recursive: true));
      final a = File('${dir.path}/a.png')..writeAsBytesSync(_png);
      final b = File('${dir.path}/b.png')..writeAsBytesSync(_png);
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ImagePrepareScreen(paths: [a.path, b.path]),
        ),
      );
      final thumbs = t
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.image != null)
          .toList();
      expect(thumbs, hasLength(2));
      expect(thumbs.every((d) => d.image!.image is ResizeImage), isTrue);
      final preview = t.widget<Image>(find.byType(Image).first);
      expect(preview.image, isA<ResizeImage>());
    });

    testWidgets('slayt zemini ve şekil görseli', (t) async {
      final slide = SlideVM(
        widthPt: 720,
        heightPt: 405,
        backgroundImage: _png,
        shapes: [ShapeVM(x: 0, y: 0, w: 100, h: 100, image: _png)],
      );
      await t.pumpWidget(MaterialApp(home: SlideCanvas(slide: slide)));
      final images = t.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(2));
      expect(images.every((i) => i.image is ResizeImage), isTrue);
    });
  });

  group('F5.3 yetim hatırlatıcılar', () {
    test('istenmeyen ve kimliği kaymış not: bildirimleri iptal edilir', () {
      final orphans = orphanReminderIds(
        [
          (id: 1, payload: 'note:a'), // istenen, kimlik doğru
          (id: 2, payload: 'note:b'), // başka cihazda kaldırıldı
          (id: 3, payload: 'note:c'), // istenen ama kimlik farklı
          (id: 999001, payload: 'briefing'), // brifinge dokunulmaz
          (id: 5, payload: null),
        ],
        {'a': 1, 'c': 30},
      );
      expect(orphans, [2, 3]);
    });
  });

  group('F5.4 yalnız bu cihaza alma', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('local_only'));
    tearDown(() {
      driveFileDeleter = null;
      dir.deleteSync(recursive: true);
    });

    test(
      'sürüm geçmişi silinir, Drive eki indirilip Drive kopyası silinir',
      () async {
        final db = FakeFirebaseFirestore();
        final store = LocalNotesStore.atPath('${dir.path}/s.json');
        final repo = NotesRepository(db, 'u1', local: store);
        final drive = Attachment(
          id: 'a1',
          kind: AttachmentKind.image,
          fileName: 'a.png',
          mimeType: 'image/png',
          driveId: 'd1',
          localPath: '${dir.path}/att/a.png',
        );
        final note = Note(
          id: 'n1',
          type: NoteType.text,
          title: 'Gizli',
          attachments: [drive],
        );
        final doc = db.doc('users/u1/notes/n1');
        await doc.set(note.toMap());
        await doc.collection('versions').add({'text': 'eski metin'});
        await doc.collection('presence').doc('u1').set({'at': 1});
        final deletedDrive = <String>[];
        driveFileDeleter = (id) async => deletedDrive.add(id);

        await repo.setLocalOnly(
          note,
          localOnly: true,
          attachments: _FakeAttachments(_png),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect((await doc.get()).exists, isFalse);
        expect((await doc.collection('versions').get()).docs, isEmpty);
        expect((await doc.collection('presence').get()).docs, isEmpty);
        expect(File(drive.localPath).readAsBytesSync(), _png);
        expect(deletedDrive, ['d1']);
        expect(store.note('n1')!.attachments.single.driveId, isEmpty);
      },
    );
  });

  group('F5.5 hesap değişince bellek', () {
    test('arama gövdesi önbelleği silinen notları budar', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      clearSearchBodyCache();
      const a = Note(id: 'a', type: NoteType.text, body: 'bir');
      const b = Note(id: 'b', type: NoteType.text, body: 'iki');
      searchableBodyForTest(a);
      searchableBodyForTest(b);
      expect(searchBodyCacheSize, 2);
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => Stream.value(const [a])),
          foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(c.dispose);
      c.listen(filteredNotesProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      c.read(filteredNotesProvider);
      expect(searchBodyCacheSize, 1);
      clearSearchBodyCache();
      expect(searchBodyCacheSize, 0);
    });
  });

  group('F5.6 ağır belge gelirken yerel ek değişikliği', () {
    const ink = [
      InkStroke(page: 0, color: 0xff000000, width: 2, points: [0.1, 0.1]),
    ];
    const old = Attachment(
      id: 'p',
      kind: AttachmentKind.pdf,
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );
    const added = Attachment(
      id: 'new',
      kind: AttachmentKind.image,
      fileName: 'b.png',
      mimeType: 'image/png',
    );

    test('bekleyen değişiklik yoksa gelen liste olduğu gibi', () {
      final incoming = [old.copyWith(ink: ink)];
      expect(
        hydrateAttachments(
          local: const [old, added],
          incoming: incoming,
          localPending: false,
        ),
        same(incoming),
      );
    });

    test('bekleyen değişiklikte yeni ek durur, ağır alan işlenir', () {
      final out = hydrateAttachments(
        local: [old.copyWith(x: 0.5), added],
        incoming: [old.copyWith(ink: ink)],
        localPending: true,
      );
      expect(out.map((a) => a.id), ['p', 'new']);
      expect(out.first.ink, ink);
      expect(out.first.x, 0.5);
    });
  });
}

class _FakeAttachments implements AttachmentRepository {
  _FakeAttachments(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> readBytes(Attachment attachment) async => bytes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 1×1 saydam PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
