/// Takvim günü anahtarı `YYYY-MM-DD` (TAKVIM_PLANI §3).
///
/// Tüm gün etkinliği ve görev son tarihi SAAT değil GÜN taşır: zaman damgası
/// olarak saklansaydı saat dilimi değişince (yolculuk) bir gün kayardı.
/// Dize sıralaması tarih sıralamasıyla aynıdır.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// [dayKey]in tersi: yerel gece yarısı. Geçersizse null.
DateTime? parseDayKey(String? raw) {
  final s = raw?.trim() ?? '';
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  final y = int.parse(m[1]!);
  final mo = int.parse(m[2]!);
  final d = int.parse(m[3]!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final out = DateTime(y, mo, d);
  // 31 Şubat gibi taşan tarih başka güne kaymasın.
  return out.month == mo ? out : null;
}

/// Günün başı (yerel gece yarısı).
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Takvim günü farkı ([b] − [a]); yaz saatinden etkilenmez (UTC'de sayılır).
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// `HH:mm` → (saat, dakika); geçersizse null.
({int hour, int minute})? parseHm(String? raw) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw?.trim() ?? '');
  if (m == null) return null;
  final h = int.parse(m[1]!);
  final mi = int.parse(m[2]!);
  if (h > 23 || mi > 59) return null;
  return (hour: h, minute: mi);
}

String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Bilinmeyen alanları ayıklar (F1.5 kuralı: eski istemci yeni sürümün
/// alanlarını silemez — `toMap` [extras]ı AYNEN geri yazar).
Map<String, dynamic> unknownKeys(Map<String, dynamic> map, Set<String> known) =>
    {
      for (final e in map.entries)
        if (!known.contains(e.key)) e.key: e.value,
    };
