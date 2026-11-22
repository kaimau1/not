import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error_log.dart';
import '../../../../core/net/json_http.dart';
import '../../../entitlement/data/entitlement_service.dart';
import '../../../entitlement/domain/entitlement.dart';
import '../ai_policy.dart' show AiRateLimiter, aiAdmissionProvider;
import '../ai_provider.dart';
import '../gemini_service.dart';
import 'decision_flag.dart';
import 'decision_models.dart';

final decisionServiceProvider = Provider<DecisionService>(
  (ref) => DecisionService(
    key: ref.watch(geminiServiceProvider).admittedDecisionKey,
    proxy: _proxyFor(ref),
  ),
);

/// Sunucu vekili (`functions/decisions.js` `decide`, PLAN U8 KARAR
/// 2026-11-22): YALNIZ Play derlemesinde ve ücretli katmanda (Pro ya da ömür
/// boyu); kendi anahtarı yoksa kullanılır. Kota sunucuda (Pro ayda 500, ömür
/// boyu bir kerelik 1000); ücretsizde null → Decisions yok. Kişisel APK/web
/// bugünkü gibi yalnız kendi anahtarıyla.
DecisionProxy? _proxyFor(Ref ref) {
  if (!EntitlementGate.active) return null;
  if (!ref.watch(proFeatureProvider(ProFeature.ownApiKey))) return null;
  final admission = ref.read(aiAdmissionProvider);
  return (body) async {
    // AI'ı kapat / kill switch / rıza vekilde de geçerli (hız sınırı yok:
    // Decisions'ın kendi sayacı var).
    admission.check(metered: false);
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
      final res = data is Map ? data['response'] : null;
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
typedef DecisionProxy = Future<Map<String, dynamic>?> Function(
  Map<String, Object?> body,
);

/// Sunucu: bu kullanıcının karar hakkı bitti.
class DecisionQuotaExhausted implements Exception {
  const DecisionQuotaExhausted();
}

/// **TEK DECISIONS SERVİSİ** (DA-E1, plan §4.2). REST `POST /v1beta/decisions`
/// (Dart SDK yok). Hiçbir durumda istisna atmaz: kullanılamıyorsa null döner
/// ve çağıran BUGÜNKÜ yoluna düşer. Sıra:
///  1. bayrak ([AiDecisionsFlag]) özelliği kapalıysa ağ yok;
///  2. [key]: [GeminiService.admittedDecisionKey] — `AiAdmission` kapıları
///     (AI'ı kapat, `aiKillSwitch`, Play rızası) ondan geçer; kendi anahtarı
///     yoksa [proxy] (Play + ücretli katman; `decide` Function, sunucu
///     kotası), o da yoksa null;
///  3. kendi hız sınırı (K8: arka plan kararları elle yapılan AI isteklerinin
///     dakikalık hakkını yemesin); 429/5xx sonrası kısa bekleme;
///  4. kısa önbellek (aynı girdi + sorular, [cacheTtl]);
///  5. zaman aşımı [timeout] (≤ 1,5 sn) → null.
class DecisionService {
  DecisionService({
    required this.key,
    JsonHttp? http,
    this.timeout = defaultTimeout,
    DateTime Function()? now,
    AiRateLimiter? limiter,
    this.proxy,
  }) : _http = http ?? JsonHttp(baseUrl: AiProvider.gemini.baseUrl),
       _now = now ?? DateTime.now,
       limiter = limiter ?? AiRateLimiter();

  /// İzinli anahtar ([GeminiService.admittedDecisionKey]).
  final Future<String?> Function() key;

  /// Kendi anahtarı yokken sunucu vekili; null = vekil yok.
  final DecisionProxy? proxy;
  final JsonHttp _http;
  final DateTime Function() _now;
  final Duration timeout;

  final AiRateLimiter limiter;

  /// ≤ 1,5 sn: kararı bekleyen akış (hızlı ekle geri sayımı) gecikmesin.
  static const defaultTimeout = Duration(seconds: 1, milliseconds: 500);

  /// Vekil (Cloud Function) soğuk başlangıcı ekler: 3 sn. Zaman aşımında
  /// sunucu hakkı yine harcayabilir (yanıt geç geldi) — kabul edilen takas.
  static const proxyTimeout = Duration(seconds: 3);

  /// Hak bitince vekil bu kadar susar (her karar noktası sunucuyu yormasın).
  static const quotaPause = Duration(hours: 6);
  static const cacheTtl = Duration(minutes: 5);
  static const cacheSize = 32;
  static const maxQuestions = 60;

  // ponytail: bellek içi LRU; kalıcı önbellek (AiCache) ölçüm gösterirse.
  final _cache = <String, (DateTime, Map<String, DecisionAnswer>)>{};
  DateTime? _pausedUntil;

  DecisionMode modeOf(String feature) => AiDecisionsFlag.modeOf(feature);

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
    final paused = _pausedUntil;
    if (paused != null && now.isBefore(paused)) return null;
    String? apiKey;
    try {
      apiKey = await key();
    } on GeminiException {
      // AI kapalı / kill switch / rıza yok — ya da Play katmanı dahili
      // AI'a yetmiyor (ömür boyu, anahtarsız): vekil kendi kapısını yine
      // geçer; vekil yoksa ağ yok.
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
      return answers;
    } on JsonHttpException catch (e) {
      final code = e.response?.statusCode;
      if (code == 429 || (code != null && code >= 500)) {
        _pausedUntil = now.add(const Duration(minutes: 1));
      }
      _fallback(feature, 'http ${code ?? e.message}', sw);
    } on DecisionQuotaExhausted {
      _pausedUntil = now.add(quotaPause);
      _fallback(feature, 'quota', sw);
    } on GeminiException {
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
