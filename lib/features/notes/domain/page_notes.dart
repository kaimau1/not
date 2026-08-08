import 'attachment.dart';

/// Sayfa notlarının ANAHTAR düzeni (bkz. `Note.pageNotes`).
///
/// Anahtar `"<ekId>#<sayfaKimliği>"`:
/// - **ek kimliği** önde, çünkü bir notta birden çok PDF/sunum olabilir;
///   sayfa 1'in notu hangi belgeye aitse ona bağlı kalmalı.
/// - **sayfa kimliği** sayfa NUMARASI DEĞİL: numara, sayfa silme/ekleme/
///   sıralama ile kayar ve bütün notlar bir sayfa şaşardı. Kimlik sayfayla
///   birlikte taşınır ([Attachment.pageIds]); kimlik atanmamış eklerde
///   `p<sayfaNo>` olarak türetilir — yani bugünkü kayıtlar için ikisi aynı
///   şeydir, kimlik listesi ancak PDF düzenleme geldiğinde yazılmaya başlar.
///
/// Ayırıcı `#`: Firestore harita anahtarında serbesttir ve ek kimliklerinde
/// (rastgele üretilen dizgi) geçmez, yani anahtar tek biçimde ayrıştırılır.
const kPageNoteSeparator = '#';

/// [pageNumber] (1 tabanlı) sayfanın kalıcı kimliği.
///
/// Ek henüz kimlik taşımıyorsa (bugünkü tüm kayıtlar) numaradan türetilir.
String pageIdFor(Attachment attachment, int pageNumber) {
  final ids = attachment.pageIds;
  if (pageNumber >= 1 && pageNumber <= ids.length) {
    final id = ids[pageNumber - 1];
    if (id.isNotEmpty) return id;
  }
  return 'p$pageNumber';
}

/// [pageNumber] sayfasının `Note.pageNotes` içindeki anahtarı.
String pageNoteKey(Attachment attachment, int pageNumber) =>
    '${attachment.id}$kPageNoteSeparator${pageIdFor(attachment, pageNumber)}';

/// Ek kimliği verilen ekin anahtarı mı? (Toplu görünüm ve temizlik için.)
bool isPageNoteKeyOf(String key, String attachmentId) =>
    key.startsWith('$attachmentId$kPageNoteSeparator');

/// Anahtardaki sayfa kimliği (ek kimliği soyulmuş hâli).
String pageIdOfKey(String key) {
  final at = key.indexOf(kPageNoteSeparator);
  return at < 0 ? key : key.substring(at + 1);
}

/// Sayfa kimliğinin karşılık geldiği 1 tabanlı sayfa numarası; kimlik bu ekte
/// bulunamazsa null. Önce ekin kimlik listesine bakılır (gerçek kimlikler),
/// bulunamazsa türetilmiş `p<N>` biçimi çözülür.
int? pageNumberOfId(Attachment attachment, String pageId) {
  final at = attachment.pageIds.indexOf(pageId);
  if (at >= 0) return at + 1;
  // Türetilmiş kimlik: ek kimlik listesi taşıyorsa ve kimlik orada YOKSA
  // sayfa silinmiş demektir — numaraya çevrilmez, yoksa silinen sayfanın
  // notu başka bir sayfanın üstüne düşerdi.
  if (attachment.pageIds.isNotEmpty) return null;
  final match = RegExp(r'^p(\d+)$').firstMatch(pageId);
  if (match == null) return null;
  final n = int.tryParse(match.group(1)!);
  return (n != null && n >= 1) ? n : null;
}

/// Ekin sayfa kimlik listesini [pageCount] sayfa için SOMUTLAŞTIRIR.
///
/// Kimlik listesi bugüne kadar BOŞ tutuluyordu (kimlikler `p<N>` olarak
/// türetiliyordu). PDF düzenleme ilk kez çalıştığında liste yazılmalı: yoksa
/// sayfa silindiğinde kalan sayfaların türetilmiş kimlikleri kayar ve bütün
/// notlar bir sayfa şaşardı.
///
/// **Somutlaştırma TÜRETİLEN kimliklerle yapılır** (`p1`, `p2`, …) — yeni
/// rastgele kimlikler üretilseydi hâlihazırda `a1#p3` anahtarıyla kayıtlı
/// notlar sahipsiz kalırdı.
List<String> materializePageIds(Attachment attachment, int pageCount) {
  if (pageCount <= 0) return const [];
  final ids = attachment.pageIds;
  return [
    for (var i = 1; i <= pageCount; i++)
      (i <= ids.length && ids[i - 1].isNotEmpty) ? ids[i - 1] : 'p$i',
  ];
}

/// Sayfa düzeni değişince yeni kimlik listesi: [order] 0 tabanlı ESKİ sayfa
/// indekslerini yeni sırayla verir (silme = indeksin listede olmaması).
///
/// Notların anahtarlarına DOKUNULMAZ; yalnız hangi kimliğin kaçıncı sayfa
/// olduğu değişir. Silinen sayfanın kimliği listeden düşer ve notu
/// `orderedPageNotes` tarafından gösterilmez — ama kayıtta DURUR: sayfa geri
/// alınırsa (geri al) notu da geri gelir.
/// [blankId] BOŞ SAYFA (order içinde -1) için yeni kimlik üretir: boş sayfanın
/// kendi kimliği olmalı, yoksa ondan sonraki sayfaların notları bir kayar.
List<String> reorderPageIds(
  List<String> ids,
  List<int> order, {
  String Function(int position)? blankId,
}) => [
  for (var position = 0; position < order.length; position++)
    if (order[position] < 0)
      (blankId ?? _defaultBlankId)(position)
    else if (order[position] < ids.length)
      ids[order[position]],
];

String _defaultBlankId(int position) => 'blank$position';

/// [attachment]'e ait sayfa notları, SAYFA SIRASINA dizilmiş hâlde.
/// Boş (silinmiş) notlar elenir — bkz. `Note.pageNotes` merge tuzağı.
///
/// Sayfası çözülemeyen anahtarlar (kimliği artık ekte olmayan, ör. silinmiş
/// sayfa) LİSTEYE GİRMEZ ama kayıtta durur: sayfa geri gelirse notu da geri
/// gelir, kullanıcının yazdığı hiçbir şey sessizce yok edilmez.
List<({int page, String text})> orderedPageNotes({
  required Attachment attachment,
  required Map<String, String> pageNotes,
}) {
  final out = <({int page, String text})>[];
  for (final entry in pageNotes.entries) {
    if (!isPageNoteKeyOf(entry.key, attachment.id)) continue;
    if (entry.value.trim().isEmpty) continue;
    final page = pageNumberOfId(attachment, pageIdOfKey(entry.key));
    if (page == null) continue;
    out.add((page: page, text: entry.value));
  }
  out.sort((a, b) => a.page.compareTo(b.page));
  return out;
}
