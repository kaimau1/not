/// **Tekrarlayan hatırlatıcı** (F18.14, 2026-11-02).
///
/// Notta `reminderAt` hep SONRAKİ çalma anıdır; [ReminderRepeat] onun nasıl
/// ilerleyeceğini söyler. Alan (`reminderRepeat`, dize) yoksa ya da boşsa
/// hatırlatıcı tek seferliktir (eski davranış). Eski istemci alanı tanımaz,
/// `extras`ta korur ve yalnız ilk çalmayı kurar — kabul edildi: veri
/// kaybolmaz, yeni istemci açılınca sonraki çalmayı kurar.
///
/// Dize biçimi (kalıcı — değiştirme): `daily`, `weekdays`, `weekly:1,3`
/// (ISO gün numaraları, 1 = Pazartesi), `monthly:31` (ayın günü), `yearly:2-29`
/// (ay-gün). Ay/yıl GÜNÜ dizede tutulur: `reminderAt` her çalmada ilerler ve
/// kısa ayda 28'e kıstırılır — gün ondan okunsaydı 31'i bir kez Şubat'a
/// düşen hatırlatıcı sonsuza dek 28'inde çalardı.
class ReminderRepeat {
  const ReminderRepeat._(
    this.kind, [
    this.days = const [],
    this.day = 0,
    this.month = 0,
  ]);

  final RepeatKind kind;

  /// [RepeatKind.weekly] için seçili günler (1–7, sıralı, tekrarsız).
  final List<int> days;

  /// Aylık/yıllık: çalınacak gün (1–31); 0 = çapadan oku.
  final int day;

  /// Yıllık: ay (1–12); 0 = çapadan oku.
  final int month;

  /// Ay/yıl gününü [anchor]dan sabitler (seçim anında çağrılır).
  ReminderRepeat anchoredTo(DateTime anchor) => switch (kind) {
    RepeatKind.monthly => ReminderRepeat._(kind, const [], anchor.day),
    RepeatKind.yearly => ReminderRepeat._(
      kind,
      const [],
      anchor.day,
      anchor.month,
    ),
    _ => this,
  };

  static const none = ReminderRepeat._(RepeatKind.none);
  static const daily = ReminderRepeat._(RepeatKind.daily);
  static const weekdays = ReminderRepeat._(RepeatKind.weekdays);
  static const monthly = ReminderRepeat._(RepeatKind.monthly);
  static const yearly = ReminderRepeat._(RepeatKind.yearly);

  factory ReminderRepeat.weekly(Iterable<int> days) {
    final set = {
      for (final d in days)
        if (d >= 1 && d <= 7) d,
    }.toList()..sort();
    return set.isEmpty ? none : ReminderRepeat._(RepeatKind.weekly, set);
  }

  bool get isNone => kind == RepeatKind.none;

  factory ReminderRepeat.parse(String? raw) {
    final s = (raw ?? '').trim();
    switch (s) {
      case 'daily':
        return daily;
      case 'weekdays':
        return weekdays;
      case 'monthly':
        return monthly;
      case 'yearly':
        return yearly;
    }
    if (s.startsWith('monthly:')) {
      final d = int.tryParse(s.substring(8)) ?? 0;
      return ReminderRepeat._(RepeatKind.monthly, const [], d.clamp(0, 31));
    }
    if (s.startsWith('yearly:')) {
      final parts = s.substring(7).split('-');
      final m = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final d = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return ReminderRepeat._(
        RepeatKind.yearly,
        const [],
        d.clamp(0, 31),
        m.clamp(0, 12),
      );
    }
    if (s.startsWith('weekly:')) {
      return ReminderRepeat.weekly([
        for (final p in s.substring(7).split(','))
          if (int.tryParse(p.trim()) != null) int.parse(p.trim()),
      ]);
    }
    return none;
  }

  String encode() => switch (kind) {
    RepeatKind.none => '',
    RepeatKind.daily => 'daily',
    RepeatKind.weekdays => 'weekdays',
    RepeatKind.weekly => 'weekly:${days.join(',')}',
    RepeatKind.monthly => day > 0 ? 'monthly:$day' : 'monthly',
    RepeatKind.yearly => day > 0 && month > 0 ? 'yearly:$month-$day' : 'yearly',
  };

  /// [anchor]ın saatini ve (ay/yıl için) gününü koruyarak [after]dan SONRAKİ
  /// ilk çalma. Ayın 31'i kısa ayda ay sonuna, 29 Şubat artık olmayan yılda
  /// 28 Şubat'a düşer; sonraki ayda yine 31'e döner (gün çapadan okunur).
  /// Yerel saatle hesaplanır: yaz saati geçişinde duvar saati korunur.
  DateTime? next(DateTime anchor, DateTime after) {
    DateTime at(int y, int m, int d) =>
        DateTime(y, m, d, anchor.hour, anchor.minute, anchor.second);
    int clampDay(int y, int m, int d) {
      final last = DateTime(y, m + 1, 0).day;
      return d > last ? last : d;
    }

    switch (kind) {
      case RepeatKind.none:
        return null;
      case RepeatKind.daily:
      case RepeatKind.weekdays:
      case RepeatKind.weekly:
        final allowed = switch (kind) {
          RepeatKind.weekdays => const [1, 2, 3, 4, 5],
          RepeatKind.weekly => days,
          _ => const [1, 2, 3, 4, 5, 6, 7],
        };
        // Takvim günü ilerletilir (Duration DEĞİL: yaz saati günü 23/25 sa).
        var day = DateTime(after.year, after.month, after.day);
        for (var i = 0; i < 15; i++) {
          final candidate = at(day.year, day.month, day.day);
          if (candidate.isAfter(after) && allowed.contains(candidate.weekday)) {
            return candidate;
          }
          day = DateTime(day.year, day.month, day.day + 1);
        }
        return null;
      case RepeatKind.monthly:
        var y = after.year;
        var m = after.month;
        for (var i = 0; i < 3; i++) {
          final c = at(y, m, clampDay(y, m, day > 0 ? day : anchor.day));
          if (c.isAfter(after)) return c;
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
        }
        return null;
      case RepeatKind.yearly:
        final mm = month > 0 ? month : anchor.month;
        final dd = day > 0 ? day : anchor.day;
        for (var y = after.year; y <= after.year + 2; y++) {
          final c = at(y, mm, clampDay(y, mm, dd));
          if (c.isAfter(after)) return c;
        }
        return null;
    }
  }

  /// [anchor]dan başlayarak [after]dan sonraki en çok [count] çalma.
  List<DateTime> upcoming(DateTime anchor, DateTime after, int count) {
    final out = <DateTime>[];
    var cursor = after;
    for (var i = 0; i < count; i++) {
      final n = next(anchor, cursor);
      if (n == null) break;
      out.add(n);
      cursor = n;
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderRepeat &&
      other.kind == kind &&
      other.day == day &&
      other.month == month &&
      other.days.length == days.length &&
      [for (var i = 0; i < days.length; i++) other.days[i] == days[i]]
          .every((b) => b);

  @override
  int get hashCode => Object.hash(kind, day, month, Object.hashAll(days));
}

enum RepeatKind { none, daily, weekdays, weekly, monthly, yearly }
