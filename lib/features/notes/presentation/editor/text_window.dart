import 'dart:math' as math;

/// F24.2 (AKICILIK_PLANI, K2 — KARAR 2026-11-03: PENCERELİ KİP) — saf model.
///
/// Uzun notta (`kWindowedThreshold` üstü) `TextField` tam metni değil,
/// imlecin çevresindeki paragraf PENCERESİNİ taşıyacak; pencere dışı paragraflar
/// önbellekli `Text.rich` olarak çizilecek. Bu dosya yalnız metin
/// hesabıdır (editöre henüz BAĞLI DEĞİL): pencere sınırları, ofset
/// eşlemesi ve pencere düzenlemesinin tam metne geri yazılması.
///
/// Pencere sınırları HEP paragraf sınırındadır (`\n` sonrası / metin başı ve
/// `\n` öncesi / metin sonu): satır içi biçim işaretleri satır sonunu
/// aşmadığı için (bkz. `text_wrap_controller.dart` paragraf önbelleği)
/// pencerenin içi ve dışı birbirinden bağımsız çizilebilir.

/// Pencereli kipe geçiş eşiği (karakter). F24.1 (telefonda ölçüldü, 2026-11-04,
/// tek alan): tuş başına LAYOUT ~5 ms/KB, 3 KB'ta karelerin yarısı bütçeyi aşıyor.
const int kWindowedThreshold = 2500;

/// Tam metin içinde `[start, end)` aralığı; ikisi de paragraf sınırında.
class TextWindow {
  const TextWindow(this.start, this.end)
    : assert(start >= 0),
      assert(end >= start);

  final int start;
  final int end;

  int get length => end - start;

  bool containsOffset(int fullOffset) =>
      fullOffset >= start && fullOffset <= end;

  /// Tam metin ofseti → pencere ofseti (pencere dışındaysa kırpılır).
  int toWindow(int fullOffset) => (fullOffset - start).clamp(0, length).toInt();

  /// Pencere ofseti → tam metin ofseti.
  int toFull(int windowOffset) => start + windowOffset;

  String slice(String full) => full.substring(start, end);

  @override
  bool operator ==(Object other) =>
      other is TextWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TextWindow($start, $end)';
}

/// Pencere uzunluğu üst sınırı (bkz. [windowAround]).
const int kWindowMaxChars = 1500;

/// [offset]'in bulunduğu paragrafın başı (önceki `\n`'den sonrası).
int paragraphStartAt(String text, int offset) {
  if (offset <= 0) return 0;
  final i = text.lastIndexOf('\n', math.min(offset, text.length) - 1);
  return i < 0 ? 0 : i + 1;
}

/// [offset]'in bulunduğu paragrafın sonu (sonraki `\n`'in kendisi ya da
/// metin sonu).
int paragraphEndAt(String text, int offset) {
  if (offset >= text.length) return text.length;
  final i = text.indexOf('\n', math.max(0, offset));
  return i < 0 ? text.length : i;
}

/// İmlecin ([caret]) çevresinde, iki yana en çok [paragraphs] paragraf ve
/// toplam en çok [maxChars] karakter taşıyan pencere. İmlecin paragrafı ve iki
/// komşusu sınırı aşsa da HEP içeride: yoksa paragraf başında geri silme üst
/// paragrafa birleşemez, satır sonunda Delete alta geçemezdi.
TextWindow windowAround(
  String text,
  int caret, {
  int paragraphs = 20,
  int maxChars = kWindowMaxChars,
}) {
  final c = caret.clamp(0, text.length).toInt();
  var start = paragraphStartAt(text, c);
  var end = paragraphEndAt(text, c);
  var before = 0;
  var after = 0;
  if (paragraphs > 0 && end < text.length) {
    end = paragraphEndAt(text, end + 1);
    after++;
  }
  if (paragraphs > 0 && start > 0) {
    start = paragraphStartAt(text, start - 1);
    before++;
  }
  // İki yana sırayla genişle (önce aşağı: yazım çoğunlukla ileri gider).
  var grew = true;
  while (grew) {
    grew = false;
    if (after < paragraphs && end < text.length) {
      final next = paragraphEndAt(text, end + 1);
      if (next - start <= maxChars) {
        end = next;
        after++;
        grew = true;
      }
    }
    if (before < paragraphs && start > 0) {
      final prev = paragraphStartAt(text, start - 1);
      if (end - prev <= maxChars) {
        start = prev;
        before++;
        grew = true;
      }
    }
  }
  return TextWindow(start, end);
}

/// Pencerenin düzenlenmiş metnini ([windowText]) tam metne yazar; yeni tam
/// metin ve yeni pencere (aynı başlangıç, yeni uzunluk) döner. Pencere
/// metni `\n` içerebilir — paragraf eklemek/silmek pencere içinde serbest.
({String text, TextWindow window}) spliceWindow(
  String full,
  TextWindow window,
  String windowText,
) {
  final text =
      full.substring(0, window.start) + windowText + full.substring(window.end);
  return (
    text: text,
    window: TextWindow(window.start, window.start + windowText.length),
  );
}

/// İmleç pencerenin kenarına [margin] karakterden çok yaklaştı mı (ya da
/// dışına çıktı mı) — yeniden pencereleme zamanı.
bool needsRewindow(
  String full,
  TextWindow window,
  int caretFull, {
  int margin = 200,
}) {
  if (!window.containsOffset(caretFull)) return true;
  final nearTop = window.start > 0 && caretFull - window.start < margin;
  final nearBottom =
      window.end < full.length && window.end - caretFull < margin;
  return nearTop || nearBottom;
}
