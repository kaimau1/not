import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/domain/note.dart';
import '../domain/agenda.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'month_grid.dart' show gridStartFor;
import 'pinch_zoom.dart';

/// Takvimin görünümleri; yakınlaştırma sırası yıl → ay → hafta.
enum CalendarView { year, month, week, agenda }

/// Görünümlerin ortak verisi (sayfa başına yeniden sorgu YOK; aralık
/// hesabı bellekte, `buildAgenda`).
class CalendarData {
  const CalendarData({
    this.events = const [],
    this.tasks = const [],
    this.reminders = const [],
  });

  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<Note> reminders;

  Map<String, List<AgendaEntry>> range(DateTime from, DateTime to) =>
      buildAgenda(
        from: from,
        to: to,
        events: events,
        tasks: tasks,
        reminderNotes: reminders,
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
  });

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
    final line = scheme.outlineVariant.withValues(alpha: 0.45);
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
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        Divider(height: 1, color: line),
        Expanded(
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
                            line: line,
                            onTap: onDayTap,
                            onLongPress: onDayLongPress,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
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
  });

  final DateTime day;
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<AgendaEntry> entries;
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
    return Semantics(
      button: true,
      label: DateFormat.yMMMMEEEEd().format(day),
      child: InkWell(
        onTap: () => onTap(day),
        onLongPress: () => onLongPress(day),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            border: Border(
              right: BorderSide(color: line, width: 0.5),
              bottom: BorderSide(color: line, width: 0.5),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              const chipH = 16.0;
              final room = math.max(
                0,
                ((c.maxHeight - 24) / (chipH + 1)).floor(),
              );
              final fits = entries.length <= room;
              final shown = fits ? entries.length : math.max(0, room - 1);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 2),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: isToday
                            ? BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? scheme.onPrimary
                                : inMonth
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final e in entries.take(shown))
                    _MonthChip(entry: e, height: chipH, dim: !inMonth),
                  if (!fits && entries.length > shown)
                    SizedBox(
                      height: chipH,
                      child: Text(
                        '+${entries.length - shown}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                        semanticsLabel: l10n.calendarMoreDays,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.entry,
    required this.height,
    required this.dim,
  });

  final AgendaEntry entry;
  final double height;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = entryColor(entry, scheme);
    final solid = entry is EventOccurrence && entry.allDay;
    final done = entry is TaskEntry && (entry as TaskEntry).task.completed;
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 1),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: solid ? color : color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entryTitle(entry, context.l10n),
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.1,
            color: solid ? scheme.onPrimary : scheme.onSurface,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
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
/// çizgisi. Boş saate dokunmak o saate yeni etkinlik açar.
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
    this.hourHeight = 52,
  });

  final DateTime weekStart;
  final CalendarData data;
  final DateTime today;
  final DateTime now;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<AgendaEntry> onEntryTap;
  final ValueChanged<DateTime> onDayTap;
  final double hourHeight;

  @override
  State<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends State<WeekPage> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.hourHeight * math.max(0, _firstHour() - 1),
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
    widget.weekStart.day + 7,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final h = widget.hourHeight;
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(
          widget.weekStart.year,
          widget.weekStart.month,
          widget.weekStart.day + i,
        ),
    ];
    final agenda = widget.data.range(widget.weekStart, _weekEnd);
    final allDay = [
      for (final d in days)
        [
          for (final e in agenda[dayKey(d)] ?? const <AgendaEntry>[])
            if (e.allDay) e,
        ],
    ];
    final allDayRows = allDay.fold<int>(0, (m, l) => math.max(m, l.length));
    final line = scheme.outlineVariant.withValues(alpha: 0.45);
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      children: [
        // Gün başlıkları.
        Row(
          children: [
            const SizedBox(width: _kHourLabelWidth),
            for (final d in days)
              Expanded(
                child: InkWell(
                  onTap: () => widget.onDayTap(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text(DateFormat.E().format(d), style: labelStyle),
                        const SizedBox(height: 2),
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: d == widget.today
                              ? BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '${d.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: d == widget.today
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (allDayRows > 0)
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
                for (final list in allDay)
                  Expanded(
                    child: Column(
                      children: [
                        for (final e in list.take(3))
                          GestureDetector(
                            onTap: () => widget.onEntryTap(e),
                            child: _MonthChip(entry: e, height: 18, dim: false),
                          ),
                        if (list.length > 3)
                          Text('+${list.length - 3}', style: labelStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        Divider(height: 1, color: line),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: SizedBox(
              height: 24 * h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _kHourLabelWidth,
                    child: Stack(
                      children: [
                        for (var hour = 1; hour < 24; hour++)
                          Positioned(
                            top: hour * h - 7,
                            right: 6,
                            child: Text(
                              formatHm(hour, 0),
                              style: labelStyle?.copyWith(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: _HourLinesPainter(h, line),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final d in days)
                            Expanded(
                              child: _WeekDayColumn(
                                day: d,
                                blocks: timedBlocksFor(
                                  d,
                                  agenda[dayKey(d)] ?? const [],
                                ),
                                hourHeight: h,
                                now: d == widget.today ? widget.now : null,
                                line: line,
                                onSlotTap: widget.onSlotTap,
                                onEntryTap: widget.onEntryTap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.day,
    required this.blocks,
    required this.hourHeight,
    required this.now,
    required this.line,
    required this.onSlotTap,
    required this.onEntryTap,
  });

  final DateTime day;
  final List<TimedBlock> blocks;
  final double hourHeight;
  final DateTime? now;
  final Color line;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<AgendaEntry> onEntryTap;

  double _y(DateTime t) =>
      (t.hour * 60 + t.minute) / 60 * hourHeight +
      (t.day != day.day ? 24 * hourHeight : 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
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
                    child: GestureDetector(
                      onTap: () => onEntryTap(b.entry),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(3, 2, 2, 1),
                        decoration: BoxDecoration(
                          color: entryColor(b.entry, scheme).withValues(
                            alpha: b.entry is EventOccurrence ? 0.85 : 0.22,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          entryTitle(b.entry, l10n),
                          // Dar blokta sözcük harf harf kırılmasın: tek
                          // satır, sağa doğru solar.
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
  });

  final DateTime month;
  final Set<String> busy;
  final DateTime today;
  final int firstDow;
  final void Function(DateTime month, Offset globalPosition) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final start = gridStartFor(month, firstDow);
    final current = today.year == month.year && today.month == month.month;
    const cell = TextStyle(fontSize: 9.5, height: 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) => onTap(month, d.globalPosition),
      child: Semantics(
        button: true,
        label: DateFormat.yMMMM().format(month),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 4),
                child: Text(
                  DateFormat.MMMM().format(month),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: current ? scheme.primary : scheme.onSurface,
                    fontWeight: FontWeight.w600,
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
                        style: cell.copyWith(color: scheme.onSurfaceVariant),
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
    );
  }

  Widget _miniDay(DateTime day, ColorScheme scheme, TextStyle style) {
    if (day.month != month.month) return const SizedBox(height: 17);
    final isToday = day == today;
    final has = busy.contains(dayKey(day));
    return SizedBox(
      height: 17,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle)
              : has
              ? BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            '${day.day}',
            style: style.copyWith(
              color: isToday ? scheme.onPrimary : scheme.onSurface,
              fontWeight: has || isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
