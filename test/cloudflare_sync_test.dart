import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/core/sync/cloudflare_config.dart';
import 'package:notlar/core/sync/cloudflare_sync_transport.dart';
import 'package:notlar/core/sync/sync_models.dart';
import 'package:notlar/core/sync/sync_outbox.dart';
import 'package:notlar/core/sync/sync_transport.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bellek içi sahte Cloudflare `/v1/sync` sunucusu — gerçek iyimser
/// eşzamanlılık (`baseVersion == version`) ve monotonik `seq` uygular.
class _InMemoryWorkerTransport implements SyncTransport {
  int _seq = 0;
  final Map<String, SyncEntityRecord> _entities = {};
  final Map<String, Uint8List> _media = {};
  SyncCadencePolicy policy = const SyncCadencePolicy(
    isLite: false,
    debounceMs: 2500,
    intervalSec: 30,
    liveShoppingWs: true,
  );
  RemoteEntitlement remoteEntitlement = const RemoteEntitlement(
    entitlement: Entitlement(
      tier: EntitlementTier.lifetime,
      lifetimeOwned: true,
    ),
    remainingCalls: 750,
    remainingTokens: 600000,
  );
  int decideCalls = 0;
  int searchCalls = 0;
  int verifyCalls = 0;

  @override
  Future<SyncPushPullResponse> pushPull(SyncPushPullRequest request) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final applied = <SyncAppliedResult>[];
    final conflicts = <SyncConflict>[];

    for (final c in request.changes) {
      final key = c.compositeKey;
      final existing = _entities[key];
      if (existing == null) {
        final nextSeq = ++_seq;
        final rec = SyncEntityRecord(
          kind: c.kind,
          id: c.id,
          seq: nextSeq,
          version: 1,
          updatedAtMs: now,
          deletedAtMs: c.deleted ? now : null,
          encrypted: c.encrypted,
          payload: c.payload,
        );
        _entities[key] = rec;
        applied.add(
          SyncAppliedResult(
            kind: c.kind,
            id: c.id,
            version: 1,
            seq: nextSeq,
            updatedAtMs: now,
            deletedAtMs: rec.deletedAtMs,
          ),
        );
      } else if (c.baseVersion != existing.version) {
        conflicts.add(
          SyncConflict(
            kind: c.kind,
            id: c.id,
            clientBaseVersion: c.baseVersion,
            serverVersion: existing.version,
            serverSeq: existing.seq,
            serverUpdatedAtMs: existing.updatedAtMs,
            serverDeletedAtMs: existing.deletedAtMs,
            serverEncrypted: existing.encrypted,
            serverPayload: existing.payload,
          ),
        );
      } else {
        final nextSeq = ++_seq;
        final nextVer = existing.version + 1;
        final rec = SyncEntityRecord(
          kind: c.kind,
          id: c.id,
          seq: nextSeq,
          version: nextVer,
          updatedAtMs: now,
          deletedAtMs: c.deleted ? now : null,
          encrypted: c.encrypted,
          payload: c.payload,
        );
        _entities[key] = rec;
        applied.add(
          SyncAppliedResult(
            kind: c.kind,
            id: c.id,
            version: nextVer,
            seq: nextSeq,
            updatedAtMs: now,
            deletedAtMs: rec.deletedAtMs,
          ),
        );
      }
    }

    final pulled =
        _entities.values.where((e) => e.seq > request.cursorSeq).toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    final maxSeq = pulled.isEmpty ? request.cursorSeq : pulled.last.seq;

    return SyncPushPullResponse(
      cursorSeq: maxSeq,
      sharedCursorMs: request.sharedCursorMs,
      serverTimeMs: now,
      hasMore: false,
      applied: applied,
      conflicts: conflicts,
      entities: pulled,
      sharedEntities: const [],
      policy: policy,
    );
  }

  @override
  Future<RemoteEntitlement> fetchEntitlement() async => remoteEntitlement;

  @override
  Future<RemoteEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    verifyCalls++;
    return remoteEntitlement;
  }

  @override
  Future<Map<String, dynamic>?> decide(
    Map<String, Object?> body, {
    Duration? timeout,
  }) async {
    decideCalls++;
    return {
      'response': {
        'answers': {
          'aisle': {'value': 'sut'},
        },
      },
      'remaining': {'monthly': 0, 'once': 749, 'pack': 0},
      'remainingTokens': {'monthly': 0, 'once': 599700, 'pack': 0},
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    searchCalls++;
    return [
      {'uid': 'u-ayse', 'name': 'Ayşe Yılmaz', 'email': 'ayse@example.com'},
    ];
  }

  @override
  Future<void> upsertUserDirectory({
    required String name,
    required String email,
    required bool discoverable,
  }) async {}

  @override
  Future<void> upsertShare({
    required String entityKind,
    required String entityId,
    required String memberUid,
    String role = 'both',
    String status = 'active',
  }) async {}

  @override
  Future<MediaUploadResult> uploadMedia({
    required String key,
    required Uint8List bytes,
    required String contentType,
    String? noteId,
  }) async {
    _media[key] = bytes;
    return MediaUploadResult(
      key: key,
      sizeBytes: bytes.length,
      bytesUsed: bytes.length,
      quotaBytes: 262144000,
    );
  }

  @override
  Future<Uint8List> downloadMedia(String key) async =>
      _media[key] ?? Uint8List(0);

  @override
  Future<void> deleteMedia(String key) async {
    _media.remove(key);
  }
}

void main() {
  tearDown(() {
    CloudflareConfig.debugApiBaseOverride = null;
  });

  group('CloudflareConfig ve PlayBuild izolasyonu', () {
    test('varsayılan (kişisel APK) boş → Firestore yolu bozulmaz', () {
      expect(CloudflareConfig.enabled, isFalse);
      expect(PlayBuild.cloudflareSync, isFalse);
    });

    test('CLOUDFLARE_API_BASE verilince normalize edilip etkinleşir', () {
      CloudflareConfig.debugApiBaseOverride = 'https://sync.notlar.app/';
      expect(CloudflareConfig.enabled, isTrue);
      expect(PlayBuild.cloudflareSync, isTrue);
      expect(CloudflareConfig.apiBase, 'https://sync.notlar.app');
      expect(
        CloudflareConfig.endpoint('/v1/sync'),
        'https://sync.notlar.app/v1/sync',
      );
    });
  });

  group('2 cihazlı (Android + Web) çevrimdışı / çakışma / 3-yönlü birleştirme / geri yükleme', () {
    test('Android ve Web çevrimdışı düzenler → çakışma 3-yönlü birleşir, veri kaybı = 0', () async {
      final server = _InMemoryWorkerTransport();

      // İki ayrı cihazın ayrı SharedPreferences depoları (Android ve Web)
      SharedPreferences.setMockInitialValues({});
      final prefsAndroid = await SharedPreferences.getInstance();
      final outboxAndroid = SyncOutbox(prefsAndroid, uid: 'u1_android');
      final localAndroid = <String, Map<String, dynamic>>{};

      final engineAndroid = SyncEngine(
        transport: server,
        outbox: outboxAndroid,
        onRemoteEntities: (list) {
          for (final e in list) {
            if (e.payload is Map) {
              localAndroid[e.id] = Map<String, dynamic>.from(e.payload as Map);
            }
          }
        },
      );

      // 1. Android ilk metin notunu ve alışveriş listesini oluşturup eşitler.
      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: {'title': 'Toplantı', 'body': 'Satır 1\nSatır 2\nSatır 3'},
      );
      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 's1',
        payload: {
          'title': 'Market',
          'items': [
            const NoteItem(id: 'i1', text: 'Süt').toMap(),
            const NoteItem(id: 'i2', text: 'Ekmek').toMap(),
          ],
        },
      );
      final initSummary = await engineAndroid.syncNow();
      expect(initSummary.pushedCount, 2);
      expect(initSummary.cursorSeq, 2);
      expect(outboxAndroid.hasPending, isFalse);

      // 2. Web cihazı ilk kez açılır ve 2 kaydı çeker.
      final outboxWeb = SyncOutbox(prefsAndroid, uid: 'u1_web');
      final localWeb = <String, Map<String, dynamic>>{};
      final engineWeb = SyncEngine(
        transport: server,
        outbox: outboxWeb,
        onRemoteEntities: (list) {
          for (final e in list) {
            if (e.payload is Map) {
              localWeb[e.id] = Map<String, dynamic>.from(e.payload as Map);
            }
          }
        },
      );
      final webPull1 = await engineWeb.syncNow();
      expect(webPull1.pulledCount, 2);
      expect(webPull1.cursorSeq, 2);

      // 30 dakika sonra değişiklik yokken yeniden açılış → 0 kayıt okunur!
      final idleReopen = await engineWeb.syncNow();
      expect(idleReopen.pulledCount, 0);
      expect(idleReopen.cursorSeq, 2);

      // 3. İKİ CİHAZ ÇEVRİMDIŞI AYNI NOTLARI DÜZENLER:
      // Android üst satırı değiştirir, Süt'ü tikler ve Domates ekler.
      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: {
          'title': 'Toplantı',
          'body': 'Satır 1 (Android)\nSatır 2\nSatır 3',
        },
      );
      // Aynı nota ikinci bir düzenleme → Outbox tek girdide birleştirir (baseVersion=1 korunur)!
      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: {
          'title': 'Toplantı',
          'body': 'Satır 1 (Android v2)\nSatır 2\nSatır 3',
        },
      );
      expect(outboxAndroid.pendingCount, 1);

      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 's1',
        payload: {
          'title': 'Market',
          'items': [
            const NoteItem(id: 'i1', text: 'Süt', checked: true).toMap(),
            const NoteItem(id: 'i2', text: 'Ekmek').toMap(),
            const NoteItem(id: 'i3', text: 'Domates').toMap(),
          ],
        },
      );

      // Web alt satırı değiştirir ve Peynir ekler (baseVersion hâlâ 1!).
      await outboxWeb.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: {
          'title': 'Toplantı',
          'body': 'Satır 1\nSatır 2\nSatır 3 (Web)',
        },
      );
      await outboxWeb.enqueue(
        kind: SyncEntityKind.note,
        id: 's1',
        payload: {
          'title': 'Market',
          'items': [
            const NoteItem(id: 'i1', text: 'Süt').toMap(),
            const NoteItem(id: 'i2', text: 'Ekmek').toMap(),
            const NoteItem(id: 'i4', text: 'Peynir').toMap(),
          ],
        },
      );

      // 4. Android önce bağlanıp yazar (version 2).
      final pushA = await engineAndroid.syncNow();
      expect(pushA.pushedCount, 2);
      expect(pushA.conflictsResolved, 0);

      // 5. Web bağlanır → sunucu conflicts[] döner → SyncEngine 3-yönlü birleştirir ve version 3 yazar!
      final pushWeb = await engineWeb.syncNow();
      expect(pushWeb.conflictsResolved, 2);
      expect(pushWeb.pushedCount, 2);
      expect(outboxWeb.hasPending, isFalse);

      // 6. Android son deltayı çeker → iki cihaz da SIFIR VERİ KAYBIYLA birleşmiş hâlde!
      await engineAndroid.syncNow();
      expect(
        localAndroid['n1']?['body'],
        'Satır 1 (Android v2)\nSatır 2\nSatır 3 (Web)',
      );
      final mergedItems = [
        for (final m in localAndroid['s1']!['items'] as List)
          NoteItem.fromMap(Map<String, dynamic>.from(m as Map)),
      ];
      expect(mergedItems.map((i) => i.text).toSet(), {
        'Süt',
        'Ekmek',
        'Domates',
        'Peynir',
      });
      expect(mergedItems.firstWhere((i) => i.id == 'i1').checked, isTrue);

      // 7. Soft delete + geri yükleme (restore) akışı.
      await outboxAndroid.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: localAndroid['n1'],
        deleted: true,
      );
      await engineAndroid.syncNow();
      final delPull = await engineWeb.syncNow();
      expect(delPull.pulledCount, 1);

      await outboxWeb.enqueue(
        kind: SyncEntityKind.note,
        id: 'n1',
        payload: localAndroid['n1'],
      );
      final restoreRes = await engineWeb.syncNow();
      expect(restoreRes.pushedCount, 1);
      expect(outboxWeb.versionOf(SyncEntityKind.note, 'n1'), 5);
    });
  });

  group('WebLiteJournal + NotesRepository Web toplu yazım düzeltmesi', () {
    test('WebLiteJournal SharedPreferences üstünde birleştirir ve açılışta kurtarır', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = FakeFirebaseFirestore();
      final webJournal = WebLiteJournal(prefs, uid: 'u-web');
      final repo = NotesRepository(db, 'u-web', webJournal: webJournal);

      expect(repo.canJournal, isTrue);

      final id = await repo.createNote(NoteType.text, title: 'Web Notu');
      final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;

      // İki art arda düzenleme WebLiteJournal'da tek girdide toplanır, buluta henüz gitmez.
      repo.journalNote(note.copyWith(body: 'ilk taslak'));
      repo.journalNote(note.copyWith(body: 'ikinci taslak (çökmeden önce)'));
      await webJournal.flush();
      expect(webJournal.contains(id), isTrue);

      final cloudBefore = (await db
              .collection(AppConstants.usersCollection)
              .doc('u-web')
              .collection(AppConstants.notesCollection)
              .doc(id)
              .get())
          .data();
      expect(cloudBefore?['body'], isNot('ikinci taslak (çökmeden önce)'));

      // Yeni oturum (tarayıcı yenilendi): aynı SharedPreferences'tan okur ve buluta yazar!
      final reloadedJournal = WebLiteJournal(prefs, uid: 'u-web');
      final reloadedRepo = NotesRepository(
        db,
        'u-web',
        webJournal: reloadedJournal,
      );
      final recovered = await reloadedRepo.recoverJournal();
      expect(recovered, 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final cloudAfter = (await db
              .collection(AppConstants.usersCollection)
              .doc('u-web')
              .collection(AppConstants.notesCollection)
              .doc(id)
              .get())
          .data();
      expect(cloudAfter?['body'], 'ikinci taslak (çökmeden önce)');
      expect(reloadedJournal.contains(id), isFalse);
    });
  });

  group('CloudflareSyncTransport HTTP sözleşmesi', () {
    test('Bearer JWT başlığı, /v1/sync, /v1/decide, /v1/billing/verify, /v1/media ve hata eşlemeleri', () async {
      final seenAuth = <String?>[];
      final mockClient = MockClient((req) async {
        seenAuth.add(req.headers['authorization']);
        if (req.url.path == '/v1/entitlement') {
          return http.Response(
            jsonEncode({
              'tier': 'lifetime',
              'lifetimeOwned': true,
              'decisionCredits': 1000,
              'decisionTokenCredits': 800000,
              'remaining': {'monthly': 0, 'once': 750, 'pack': 1000},
              'remainingTokens': {'monthly': 0, 'once': 600000, 'pack': 800000},
            }),
            200,
          );
        }
        if (req.url.path == '/v1/decide') {
          if (req.headers['x-firebase-appcheck'] == 'exhaust') {
            return http.Response(
              jsonEncode({
                'error': {'code': 'resource_exhausted', 'message': 'Kota bitti'},
              }),
              429,
            );
          }
          return http.Response(
            jsonEncode({
              'response': {
                'answers': {'k': true},
              },
              'remaining': {'once': 749},
              'remainingTokens': {'once': 599500},
            }),
            200,
          );
        }
        if (req.url.path == '/v1/users/search') {
          return http.Response(
            jsonEncode({
              'results': [
                {'uid': 'u2', 'name': 'Mehmet', 'email': 'm@example.com'},
              ],
            }),
            200,
          );
        }
        if (req.url.path.startsWith('/v1/media/')) {
          if (req.method == 'PUT') {
            return http.Response(
              jsonEncode({
                'ok': true,
                'key': 'u1/n1/img.png',
                'sizeBytes': req.bodyBytes.length,
                'bytesUsed': req.bodyBytes.length,
                'quotaBytes': 262144000,
              }),
              201,
            );
          }
          if (req.method == 'GET') {
            return http.Response.bytes([1, 2, 3, 4], 200);
          }
          if (req.method == 'DELETE') {
            return http.Response(jsonEncode({'ok': true, 'deleted': true}), 200);
          }
        }
        return http.Response('not found', 404);
      });

      var appCheck = 'ok-token';
      final transport = CloudflareSyncTransport(
        baseUrl: 'https://sync.notlar.app',
        getIdToken: () async => 'firebase-jwt-123',
        getAppCheckToken: () async => appCheck,
        client: mockClient,
      );

      final ent = await transport.fetchEntitlement();
      expect(ent.entitlement.lifetimeOwned, isTrue);
      expect(ent.remainingCalls, 1750);
      expect(ent.remainingTokens, 1400000);

      final dec = await transport.decide({'model': 'gemini-decision-1'});
      expect(dec?['remaining'], {'once': 749});

      appCheck = 'exhaust';
      await expectLater(
        () => transport.decide({'model': 'gemini-decision-1'}),
        throwsA(isA<SyncQuotaException>()),
      );

      final users = await transport.searchUsers('meh');
      expect(users.length, 1);
      expect(users.first['uid'], 'u2');

      final uploaded = await transport.uploadMedia(
        key: 'u1/n1/img.png',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        contentType: 'image/png',
        noteId: 'n1',
      );
      expect(uploaded.sizeBytes, 4);
      final downloaded = await transport.downloadMedia('u1/n1/img.png');
      expect(downloaded, [1, 2, 3, 4]);
      await transport.deleteMedia('u1/n1/img.png');

      expect(seenAuth.every((h) => h == 'Bearer firebase-jwt-123'), isTrue);
    });
  });

  group('Riverpod Cloudflare yönlendirmesi (Play + Cloudflare etkin)', () {
    test('entitlementProvider, FriendsRepository ve DecisionService CloudflareSyncTransport kullanır', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeTransport = _InMemoryWorkerTransport();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('u-cf'),
          cloudflareSyncTransportProvider.overrideWithValue(fakeTransport),
        ],
      );
      addTearDown(container.dispose);

      // FriendsRepository doğrudan Cloudflare /v1/users/search çağırır.
      final friendsRepo = FriendsRepository(
        FakeFirebaseFirestore(),
        uid: 'u-cf',
        email: 'cf@example.com',
        name: 'CF User',
        syncTransport: fakeTransport,
      );
      final found = await friendsRepo.searchUsers('ayş');
      expect(fakeTransport.searchCalls, 1);
      expect(found.single.uid, 'u-ayse');

      // Play derlemesinde entitlementProvider Cloudflare'dan okur.
      if (EntitlementGate.active) {
        final sub = container.listen(entitlementProvider, (_, _) {});
        addTearDown(sub.close);
        final ent = await container.read(entitlementProvider.future);
        expect(ent.lifetimeOwned, isTrue);

        // DecisionQuotaSnapshot sunucu yanıtını doğru toplar.
        final snap = DecisionQuotaSnapshot.fromServerMaps(
          {'monthly': 0, 'once': 749, 'pack': 0},
          {'monthly': 0, 'once': 599700, 'pack': 0},
        );
        expect(snap?.remainingCalls, 749);
        expect(snap?.remainingTokens, 599700);
      }
    });
  });
}
