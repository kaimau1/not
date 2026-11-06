import '../../notes/domain/reminder_repeat.dart';
import 'day_key.dart';

/// **Etkinlik/görev tekrarı** (TAKVIM_PLANI K4, 2026-11-06: "mevcut
/// hatırlatıcı tekrarını genişlet, tek ayrıştırıcı").
///
/// Biçim: `<ReminderRepeat dizesi>[;every=N][;until=YYYY-MM-DD][;count=N]`
/// — ör. `weekly:1,3;every=2;until=2026-12-31`. İlk parça notların
/// `reminderRepeat`iyle AYNI dil ([ReminderRepeat.parse]); ek parametreler
/// yalnız takvimde. Not hatırlatıcısına YAZILMAZ (eski istemci `;`li dizeyi
/// tanımaz, tek seferlik sanar).
///
/// İstisnalar (K3): yerel tekrarda "yalnız bunu sil" = o günün anahtarı
/// etkinliğin `exdates`ine eklenir; taşınmış tekil oluş YOK (gerekirse
/// "bundan sonrakiler" ikiye bölünür). Google etkinliklerinin tekrarını
/// Google çözer (`singleEvents=true`).
class Recurrence {
  const Recurrence(
    this.base, {
    this.every = 1,
    this.until = '',
    this.count = 0,
  });

  static const none = Recurrence(ReminderRepeat.none);

  final ReminderRepeat base;

  /// Her kaçıncı gün/hafta/ay/yıl (≥ 1).
  final int every;

  /// Son gün dahil (`YYYY-MM-DD`); '' = sınırsız.
  final String until;

  /// En çok kaç oluş (ilk oluş dahil); 0 = sınırsız.
  final int count;

  bool get isNone => base.isNone;

  factory Recurrence.parse(String? raw) {
    final parts = (raw ?? '').split(';');
    final base = ReminderRepeat.parse(parts.first);
    if (base.isNone) return none;
    var every = 1;
    var until = '';
    var count = 0;
    for (final p in parts.skip(1)) {
      final i = p.indexOf('=');
      if (i < 0) continue;
      final k = p.substring(0, i).trim();
      final v = p.substring(i + 1).trim();
      switch (k) {
        case 'every':
          every = (int.tryParse(v) ?? 1).clamp(1, 999);
        case 'until':
          until = parseDayKey(v) == null ? '' : v;
        case 'count':
          count = (int.tryParse(v) ?? 0).clamp(0, 9999);
      }
    }
    return Recurrence(base, every: every, until: until, count: count);
  }

  String encode() {
    if (isNone) return '';
    final b = StringBuffer(base.encode());
    if (every > 1) b.write(';every=$every');
    if (until.isNotEmpty) b.write(';until=$until');
    if (count > 0) b.write(';count=$count');
    return b.toString();
  }

  Recurrence copyWith({
    ReminderRepeat? base,
    int? every,
    String? until,
    int? count,
  }) => Recurrence(
    base ?? this.base,
    every: every ?? this.every,
    until: until ?? this.until,
    count: count ?? this.count,
  );

  /// Ay/yıl gününü [start]tan sabitler (bkz. [ReminderRepeat.anchoredTo]).
  Recurrence anchoredTo(DateTime start) =>
      copyWith(base: base.anchoredTo(start));

  bool _intervalOk(DateTime start, DateTime occ) {
    if (every <= 1) return true;
    switch (base.kind) {
      case RepeatKind.none:
        return false;
      case RepeatKind.daily:
        return daysBetween(start, occ) % every == 0;
      case RepeatKind.weekdays:
      case RepeatKind.weekly:
        final ms = startOfDay(start)
            .subtract(Duration(days: start.weekday - 1));
        final mo = startOfDay(occ).subtract(Duration(days: occ.weekday - 1));
        return (daysBetween(ms, mo) ~/ 7) % every == 0;
      case RepeatKind.monthly:
        final diff =
            (occ.year * 12 + occ.month) - (start.year * 12 + start.month);
        return diff % every == 0;
      case RepeatKind.yearly:
        return (occ.year - start.year) % every == 0;
    }
  }

  /// [start] (ilk oluş, her zaman sayılır) ile başlayan dizide BAŞLANGICI
  /// `[from, to)` aralığına düşen oluşlar. [exdates]teki günler atlanır ama
  /// [count]a sayılır (RFC 5545 EXDATE gibi). Tekrarsızsa yalnız [start].
  List<DateTime> between(
    DateTime start,
    DateTime from,
    DateTime to, {
    Set<String> exdates = const {},
    int max = 500,
  }) {
    final out = <DateTime>[];
    bool keep(DateTime d) =>
        !d.isBefore(from) && d.isBefore(to) && !exdates.contains(dayKey(d));
    if (keep(start)) out.add(start);
    if (isNone) return out;
    final rule = base.anchoredTo(start);
    final untilDay = parseDayKey(until);
    var n = 1;
    var cursor = start;
    // Günlük 50 yıl ≈ 18 000 adım: sınırsız döngüye karşı tavan.
    for (var guard = 0; guard < 20000; guard++) {
      final next = rule.next(start, cursor);
      if (next == null || !next.isBefore(to)) break;
      cursor = next;
      if (!_intervalOk(start, next)) continue;
      if (untilDay != null && startOfDay(next).isAfter(untilDay)) break;
      n++;
      if (count > 0 && n > count) break;
      if (keep(next)) {
        out.add(next);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// [after]dan SONRAKİ ilk oluş (hatırlatma kurmak ve görevi ilerletmek için).
  DateTime? nextAfter(
    DateTime start,
    DateTime after, {
    Set<String> exdates = const {},
  }) {
    if (start.isAfter(after) && !exdates.contains(dayKey(start))) return start;
    // Aralık ucu: en seyrek kural (yıllık × every) için bile yeter.
    final to = after.add(Duration(days: 366 * every + 400));
    final list = between(
      start,
      after.add(const Duration(microseconds: 1)),
      to,
      exdates: exdates,
      max: 1,
    );
    return list.isEmpty ? null : list.first;
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.base == base &&
      other.every == every &&
      other.until == until &&
      other.count == count;

  @override
  int get hashCode => Object.hash(base, every, until, count);
}
