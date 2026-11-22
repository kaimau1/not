/// Hızlı ekle için "takvime / bir güne ekle" komutu (kullanıcı isteği
/// 2026-11-22: "bugüne ekle dediğim zaman takvim notu gibi bugüne not
/// ekleyebilir; 1 Ocak'ı ekle, bir hafta sonrasına ekle, bir gün sonrasına
/// ekle gibi şeyler de çalışabilmeli — yeni not oluşturup takvime bağlasın").
///
/// Cümlenin SONUNDAKİ gün hedefi + ekleme fiili aranır:
/// "süt al bugüne ekle", "dişçi randevusu 1 ocağa ekle",
/// "faturayı öde bir hafta sonrasına ekle", "toplantı cumaya ekle",
/// "rapor takvime ekle" (gün yoksa bugün). Yalnız "ekle" (gün hedefi yok)
/// komut DEĞİLDİR — hızlı eklemenin olağan "nota ekle" akışı sürer.
///
/// Saf işlev; [now] testler için. Desteklenen diller: tr, en.
library;

/// Çözülen komut: bağlanacak gün (gece yarısı) ve nota yazılacak metin.
typedef CalendarDayCommand = ({DateTime day, String content});

const _trMonths = <String, int>{
  'ocak': 1,
  'ocağ': 1,
  'şubat': 2,
  'mart': 3,
  'nisan': 4,
  'mayıs': 5,
  'haziran': 6,
  'temmuz': 7,
  'ağustos': 8,
  'eylül': 9,
  'ekim': 10,
  'kasım': 11,
  'aralık': 12,
  'aralığ': 12,
};

const _trWeekdays = <String, int>{
  'pazartesi': DateTime.monday,
  'salı': DateTime.tuesday,
  'çarşamba': DateTime.wednesday,
  'perşembe': DateTime.thursday,
  'cumartesi': DateTime.saturday,
  'cuma': DateTime.friday,
  'pazar': DateTime.sunday,
};

const _trNumbers = <String, int>{
  'bir': 1,
  'iki': 2,
  'üç': 3,
  'dört': 4,
  'beş': 5,
  'altı': 6,
  'yedi': 7,
  'sekiz': 8,
  'dokuz': 9,
  'on': 10,
};

const _enMonths = <String, int>{
  'january': 1,
  'jan': 1,
  'february': 2,
  'feb': 2,
  'march': 3,
  'mar': 3,
  'april': 4,
  'apr': 4,
  'may': 5,
  'june': 6,
  'jun': 6,
  'july': 7,
  'jul': 7,
  'august': 8,
  'aug': 8,
  'september': 9,
  'sep': 9,
  'sept': 9,
  'october': 10,
  'oct': 10,
  'november': 11,
  'nov': 11,
  'december': 12,
  'dec': 12,
};

const _enWeekdays = <String, int>{
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

const _enNumbers = <String, int>{
  'a': 1,
  'an': 1,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
};

String _alt(Iterable<String> words) =>
    (words.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');

/// Türkçe küçük harf ('I' → 'ı', 'İ' → 'i'); uzunluk korunur.
String _trLower(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    b.write(switch (c) {
      'I' => 'ı',
      'İ' => 'i',
      _ => c.toLowerCase(),
    });
  }
  return b.toString();
}

DateTime _addMonths(DateTime d, int months) {
  final m = d.month - 1 + months;
  final year = d.year + (m ~/ 12);
  final month = m % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, d.day > last ? last : d.day);
}

DateTime? _offset(DateTime today, int n, String unit) => switch (unit) {
  'gün' || 'day' || 'days' => DateTime(today.year, today.month, today.day + n),
  'hafta' ||
  'week' ||
  'weeks' => DateTime(today.year, today.month, today.day + 7 * n),
  'ay' || 'month' || 'months' => _addMonths(today, n),
  'yıl' || 'sene' || 'year' || 'years' => _addMonths(today, 12 * n),
  _ => null,
};

/// [day]. ayın [month]'ı; yıl verilmediyse BUGÜNDEN SONRAKİ ilk o gün
/// ("1 ocak" Kasım'da söylenince gelecek yılın 1 Ocak'ı).
DateTime? _dayOfMonth(DateTime today, int day, int month, int? year) {
  if (day < 1 || day > 31) return null;
  DateTime build(int y) {
    final d = DateTime(y, month, day);
    return d.month == month ? d : DateTime(y, month + 1, 0);
  }

  if (year != null) return build(year);
  final thisYear = build(today.year);
  return thisYear.isBefore(today) ? build(today.year + 1) : thisYear;
}

DateTime _nextWeekday(DateTime today, int weekday, {bool nextWeek = false}) {
  var delta = (weekday - today.weekday) % 7;
  if (delta == 0) delta = 7;
  if (nextWeek && delta < 7) delta += 7;
  return DateTime(today.year, today.month, today.day + delta);
}

int? _num(String s, Map<String, int> words) => int.tryParse(s) ?? words[s];

/// Komutu çözer; komut yoksa null.
CalendarDayCommand? parseCalendarDayCommand(
  String text, {
  String languageCode = 'tr',
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final code = languageCode.split(RegExp('[-_]')).first.toLowerCase();
  return switch (code) {
    'tr' => _parseTr(text, today),
    'en' => _parseEn(text, today),
    _ => null,
  };
}

String _clean(String s) =>
    s.replaceAll(RegExp(r'[\s,;:.\-–]+$'), '').replaceAll(RegExp(r'^\s+'), '');

CalendarDayCommand? _parseTr(String text, DateTime today) {
  final lower = _trLower(text);
  // Fiil: "... ekle", "... not ekle", "... takvime ekle", "... kaydet".
  final verb = RegExp(
    r"(?:\s+için)?(?:\s+(takvime|takvimde))?(?:\s+(?:bir\s+)?not(?:\s+olarak)?)?\s+(?:ekle|kaydet|yaz|koy)(?:r?\s*misin)?\s*[.!]*\s*$",
  ).firstMatch(' $lower');
  if (verb == null) return null;
  final calendarWord = verb.group(1) != null;
  // ' ' öneki için bir kayma.
  final head = lower.substring(0, (verb.start - 1).clamp(0, lower.length));
  const suffix = r"(?:['’]?(?:y?[ae]|n[ae]))?";
  // "1 ocağı ekle" (belirtme hâli) da gün hedefi sayılır.
  const monthSuffix = r"(?:['’]?(?:y?[aeıiuü]|n[ae]))?";
  final number = '(\\d{1,2}|${_alt(_trNumbers.keys)})';
  final rules = <(RegExp, DateTime? Function(RegExpMatch))>[
    (
      RegExp('(?:^|\\s)(?:öbür\\s*gün|yarından\\s+sonra)$suffix\$'),
      (_) => DateTime(today.year, today.month, today.day + 2),
    ),
    (
      RegExp('(?:^|\\s)yarın$suffix\$'),
      (_) => DateTime(today.year, today.month, today.day + 1),
    ),
    (RegExp('(?:^|\\s)(?:bu\\s*gün|bugün)$suffix\$'), (_) => today),
    (
      RegExp('(?:^|\\s)haftaya$suffix\$'),
      (_) => DateTime(today.year, today.month, today.day + 7),
    ),
    (
      RegExp(
        '(?:^|\\s)$number\\s+(gün|hafta|ay|yıl|sene)\\s+sonra(?:sı(?:na)?|ya)?\$',
      ),
      (m) {
        final n = _num(m.group(1)!, _trNumbers);
        return n == null ? null : _offset(today, n, m.group(2)!);
      },
    ),
    (
      RegExp(
        '(?:^|\\s)(\\d{1,2})\\s*(?:\\.\\s*)?(${_alt(_trMonths.keys)})$monthSuffix'
        "(?:\\s+(\\d{4})$suffix)?(?:\\s+tarihine)?\$",
      ),
      (m) => _dayOfMonth(
        today,
        int.parse(m.group(1)!),
        _trMonths[m.group(2)!]!,
        m.group(3) == null ? null : int.parse(m.group(3)!),
      ),
    ),
    (
      RegExp(
        '(?:^|\\s)(?:(önümüzdeki|gelecek|haftaya|bu)\\s+)?'
        '(${_alt(_trWeekdays.keys)})(?:y[ae]|[ae]|ye|ya)?(?:\\s+günü(?:ne)?)?\$',
      ),
      (m) => _nextWeekday(
        today,
        _trWeekdays[m.group(2)!]!,
        nextWeek: m.group(1) == 'haftaya',
      ),
    ),
  ];
  for (final (re, toDay) in rules) {
    final m = re.firstMatch(head);
    if (m == null) continue;
    final day = toDay(m);
    if (day == null) return null;
    final content = _clean(text.substring(0, m.start));
    return (day: day, content: content);
  }
  if (calendarWord) {
    return (day: today, content: _clean(text.substring(0, head.length)));
  }
  return null;
}

CalendarDayCommand? _parseEn(String text, DateTime today) {
  final lower = text.toLowerCase();
  final verb = RegExp(
    r'(?:^|\s)(?:add|put|save|note)(?:\s+(?:it|this))?(?:\s+(?:to|for|on|in))?(?:\s+(?:the\s+)?(calendar))?(?:\s+(?:for|on|in))?\s+',
  );
  // "milk add to tomorrow" / "milk add for jan 1": fiil + hedef sonda.
  RegExpMatch? v;
  for (final m in verb.allMatches(lower)) {
    v = m;
  }
  final String head;
  final String target;
  if (v != null) {
    head = text.substring(0, v.start);
    target = lower.substring(v.end).replaceAll(RegExp(r'[\s.!]+$'), '');
  } else {
    final cal = RegExp(
      r'\s+(?:add|put|save)\s+(?:it\s+)?to\s+(?:the\s+)?calendar[\s.!]*$',
    ).firstMatch(lower);
    if (cal == null) return null;
    return (day: today, content: _clean(text.substring(0, cal.start)));
  }
  final number = '(\\d{1,2}|${_alt(_enNumbers.keys)})';
  DateTime? day;
  RegExpMatch? m;
  if (target == 'calendar' || target == 'the calendar' || target == 'today') {
    day = today;
  } else if (target == 'tomorrow') {
    day = DateTime(today.year, today.month, today.day + 1);
  } else if (target == 'next week') {
    day = DateTime(today.year, today.month, today.day + 7);
  } else if ((m = RegExp(
        '^$number\\s+(days?|weeks?|months?|years?)(?:\\s+(?:from\\s+now|later))?\$',
      ).firstMatch(target)) !=
      null) {
    final n = _num(m!.group(1)!, _enNumbers);
    day = n == null ? null : _offset(today, n, m.group(2)!);
  } else if ((m = RegExp(
        '^(${_alt(_enMonths.keys)})\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(\\d{4}))?\$',
      ).firstMatch(target)) !=
      null) {
    day = _dayOfMonth(
      today,
      int.parse(m!.group(2)!),
      _enMonths[m.group(1)!]!,
      m.group(3) == null ? null : int.parse(m.group(3)!),
    );
  } else if ((m = RegExp(
        '^(\\d{1,2})(?:st|nd|rd|th)?\\s+(?:of\\s+)?(${_alt(_enMonths.keys)})(?:,?\\s+(\\d{4}))?\$',
      ).firstMatch(target)) !=
      null) {
    day = _dayOfMonth(
      today,
      int.parse(m!.group(1)!),
      _enMonths[m.group(2)!]!,
      m.group(3) == null ? null : int.parse(m.group(3)!),
    );
  } else if ((m = RegExp('^(?:(next|this)\\s+)?(${_alt(_enWeekdays.keys)})\$')
          .firstMatch(target)) !=
      null) {
    day = _nextWeekday(
      today,
      _enWeekdays[m!.group(2)!]!,
      nextWeek: m.group(1) == 'next',
    );
  }
  if (day == null) return null;
  return (day: day, content: _clean(head));
}
