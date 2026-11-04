import '../data/gmail_api.dart';

/// E-postadan not taslağı (F28.1): konu → başlık, gövde → metin, sonda
/// kaynak satırı (kimden, tarih, Gmail bağlantısı). Saf; testli.
///
/// Gövde not belgesi sınırına göre kesilir ([maxBodyChars]) — uzun bülten
/// notu 1 MiB'a yaklaştırmasın.
const maxBodyChars = 60000;

({String title, String body}) noteDraftFromEmail(
  GmailMessage m, {
  String? replacementBody,
}) {
  var text = (replacementBody ?? m.body).trim();
  if (text.length > maxBodyChars) {
    text = '${text.substring(0, maxBodyChars)}…';
  }
  final date = m.date;
  final when = date == null
      ? ''
      : ' · ${date.year}-${_two(date.month)}-${_two(date.day)}';
  final source = '— ${displayFrom(m.from)}$when\n${m.webUrl}';
  final title = m.subject.trim().isEmpty ? '(konu yok)' : m.subject.trim();
  return (
    title: title.length > 200 ? title.substring(0, 200) : title,
    body: text.isEmpty ? source : '$text\n\n$source',
  );
}

String _two(int n) => n.toString().padLeft(2, '0');

/// AI çıktısındaki madde satırlarını ("- x", "• x", "1. x", "[ ] x")
/// liste maddelerine çevirir; madde yoksa boş liste.
List<String> taskItemsFromAi(String text) => [
  for (final line in text.split('\n'))
    if (RegExp(r'^\s*(?:[-*•]|\d+[.)]|\[\s?[xX ]?\])\s+').hasMatch(line))
      line
          .replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)]|\[\s?[xX ]?\])\s+'), '')
          .replaceFirst(RegExp(r'^\[\s?[xX ]?\]\s+'), '')
          .trim(),
].where((s) => s.isNotEmpty).toList();
