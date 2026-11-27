part of 'calendar_views.dart';

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
                  fontWeight: AppWeight.strong,
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
                    fontWeight: AppWeight.strong,
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
                              fontWeight: AppWeight.strong,
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
                    : AppWeight.regular,
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
