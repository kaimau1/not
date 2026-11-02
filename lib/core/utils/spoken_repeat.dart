import '../../features/notes/domain/reminder_repeat.dart';

/// Konuşmadaki TEKRARI çıkarır (F18.14): "her pazartesi 9'da", "hafta içi
/// her gün", "every month"… Zaman [parseSpokenDateTime]in işi; burası yalnız
/// tekrar kalıbını tanır. [anchor] çözülen ilk çalma anı (haftalık "her
/// hafta"da günü, aylık/yıllıkta günü ondan). Tanınmazsa [ReminderRepeat.none].
/// tr + en (diğer dillerde tekrar sesle kurulmaz; elle seçilir).
ReminderRepeat parseSpokenRepeat(String text, DateTime anchor) {
  final t = _lower(text);
  bool has(String pattern) => RegExp(pattern, unicode: true).hasMatch(t);

  const trDays = {
    'pazartesi': 1,
    'salı': 2,
    'çarşamba': 3,
    'perşembe': 4,
    'cuma': 5,
    'cumartesi': 6,
    'pazar': 7,
  };
  const enDays = {
    'monday': 1,
    'tuesday': 2,
    'wednesday': 3,
    'thursday': 4,
    'friday': 5,
    'saturday': 6,
    'sunday': 7,
  };

  if (has(r'hafta\s*içi') ||
      has(r'\bevery\s+weekday\b') ||
      has(r'\bweekdays\b')) {
    return ReminderRepeat.weekdays;
  }
  if (has(r'(^|\s)her\s+gün') || has(r'\bevery\s*day\b') || has(r'\bdaily\b')) {
    return ReminderRepeat.daily;
  }
  // "her pazartesi ve perşembe", "every monday and friday".
  final days = <int>{};
  final trMatch = RegExp(r'(^|\s)her\s+(.+)', unicode: true).firstMatch(t);
  if (trMatch != null) {
    // "cumartesi" "cuma"yı, "pazartesi" "pazar"ı içerir: uzundan kısaya,
    // eşleşen kelime metinden düşülür.
    var rest = trMatch.group(2)!;
    final names = trDays.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final name in names) {
      final re = RegExp('(^|[^a-zçğıöşü])$name', unicode: true);
      if (re.hasMatch(rest)) {
        days.add(trDays[name]!);
        rest = rest.replaceAll(re, ' ');
      }
    }
  }
  final enMatch = RegExp(r'\bevery\s+(.+)').firstMatch(t);
  if (enMatch != null) {
    for (final e in enDays.entries) {
      if (RegExp('\\b${e.key}s?\\b').hasMatch(enMatch.group(1)!)) {
        days.add(e.value);
      }
    }
  }
  if (days.isNotEmpty) return ReminderRepeat.weekly(days);
  if (has(r'(^|\s)her\s+hafta') ||
      has(r'\bevery\s+week\b') ||
      has(r'\bweekly\b')) {
    return ReminderRepeat.weekly([anchor.weekday]);
  }
  if (has(r'(^|\s)her\s+ay(\s|$|ın|ın)') ||
      has(r'\bevery\s+month\b') ||
      has(r'\bmonthly\b')) {
    return ReminderRepeat.monthly.anchoredTo(anchor);
  }
  if (has(r'(^|\s)her\s+(yıl|sene)') ||
      has(r'\bevery\s+year\b') ||
      has(r'\b(yearly|annually)\b')) {
    return ReminderRepeat.yearly.anchoredTo(anchor);
  }
  return ReminderRepeat.none;
}

String _lower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// [parseSpokenRepeat]in kayıt dizesi; tekrar yoksa null (alan değişmez).
String? spokenRepeatOrNull(String text, DateTime anchor) {
  final r = parseSpokenRepeat(text, anchor);
  return r.isNone ? null : r.encode();
}
