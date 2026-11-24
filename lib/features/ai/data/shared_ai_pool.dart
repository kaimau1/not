import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/settings_providers.dart';
import 'ai_provider.dart';
import 'api_key_store.dart';

/// Yapay zekâ isteklerinin hangi kaynaktan karşılanacağı.
///
/// Açık geçiş zorunludur: kullanıcı [AiSourceMode.byok] seçtiyse kendi API
/// anahtarı 401/403/429 verse bile sessizce [AiSourceMode.sharedPool]'a
/// geçilmez (0-fallback kuralı).
enum AiSourceMode {
  sharedPool,
  byok;

  static AiSourceMode fromId(String? raw, {required bool hasOwnKey}) =>
      switch (raw) {
        'byok' => AiSourceMode.byok,
        'sharedPool' => AiSourceMode.sharedPool,
        _ => hasOwnKey ? AiSourceMode.byok : AiSourceMode.sharedPool,
      };
}

enum SharedAiPoolErrorKind {
  unauthenticated,
  insufficientCredits,
  byokExhausted,
  rateLimited,
  unavailable,
}

class SharedAiPoolException implements Exception {
  const SharedAiPoolException(this.kind, [this.message = '']);

  final SharedAiPoolErrorKind kind;
  final String message;

  @override
  String toString() => 'SharedAiPoolException(${kind.name}: $message)';
}

/// 5 yedek anahtara kadar BYOK havuzu (slot 0 ana `ApiKeyStore`, slot 1..4
/// yedekler). Kota (429) / geçici hatada dış-anahtar × iç-model sırasıyla döner;
/// 401/403 anahtarı soğumaya alır.
class ByokKeyPool {
  ByokKeyPool([this._storage = const FlutterSecureStorage()]);

  static const int maxKeys = 5;
  static const String _cooldownPrefsKey = 'notlar_byok_cooldowns_v1';

  final FlutterSecureStorage _storage;
  final Map<String, int> _cooldownUntilMs = {};

  static String _slotStorageKey(AiProvider provider, int index) {
    if (index == 0) return ApiKeyStore.storageKey(provider);
    return '${provider.id}_api_key_backup_$index';
  }

  Future<List<String>> readKeys(AiProvider provider) async {
    final out = <String>[];
    for (var i = 0; i < maxKeys; i++) {
      final raw = (await _storage.read(key: _slotStorageKey(provider, i)))
          ?.trim();
      if (raw == null || raw.isEmpty || out.contains(raw)) continue;
      out.add(raw);
    }
    return out;
  }

  Future<void> saveBackupKey(AiProvider provider, int index, String key) async {
    if (index < 1 || index >= maxKeys) {
      throw RangeError.range(index, 1, maxKeys - 1, 'index');
    }
    final clean = key.trim();
    final k = _slotStorageKey(provider, index);
    if (clean.isEmpty) {
      await _storage.delete(key: k);
    } else {
      await _storage.write(key: k, value: clean);
    }
  }

  static String _slotId(String key, String model) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '${hash.toRadixString(16)}|$model';
  }

  bool isCooling(String key, String model, {DateTime? now}) {
    final until = _cooldownUntilMs[_slotId(key, model)];
    if (until == null) return false;
    return until > (now ?? DateTime.now()).millisecondsSinceEpoch;
  }

  void markFailure(
    String key,
    String model, {
    required int statusCode,
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final durationMs = switch (statusCode) {
      401 || 403 => const Duration(minutes: 30).inMilliseconds,
      404 => const Duration(hours: 12).inMilliseconds,
      429 => const Duration(minutes: 3).inMilliseconds,
      >= 500 && < 600 => const Duration(minutes: 2).inMilliseconds,
      _ => 0,
    };
    if (durationMs <= 0) return;
    _cooldownUntilMs[_slotId(key, model)] = ts + durationMs;
  }

  void markSuccess(String key, String model) {
    _cooldownUntilMs.remove(_slotId(key, model));
  }

  Future<void> saveCooldowns(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final active = <String, int>{
      for (final e in _cooldownUntilMs.entries)
        if (e.value > now) e.key: e.value,
    };
    await prefs.setString(_cooldownPrefsKey, jsonEncode(active));
  }

  void loadCooldowns(SharedPreferences prefs) {
    final raw = prefs.getString(_cooldownPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      _cooldownUntilMs.clear();
      for (final e in decoded.entries) {
        final until = (e.value as num?)?.toInt() ?? 0;
        if (until > now) _cooldownUntilMs['${e.key}'] = until;
      }
    } catch (_) {
      // Bozuk yerel kayıt yok sayılır.
    }
  }

  /// Dış-anahtar × iç-model sırasında soğumada olmayan aday çiftleri döner.
  List<({String key, String model})> orderedSlots({
    required List<String> keys,
    required List<String> models,
    DateTime? now,
  }) {
    final candidates = <({String key, String model})>[];
    for (final key in keys) {
      final cleanKey = key.trim();
      if (cleanKey.isEmpty) continue;
      for (final model in models) {
        if (!isCooling(cleanKey, model, now: now)) {
          candidates.add((key: cleanKey, model: model));
        }
      }
    }
    return candidates;
  }
}

@immutable
class SharedAiPoolState {
  const SharedAiPoolState({
    this.balance,
    this.starterGranted = false,
    this.apps = const ['notlar', 'dosya_okuyucu'],
    this.loading = false,
    this.error,
  });

  final int? balance;
  final bool starterGranted;
  final List<String> apps;
  final bool loading;
  final String? error;

  bool get knownEmpty => balance != null && balance! <= 0;

  SharedAiPoolState copyWith({
    int? balance,
    bool? starterGranted,
    List<String>? apps,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => SharedAiPoolState(
    balance: balance ?? this.balance,
    starterGranted: starterGranted ?? this.starterGranted,
    apps: apps ?? this.apps,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

typedef SharedPoolCallable = Future<Map<String, dynamic>> Function(
  String functionName,
  Map<String, dynamic> payload,
);

/// Ortak AI Havuzu istemcisi (Notlar + Dosyalarım tek Google hesabı).
class SharedAiPoolClient {
  SharedAiPoolClient({SharedPoolCallable? caller}) : _callFn = caller;

  static const String appId = 'notlar';
  static const int starterCredits = 500;

  final SharedPoolCallable? _callFn;
  int? _knownBalance;

  int? get knownBalance => _knownBalance;

  @visibleForTesting
  void setKnownBalanceForTest(int? balance) => _knownBalance = balance;

  /// Güvenlik kuralı: BYOK kipinde 401/403/429 gelirse havuza DÜŞÜLMEZ.
  static Never guardByokFailure({
    required AiSourceMode mode,
    required int statusCode,
  }) {
    if (mode == AiSourceMode.byok &&
        (statusCode == 401 || statusCode == 403 || statusCode == 429)) {
      throw SharedAiPoolException(
        SharedAiPoolErrorKind.byokExhausted,
        'status:$statusCode',
      );
    }
    throw SharedAiPoolException(
      SharedAiPoolErrorKind.unavailable,
      'status:$statusCode',
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final override = _callFn;
    if (override != null) return override(name, payload);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(name);
      final result = await callable.call<dynamic>(payload);
      final raw = result.data;
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) {
        return {for (final e in raw.entries) '${e.key}': e.value};
      }
      return const {};
    } on FirebaseFunctionsException catch (e) {
      throw switch (e.code) {
        'unauthenticated' || 'permission-denied' => const SharedAiPoolException(
          SharedAiPoolErrorKind.unauthenticated,
        ),
        'resource-exhausted' => SharedAiPoolException(
          e.message == 'rate-limited'
              ? SharedAiPoolErrorKind.rateLimited
              : SharedAiPoolErrorKind.insufficientCredits,
          e.message ?? '',
        ),
        _ => SharedAiPoolException(
          SharedAiPoolErrorKind.unavailable,
          e.message ?? '',
        ),
      };
    }
  }

  Future<SharedAiPoolState> fetchStatus() async {
    final data = await _invoke('sharedAiPoolStatus', const {'appId': appId});
    final bal = (data['balance'] as num?)?.toInt();
    _knownBalance = bal;
    final rawApps = data['apps'];
    final apps = rawApps is List
        ? [for (final a in rawApps) '$a']
        : const ['notlar', 'dosya_okuyucu'];
    return SharedAiPoolState(
      balance: bal,
      starterGranted: data['starterGranted'] == true,
      apps: apps,
    );
  }

  Future<({String text, int remainingCredits, int cost})> generate({
    required AiSourceMode mode,
    required List<Map<String, dynamic>> contents,
    String model = 'gemini-2.5-flash',
    Map<String, dynamic>? generationConfig,
  }) async {
    // BYOK kipinde ortak havuz asla fallback olarak kullanılmaz.
    if (mode != AiSourceMode.sharedPool) {
      throw const SharedAiPoolException(
        SharedAiPoolErrorKind.byokExhausted,
        'byok-mode-no-fallback',
      );
    }
    // 0-bakiye koruma duvarı: bilinen bakiye <= 0 ise HİÇ ağ isteği atılmaz.
    if (_knownBalance != null && _knownBalance! <= 0) {
      throw const SharedAiPoolException(
        SharedAiPoolErrorKind.insufficientCredits,
        'cached-zero-balance',
      );
    }
    try {
      final data = await _invoke('sharedAiPoolGenerate', {
        'appId': appId,
        'model': model,
        'contents': contents,
        'generationConfig': ?generationConfig,
      });
      final text = (data['text'] as String? ?? '').trim();
      final rem =
          (data['remainingCredits'] as num?)?.toInt() ?? _knownBalance ?? 0;
      final cost = (data['cost'] as num?)?.toInt() ?? 1;
      _knownBalance = rem;
      return (text: text, remainingCredits: rem, cost: cost);
    } on SharedAiPoolException catch (e) {
      if (e.kind == SharedAiPoolErrorKind.insufficientCredits) {
        _knownBalance = 0;
      }
      rethrow;
    }
  }
}

final aiSourceModeProvider =
    NotifierProvider<AiSourceModeNotifier, AiSourceMode>(
      AiSourceModeNotifier.new,
    );

class AiSourceModeNotifier extends Notifier<AiSourceMode> {
  static const String prefsKey = 'ai_source_mode';

  @override
  AiSourceMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(prefsKey);
    final hasOwnKey = (ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty;
    return AiSourceMode.fromId(raw, hasOwnKey: hasOwnKey);
  }

  void set(AiSourceMode mode) {
    if (state == mode) return;
    state = mode;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(prefsKey, mode.name),
    );
  }
}

final sharedAiPoolClientProvider = Provider<SharedAiPoolClient>(
  (ref) => SharedAiPoolClient(),
);

final sharedAiPoolProvider =
    NotifierProvider<SharedAiPoolNotifier, SharedAiPoolState>(
      SharedAiPoolNotifier.new,
    );

class SharedAiPoolNotifier extends Notifier<SharedAiPoolState> {
  @override
  SharedAiPoolState build() => const SharedAiPoolState();

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await ref.read(sharedAiPoolClientProvider).fetchStatus();
      state = next;
    } on SharedAiPoolException catch (e) {
      state = state.copyWith(loading: false, error: e.kind.name);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  void applyRemaining(int remaining) {
    ref.read(sharedAiPoolClientProvider).setKnownBalanceForTest(remaining);
    state = state.copyWith(balance: remaining, clearError: true);
  }
}

final byokKeyPoolProvider = Provider<ByokKeyPool>((ref) => ByokKeyPool());

final byokKeysProvider = FutureProvider<List<String>>((ref) {
  final provider = ref.watch(activeProviderProvider);
  ref.watch(activeApiKeyProvider);
  return ref.watch(byokKeyPoolProvider).readKeys(provider);
});
