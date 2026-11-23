import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/web_attachment_cache.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/drive_store.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

class _NoStorage extends Fake implements FirebaseStorage {}

void main() {
  group('WebAttachmentCache & LRU bütçesi', () {
    test('keysToEvictForDriveBudget yalnızca en eski drive:* girdilerini seçer, local:* korunur', () {
      final entries = <WebCacheEntryMeta>[
        (key: webLocalCacheKey('loc-1'), sizeBytes: 500, updatedAtMs: 1),
        (key: webDriveCacheKey('drv-old'), sizeBytes: 60, updatedAtMs: 10),
        (key: webDriveCacheKey('drv-mid'), sizeBytes: 50, updatedAtMs: 20),
        (key: webDriveCacheKey('drv-new'), sizeBytes: 40, updatedAtMs: 30),
      ];

      final evict = keysToEvictForDriveBudget(entries, maxDriveBytes: 100);
      expect(evict, [webDriveCacheKey('drv-old')]);

      final evictTwo = keysToEvictForDriveBudget(entries, maxDriveBytes: 40);
      expect(evictTwo, [
        webDriveCacheKey('drv-old'),
        webDriveCacheKey('drv-mid'),
      ]);
      expect(evictTwo.contains(webLocalCacheKey('loc-1')), isFalse);
    });

    test('MemoryWebAttachmentCache local:* izler, clearDriveCache yalnızca drive:* siler', () async {
      final cache = MemoryWebAttachmentCache();
      await cache.init();
      final revEvents = <int>[];
      cache.revision.addListener(() => revEvents.add(cache.revision.value));

      await cache.put(
        webLocalCacheKey('a-local'),
        Uint8List.fromList([1, 2, 3, 4]),
        'image/png',
      );
      expect(cache.knownLocalIds, contains('a-local'));
      expect(revEvents, isNotEmpty);

      await cache.put(
        webDriveCacheKey('d-1'),
        Uint8List.fromList([9, 8, 7]),
        'application/pdf',
      );
      final beforeClear = await cache.stats();
      expect(beforeClear.localCount, 1);
      expect(beforeClear.localBytes, 4);
      expect(beforeClear.driveCount, 1);
      expect(beforeClear.driveBytes, 3);

      final gotLocal = await cache.get(webLocalCacheKey('a-local'));
      expect(gotLocal?.bytes, Uint8List.fromList([1, 2, 3, 4]));
      expect(gotLocal?.mimeType, 'image/png');

      await cache.clearDriveCache();
      final afterClear = await cache.stats();
      expect(afterClear.driveCount, 0);
      expect(afterClear.driveBytes, 0);
      expect(afterClear.localCount, 1);
      expect(cache.knownLocalIds, contains('a-local'));

      await cache.delete(webLocalCacheKey('a-local'));
      expect(cache.knownLocalIds, isNot(contains('a-local')));
    });

    test('webLocalCacheContains etkin önbelleğe göre yanıt verir', () async {
      final prev = webAttachmentCache;
      final mem = MemoryWebAttachmentCache();
      setWebAttachmentCacheForTest(mem);
      addTearDown(() => setWebAttachmentCacheForTest(prev));

      expect(webLocalCacheContains('att-99'), isFalse);
      await mem.put(
        webLocalCacheKey('att-99'),
        Uint8List.fromList([42]),
        'audio/webm',
      );
      expect(webLocalCacheContains('att-99'), isTrue);
    });
  });

  group('WebDriveAuth GIS sessiz yenileme ve açılır pencere yedeği', () {
    test('eşzamanlı sessiz accessToken çağrıları tek GIS isteğinde birleşir', () async {
      var now = DateTime(2026, 11, 23, 10);
      var gisCalls = 0;
      String? lastHint;
      bool? lastSilent;

      final auth = WebDriveAuth(
        clientId: () => 'test-client-id',
        gisAvailable: () => true,
        uidProvider: () => 'uid-sync-1',
        emailProvider: () => 'dr@example.com',
        now: () => now,
        gisRequester:
            ({
              required clientId,
              required scopes,
              loginHint,
              required silent,
            }) async {
              gisCalls++;
              lastHint = loginHint;
              lastSilent = silent;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return (token: 'gis-silent-tok', expiresIn: 3600);
            },
        popupConnect: () async => 'popup-should-not-run',
      );
      addTearDown(auth.disconnect);

      final results = await Future.wait([
        auth.accessToken(),
        auth.accessToken(),
        auth.accessToken(),
      ]);

      expect(results, ['gis-silent-tok', 'gis-silent-tok', 'gis-silent-tok']);
      expect(gisCalls, 1);
      expect(lastHint, 'dr@example.com');
      expect(lastSilent, isTrue);

      // Süre dolmadan bellek/oturum önbelleğinden gelir (yeni GIS isteği yok).
      now = now.add(const Duration(minutes: 10));
      expect(await auth.accessToken(), 'gis-silent-tok');
      expect(gisCalls, 1);
    });

    test('sessiz yenileme boş dönerse 60s bekleme uygular; connect etkileşimli alır', () async {
      var now = DateTime(2026, 11, 23, 11);
      var silentCalls = 0;
      var interactiveCalls = 0;
      final startRev = webDriveTokenRevision.value;

      final auth = WebDriveAuth(
        clientId: () => 'test-client-id',
        gisAvailable: () => true,
        uidProvider: () => 'uid-cooldown',
        emailProvider: () => 'hekim@example.com',
        now: () => now,
        gisRequester:
            ({
              required clientId,
              required scopes,
              loginHint,
              required silent,
            }) async {
              if (silent) {
                silentCalls++;
                return null;
              }
              interactiveCalls++;
              return (token: 'gis-interactive-tok', expiresIn: 1800);
            },
        popupConnect: () async => null,
      );
      addTearDown(auth.disconnect);

      expect(await auth.accessToken(), isNull);
      expect(silentCalls, 1);

      // Bekleme süresi içinde tekrar denemez.
      now = now.add(const Duration(seconds: 20));
      expect(await auth.accessToken(), isNull);
      expect(silentCalls, 1);

      // Etkileşimli connect beklemeyi beklemeden jetonu alır ve revizyonu artırır.
      expect(await auth.connect(), isTrue);
      expect(interactiveCalls, 1);
      expect(await auth.accessToken(), 'gis-interactive-tok');
      expect(webDriveTokenRevision.value, greaterThan(startRev));

      await auth.invalidate('gis-interactive-tok');
      // İptalden sonra bekleme temizlenir ve tekrar sessiz deneyebilir.
      now = now.add(const Duration(seconds: 65));
      expect(await auth.accessToken(), isNull);
      expect(silentCalls, 2);
    });

    test('GIS yokken veya boş dönerken connect Firebase açılır pencere yedeğine düşer', () async {
      var popupCalls = 0;
      final auth = WebDriveAuth(
        clientId: () => '',
        gisAvailable: () => false,
        uidProvider: () => 'uid-popup',
        emailProvider: () => 'pop@example.com',
        popupConnect: () async {
          popupCalls++;
          return 'popup-tok';
        },
      );
      addTearDown(auth.disconnect);

      expect(await auth.connect(), isTrue);
      expect(popupCalls, 1);
      expect(await auth.accessToken(), 'popup-tok');
    });
  });

  group('AttachmentRepository web ses ve önbellek yüklemeleri', () {
    test('prepareAudioBytes maxBytes sınırını aşan sesi reddeder', () async {
      final repo = AttachmentRepository(_NoStorage(), 'u1', 4);
      await expectLater(
        repo.prepareAudioBytes(
          noteId: 'n1',
          bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          mimeTypeHint: 'audio/webm',
        ),
        throwsA(isA<FileTooLargeException>()),
      );
    });

    test('uploadWebCachedToDrive ve uploadWebCachedToStorage eksik/yüklü ekte null döner', () async {
      final prev = webAttachmentCache;
      final mem = MemoryWebAttachmentCache();
      setWebAttachmentCacheForTest(mem);
      addTearDown(() => setWebAttachmentCacheForTest(prev));

      final repo = AttachmentRepository(_NoStorage(), 'u1', 1024);

      const syncedDrive = Attachment(
        id: 'att-drv',
        kind: AttachmentKind.audio,
        fileName: 'ses.webm',
        mimeType: 'audio/webm',
        driveId: 'drive-123',
      );
      expect(await repo.uploadWebCachedToDrive('n1', syncedDrive), isNull);

      const syncedStorage = Attachment(
        id: 'att-stg',
        kind: AttachmentKind.pdf,
        fileName: 'lab.pdf',
        mimeType: 'application/pdf',
        storagePath: 'users/u1/n1/lab.pdf',
        downloadUrl: 'https://example.com/lab.pdf',
      );
      expect(await repo.uploadWebCachedToStorage('n1', syncedStorage), isNull);

      const missingCached = Attachment(
        id: 'att-missing',
        kind: AttachmentKind.audio,
        fileName: 'ses.webm',
        mimeType: 'audio/webm',
      );
      expect(await repo.uploadWebCachedToDrive('n1', missingCached), isNull);
      expect(await repo.uploadWebCachedToStorage('n1', missingCached), isNull);
    });
  });
}
