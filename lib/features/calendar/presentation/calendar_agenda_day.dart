part of 'calendar_screen.dart';

/// Seçili günden başlayan ajanda: kaydı olan günler + seçili gün (boşsa
/// "plan yok"). Tembel liste: satırlar görünür olunca kurulur.
class _AgendaList extends ConsumerWidget {
  const _AgendaList({
    super.key,
    required this.from,
    required this.days,
    required this.today,
    required this.events,
    required this.tasks,
    required this.reminders,
    this.timedNotes = const [],
    this.dayNotes = const {},
    required this.onMore,
  });

  final Map<String, List<DayNote>> dayNotes;

  final DateTime from;
  final int days;
  final DateTime today;
  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<Note> reminders;
  final List<Note> timedNotes;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final to = DateTime(from.year, from.month, from.day + days);
    final agenda = buildAgenda(
      from: from,
      to: to,
      events: events,
      tasks: tasks,
      reminderNotes: reminders,
      timedNotes: timedNotes,
      dayNotes: dayNotes,
    );
    final holidays = ref.watch(holidayCalendarProvider);
    // Kaydı olmayan tatil günleri de ajandada başlık olarak görünür.
    final keys = {...agenda.keys};
    if (holidays.enabled) {
      for (var y = from.year; y <= to.year; y++) {
        for (final k in holidays.year(y).keys) {
          if (k.compareTo(dayKey(from)) >= 0 && k.compareTo(dayKey(to)) < 0) {
            keys.add(k);
          }
        }
      }
    }
    final rows = <Object>[];
    final selectedKey = dayKey(from);
    if (!keys.contains(selectedKey)) {
      rows
        ..add(from)
        ..add(l10n.calendarNothingThisDay);
    }
    for (final k in keys.toList()..sort()) {
      rows.add(parseDayKey(k)!);
      rows.addAll(agenda[k] ?? const <AgendaEntry>[]);
    }
    rows.add(#more);

    return ListView.builder(
      key: const ValueKey('calendar-agenda'),
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return switch (row) {
          DateTime day => _DayHeader(
            day: day,
            today: today,
            holiday: holidays.on(day),
          ),
          String text => Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          EventOccurrence occ =>
            _withQuickDelete(occ, _EventTile(occurrence: occ)),
          TaskEntry t => _withQuickDelete(t, _TaskTile(task: t.task)),
          ReminderEntry r => _withQuickDelete(r, _ReminderTile(entry: r)),
          _ => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton.icon(
                onPressed: onMore,
                icon: const Icon(Icons.expand_more),
                label: Text(l10n.calendarMoreDays),
              ),
            ),
          ),
        };
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today, this.holiday});

  final DateTime day;
  final DateTime today;

  /// Ajandada günün tatili başlığın yanında.
  final Holiday? holiday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = AppText.of(theme);
    final isToday = day == today;
    final base = isToday
        ? '${context.l10n.calendarToday} · ${DateFormat.MMMMEEEEd().format(day)}'
        : DateFormat.MMMMEEEEd().format(day);
    final text = holiday == null ? base : '$base · ${holiday!.name}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.m,
        AppSpace.l,
        AppSpace.m,
        AppSpace.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: textStyle.section.copyWith(
            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Satır kabuğu: solda renk şeridi, kart zemini.
///
/// F79.1 (D16) ölçü birliği: başlık her türde `rowTitle`, alt satır `meta`;
/// en az 56 dp (tek satır) / 64 dp (alt satırlı), içerik dikeyde ortada.
/// Yerleşim (şerit, kart, sağdaki çöp düğmesi) aynen.
class _EntryShell extends StatelessWidget {
  const _EntryShell({
    required this.accent,
    required this.child,
    this.onTap,
    this.twoLine = false,
  });

  final Color accent;
  final Widget child;
  final VoidCallback? onTap;
  final bool twoLine;

  static const double oneLineHeight = 56;
  static const double twoLineHeight = 64;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Material(
        color: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: tokens.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: twoLine ? twoLineHeight : oneLineHeight,
                    ),
                    child: Padding(
                      // Dikey dolgu ince: yüksekliği alt sınır verir; görevin
                      // onay kutusu (48 dp dokunma alanı) 56'yı aşmasın.
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.m,
                        vertical: AppSpace.xs,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = occurrence.event;
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat.Hm();
    final when = e.allDay
        ? l10n.eventAllDay
        : '${time.format(occurrence.start)} – ${time.format(occurrence.end)}';
    final sub = [when, if (e.location.isNotEmpty) e.location].join(' · ');
    final text = AppText.of(Theme.of(context));
    // Sağdaki durum simgeleri (🔔 ↻ bulut, not): 18 dp, `onSurfaceVariant`.
    const status = AppIconSize.s;
    return _EntryShell(
      accent: e.color != null ? Color(e.color!) : scheme.primary,
      twoLine: true,
      onTap: () => e.fromGoogle
          ? showGoogleEventSheet(context, e, occurrence.start)
          : showEventEditor(
              context,
              existing: e,
              occurrenceStart: occurrence.start,
            ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title.isEmpty ? l10n.eventUntitled : e.title,
                  style: text.rowTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  sub,
                  style: text.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Google Takvim etkinliği (F48.3): bulut simgesi, bağlı not ataç.
          if (e.fromGoogle)
            Icon(
              Icons.cloud_outlined,
              size: status,
              color: scheme.onSurfaceVariant,
              semanticLabel: l10n.gcalTitle,
            ),
          // Bağlı not simgesi: tek bağlı not varsa DOKUNUNCA doğrudan o not
          // açılır (etkinlikten nota tek dokunuş, 2026-11-08).
          if (e.noteIds.isNotEmpty)
            InkResponse(
              key: ValueKey('event-note-${e.id}'),
              radius: 18,
              onTap: e.noteIds.length == 1
                  ? () => unawaited(
                      context.pushNote(noteRoutePath(e.noteIds.first)),
                    )
                  : () => e.fromGoogle
                        ? showGoogleEventSheet(context, e, occurrence.start)
                        : showEventEditor(
                            context,
                            existing: e,
                            occurrenceStart: occurrence.start,
                          ),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.sticky_note_2_outlined,
                  size: status,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (e.repeats)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
              child: Icon(
                Icons.repeat,
                size: status,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (e.reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
              child: Icon(
                Icons.notifications_none,
                size: status,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.entry});

  final ReminderEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final note = entry.note;
    final title = note.displayTitle.trim().isNotEmpty
        ? note.displayTitle.trim()
        : note.locked
        ? l10n.remindersUntitled
        : note.toPlainText().split('\n').first.trim();
    final text = AppText.of(Theme.of(context));
    return _EntryShell(
      accent: scheme.secondary,
      twoLine: true,
      onTap: () => unawaited(context.pushNote(noteRoutePath(note.id))),
      child: Row(
        children: [
          Icon(
            entry.isDayLink
                ? Icons.sticky_note_2_outlined
                : entry.expiry
                ? AppIcons.archive
                : Icons.alarm,
            size: AppIconSize.s,
            color: scheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? l10n.remindersUntitled : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.rowTitle,
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  entry.isDayLink
                      ? (entry.linkTimed
                            ? '${DateFormat.Hm().format(entry.at)} · '
                                  '${l10n.calendarLinkedNotes}'
                            : l10n.calendarLinkedNotes)
                      : '${DateFormat.Hm().format(entry.at)} · '
                            '${entry.expiry ? l10n.calendarExpiryTag : l10n.calendarReminderTag}',
                  style: text.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.entry});

  final RoutineEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final r = entry.routine;
    final color = r.color == null ? scheme.primary : Color(r.color!);
    final text = AppText.of(Theme.of(context));
    return _EntryShell(
      accent: color,
      twoLine: true,
      onTap: () => unawaited(showRoutineDaySheet(context, r, entry.day)),
      child: Row(
        children: [
          Icon(
            entry.log.completed ? Icons.check_circle : kRoutineIcon,
            size: AppIconSize.s,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title.trim().isEmpty ? l10n.eventUntitled : r.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.rowTitle,
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  [
                    if (!entry.allDay) DateFormat.Hm().format(entry.at),
                    routineProgressLabel(l10n, r, entry.log),
                  ].join(' · '),
                  style: text.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// **GÜN SAYFASI** (kullanıcı isteği 2026-11-07: "günlerin üzerine çift
/// tıklayınca sadece o günün sayfası açılsın"): ay görünümünde güne çift
/// dokununca açılır. Tek günlük saat çizelgesi (hafta görünümünün tek
/// sütunlu hâli), yatay kaydırma ya da oklarla önceki/sonraki gün.
class CalendarDayScreen extends ConsumerStatefulWidget {
  const CalendarDayScreen({
    super.key,
    required this.day,
    this.today,
    this.onEntryTap,
    this.onEntryMoveToTime,
    this.now,
  });

  final DateTime day;
  final DateTime? today;
  final ValueChanged<AgendaEntry>? onEntryTap;
  final void Function(AgendaEntry entry, DateTime target)? onEntryMoveToTime;

  /// Test için "şimdi".
  final DateTime? now;

  @override
  ConsumerState<CalendarDayScreen> createState() => _CalendarDayScreenState();
}

class _CalendarDayScreenState extends ConsumerState<CalendarDayScreen> {
  /// Sayfa 0 = 2000-01-01 değil; başlangıç günü ortada (±10 yıl).
  static const _kCenter = 3650;
  late final PageController _controller = PageController(initialPage: _kCenter);
  late DateTime _day = widget.day;

  DateTime _dayAt(int i) => DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day + i - _kCenter,
  );

  void _step(int delta) {
    if (!_controller.hasClients) return;
    unawaited(
      _controller.animateToPage(
        (_controller.page?.round() ?? _kCenter) + delta,
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.emphasized,
      ),
    );
  }

  void _goToday() {
    if (!_controller.hasClients) return;
    final i = _kCenter + _today.difference(widget.day).inDays;
    _controller.jumpToPage(i.clamp(0, 2 * _kCenter));
  }

  DateTime get _today =>
      widget.today ?? startOfDay(widget.now ?? DateTime.now());

  /// SAATE NOT (kullanıcı isteği 2026-11-22: "saatlere not eklenebilmeli,
  /// şu an sadece etkinlik ekleniyor"): boş saate dokununca etkinlik mi not
  /// mu sorulur; not o güne o SAATLE bağlanır (`noteTimes`).
  Future<void> _onSlotTap(DateTime t) async {
    final l10n = context.l10n;
    final choice = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: Text(
                l10n.calendarSlotAddTitle(DateFormat.Hm().format(t)),
                style: AppText.of(Theme.of(ctx)).sheetTitle,
              ),
            ),
            ListTile(
              key: const ValueKey('slot-add-note'),
              leading: const Icon(Icons.edit_note),
              title: Text(l10n.calendarAddNote),
              onTap: () => Navigator.pop(ctx, 'note'),
            ),
            ListTile(
              key: const ValueKey('slot-add-event'),
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.calendarAddEvent),
              onTap: () => Navigator.pop(ctx, 'event'),
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'note') {
      await openDayNote(context, ref, t, minutes: t.hour * 60 + t.minute);
    } else {
      await showEventEditor(context, start: t);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = AppTokens.fromTheme(theme);
    final data = ref.watch(calendarDataProvider);
    final now = widget.now ?? DateTime.now();
    final today = _today;
    final dayTitle = DateFormat.yMMMMEEEEd().format(_day);
    final text = AppText.of(theme);
    // AYRINTILI BAŞLIK (kullanıcı isteği 2026-11-22: "gün sayfasındayken üst
    // daha düzgün, daha detaylı olsun"): büyük gün + ay, altında haftanın
    // günü · göreli gün · yılın haftası.
    final rel = _day.difference(today).inDays;
    final relText = switch (rel) {
      0 => l10n.calendarRelToday,
      1 => l10n.calendarRelTomorrow,
      -1 => l10n.calendarRelYesterday,
      > 1 => l10n.calendarRelInDays(rel),
      _ => l10n.calendarRelDaysAgo(-rel),
    };
    final subtitle = [
      DateFormat.EEEE().format(_day),
      if (_day.year != today.year) '${_day.year}',
      relText,
      l10n.calendarWeekNumber(isoWeekNumber(_day)),
    ].join(' · ');
    final backgroundLayers = buildAppBackgroundLayers(context, ref);
    final hasBackground = backgroundLayers.isNotEmpty;
    final scaffold = Scaffold(
      backgroundColor: hasBackground ? Colors.transparent : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: hasBackground ? Colors.transparent : null,
        systemOverlayStyle: hasBackground ? statusBarOverZemin(context) : null,
        titleSpacing: 0,
        toolbarHeight: 64,
        title: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.short),
          child: Semantics(
            key: ValueKey(dayTitle),
            label: dayTitle,
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.MMMMd().format(_day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.screenTitle.copyWith(
                    fontSize: (text.screenTitle.fontSize ?? 20) + 2,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                    color: rel == 0
                        ? theme.colorScheme.primary
                        : text.meta.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('day-page-prev'),
            tooltip: l10n.calendarPrevious,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _step(-1),
          ),
          IconButton(
            key: const ValueKey('day-page-next'),
            tooltip: l10n.calendarNext,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _step(1),
          ),
          IconButton(
            tooltip: l10n.calendarToday,
            icon: const Icon(Icons.today_outlined),
            onPressed: _goToday,
          ),
          IconButton(
            key: const ValueKey('day-page-home'),
            tooltip: l10n.goHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goHome(ref, GoRouter.of(context)),
          ),
        ],
      ),
      // "+" YOK (kullanıcı isteği 2026-11-22: "butonlar da var, artıya gerek
      // yok"): Etkinlik · Görev · Not alt satırda.
      body: Column(
        children: [
          _DaySummaryRow(day: _day, data: data),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              physics: ref.watch(calendarSwipeProvider)
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: 2 * _kCenter + 1,
              onPageChanged: (i) => setState(() => _day = _dayAt(i)),
              itemBuilder: (context, i) => WeekPage(
                key: ValueKey('day-${dayKey(_dayAt(i))}'),
                weekStart: _dayAt(i),
                dayCount: 1,
                data: data,
                today: today,
                now: now,
                onSlotTap: (t) => unawaited(_onSlotTap(t)),
                onEntryTap:
                    widget.onEntryTap ?? (e) => openCalendarEntry(context, e),
                onDayTap: (_) {},
                onEntryMoveToTime:
                    widget.onEntryMoveToTime ??
                    (e, t) => moveCalendarEntryToTime(context, ref, e, t),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              border: Border(top: BorderSide(color: tokens.hairline)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.m,
                  AppSpace.s,
                  AppSpace.m,
                  AppSpace.m,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        key: const ValueKey('day-page-event'),
                        onPressed: () =>
                            unawaited(showEventEditor(context, day: _day)),
                        icon: const Icon(
                          Icons.event_outlined,
                          size: AppIconSize.s,
                        ),
                        label: Text(
                          l10n.calendarAddEvent,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            unawaited(showTaskEditor(context, due: _day)),
                        icon: const Icon(Icons.add_task, size: AppIconSize.s),
                        label: Text(
                          l10n.tasksNewTask,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('day-page-note'),
                        onPressed: () => unawaited(
                          openDayNote(context, ref, _day),
                        ),
                        icon: const Icon(Icons.edit_note, size: AppIconSize.s),
                        label: Text(
                          l10n.calendarDayNote,
                          overflow: TextOverflow.ellipsis,
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
    );
    if (!hasBackground) return scaffold;
    return Stack(
      children: [
        ...backgroundLayers,
        scaffold,
      ],
    );
  }
}

/// ISO-8601 yılın haftası (Pazartesi başlar; 1. hafta yılın ilk Perşembesini
/// içerir). Yaz saati kaymasın diye UTC'de hesaplanır.
int isoWeekNumber(DateTime d) {
  final day = DateTime.utc(d.year, d.month, d.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final jan1 = DateTime.utc(thursday.year);
  return thursday.difference(jan1).inDays ~/ 7 + 1;
}

/// Gün sayfasının üstündeki ÖZET satırı: tatil, etkinlik / görev /
/// hatırlatıcı / bağlı not sayıları (kullanıcı isteği 2026-11-22: "sayfa
/// içinde daha detaylı bilgiler olabilir"). Hiç kayıt yoksa "Boş gün".
class _DaySummaryRow extends StatelessWidget {
  const _DaySummaryRow({required this.day, required this.data});

  final DateTime day;
  final CalendarData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final next = DateTime(day.year, day.month, day.day + 1);
    final entries = data.range(day, next)[dayKey(day)] ?? const [];
    var events = 0, tasks = 0, reminders = 0;
    for (final e in entries) {
      switch (e) {
        case EventOccurrence():
          events++;
        case TaskEntry():
        case RoutineEntry():
          tasks++;
        case ReminderEntry():
          reminders++;
      }
    }
    final notes = (data.dayNotes[dayKey(day)] ?? const []).length;
    final holiday = data.holidays.on(day);
    Widget chip(IconData icon, String label, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.xs, color: fg),
          const SizedBox(width: AppSpace.xs),
          Text(label, style: text.label.copyWith(color: fg)),
        ],
      ),
    );
    final neutralFg = scheme.onSurfaceVariant;
    final neutralBg = scheme.surfaceContainerHigh;
    final chips = <Widget>[
      if (holiday != null)
        chip(
          Icons.celebration_outlined,
          holiday.name,
          scheme.onErrorContainer,
          scheme.errorContainer,
        ),
      if (events > 0)
        chip(
          Icons.event_outlined,
          l10n.calendarDayEvents(events),
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
      if (tasks > 0)
        chip(
          Icons.task_alt,
          l10n.calendarDayTasks(tasks),
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
        ),
      if (reminders > 0)
        chip(
          Icons.notifications_none,
          l10n.calendarDayReminders(reminders),
          neutralFg,
          neutralBg,
        ),
      if (notes > 0)
        chip(
          Icons.sticky_note_2_outlined,
          l10n.calendarDayNotesCount(notes),
          neutralFg,
          neutralBg,
        ),
      if (holiday == null && entries.isEmpty && notes == 0)
        chip(Icons.wb_sunny_outlined, l10n.calendarDayFree, neutralFg, neutralBg),
    ];
    return Padding(
      key: const ValueKey('day-page-summary'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.xxs,
        AppSpace.l,
        AppSpace.s,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: chips,
        ),
      ),
    );
  }
}

/// Uzun takvim görünümünde alt kenarda hafif tutamak: dokununca veya yukarı
/// çekince seçili günün alt panelini yeniden açar.
class _OpenDayPanelPill extends StatelessWidget {
  const _OpenDayPanelPill({required this.selected, required this.onOpen});

  final DateTime selected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    return GestureDetector(
      key: const ValueKey('calendar-open-day-panel'),
      onTap: onOpen,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -120) onOpen();
      },
      child: Material(
        color: tokens.card.withValues(alpha: AppAlpha.strong),
        shape: StadiumBorder(side: BorderSide(color: tokens.hairline)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.xs,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: AppIconSize.s,
                color: scheme.primary,
              ),
              Text(
                DateFormat.MMMd().format(selected),
                style: AppText.of(theme).badge.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Takvim görünüm seçici: yumuşak kapsül içinde kayan seçim hapı.
/// Çerçevesiz, ince; seçili görünüm dolgulu vurgu rengi (bkz. `_viewBar`).
class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    super.key,
    required this.view,
    required this.labels,
    required this.onPick,
  });

  final CalendarView view;
  final Map<CalendarView, String> labels;
  final ValueChanged<CalendarView> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(Theme.of(context));
    const views = CalendarView.values;
    final n = views.length;
    final duration = AppMotion.of(context, AppMotion.short);
    // Görünen kapsül 40 dp; dokunma alanları kapsülün üst/altındaki boşluğu
    // da kapsar (48 dp, `tap_targets_test`).
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  // Kayan seçim hapı.
                  child: AnimatedAlign(
                    duration: duration,
                    curve: AppMotion.standard,
                    alignment: Alignment(-1 + 2 * view.index / (n - 1), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / n,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Row(
              children: [
                for (final v in views)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: v == view,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onPick(v),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            style: text.label.copyWith(
                              color: v == view
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                              fontWeight: v == view
                                  ? AppWeight.strong
                                  : AppWeight.medium,
                            ),
                            child: Text(
                              labels[v]!,
                              key: ValueKey('calendar-view-${v.name}'),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// BUGÜN hapı: görünen dönem bugünü içeriyorsa sakin (günün sayısı + "Bugün"),
/// içermiyorsa dolgulu vurgu + bugünün yönünü gösteren ok — "bugünde
/// olmadığımı anlamıyorum" (kullanıcı 2026-11-22).
class _TodayPill extends StatelessWidget {
  const _TodayPill({
    super.key,
    required this.label,
    required this.day,
    required this.away,
    required this.onTap,
  });

  final String label;
  final int day;

  /// 0 = bugündesin, 1 = ileridesin (bugün geride), -1 = geridesin.
  final int away;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(Theme.of(context));
    final off = away != 0;
    // `tertiary` yalnız AI kimliğinde (`color_roles_test`).
    final fg = off ? scheme.onSecondaryContainer : scheme.primary;
    final style = text.label.copyWith(color: fg, fontWeight: AppWeight.strong);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: off ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.xs,
                children: [
                  if (away > 0)
                    Icon(Icons.arrow_back_rounded, size: AppIconSize.xs, color: fg)
                  else if (away == 0)
                    // Günün sayısı küçük bir rozet içinde (takvim yaprağı).
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$day',
                        style: text.badge.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: AppWeight.strong,
                        ),
                      ),
                    ),
                  Text(label, style: style),
                  if (away < 0)
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: AppIconSize.xs,
                      color: fg,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
