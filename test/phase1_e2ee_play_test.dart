import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/sync/cloudflare_config.dart';
import 'package:notlar/core/sync/cloudflare_sync_transport.dart';
import 'package:notlar/core/sync/sync_models.dart';
import 'package:notlar/core/sync/sync_transport.dart';
import 'package:notlar/core/utils/note_e2ee.dart';
import 'package:notlar/core/utils/note_e2ee_session.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineSwitchingTransport implements SyncTransport {
  bool throwOnFetch = false;

  @override
  Future<RemoteEntitlement> fetchEntitlement() async {
    if (throwOnFetch) throw const SyncTransportException('offline', 'network');
    return const RemoteEntitlement(
      entitlement: Entitlement(tier: EntitlementTier.lifetime, lifetimeOwned: true),
      remainingCalls: 750,
      remainingTokens: 600000,
    );
  }

  @override
  Future<void> deleteAccount() async {}
  @override
  Future<void> deleteMedia(String key) async {}
  @override
  Future<Uint8List> downloadMedia(String key) async => Uint8List(0);
  @override
  Future<Map<String, dynamic>?> decide(Map<String, Object?> body, {Duration? timeout}) async => null;
  @override
  Future<SyncPushPullResponse> pushPull(SyncPushPullRequest request) async =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async => const [];
  @override
  Future<MediaUploadResult> uploadMedia({
    required String key,
    required Uint8List bytes,
    required String contentType,
    String? noteId,
  }) async => throw UnimplementedError();
  @override
  Future<void> upsertShare({
    required String entityKind,
    required String entityId,
    required String memberUid,
    String role = 'both',
    String status = 'active',
  }) async {}
  @override
  Future<void> upsertUserDirectory({
    required String name,
    required String email,
    required bool discoverable,
  }) async {}
  @override
  Future<RemoteEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async => throw UnimplementedError();
}

void main() {
  setUp(() {
    NoteE2eeSession.debugReset();
    AiConsentNotifier.debugRequired = null;
    CloudflareConfig.debugApiBaseOverride = null;
  });

  tearDown(() {
    NoteE2eeSession.debugReset();
    AiConsentNotifier.debugRequired = null;
    CloudflareConfig.debugApiBaseOverride = null;
  });

  group('Phase 1 E2EE data-loss protections', () {
    test('locked note or raw e2ee envelope is never treated as isEmpty', () {
      final locked = Note(
        id: 'n-locked',
        type: NoteType.text,
        locked: true,
      );
      expect(locked.isEmpty, isFalse);

      final encryptedOnStartup = Note.fromMap('n-startup', {
        'type': 'text',
        'title': '',
        'body': '',
        'locked': true,
        'e2ee': 'e2ee:v1:stub-envelope',
      });
      expect(encryptedOnStartup.isEmpty, isFalse);
      expect(encryptedOnStartup.extras.containsKey('e2ee'), isTrue);
    });

    test('textPages and pageNotes encrypt inside e2ee and clear plaintext on wire', () {
      final key = NoteE2ee.generateKey();
      NoteE2eeSession.setKey(key);

      final note = Note(
        id: 'n-multi',
        type: NoteType.pdf,
        title: 'Belge',
        body: 'Ana gövde',
        locked: true,
        pageNotes: const {'1': 'Sayfa 1 gizli notu'},
        textPages: const [NoteTextPage(id: 'tp2', body: 'Sayfa 2 gizli metin')],
      );
      final wire = note.toMap();
      expect(wire['body'], '');
      expect(wire['textPages'], isEmpty);
      expect(wire.containsKey('pageNotes'), isFalse);
      expect(wire['e2ee'], startsWith(NoteE2ee.prefix));

      final restored = Note.fromMap('n-multi', wire);
      expect(restored.body, 'Ana gövde');
      expect(restored.pageNotes['1'], 'Sayfa 1 gizli notu');
      expect(restored.textPages.single.body, 'Sayfa 2 gizli metin');
      expect(restored.extras.containsKey('e2ee'), isFalse);
    });

    test('decryptWithKey recovers cached locked note and unlock strips e2ee', () {
      final key = NoteE2ee.generateKey();
      NoteE2eeSession.setKey(key);
      final wire = Note(
        id: 'n-decrypt',
        type: NoteType.checklist,
        title: 'Gizli',
        items: const [NoteItem(id: '1', text: 'Pin kodu 4321')],
        locked: true,
      ).toMap();

      // Simulate app restart before authentication (session key cleared).
      NoteE2eeSession.debugReset();
      final startupCached = Note.fromMap('n-decrypt', wire);
      expect(startupCached.items, isEmpty);
      expect(startupCached.extras['e2ee'], isA<String>());

      final decrypted = startupCached.decryptWithKey(key);
      expect(decrypted.items.single.text, 'Pin kodu 4321');
      expect(decrypted.extras.containsKey('e2ee'), isFalse);

      final unlocked = decrypted.copyWith(locked: false);
      final unlockedWire = unlocked.toMap();
      expect(unlockedWire.containsKey('e2ee'), isFalse);
      expect(Note.knownKeys.containsAll(unlockedWire.keys), isTrue);
    });

    test('legacy unlocked note keeps newer plaintext over stale e2ee', () {
      final key = NoteE2ee.generateKey();
      final staleEnvelope = NoteE2ee.encryptNotePayload(
        body: 'Eski şifreli veri',
        items: const [],
        key: key,
        noteId: 'n-legacy',
      );
      NoteE2eeSession.setKey(key);
      final parsed = Note.fromMap('n-legacy', {
        'type': 'text',
        'title': 'Başlık',
        'body': 'Güncel düz metin',
        'locked': false,
        'e2ee': staleEnvelope,
        'updatedAt': Timestamp.now(),
      });
      expect(parsed.body, 'Güncel düz metin');
      expect(parsed.extras.containsKey('e2ee'), isFalse);
    });
  });

  group('Phase 1 Play consent, credits, and offline cache', () {
    test('EntitlementGate grants smartDecisions when decisionCredits > 0', () {
      const packOnly = Entitlement(
        decisionCredits: 1000,
      );
      expect(
        EntitlementGate.allows(ProFeature.smartDecisions, packOnly, DateTime.utc(2026)),
        isTrue,
      );
    });

    test('AiConsentNotifier accept and revoke toggle Play consent state', () async {
      AiConsentNotifier.debugRequired = true;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);

      expect(c.read(aiConsentProvider), isFalse);
      c.read(aiConsentProvider.notifier).accept();
      expect(c.read(aiConsentProvider), isTrue);
      c.read(aiConsentProvider.notifier).revoke();
      expect(c.read(aiConsentProvider), isFalse);
    });

    test('Cloudflare entitlement stream preserves cached lifetime entitlement offline', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final transport = _OfflineSwitchingTransport();

      // 1. Direct stream check runs in both Play and non-Play builds.
      final onlineEvents = await cloudflareEntitlementStream(
        transport,
        'uid-cache-test',
        prefs,
      ).toList();
      expect(onlineEvents.last.lifetimeOwned, isTrue);

      transport.throwOnFetch = true;
      final offlineEvents = await cloudflareEntitlementStream(
        transport,
        'uid-cache-test',
        prefs,
      ).toList();
      expect(offlineEvents, isNotEmpty);
      expect(offlineEvents.first.lifetimeOwned, isTrue);

      // 2. Provider wiring check (with listener attached so StreamProvider settles).
      final offlineContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('uid-cache-test'),
          cloudflareSyncTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(offlineContainer.dispose);
      final sub = offlineContainer.listen(entitlementProvider, (_, _) {});
      addTearDown(sub.close);
      final providerEnt = await offlineContainer.read(entitlementProvider.future);
      if (EntitlementGate.active) {
        expect(providerEnt.lifetimeOwned, isTrue);
      } else {
        expect(providerEnt.tier, EntitlementTier.free);
      }
    });
  });
}
