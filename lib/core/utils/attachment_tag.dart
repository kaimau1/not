/// Metnin İÇİNE gömülen EK ETİKETİ: "📎 rapor.pdf".
///
/// Kullanıcı isteği 2026-08-16: "yazıya görsel PDF vs gömme, altı çizilir
/// kırmızı işaretlenir, tıklayınca önizlemesi açılır, bir butonla da
/// düzenleme açılır, dışa aktar doğru çalışmalı."
///
/// **KARAR — etiket GİZLİ bir kimlik taşımaz, dosya ADIYLA eşleşir.**
/// Satır içi biçim işaretleri (bkz. rich_text.dart) metinde DURUYOR ve yalnız
/// görünmez çiziliyor; aynı yolu ek etiketi için de kullanmak, imleç/seçim
/// konumlarının denetleyicinin metniyle birebir örtüşmesi gereken bir yerde
/// (bkz. [WrapTextController.buildTextSpan]) ikinci bir gizli karakter sınıfı
/// daha demek olurdu. Ad ile eşleşme bu sorunu tümden ortadan kaldırır:
///
///  * çizilen metin ile ham metin AYNI — hiçbir konum kaymaz,
///  * kopyala/yapıştır, paylaşım ve dışa aktarma etiketi okunur biçimde
///    taşır ("📎 rapor.pdf" her yerde anlamlı),
///  * eski notlarda geriye dönük çalışır (özel bir alan gerekmez).
///
/// Bedeli: aynı notta AYNI ADLI iki ek varsa etiket ilkine bağlanır. Nadir
/// ve zararsız — iki dosyanın adı aynıysa kullanıcı zaten hangisinin hangisi
/// olduğunu ayırt edemiyor.
library;

/// Etiketin başındaki ataç. Ad ile arasında TEK boşluk vardır.
const String kAttachmentTagPrefix = '📎 ';

/// [fileName] için metne yazılacak etiket.
String attachmentTagFor(String fileName) =>
    '$kAttachmentTagPrefix${fileName.trim()}';

/// [text] içindeki ek etiketlerinin konumları.
///
/// Yalnız [fileNames} kümesinde GERÇEKTEN bulunan adlar eşleşir: kullanıcı
/// düz metin olarak "📎 bir şey" yazdıysa o kırmızıya boyanmaz, çünkü
/// tıklanacak bir ek yok.
///
/// Eşleştirme en UZUN addan başlar: "rapor.pdf" ile "rapor.pdf.bak" bir arada
/// varsa kısa olanın uzun adın başına oturup etiketi ortadan bölmesi
/// engellenir.
List<({int start, int end, String fileName})> findAttachmentTags(
  String text,
  Iterable<String> fileNames,
) {
  final names = [
    for (final name in fileNames)
      if (name.trim().isNotEmpty) name.trim(),
  ]..sort((a, b) => b.length - a.length);
  if (names.isEmpty || text.isEmpty) return const [];

  final found = <({int start, int end, String fileName})>[];
  var cursor = 0;
  while (true) {
    final at = text.indexOf(kAttachmentTagPrefix, cursor);
    if (at < 0) break;
    final nameStart = at + kAttachmentTagPrefix.length;
    String? matched;
    for (final name in names) {
      if (text.startsWith(name, nameStart)) {
        matched = name;
        break;
      }
    }
    if (matched == null) {
      cursor = nameStart;
      continue;
    }
    final end = nameStart + matched.length;
    found.add((start: at, end: end, fileName: matched));
    cursor = end;
  }
  return found;
}

/// [offset] konumundaki (ya da hemen bitişiğindeki) ek etiketinin dosya adı;
/// yoksa null.
///
/// Bitiş sınırı DAHİL: imleç etiketin sonuna konduğunda da bulunur — metne
/// dokunmak imleci karakterin sağına koyabiliyor ve kullanıcı için orası hâlâ
/// "etiketin üstü" (bağlantılardaki [linkAt] ile aynı kural).
String? attachmentTagAt(String text, int offset, Iterable<String> fileNames) {
  for (final tag in findAttachmentTags(text, fileNames)) {
    if (offset >= tag.start && offset <= tag.end) return tag.fileName;
  }
  return null;
}

/// Etiketleri DIŞA AKTARMA için okunur düz metne çevirir: "📎 rapor.pdf" →
/// "[ek: rapor.pdf]".
///
/// KÖK NEDEN: PDF ve Word çıktıları gömülü PT Sans ile diziliyor ve o fontta
/// ATAÇ (U+1F4CE) glifi YOK — etiket çıktıda boş kutu olarak görünürdü.
/// Köşeli parantezli biçim hem her fontta çizilir hem de metnin içinde
/// "burada bir ek var" bilgisini korur.
///
/// [names] verilirse yalnız GERÇEKTEN var olan eklerin etiketleri çevrilir;
/// kullanıcının düz metin olarak yazdığı bir ataç olduğu gibi kalır.
String exportAttachmentTags(String text, Iterable<String> names) {
  final tags = findAttachmentTags(text, names);
  if (tags.isEmpty) return text;
  final buffer = StringBuffer();
  var cursor = 0;
  for (final tag in tags) {
    buffer
      ..write(text.substring(cursor, tag.start))
      ..write('[ek: ${tag.fileName}]');
    cursor = tag.end;
  }
  buffer.write(text.substring(cursor));
  return buffer.toString();
}

/// DOKUNUŞ için etiket araması: [offset] etiketin İÇİNDE olmalı (iki sınır
/// HARİÇ). [attachmentTagAt] sınırları dahil sayar — o seçim menüsü için
/// doğru; ama dokunuşta etiketin hemen yanına imleç koymak (yazmaya devam
/// etmek için) önizlemeyi açıyordu (gömme yeniden tasarımı, 2026-10-11).
({int start, int end, String fileName})? attachmentTagInside(
  String text,
  int offset,
  Iterable<String> fileNames,
) {
  for (final tag in findAttachmentTags(text, fileNames)) {
    if (offset > tag.start && offset < tag.end) return tag;
  }
  return null;
}

/// Seçimin iki ucundaki boşlukları dışarıda bırakan aralık; seçim yalnız
/// boşluksa null.
///
/// KÖK NEDEN (eski gömme): etiket metni kırpılıyor ama yazılırken KIRPILMAMIŞ
/// aralığın yerine konuyordu — "kelime " seçilince kelimenin arkasındaki
/// boşluk yutuluyor, sonraki sözcük etikete yapışıyordu.
({int start, int end})? trimmedRange(String text, int start, int end) {
  var s = start.clamp(0, text.length);
  var e = end.clamp(s, text.length);
  while (s < e && text[s].trim().isEmpty) {
    s++;
  }
  while (e > s && text[e - 1].trim().isEmpty) {
    e--;
  }
  return s == e ? null : (start: s, end: e);
}

/// [label] etiketinin metindeki TÜM ataçlarını söker ("📎 kelime" →
/// "kelime"): gömmeyi kaldırmak yazıya dokunmaz, yalnız bağı çözer.
String removeAttachmentTags(String text, String label) =>
    text.replaceAll(attachmentTagFor(label), label.trim());
