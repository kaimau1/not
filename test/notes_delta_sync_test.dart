import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_delta_sync.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **S1 "yalnız değişeni dinle"** (P67, 2026-11-17).
///
/// SINIR: sahte Firestore önbellek/sunucu ayrımı yapmaz (`ListenSource`
/// yok sayılır). Okuma hesabında cihaz önbelleği AYRI bir sahte veritabanıyla
/// taklit edilir; önbelleğin besleyiciden dolması ve bekleyen yazımın
/// önbellek dinleyicisinde görünmesi cihazda doğrulanmalı ("cihaz
/// bekliyor"). Buradaki testler yol seçimini, imleci, geri dönüşleri ve
/// okunan belge sayısını doğrular.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    NotesRepository.lastFeed = null;
  });

  CollectionReference<Map<String, dynamic>> notesOf(
    FakeFirebaseFirestore d,
    String uid,
  ) => d.collection('users').doc(uid).collection('notes');

  /// [n] not, damgası [at] (eski oturumda görülmüş hâl).
  Future<void> seed(
    FakeFirebaseFirestore d,
    String uid,
    int n, {
    DateTime? at,
    bool stamp = true,
  }) async {
    final ts = Timestamp.fromDate(
      at ?? DateTime.now().subtract(const Duration(days: 3)),
    );
    for (var i = 0; i < n; i++) {
      await notesOf(d, uid).doc('n$i').set({
        'type': 'text',
        'title': 'not $i',
        'body': '',
        'deletedAt': null,
        'orderIndex': i.toDouble(),
        // Gerçekçi dağılım: her not bir saat önce düzenlenmiş.
        'updatedAt': ts.minus(i),
        if (stamp) kSyncAtField: ts.minus(i),
      });
    }
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('bayrak', () {
    test('varsayılan AÇIK; yalnız uzak false kapatır; yerel geri alma', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(SyncDeltaFlag.enabled(prefs), isTrue);
      await SyncDeltaFlag.remember({'minClient': 3}, prefs);
      expect(SyncDeltaFlag.enabled(prefs), isTrue);
      await SyncDeltaFlag.remember({'syncDeltaListen': 'false'}, prefs);
      expect(SyncDeltaFlag.enabled(prefs), isTrue, reason: 'yalnız bool');
      // Konsoldan kapatma: false bir sonraki açılışta eski yol.
      await SyncDeltaFlag.remember({'syncDeltaListen': false}, prefs);
      expect(SyncDeltaFlag.enabled(prefs), isFalse);
      await SyncDeltaFlag.remember({'syncDeltaListen': true}, prefs);
      expect(SyncDeltaFlag.enabled(prefs), isTrue);
      await prefs.setBool(SyncDeltaFlag.offKey, true);
      expect(SyncDeltaFlag.enabled(prefs), isFalse, reason: 'yerel geri al');
      await prefs.remove(SyncDeltaFlag.offKey);
      await SyncDeltaFlag.remember({'syncDeltaListen': false}, prefs);
      await SyncDeltaFlag.remember(null, prefs);
      expect(SyncDeltaFlag.enabled(prefs), isTrue);
    });

    test('bayrak kapalıyken akış bugünkü yol (S1 akışı kurulmaz)', () async {
      await seed(db, 'u1', 3);
      final repo = NotesRepository(db, 'u1');
      final notes = await repo.watchNotes().first;
      expect(notes, hasLength(3));
      expect(NotesRepository.lastFeed, isNull);
    });
  });

  group('okuma maliyeti (soğuk açılış, 300 not)', () {
    for (final changed in [0, 5, 50]) {
      test('$changed değişiklik', () async {
        // Cihaz önbelleği = son oturumdaki hâl; sunucu = o hâl + değişiklikler.
        final cacheDb = FakeFirebaseFirestore();
        await seed(cacheDb, 'u1', 300);
        await seed(db, 'u1', 300);
        final serverRepo = NotesRepository(db, 'u1');
        for (var i = 0; i < changed; i++) {
          serverRepo.updateFields('n$i', {'title': 'değişti $i'});
        }
        await settle();

        // ÖNCE: bugünkü yol — dinleyici 30 dk'dan uzun kopuksa sonuçtaki
        // HER belge okunmuş sayılır.
        final before = (await notesOf(
          db,
          'u1',
        ).where('deletedAt', isNull: true).get()).docs.length;

        // SONRA: S1.
        final feed = NotesDeltaFeed(
          notesOf(db, 'u1'),
          cacheNotes: notesOf(cacheDb, 'u1'),
        );
        final sub = feed.events().listen((_) {});
        await settle();
        await sub.cancel();
        final after = feed.stats;
        // ignore: avoid_print
        print(
          'S1 okuma: $changed değişiklik → önce $before, sonra '
          '${after.totalReads} ($after)',
        );
        expect(after.mode, NotesFeedMode.delta);
        expect(before, 300);
        // Değişenler + imlecin 10 dk örtüşmesindeki not (en son görülen).
        expect(after.docReads, inInclusiveRange(changed, changed + 1));
        expect(after.countReads, 1);
        expect(after.totalReads, lessThanOrEqualTo(changed + 2));
      });
    }
  });

  group('yol seçimi ve geri dönüşler', () {
    Future<NotesDeltaFeed> open(
      String uid, {
      DateTime Function()? now,
      ServerCount? count,
    }) async {
      final feed = NotesDeltaFeed(
        notesOf(db, uid),
        now: now,
        serverCount: count,
      );
      final sub = feed.events().listen((_) {});
      addTearDown(sub.cancel);
      await settle();
      return feed;
    }

    test(
      'ilk açılış (önbellek boş) → eski yol; sonra yazılan görünür',
      () async {
        final repo = NotesRepository(db, 'u1');
        final feed = NotesDeltaFeed(notesOf(db, 'u1'));
        final lists = <List<Note>>[];
        final sub = repo.watchNotes(feed: feed).listen(lists.add);
        await settle();
        expect(feed.stats.mode, NotesFeedMode.legacy);
        expect(feed.stats.reason, 'önbellek boş');
        await repo.createNote(NoteType.text, title: 'yeni');
        await settle();
        expect(lists.last.map((n) => n.title), ['yeni']);
        await sub.cancel();
      },
    );

    test('damgasız eski veri → eski yol', () async {
      await seed(db, 'u1', 4, stamp: false);
      final feed = await open('u1');
      expect(feed.stats.mode, NotesFeedMode.legacy);
      expect(feed.stats.reason, 'damgalı belge yok');
    });

    test('imleç 30 günden eski (31 gün kapalı cihaz) → eski yol', () async {
      await seed(
        db,
        'u1',
        4,
        at: DateTime.now().subtract(const Duration(days: 31)),
      );
      final feed = await open('u1');
      expect(feed.stats.mode, NotesFeedMode.legacy);
    });

    test(
      'saat kayması: imleç sunucu damgası, cihaz saati sorguyu değiştirmez',
      () async {
        await seed(db, 'u1', 10);
        final normal = await open('u1');
        // Cihaz 5 gün geride: yine S1, aynı belgeler okunur.
        final behind = await open(
          'u1',
          now: () => DateTime.now().subtract(const Duration(days: 5)),
        );
        expect(behind.stats.mode, NotesFeedMode.delta);
        expect(behind.stats.docReads, normal.stats.docReads);
        // Cihaz 40 gün ileride: güvenli taraf, eski yol (tam okuma).
        final ahead = await open(
          'u1',
          now: () => DateTime.now().add(const Duration(days: 40)),
        );
        expect(ahead.stats.mode, NotesFeedMode.legacy);
      },
    );

    test('sayım tutmazsa (başka cihazda kalıcı silme/önbellekten atılma) '
        '→ eski yol, liste sıfırdan', () async {
      await seed(db, 'u1', 5);
      final repo = NotesRepository(db, 'u1');
      final feed = NotesDeltaFeed(
        notesOf(db, 'u1'),
        serverCount: (_) async => 4,
      );
      final events = <NotesFeedEvent>[];
      final sub = feed.events().listen(events.add);
      await settle();
      expect(feed.stats.mode, NotesFeedMode.legacy);
      expect(feed.stats.reason, startsWith('sayım tutmadı'));
      expect(
        events.where((e) => e.reset),
        hasLength(2),
        reason: 'önbellek görüntüsü + eski yolun ilk görüntüsü',
      );
      await sub.cancel();
      // Depo akışında liste tam.
      final notes = await repo
          .watchNotes(
            feed: NotesDeltaFeed(
              notesOf(db, 'u1'),
              serverCount: (_) async => 4,
            ),
          )
          .first;
      expect(notes, hasLength(5));
    });

    test('çevrimdışı (sayım alınamaz) → eski yol (bugünkü maliyet)', () async {
      await seed(db, 'u1', 5);
      final feed = await open(
        'u1',
        count: (_) async => throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        ),
      );
      expect(feed.stats.mode, NotesFeedMode.legacy);
      expect(feed.stats.reason, 'sayım alınamadı');
    });

    test('sayım tutarsa S1 sürer', () async {
      await seed(db, 'u1', 5);
      final feed = await open('u1');
      expect(feed.stats.mode, NotesFeedMode.delta);
      expect(feed.stats.countReads, 1);
    });

    test('önbellek listen() senkron fırlatırsa eski yola döner ve notları verir', () async {
      await seed(db, 'u1', 3);
      final repo = NotesRepository(db, 'u1');
      final feed = NotesDeltaFeed(
        notesOf(db, 'u1'),
        cacheNotes: _ThrowingCacheCollection(),
      );
      final emitted = <List<Note>>[];
      final sub = repo.watchNotes(feed: feed).listen(emitted.add);
      await settle();
      expect(feed.stats.mode, NotesFeedMode.legacy);
      expect(feed.stats.reason, startsWith('önbellek dinleyicisi hata:'));
      expect(emitted, isNotEmpty);
      expect(emitted.last, hasLength(3));
      await sub.cancel();
    });
  });

  group('iki cihaz (aynı hesap)', () {
    test(
      'öbür cihazda düzenleme, çöpe atma, geri yükleme listeye yansır',
      () async {
        await seed(db, 'u1', 3);
        final phone = NotesRepository(db, 'u1');
        final tablet = NotesRepository(db, 'u1');
        final lists = <List<Note>>[];
        final sub = phone.watchNotes(delta: true).listen(lists.add);
        await settle();
        expect(NotesRepository.lastFeed!.stats.mode, NotesFeedMode.delta);
        expect(lists.last, hasLength(3));

        tablet.updateFields('n1', {'title': 'tabletten'});
        await settle();
        expect(lists.last.firstWhere((n) => n.id == 'n1').title, 'tabletten');

        tablet.softDelete('n2');
        await settle();
        expect(lists.last.map((n) => n.id), isNot(contains('n2')));
        // Çöpe atma damgayı tazeler → besleyiciye girer.
        final trashed = (await notesOf(db, 'u1').doc('n2').get()).data()!;
        expect(
          (trashed[kSyncAtField] as Timestamp).toDate().year,
          DateTime.now().year,
        );

        tablet.restore('n2');
        await settle();
        expect(lists.last.map((n) => n.id), contains('n2'));
        await sub.cancel();
      },
    );

    test('bu cihazın yazımı (çevrimdışı kuyruk dahil) listede anında; '
        'bekleyen damga imlece sayılmaz', () async {
      await seed(db, 'u1', 2);
      final phone = NotesRepository(db, 'u1');
      final lists = <List<Note>>[];
      final sub = phone.watchNotes(delta: true).listen(lists.add);
      await settle();
      final id = await phone.createNote(NoteType.text, title: 'çevrimdışı');
      await settle();
      expect(lists.last.map((n) => n.id), contains(id));
      await sub.cancel();

      // Bekleyen yazımda damga null gelir (serverTimestampBehavior.none):
      // imleç yalnız sunucuya ulaşmış damgalardan.
      final snap = await notesOf(db, 'u1').get();
      final pending = <String, dynamic>{kSyncAtField: null};
      final docs = [for (final d in snap.docs) d.data(), pending, null];
      final cursor = NotesDeltaFeed.cursorOf(docs);
      expect(cursor, isNotNull);
      expect(
        cursor,
        NotesDeltaFeed.cursorOf([for (final d in snap.docs) d.data()]),
      );
      expect(NotesDeltaFeed.cursorOf([pending]), isNull);
    });
  });

  test('hesap değişimi: imleç ve önbellek hesaba özel', () async {
    await seed(db, 'a', 5);
    final a = NotesRepository(db, 'a');
    final b = NotesRepository(db, 'b');
    final aNotes = await a.watchNotes(delta: true).first;
    expect(NotesRepository.lastFeed!.stats.mode, NotesFeedMode.delta);
    final bFeed = NotesDeltaFeed(notesOf(db, 'b'));
    final bLists = <List<Note>>[];
    final sub = b.watchNotes(feed: bFeed).listen(bLists.add);
    await settle();
    expect(aNotes, hasLength(5));
    expect(bFeed.stats.mode, NotesFeedMode.legacy, reason: 'B önbelleği boş');
    expect(bLists.every((l) => l.isEmpty), isTrue, reason: 'A sızmaz');
    await sub.cancel();
  });
}

extension on Timestamp {
  Timestamp minus(int hours) =>
      Timestamp.fromDate(toDate().subtract(Duration(hours: hours)));
}

// ignore: subtype_of_sealed_class
class _ThrowingCacheCollection implements CollectionReference<Map<String, dynamic>> {
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) => _ThrowingCacheQuery();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _ThrowingCacheQuery implements Query<Map<String, dynamic>> {
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => _ThrowingListenStream();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingListenStream
    extends Stream<QuerySnapshot<Map<String, dynamic>>> {
  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listen(
    void Function(QuerySnapshot<Map<String, dynamic>> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw StateError('wasm cache boom');
  }
}
