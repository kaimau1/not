// HAK SAĞLAYICISI — PLAN §1.5 PL14. Tek kaynak: `entitlements/{uid}`
// (istemci yalnız OKUR; yazma Admin SDK, bkz. firestore.rules). Web ve
// Android aynı sağlayıcıyı izler.
//
// KİŞİSEL APK / WEB: [EntitlementGate.active] false → Firestore'a HİÇ
// gidilmez (ek okuma yok), herkes her şeye erişir.
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/sync/cloudflare_sync_transport.dart';
import '../../../core/sync/sync_transport.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart'
    show sharedPreferencesProvider;
import '../domain/entitlement.dart';

const _cfEntitlementCachePrefix = 'cf_entitlement_v1_';

Entitlement? _readCachedEntitlement(SharedPreferences? prefs, String uid) {
  final raw = prefs?.getString('$_cfEntitlementCachePrefix$uid');
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    DateTime? parseMs(String key) {
      final v = map[key];
      return v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
    }

    return Entitlement.fromMap({
      'tier': map['tier'],
      'lifetimeOwned': map['lifetimeOwned'],
      'decisionCredits': map['decisionCredits'],
      'decisionTokenCredits': map['decisionTokenCredits'],
      'proUntil': parseMs('proUntilMs'),
      'trialEndsAt': parseMs('trialEndsAtMs'),
    });
  } catch (_) {
    return null;
  }
}

void _writeCachedEntitlement(
  SharedPreferences? prefs,
  String uid,
  Entitlement e,
) {
  if (prefs == null) return;
  unawaited(
    prefs.setString(
      '$_cfEntitlementCachePrefix$uid',
      jsonEncode({
        'tier': e.tier.name,
        'lifetimeOwned': e.lifetimeOwned,
        'decisionCredits': e.decisionCredits,
        'decisionTokenCredits': e.decisionTokenCredits,
        'proUntilMs': e.proUntil?.millisecondsSinceEpoch,
        'trialEndsAtMs': e.trialEndsAt?.millisecondsSinceEpoch,
      }),
    ),
  );
}

@visibleForTesting
Stream<Entitlement> cloudflareEntitlementStream(
  SyncTransport transport,
  String uid,
  SharedPreferences? prefs,
) async* {
  final cached = _readCachedEntitlement(prefs, uid);
  if (cached != null) yield cached;
  try {
    final remote = await transport.fetchEntitlement();
    _writeCachedEntitlement(prefs, uid, remote.entitlement);
    yield remote.entitlement;
  } catch (_) {
    if (cached == null) yield Entitlement.none;
  }
}

/// Oturumdaki kullanıcının hak belgesi. Play derlemesinde belge yoksa ya da
/// okunamazsa (çevrimdışı ilk açılış, izin hatası) ücretsiz sayılır — hak
/// vermemek, yanlışlıkla Pro vermekten güvenli (okuyanlar `.value ?? none`).
/// Cloudflare Worker (`CLOUDFLARE_API_BASE`) etkinse hak `GET /v1/entitlement`
/// uç noktasından okunur ve çevrimdışı açılışlar için UID bazlı önbelleğe
/// alınır; değilse mevcut Firestore yolu sürer.
final entitlementProvider = StreamProvider<Entitlement>((ref) {
  if (!EntitlementGate.active) return Stream.value(Entitlement.none);
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(Entitlement.none);
  final transport = ref.watch(cloudflareSyncTransportProvider);
  if (transport != null) {
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {
      prefs = null;
    }
    return cloudflareEntitlementStream(transport, uid, prefs);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.entitlementsCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => entitlementFromFirestore(doc.data()));
});

/// Firestore `Timestamp` alanlarını [DateTime]'a çevirip modeli kurar.
Entitlement entitlementFromFirestore(Map<String, dynamic>? data) {
  if (data == null) return Entitlement.none;
  return Entitlement.fromMap({
    for (final e in data.entries)
      e.key: e.value is Timestamp ? (e.value as Timestamp).toDate() : e.value,
  });
}

/// Şu an geçerli hak + saat. Deneme/abonelik bitiş anında kendini yeniler
/// (uygulama açıkken deneme bitince kapı yeniden başlatmadan kapanır).
final _entitlementNowProvider = Provider<(Entitlement, DateTime)>((ref) {
  final e = ref.watch(entitlementProvider).value ?? Entitlement.none;
  final now = DateTime.now();
  final next = e.nextChange(now);
  if (next != null) {
    // Timer tavanı (~24,8 gün) aşılmasın; uzak bitişte ara yenileme zararsız.
    var wait = next.difference(now) + const Duration(seconds: 1);
    if (wait > const Duration(days: 20)) wait = const Duration(days: 20);
    final timer = Timer(wait, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return (e, now);
});

/// Geçerli katman (Play dışında hep [EntitlementTier.free] görünür ama
/// kapılar [EntitlementGate.allows] üzerinden açık).
final effectiveTierProvider = Provider<EntitlementTier>((ref) {
  final (e, now) = ref.watch(_entitlementNowProvider);
  return e.effectiveTier(now);
});

/// Özellik kapısı — ekranlar bunu izler. Bayraksız derlemede hep `true`.
final proFeatureProvider = Provider.family<bool, ProFeature>((ref, feature) {
  if (!EntitlementGate.active) return true;
  final (e, now) = ref.watch(_entitlementNowProvider);
  return EntitlementGate.allows(feature, e, now);
});

/// "Eski ekleri Drive'a taşı" önerisi bayrağı (UI YOK; metin
/// [EntitlementGate.moveToDriveDraft]). Bayraksız derlemede hep `false`.
final offerMoveToDriveProvider = Provider<bool>((ref) {
  if (!EntitlementGate.active) return false;
  final (e, now) = ref.watch(_entitlementNowProvider);
  return EntitlementGate.offerMoveToDrive(e, now);
});
