import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/net/json_http.dart';
import '../../../core/play_build.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../notes/domain/list_mode.dart';
import '../../notes/domain/text_item_extractor.dart';
import '../../settings/settings_providers.dart' show sharedPreferencesProvider;
import 'ai_policy.dart';
import 'ai_provider.dart';
import 'api_key_store.dart';

/// Tek bir liste AI işleminin sonucu (başarılı AI, önbellek veya 0-kredi yerel yedek).
@immutable
class ListAiResult<T> {
  const ListAiResult({
    required this.items,
    this.usedAi = false,
    this.usedFallback = false,
    this.quotaReached = false,
    this.fromCache = false,
  });

  final List<T> items;
  final bool usedAi;
  final bool usedFallback;
  final bool quotaReached;
  final bool fromCache;
}

/// Dış AI çağrı soyutlaması (sunucu `sharedAiPoolGenerate` veya BYOK Gemini).
typedef ListAiRemoteInvoker = Future<String?> Function({
  required String taskProfile,
  required String prompt,
  required int maxOutputTokens,
});

/// **KOTA KONTROLLÜ LİSTE YAPAY ZEKÂ SERVİSİ** (Faz 3):
///
/// Yalnız iki bilinçli kullanıcı aksiyonunda devreye girer:
/// 1. Proje kipinde tek görevi 3–5 alt adıma bölme (`list_breakdown`),
/// 2. "Metinden ayıkla" levhasında kullanıcının açıkça "Yapay zekâ ile netleştir"
///    düğmesine basması (`list_extract`).
///
/// Kota & gizlilik korumaları:
/// - Kilitli notlar ASLA ağa gönderilmez.
/// - Daima en ucuz model (`gemini-2.5-flash-lite`, 1 kredi) ve `<= 350` çıkış jetonu.
/// - Günlük istemci yumuşak sınırı: ücretsiz 5/gün, Tam Sürüm/Pro 25/gün, BYOK sınırsız.
/// - SHA-256 içerik önbelleği: alt adım bölme 7 gün, metin ayıklama 24 saat (0 kredi).
/// - 6 saniyelik zaman aşımı; çevrimdışı/kota dolu/hata hâlinde 0 kredilik yerel
///   yedek sonuç döner (kullanıcı hiçbir zaman engellenmez).
class ListAiService {
  ListAiService({
    required this.prefs,
    required this.remoteInvoker,
    required this.isPro,
    required this.readOwnKey,
    required this.isAiAllowed,
    required this.isSignedInNonAnonymous,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const modelId = 'gemini-2.5-flash-lite';
  static const maxPromptChars = 2500;
  static const maxOutputTokens = 350;
  static const dailyLimitFree = 5;
  static const dailyLimitPro = 25;
  static const requestTimeout = Duration(seconds: 6);
  static const breakdownCacheTtl = Duration(days: 7);
  static const extractCacheTtl = Duration(hours: 24);
  static const _quotaPrefsKey = 'list_ai_daily_quota_v1';
  static const _cachePrefsKey = 'list_ai_cache_v1';
  static const _maxCacheEntries = 60;

  final SharedPreferences prefs;
  final ListAiRemoteInvoker remoteInvoker;
  final bool Function() isPro;
  final Future<String?> Function() readOwnKey;
  final bool Function() isAiAllowed;
  final bool Function() isSignedInNonAnonymous;
  final DateTime Function() _clock;

  /// Günlük kalan yerel kota hakkı (BYOK varsa null = sınırsız).
  int? remainingDailyQuota({bool hasOwnKey = false}) {
    if (hasOwnKey) return null;
    final limit = isPro() ? dailyLimitPro : dailyLimitFree;
    final used = _readDailyUsage();
    return (limit - used).clamp(0, limit);
  }

  /// Tek bir proje görevini 3–5 uygulanabilir alt adıma böler.
  Future<ListAiResult<String>> breakdownTask(
    String taskText, {
    required String locale,
    String? listTitle,
    bool noteLocked = false,
  }) async {
    final trimmed = taskText.trim();
    if (trimmed.isEmpty) {
      return const ListAiResult(items: [], usedFallback: true);
    }
    final fallback = localBreakdownFallback(trimmed, locale: locale);
    if (noteLocked || !isAiAllowed()) {
      return ListAiResult(items: fallback, usedFallback: true);
    }

    final cacheKey = _hashKey('bd|$locale|${listTitle ?? ''}|$trimmed');
    final cached = _readCache(cacheKey, ttl: breakdownCacheTtl);
    if (cached != null && cached.isNotEmpty) {
      return ListAiResult(items: cached, usedAi: true, fromCache: true);
    }

    final ownKey = (await readOwnKey())?.trim();
    final hasOwnKey = ownKey != null && ownKey.isNotEmpty;
    if (!hasOwnKey && !isSignedInNonAnonymous()) {
      return ListAiResult(items: fallback, usedFallback: true);
    }
    if (!hasOwnKey && !_hasDailyQuota()) {
      return ListAiResult(
        items: fallback,
        usedFallback: true,
        quotaReached: true,
      );
    }

    final prompt = _buildBreakdownPrompt(
      trimmed,
      locale: locale,
      listTitle: listTitle,
    );
    try {
      final raw = await remoteInvoker(
        taskProfile: 'list_breakdown',
        prompt: prompt,
        maxOutputTokens: maxOutputTokens,
      ).timeout(requestTimeout);
      final parsed = _parseStringArray(raw);
      if (parsed.isNotEmpty) {
        final steps = parsed.take(5).toList();
        if (!hasOwnKey) await _incrementDailyUsage();
        await _writeCache(cacheKey, steps);
        return ListAiResult(items: steps, usedAi: true);
      }
    } on _DailyQuotaExceededError {
      return ListAiResult(
        items: fallback,
        usedFallback: true,
        quotaReached: true,
      );
    } catch (_) {
      // Ağ / zaman aşımı / parse hatasında sessizce yerel yedeğe düş.
    }
    return ListAiResult(items: fallback, usedFallback: true);
  }

  /// Karmaşık mesaj / tarif metninden temiz liste maddeleri çıkarır.
  Future<ListAiResult<ExtractedItemDraft>> extractItems(
    String rawText, {
    required ListMode mode,
    required String locale,
    Map<String, int> learnedGroups = const {},
    bool noteLocked = false,
  }) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return const ListAiResult(items: [], usedFallback: true);
    }
    final clipped = trimmed.length > maxPromptChars - 400
        ? trimmed.substring(0, maxPromptChars - 400)
        : trimmed;
    final fallback = TextItemExtractor.extractLocal(
      clipped,
      mode: mode,
      locale: locale,
      learnedGroups: learnedGroups,
      now: _clock(),
    );
    if (noteLocked || !isAiAllowed()) {
      return ListAiResult(items: fallback, usedFallback: true);
    }

    final cacheKey = _hashKey('ex|$locale|${mode.name}|$clipped');
    final cached = _readCache(cacheKey, ttl: extractCacheTtl);
    if (cached != null && cached.isNotEmpty) {
      final drafts = TextItemExtractor.fromCleanLines(
        cached,
        mode: mode,
        locale: locale,
        learnedGroups: learnedGroups,
        now: _clock(),
      );
      if (drafts.isNotEmpty) {
        return ListAiResult(items: drafts, usedAi: true, fromCache: true);
      }
    }

    final ownKey = (await readOwnKey())?.trim();
    final hasOwnKey = ownKey != null && ownKey.isNotEmpty;
    if (!hasOwnKey && !isSignedInNonAnonymous()) {
      return ListAiResult(items: fallback, usedFallback: true);
    }
    if (!hasOwnKey && !_hasDailyQuota()) {
      return ListAiResult(
        items: fallback,
        usedFallback: true,
        quotaReached: true,
      );
    }

    final prompt = _buildExtractPrompt(clipped, mode: mode, locale: locale);
    try {
      final raw = await remoteInvoker(
        taskProfile: 'list_extract',
        prompt: prompt,
        maxOutputTokens: maxOutputTokens,
      ).timeout(requestTimeout);
      final lines = _parseStringArray(raw);
      if (lines.isNotEmpty) {
        final drafts = TextItemExtractor.fromCleanLines(
          lines,
          mode: mode,
          locale: locale,
          learnedGroups: learnedGroups,
          now: _clock(),
        );
        if (drafts.isNotEmpty) {
          if (!hasOwnKey) await _incrementDailyUsage();
          await _writeCache(cacheKey, lines);
          return ListAiResult(items: drafts, usedAi: true);
        }
      }
    } on _DailyQuotaExceededError {
      return ListAiResult(
        items: fallback,
        usedFallback: true,
        quotaReached: true,
      );
    } catch (_) {
      // Hata hâlinde yerel ayıklamaya düş.
    }
    return ListAiResult(items: fallback, usedFallback: true);
  }

  /// 0 kredilik deterministik yerel alt adım üreteci (çevrimdışı / kota dolu).
  static List<String> localBreakdownFallback(
    String taskText, {
    String locale = 'tr',
  }) {
    final clean = taskText.trim();
    if (clean.isEmpty) return const [];
    final isTr = locale.toLowerCase().startsWith('tr');
    final lower = clean.toLowerCase();

    // Görevde virgül / "ve" / "+" ile ayrılmış açık parçalar varsa onları alt
    // adım yap.
    final explicitParts = clean
        .split(RegExp(r'\s*(?:,|;|\+|/)\s*'))
        .map((s) => s.trim())
        .where((s) => s.length >= 3)
        .toList();
    if (explicitParts.length >= 2 && explicitParts.length <= 5) {
      return explicitParts;
    }

    if (isTr) {
      if (lower.contains('sunum') ||
          lower.contains('rapor') ||
          lower.contains('yaz')) {
        return [
          'Ana başlıkları ve kapsamı çıkar',
          'İlk taslağı hazırla',
          'Verileri ve görselleri ekle',
          'Son kontrolü yap ve paylaş',
        ];
      }
      if (lower.contains('toplant') || lower.contains('görüşme')) {
        return [
          'Gündem maddelerini belirle',
          'Gerekli belgeleri hazırla',
          'Notları ve sonraki adımları kaydet',
        ];
      }
      if (lower.contains('fatura') ||
          lower.contains('ödeme') ||
          lower.contains('başvur')) {
        return [
          'Gerekli belgeleri ve bilgileri topla',
          'İşlemi tamamla',
          'Onay / dekontu kaydet',
        ];
      }
      return [
        'Kapsamı ve ilk adımı netleştir',
        'Ana çalışmayı tamamla',
        'Son kontrolü yap ve kapat',
      ];
    }

    return [
      'Clarify scope and requirements',
      'Complete main draft / work',
      'Review and finalize',
    ];
  }

  String _todayKey() => isoDayKeyOf(_clock());

  int _readDailyUsage() {
    final raw = prefs.getString(_quotaPrefsKey);
    if (raw == null || raw.isEmpty) return 0;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['day'] == _todayKey() && map['count'] is num) {
        return (map['count'] as num).toInt().clamp(0, 1000);
      }
    } catch (_) {}
    return 0;
  }

  bool _hasDailyQuota() {
    final limit = isPro() ? dailyLimitPro : dailyLimitFree;
    return _readDailyUsage() < limit;
  }

  Future<void> _incrementDailyUsage() async {
    final next = _readDailyUsage() + 1;
    await prefs.setString(
      _quotaPrefsKey,
      jsonEncode({'day': _todayKey(), 'count': next}),
    );
  }

  String _hashKey(String raw) =>
      sha256.convert(utf8.encode(raw)).toString().substring(0, 24);

  List<String>? _readCache(String key, {required Duration ttl}) {
    final raw = prefs.getString(_cachePrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = map[key];
      if (entry is! Map) return null;
      final ts = entry['ts'];
      final items = entry['v'];
      if (ts is! num || items is! List) return null;
      final ageMs = _clock().millisecondsSinceEpoch - ts.toInt();
      if (ageMs < 0 || ageMs > ttl.inMilliseconds) return null;
      return [
        for (final s in items)
          if (s is String && s.trim().isNotEmpty) s.trim(),
      ];
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<String> values) async {
    final nowMs = _clock().millisecondsSinceEpoch;
    final map = <String, dynamic>{};
    final raw = prefs.getString(_cachePrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        map.addAll(decoded);
      } catch (_) {}
    }
    map[key] = {'ts': nowMs, 'v': values};
    if (map.length > _maxCacheEntries) {
      final entries = map.entries.toList()
        ..sort((a, b) {
          final ta = (a.value is Map && a.value['ts'] is num)
              ? (a.value['ts'] as num).toInt()
              : 0;
          final tb = (b.value is Map && b.value['ts'] is num)
              ? (b.value['ts'] as num).toInt()
              : 0;
          return ta.compareTo(tb);
        });
      for (final e in entries.take(map.length - _maxCacheEntries)) {
        map.remove(e.key);
      }
    }
    await prefs.setString(_cachePrefsKey, jsonEncode(map));
  }

  static String _buildBreakdownPrompt(
    String task, {
    required String locale,
    String? listTitle,
  }) {
    final lang = locale.toLowerCase().startsWith('tr') ? 'Turkish' : locale;
    final ctx = listTitle != null && listTitle.trim().isNotEmpty
        ? 'List title: "${listTitle.trim()}".\n'
        : '';
    return 'Break down this task into 3 to 5 short, concrete checklist sub-steps in $lang.\n'
        '${ctx}Task: "$task"\n'
        'Return ONLY a JSON array of short strings (each <= 60 chars), no markdown or extra text.';
  }

  static String _buildExtractPrompt(
    String text, {
    required ListMode mode,
    required String locale,
  }) {
    final lang = locale.toLowerCase().startsWith('tr') ? 'Turkish' : locale;
    return 'Extract clean checklist items in $lang for a ${mode.name} list from the text below.\n'
        'Keep quantities, units, prices or dates if mentioned. Omit greetings and chatter.\n'
        'Return ONLY a JSON array of short item strings (max 25 items), no markdown.\n'
        'Text:\n$text';
  }

  static List<String> _parseStringArray(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    var text = raw.trim();
    // Kod çiti varsa ayıkla (```json [...] ```).
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start >= 0 && end > start) {
        final decoded = jsonDecode(text.substring(start, end + 1));
        if (decoded is List) {
          return [
            for (final e in decoded)
              if (e is String && e.trim().isNotEmpty) e.trim(),
          ];
        }
      }
    } catch (_) {
      // JSON gelmediyse düz satırlara böl.
    }
    return [
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty)
          line.trim().replaceFirst(RegExp(r'^(?:[-*•]|\d+[.)])\s*'), '').trim(),
    ].where((s) => s.length >= 2).toList();
  }
}

class _DailyQuotaExceededError implements Exception {
  const _DailyQuotaExceededError();
}

/// Uygulama genelinde [ListAiService] sağlayıcısı.
final listAiServiceProvider = Provider<ListAiService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final keyStore = ref.watch(apiKeyStoreProvider);

  Future<String?> invokeRemote({
    required String taskProfile,
    required String prompt,
    required int maxOutputTokens,
  }) async {
    // 1. Kullanıcının kendi Gemini anahtarı (BYOK) varsa doğrudan onu kullan.
    final ownKey = (await keyStore.read())?.trim();
    if (ownKey != null && ownKey.isNotEmpty) {
      final httpClient = JsonHttp(
        baseUrl: AiProvider.gemini.baseUrl,
        receiveTimeout: ListAiService.requestTimeout,
      );
      final res = await httpClient.post<Map<String, dynamic>>(
        '/models/${ListAiService.modelId}:generateContent',
        headers: {
          'content-type': 'application/json',
          ...AiProvider.gemini.authHeaders(ownKey),
        },
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': maxOutputTokens,
            'responseMimeType': 'application/json',
          },
        },
        timeout: ListAiService.requestTimeout,
      );
      final candidates = res.data?['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = (candidates.first as Map?)?['content'];
        final parts = (content as Map?)?['parts'];
        if (parts is List) {
          return parts
              .map((p) => (p is Map && p['text'] is String) ? p['text'] : '')
              .join()
              .trim();
        }
      }
      return null;
    }

    // 2. Ortak AI havuzu (`sharedAiPoolGenerate`) — yalnız Play/sunucu geçidi.
    if (!PlayBuild.enabled) return null;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sharedAiPoolGenerate',
        options: HttpsCallableOptions(timeout: ListAiService.requestTimeout),
      );
      final response = await callable.call<Map<String, dynamic>>({
        'appId': 'notlar',
        'model': ListAiService.modelId,
        'taskProfile': taskProfile,
        'prompt': prompt,
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': maxOutputTokens,
          'responseMimeType': 'application/json',
        },
      });
      final text = response.data['text'];
      return text is String ? text : null;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted' &&
          (e.message?.contains('daily-quota') == true ||
              e.message?.contains('insufficient-credits') == true)) {
        throw const _DailyQuotaExceededError();
      }
      return null;
    }
  }

  return ListAiService(
    prefs: prefs,
    remoteInvoker: invokeRemote,
    isPro: () {
      final ent = ref.read(entitlementProvider).value ?? Entitlement.none;
      return ent.hasFullVersion;
    },
    readOwnKey: keyStore.read,
    isAiAllowed: () =>
        !ref.read(aiTurnedOffProvider) &&
        !ref.read(aiKillSwitchProvider) &&
        ref.read(aiConsentProvider),
    isSignedInNonAnonymous: () {
      try {
        final user = FirebaseAuth.instance.currentUser;
        return user != null && !user.isAnonymous;
      } catch (_) {
        return false;
      }
    },
  );
});
