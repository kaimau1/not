/// **TEKRARLANAN DİKTE PARÇALARINI TEKE İNDİRME**
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-11-10: "sesle yazarken cümle bir kez
/// yazılıyor, sonra bir daha yazılıyor; bazen fazla klon geri siliniyor,
/// bazen silinmiyor"): Android tanıyıcısı kısa bir duraklamada
/// `onEndOfSpeech` deyip AYNI sesi yeniden yazıya döküyor — yeni ara sonuç
/// önceki cümleyi baştan tekrar ediyor. Yerli taraf (MainActivity) bunu yeni
/// segment sayıp önceki cümleyi kalıcı yapıyor ve tekrarı ALT SATIRA
/// ekliyordu: `"X\nX"`. Final sonuç birebir aynı gelirse yerli birleştirme
/// klonu geri alıyordu ("bazen siliniyor"); bir kelimesi farklı ya da kısa
/// gelirse klon kalıyordu ("bazen silinmiyor"). Üstelik editör kısalan metni
/// yok saydığı için (bkz. `dictationMerge`) geri alınan klon ekranda kalıyordu.
///
/// Kural: ardışık iki parçadan biri ötekinin baş kısmının tekrarıysa (küçük
/// harf, noktalama yok; son kelime yarım olabilir) ya da kelimelerinin büyük
/// çoğunluğu aynı sırada aynıysa TEK parça kalır — uzun olan.
String collapseRepeatedSegments(String text) {
  if (!text.contains('\n')) return text;
  final out = <String>[];
  for (final raw in text.split('\n')) {
    final part = raw.trim();
    if (part.isEmpty) continue;
    if (out.isNotEmpty) {
      switch (_repeat(out.last, part)) {
        case _Repeat.dropNext:
          continue;
        case _Repeat.replacePrev:
          out[out.length - 1] = part;
          continue;
        case _Repeat.none:
          break;
      }
    }
    out.add(part);
  }
  return out.join('\n');
}

/// Yazılmış metnin [shown] sonundaki kuyruk, yeni metin [next] içinde zaten
/// varsa (yerli taraf klonu sonradan geri aldı) true. Editör kısalmayı ancak
/// bu durumda kabul eder.
bool droppedTailIsRepeat(String shown, String next) {
  if (!shown.startsWith(next)) return false;
  final tail = speechWords(shown.substring(next.length));
  if (tail.length < 3) return false;
  final words = speechWords(next);
  for (var i = 0; i + tail.length <= words.length; i++) {
    var same = true;
    for (var j = 0; j < tail.length && same; j++) {
      same = words[i + j] == tail[j];
    }
    if (same) return true;
  }
  return false;
}

enum _Repeat { none, dropNext, replacePrev }

final _punct = RegExp(r'''[.,;:!?…"'“”‘’()\-]''');

List<String> speechWords(String s) => s
    .toLowerCase()
    .replaceAll(_punct, ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

_Repeat _repeat(String prev, String next) {
  final a = speechWords(prev);
  final b = speechWords(next);
  if (a.isEmpty || b.isEmpty) return _Repeat.none;
  // Tek-iki kelimelik "evet … evet" gerçek bir tekrar olabilir; dokunulmaz.
  if (b.length <= a.length && a.length >= 3 && _prefixLike(b, a)) {
    return _Repeat.dropNext;
  }
  if (a.length < b.length && a.length >= 2 && _prefixLike(a, b)) {
    return _Repeat.replacePrev;
  }
  // Yeniden dökümde bir-iki kelime farklı çıkabilir ("şeyleri" → "şeylere").
  final m = a.length < b.length ? a.length : b.length;
  if (m >= 4 && a.first == b.first) {
    var same = 0;
    for (var i = 0; i < m; i++) {
      if (a[i] == b[i]) same++;
    }
    if (same / m >= 0.75) {
      return b.length >= a.length ? _Repeat.replacePrev : _Repeat.dropNext;
    }
  }
  return _Repeat.none;
}

/// [short] kelimeleri [long]un başıyla aynı mı (son kelime yarım olabilir).
bool _prefixLike(List<String> short, List<String> long) {
  for (var i = 0; i < short.length; i++) {
    final last = i == short.length - 1;
    if (short[i] == long[i]) continue;
    if (last && long[i].startsWith(short[i])) continue;
    return false;
  }
  return true;
}
