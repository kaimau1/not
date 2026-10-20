import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/core/utils/local_file.dart';
import 'package:notlar/features/ai/data/attachment_text_index.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/local_notes_store.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/data/prefs_sync.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 6 (PERFORMANS_TOPARLAMA_PLANI.md): kayıt yolu, arka plan işleri,
/// sorgular.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  Future<Note> noteNow(String id) async =>
      (await repo.watchNote(id).firstWhere((n) => n != null))!;

  Attachment pdfWith(List<double> points) => Attachment(
    id: 'a1',
    kind: AttachmentKind.pdf,
    fileName: 'x.pdf',
    mimeType: 'application/pdf',
    ink: [InkStroke(page: 1, color: 0xFF000000, width: 2, points: points)],
  );

  group('F6.1 kayıt yolu', () {
    test('yerinde büyüyen çizgi "değişmedi" sanılmaz', () async {
      final id = await repo.createNote(NoteType.text);
      final note = await noteNow(id);
      final points = <double>[0.1, 0.1];
      final withInk = note.copyWith(attachments: [pdfWith(points)]);
      await repo.updateNote(withInk);
      // Etkin çizgi (InkController) noktaları YERİNDE ekler.
      points.addAll([0.2, 0.2]);
      await repo.updateNote(withInk.copyWith(body: 'x'));
      final atts =
          (await db.doc('users/u1/notes/$id').get()).data()!['attachments']
              as List;
      final ink = ((atts.single as Map)['ink'] as List).single as Map;
      expect((ink['d'] as List).length, 4);
    });

    test('ölçüm: 300 çizgi × 200 nokta, değişmeyen eklerle kayıt', () async {
      final id = await repo.createNote(NoteType.text);
      final note = await noteNow(id);
      final heavy = note.copyWith(
        attachments: [
          Attachment(
            id: 'a1',
            kind: AttachmentKind.pdf,
            fileName: 'x.pdf',
            mimeType: 'application/pdf',
            ink: [
              for (var s = 0; s < 300; s++)
                InkStroke(
                  page: 1,
                  color: 0xFF000000,
                  width: 2,
                  points: [for (var i = 0; i < 400; i++) (i + s) / 1000],
                ),
            ],
          ),
        ],
      );
      await repo.updateNote(heavy);
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        await repo.updateNote(heavy.copyWith(body: 'yazı $i'));
      }
      // Eşik yok (makineye bağlı); yalnız çıktıya yazılır.
      // ignore: avoid_print
      print(
        'F6.1 updateNote (değişmeyen ağır ek): '
        '${sw.elapsedMilliseconds / 10} ms/kayıt',
      );
      final main = await db.doc('users/u1/notes/$id').get();
      expect(main.data()!['body'], 'yazı 9');
      expect(main.data()!['heavyRef'], isTrue);
    });

    test('utf8Length utf8.encode ile aynı', () {
      for (final s in ['', 'abc', 'ığüşöç İ', '🙂 emoji', 'a\uD800b']) {
        expect(utf8Length(s), utf8.encode(s).length, reason: s);
      }
    });
  });

  group('F6.2 editör kapanınca depo kayıtları bırakılır', () {
    test('yeniden açılış 30 dk aralığını delmez, taban yeni hâl', () async {
      final id = await repo.createNote(NoteType.text, body: 'dün');
      final opened = await noteNow(id);
      repo.rememberVersionBase(opened);
      await repo.updateNote(opened.copyWith(body: 'bugün'));
      repo.releaseNote(id);
      final reopened = opened.copyWith(body: 'bugün');
      repo.rememberVersionBase(reopened);
      await repo.updateNote(reopened.copyWith(body: 'yarın'));
      await Future<void>.delayed(Duration.zero);
      final versions = await repo.listVersions(id);
      expect(versions.map((v) => v.body), ['dün']);
      // Kendi yankısı yine tanınır (özetle).
      expect(repo.isOwnEcho(reopened.copyWith(body: 'yarın')), isTrue);
      expect(repo.isOwnEcho(reopened.copyWith(body: 'başka')), isFalse);
    });
  });

  group('F6.3 ek metni indeksi', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('att_text');
      AttachmentTextIndex.overrideDir = dir.path;
    });
    tearDown(() {
      AttachmentTextIndex.overrideDir = null;
      dir.deleteSync(recursive: true);
    });

    test(
      'eski SharedPreferences önbelleği dosyaya taşınır, katlanmış kopya',
      () async {
        SharedPreferences.setMockInitialValues({
          'attachment_search': true,
          AttachmentTextIndex.legacyCacheKey: jsonEncode({
            'a1': 'Işık FATURASI',
            'silinmiş': 'eski',
          }),
        });
        final prefs = await SharedPreferences.getInstance();
        const note = Note(
          id: 'n1',
          type: NoteType.text,
          attachments: [
            Attachment(
              id: 'a1',
              kind: AttachmentKind.image,
              fileName: 'f.png',
              mimeType: 'image/png',
            ),
          ],
        );
        final c = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('u1'),
            notesStreamProvider.overrideWith(
              (ref) => Stream.value(const [note]),
            ),
          ],
        );
        addTearDown(c.dispose);
        c.listen(attachmentFoldedTextProvider, (_, _) {});
        final file = File('${dir.path}/attachment_text_u1.json');
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          if (prefs.getString(AttachmentTextIndex.legacyCacheKey) == null &&
              file.existsSync() &&
              !file.readAsStringSync().contains('silinmiş')) {
            break;
          }
        }
        expect(c.read(attachmentTextProvider), {'n1': 'Işık FATURASI\n'});
        expect(c.read(attachmentFoldedTextProvider)['n1'], contains('isik'));
        expect(prefs.getString(AttachmentTextIndex.legacyCacheKey), isNull);
        expect(file.existsSync(), isTrue);
        // Silinen ekin metni budandı.
        expect(jsonDecode(file.readAsStringSync()), {'a1': 'Işık FATURASI'});
      },
    );
  });

  group('F6.4 ayar senkronu', () {
    test('aynı anlık görüntü (sıra farklı) yeniden yazılmaz', () {
      final plan = planPrefsSync(
        local: {'a': 1, 'b': 'x'},
        snapshot: {'b': 'x', 'a': 1},
        remote: {'a': 1, 'b': 'x'},
      );
      expect(plan.apply, isEmpty);
      expect(plan.push, isEmpty);
      expect(plan.remove, isEmpty);
      expect(prefsSnapshotUnchanged({'b': 'x', 'a': 1}, plan.snapshot), isTrue);
      expect(prefsSnapshotUnchanged(null, plan.snapshot), isFalse);
      expect(
        prefsSnapshotUnchanged({'a': 2, 'b': 'x'}, plan.snapshot),
        isFalse,
      );
    });
  });

  group('F6.5 yerel depo', () {
    test('note(id) ayrıştırma önbelleğinden; flush izolede yazar', () async {
      final dir = Directory.systemTemp.createTempSync('local_store');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/s.json';
      final store = LocalNotesStore.atPath(path);
      store.put('n1', const Note(id: 'n1', type: NoteType.text).toMap());
      expect(identical(store.note('n1'), store.note('n1')), isTrue);
      store.merge('n1', {'body': 'gövde'});
      await Future.wait([store.flush(), store.flush()]);
      expect(LocalNotesStore.atPath(path).note('n1')!.body, 'gövde');
    });
  });

  group('F6.6 büyük AI gövdesi', () {
    test('kaba boy eşiği ve bayt kodlaması', () {
      final small = {'a': 'x' * 10};
      final big = {
        'contents': [
          {'data': 'y' * (kIsolateBodyBytes + 1)},
        ],
      };
      expect(roughJsonSize(small) < kIsolateBodyBytes, isTrue);
      expect(roughJsonSize(big) > kIsolateBodyBytes, isTrue);
      expect(decodeJsonBytes(encodeJsonBytes({'ı': 'ş'})), {'ı': 'ş'});
    });
  });

  group('F6.7 dar sorgular', () {
    test('çöp yalnız silinmişleri, klasör artımlı ayrıştırır', () async {
      final a = await repo.createNote(NoteType.text, body: 'a');
      final b = await repo.createNote(NoteType.text, body: 'b');
      await db.doc('users/u1/notes/$a').update({'folderId': 'f1'});
      await db.doc('users/u1/notes/$b').update({
        'folderId': 'f1',
        'deletedAt': Timestamp.now(),
      });
      final trash = await repo.watchTrash().first;
      expect(trash.map((n) => n.id), [b]);
      final stream = repo.watchFolderNotes('f1');
      final seen = <List<String>>[];
      final sub = stream.listen((l) => seen.add([for (final n in l) n.body]));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await db.doc('users/u1/notes/$a').update({'body': 'a2'});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(seen.first, ['a']);
      expect(seen.last, ['a2']);
    });
  });

  group('F6.9 olmayan dosya kısa süre önbellekte', () {
    test('yazan yol kaydı düşürünce hemen görünür', () {
      final dir = Directory.systemTemp.createTempSync('exists');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/a.png';
      expect(localFileExists(path), isFalse);
      File(path).writeAsBytesSync([1]);
      // Negatif kayıt hâlâ taze: sistem çağrısı yapılmaz.
      expect(localFileExists(path), isFalse);
      forgetLocalFile(path);
      expect(localFileExists(path), isTrue);
      final other = '${dir.path}/b.png';
      expect(localFileExists(other), isFalse);
      File(other).writeAsBytesSync([1]);
      forgetMissingLocalFiles();
      expect(localFileExists(other), isTrue);
    });
  });
}
