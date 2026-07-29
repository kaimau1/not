/// Metin alanlarında seçimi KELİMEden CÜMLEye genişletme.
///
/// Uzun basış (ve çift dokunuş) Flutter'da yalnızca altındaki KELİMEYİ seçer.
/// Not uygulamasında seçim neredeyse her zaman bir cümleyi taşımak/silmek/AI'a
/// vermek için yapılıyor; kullanıcı her seferinde tutamakları elle çekmek
/// zorunda kalıyordu ("yarım yamalak seçiliyor"). Bu yüzden yeni açılan bir
/// kelime seçimi kendiliğinden içinde bulunduğu cümleye büyütülür.
///
/// Tutamaklarla daraltma korunur: seçim ÖNCEKİ seçimin içinde kalıyorsa
/// dokunulmaz — yoksa kullanıcı cümleden bir parça seçemezdi.
library;

import 'package:flutter/widgets.dart';

/// Cümleyi bitiren noktalama. Türkçede üç nokta tek karakter olarak da
/// gelebildiği için '…' ayrıca listede.
const String _terminators = '.!?…';

/// Sınırın İÇİNDE kalan kapatıcılar: `(bitti.)` ya da `"bitti."` gibi
/// durumlarda kapanış işareti cümleye dahildir.
const String _closers = ')]}»"\'’”';

bool _isSpace(String c) => c.trim().isEmpty;

/// [i] konumunda gerçek bir cümle sonu varsa, sonun BİTTİĞİ konumu döndürür
/// (ardışık noktalama ve kapatıcılar dahil); yoksa null.
///
/// "3.5" ya da "vb.x" gibi yerlerde nokta cümle bitirmez: noktalama öbeğinin
/// ardından boşluk ya da metin sonu gelmelidir.
int? _terminatorEnd(String text, int i) {
  if (!_terminators.contains(text[i])) return null;
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
    return punctuationEnd;
  }
  return j;
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

/// [controller] üzerinde yeni açılan kelime seçimlerini cümleye genişletir.
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

  /// Kendi yazdığımız seçimle tekrar tetiklenmemek için.
  bool _busy = false;

  void onChanged() {
    if (_busy) return;
    final selection = controller.selection;
    final previous = _previous;
    _previous = selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final text = controller.text;
    if (selection.end > text.length) return;

    // Tutamakla daraltma/genişletme: seçim önceki seçimin içindeyse kullanıcı
    // bilerek küçültüyordur, karışma.
    if (previous != null &&
        !previous.isCollapsed &&
        selection.start >= previous.start &&
        selection.end <= previous.end) {
      return;
    }

    // Yalnız TEK KELİMELİK seçimler büyütülür: uzun basış/çift dokunuş bunu
    // üretir. "Tümünü seç" ya da elle çekilmiş çok kelimeli seçim boşluk
    // içerdiğinden buraya girmez.
    final picked = text.substring(selection.start, selection.end);
    if (picked.isEmpty || picked.contains(RegExp(r'\s'))) return;

    final range = sentenceRangeAt(text, selection.start);
    if (range.start >= range.end) return;
    if (range.start == selection.start && range.end == selection.end) return;
    // Cümle, seçilen kelimeyi kapsamıyorsa (beklenmez) dokunma.
    if (range.start > selection.start || range.end < selection.end) return;

    _busy = true;
    final expanded = TextSelection(
      baseOffset: range.start,
      extentOffset: range.end,
    );
    controller.selection = expanded;
    _previous = expanded;
    _busy = false;
  }
}
