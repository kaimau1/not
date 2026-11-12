import 'dart:math' as math;

import 'package:flutter/widgets.dart' show CharacterRange;

import '../../../core/utils/rich_text.dart';
import '../../../core/utils/search_fold.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/sensitive_text.dart';
import 'notes_providers.dart' show bodySearchMatch;

/// **KART ÖNİZLEMESİNİN DİLİMİ** (F21.1, telefonda ölçüldü 2026-11-03).
///
/// KÖK NEDEN (kaydırma/arama kasması): kart 2-4 satır göstermek için notun
/// TAMAMINI hassas numara örtmesinden (regex), biçim ayrıştırmasından ve
/// metin motorundan geçiriyordu. Metin motoru `maxLines`'tan bağımsız bütün
/// paragrafı şekillendirir: kaydırmada bütçeyi aşan karelerin CPU'sunun
/// %60'ı `_NativeParagraph._layout`, LAYOUT 60-90 ms/kare; aramada 450 ms.
/// Kart artık yalnız görünebilecek kadarını işler: gövde en çok 4 satır
/// çizilir (5. satır kartın kendi `…`sunu korur); 300 karakter dört sütunlu
/// tablette de dört satırı doldurur. 600'de kaydırma LAYOUT p99 hâlâ 20 ms'ydi.
const kPreviewMaxLines = 5;
const kPreviewMaxChars = 300;

/// Madde ve sayfa notu satırı tek satır: 120 karakter geniş kartı da doldurur.
const kPreviewItemChars = 120;

/// Örtme dilimin iki yanından bu kadar taşar: kesimde bölünen IBAN/kart
/// numarası tanınmaz, ilk haneleri AÇIK görünürdü (IBAN en çok 64 karakter).
const _maskMargin = 64;

/// [text]in kartta görünebilecek kadarı: ilk [maxLines] satır, en çok
/// [maxChars] kod birimi. Kesim GRAFEM sınırında (emoji, birleşik harf
/// bölünmez); satır ortasında kesilen dilim `…` ile biter, kesilmeyen metin
/// aynen döner. [mask]: hassas numaralar örtülür (bkz. [maskSensitiveNumbers]).
/// Biçim işareti kesimde açık kalırsa düz metin çizilir — `richSpans`
/// eşleşmeyen işareti düz sayar.
String previewSlice(
  String text, {
  bool mask = false,
  int maxLines = kPreviewMaxLines,
  int maxChars = kPreviewMaxChars,
}) => _cut(text, 0, mask: mask, maxLines: maxLines, maxChars: maxChars);

String _cut(
  String text,
  int start, {
  required bool mask,
  int maxLines = kPreviewMaxLines,
  int maxChars = kPreviewMaxChars,
}) {
  var end = math.min(text.length, start + maxChars);
  var lineCut = false;
  var lines = 1;
  for (var i = start; i < end; i++) {
    if (text.codeUnitAt(i) == 0x0A && ++lines > maxLines) {
      end = i;
      lineCut = true;
      break;
    }
  }
  if (!lineCut) end = _boundaryBefore(text, end);
  final head = mask
      ? _masked(text, start, end)
      : start == 0 && end == text.length
      ? text
      : text.substring(start, end);
  // Satır sonunda kesilen dilimin devamını kartın kendi `…`su gösterir.
  final midLine = !lineCut && end < text.length && text.codeUnitAt(end) != 0x0A;
  return midLine ? '$head…' : head;
}

/// [index]te ya da öncesindeki ilk grafem sınırı.
int _boundaryBefore(String text, int index) => index >= text.length
    ? text.length
    : CharacterRange.at(text, index).stringBeforeLength;

/// [text]in [start, end) aralığı, hassas numaralar örtülmüş. Örtme uzunluğu
/// korur (yalnız ASCII harf/rakam `•` olur): taşan pay kesilince konumlar
/// aynı kalır.
String _masked(String text, int start, int end) {
  final from = math.max(0, start - _maskMargin);
  final to = math.min(text.length, end + _maskMargin);
  return maskSensitiveNumbers(text.substring(from, to))
      .substring(start - from, end - from);
}

/// Dar kartta (2 sütunlu telefon) bir satıra sığan yaklaşık karakter.
const _lineChars = 24;

/// Kesitte eşleşmenin önünde bırakılan bağlam (karakter).
const _lead = 24;

/// **ARAMA KESİTİ** (F21.3): sorgunun gövdedeki eşleşmesi kartın görünen
/// başında değilse eşleşmenin çevresinden kısa kesit — Keep gibi "… önceki
/// sözcükler EŞLEŞME sonrası". Dilimle gövde baştan gösterilseydi uzun notta
/// eşleşme (ve vurgusu) kartta hiç görünmezdi. Eşleşme dar kartta bile ilk
/// [maxLines] satırda görünüyorsa null: kart gövdeyi baştan gösterir.
///
/// [plain] biçim işaretleri sökülmüş gövde, [index]/[length] eşleşme.
String? searchExcerpt(
  String plain,
  int index,
  int length, {
  required int maxLines,
  bool mask = false,
}) {
  if (_visibleAtStart(plain, index + length, maxLines)) return null;
  // Eşleşmenin satır başından; satır başı çok gerideyse bir sözcük başından.
  var start = plain.lastIndexOf('\n', index) + 1;
  if (index - start > _lead) {
    final space = plain.indexOf(' ', index - _lead);
    start = space >= 0 && space < index
        ? space + 1
        : _boundaryBefore(plain, index - _lead);
  }
  if (start == 0) return null;
  return '… ${_cut(plain, start, mask: mask)}';
}

/// [end]e kadarki metin dar kartın ilk [maxLines] satırına sığar mı? Satır
/// kırılımı kabaca: her satır ⌈uzunluk / [_lineChars]⌉ satır tutar.
bool _visibleAtStart(String plain, int end, int maxLines) {
  if (end > maxLines * _lineChars) return false;
  var rows = 0;
  var lineStart = 0;
  for (var i = 0; i < end; i++) {
    if (plain.codeUnitAt(i) != 0x0A) continue;
    rows += math.max(1, ((i - lineStart) / _lineChars).ceil());
    lineStart = i + 1;
  }
  rows += math.max(1, ((end - lineStart) / _lineChars).ceil());
  return rows <= maxLines;
}

/// Kartın madde dilimi (bkz. [cardItemSlice]): çizilecek maddeler, "+N madde
/// daha" sayısı, özete inen işaretli sayısı (0 = özet satırı yok) ve "hepsi
/// tamam" hâli.
typedef CardItemSlice = ({
  List<NoteItem> shown,
  int more,
  int done,
  bool allDone,
});

/// **KARTTA İŞARETLİLER TEK SATIR** (F74.4, K-D5): işaretsiz madde varken
/// kart yalnız onları gösterir (dilim sınırı [max] aynı), işaretliler tek
/// satır "✓ N tamamlandı"ya iner — uzun listede kart üstü çizili satır
/// duvarıydı, okunacak madde görünmüyordu. Hepsi işaretliyse ilk iki madde
/// (üstü çizili) + "✓ Hepsi tamam (N)". [ordered] işaretsizler önce sıralı;
/// [collapseChecked] kapalıyken (`card_show_checked` açık) bugünkü görünüm.
CardItemSlice cardItemSlice(
  List<NoteItem> ordered,
  int max, {
  required bool collapseChecked,
}) {
  bool isDone(NoteItem i) => i.checked && !i.header;
  final done = collapseChecked ? ordered.where(isDone).length : 0;
  if (done == 0) {
    final shown = ordered.take(max).toList();
    return (
      shown: shown,
      more: ordered.length - shown.length,
      done: 0,
      allDone: false,
    );
  }
  final open = [
    for (final i in ordered)
      if (!isDone(i)) i,
  ];
  if (open.any((i) => !i.header)) {
    final shown = open.take(max).toList();
    return (
      shown: shown,
      more: open.length - shown.length,
      done: done,
      allDone: false,
    );
  }
  return (
    shown: ordered.where(isDone).take(2).toList(),
    more: 0,
    done: done,
    allDone: true,
  );
}

/// **KARTIN HAZIR ÖNİZLEMESİ** — not ÖRNEĞİ başına bir kez (F21.2).
///
/// Akış değişmeyen notun örneğini korur (`watchNotes` yalnız değişen belgeyi
/// yeniden çözer), yani önbellek not SÜRÜMÜ başına: kart yeniden kurulsa da
/// (kaydırmada geri gelme, seçim, editörden dönüş) dilim, örtme ve TAM
/// metinde parola taraması tekrarlanmaz. `Expando`: not bellekten düşünce
/// girdisi de düşer. Ayar ("hassas içeriği gizle") değişince girdi yenilenir.
class CardPreview {
  CardPreview._(this._note, this.hideSensitive);

  static final _cache = Expando<CardPreview>('cardPreview');

  static CardPreview of(Note note, {required bool hideSensitive}) {
    final hit = _cache[note];
    if (hit != null && hit.hideSensitive == hideSensitive) return hit;
    return _cache[note] = CardPreview._(note, hideSensitive);
  }

  final Note _note;

  /// Hassas numaralar örtülü mü (Ayarlar → Görünüm, B1).
  final bool hideSensitive;

  /// Parola notu mu (B1) — başlık, gövde ve maddelerin TAMAMINDA.
  late final bool credential = isCredentialNote(_note);

  /// Başlık örtülmez (eskiden de örtülmüyordu); yalnız dilimlenir.
  late final String title = previewSlice(_note.title);

  late final String body = previewSlice(_note.body, mask: hideSensitive);

  /// Ekran okuyucu etiketinin gövde kısmı: ilk 160 karakter, düz.
  late final String label = () {
    final end = _boundaryBefore(_note.body, 160);
    return stripRichMarkers(
      hideSensitive
          ? _masked(_note.body, 0, end)
          : _note.body.substring(0, end),
    ).trim();
  }();

  final _items = <String, String>{};

  /// Madde / sayfa notu metninin satırlık dilimi.
  String item(String text) => _items[text] ??= previewSlice(
    text,
    mask: hideSensitive,
    maxChars: kPreviewItemChars,
  );

  (String, int)? _excerptKey;
  String? _excerpt;

  /// Aramada gövdenin kesiti (bkz. [searchExcerpt]); son sorgu için saklanır.
  String? excerpt(String query, int maxLines) {
    final key = (query, maxLines);
    if (key == _excerptKey) return _excerpt;
    _excerptKey = key;
    final folded = foldForSearch(query.trim());
    final match = bodySearchMatch(_note, folded);
    return _excerpt = match == null
        ? null
        : searchExcerpt(
            match.$1,
            match.$2,
            folded.length,
            maxLines: maxLines,
            mask: hideSensitive,
          );
  }
}
