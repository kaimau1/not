/// Cihaz tanıyıcısından gelen dökümün segment sınırındaki YİNELENEN
/// kelimelerini temizler.
///
/// KÖK NEDEN: Android tanıyıcısı kısa duraklamalarda oturumu kapatıp yeniden
/// başlatıyor. Köprü (MainActivity), "yeni ara sonuç önceki segmentin devamı
/// mı?" sorusunda KARARSIZ kaldığında bilerek "devamı değil" der ve o ana
/// kadarki metni kalıcı yapar — konuşulanı kaybetmektense bir kelimeyi
/// tekrarlamak yeğdir. Bedeli, dökümün sınırında görünen tekrar
/// ("... eldiven eldiven 558 blade").
///
/// Burada o bedel geri alınır: segmentler `\n` ile birleştirildiğinden tekrar
/// HER ZAMAN satır sınırındadır. Bir önceki satırın SONU ile yeni satırın
/// BAŞI aynı kelimelerle başlıyorsa, o kelimeler yeni satırın başından
/// düşürülür. Kelime sınırında çalışır (kelimenin bir parçası atılmaz) ve
/// yalnızca sınıra bakar: cümlenin ortasında gerçekten iki kez söylenmiş bir
/// kelimeye ("çok çok iyi") dokunmaz.
String dedupeSpeechSegments(String text) {
  if (!text.contains('\n')) return text;
  final out = <String>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (out.isEmpty) {
      out.add(line);
      continue;
    }
    final rest = _withoutRepeatedHead(out.last, line);
    // Satırın TAMAMI önceki satırın tekrarıysa satır tümüyle düşer.
    if (rest.isNotEmpty) out.add(rest);
  }
  return out.join('\n');
}

/// [next]'in başındaki, [previous]'ın sonuyla ÖRTÜŞEN kelimeler atılmış hâli;
/// tümü örtüşüyorsa boş dize.
String _withoutRepeatedHead(String previous, String next) {
  final prevWords = previous.split(RegExp(r'\s+'));
  final nextWords = next.split(RegExp(r'\s+'));
  // En uzun örtüşmeden başlanır: iki kelimelik tekrarda yalnız ikincisini
  // atmak ilkini yerinde bırakırdı. Tavan 6 kelime — daha uzun örtüşme
  // tanıyıcı tekrarı değil, kullanıcının gerçekten yinelediği bir cümledir.
  var maxOverlap = prevWords.length < nextWords.length
      ? prevWords.length
      : nextWords.length;
  if (maxOverlap > 6) maxOverlap = 6;
  for (var n = maxOverlap; n >= 1; n--) {
    final tail = prevWords.sublist(prevWords.length - n).join(' ');
    final head = nextWords.sublist(0, n).join(' ');
    if (_sameWords(tail, head)) {
      return nextWords.sublist(n).join(' ').trim();
    }
  }
  return next;
}

/// Karşılaştırma büyük/küçük harf ve sondaki noktalamadan bağımsızdır:
/// tanıyıcı aynı kelimeyi bir turda "Eldiven", ötekinde "eldiven," yazabiliyor.
bool _sameWords(String a, String b) => _normalize(a) == _normalize(b);

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+'), '').trim();
