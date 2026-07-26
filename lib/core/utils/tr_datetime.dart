/// Türkçe konuşmadan tarih/saat çıkaran ayrıştırıcı.
///
/// Sesli asistanın emniyet ağıdır: model `create_note`'u çağırırken
/// `reminderAt` alanını doldurmayı atlayabiliyor ("yarın sabah 9'da toplantım
/// var" bir EMİR değil bildirim cümlesi olduğu için modelin isteğe bağlı
/// alanı geçmesi tipik). Zamanı burada yerelde de hesaplayınca davranış
/// modelin keyfine kalmıyor.
///
/// Model alanı doldurduysa bu ayrıştırıcı devreye GİRMEZ — modelin bağlamı
/// (not defteri, konuşma geçmişi) daha geniştir.
library;

/// Günün bölümü söylendiğinde varsayılan saat.
const Map<String, int> _partHours = {
  'sabah': 9,
  'öğlen': 12,
  'öğle': 12,
  'öğleden sonra': 15,
  'ikindi': 16,
  'akşam': 19,
  'gece': 22,
};

/// "sabah 9" 09:00, "akşam 7" 19:00 demektir: bu bölümlerde 12'den küçük
/// saate 12 eklenir.
const Set<String> _afternoonParts = {
  'öğleden sonra',
  'ikindi',
  'akşam',
  'gece',
};

const Map<String, int> _weekdays = {
  'pazartesi': DateTime.monday,
  'salı': DateTime.tuesday,
  'çarşamba': DateTime.wednesday,
  'perşembe': DateTime.thursday,
  'cuma': DateTime.friday,
  'cumartesi': DateTime.saturday,
  'pazar': DateTime.sunday,
};

/// Türkçe küçük harfe çevirir. Dart'ın `toLowerCase`'i 'I' harfini 'i'
/// yapar (Türkçede 'ı' olmalı) ve 'İ' için birleşik nokta üretir — ikisi de
/// aşağıdaki anahtar kelimeleri kaçırtıyordu.
String _lower(String text) =>
    text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Türkçe harfler — kelime sınırı denetimi için. Dart'ın `\b`'si ASCII `\w`
/// üzerinden çalıştığından "ü", "ş", "ğ" gibi harflerde yanlış yerde sınır
/// görüyor; bu yüzden sınır elle denetlenir.
final RegExp _letter = RegExp('[a-zçğıiöşü]');

/// [word] metinde KELİME olarak geçiyor mu. Basit `contains` "bugünlük bu
/// kadar" cümlesinde "bugün" görüp hatırlatıcı uyduruyordu.
bool _hasWord(String text, String word) {
  var from = 0;
  while (true) {
    final at = text.indexOf(word, from);
    if (at < 0) return false;
    final before = at == 0 ? '' : text[at - 1];
    final afterIndex = at + word.length;
    final after = afterIndex >= text.length ? '' : text[afterIndex];
    if (!_letter.hasMatch(before) && !_letter.hasMatch(after)) return true;
    from = at + 1;
  }
}

/// Metindeki saat bilgisi. Rastgele sayıları saat sanmamak için sayı
/// MUTLAKA bir saat ipucuna bağlı olmalı: "14:30", "saat 9", "9'da",
/// "9 buçuk". Yoksa yalnızca günün bölümü (sabah/akşam…) kullanılır.
({int hour, int minute})? _parseTime(String text) {
  // Günün bölümü: "öğleden sonra" daha uzun olduğu için "öğle"den ÖNCE
  // aranır, yoksa 15:00 yerine 12:00 çıkardı.
  String? part;
  for (final name in const [
    'öğleden sonra',
    'ikindi',
    'sabah',
    'öğlen',
    'öğle',
    'akşam',
    'gece',
  ]) {
    if (_hasWord(text, name)) {
      part = name;
      break;
    }
  }

  int? hour;
  var minute = 0;

  final explicit = RegExp(r'\b(\d{1,2})[:.](\d{2})\b').firstMatch(text);
  final withSaat = RegExp(r'\bsaat\s+(\d{1,2})\b').firstMatch(text);
  // "9'da", "9da", "9 da" — kesme işareti konuşma dökümünde çoğu zaman yok.
  final withSuffix = RegExp(
    r"\b(\d{1,2})\s*['’`]?\s*(?:da|de|ta|te)\b",
  ).firstMatch(text);
  final half = RegExp(r'\b(\d{1,2})\s+buçuk\b').firstMatch(text);

  if (explicit != null) {
    hour = int.parse(explicit.group(1)!);
    minute = int.parse(explicit.group(2)!);
  } else if (half != null) {
    hour = int.parse(half.group(1)!);
    minute = 30;
  } else if (withSaat != null) {
    hour = int.parse(withSaat.group(1)!);
  } else if (withSuffix != null) {
    hour = int.parse(withSuffix.group(1)!);
  }

  if (hour == null) {
    if (part == null) return null;
    return (hour: _partHours[part]!, minute: 0);
  }
  if (hour > 23 || minute > 59) return null;
  // "akşam 7" → 19:00. Saat açıkça 24'lük yazıldıysa (19:00) dokunulmaz.
  if (part != null && _afternoonParts.contains(part) && hour < 12) hour += 12;
  return (hour: hour, minute: minute);
}

/// Metindeki günü verir: gün bulunamazsa null (saat varsa çağıran bugüne
/// düşürür).
DateTime? _parseDay(String text, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  // "yarın" içinde "yarım" yok, ama "yarın"dan önce "öbür gün" aranmalı
  // değil — ikisi çakışmaz, sıra önemsiz.
  if (_hasWord(text, 'öbür gün') || _hasWord(text, 'öbürgün')) {
    return today.add(const Duration(days: 2));
  }
  if (_hasWord(text, 'yarın')) return today.add(const Duration(days: 1));
  if (_hasWord(text, 'bugün')) return today;

  for (final entry in _weekdays.entries) {
    if (!_hasWord(text, entry.key)) continue;
    var delta = (entry.value - today.weekday) % 7;
    // "haftaya salı" / "gelecek salı": bu haftaki gün değil, sonraki.
    final nextWeek =
        _hasWord(text, 'haftaya') || _hasWord(text, 'gelecek hafta');
    if (delta == 0) delta = 7; // "salı" bugünse kastedilen sonraki salıdır
    if (nextWeek && delta < 7) delta += 7;
    return today.add(Duration(days: delta));
  }
  return null;
}

/// Konuşmadan hatırlatıcı zamanı çıkarır; bulamazsa null döner.
///
/// Gün ya da saat ipucu YOKSA null döner — "toplantım var" gibi zamansız
/// cümleler için hatırlatıcı uydurulmaz. Sonuç her zaman GELECEKtedir:
/// gün söylenmemiş ve saat bugün için geçmişse ertesi güne kayar.
DateTime? parseTurkishDateTime(String text, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final normalized = _lower(text);

  final day = _parseDay(normalized, reference);
  final time = _parseTime(normalized);
  if (day == null && time == null) return null;

  final base = day ?? DateTime(reference.year, reference.month, reference.day);
  // Gün söylenip saat söylenmediyse sabah 9 varsayılır: "yarın toplantım
  // var" için gece yarısına hatırlatıcı kurmak işe yaramaz.
  final result = DateTime(
    base.year,
    base.month,
    base.day,
    time?.hour ?? 9,
    time?.minute ?? 0,
  );

  if (result.isAfter(reference)) return result;
  // Gün açıkça söylendiyse geçmişe kurulmaz (kullanıcı geçmiş bir günü
  // kastetmiştir, hatırlatıcı anlamsız).
  if (day != null) return null;
  return result.add(const Duration(days: 1));
}
