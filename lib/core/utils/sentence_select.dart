/// Metin alanlarında seçimi akıllıca genişletme: KELİME → TOKEN → CÜMLE.
///
/// Uzun basış (ve çift dokunuş) Flutter'da yalnızca altındaki KELİMEYİ seçer
/// ve kelime sınırı her noktalamada kesilir. Not uygulamasında bu iki ayrı
/// derdi vardı:
///
/// 1. Seçim çoğu zaman bir cümleyi taşımak/silmek/AI'a vermek için yapılıyor;
///    kullanıcı tutamakları elle çekmek zorunda kalıyordu ("yarım yamalak
///    seçiliyor"). Yeni açılan kelime seçimi kendiliğinden cümleye büyür.
/// 2. API anahtarı, URL, e-posta, sürüm numarası gibi NOKTALAMAYLA YAPIŞIK
///    token'lar çift dokunuşta paramparça seçiliyordu ("sk-abc.Xyz"in yalnız
///    "abc"si). Kelime böyle bir token'ın parçasıysa önce TOKEN'ın tamamı
///    seçilir; kullanıcı aynı kelimeye bir kez daha çift dokunursa cümleye
///    büyür.
///
/// Tutamaklarla daraltma korunur: seçim ÖNCEKİ seçimin içinde kalıyorsa
/// dokunulmaz — yoksa kullanıcı cümleden bir parça seçemezdi. (Cümleye
/// büyümüş seçime ikinci çift dokunuş da bu yoldan tek kelimeye iner.)
library;

import 'package:flutter/widgets.dart';

/// Cümleyi bitiren noktalama. Türkçede üç nokta tek karakter olarak da
/// gelebildiği için '…' ayrıca listede.
const String _terminators = '.!?…';

/// Sınırın İÇİNDE kalan kapatıcılar: `(bitti.)` ya da `"bitti."` gibi
/// durumlarda kapanış işareti cümleye dahildir.
const String _closers = ')]}»"\'’”';

/// Token seçiminde kenarlardan atılan sarmalayıcılar: `(https://x.com)` ya da
/// `"sk-abc",` seçilirken parantez/tırnak/virgül token'a dahil edilmez.
const String _tokenLeadingTrim = '([{<«"\'‘“';
const String _tokenTrailingTrim = ')]}>»"\'’”.,;:!?…';

/// Nokta ile biten ve cümleyi BİTİRMEYEN yaygın Türkçe kısaltmalar.
/// "bkz. yukarıdaki not" ya da "Dr. Ahmet" bir cümle sonu değildir; eskiden
/// cümle seçimi bu noktalarda kırılıyordu. Liste küçük harfle tutulur,
/// karşılaştırma Türkçe küçük harfe çevrilerek yapılır (İ→i, I→ı).
const Set<String> _abbreviations = {
  'vb.', 'vs.', 'vd.', 'bkz.', 'ör.', 'örn.', 'yy.', 'sn.', 'dk.', 'no.',
  'tel.', 'dr.', 'prof.', 'doç.', 'yrd.', 'öğr.', 'gör.', 'av.', 'hz.',
  'mah.', 'cad.', 'sok.', 'apt.', 'krş.', 'çev.', 'ed.', 'yay.', 'km.',
  'cm.', 'mm.', 'kg.', 'gr.', 'lt.', 'a.ş.', 'ltd.', 'şti.', 't.c.', 'st.',
};

bool _isSpace(String c) => c.trim().isEmpty;

String _lowerTr(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

/// Küçük HARF mi? (Rakam ve noktalamada büyük/küçük hâl aynı olduğundan
/// ikisi de false verir.)
bool _isLowerLetter(String c) => c.toUpperCase() != c && c.toLowerCase() == c;

/// [i] konumundaki noktadan geriye, boşluğa kadar olan sözcük (nokta hariç).
String _wordBefore(String text, int i) {
  var s = i;
  while (s > 0 && !_isSpace(text[s - 1])) {
    s--;
  }
  return text.substring(s, i);
}

/// Noktalama öbeğinden sonraki ilk boşluk-olmayan karakter; yoksa null.
String? _nextVisible(String text, int j) {
  var k = j;
  while (k < text.length && _isSpace(text[k])) {
    k++;
  }
  return k < text.length ? text[k] : null;
}

/// [i] konumunda gerçek bir cümle sonu varsa, sonun BİTTİĞİ konumu döndürür
/// (ardışık noktalama ve kapatıcılar dahil); yoksa null.
///
/// "3.5" ya da "vb.x" gibi yerlerde nokta cümle bitirmez: noktalama öbeğinin
/// ardından boşluk ya da metin sonu gelmelidir. Ek kurallar:
/// - Kısaltmalar ("bkz.", "Dr.", "T.C.") ve tek harf + nokta (ad baş harfi,
///   "A. Ahmet") cümleyi bitirmez.
/// - Sıra sayısı ("3. katta") ancak ardından KÜÇÜK harf geliyorsa bitirmez;
///   "Saat 5. Sonra çıktık." cümle sonudur.
/// - Üç nokta ("...", "…") ardından küçük harf geliyorsa duraksamadır,
///   cümle sonu değil ("olur mu... bilmiyorum").
int? _terminatorEnd(String text, int i) {
  if (!_terminators.contains(text[i])) return null;
  // Öbek yalnız İLK karakterinden yargılanır: "..."ün son noktası tek başına
  // değerlendirilse "bilmem..." sözcüğü kısaltma/üç nokta kurallarından
  // kaçıp cümleyi yanlış yerden bitiriyordu.
  if (i > 0 && _terminators.contains(text[i - 1])) return null;
  var j = i + 1;
  while (j < text.length && _terminators.contains(text[j])) {
    j++;
  }
  final punctuationEnd = j;
  while (j < text.length && _closers.contains(text[j])) {
    j++;
  }
  if (j < text.length && !_isSpace(text[j])) {
    // Kapatıcıları saydıktan sonra hâlâ harf geliyorsa öbek cümle sonu
    // değildir; kapatıcısız hâlini dene ("(a.b)" gibi).
    if (punctuationEnd < text.length && !_isSpace(text[punctuationEnd])) {
      return null;
    }
    return _refine(text, i, punctuationEnd, punctuationEnd);
  }
  return _refine(text, i, punctuationEnd, j);
}

/// Boşluk/satır-sonu koşulunu geçmiş öbeğe kısaltma, sıra sayısı ve üç nokta
/// kurallarını uygular; öbek yine de cümle sonuysa [end]'i döndürür.
int? _refine(String text, int i, int punctuationEnd, int end) {
  final cluster = text.substring(i, punctuationEnd);
  if (cluster == '.') {
    final word = _wordBefore(text, i);
    if (word.isNotEmpty) {
      // Tek harf + nokta: ad baş harfi ("A. Ahmet").
      if (word.length == 1 && !_isDigit(word)) return null;
      if (_abbreviations.contains('${_lowerTr(word)}.')) return null;
      // Sıra sayısı: "3. katta" sürer, "Saat 5. Sonra" biter.
      if (word.codeUnits.every((u) => u >= 0x30 && u <= 0x39)) {
        final next = _nextVisible(text, end);
        if (next != null && _isLowerLetter(next)) return null;
      }
    }
  } else if (!cluster.contains('!') && !cluster.contains('?')) {
    // Yalnız noktalardan oluşan öbek (üç nokta): küçük harfle süren metin
    // duraksamadır ("olur mu... bilmiyorum" tek cümledir).
    final next = _nextVisible(text, end);
    if (next != null && _isLowerLetter(next)) return null;
  }
  return end;
}

/// [offset] konumunu içeren cümlenin aralığı. Satır sonu da cümle sınırıdır:
/// listelerde ve başlıklarda nokta konmayan satırlar tek başına bir cümledir.
TextRange sentenceRangeAt(String text, int offset) {
  if (text.isEmpty) return const TextRange.collapsed(0);
  final pos = offset.clamp(0, text.length);

  var start = 0;
  for (var i = pos - 1; i >= 0; i--) {
    if (text[i] == '\n') {
      start = i + 1;
      break;
    }
    final end = _terminatorEnd(text, i);
    if (end != null && end <= pos) {
      start = end;
      break;
    }
  }
  while (start < pos && _isSpace(text[start])) {
    start++;
  }

  var end = text.length;
  for (var i = start; i < text.length; i++) {
    if (text[i] == '\n') {
      end = i;
      break;
    }
    final stop = _terminatorEnd(text, i);
    if (stop != null) {
      end = stop;
      break;
    }
  }
  while (end > start && _isSpace(text[end - 1])) {
    end--;
  }
  if (end < pos) end = pos;
  return TextRange(start: start, end: end);
}

/// [range] içindeki bir kelimenin parçası olduğu TOKEN'ın aralığı: boşluğa
/// kadar genişletilir, kenarlardaki sarmalayıcı noktalama (tırnak, parantez,
/// virgül, cümle sonu noktası) atılır.
///
/// "anahtar: sk-abc.Xyz_9 kaydet" içinde "abc" kelimesi → "sk-abc.Xyz_9".
/// Token kelimenin kendisiyse (çevresinde yapışık noktalama yoksa) aralık
/// olduğu gibi döner — çağıran bunu "token yok" diye yorumlar.
TextRange tokenRangeAt(String text, TextRange range) {
  var start = range.start;
  var end = range.end;
  while (start > 0 && !_isSpace(text[start - 1]) && text[start - 1] != '\n') {
    start--;
  }
  while (end < text.length && !_isSpace(text[end])) {
    end++;
  }
  // Kırpma döngüleri kelimenin sınırını aşamaz (koşul range'e bakar); yani
  // sonuç her zaman kelimeyi kapsar.
  while (start < range.start && _tokenLeadingTrim.contains(text[start])) {
    start++;
  }
  while (end > range.end && _tokenTrailingTrim.contains(text[end - 1])) {
    end--;
  }
  return TextRange(start: start, end: end);
}

/// [controller] üzerinde yeni açılan kelime seçimlerini akıllıca genişletir
/// (kelime → token → cümle; ayrıntı için kütüphane yorumuna bak).
///
/// Ayrı bir `dispose` gerekmez: dinleyici denetleyicinin kendisiyle birlikte
/// ölür (controller.dispose listeleri boşaltır).
void attachSentenceSelection(TextEditingController controller) {
  final expander = _SentenceExpander(controller);
  controller.addListener(expander.onChanged);
}

class _SentenceExpander {
  _SentenceExpander(this.controller);

  final TextEditingController controller;

  TextSelection? _previous;
  String? _previousText;

  /// Son otomatik genişletmenin döngü durumu: hangi kelimeden büyüdü, neye
  /// büyüdü ve token seviyesinde mi kaldı. Aynı kelimeye İKİNCİ çift dokunuş
  /// (Flutter yine baz kelimeyi seçer) token'dan cümleye tırmanmak için
  /// kullanılır.
  TextRange? _cycleWord;
  TextRange? _cycleExpanded;
  bool _cycleTokenLevel = false;

  /// Kendi yazdığımız seçimle tekrar tetiklenmemek için.
  bool _busy = false;

  void _apply(TextSelection selection) {
    _busy = true;
    controller.selection = selection;
    _previous = selection;
    _busy = false;
  }

  void onChanged() {
    if (_busy) return;
    final selection = controller.selection;
    final previous = _previous;
    _previous = selection;
    final text = controller.text;
    final previousText = _previousText;
    _previousText = text;
    if (!selection.isValid || selection.isCollapsed) return;
    if (selection.end > text.length) return;

    // KÖK NEDEN (v1.0.179): biçim uygulamak metni DEĞİŞTİRİR (işaretler
    // eklenir) ve seçimi programlı olarak yeni konumuna taşır. Kaydırılan
    // seçim "önceki seçimin içinde" kalmadığı için buradaki genişletme
    // devreye giriyor, kullanıcının seçtiği tek kelime kendiliğinden TÜM
    // SATIRA büyüyor ve bir sonraki boyut değişikliği satırın tamamına
    // uygulanıyordu. Genişletme yalnız METİN AYNIYKEN (yani seçim gerçekten
    // kullanıcı dokunuşuyla değiştiğinde) çalışır.
    if (previousText != null && previousText != text) {
      _cycleWord = null;
      _cycleExpanded = null;
      return;
    }

    if (previous != null &&
        !previous.isCollapsed &&
        selection.start >= previous.start &&
        selection.end <= previous.end) {
      // Token seviyesinde kalmış bir genişletmeden sonra AYNI baz kelime
      // yeniden seçildiyse bu, tutamak daraltması değil ikinci çift
      // dokunuştur: bir üst seviyeye (cümleye) çık.
      final word = _cycleWord;
      if (_cycleTokenLevel &&
          word != null &&
          previous.start == _cycleExpanded?.start &&
          previous.end == _cycleExpanded?.end &&
          selection.start == word.start &&
          selection.end == word.end) {
        final range = sentenceRangeAt(text, word.start);
        if (range.start < range.end &&
            range.start <= selection.start &&
            range.end >= selection.end) {
          _cycleExpanded = range;
          _cycleTokenLevel = false;
          _apply(
            TextSelection(baseOffset: range.start, extentOffset: range.end),
          );
        }
        return;
      }
      // Tutamakla daraltma/genişletme: kullanıcı bilerek küçültüyor, karışma.
      return;
    }

    // Yalnız TEK KELİMELİK seçimler büyütülür: uzun basış/çift dokunuş bunu
    // üretir. "Tümünü seç" ya da elle çekilmiş çok kelimeli seçim boşluk
    // içerdiğinden buraya girmez.
    final picked = text.substring(selection.start, selection.end);
    if (picked.isEmpty || picked.contains(RegExp(r'\s'))) return;

    final wordRange = TextRange(start: selection.start, end: selection.end);

    // Önce token: kelime noktalamayla yapışık bir bütünün (API anahtarı, URL,
    // e-posta, sürüm no) parçasıysa cümle yerine O BÜTÜN seçilir — "premium"
    // dokunuş tam burası: eskiden anahtarın yalnız bir parçası seçiliyor,
    // cümle genişletmesi de anahtarı komşu metinle birlikte yutuyordu.
    final token = tokenRangeAt(text, wordRange);
    if (token.start < wordRange.start || token.end > wordRange.end) {
      _cycleWord = wordRange;
      _cycleExpanded = token;
      _cycleTokenLevel = true;
      _apply(TextSelection(baseOffset: token.start, extentOffset: token.end));
      return;
    }

    final range = sentenceRangeAt(text, selection.start);
    if (range.start >= range.end) return;
    if (range.start == selection.start && range.end == selection.end) return;
    // Cümle, seçilen kelimeyi kapsamıyorsa (beklenmez) dokunma.
    if (range.start > selection.start || range.end < selection.end) return;

    _cycleWord = wordRange;
    _cycleExpanded = range;
    _cycleTokenLevel = false;
    _apply(TextSelection(baseOffset: range.start, extentOffset: range.end));
  }
}
