/// AI çıktısındaki Markdown işaretlerini temizler; notlar düz metin tutar.
/// Model bazen istenmese de **kalın**, *italik*, `kod`, # başlık üretiyor;
/// bunlar not içeriğine ham girmesin diye buradan geçirilir.
String stripMarkdown(String input) {
  var text = input;
  // Kod bloğu çitleri (```dart gibi dil etiketleri dahil)
  text = text.replaceAll(RegExp('```[a-zA-Z]*'), '');
  // Kalın: **x** / satır içi italik ve kod
  text = text.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
  text = text.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
  text = text.replaceAllMapped(RegExp('`([^`]+?)`'), (m) => m[1]!);
  // Satır başındaki başlık (#), alıntı (>) işaretleri
  text = text.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');
  text = text.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');
  return text;
}
