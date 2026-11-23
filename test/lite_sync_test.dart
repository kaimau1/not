// LITE EŞİTLEME BEKÇİSİ (PLAN §1.5 katman tablosu, T11, 1.4/1 S4).
//
// Bayraksız (`flutter test`) koşu: kişisel APK / web bugünkü gibi. Play
// koşusu: `flutter test test/lite_sync_test.dart --dart-define=NOTLAR_PLAY=true`.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/core/save_cadence.dart';
import 'package:notlar/core/utils/debouncer.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/drive_store.dart';
import 'package:notlar/features/notes/data/lite_sync.dart';
import 'package:notlar/features/notes/data/local_notes_store.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// Günlük çağrılarını sayan sahte depo (editör testi).
class _LiteRepo extends CountingNotesRepository {
  int journaled = 0;

  @override
  bool get canJournal => true;

  @override
  void journalNote(Note note) => journaled++;
}

void main() {
  tearDown(SaveCadence.reset);

  group('SaveCadence Lite aralığı', () {
    test('varsayılan 5 dk; config/app.liteSaveSec sınırlanır', () {
      expect(SaveCadence.liteInterval, const Duration(minutes: 5));
      SaveCadence.apply({'liteSaveSec': 120});
      expect(SaveCadence.liteInterval, const Duration(minutes: 2));
      SaveCadence.apply({'liteSaveSec': 1});
      expect(SaveCadence.liteInterval, const Duration(seconds: 30));
      SaveCadence.apply({'liteSaveSec': 99999});
      expect(SaveCadence.liteInterval, const Duration(minutes: 15));
      SaveCadence.apply(null);
      expect(SaveCadence.liteInterval, const Duration(minutes: 5));
    });
  });

  group('liteHoldsCloudWrite (saf karar)', () {
    bool hold({
      bool lite = true,
      bool own = true,
      bool shared = false,
      bool device = false,
      bool journal = true,
    }) => liteHoldsCloudWrite(
      lite: lite,
      ownNote: own,
      sharedByMe: shared,
      deviceOnly: device,
      journalReady: journal,
    );

    test('yalnız Lite + kendi + paylaşılmayan + bulutta + günlük hazır', () {
      expect(hold(), isTrue);
      expect(hold(lite: false), isFalse, reason: 'Pro / ömür boyu / kişisel');
      expect(hold(own: false), isFalse, reason: 'başkasının notu');
      expect(hold(shared: true), isFalse, reason: 'paylaşılan anında');
      expect(hold(device: true), isFalse, reason: 'zaten buluta gitmez');
      expect(
        hold(journal: false),
        isFalse,
        reason: 'web: güvencesiz erteleme yok',
      );
    });
  });

  testWidgets('Lite Debouncer: yazarken 5 dk\'da TEK yazım, çıkışta hemen', (
    tester,
  ) async {
    final d = Debouncer()
      ..delay = SaveCadence.liteInterval
      ..maxWait = SaveCadence.liteInterval;
    var writes = 0;
    // 4 dk aralıksız yazım: hiç bulut yazımı yok.
    for (var i = 0; i < 240; i++) {
      d(() => writes++);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(writes, 0);
    // 5. dakikada üst sınır.
    for (var i = 0; i < 60; i++) {
      d(() => writes++);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(writes, 1);
    // Arka plana geçiş: beklemeden.
    d(() => writes++);
    d.flush();
    expect(writes, 2);
  });

  group('kayıt günlüğü (veri kaybı güvencesi)', () {
    late Directory dir;
    late FakeFirebaseFirestore db;
    late LocalNotesStore journal;
    late NotesRepository repo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('lite_journal');
      db = FakeFirebaseFirestore();
      journal = LocalNotesStore.atPath('${dir.path}/j.json');
      repo = NotesRepository(db, 'u1', journal: journal);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    Future<Map<String, dynamic>?> cloud(String id) async =>
        (await db
                .collection(AppConstants.usersCollection)
                .doc('u1')
                .collection(AppConstants.notesCollection)
                .doc(id)
                .get())
            .data();

    test('günlük buluta YAZMAZ; tam not yazımı girdiyi siler', () async {
      final id = await repo.createNote(NoteType.text, title: 'a');
      final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
      repo.journalNote(note.copyWith(body: 'yerel'));
      expect(journal.contains(id), isTrue);
      expect((await cloud(id))!['body'], isNot('yerel'));
      await repo.updateNote(note.copyWith(body: 'bulut'));
      expect(journal.contains(id), isFalse);
      expect((await cloud(id))!['body'], 'bulut');
    });

    test('çöken oturumun artığı açılışta buluta yazılır', () async {
      final id = await repo.createNote(NoteType.text, title: 'a');
      final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
      repo.journalNote(note.copyWith(body: 'çökmeden önce yazılan'));
      expect(await repo.recoverJournal(), 1);
      expect((await cloud(id))!['body'], 'çökmeden önce yazılan');
      expect(journal.contains(id), isFalse);
    });

    test('silinmiş / çöpteki / olmayan nota dokunulmaz', () async {
      final id = await repo.createNote(NoteType.text, title: 'a');
      final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
      repo.journalNote(note.copyWith(body: 'eski'));
      await db
          .collection(AppConstants.usersCollection)
          .doc('u1')
          .collection(AppConstants.notesCollection)
          .doc(id)
          .set({'deletedAt': Timestamp.now()}, SetOptions(merge: true));
      repo.journalNote(
        Note(id: 'yok', type: NoteType.text, title: 'x', body: 'hayalet'),
      );
      expect(await repo.recoverJournal(), 0);
      expect(journal.isEmpty, isTrue);
      expect((await cloud(id))!['body'], isNot('eski'));
      expect(await cloud('yok'), isNull, reason: 'silinen not dirilmez');
    });
  });

  group('editör (Lite)', () {
    final note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'Yazı',
      body: 'gövde',
    );

    // Paylaşım bilgisi yüklenmeden not "paylaşılan" sayılır (bkz.
    // noteSharedByMe) — Lite testleri boş paylaşım listesi verir.
    final lite = [
      liteSyncProvider.overrideWithValue(true),
      myNoteSharesProvider.overrideWith((ref) => Stream.value(const {})),
    ];

    Future<void> type(WidgetTester tester) async {
      final body = find.byType(EditableText).last;
      await tester.tap(body);
      await tester.pump();
      await tester.enterText(body, 'gövde!');
    }

    testWidgets('yazı: 4 dk bulut yok (günlük var), 5. dakikada tek yazım', (
      tester,
    ) async {
      final repo = _LiteRepo();
      await pumpEditor(tester, note, repo: repo, overrides: lite);
      repo.resetCounts();
      await type(tester);
      for (var t = 0; t < 240; t += 5) {
        await tester.pump(const Duration(seconds: 5));
      }
      expect(repo.updateNoteCalls, 0, reason: '4 dk: buluta yazım yok');
      expect(repo.journaled, greaterThan(0), reason: 'günlük (yerel) anında');
      for (var t = 0; t < 70; t += 5) {
        await tester.pump(const Duration(seconds: 5));
      }
      expect(repo.updateNoteCalls, 1, reason: '5 dk: tek yazım');
      expect(repo.lastSaved!.body, 'gövde!');
      await endEditor(tester);
    });

    testWidgets('arka plana geçince bekleyen yazı hemen buluta gider', (
      tester,
    ) async {
      final repo = _LiteRepo();
      await pumpEditor(tester, note, repo: repo, overrides: lite);
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 30));
      expect(repo.updateNoteCalls, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(repo.updateNoteCalls, 1);
      expect(repo.lastSaved!.body, 'gövde!');
      for (final st in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await endEditor(tester);
    });

    testWidgets('editör kapanınca bekleyen yazı kaybolmaz', (tester) async {
      final repo = _LiteRepo();
      await pumpEditor(tester, note, repo: repo, overrides: lite);
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 20));
      expect(repo.updateNoteCalls, 0);
      await endEditor(tester);
      expect(repo.updateNoteCalls, greaterThanOrEqualTo(1));
      expect(repo.lastSaved!.body, 'gövde!');
    });

    testWidgets('bulut simgesine dokunuş = şimdi eşitle', (tester) async {
      final repo = _LiteRepo();
      await pumpEditor(tester, note, repo: repo, overrides: lite);
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.updateNoteCalls, 0);
      await tester.tap(find.byKey(const ValueKey('editor-lite-sync')));
      await tester.pump();
      expect(repo.updateNoteCalls, 1);
      await endEditor(tester);
    });

    testWidgets('paylaşılan klasördeki not anında (2 sn) yazılır', (
      tester,
    ) async {
      final repo = _LiteRepo();
      final shared = note.copyWith(folderId: 'f');
      final c = await pumpEditor(
        tester,
        shared,
        repo: repo,
        overrides: [
          ...lite,
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const [
              NoteFolder(
                id: 'f',
                name: 'Ortak',
                ownerId: 'u',
                sharedWith: ['x'],
              ),
            ]),
          ),
        ],
      );
      c.listen(foldersStreamProvider, (_, _) {});
      await tester.pump();
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.updateNoteCalls, 1);
      expect(repo.journaled, 0, reason: 'paylaşılanda günlük/erteleme yok');
      await endEditor(tester);
    });

    testWidgets('paylaşım bilgisi yüklenmediyse güvenli: anında', (
      tester,
    ) async {
      final repo = _LiteRepo();
      await pumpEditor(
        tester,
        note,
        repo: repo,
        overrides: [
          liteSyncProvider.overrideWithValue(true),
          myNoteSharesProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.updateNoteCalls, 1);
      await endEditor(tester);
    });

    testWidgets('Lite DEĞİL (kişisel / Pro): eski sıklık, simge eski', (
      tester,
    ) async {
      final repo = _LiteRepo();
      await pumpEditor(
        tester,
        note,
        repo: repo,
        overrides: [liteSyncProvider.overrideWithValue(false)],
      );
      repo.resetCounts();
      await type(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.updateNoteCalls, 1);
      expect(repo.journaled, 0);
      expect(find.byKey(const ValueKey('editor-lite-sync')), findsNothing);
      await endEditor(tester);
    });
  });

  group('kapı', () {
    test('liteSyncProvider: kişisel derlemede hep false', () {
      if (PlayBuild.enabled) return;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(liteSyncProvider), isFalse);
    });

    test('Play: ücretsiz Lite; ömür boyu ve Pro anında', () async {
      if (!PlayBuild.enabled) return;
      Future<ProviderContainer> with_(Entitlement e) async {
        final c = ProviderContainer(
          overrides: [
            entitlementProvider.overrideWith((ref) => Stream.value(e)),
          ],
        );
        addTearDown(c.dispose);
        c.listen(entitlementProvider, (_, _) {});
        await c.read(entitlementProvider.future);
        return c;
      }

      final free = await with_(Entitlement.none);
      expect(free.read(liteSyncProvider), isTrue);
      final life = await with_(Entitlement.fromMap({'tier': 'lifetime'}));
      expect(life.read(liteSyncProvider), isFalse);
      final pro = await with_(
        Entitlement.fromMap({
          'tier': 'pro',
          'proUntil': DateTime.now().add(const Duration(days: 3)),
        }),
      );
      expect(pro.read(liteSyncProvider), isFalse);
    });
  });

  group('ek deposu seçimi (cloudAttachments)', () {
    AttachmentSyncMode mode({required bool google, bool cloud = false}) =>
        attachmentSyncModeFor(
          web: false,
          googleUser: google,
          cloudAttachments: cloud,
        );

    test('hak yok (Lite): Google → Drive, misafir → yalnız cihaz', () {
      expect(mode(google: true), AttachmentSyncMode.drive);
      expect(mode(google: false), AttachmentSyncMode.textOnly);
    });

    test('hak var (Pro): bizim bulut (Storage)', () {
      expect(mode(google: true, cloud: true), AttachmentSyncMode.storage);
      expect(mode(google: false, cloud: true), AttachmentSyncMode.storage);
    });

    test('kişisel derleme: kapı açık görünse de Storage SEÇİLMEZ', () {
      if (PlayBuild.enabled) return;
      expect(EntitlementGate.active, isFalse);
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(c.dispose);
      c.listen(authStateProvider, (_, _) {});
      // Hak kapısı (bayraksız) açık; yine de Drive/yalnız-metin yolu sürer.
      expect(c.read(proFeatureProvider(ProFeature.cloudAttachments)), isTrue);
      expect(
        c.read(attachmentSyncModeProvider),
        isNot(AttachmentSyncMode.storage),
      );
    });
  });
}
