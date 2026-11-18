import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error_log.dart';
import '../../../../core/net/json_http.dart';
import '../ai_policy.dart' show AiRateLimiter;
import '../ai_provider.dart';
import '../gemini_service.dart';
import 'decision_flag.dart';
import 'decision_models.dart';

final decisionServiceProvider = Provider<DecisionService>(
  (ref) => DecisionService(
    key: ref.watch(geminiServiceProvider).admittedDecisionKey,
  ),
);

/// **TEK DECISIONS SERVİSİ** (DA-E1, plan §4.2). REST `POST /v1beta/decisions`
/// (Dart SDK yok). Hiçbir durumda istisna atmaz: kullanılamıyorsa null döner
/// ve çağıran BUGÜNKÜ yoluna düşer. Sıra:
///  1. bayrak ([AiDecisionsFlag]) özelliği kapalıysa ağ yok;
///  2. [key]: [GeminiService.admittedDecisionKey] — `AiAdmission` kapıları
///     (AI'ı kapat, `aiKillSwitch`, Play rızası) ondan geçer; anahtarsız
///     dahili kipte vekil (`decide` Function, DA-E3) YOK → null;
///  3. kendi hız sınırı (K8: arka plan kararları elle yapılan AI isteklerinin
///     dakikalık hakkını yemesin); 429/5xx sonrası kısa bekleme;
///  4. kısa önbellek (aynı girdi + sorular, [cacheTtl]);
///  5. zaman aşımı [timeout] (≤ 1,5 sn) → null.
class DecisionService {
  DecisionService({
    required this.key,
    JsonHttp? http,
    this.timeout = const Duration(milliseconds: 1500),
    DateTime Function()? now,
  }) : _http = http ?? JsonHttp(baseUrl: AiProvider.gemini.baseUrl),
       _now = now ?? DateTime.now;

  /// İzinli anahtar ([GeminiService.admittedDecisionKey]).
  final Future<String?> Function() key;
  final JsonHttp _http;
  final DateTime Function() _now;
  final Duration timeout;

  final limiter = AiRateLimiter();

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
    final String? apiKey;
    try {
      apiKey = await key();
    } on GeminiException {
      return null; // AI kapalı / kill switch / rıza yok: ağ yok.
    }
    if (apiKey == null || apiKey.isEmpty) return null;
    if (!limiter.tryAcquire(now)) return null;
    final sw = Stopwatch()..start();
    try {
      final res = await _http
          .post<Map<String, dynamic>>(
            '/decisions',
            headers: AiProvider.gemini.authHeaders(apiKey),
            data: {
              'model': model,
              'input': [
                {'type': 'text', 'text': input},
              ],
              'questions': qs,
            },
            timeout: timeout,
          )
          .timeout(timeout);
      final answers = parseDecisionResponse(res.data, questions);
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
