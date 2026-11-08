/// **E-POSTADAN AKILLI BAĞLANTILAR** (2026-11-08): gövdedeki tarih/saatleri
/// bulur ("12.11.2026 14:30", "12 Kasım saat 10.00", "2026-11-12"). Saf ve
/// testli; arayüz her sonucu "Takvime ekle" çipine çevirir.
class SmartDate {
  const SmartDate(this.when, {required this.hasTime, required this.raw});
  final DateTime when;
  final bool hasTime;

  /// Metindeki ilk yazılışı (çipte gösterilir).
  final String raw;
}

const _months = {
  'oca': 1, 'şub': 2, 'sub': 2, 'mar': 3, 'nis': 4, 'apr': 4, 'may': 5,
  'haz': 6, 'jun': 6, 'tem': 7, 'jul': 7, 'ağu': 8, 'agu': 8, 'aug': 8,
  'eyl': 9, 'sep': 9, 'eki': 10, 'oct': 10, 'kas': 11, 'nov': 11,
  'ara': 12, 'dec': 12, 'jan': 1, 'feb': 2,
};

final _numeric = RegExp(r'\b(\d{1,2})[./](\d{1,2})[./](\d{4}|\d{2})\b');
final _iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
final _named = RegExp(
  r'\b(\d{1,2})\s+(ocak|şubat|mart|nisan|may[ıi]s|haziran|temmuz|ağustos|'
  r'eylül|ekim|kas[ıi]m|aral[ıi]k|january|february|march|april|may|june|'
  r'july|august|september|october|november|december)(?:\s+(\d{4}))?\b',
  caseSensitive: false,
);
final _time = RegExp(
  r'(?:saat\s*(\d{1,2})[:.]([0-5]\d)|\b([01]?\d|2[0-3]):([0-5]\d)\b)',
  caseSensitive: false,
);

/// [text] içindeki tarihler (en çok [max], yinelenenler tek). Yılsız tarih bu
/// yıl; [now]dan 60 günden fazla geride kalırsa gelecek yıl sayılır.
List<SmartDate> findSmartDates(String text, DateTime now, {int max = 4}) {
  final found = <({int at, int end, int y, int m, int d, bool yearless})>[];
  for (final m in _numeric.allMatches(text)) {
    var y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
    found.add((
      at: m.start,
      end: m.end,
      y: y,
      m: int.parse(m.group(2)!),
      d: int.parse(m.group(1)!),
      yearless: false,
    ));
  }
  for (final m in _iso.allMatches(text)) {
    found.add((
      at: m.start,
      end: m.end,
      y: int.parse(m.group(1)!),
      m: int.parse(m.group(2)!),
      d: int.parse(m.group(3)!),
      yearless: false,
    ));
  }
  for (final m in _named.allMatches(text)) {
    final month = _months[m.group(2)!.toLowerCase().substring(0, 3)];
    if (month == null) continue;
    final year = m.group(3);
    found.add((
      at: m.start,
      end: m.end,
      y: year == null ? now.year : int.parse(year),
      m: month,
      d: int.parse(m.group(1)!),
      yearless: year == null,
    ));
  }
  found.sort((a, b) => a.at.compareTo(b.at));
  final out = <SmartDate>[];
  final seen = <String>{};
  for (final f in found) {
    var y = f.y;
    var date = DateTime(y, f.m, f.d);
    if (date.month != f.m || date.day != f.d) continue; // 31 Şubat gibi
    if (f.yearless &&
        date.isBefore(DateTime(now.year, now.month, now.day - 60))) {
      y += 1;
      date = DateTime(y, f.m, f.d);
    }
    // Saat: tarihten hemen sonraki ~30 karakterde.
    final tail = text.substring(f.end, (f.end + 30).clamp(f.end, text.length));
    final t = _time.firstMatch(tail);
    var hasTime = false;
    if (t != null) {
      final h = int.parse(t.group(1) ?? t.group(3)!);
      final mi = int.parse(t.group(2) ?? t.group(4)!);
      date = DateTime(y, f.m, f.d, h, mi);
      hasTime = true;
    }
    if (!seen.add(date.toIso8601String())) continue;
    out.add(SmartDate(date, hasTime: hasTime, raw: text.substring(f.at, f.end)));
    if (out.length >= max) break;
  }
  return out;
}

/// `"Ad <a@b.c>"` başlığından (ad, adres); adres yoksa null.
({String name, String email})? parseSender(String from) {
  final m = RegExp(r'^\s*"?([^"<]*?)"?\s*<([^>]+)>').firstMatch(from);
  if (m != null) return (name: m.group(1)!.trim(), email: m.group(2)!.trim());
  final bare = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+').firstMatch(from);
  return bare == null ? null : (name: '', email: bare.group(0)!);
}
