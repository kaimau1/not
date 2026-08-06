/// Konuşmadan tarih/saat çıkaran ayrıştırıcı — uygulamanın 16 dilinin
/// tamamı (tr, en, de, es, fr, it, pt, nl, pl, ru, id, hi, ja, ko, zh, ar).
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

/// Harf sayılan karakterler — kelime sınırı denetimi için. Dart'ın `\b`'si
/// ASCII `\w` üzerinden çalıştığından "ü", "ş", "ñ" gibi harflerde yanlış
/// yerde sınır görüyor; bu yüzden sınır elle denetlenir.
///
/// Latin Ext-A (ğışłśż…), Kiril, Arap ve Devanagari BİLEREK dahil: bu
/// yazılarda kelimeler boşlukla ayrılıyor, harf sayılmazlarsa her konum sınır
/// gibi görünür ve "завтра" uzun bir kelimenin ortasında da eşleşirdi.
///
/// CJK ve Hangul BİLEREK dışarıda: Japonca/Çince kelimeleri boşlukla
/// ayırmıyor, Korece de eklerini kelimeye bitiştiriyor ("내일에"). Onları harf
/// saymak her eşleşmeyi öldürürdü; oralarda alt dize eşleşmesi kabul.
/// Aralıklar `\u` ile yazıldı: Arap bloğunun başındaki karakterler görünmez
/// biçim işaretleri, kaynağa çıplak yazılırsa okunamaz/bozulabilir hâle gelir.
final RegExp _letter = RegExp(
  '[a-zà-öø-ÿğış'
  'Ā-ſ' // Latin Ext-A: ł, ś, ż, ğ, ı, š…
  'Ѐ-ӿ' // Kiril
  '؀-ۿ' // Arap
  'ऀ-ॿ' // Devanagari
  ']',
);

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
  // TUZAK — `\b` ASCII: 'à', 'в', 'ا' gibi harflerin ÖNÜNDE sınır bulunamaz
  // (iki taraf da ASCII-dışı → sınır yok), o yüzden aşağıdaki kalıplarda
  // `\b` yerine `(?:^|\s)` kullanıldı. Sondaki `(?!\d)` de "à 9h"/"9時" gibi
  // saate harf/işaret bitişen yazımları kaçırmamak için `\b`'nin yerini alır.
  'fr': _SpokenLanguage(
    parts: const {
      'après-midi': 15,
      'matin': 9,
      'midi': 12,
      'soir': 19,
      'nuit': 22,
    },
    afternoonParts: const {'après-midi', 'soir', 'nuit'},
    weekdays: _weekdayMap(const [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ]),
    today: const ["aujourd'hui"],
    // "après-demain" ÖNCE aranıyor (_parseDay), ayrıca '-' harf sayılmadığı
    // için burada ayrı bir kalıp gerekmiyor.
    tomorrow: const ['demain'],
    dayAfterTomorrow: const ['après-demain'],
    nextWeek: const ['semaine prochaine'],
    hourPrefix: RegExp(r'(?:^|\s)à\s+(\d{1,2})(?!\d)'),
    halfPast: RegExp(r'\b(\d{1,2})\s*(?:h|heures?)\s+et\s+demie\b'),
  ),
  'it': _SpokenLanguage(
    parts: const {
      'pomeriggio': 15,
      'mattina': 9,
      'mezzogiorno': 12,
      'sera': 19,
      'notte': 22,
    },
    afternoonParts: const {'pomeriggio', 'sera', 'notte'},
    weekdays: _weekdayMap(const [
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ]),
    today: const ['oggi'],
    // "dopodomani" içindeki "domani" kelime sınırından geçemez ('o' harf).
    tomorrow: const ['domani'],
    dayAfterTomorrow: const ['dopodomani'],
    nextWeek: const ['prossima settimana', 'settimana prossima'],
    hourPrefix: RegExp(r'\balle\s+(\d{1,2})\b'),
    halfPast: RegExp(r'\b(\d{1,2})\s+e\s+mezza\b'),
  ),
  'pt': _SpokenLanguage(
    parts: const {
      'da manhã': 9,
      'meio-dia': 12,
      'da tarde': 15,
      'da noite': 21,
      'manhã': 9,
      'tarde': 15,
      'noite': 21,
    },
    afternoonParts: const {'da tarde', 'da noite', 'tarde', 'noite'},
    // Kısa biçimler: "segunda-feira" içindeki "segunda" da eşleşir ('-' harf
    // değil), tersi olmazdı.
    weekdays: _weekdayMap(const [
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado',
      'domingo',
    ]),
    today: const ['hoje'],
    tomorrow: const ['amanhã'],
    dayAfterTomorrow: const ['depois de amanhã'],
    nextWeek: const ['próxima semana', 'semana que vem'],
    hourPrefix: RegExp(r'(?:^|\s)(?:às|as)\s+(\d{1,2})(?!\d)'),
    halfPast: RegExp(r'\b(\d{1,2})\s+e\s+meia\b'),
  ),
  'nl': _SpokenLanguage(
    parts: const {'middag': 15, 'ochtend': 9, 'avond': 19, 'nacht': 22},
    afternoonParts: const {'middag', 'avond', 'nacht'},
    weekdays: _weekdayMap(const [
      'maandag',
      'dinsdag',
      'woensdag',
      'donderdag',
      'vrijdag',
      'zaterdag',
      'zondag',
    ]),
    today: const ['vandaag'],
    tomorrow: const ['morgen'],
    dayAfterTomorrow: const ['overmorgen'],
    nextWeek: const ['volgende week'],
    hourPrefix: RegExp(r'\bom\s+(\d{1,2})\b'),
    // "half 9" Felemenkçede 8:30 — Almancadaki gerekçenin aynısı, bilerek yok.
  ),
  'pl': _SpokenLanguage(
    parts: const {
      'po południu': 15,
      'rano': 9,
      'południe': 12,
      'wieczorem': 19,
      'wieczór': 19,
      'w nocy': 22,
    },
    afternoonParts: const {'po południu', 'wieczorem', 'wieczór', 'w nocy'},
    // Lehçe gün adlarını çekimliyor ("we wtorek" ama "w środę"); taban biçim
    // yazıldı, çekimli hâller modele düşer.
    weekdays: _weekdayMap(const [
      'poniedziałek',
      'wtorek',
      'środa',
      'czwartek',
      'piątek',
      'sobota',
      'niedziela',
    ]),
    today: const ['dzisiaj', 'dziś'],
    tomorrow: const ['jutro'],
    dayAfterTomorrow: const ['pojutrze'],
    nextWeek: const ['przyszłym tygodniu', 'przyszły tydzień'],
    hourPrefix: RegExp(r'\bo\s+(\d{1,2})\b'),
  ),
  'ru': _SpokenLanguage(
    parts: const {
      'после обеда': 15,
      'утром': 9,
      'утро': 9,
      'днём': 13,
      'вечером': 19,
      'вечер': 19,
      'ночью': 22,
      'ночь': 22,
    },
    afternoonParts: const {
      'после обеда',
      'днём',
      'вечером',
      'вечер',
      'ночью',
      'ночь',
    },
    weekdays: _weekdayMap(const [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ]),
    today: const ['сегодня'],
    tomorrow: const ['завтра'],
    dayAfterTomorrow: const ['послезавтра'],
    nextWeek: const ['следующей неделе', 'следующая неделя'],
    hourPrefix: RegExp(r'(?:^|\s)в\s+(\d{1,2})(?!\d)'),
  ),
  'id': _SpokenLanguage(
    parts: const {'sore': 15, 'pagi': 9, 'siang': 12, 'malam': 19},
    afternoonParts: const {'sore', 'malam'},
    // NOT: 'minggu' hem Pazar hem "hafta" demek; "minggu depan" (gelecek
    // hafta) gelecek PAZAR olarak çözülür. Hatırlatıcı bağlamında kabul
    // edilebilir bir yaklaşım, yanlış saat değil.
    weekdays: _weekdayMap(const [
      'senin',
      'selasa',
      'rabu',
      'kamis',
      'jumat',
      'sabtu',
      'minggu',
    ]),
    today: const ['hari ini'],
    tomorrow: const ['besok'],
    dayAfterTomorrow: const ['lusa'],
    nextWeek: const ['minggu depan', 'pekan depan'],
    hourPrefix: RegExp(r'\bjam\s+(\d{1,2})\b'),
  ),
  'hi': _SpokenLanguage(
    parts: const {'दोपहर': 15, 'सुबह': 9, 'शाम': 19, 'रात': 22},
    afternoonParts: const {'दोपहर', 'शाम', 'रात'},
    weekdays: _weekdayMap(const [
      'सोमवार',
      'मंगलवार',
      'बुधवार',
      'गुरुवार',
      'शुक्रवार',
      'शनिवार',
      'रविवार',
    ]),
    today: const ['आज'],
    // 'कल' hem "yarın" hem "dün" demek. Hatırlatıcı istemi doğası gereği
    // GELECEĞE bakar, o yüzden yarın kabul edildi.
    tomorrow: const ['कल'],
    dayAfterTomorrow: const ['परसों'],
    nextWeek: const ['अगले हफ्ते', 'अगले सप्ताह'],
    hourPrefix: RegExp(r'(\d{1,2})\s*बजे'),
  ),
  'ja': _SpokenLanguage(
    parts: const {'午後': 15, '午前': 10, '朝': 9, '昼': 12, '夕方': 18, '夜': 22},
    afternoonParts: const {'午後', '夕方', '夜'},
    weekdays: _weekdayMap(const [
      '月曜日',
      '火曜日',
      '水曜日',
      '木曜日',
      '金曜日',
      '土曜日',
      '日曜日',
    ]),
    today: const ['今日'],
    tomorrow: const ['明日', 'あした'],
    dayAfterTomorrow: const ['明後日', 'あさって'],
    nextWeek: const ['来週'],
    hourPrefix: RegExp(r'(\d{1,2})\s*時'),
  ),
  'ko': _SpokenLanguage(
    parts: const {'오후': 15, '오전': 10, '아침': 9, '점심': 12, '저녁': 19, '밤': 22},
    afternoonParts: const {'오후', '저녁', '밤'},
    weekdays: _weekdayMap(const [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ]),
    today: const ['오늘'],
    tomorrow: const ['내일'],
    dayAfterTomorrow: const ['모레'],
    nextWeek: const ['다음 주', '다음주'],
    hourPrefix: RegExp(r'(\d{1,2})\s*시'),
  ),
  'zh': _SpokenLanguage(
    parts: const {'下午': 15, '上午': 10, '早上': 9, '中午': 12, '晚上': 19, '夜里': 22},
    afternoonParts: const {'下午', '晚上', '夜里'},
    weekdays: _weekdayMap(const [
      '星期一',
      '星期二',
      '星期三',
      '星期四',
      '星期五',
      '星期六',
      '星期日',
    ]),
    today: const ['今天'],
    tomorrow: const ['明天'],
    dayAfterTomorrow: const ['后天', '後天'],
    nextWeek: const ['下周', '下星期'],
    hourPrefix: RegExp(r'(\d{1,2})\s*[点點]'),
  ),
  'ar': _SpokenLanguage(
    parts: const {
      'بعد الظهر': 15,
      'الصباح': 9,
      'صباحا': 9,
      'الظهر': 12,
      'المساء': 19,
      'مساء': 19,
      'الليل': 22,
      'ليلا': 22,
    },
    afternoonParts: const {'بعد الظهر', 'المساء', 'مساء', 'الليل', 'ليلا'},
    weekdays: _weekdayMap(const [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ]),
    today: const ['اليوم'],
    tomorrow: const ['غدا', 'غدًا', 'بكرة'],
    dayAfterTomorrow: const ['بعد غد'],
    nextWeek: const ['الأسبوع القادم', 'الأسبوع المقبل'],
    hourPrefix: RegExp(r'(?:^|\s)(?:الساعة|في)\s+(\d{1,2})(?!\d)'),
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
    parseSpokenDateTime(text, languageCode: Intl.getCurrentLocale(), now: now);
