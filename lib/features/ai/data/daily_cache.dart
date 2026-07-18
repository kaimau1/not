import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';
import 'ai_gate.dart';

/// Günde bir kez üretilen, sonucu diske (SharedPreferences) yazılan AI
/// çıktıları (önemli e-postalar, öneriler, haftalık özet, brifing) için
/// ortak taban.
///
/// Davranış:
/// - autoDispose DEĞİL: ekranlar arası gezinmede canlı kalır; bir ekrandan
///   çıkıp başkasına geçince tarama arka planda sürer ve biten sonuç saklanır.
/// - Uygulama yeniden açılışında son sonuç diskten okunur ("hep görünür").
/// - Aynı güne ait önbellek varsa yeniden ÜRETİLMEZ (sadece gösterilir).
/// - **Sınırsız kullanıcı** (BYOK/premium): önbellek bayatsa (yeni gün)
///   otomatik yeniden üretir; [refresh] her an zorlar.
/// - **Ücretsiz kullanıcı**: kotayı boşa harcamamak için OTOMATİK ÜRETMEZ.
///   İçerik yalnızca [generate] (düğme) ile, günde en fazla bir kez üretilir;
///   üretildikten sonra o gün tekrar üretilemez (yalnızca gösterilir).
abstract class DailyCacheNotifier<T> extends AsyncNotifier<T> {
  /// Sonucun yazılacağı SharedPreferences anahtarı (tarih ayrı anahtara).
  String get cacheKey;

  /// İçerik henüz üretilmemişken kullanılacak boş değer ('' veya const []).
  T get emptyValue;

  /// Sonucu bu gün için üretir (AI çağrısı burada yapılır).
  Future<T> compute();

  /// [T] ↔ String dönüşümü (SharedPreferences yalnızca string tutar).
  String encode(T value);
  T decode(String raw);

  String get _dateKey => '${cacheKey}_date';

  /// Bu içerik bugün üretildi mi? (Ücretsiz kullanıcıda "günde 1 kez" kilidi
  /// ve düğme durumu bununla belirlenir.)
  bool get generatedToday =>
      ref.read(sharedPreferencesProvider).getString(_dateKey) == _todayStamp();

  T? _tryDecode(String raw) {
    try {
      return decode(raw);
    } catch (_) {
      // Bozuk/eski biçimli önbellek.
      return null;
    }
  }

  @override
  Future<T> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final storedValue = prefs.getString(cacheKey);
    final isToday = prefs.getString(_dateKey) == _todayStamp();
    final cached = storedValue == null ? null : _tryDecode(storedValue);

    if (cached != null && isToday) return cached;

    // Sınırsız kullanıcıda yeni günde otomatik üret; ücretsizde üretme,
    // varsa eski sonucu göster, yoksa boş (kullanıcı düğmeyle üretir).
    if (ref.watch(aiUnlimitedProvider)) return _computeAndStore();
    return cached ?? emptyValue;
  }

  Future<T> _computeAndStore() async {
    final value = await compute();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(cacheKey, encode(value));
    await prefs.setString(_dateKey, _todayStamp());
    return value;
  }

  /// "Yenile"/"Oluştur" düğmesi. Sınırsız kullanıcıda her an yeniden üretir;
  /// ücretsiz kullanıcıda o gün henüz üretilmediyse üretir, üretildiyse
  /// hiçbir şey yapmaz (çağıran taraf kullanıcıyı bilgilendirir).
  Future<void> refresh() async {
    if (!ref.read(aiUnlimitedProvider) && generatedToday) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_computeAndStore);
  }
}

/// Yerel gün damgası (YYYY-M-D) — aynı gün karşılaştırması için.
String _todayStamp() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
