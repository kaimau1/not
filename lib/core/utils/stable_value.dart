/// Türetilmiş sağlayıcıların ÖNCEKİ sonucunu tutan kutu (F2.1).
///
/// Riverpod bir sağlayıcının izleyicilerini yalnız yeni değer `!=` eskisi
/// olduğunda uyandırır; liste/harita/küme ise `==`'yi kimlikle karşılaştırır.
/// Not akışının HER yayınında (editörde her otomatik kayıtta) yeni koleksiyon
/// dönen sağlayıcı, içerik aynı olsa da çip satırını, klasör rafını, arşivi
/// yeniden kurduruyordu. Kutu, içerik aynıysa ESKİ örneği geri verir.
///
/// Kutu, sahibi olan sağlayıcıyla aynı ömürde ayrı bir sağlayıcıda yaşar
/// (sağlayıcı gövdesi her yeniden çalışmada sıfırdan başlar).
class StableBox<T> {
  T? _last;
  bool _has = false;

  /// [next] içerikçe öncekine eşitse ([equals]) öncekini, değilse [next]'i
  /// döndürür ve saklar.
  T keep(T next, bool Function(T a, T b) equals) {
    final last = _last;
    if (_has && equals(last as T, next)) return last;
    _last = next;
    _has = true;
    return next;
  }
}

/// Elemanları SIRAYLA AYNI ÖRNEK olan listeler. Not akışı (artımlı önbellek)
/// değişmeyen `Note` örneklerini koruduğu için kimlik yeterli — `Note`'ta
/// `==` yok, alan alan karşılaştırma da gereksiz pahalı olurdu.
bool sameInstances<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

/// Elemanları sırayla `==` olan listeler (etiket adları gibi değer türleri).
bool sameValues<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Anahtar ve değerleri `==` olan haritalar.
bool sameMap<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

/// Aynı elemanları taşıyan kümeler.
bool sameSet<T>(Set<T> a, Set<T> b) =>
    identical(a, b) || (a.length == b.length && a.containsAll(b));
