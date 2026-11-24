import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../../notes/domain/note.dart';
import '../domain/agenda.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/holidays.dart';
import '../domain/routine.dart';
import '../domain/task_item.dart';
import 'month_grid.dart' show gridStartFor;
import 'pinch_zoom.dart';
import '../../../app/theme/app_tokens.dart';

/// Takvimin görünümleri; yakınlaştırma sırası yıl → ay → hafta.
enum CalendarView { year, month, week, agenda }

/// Görünümlerin ortak verisi (sayfa başına yeniden sorgu YOK; aralık
/// hesabı bellekte, `buildAgenda`).
class CalendarData {
  const CalendarData({
    this.events = const [],
    this.tasks = const [],
    this.reminders = const [],
    this.timedNotes = const [],
    this.routines = const [],
    this.routineLogs = const {},
    this.holidays = const HolidayCalendar.off(),
    this.dayNotes = const {},
  });

  /// Güne bağlı notlar (gün anahtarı → not + saat).
  final Map<String, List<DayNote>> dayNotes;

  /// Resmî ve dinî tatiller (kayıt değil; hücrede ayrı şerit).
  final HolidayCalendar holidays;

  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<Note> reminders;

  /// Zamanlı notlar (`expiresAt`, U4): arşivlenecekleri gün görünür.
  final List<Note> timedNotes;

  /// Rutinler ve günlük kayıtları (Faz 53).
  final List<Routine> routines;
  final Map<String, Map<String, RoutineLog>> routineLogs;

  Map<String, List<AgendaEntry>> range(DateTime from, DateTime to) =>
      buildAgenda(
        from: from,
        to: to,
        events: events,
        tasks: tasks,
        reminderNotes: reminders,
        timedNotes: timedNotes,
        routines: routines,
        routineLogs: routineLogs,
        dayNotes: dayNotes,
      );
}

// ------------------------------------------------------------ dönem hesabı

/// Sayfa dizinlerinin başlangıcı (PageView sonsuz değil: 2000–2100).
final kCalendarOrigin = DateTime(2000);
const kMonthPages = 1200;
const kYearPages = 100;
const kWeekPages = 5250;

DateTime weekStartOf(DateTime d, int firstDayOfWeekIndex) {
  final off = (d.weekday % 7 - firstDayOfWeekIndex + 7) % 7;
  return DateTime(d.year, d.month, d.day - off);
}

int monthIndexOf(DateTime d) => (d.year - 2000) * 12 + d.month - 1;
DateTime monthAtIndex(int i) => DateTime(2000 + i ~/ 12, i % 12 + 1);

int weekIndexOf(DateTime d, int firstDow) =>
    daysBetween(
      weekStartOf(kCalendarOrigin, firstDow),
      weekStartOf(d, firstDow),
    ) ~/
    7;

DateTime weekAtIndex(int i, int firstDow) {
  final o = weekStartOf(kCalendarOrigin, firstDow);
  return DateTime(o.year, o.month, o.day + i * 7);
}

int yearIndexOf(DateTime d) => d.year - 2000;

/// Satırın vurgu rengi.
Color entryColor(AgendaEntry e, ColorScheme scheme) => switch (e) {
  EventOccurrence(:final event) =>
    event.color != null ? Color(event.color!) : scheme.primary,
  TaskEntry() => scheme.tertiary,
  ReminderEntry() => scheme.secondary,
  RoutineEntry(:final routine) =>
    routine.color != null ? Color(routine.color!) : scheme.primary,
};

String entryTitle(AgendaEntry e, AppLocalizations l10n) {
  final raw = switch (e) {
    EventOccurrence(:final event) => event.title,
    TaskEntry(:final task) => task.title,
    ReminderEntry(:final note) =>
      note.displayTitle.trim().isNotEmpty
          ? note.displayTitle
          : note.locked
          ? ''
          : note.toPlainText().split('\n').first,
    RoutineEntry(:final routine) => routine.title,
  };
  final t = raw.trim();
  if (t.isNotEmpty) return t;
  return e is ReminderEntry ? l10n.remindersUntitled : l10n.eventUntitled;
}

// ------------------------------------------------------------------ AY

/// **AY GÖRÜNÜMÜ**: 6 hafta satırı ekranı doldurur; hücrede sığdığı kadar
/// kayıt şeridi + "+n". Hafta satırları [targets]a kaydedilir (iki parmakla
/// yakınlaştırınca o hafta açılır).
class MonthPage extends StatelessWidget {
  const MonthPage({
    super.key,
    required this.month,
    required this.data,
    required this.today,
    required this.selected,
    required this.firstDow,
    required this.targets,
    required this.onDayTap,
    required this.onDayLongPress,
    this.onDayDoubleTap,
    this.onEntryMove,
    this.onNoteTap,
    this.compact = false,
  });

  /// Gün paneli açık, takvim daraldı: hücreler daha sıkı (gün numarası sağ
  /// üstte, altında sığdığı kadar not/etkinlik/etiket şeridi).
  final bool compact;

  /// Hücredeki not şeridine doğrudan dokunuldu (hızlı önizleme açılır).
  final void Function(Note note, DateTime day)? onNoteTap;

  /// Güne çift dokunuş: yalnız o günün sayfası açılır.
  final ValueChanged<DateTime>? onDayDoubleTap;

  /// Kayıt başka güne SÜRÜKLENİP bırakıldı (F47.5); null = taşıma yok.
  final void Function(AgendaEntry entry, DateTime day)? onEntryMove;

  final DateTime month;
  final CalendarData data;
  final DateTime today;
  final DateTime selected;
  final int firstDow;
  final ZoomTargets targets;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = gridStartFor(month, firstDow);
    final agenda = data.range(
      start,
      DateTime(start.year, start.month, start.day + 42),
    );
    final line = scheme.outlineVariant.withValues(alpha: 0.7);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    // Kısa ad: tek harfte Pazartesi ile Pazar ikisi de "P".
                    DateFormat.E().dateSymbols.SHORTWEEKDAYS[(firstDow + i) %
                        7],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: (firstDow + i) % 7 == 0 || (firstDow + i) % 7 == 6
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 3, 3),
            child: Column(
              children: [
                for (var w = 0; w < 6; w++)
                  Expanded(
                    child: Row(
                      key: targets.keyFor((
                        'week-row',
                        monthIndexOf(month),
                        w,
                      ), DateTime(start.year, start.month, start.day + w * 7)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _MonthCell(
                              day: DateTime(
                                start.year,
                                start.month,
                                start.day + w * 7 + d,
                              ),
                              month: month,
                              today: today,
                              selected: selected,
                              entries:
                                  agenda[dayKey(
                                    DateTime(
                                      start.year,
                                      start.month,
                                      start.day + w * 7 + d,
                                    ),
                                  )] ??
                                  const [],
                              holiday: data.holidays.on(
                                DateTime(
                                  start.year,
                                  start.month,
                                  start.day + w * 7 + d,
                                ),
                              ),
                              line: line,
                              compact: compact,
                              onTap: onDayTap,
                              onLongPress: onDayLongPress,
                              onDoubleTap: onDayDoubleTap,
                              onEntryMove: onEntryMove,
                              onNoteTap: onNoteTap,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.month,
    required this.today,
    required this.selected,
    required this.entries,
    required this.line,
    required this.onTap,
    required this.onLongPress,
    this.holiday,
    this.onDoubleTap,
    this.onEntryMove,
    this.onNoteTap,
    this.compact = false,
  });

  final bool compact;
  final void Function(AgendaEntry entry, DateTime day)? onEntryMove;
  final void Function(Note note, DateTime day)? onNoteTap;
  final ValueChanged<DateTime>? onDoubleTap;
  final DateTime day;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<AgendaEntry> entries;
  final Holiday? holiday;
  final Color line;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final inMonth = day.month == month.month;
    final isToday = day == today;
    final isSelected = day == selected && !isToday;
    final move = onEntryMove;
    if (move == null) {
      return _cell(context, isToday, isSelected, inMonth, l10n, scheme, false);
    }
    return DragTarget<AgendaEntry>(
      onWillAcceptWithDetails: (d) => movedToDay(d.data, day) != null,
      onAcceptWithDetails: (d) => move(d.data, day),
      builder: (context, candidates, _) => _cell(
        context,
        isToday,
        isSelected,
        inMonth,
        l10n,
        scheme,
        candidates.isNotEmpty,
      ),
    );
  }

  /// Kayıt şeridi uzun basınca sürüklenir (taşınabiliyorsa).
  Widget _draggableChip(
    BuildContext context,
    AgendaEntry e,
    Widget chip,
    double width,
  ) {
    if (onEntryMove == null || !canMoveEntry(e)) return chip;
    return LongPressDraggable<AgendaEntry>(
      data: e,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: math.max(width, 72), child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  /// Hücre üst başlığı: sağ üstte gün numarası, taşan kayıt varsa sol üstte
  /// `+N` sayacı (hücre içindeki boşluk tamamen not/etiket şeritlerine kalır).
  Widget _dayHeader(
    BuildContext context, {
    required bool wide,
    required bool isToday,
    required bool isSelected,
    required bool off,
    required bool inMonth,
    required Color dayColor,
    required ColorScheme scheme,
    required AppLocalizations l10n,
    required int overflow,
  }) {
    final badgeSize = wide
        ? kMonthBadgeSizeWide
        : compact
        ? kMonthBadgeSizeCompact
        : kMonthBadgeSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 2, 3, 1),
      child: Row(
        children: [
          if (overflow > 0)
            Semantics(
              label: l10n.calendarMoreDays,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: inMonth
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: wide ? 9.5 : 8.5,
                    height: 1.0,
                    fontWeight: AppWeight.strong,
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    color: off ? scheme.error : scheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: wide
                    ? 12.5
                    : compact
                    ? 10.5
                    : 11.5,
                height: 1.0,
                fontWeight: isToday || isSelected || off
                    ? AppWeight.strong
                    : AppWeight.medium,
                color: dayColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Çok dar dikey yükseklikte (yatay/bölünmüş ekran) taşmayı önleyen ince
  /// renkli çizgi yedeği — gün numarası yine sağ üstte.
  Widget _microBarsFallback(
    BuildContext context,
    BoxConstraints c, {
    required bool isToday,
    required bool isSelected,
    required bool off,
    required bool inMonth,
    required Color dayColor,
    required ColorScheme scheme,
    required AppLocalizations l10n,
  }) {
    final colors = <Color>[
      if (holiday != null) scheme.error,
      for (final e in entries) entryColor(e, scheme),
    ];
    final bars = math.max(0, math.min(3, ((c.maxHeight - 20) / 5).floor()));
    final overflow = math.max(0, colors.length - bars);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dayHeader(
          context,
          wide: false,
          isToday: isToday,
          isSelected: isSelected,
          off: off,
          inMonth: inMonth,
          dayColor: dayColor,
          scheme: scheme,
          l10n: l10n,
          overflow: overflow,
        ),
        for (final color in colors.take(bars))
          Container(
            height: 3,
            margin: const EdgeInsets.fromLTRB(4, 1, 4, 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.hair),
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    bool isToday,
    bool isSelected,
    bool inMonth,
    AppLocalizations l10n,
    ColorScheme scheme,
    bool hovering,
  ) {
    // KÂĞIT HÜCRELER (kullanıcı bulgusu 2026-11-07: "çok düz, günler
    // arasında belli belirsiz çizgi var"): her gün masanın üstünde ayrı,
    // köşesi yuvarlak bir kâğıt; hafta sonu hafif koyu, ay dışı günler
    // sönük, bugün vurgu kenarlı. Gölge YOK (42 hücre × her kare — akıcılık
    // bütçesi); hücre kendi `Material`ı: dokunma dalgası zeminin üstünde.
    final card = AppTokens.of(context).card;
    final weekend = day.weekday >= DateTime.saturday;
    final off = holiday?.isOff ?? false;
    final radius = BorderRadius.circular(AppRadius.s);
    final Color fill;
    if (hovering) {
      fill = scheme.primaryContainer.withValues(alpha: 0.7);
    } else if (isSelected) {
      fill = scheme.primaryContainer.withValues(alpha: 0.55);
    } else if (!inMonth) {
      fill = scheme.surfaceContainerLow.withValues(alpha: 0.3);
    } else if (off) {
      fill = Color.alphaBlend(
        scheme.error.withValues(alpha: 0.07),
        card.withValues(alpha: AppAlpha.strong),
      );
    } else if (weekend) {
      fill = scheme.surfaceContainerHigh.withValues(alpha: AppAlpha.strong);
    } else {
      fill = card.withValues(alpha: AppAlpha.strong);
    }
    final side = isToday
        ? BorderSide(color: scheme.primary, width: 1.5)
        : isSelected
        ? BorderSide(color: scheme.primary.withValues(alpha: AppAlpha.muted))
        : BorderSide(color: line, width: 0.8);
    final dayColor = isToday
        ? scheme.onPrimary
        : !inMonth
        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
        : off
        ? scheme.error
        : scheme.onSurface;
    final h = holiday;
    // O günkü notların benzersiz etiketleri: asıl not/etkinliklerden sonra
    // hücrede yer kalırsa `#etiket` hapı olarak görünür.
    final noteTags = <String>[];
    final seenTags = <String>{};
    for (final e in entries) {
      if (e is ReminderEntry) {
        for (final t in e.note.tags) {
          final clean = t.trim();
          if (clean.isNotEmpty && seenTags.add(clean) && noteTags.length < 3) {
            noteTags.add(clean);
          }
        }
      }
    }
    final primaryChips =
        <Widget Function(int lines, double height, double width, double font)>[
          if (h != null)
            (lines, height, width, font) => HolidayChip(
              holiday: h,
              height: height,
              lines: lines,
              dim: !inMonth,
              fontSize: font,
            ),
          for (final e in entries)
            (lines, height, width, font) {
              final base = _MonthChip(
                entry: e,
                height: height,
                lines: lines,
                dim: !inMonth,
                fontSize: font,
                onTap: e is ReminderEntry && onNoteTap != null
                    ? () => onNoteTap!(e.note, day)
                    : null,
              );
              return _draggableChip(context, e, base, width);
            },
        ];
    return Semantics(
      button: true,
      label: [
        DateFormat.yMMMMEEEEd().format(day),
        if (h != null) h.name,
      ].join(', '),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(borderRadius: radius, side: side),
          child: InkWell(
            borderRadius: radius,
            onTap: () => onTap(day),
            onDoubleTap: onDoubleTap == null ? null : () => onDoubleTap!(day),
            onLongPress: () => onLongPress(day),
            child: LayoutBuilder(
              builder: (context, c) {
                // YAZI SIĞSIN (kullanıcı isteği 2026-11-07 + 2026-11-21):
                // gün numarası sağ üstte; altında sığdığı kadar not, etkinlik
                // ve `#etiket` şeridi. Varsayılan dar görünümde bile kör çizgi
                // yerine okunur başlıklar yer alır; taşanlar sol üstte `+N`.
                final wide = !compact && monthCellRoomy(c.maxWidth, c.maxHeight);
                final headerH = wide
                    ? kMonthBadgeSizeWide + 4
                    : compact
                    ? kMonthBadgeSizeCompact + 3
                    : kMonthBadgeSize + 4;
                final avail = c.maxHeight - headerH;
                if (avail < kMonthChipCompactLine) {
                  return _microBarsFallback(
                    context,
                    c,
                    isToday: isToday,
                    isSelected: isSelected,
                    off: off,
                    inMonth: inMonth,
                    dayColor: dayColor,
                    scheme: scheme,
                    l10n: l10n,
                  );
                }
                final oneLine = compact
                    ? kMonthChipCompactLine
                    : wide
                    ? kMonthChipOneLineWide
                    : kMonthChipOneLine;
                final twoLine = wide
                    ? kMonthChipTwoLineWide
                    : kMonthChipTwoLine;
                // DAR GÖRÜNÜMDE DE iki satır (kullanıcı bulgusu 2026-11-21:
                // "29 Ekim Bayramı gibi şeyler sığmamış" — panel açıkken
                // hücre tek satıra kırpıyordu "29 Ekim Ba"): yer varsa.
                final twoLines =
                    primaryChips.isNotEmpty &&
                    noteTags.isEmpty &&
                    primaryChips.length * (twoLine + 1) <= avail;
                final chipH = twoLines ? twoLine : oneLine;
                final room = math.max(0, (avail / (chipH + 1)).floor());
                final shownPrimary = math.min(primaryChips.length, room);
                final overflow = primaryChips.length - shownPrimary;
                final freeAfterPrimary = math.max(0, room - shownPrimary);
                final shownTags = overflow == 0
                    ? math.min(noteTags.length, freeAfterPrimary)
                    : 0;
                final chipFont = compact
                    ? 8.5
                    : wide
                    ? 11.0
                    : 9.5;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _dayHeader(
                      context,
                      wide: wide,
                      isToday: isToday,
                      isSelected: isSelected,
                      off: off,
                      inMonth: inMonth,
                      dayColor: dayColor,
                      scheme: scheme,
                      l10n: l10n,
                      overflow: overflow,
                    ),
                    for (final chip in primaryChips.take(shownPrimary))
                      chip(twoLines ? 2 : 1, chipH, c.maxWidth, chipFont),
                    for (final tag in noteTags.take(shownTags))
                      _TagCellChip(
                        tag: tag,
                        height: oneLine,
                        dim: !inMonth,
                        fontSize: chipFont,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Gün numarası dairesi boyutları (sağ üst köşe).
const kMonthBadgeSizeCompact = 17.0;
const kMonthBadgeSize = 20.0;
const kMonthBadgeSizeWide = 22.0;

/// Ay şeridinin yüksekliği: dar / tek satır / iki satır.
const kMonthChipCompactLine = 13.0;
const kMonthChipOneLine = 14.0;
const kMonthChipTwoLine = 25.0;

/// Geniş hücre (KW-9): bu genişlikten itibaren gün 13, şerit 11 pt.
const kMonthWideCell = 140.0;
const kMonthChipOneLineWide = 16.0;
const kMonthChipTwoLineWide = 29.0;

/// Uzun hücre (P78 KT-23, dikey tablet ~80 x 120 dp): bu ölçülerden
/// itibaren de geniş hücre yazısı. Telefon (≈ 51 dp genişlik) ve yatay
/// telefon (kısa hücre) etkilenmez.
const kMonthTallCellWidth = 72.0;
const kMonthTallCellHeight = 100.0;

/// Hücre "geniş" yazıyı taşır mı (KW-9 + KT-23).
bool monthCellRoomy(double width, double height) =>
    width >= kMonthWideCell ||
    (width >= kMonthTallCellWidth && height >= kMonthTallCellHeight);

/// Hücre ölçüsüne göre şerit yazısı (KW-9, KT-23).
double monthChipFontSize(double cellWidth, [double cellHeight = 0]) =>
    monthCellRoomy(cellWidth, cellHeight) ? 11 : 9.5;

/// Ay dışı günün şerit tonu (KW-4): saydamlık (%50 → 2,3:1) yerine
/// sönük zemin + `onSurfaceVariant` yazı (M3'te ≥ 4,5:1).
({Color background, Color foreground}) monthChipDimTone(ColorScheme scheme) => (
  background: scheme.surfaceContainerHigh,
  foreground: scheme.onSurfaceVariant,
);

/// Şerit kutusu: kayıt, not ve tatil şeridi aynı biçimde; sol kenar vurgu
/// çizgisiyle notlar/etkinlikler hücrede ilk bakışta ayrışır.
Widget _chipBox({
  required String text,
  required double height,
  required int lines,
  required Color background,
  required Color foreground,
  Color? accent,
  Border? border,
  bool strike = false,
  double fontSize = 9.5,
  VoidCallback? onTap,
}) {
  final box = Container(
    height: height,
    margin: const EdgeInsets.fromLTRB(2, 0, 2, 1),
    padding: EdgeInsets.fromLTRB(accent != null ? 0 : 3, 0, 3, 0),
    alignment: Alignment.centerLeft,
    clipBehavior: accent != null ? Clip.antiAlias : Clip.none,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      border: border,
    ),
    child: accent != null
        ? Row(
            children: [
              Container(width: 2, color: accent),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  text,
                  maxLines: lines,
                  overflow: lines > 1
                      ? TextOverflow.ellipsis
                      : TextOverflow.clip,
                  softWrap: lines > 1,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.08,
                    color: foreground,
                    decoration: strike ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          )
        : Text(
            text,
            maxLines: lines,
            // Tek satırda harf harf kırpılır (daha çok harf görünür); iki satırda
            // sözcükten kırılır, taşan "…".
            overflow: lines > 1 ? TextOverflow.ellipsis : TextOverflow.clip,
            softWrap: lines > 1,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.08,
              color: foreground,
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
  );
  if (onTap == null) return box;
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: box,
  );
}

class _TagCellChip extends StatelessWidget {
  const _TagCellChip({
    required this.tag,
    required this.height,
    required this.dim,
    required this.fontSize,
  });

  final String tag;
  final double height;
  final bool dim;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = dim ? monthChipDimTone(scheme) : null;
    return _chipBox(
      text: '#$tag',
      height: height,
      lines: 1,
      fontSize: fontSize,
      background:
          tone?.background ??
          scheme.secondaryContainer.withValues(alpha: AppAlpha.strong),
      foreground: tone?.foreground ?? scheme.onSecondaryContainer,
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.entry,
    required this.height,
    required this.dim,
    this.lines = 1,
    this.fontSize = 9.5,
    this.onTap,
  });

  final AgendaEntry entry;
  final double height;
  final bool dim;
  final int lines;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = entryColor(entry, scheme);
    final solid = entry is EventOccurrence && entry.allDay;
    final done = entry is TaskEntry && (entry as TaskEntry).task.completed;
    final google =
        entry is EventOccurrence && (entry as EventOccurrence).event.fromGoogle;
    final tone = dim ? monthChipDimTone(scheme) : null;
    final e = entry;
    final hasCustomNoteColor =
        e is ReminderEntry &&
        (e.note.color != NoteColor.none || e.note.customColor != null);
    final noteBg = hasCustomNoteColor
        ? NoteColors.noteSurfaceIn(theme, e.note)
        : null;
    final noteInk = hasCustomNoteColor
        ? NoteColors.noteInkIn(theme, e.note)
        : null;
    // Güne SAATLE bağlı not şeritte saatiyle ("09:00 Toplantı notu").
    final title = e is ReminderEntry && e.isDayLink && e.linkTimed
        ? '${formatHm(e.at.hour, e.at.minute)} ${entryTitle(e, context.l10n)}'
        : entryTitle(e, context.l10n);
    return _chipBox(
      text: title,
      height: height,
      lines: lines,
      fontSize: fontSize,
      strike: done,
      onTap: onTap,
      accent: tone != null || solid
          ? null
          : (noteInk ?? color).withValues(alpha: AppAlpha.strong),
      background:
          tone?.background ??
          noteBg ??
          (solid ? color : color.withValues(alpha: 0.16)),
      foreground:
          tone?.foreground ??
          noteInk ??
          (solid ? scheme.onPrimary : scheme.onSurface),
      // Google Takvim etkinliği farklı kenarlıkla (F48.3).
      border: google
          ? Border.all(color: color.withValues(alpha: 0.8), width: 0.8)
          : null,
    );
  }
}

/// Resmî/dinî tatil şeridi: tam gün dolu kırmızı, arife (yarım gün) kenarlı.
class HolidayChip extends StatelessWidget {
  const HolidayChip({
    super.key,
    required this.holiday,
    this.height = kMonthChipOneLine,
    this.lines = 1,
    this.dim = false,
    this.full = false,
    this.estimatedLabel,
    this.fontSize = 9.5,
  });

  final double fontSize;

  /// Tahmini tarihte ada eklenir ("tahmini"); null = eklenmez.
  final String? estimatedLabel;

  final Holiday holiday;
  final double height;
  final int lines;
  final bool dim;

  /// Uzun ad (hafta/gün sayfası); ay hücresinde kısa ad.
  final bool full;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final off = holiday.isOff;
    return Semantics(
      label: holiday.name,
      excludeSemantics: true,
      child: _chipBox(
        text: [
          full ? holiday.name : holiday.short,
          if (holiday.estimated && estimatedLabel != null) '($estimatedLabel)',
        ].join(' '),
        height: height,
        lines: lines,
        fontSize: fontSize,
        background: dim
            ? monthChipDimTone(scheme).background
            : off
            ? scheme.error.withValues(alpha: AppAlpha.strong)
            : scheme.error.withValues(alpha: 0.1),
        foreground: dim
            ? monthChipDimTone(scheme).foreground
            : off
            ? scheme.onError
            : scheme.error,
        border: off || dim
            ? null
            : Border.all(
                color: scheme.error.withValues(alpha: AppAlpha.muted),
                width: 0.8,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------- HAFTA

/// Saat ızgarasında bir blok (çakışanlar yan yana sütunlara bölünür).
class TimedBlock {
  TimedBlock(this.entry, this.start, this.end);

  final AgendaEntry entry;
  final DateTime start;
  final DateTime end;
  int column = 0;
  int columns = 1;
}

/// Çakışan blokları sütunlara yerleştirir (küme başına sütun sayısı ortak).
List<TimedBlock> layoutTimedBlocks(List<TimedBlock> blocks) {
  final sorted = [...blocks]
    ..sort((a, b) {
      final c = a.start.compareTo(b.start);
      return c != 0 ? c : b.end.compareTo(a.end);
    });
  var cluster = <TimedBlock>[];
  var colEnds = <DateTime>[];
  DateTime? clusterEnd;
  void flush() {
    for (final b in cluster) {
      b.columns = colEnds.length;
    }
    cluster = [];
    colEnds = [];
    clusterEnd = null;
  }

  for (final b in sorted) {
    if (clusterEnd != null && !b.start.isBefore(clusterEnd!)) flush();
    var col = colEnds.indexWhere((end) => !end.isAfter(b.start));
    if (col < 0) {
      col = colEnds.length;
      colEnds.add(b.end);
    } else {
      colEnds[col] = b.end;
    }
    b.column = col;
    cluster.add(b);
    if (clusterEnd == null || b.end.isAfter(clusterEnd!)) clusterEnd = b.end;
  }
  flush();
  return sorted;
}

/// Gün içindeki saatli bloklar (çok günlü saatli etkinlik güne kırpılır).
List<TimedBlock> timedBlocksFor(DateTime day, List<AgendaEntry> entries) {
  final dayStart = startOfDay(day);
  final dayEnd = DateTime(day.year, day.month, day.day + 1);
  final out = <TimedBlock>[];
  for (final e in entries) {
    if (e.allDay) continue;
    final (s, en) = switch (e) {
      EventOccurrence occ => (occ.start, occ.end),
      TaskEntry t => (t.at, t.at.add(const Duration(minutes: 30))),
      ReminderEntry r => (r.at, r.at.add(const Duration(minutes: 20))),
      RoutineEntry r => (r.at, r.at.add(const Duration(minutes: 30))),
    };
    final start = s.isBefore(dayStart) ? dayStart : s;
    var end = en.isAfter(dayEnd) ? dayEnd : en;
    if (!end.isAfter(start)) end = start.add(const Duration(minutes: 20));
    out.add(TimedBlock(e, start, end));
  }
  return layoutTimedBlocks(out);
}

const _kHourLabelWidth = 44.0;

/// **HAFTA GÖRÜNÜMÜ**: üstte günler ve tüm gün şeridi, altında 24 saatlik
/// kaydırılır ızgara; çakışan etkinlikler yan yana, bugün kırmızı "şimdi"
/// çizgisi. Boş saate dokunmak o saate yeni etkinlik açar; kayıtlar uzun
/// basıp sürüklenerek başka gün ve çeyrek saate taşınabilir (P92).
class WeekPage extends StatefulWidget {
  const WeekPage({
    super.key,
    required this.weekStart,
    required this.data,
    required this.today,
    required this.now,
    required this.onSlotTap,
    required this.onEntryTap,
    required this.onDayTap,
    this.onEntryMoveToTime,
    this.hourHeight = 52,
    this.dayCount = 7,
  });

  /// Gösterilen gün sayısı: hafta 7, gün sayfası 1.
  final int dayCount;

  final DateTime weekStart;
  final CalendarData data;
  final DateTime today;
  final DateTime now;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<AgendaEntry> onEntryTap;
  final ValueChanged<DateTime> onDayTap;

  /// Hafta / gün ızgarasında sürükle-bırak saat değişimi (P92).
  final void Function(AgendaEntry entry, DateTime target)? onEntryMoveToTime;
  final double hourHeight;

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  final _gridKey = GlobalKey();
  final _hover = ValueNotifier<({int dayIndex, int hour, int minute})?>(null);

  late final ScrollController _scroll = ScrollController(
    // −10: en üstteki saat etiketi yarıdan kesilmesin ("02:00" yarım).
    initialScrollOffset: math.max(
      0,
      widget.hourHeight * math.max(0, _firstHour() - 1) - 10,
    ),
  );

  /// Haftanın ilk saatli kaydı (yoksa bugünse şimdi, değilse 08:00).
  int _firstHour() {
    final agenda = widget.data.range(widget.weekStart, _weekEnd);
    var first = 24;
    for (final list in agenda.values) {
      for (final e in list) {
        if (!e.allDay && e.at.hour < first) first = e.at.hour;
      }
    }
    if (first < 24) return first;
    final inWeek =
        !widget.today.isBefore(widget.weekStart) &&
        widget.today.isBefore(_weekEnd);
    return inWeek ? widget.now.hour : 8;
  }

  DateTime get _weekEnd => DateTime(
    widget.weekStart.year,
    widget.weekStart.month,
    widget.weekStart.day + widget.dayCount,
  );

  ({int dayIndex, int hour, int minute})? _slotAt(
    Offset global,
    List<DateTime> days,
    double h,
  ) {
    final box = _gridKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.width <= 0) return null;
    final local = box.globalToLocal(global);
    final colW = box.size.width / days.length;
    final dayIndex = (local.dx / colW).floor().clamp(0, days.length - 1);
    final snapped = snapToQuarterHour(local.dy, h);
    return (dayIndex: dayIndex, hour: snapped.hour, minute: snapped.minute);
  }

  @override
  void dispose() {
    _hover.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final h = widget.hourHeight;
    final days = [
      for (var i = 0; i < widget.dayCount; i++)
        DateTime(
          widget.weekStart.year,
          widget.weekStart.month,
          widget.weekStart.day + i,
        ),
    ];
    final single = widget.dayCount == 1;
    final agenda = widget.data.range(widget.weekStart, _weekEnd);
    final holidays = [for (final d in days) widget.data.holidays.on(d)];
    final allDay = [
      for (final d in days)
        [
          for (final e in agenda[dayKey(d)] ?? const <AgendaEntry>[])
            if (e.allDay) e,
        ],
    ];
    final allDayRows = allDay.fold<int>(0, (m, l) => math.max(m, l.length));
    final hasHoliday = holidays.any((x) => x != null);
    final hasMovable =
        widget.onEntryMoveToTime != null &&
        agenda.values.any((list) => list.any(canMoveEntry));
    final line = scheme.outlineVariant.withValues(alpha: 0.7);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    // GÖRSEL (kullanıcı bulgusu 2026-11-07: hafta "düz, boş"): başlık kâğıt
    // şerit; hafta sonu ve bugün sütunları hafif tonlu; tatil günü kırmızı.
    Color? columnTint(int i) {
      final d = days[i];
      if (d == widget.today) {
        return scheme.primaryContainer.withValues(alpha: 0.22);
      }
      if (holidays[i]?.isOff ?? false) {
        return scheme.error.withValues(alpha: 0.05);
      }
      if (!single && d.weekday >= DateTime.saturday) {
        return scheme.surfaceContainerHigh.withValues(alpha: 0.45);
      }
      return null;
    }

    final baseGrid = CustomPaint(
      painter: _HourLinesPainter(h, line),
      child: Row(
        key: hasMovable ? _gridKey : null,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: _WeekDayColumn(
                day: days[i],
                tint: columnTint(i),
                blocks: timedBlocksFor(
                  days[i],
                  agenda[dayKey(days[i])] ?? const [],
                ),
                hourHeight: h,
                now: days[i] == widget.today ? widget.now : null,
                line: line,
                onSlotTap: widget.onSlotTap,
                onEntryTap: widget.onEntryTap,
                enableDrag: hasMovable,
              ),
            ),
        ],
      ),
    );

    // S22 bütçesi: taşınabilir kayıt yoksa tek bir DragTarget bile kurulmaz.
    final Widget timedGrid = hasMovable
        ? DragTarget<AgendaEntry>(
            key: const ValueKey('week-timed-drop-target'),
            onWillAcceptWithDetails: (d) => canMoveEntry(d.data),
            onMove: (d) {
              final slot = _slotAt(d.offset, days, h);
              if (_hover.value != slot) _hover.value = slot;
            },
            onLeave: (_) => _hover.value = null,
            onAcceptWithDetails: (d) {
              final slot = _slotAt(d.offset, days, h);
              _hover.value = null;
              if (slot == null) return;
              final day = days[slot.dayIndex];
              widget.onEntryMoveToTime?.call(
                d.data,
                DateTime(day.year, day.month, day.day, slot.hour, slot.minute),
              );
            },
            builder: (context, candidate, _) {
              if (candidate.isEmpty) return baseGrid;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: baseGrid),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<
                        ({int dayIndex, int hour, int minute})?
                      >(
                        valueListenable: _hover,
                        builder: (context, slot, _) {
                          if (slot == null) return const SizedBox.shrink();
                          return LayoutBuilder(
                            builder: (context, c) {
                              final colW = c.maxWidth / days.length;
                              final top = (slot.hour + slot.minute / 60) * h;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: slot.dayIndex * colW + 2,
                                    width: math.max(0, colW - 4),
                                    top: top,
                                    height: math.max(22, h * 0.5),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer
                                            .withValues(alpha: AppAlpha.strong),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                        border: Border.all(
                                          color: scheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpace.xs,
                                          vertical: AppSpace.xxs,
                                        ),
                                        child: Text(
                                          formatHm(slot.hour, slot.minute),
                                          style: AppText.of(theme).badge
                                              .copyWith(
                                                color:
                                                    scheme.onPrimaryContainer,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        : baseGrid;

    return Column(
      children: [
        // Gün başlıkları + tüm gün şeritleri: tek kâğıt şerit.
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
            border: Border(bottom: BorderSide(color: line)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: _kHourLabelWidth),
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: _WeekDayHeader(
                        day: days[i],
                        today: widget.today,
                        holiday: holidays[i],
                        // Gün sayfasında başlık zaten o gün: dokunuş yok.
                        onTap: single ? null : () => widget.onDayTap(days[i]),
                      ),
                    ),
                ],
              ),
              if (allDayRows > 0 || hasHoliday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _kHourLabelWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, right: 4),
                          child: Text(
                            l10n.eventAllDay,
                            style: labelStyle?.copyWith(fontSize: 9),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      for (var i = 0; i < days.length; i++)
                        Expanded(
                          child: Column(
                            children: [
                              if (holidays[i] != null)
                                HolidayChip(
                                  holiday: holidays[i]!,
                                  full: single,
                                  height: single ? 20 : kMonthChipTwoLine,
                                  lines: single ? 1 : 2,
                                ),
                              for (final e in allDay[i].take(3))
                                _weekAllDayChip(
                                  context,
                                  e,
                                  single: single,
                                  draggable: hasMovable && canMoveEntry(e),
                                ),
                              if (allDay[i].length > 3)
                                Text(
                                  '+${allDay[i].length - 3}',
                                  style: labelStyle,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: 24 * h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    size: Size(_kHourLabelWidth, 24 * h),
                    painter: _HourLabelsPainter(
                      h,
                      labelStyle?.copyWith(fontSize: 10),
                      Directionality.of(context),
                    ),
                  ),
                  Expanded(child: timedGrid),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekAllDayChip(
    BuildContext context,
    AgendaEntry entry, {
    required bool single,
    required bool draggable,
  }) {
    final chip = GestureDetector(
      onTap: () => widget.onEntryTap(entry),
      child: _MonthChip(
        entry: entry,
        height: single ? 20 : kMonthChipTwoLine,
        lines: single ? 1 : 2,
        dim: false,
      ),
    );
    if (!draggable) return chip;
    return LongPressDraggable<AgendaEntry>(
      data: entry,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _weekDragFeedback(context, entry),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
  }
}

Widget _weekDragFeedback(BuildContext context, AgendaEntry entry) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final l10n = context.l10n;
  final color = entryColor(entry, scheme);
  return Transform.translate(
    offset: const Offset(-24, -14),
    child: Material(
      elevation: 4,
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs,
          ),
          child: Text(
            entryTitle(entry, l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.of(theme).badge.copyWith(color: scheme.onPrimary),
          ),
        ),
      ),
    ),
  );
}

/// Hafta başlığında bir gün: kısa ad + numara (bugün dolu daire, tatil
/// kırmızı). Dokununca o günün sayfası (kullanıcı isteği 2026-11-07).
class _WeekDayHeader extends StatelessWidget {
  const _WeekDayHeader({
    required this.day,
    required this.today,
    required this.holiday,
    required this.onTap,
  });

  final DateTime day;
  final DateTime today;
  final Holiday? holiday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final off = holiday?.isOff ?? false;
    final weekend = day.weekday >= DateTime.saturday;
    final accent = off ? scheme.error : scheme.primary;
    return Semantics(
      button: onTap != null,
      label: [
        DateFormat.yMMMMEEEEd().format(day),
        if (holiday != null) holiday!.name,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            spacing: 2,
            children: [
              Text(
                DateFormat.E().format(day),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: off || weekend ? accent : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(color: accent, shape: BoxShape.circle)
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? (off ? scheme.onError : scheme.onPrimary)
                        : off
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourLinesPainter extends CustomPainter {
  _HourLinesPainter(this.hourHeight, this.color);

  final double hourHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (var hour = 1; hour < 24; hour++) {
      final y = hour * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_HourLinesPainter old) =>
      old.hourHeight != hourHeight || old.color != color;
}

class _HourLabelsPainter extends CustomPainter {
  _HourLabelsPainter(this.hourHeight, this.style, this.textDirection);

  final double hourHeight;
  final TextStyle? style;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: textDirection);
    for (var hour = 1; hour < 24; hour++) {
      tp.text = TextSpan(text: formatHm(hour, 0), style: style);
      tp.layout();
      tp.paint(
        canvas,
        Offset(size.width - tp.width - 6, hour * hourHeight - 7),
      );
    }
  }

  @override
  bool shouldRepaint(_HourLabelsPainter old) =>
      old.hourHeight != hourHeight ||
      old.style != style ||
      old.textDirection != textDirection;
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.day,
    this.tint,
    required this.blocks,
    required this.hourHeight,
    required this.now,
    required this.line,
    required this.onSlotTap,
    required this.onEntryTap,
    this.enableDrag = false,
  });

  final DateTime day;
  final Color? tint;
  final List<TimedBlock> blocks;
  final double hourHeight;
  final DateTime? now;
  final Color line;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<AgendaEntry> onEntryTap;
  final bool enableDrag;

  double _y(DateTime t) =>
      (t.hour * 60 + t.minute) / 60 * hourHeight +
      (t.day != day.day ? 24 * hourHeight : 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        border: Border(left: BorderSide(color: line, width: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final hour = (d.localPosition.dy / hourHeight).floor().clamp(
                0,
                23,
              );
              onSlotTap(DateTime(day.year, day.month, day.day, hour));
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final b in blocks)
                  Positioned(
                    top: _y(b.start),
                    height: math.max(18, _y(b.end) - _y(b.start) - 1),
                    left: b.column * w / b.columns + 1,
                    width: w / b.columns - 2,
                    child: _blockTile(
                      context,
                      b,
                      w: w,
                      scheme: scheme,
                      l10n: l10n,
                    ),
                  ),
                if (now != null)
                  Positioned(
                    top: _y(now!) - 1,
                    left: -3,
                    right: 0,
                    child: IgnorePointer(
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: scheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Container(height: 1.5, color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _blockTile(
    BuildContext context,
    TimedBlock b, {
    required double w,
    required ColorScheme scheme,
    required AppLocalizations l10n,
  }) {
    final tile = GestureDetector(
      onTap: () => onEntryTap(b.entry),
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 2, 2, 1),
        decoration: BoxDecoration(
          color: entryColor(
            b.entry,
            scheme,
          ).withValues(alpha: b.entry is EventOccurrence ? 0.85 : 0.22),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          entryTitle(b.entry, l10n),
          // Dar blokta sözcük harf harf kırılmasın: tek satır, sağa solar.
          maxLines: w / b.columns >= 56 ? 3 : 1,
          softWrap: w / b.columns >= 56,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.15,
            color: b.entry is EventOccurrence
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
      ),
    );
    if (!enableDrag || !canMoveEntry(b.entry)) return tile;
    return LongPressDraggable<AgendaEntry>(
      data: b.entry,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _weekDragFeedback(context, b.entry),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

// ------------------------------------------------------------------ YIL

/// **YIL GÖRÜNÜMÜ**: 12 küçük ay; dolu günler kalın ve vurgulu, bugün
/// daire. Aya dokunmak (ya da iki parmakla açmak) o ayı açar.
class YearPage extends StatelessWidget {
  const YearPage({
    super.key,
    required this.year,
    required this.data,
    required this.today,
    required this.firstDow,
    required this.targets,
    required this.onMonthTap,
  });

  final int year;
  final CalendarData data;
  final DateTime today;
  final int firstDow;
  final ZoomTargets targets;
  final void Function(DateTime month, Offset globalPosition) onMonthTap;

  @override
  Widget build(BuildContext context) {
    // Not hatırlatıcıları SAYILMAZ: her gün tekrarlanan bir hatırlatıcı
    // yılın bütün günlerini "dolu" gösteriyordu.
    final busy = CalendarData(
      events: data.events,
      tasks: data.tasks,
    ).range(DateTime(year), DateTime(year + 1)).keys.toSet();
    final holidays = data.holidays.year(year);
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 520
            ? 3
            : c.maxWidth < 900
            ? 4
            : 6;
        final rows = (12 / cols).ceil();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
          child: ConstrainedBox(
            // Sığıyorsa aylar yüksekliğe yayılır (altta boşluk kalmasın).
            constraints: BoxConstraints(
              minHeight: math.max(0, c.maxHeight - 92),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var r = 0; r < rows; r++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var col = 0; col < cols; col++)
                        Expanded(
                          child: r * cols + col < 12
                              ? _MiniMonth(
                                  key: targets.keyFor((
                                    'year-month',
                                    year,
                                    r * cols + col,
                                  ), DateTime(year, r * cols + col + 1)),
                                  month: DateTime(year, r * cols + col + 1),
                                  busy: busy,
                                  holidays: holidays,
                                  today: today,
                                  firstDow: firstDow,
                                  onTap: onMonthTap,
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    super.key,
    required this.month,
    required this.busy,
    required this.today,
    required this.firstDow,
    required this.onTap,
    this.holidays = const {},
  });

  final DateTime month;
  final Set<String> busy;
  final Map<String, Holiday> holidays;
  final DateTime today;
  final int firstDow;
  final void Function(DateTime month, Offset globalPosition) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final start = gridStartFor(month, firstDow);
    final current = today.year == month.year && today.month == month.month;
    const cell = TextStyle(fontSize: 10, height: 1.0);
    // GÖRSEL (kullanıcı bulgusu 2026-11-07: yıl "düz"): her ay ayrı kâğıt
    // kart; bu ay vurgu kenarlı. Hafta sonu sütunu tonlu, tatil kırmızı,
    // kayıtlı gün altında nokta.
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: AppTokens.of(context).card.withValues(alpha: AppAlpha.strong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(
            color: current
                ? scheme.primary.withValues(alpha: 0.8)
                : scheme.outlineVariant.withValues(alpha: 0.7),
            width: current ? 1.4 : 0.8,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onTap(month, d.globalPosition),
          child: Semantics(
            button: true,
            label: DateFormat.yMMMM().format(month),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      DateFormat.MMMM().format(month),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: current ? scheme.primary : scheme.onSurface,
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Text(
                            material.narrowWeekdays[(firstDow + i) % 7],
                            textAlign: TextAlign.center,
                            style: cell.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color:
                                  (firstDow + i) % 7 == 0 ||
                                      (firstDow + i) % 7 == 6
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  for (var w = 0; w < 6; w++)
                    Row(
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _miniDay(
                              DateTime(
                                start.year,
                                start.month,
                                start.day + w * 7 + d,
                              ),
                              scheme,
                              cell,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniDay(DateTime day, ColorScheme scheme, TextStyle style) {
    if (day.month != month.month) return const SizedBox(height: 18);
    final isToday = day == today;
    final key = dayKey(day);
    final has = busy.contains(key);
    final holiday = holidays[key];
    final off = holiday?.isOff ?? false;
    final weekend = day.weekday >= DateTime.saturday;
    return SizedBox(
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 14,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    color: off ? scheme.error : scheme.primary,
                    borderRadius: BorderRadius.circular(7),
                  )
                : holiday != null
                ? BoxDecoration(
                    color: scheme.error.withValues(alpha: off ? 0.14 : 0.07),
                    borderRadius: BorderRadius.circular(7),
                  )
                : null,
            child: Text(
              '${day.day}',
              style: style.copyWith(
                color: isToday
                    ? (off ? scheme.onError : scheme.onPrimary)
                    : holiday != null
                    ? scheme.error
                    : weekend
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
                fontWeight: has || isToday || off
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: has ? scheme.primary : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
