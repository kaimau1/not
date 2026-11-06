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

/// Gelen kutusu hızlı süzgeçleri (Gmail ekranı baştan, 2026-11-06). Her biri
/// Gmail arama sözdizimine çevrilir; YALNIZ OKUMA, sunucuda bir şey değişmez.
enum GmailFilter { inbox, unread, starred, attachments, today }

/// Süzgeç + kullanıcının yazdığı arama → tek Gmail sorgusu. Boş dönerse
/// istemci gelen kutusunu (`labelIds=INBOX`) ister.
String gmailQuery(GmailFilter filter, String text) {
  final t = text.trim();
  final f = switch (filter) {
    GmailFilter.inbox => '',
    GmailFilter.unread => 'is:unread',
    GmailFilter.starred => 'is:starred',
    GmailFilter.attachments => 'has:attachment',
    GmailFilter.today => 'newer_than:1d',
  };
  // Süzgeç seçiliyken arama da gelen kutusunda kalsın (yoksa tüm posta).
  final scope = filter == GmailFilter.inbox ? '' : 'in:inbox';
  return [scope, f, t].where((s) => s.isNotEmpty).join(' ');
}

/// Listede tarih kümesi.
enum GmailDay { today, yesterday, thisWeek, older }

GmailDay gmailDayOf(DateTime? date, DateTime now) {
  if (date == null) return GmailDay.older;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return GmailDay.today;
  if (diff == 1) return GmailDay.yesterday;
  if (diff < 7) return GmailDay.thisWeek;
  return GmailDay.older;
}

/// Gönderen adının baş harfi (avatar); harf yoksa '?'.
String senderInitial(String from) {
  final name = displayFrom(from);
  for (final r in name.runes) {
    final c = String.fromCharCode(r);
    if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(c)) {
      // Türkçe: i → İ (Dart'ın toUpperCase'i yerel bilmez).
      return c == 'i' ? 'İ' : c.toUpperCase();
    }
  }
  return '?';
}
