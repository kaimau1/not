import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';

/// Günde bir kez otomatik üretilen, sonucu diske (SharedPreferences) yazılan
/// AI çıktıları (önemli e-postalar, öneriler, haftalık özet, brifing) için
/// ortak taban.
///
/// Davranış:
/// - autoDispose DEĞİL: ekranlar arası gezinmede canlı kalır; bir ekrandan
///   çıkıp başkasına geçince tarama arka planda sürer ve biten sonuç saklanır.
/// - Uygulama yeniden açılışında son sonuç diskten okunur ("hep görünür").
/// - Aynı güne ait önbellek varsa yeniden ÜRETİLMEZ (sadece gösterilir);
///   gün değişince ilk girişte otomatik yenilenir.
/// - [refresh] (Yenile düğmesi) her koşulda yeniden üretir.
abstract class DailyCacheNotifier<T> extends AsyncNotifier<T> {
  /// Sonucun yazılacağı SharedPreferences anahtarı (tarih ayrı anahtara).
  String get cacheKey;

  /// Sonucu bu gün için üretir (AI çağrısı burada yapılır).
  Future<T> compute();

  /// [T] ↔ String dönüşümü (SharedPreferences yalnızca string tutar).
  String encode(T value);
  T decode(String raw);

  String get _dateKey => '${cacheKey}_date';

  @override
  Future<T> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedValue = prefs.getString(cacheKey);
    final storedDate = prefs.getString(_dateKey);
    if (storedValue != null && storedDate == _todayStamp()) {
      try {
        return decode(storedValue);
      } catch (_) {
        // Bozuk/eski biçimli önbellek → yeniden üret.
      }
    }
    return _computeAndStore();
  }

  Future<T> _computeAndStore() async {
    final value = await compute();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(cacheKey, encode(value));
    await prefs.setString(_dateKey, _todayStamp());
    return value;
  }

  /// "Yenile" düğmesi: önbelleği yok sayıp hemen yeniden üretir.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_computeAndStore);
  }
}

/// Yerel gün damgası (YYYY-M-D) — aynı gün karşılaştırması için.
String _todayStamp() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
