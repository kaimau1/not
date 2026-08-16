/// Liste ↔ düz metin dönüşümü ve madde sıralaması — **yapay zekâ olmadan**.
///
/// Kullanıcı isteği 2026-08-16: "liste notunu metine dönüştürme ve tam tersi
/// ai sız" + "madde yıldızlama ve sıralama". Uygulamada bu işi yapan tek yol
/// AI'nın "biçimi değiştir" komutuydu: bir model çağrısı harcıyor, çevrimdışı
/// çalışmıyor ve — en kötüsü — modelin kendi yorumu metni sessizce
/// değiştirebiliyordu (madde birleştirme, noktalama düzeltme). Oysa dönüşüm
/// tümüyle mekanik bir iş.
///
/// Saf fonksiyonlar → birim testli; kimlik üretimi dışarıdan verilir ki test
/// belirleyici olsun.
library;

import 'note_item.dart';

/// Editörün düzenleme tamponunda yaşayan GÖRÜNMEZ karakterler: sarma çapası
/// (U+FFFC) ve kelime birleştirici (U+2060) — bkz. text_wrap.dart.
///
/// Çağıranın `logicalText` vermesi beklenir, ama burada da temizlenir:
/// bir tanesi satır başına düşünce madde işareti kalıbı eşleşmiyor ve
/// kullanıcı maddede ham "OBJ- [x] ..." metnini görüyordu (2026-08-16).
final RegExp _invisibleChars = RegExp('[\u{FFFC}\u{2060}]', unicode: true);

/// Düz metni liste maddelerine böler.
///
/// Her BOŞ OLMAYAN satır bir madde olur. Satırın başındaki liste işaretleri
/// (`-`, `*`, `•`, `1.`, `1)`) ve onay kutusu işaretleri (`[ ]`, `[x]`)
/// SÖKÜLÜR: metin zaten elle liste gibi yazılmışsa maddeler "- süt" değil
/// "süt" olmalı, yoksa madde satırının önünde ikinci bir tire görünürdü.
///
/// `[x]` işareti taşıyan satır TAMAMLANMIŞ madde olarak gelir — metne
/// dönüştürülüp geri alınan bir liste durumunu kaybetmesin (gidiş-dönüş).
///
/// Boş satırlar atlanır: paragraflar arası boşluk boş maddelere dönseydi
/// liste baştan sona delik deşik olurdu.
List<NoteItem> itemsFromText(String text, {required String Function() newId}) {
  final items = <NoteItem>[];
  for (final rawLine in text.split('\n')) {
    var line = rawLine.replaceAll(_invisibleChars, '').trim();
    if (line.isEmpty) continue;
    var checked = false;
    // Madde işareti: "- ", "* ", "• ", "1. ", "1) "
    line = line.replaceFirst(RegExp(r'^([-*•]|\d+[.)])\s+'), '');
    // Onay kutusu: "[ ] ", "[x] ", "[X] "
    final box = RegExp(r'^\[([ xX])\]\s*').firstMatch(line);
    if (box != null) {
      checked = box.group(1)!.toLowerCase() == 'x';
      line = line.substring(box.end);
    }
    line = line.trim();
    if (line.isEmpty) continue;
    items.add(NoteItem(id: newId(), text: line, checked: checked));
  }
  return items;
}

/// Liste maddelerini düz metne çevirir.
///
/// [numbered] true ise (sıralı liste notu) satırlar "1. ", "2. " …, değilse
/// tire ile başlar. Tamamlanmış maddeler `[x]` ile işaretlenir ki dönüşüm
/// GERİ alınabilsin ([itemsFromText] bu işaretleri okur) — "metne çevirdim,
/// geri aldım, hangilerini bitirdiğim kayboldu" olmasın.
///
/// [numbered] listede onay kutusu yazılmaz: sıralı listede `checked` alanı
/// zaten anlamsız (bkz. [NoteItem.checked]).
String textFromItems(List<NoteItem> items, {bool numbered = false}) {
  final lines = <String>[];
  var number = 0;
  for (final item in items) {
    final text = item.text.trim();
    if (text.isEmpty) continue;
    if (numbered) {
      lines.add('${++number}. $text');
    } else {
      lines.add('- ${item.checked ? '[x] ' : ''}$text');
    }
  }
  return lines.join('\n');
}

/// Madde sıralama ölçütleri.
enum ItemSort {
  /// Yıldızlılar en üstte; kendi aralarında sıra korunur.
  starredFirst,

  /// Tamamlanmamışlar üstte, tamamlananlar altta.
  uncheckedFirst,

  /// Metne göre A→Z (Türkçe harf sırasıyla).
  alphabetical,

  /// Metne göre Z→A.
  alphabeticalDesc,
}

/// Türkçe alfabe sırası. `String.compareTo` kod noktalarına göre sıralıyor ve
/// Türkçe harfleri (ç, ğ, ı, ö, ş, ü) ASCII'nin SONUNA atıyor: "zeytin"
/// "çilek"ten önce geliyordu. Harfler burada alfabedeki sıralarına eşlenir.
const String _turkishAlphabet = 'aâbcçdefgğhıiîjklmnoöprsştuüûvyz';

int _turkishCompare(String a, String b) {
  final x = a.toLowerCase();
  final y = b.toLowerCase();
  for (var i = 0; i < x.length && i < y.length; i++) {
    if (x[i] == y[i]) continue;
    final ix = _turkishAlphabet.indexOf(x[i]);
    final iy = _turkishAlphabet.indexOf(y[i]);
    // Alfabede olmayan karakterler (rakam, noktalama) harflerden ÖNCE gelir;
    // kendi aralarında kod noktası sırasıyla.
    if (ix < 0 && iy < 0) return x[i].compareTo(y[i]);
    if (ix < 0) return -1;
    if (iy < 0) return 1;
    if (ix != iy) return ix - iy;
  }
  return x.length - y.length;
}

/// Maddeleri [sort] ölçütüne göre sıralar. Liste KOPYALANIR; girdi
/// değişmez.
///
/// Sıralama KARARLIDIR (`List.sort` değil, indeks kırıcılı karşılaştırma):
/// eşit ölçütlü maddeler kullanıcının elle verdiği sırayı korur. Kararsız
/// bir sıralama "yıldızlıları üste al" dendiğinde geri kalan her şeyi de
/// gelişigüzel karıştırırdı.
List<NoteItem> sortItems(List<NoteItem> items, ItemSort sort) {
  final indexed = [
    for (var i = 0; i < items.length; i++) (index: i, item: items[i]),
  ];
  indexed.sort((a, b) {
    final result = switch (sort) {
      ItemSort.starredFirst =>
        (b.item.starred ? 1 : 0) - (a.item.starred ? 1 : 0),
      ItemSort.uncheckedFirst =>
        (a.item.checked ? 1 : 0) - (b.item.checked ? 1 : 0),
      ItemSort.alphabetical => _turkishCompare(a.item.text, b.item.text),
      ItemSort.alphabeticalDesc => _turkishCompare(b.item.text, a.item.text),
    };
    return result != 0 ? result : a.index - b.index;
  });
  return [for (final entry in indexed) entry.item];
}
