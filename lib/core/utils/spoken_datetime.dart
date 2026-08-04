/// Konuşmadan tarih/saat çıkaran ayrıştırıcı (tr, en, de, es).
///
/// Sesli asistanın emniyet ağıdır: model `create_note`'u çağırırken
/// `reminderAt` alanını doldurmayı atlayabiliyor ("yarın sabah 9'da toplantım
/// var" bir EMİR değil bildirim cümlesi olduğu için modelin isteğe bağlı
/// alanı geçmesi tipik). Zamanı burada yerelde de hesaplayınca davranış
/// modelin keyfine kalmıyor.
///
/// Model alanı doldurduysa bu ayrıştırıcı devreye GİRMEZ — modelin bağlamı
/// (not defteri, konuşma geçmişi) daha geniştir.
///
/// Desteklenmeyen dilde `null` döner: emniyet ağı yoktur, davranış modele
/// kalır (eskiden Türkçe dışındaki HER dilde durum buydu).
library;

import 'package:intl/intl.dart';

/// Bir dilin zaman sözcükleri. Yeni dil eklemek = [_languages]'a bir giriş;
/// ayrıştırma mantığı ortak, yalnız sözlük değişir.
class _SpokenLanguage {
  const _SpokenLanguage({
    required this.parts,
    required this.afternoonParts,
    required this.weekdays,
    required this.today,
    required this.tomorrow,
    required this.dayAfterTomorrow,
    required this.nextWeek,
    required this.hourPrefix,
    this.tomorrowPattern,
    this.hourSuffix,
    this.halfPast,
    this.meridiem,
    this.lower = _defaultLower,
  });

  /// Günün bölümü → varsayılan saat. UZUN ifadeler önce gelmeli ("öğleden
  /// sonra", "öğle"den önce): eşleşme sırası bu haritanın sırasıdır.
  final Map<String, int> parts;

  /// Bu bölümlerde 12'den küçük saate 12 eklenir ("akşam 7" = 19:00).
  final Set<String> afternoonParts;

  final Map<String, int> weekdays;
  final List<String> today;
  final List<String> tomorrow;
  final List<String> dayAfterTomorrow;

  /// "haftaya salı" / "next Tuesday": bu haftaki gün değil sonraki.
  final List<String> nextWeek;

  /// "saat 9" / "at 9" / "um 9" / "a las 9".
  final RegExp hourPrefix;

  /// [tomorrow] sözcük listesinin yerine geçen kalıp. İspanyolcada "mañana"
  /// hem "yarın" hem "sabah" demek; "la mañana"/"esta mañana" günün bölümüdür,
  /// yarın DEĞİLdir.
  final RegExp? tomorrowPattern;

  /// Türkçedeki "9'da / 9da / 9 da" eki. Konuşma dökümünde kesme işareti
  /// çoğu zaman düşüyor.
  final RegExp? hourSuffix;

  /// Buçuklu saat: yakalanan grup SAAT, dakika 30 olur ("9 buçuk",
  /// "half past 9", "9 y media"). Almanca "halb 9" 8:30 demek olduğu için
  /// bilerek boş bırakıldı — yanlış saat kurmaktansa modele düşmek iyi.
  final RegExp? halfPast;

  /// "9 pm" — 1. grup saat, 2. grup am/pm.
  final RegExp? meridiem;

  /// Küçük harfe çevirim (Türkçe 'I' için ayrı).
  final String Function(String) lower;
}

String _defaultLower(String text) => text.toLowerCase();

/// Türkçe küçük harfe çevirir. Dart'ın `toLowerCase`'i 'I' harfini 'i'
/// yapar (Türkçede 'ı' olmalı) ve 'İ' için birleşik nokta üretir — ikisi de
/// aşağıdaki anahtar kelimeleri kaçırtıyordu.
String _turkishLower(String text) =>
    text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Latin harfleri — kelime sınırı denetimi için. Dart'ın `\b`'si ASCII `\w`
/// üzerinden çalıştığından "ü", "ş", "ñ" gibi harflerde yanlış yerde sınır
/// görüyor; bu yüzden sınır elle denetlenir.
final RegExp _letter = RegExp('[a-zà-öø-ÿğış]');

const _weekdayNames = [
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

Map<String, int> _weekdayMap(List<String> names) => {
  for (var i = 0; i < names.length; i++) names[i]: _weekdayNames[i],
};

final Map<String, _SpokenLanguage> _languages = {
  'tr': _SpokenLanguage(
    parts: const {
      'öğleden sonra': 15,
      'ikindi': 16,
      'sabah': 9,
      'öğlen': 12,
      'öğle': 12,
      'akşam': 19,
      'gece': 22,
    },
    afternoonParts: const {'öğleden sonra', 'ikindi', 'akşam', 'gece'},
    weekdays: _weekdayMap(const [
      'pazartesi',
      'salı',
      'çarşamba',
      'perşembe',
      'cuma',
      'cumartesi',
      'pazar',
    ]),
    today: const ['bugün'],
    tomorrow: const ['yarın'],
    dayAfterTomorrow: const ['öbür gün', 'öbürgün'],
    nextWeek: const ['haftaya', 'gelecek hafta'],
    hourPrefix: RegExp(r'\bsaat\s+(\d{1,2})\b'),
    hourSuffix: RegExp(r"\b(\d{1,2})\s*['’`]?\s*(?:da|de|ta|te)\b"),
    halfPast: RegExp(r'\b(\d{1,2})\s+buçuk\b'),
    lower: _turkishLower,
  ),
  'en': _SpokenLanguage(
    parts: const {
      'afternoon': 15,
      'morning': 9,
      'noon': 12,
      'evening': 19,
      'tonight': 20,
      'night': 22,
    },
    afternoonParts: const {'afternoon', 'evening', 'tonight', 'night'},
    weekdays: _weekdayMap(const [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ]),
    today: const ['today', 'tonight'],
    tomorrow: const ['tomorrow'],
    dayAfterTomorrow: const ['day after tomorrow'],
    nextWeek: const ['next week'],
    hourPrefix: RegExp(r'\bat\s+(\d{1,2})\b'),
    halfPast: RegExp(r'\bhalf past\s+(\d{1,2})\b'),
    meridiem: RegExp(r'\b(\d{1,2})\s*([ap])\.?m\.?\b'),
  ),
  'de': _SpokenLanguage(
    parts: const {
      'nachmittag': 15,
      'vormittag': 10,
      'morgens': 9,
      'am morgen': 9,
      'mittag': 12,
      'abend': 19,
      'nacht': 22,
    },
    afternoonParts: const {'nachmittag', 'abend', 'nacht'},
    weekdays: _weekdayMap(const [
      'montag',
      'dienstag',
      'mittwoch',
      'donnerstag',
      'freitag',
      'samstag',
      'sonntag',
    ]),
    today: const ['heute'],
    // "morgens" ve "übermorgen" kelime sınırı denetiminden geçemez, yani
    // "morgen" yalnız GÜN anlamındayken eşleşir.
    tomorrow: const ['morgen'],
    dayAfterTomorrow: const ['übermorgen'],
    nextWeek: const ['nächste woche', 'kommende woche'],
    hourPrefix: RegExp(r'\bum\s+(\d{1,2})\b'),
  ),
  'es': _SpokenLanguage(
    // "esta tarde" de "por la tarde" de aynı bölümü anlatıyor: uzun ifadeler
    // önce, çıplak sözcükler sonra aranır.
    parts: const {
      'la mañana': 9,
      'mediodía': 12,
      'la tarde': 16,
      'la noche': 22,
      'mañana': 9,
      'tarde': 16,
      'noche': 22,
    },
    afternoonParts: const {'la tarde', 'la noche', 'tarde', 'noche'},
    weekdays: _weekdayMap(const [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ]),
    today: const ['hoy'],
    tomorrow: const ['mañana'],
    // "por la mañana" / "esta mañana" = sabah; yarın DEĞİL.
    tomorrowPattern: RegExp(r'(?<!la\s)(?<!esta\s)\bmañana\b'),
    dayAfterTomorrow: const ['pasado mañana'],
    nextWeek: const ['próxima semana', 'semana que viene'],
    hourPrefix: RegExp(r'\ba\s+las?\s+(\d{1,2})\b'),
    halfPast: RegExp(r'\b(\d{1,2})\s+y media\b'),
  ),
};

/// Bu dilde yerel ayrıştırma var mı.
bool spokenDateTimeSupported(String languageCode) =>
    _languages.containsKey(_baseCode(languageCode));

String _baseCode(String languageCode) =>
    languageCode.split(RegExp('[-_]')).first.toLowerCase();

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

bool _hasAny(String text, List<String> words) =>
    words.any((w) => _hasWord(text, w));

/// Metindeki saat bilgisi. Rastgele sayıları saat sanmamak için sayı
/// MUTLAKA bir saat ipucuna bağlı olmalı: "14:30", "saat 9", "9'da",
/// "9 buçuk", "9 pm". Yoksa yalnızca günün bölümü (sabah/akşam…) kullanılır.
({int hour, int minute})? _parseTime(String text, _SpokenLanguage lang) {
  String? part;
  for (final name in lang.parts.keys) {
    if (_hasWord(text, name)) {
      part = name;
      break;
    }
  }

  int? hour;
  var minute = 0;
  var meridiemPm = false;
  var meridiemAm = false;

  final explicit = RegExp(r'\b(\d{1,2})[:.](\d{2})\b').firstMatch(text);
  final meridiem = lang.meridiem?.firstMatch(text);
  final half = lang.halfPast?.firstMatch(text);
  final prefix = lang.hourPrefix.firstMatch(text);
  final suffix = lang.hourSuffix?.firstMatch(text);

  if (explicit != null) {
    hour = int.parse(explicit.group(1)!);
    minute = int.parse(explicit.group(2)!);
    // "9:30 pm": dakika açık yazılmışken öğleden sonra imi hâlâ geçerli.
    meridiemPm = meridiem?.group(2) == 'p';
    meridiemAm = meridiem != null && !meridiemPm;
  } else if (meridiem != null) {
    hour = int.parse(meridiem.group(1)!);
    meridiemPm = meridiem.group(2) == 'p';
    meridiemAm = !meridiemPm;
  } else if (half != null) {
    hour = int.parse(half.group(1)!);
    minute = 30;
  } else if (prefix != null) {
    hour = int.parse(prefix.group(1)!);
  } else if (suffix != null) {
    hour = int.parse(suffix.group(1)!);
  }

  if (hour == null) {
    if (part == null) return null;
    return (hour: lang.parts[part]!, minute: 0);
  }
  if (hour > 23 || minute > 59) return null;
  // "9 pm" → 21:00, "12 am" → 00:00.
  if (meridiemPm && hour < 12) hour += 12;
  if (meridiemAm && hour == 12) hour = 0;
  // "akşam 7" → 19:00. Saat açıkça 24'lük yazıldıysa (19:00) dokunulmaz.
  if (!meridiemAm &&
      !meridiemPm &&
      part != null &&
      lang.afternoonParts.contains(part) &&
      hour < 12) {
    hour += 12;
  }
  return (hour: hour, minute: minute);
}

/// Metindeki günü verir: gün bulunamazsa null (saat varsa çağıran bugüne
/// düşürür).
DateTime? _parseDay(String text, DateTime now, _SpokenLanguage lang) {
  final today = DateTime(now.year, now.month, now.day);
  // "öbür gün"/"pasado mañana" ÖNCE aranır: içinde "yarın"/"mañana" geçiyor.
  if (_hasAny(text, lang.dayAfterTomorrow)) {
    return today.add(const Duration(days: 2));
  }
  final pattern = lang.tomorrowPattern;
  final isTomorrow = pattern != null
      ? pattern.hasMatch(text)
      : _hasAny(text, lang.tomorrow);
  if (isTomorrow) return today.add(const Duration(days: 1));
  if (_hasAny(text, lang.today)) return today;

  for (final entry in lang.weekdays.entries) {
    if (!_hasWord(text, entry.key)) continue;
    var delta = (entry.value - today.weekday) % 7;
    final nextWeek = _hasAny(text, lang.nextWeek);
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
///
/// [languageCode] 'tr', 'en-US' gibi; desteklenmeyen dilde null döner.
DateTime? parseSpokenDateTime(
  String text, {
  String languageCode = 'tr',
  DateTime? now,
}) {
  final lang = _languages[_baseCode(languageCode)];
  if (lang == null) return null;
  final reference = now ?? DateTime.now();
  final normalized = lang.lower(text);

  final day = _parseDay(normalized, reference, lang);
  final time = _parseTime(normalized, lang);
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

/// Uygulamanın o anki dilinde ayrıştırır — çağrı yerleri dil kodunu tek tek
/// hesaplamasın (biri unutulursa o akış sessizce Türkçeye sabitlenirdi).
DateTime? parseSpokenDateTimeNow(String text, {DateTime? now}) =>
    parseSpokenDateTime(
      text,
      languageCode: Intl.getCurrentLocale(),
      now: now,
    );
