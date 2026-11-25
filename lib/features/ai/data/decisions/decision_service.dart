import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error_log.dart';
import '../../../../core/net/json_http.dart';
import '../../../../core/sync/cloudflare_sync_transport.dart';
import '../../../../core/sync/sync_transport.dart';
import '../../../entitlement/data/entitlement_service.dart';
import '../../../entitlement/domain/entitlement.dart';
import '../../../settings/settings_providers.dart'
    show sharedPreferencesProvider;
import '../ai_policy.dart';
import '../ai_provider.dart';
import '../api_key_store.dart';
import 'decision_flag.dart';
import 'decision_models.dart';

/// Decisions API çift kilitli bütçe sabitleri (50 TL Tek Seferlik Tam Sürüm).
/// Sunucu eşi: `functions/decisions_util.js` (`LIFETIME_ONCE`,
/// `LIFETIME_MAX_INPUT_TOKENS`, `PACK_TOKENS_PER_CALL`).
abstract final class DecisionQuotaDefaults {
  static const lifetimeCalls = 750;
  static const lifetimeTokens = 600000;
  static const packTokensPerCall = 800;
}

/// Kullanıcının sunucu tarafı Decisions API kalan hak özeti.
@immutable
class DecisionQuotaSnapshot {
  const DecisionQuotaSnapshot({
    required this.remainingCalls,
    required this.remainingTokens,
    this.syncedFromServer = false,
  });

  final int remainingCalls;
  final int remainingTokens;

  /// En az bir kez sunucu yanıtından güncellendi mi.
  final bool syncedFromServer;

  bool get exhausted => remainingCalls <= 0 || remainingTokens <= 0;

  Map<String, Object?> toJson() => {
    'calls': remainingCalls,
    'tokens': remainingTokens,
    'synced': syncedFromServer,
  };

  static DecisionQuotaSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final calls = raw['calls'];
    final tokens = raw['tokens'];
    if (calls is! num || tokens is! num) return null;
    return DecisionQuotaSnapshot(
      remainingCalls: calls.toInt().clamp(0, 10000000),
      remainingTokens: tokens.toInt().clamp(0, 1000000000),
      syncedFromServer: raw['synced'] == true,
    );
  }

  /// Sunucu `decide` yanıtındaki `remaining` ve `remainingTokens` haritalarını
  /// (kova toplamı: `monthly + once + pack`) tek özete çevirir.
  static DecisionQuotaSnapshot? fromServerMaps(
    Object? remainingRaw,
    Object? remainingTokensRaw,
  ) {
    final calls = _sumMap(remainingRaw);
    final tokens = _sumMap(remainingTokensRaw);
    if (calls == null && tokens == null) return null;
    return DecisionQuotaSnapshot(
      remainingCalls: calls ?? 0,
      remainingTokens: tokens ?? 0,
      syncedFromServer: true,
    );
  }

  static int? _sumMap(Object? raw) {
    if (raw is! Map) return null;
    var sum = 0;
    var found = false;
    for (final v in raw.values) {
      if (v is num) {
        sum += v.toInt().clamp(0, 1000000000);
        found = true;
      }
    }
    return found ? sum : null;
  }
}

/// Ayarlar → Tam Sürüm kartı ve [ProScreen] için kalan akıllı karar sayacı.
/// Sunucu yanıtı geldikçe güncellenir ve yerelde saklanır; henüz çağrı
/// yapılmadıysa [Entitlement] haklarından başlangıç tavanı hesaplanır.
final decisionQuotaProvider =
    NotifierProvider<DecisionQuotaNotifier, DecisionQuotaSnapshot>(
      DecisionQuotaNotifier.new,
    );

class DecisionQuotaNotifier extends Notifier<DecisionQuotaSnapshot> {
  static const prefsKey = 'decision_quota_snapshot_v1';

  @override
  DecisionQuotaSnapshot build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final ent = ref.watch(entitlementProvider).value ?? Entitlement.none;
    final raw = prefs.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = DecisionQuotaSnapshot.fromJson(jsonDecode(raw));
        if (parsed != null) return parsed;
      } catch (_) {
        // Bozuk önbellek varsayılana düşer.
      }
    }
    return _defaultFor(ent);
  }

  static DecisionQuotaSnapshot _defaultFor(Entitlement ent) {
    final baseCalls = ent.hasFullVersion
        ? DecisionQuotaDefaults.lifetimeCalls
        : 0;
    final baseTokens = ent.hasFullVersion
        ? DecisionQuotaDefaults.lifetimeTokens
        : 0;
    final extraCalls = ent.decisionCredits;
    final extraTokens = ent.decisionTokenCredits > 0
        ? ent.decisionTokenCredits
        : extraCalls * DecisionQuotaDefaults.packTokensPerCall;
    return DecisionQuotaSnapshot(
      remainingCalls: baseCalls + extraCalls,
      remainingTokens: baseTokens + extraTokens,
    );
  }

  void updateFromServer(DecisionQuotaSnapshot snapshot) {
    state = snapshot;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setString(prefsKey, jsonEncode(snapshot.toJson())));
  }

  void markExhausted() {
    updateFromServer(
      const DecisionQuotaSnapshot(
        remainingCalls: 0,
        remainingTokens: 0,
        syncedFromServer: true,
      ),
    );
  }
}

final decisionServiceProvider = Provider<DecisionService>(
  (ref) => DecisionService(
    key: _admittedGeminiKeyFor(ref),
    proxy: _proxyFor(ref),
    prefs: ref.watch(sharedPreferencesProvider),
    onQuota: (snapshot) =>
        ref.read(decisionQuotaProvider.notifier).updateFromServer(snapshot),
    onQuotaExhausted: () =>
        ref.read(decisionQuotaProvider.notifier).markExhausted(),
  ),
);

/// Kendi Gemini anahtarı (BYOK): [AiAdmission] kapısından (AI kapalı /
/// kill switch / rıza / katman) geçer ve anahtarı güvenli depodan okur.
Future<String?> Function() _admittedGeminiKeyFor(Ref ref) {
  final store = ref.watch(apiKeyStoreProvider);
  final admission = ref.read(aiAdmissionProvider);
  return () async {
    final raw = (await store.read())?.trim();
    if (raw == null || raw.isEmpty) return null;
    admission.check(metered: false);
    admission.checkTier(hasOwnKey: true);
    return raw;
  };
}

/// Sunucu vekili (`functions/decisions.js` `decide`, PLAN U8 / Faz 0+1):
/// YALNIZ Play derlemesinde ve Tam Sürüm katmanında; kendi anahtarı yoksa
/// kullanılır. Kota sunucuda (750 karar / 600K jeton çift kilidi + ek
/// +1.000 karar paketi); ücretsizde null → Decisions yok.
DecisionProxy? _proxyFor(Ref ref) {
  if (!EntitlementGate.active) return null;
  if (!ref.watch(proFeatureProvider(ProFeature.smartDecisions))) return null;
  final admission = ref.read(aiAdmissionProvider);
  final cfTransport = ref.watch(cloudflareSyncTransportProvider);
  return (body) async {
    admission.check(metered: false);
    if (cfTransport != null) {
      try {
        final data = await cfTransport.decide(
          body,
          timeout: DecisionService.proxyTimeout,
        );
        if (data == null) return null;
        final snapshot = DecisionQuotaSnapshot.fromServerMaps(
          data['remaining'],
          data['remainingTokens'],
        );
        if (snapshot != null) {
          ref.read(decisionQuotaProvider.notifier).updateFromServer(snapshot);
        }
        final res = data['response'];
        return res is Map<String, dynamic>
            ? res
            : (res is Map ? Map<String, dynamic>.from(res) : null);
      } on SyncQuotaException {
        throw const DecisionQuotaExhausted();
      }
    }
    try {
      final r = await FirebaseFunctions.instance
          .httpsCallable(
            'decide',
            options: HttpsCallableOptions(
              timeout: DecisionService.proxyTimeout,
            ),
          )
          .call<Object?>(body);
      final data = r.data;
      if (data is! Map) return null;
      final snapshot = DecisionQuotaSnapshot.fromServerMaps(
        data['remaining'],
        data['remainingTokens'],
      );
      if (snapshot != null) {
        ref.read(decisionQuotaProvider.notifier).updateFromServer(snapshot);
      }
      final res = data['response'];
      // Platform kanalı iç içe Map<Object?, Object?> verir → JSON'la düzle.
      return res is Map
          ? jsonDecode(jsonEncode(res)) as Map<String, dynamic>
          : null;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const DecisionQuotaExhausted();
      rethrow;
    }
  };
}

/// Vekil çağrısı: gövde → Decisions yanıtı (null = boş yanıt).
typedef DecisionProxy =
    Future<Map<String, dynamic>?> Function(Map<String, Object?> body);

/// Sunucu: bu kullanıcının karar hakkı bitti.
class DecisionQuotaExhausted implements Exception {
  const DecisionQuotaExhausted();
}

/// **TEK DECISIONS SERVİSİ** (DA-E1, plan §4.2, Faz 1). REST
/// `POST /v1beta/decisions` (`gemini-decision-1`). Hiçbir durumda istisna
/// atmaz: kullanılamıyorsa null döner ve çağıran yerel yoluna düşer. Sıra:
///  1. bayrak ([AiDecisionsFlag]) özelliği kapalıysa ağ yok;
///  2. [key]: kullanıcının kendi Gemini anahtarı (BYOK, `AiAdmission`
///     kapılarından geçer); kendi anahtarı yoksa [proxy] (Play + Tam Sürüm;
///     `decide` Function, sunucu kotası), o da yoksa null;
///  3. kendi hız sınırı; 429/5xx sonrası kısa bekleme;
///  4. bellek önbelleği ([cacheTtl]) + [persistentFeatures] için kalıcı yerel
///     önbellek ([persistentCacheTtl], SHA-256 özetli anahtar; düz metin yok);
///  5. zaman aşımı [timeout] (≤ 1,5 sn) → null.
class DecisionService {
  DecisionService({
    required this.key,
    JsonHttp? http,
    this.timeout = defaultTimeout,
    DateTime Function()? now,
    AiRateLimiter? limiter,
    this.proxy,
    this.prefs,
    this.onQuota,
    this.onQuotaExhausted,
  }) : _http = http ?? JsonHttp(baseUrl: AiProvider.gemini.baseUrl),
       _now = now ?? DateTime.now,
       limiter = limiter ?? AiRateLimiter();

  /// İzinli Gemini anahtarı (BYOK).
  final Future<String?> Function() key;

  /// Kendi anahtarı yokken sunucu vekili; null = vekil yok.
  final DecisionProxy? proxy;
  final JsonHttp _http;
  final DateTime Function() _now;
  final SharedPreferences? prefs;
  final Duration timeout;
  final void Function(DecisionQuotaSnapshot snapshot)? onQuota;
  final void Function()? onQuotaExhausted;

  final AiRateLimiter limiter;

  /// ≤ 1,5 sn: kararı bekleyen akış (hızlı ekle geri sayımı) gecikmesin.
  static const defaultTimeout = Duration(seconds: 1, milliseconds: 500);

  /// Vekil (Cloud Function) soğuk başlangıcı ekler: 3 sn.
  static const proxyTimeout = Duration(seconds: 3);

  /// Hak bitince vekil bu kadar susar (her karar noktası sunucuyu yormasın).
  static const quotaPause = Duration(hours: 6);
  static const cacheTtl = Duration(minutes: 5);
  static const cacheSize = 32;
  static const maxQuestions = 60;

  /// P1-2: Uygulama kapansa da tekrar kredi yakmaması gereken kararlar.
  static const Set<String> persistentFeatures = {
    DecisionFeature.noteTriage,
    DecisionFeature.shopAisle,
  };
  static const persistentCacheTtl = Duration(days: 30);
  static const persistentCacheSize = 200;
  static const persistentPrefsKey = 'decision_persistent_cache_v1';

  final _cache = <String, (DateTime, Map<String, DecisionAnswer>)>{};
  Map<String, Object?>? _persistentRaw;
  DateTime? _pausedUntil;

  DecisionMode modeOf(String feature) => AiDecisionsFlag.modeOf(feature);

  /// Ayarlar → Kendi Gemini Anahtarı (BYOK) doğrulaması: `GET /models` ile
  /// anahtarın geçerli olduğunu tek hafif istekle kontrol eder.
  Future<bool> validateGeminiKey(String rawKey) async {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) return false;
    try {
      await _http
          .get<Map<String, dynamic>>(
            '/models',
            headers: AiProvider.gemini.authHeaders(trimmed),
            queryParameters: const {'pageSize': '1'},
            timeout: const Duration(seconds: 8),
          )
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _hashKey(String raw) =>
      sha256.convert(utf8.encode(raw)).toString();

  Map<String, Object?> _loadPersistent() {
    final existing = _persistentRaw;
    if (existing != null) return existing;
    final prefs = this.prefs;
    if (prefs == null) return _persistentRaw = <String, Object?>{};
    final raw = prefs.getString(persistentPrefsKey);
    if (raw == null || raw.isEmpty) {
      return _persistentRaw = <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return _persistentRaw = Map<String, Object?>.from(decoded);
      }
    } catch (_) {
      // Bozuk yerel önbellek sessizce sıfırlanır.
    }
    return _persistentRaw = <String, Object?>{};
  }

  Map<String, DecisionAnswer>? _readPersistent(
    String hashedKey,
    Map<String, DecisionQuestion> questions,
    DateTime now,
  ) {
    if (prefs == null) return null;
    final store = _loadPersistent();
    final entry = store[hashedKey];
    if (entry is! Map) return null;
    final tsMs = entry['ts'];
    final answersRaw = entry['answers'];
    if (tsMs is! num || answersRaw is! Map) {
      store.remove(hashedKey);
      return null;
    }
    final savedAt = DateTime.fromMillisecondsSinceEpoch(tsMs.toInt());
    if (now.difference(savedAt) >= persistentCacheTtl) {
      store.remove(hashedKey);
      return null;
    }
    final parsed = parseDecisionResponse({'answers': answersRaw}, questions);
    if (parsed.isEmpty) return null;
    // LRU tazeleme.
    store.remove(hashedKey);
    store[hashedKey] = entry;
    return parsed;
  }

  void _writePersistent(
    String hashedKey,
    Map<String, DecisionAnswer> answers,
    DateTime now,
  ) {
    final storePrefs = prefs;
    if (storePrefs == null || answers.isEmpty) return;
    final store = _loadPersistent();
    store.remove(hashedKey);
    store[hashedKey] = <String, Object?>{
      'ts': now.millisecondsSinceEpoch,
      'answers': {for (final e in answers.entries) e.key: e.value.toJson()},
    };
    while (store.length > persistentCacheSize) {
      store.remove(store.keys.first);
    }
    unawaited(storePrefs.setString(persistentPrefsKey, jsonEncode(store)));
  }

  /// [feature] için [input] metni üstünde [questions]'ı TEK çağrıda sorar
  /// (toplu soru: aynı girdi, N soru). Kullanılamıyorsa null. Boş harita =
  /// yanıt geldi ama hiçbir soru ayrıştırılamadı.
  Future<Map<String, DecisionAnswer>?> decide(
    String feature, {
    required String input,
    required Map<String, DecisionQuestion> questions,
  }) async {
    if (modeOf(feature) == DecisionMode.off) return null;
    if (input.trim().isEmpty ||
        questions.isEmpty ||
        questions.length > maxQuestions ||
        !questions.keys.every(decisionKeyPattern.hasMatch)) {
      return null;
    }
    final model = AiDecisionsFlag.model;
    final qs = {for (final e in questions.entries) e.key: e.value.toJson()};
    final cacheKey = '$feature|$model|$input|${jsonEncode(qs)}';
    final now = _now();
    final hit = _cache.remove(cacheKey);
    if (hit != null && now.difference(hit.$1) < cacheTtl) {
      _cache[cacheKey] = hit;
      return hit.$2;
    }
    final persist = persistentFeatures.contains(feature) && prefs != null;
    final persistentHash = persist ? _hashKey(cacheKey) : null;
    if (persistentHash != null) {
      final saved = _readPersistent(persistentHash, questions, now);
      if (saved != null) {
        _cache[cacheKey] = (now, saved);
        return saved;
      }
    }
    final paused = _pausedUntil;
    if (paused != null && now.isBefore(paused)) return null;
    String? apiKey;
    try {
      apiKey = await key();
    } on AiPolicyException {
      // AI kapalı / kill switch / rıza yok / katman yetmiyor: vekil kendi
      // kapısını yine geçer; vekil yoksa ağ yok.
      apiKey = null;
    }
    final viaProxy = apiKey == null || apiKey.isEmpty;
    final proxy = this.proxy;
    if (viaProxy && proxy == null) return null;
    if (!limiter.tryAcquire(now)) return null;
    final body = <String, Object?>{
      'model': model,
      'input': [
        {'type': 'text', 'text': input},
      ],
      'questions': qs,
    };
    final sw = Stopwatch()..start();
    try {
      final Map<String, dynamic>? data;
      if (viaProxy) {
        data = await proxy!(body).timeout(proxyTimeout);
      } else {
        final res = await _http
            .post<Map<String, dynamic>>(
              '/decisions',
              headers: AiProvider.gemini.authHeaders(apiKey),
              data: body,
              timeout: timeout,
            )
            .timeout(timeout);
        data = res.data;
      }
      final answers = parseDecisionResponse(data, questions);
      _cache[cacheKey] = (now, answers);
      while (_cache.length > cacheSize) {
        _cache.remove(_cache.keys.first);
      }
      if (persistentHash != null && answers.isNotEmpty) {
        _writePersistent(persistentHash, answers, now);
      }
      return answers;
    } on JsonHttpException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429 || (code != null && code >= 500)) {
        _pausedUntil = now.add(const Duration(minutes: 1));
      }
      _fallback(feature, 'http ${code ?? e.message}', sw);
    } on DecisionQuotaExhausted {
      _pausedUntil = now.add(quotaPause);
      onQuotaExhausted?.call();
      _fallback(feature, 'quota', sw);
    } on AiPolicyException {
      return null; // vekil kapısı (AI kapalı / kill switch / rıza): sessiz.
    } on TimeoutException {
      _fallback(feature, 'timeout', sw);
    } catch (e) {
      _fallback(feature, e.runtimeType.toString(), sw);
    }
    return null;
  }

  /// İÇERİK YAZILMAZ: yalnız özellik, neden, süre.
  static void _fallback(String feature, String why, Stopwatch sw) =>
      ErrorLog.record(
        'decision-fallback',
        '$feature: $why (${sw.elapsedMilliseconds} ms)',
      );

  /// Gölge kip uyuşma kaydı (İÇERİK YOK).
  static void logShadow(String feature, String detail) =>
      ErrorLog.record('decision-shadow', '$feature: $detail');
}
