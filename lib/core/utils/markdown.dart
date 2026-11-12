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

/// `.md` / `.markdown` dosyası mı — ad ya da MIME (P54). Paylaşımda ad
/// uzantısız gelebiliyor, MIME yedek ölçüt.
bool isMarkdownFile(String name, {String? mime}) {
  final lower = name.toLowerCase();
  return lower.endsWith('.md') ||
      lower.endsWith('.markdown') ||
      (mime ?? '').toLowerCase().contains('markdown');
}

final _checkboxLine = RegExp(r'^(\s*)[-*+]\s+\[( |x|X)\]\s?', multiLine: true);
final _bulletLine = RegExp(r'^(\s*)[-*+]\s+', multiLine: true);
final _mdLink = RegExp(r'!?\[([^\]]*)\]\(([^)\s]+)[^)]*\)');

/// Markdown → OKUNUR düz metin (P54): ek okuma ekranı ve oradan nota eklenen
/// metin. İşaretler kalkar; onay kutusu ☐/☑, madde •, bağlantı "ad (adres)".
String markdownReadable(String md) => stripMarkdown(
  md
      .replaceAll('\r\n', '\n')
      .replaceAllMapped(
        _checkboxLine,
        (m) => '${m[1]}${m[2]!.toLowerCase() == 'x' ? '☑' : '☐'} ',
      )
      .replaceAllMapped(_bulletLine, (m) => '${m[1]}• ')
      .replaceAllMapped(
        _mdLink,
        (m) => m[1]!.isEmpty ? m[2]! : '${m[1]} (${m[2]})',
      )
      .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1]!),
);
