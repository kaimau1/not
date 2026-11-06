import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/calendar_repository.dart';
import '../domain/agenda.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'calendar_views.dart';
import 'event_editor.dart';
import 'month_grid.dart';
import 'pinch_zoom.dart';
import 'task_editor.dart';

/// Hatırlatıcılı notlar (gizli klasör bastırması Hatırlatıcılar ekranıyla
/// aynı kural).
final calendarReminderNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  return [
    for (final n in notes)
      if (n.reminderAt != null &&
          (n.folderId == null || !suppressed.contains(n.folderId)))
        n,
  ];
});

/// Geniş düzen eşiği: ajandada ay ızgarası solda sabit.
const _kWideCalendar = 720.0;

/// Ajandanın bir seferde gösterdiği gün sayısı ("Daha ileri" uzatır).
const _kAgendaWindowDays = 60;

const _kViewPref = 'calendar_view';
const _kPinchHintPref = 'calendar_pinch_hint_v1';

/// **TAKVİM** (TAKVIM_PLANI Faz 47 + kullanıcı isteği 2026-11-06): YIL · AY ·
/// HAFTA · AJANDA. İki parmakla yakınlaştırma yıl → ay → hafta (parmakların
/// altındaki ay/hafta açılır), uzaklaştırma tersi; geçiş o noktadan büyüyerek
/// olur. Dönemler arası yatay kaydırma. Seçilen görünüm hatırlanır.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.now});

  /// Test için "şimdi".
  final DateTime? now;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _today = startOfDay(widget.now ?? DateTime.now());
  late DateTime _selected = _today;

  /// Görünen dönemin içindeki bir gün (ay/hafta/yıl sayfası bundan).
  late DateTime _focus = _today;
  late CalendarView _view = _storedView();

  // Ajanda görünümü.
  late DateTime _month = monthOf(_today);
  bool _monthOpen = false;
  int _windowDays = _kAgendaWindowDays;

  // Geçiş ve iki parmak.
  final _targets = ZoomTargets();
  final _bodyKey = GlobalKey();
  ZoomDirection _lastZoom = ZoomDirection.zoomIn;
  Alignment _origin = Alignment.center;
  bool _pinching = false;

  /// Kıstırırken canlı ölçek: yalnız `Transform` yeniden çizilir (sayfalar
  /// her parmak hareketinde yeniden kurulmaz).
  final _preview = ValueNotifier<(double, Alignment)>((1, Alignment.center));
  int _epoch = 0;
  final Map<String, GlobalKey<_PagedViewState>> _pagers = {};

  CalendarView _storedView() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_kViewPref);
      return CalendarView.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => CalendarView.month,
      );
    } catch (_) {
      return CalendarView.month;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePinchHint());
  }

  void _maybePinchHint() {
    if (!mounted || _view == CalendarView.agenda) return;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool(_kPinchHintPref) ?? false) return;
      unawaited(prefs.setBool(_kPinchHintPref, true));
      ScaffoldMessenger.of(context).showMessage(
        context.l10n.calendarPinchHint,
        duration: const Duration(seconds: 5),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  int get _firstDow => MaterialLocalizations.of(context).firstDayOfWeekIndex;

  GlobalKey<_PagedViewState> get _pagerKey =>
      _pagers.putIfAbsent('${_view.name}#$_epoch', GlobalKey.new);

  int _pageOf(CalendarView view, DateTime d) => switch (view) {
    CalendarView.year => yearIndexOf(d),
    CalendarView.month => monthIndexOf(d),
    CalendarView.week => weekIndexOf(d, _firstDow),
    CalendarView.agenda => 0,
  };

  DateTime _dateOfPage(int i) => switch (_view) {
    CalendarView.year => DateTime(2000 + i),
    CalendarView.month => monthAtIndex(i),
    CalendarView.week => weekAtIndex(i, _firstDow),
    CalendarView.agenda => _focus,
  };

  /// Küresel noktanın gövdedeki hizası (geçiş o noktadan büyüsün).
  Alignment _alignmentAt(Offset? global) {
    final box = _bodyKey.currentContext?.findRenderObject();
    if (global == null || box is! RenderBox || !box.hasSize) {
      return Alignment.center;
    }
    final local = box.globalToLocal(global);
    return Alignment(
      (local.dx / box.size.width * 2 - 1).clamp(-1, 1),
      (local.dy / box.size.height * 2 - 1).clamp(-1, 1),
    );
  }

  void _setView(
    CalendarView view, {
    DateTime? focus,
    Offset? from,
    ZoomDirection direction = ZoomDirection.zoomIn,
  }) {
    if (view == _view && focus == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _lastZoom = direction;
      _origin = _alignmentAt(from);
      _view = view;
      if (focus != null) _focus = focus;
      if (view == CalendarView.agenda) {
        _selected = startOfDay(_focus);
        _month = monthOf(_focus);
        _windowDays = _kAgendaWindowDays;
      }
      _targets.clear();
      _preview.value = (1, Alignment.center);
      _epoch++;
    });
    try {
      unawaited(
        ref.read(sharedPreferencesProvider).setString(_kViewPref, view.name),
      );
    } catch (_) {}
  }

  void _onZoom(ZoomDirection dir, Offset global) {
    final zoomIn = dir == ZoomDirection.zoomIn;
    switch (_view) {
      case CalendarView.year:
        if (!zoomIn) return;
        final month =
            _targets.at(global) ??
            (_focus.year == _today.year
                ? monthOf(_today)
                : DateTime(_focus.year));
        _setView(CalendarView.month, focus: month, from: global);
      case CalendarView.month:
        if (zoomIn) {
          final week =
              _targets.at(global) ??
              weekStartOf(
                _selected.month == _focus.month ? _selected : _focus,
                _firstDow,
              );
          _setView(CalendarView.week, focus: week, from: global);
        } else {
          _setView(
            CalendarView.year,
            focus: _focus,
            from: global,
            direction: ZoomDirection.zoomOut,
          );
        }
      case CalendarView.week:
        if (zoomIn) return;
        // Haftanın ortası hangi aydaysa o ay.
        final mid = DateTime(_focus.year, _focus.month, _focus.day + 3);
        _setView(
          CalendarView.month,
          focus: monthOf(mid),
          from: global,
          direction: ZoomDirection.zoomOut,
        );
      case CalendarView.agenda:
        if (zoomIn) return;
        _setView(
          CalendarView.month,
          focus: monthOf(_selected),
          from: global,
          direction: ZoomDirection.zoomOut,
        );
    }
  }

  void _onPreview(double scale, Offset focal) {
    if (_view == CalendarView.agenda) return;
    final s = scale.clamp(0.9, 1.1);
    final (old, origin) = _preview.value;
    if ((s - old).abs() < 0.004 && s != 1) return;
    _preview.value = (s, s == 1 ? origin : _alignmentAt(focal));
  }

  void _goToday() {
    _today = startOfDay(widget.now ?? DateTime.now());
    setState(() {
      _selected = _today;
      _focus = _today;
      _month = monthOf(_today);
      _windowDays = _kAgendaWindowDays;
    });
    _pagerKey.currentState?.animateToPage(_pageOf(_view, _today));
  }

  void _step(int delta) => _pagerKey.currentState?.step(delta);

  Future<void> _newEvent() => showEventEditor(context, day: _selected);

  void _openEntry(AgendaEntry e) {
    switch (e) {
      case EventOccurrence(:final event, :final start):
        unawaited(
          showEventEditor(context, existing: event, occurrenceStart: start),
        );
      case TaskEntry(:final task):
        unawaited(showTaskEditor(context, existing: task));
      case ReminderEntry(:final note):
        unawaited(context.pushNote(noteRoutePath(note.id)));
    }
  }

  /// Sürükle-bırak ile güne taşıma (F47.5); "Geri al" eski hâli yazar.
  void _moveEntry(AgendaEntry entry, DateTime day) {
    final moved = movedToDay(entry, day);
    if (moved == null) return;
    final calendar = ref.read(calendarRepositoryProvider);
    final notes = ref.read(notesRepositoryProvider);
    final VoidCallback undo;
    switch (moved) {
      case CalendarEvent():
        if (calendar == null) return;
        final before = (entry as EventOccurrence).event;
        calendar.saveEvent(moved);
        undo = () => calendar.saveEvent(before);
      case TaskItem():
        if (calendar == null) return;
        final before = (entry as TaskEntry).task;
        calendar.saveTask(moved);
        undo = () => calendar.saveTask(before);
      case Note():
        if (notes == null) return;
        final before = (entry as ReminderEntry).note;
        notes.setReminder(moved.id, moved.reminderAt);
        undo = () => notes.setReminder(before.id, before.reminderAt);
      default:
        return;
    }
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    showUndoSnackBar(
      context,
      message: l10n.calendarMoved(DateFormat.MMMEd().format(day)),
      undoLabel: l10n.undo,
      onUndo: undo,
    );
  }

  Future<void> _showDay(DateTime day, CalendarData data) {
    setState(() => _selected = startOfDay(day));
    return showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DaySheet(
        day: day,
        today: _today,
        data: data,
        onNewEvent: () {
          Navigator.pop(ctx);
          unawaited(showEventEditor(context, day: day));
        },
        onNewTask: () {
          Navigator.pop(ctx);
          unawaited(showTaskEditor(context, due: day));
        },
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_view) {
    CalendarView.year => '${_focus.year}',
    CalendarView.month => DateFormat.yMMMM().format(_focus),
    CalendarView.week => () {
      final s = weekStartOf(_focus, _firstDow);
      final e = DateTime(s.year, s.month, s.day + 6);
      return '${DateFormat.MMMd().format(s)} – ${DateFormat.yMMMd().format(e)}';
    }(),
    CalendarView.agenda => DateFormat.yMMMM().format(_month),
  };

  IconData _viewIcon(CalendarView v) => switch (v) {
    CalendarView.year => Icons.calendar_view_month_outlined,
    CalendarView.month => Icons.calendar_month_outlined,
    CalendarView.week => Icons.view_week_outlined,
    CalendarView.agenda => Icons.view_agenda_outlined,
  };

  String _viewLabel(AppLocalizations l10n, CalendarView v) => switch (v) {
    CalendarView.year => l10n.calendarViewYear,
    CalendarView.month => l10n.calendarViewMonth,
    CalendarView.week => l10n.calendarViewWeek,
    CalendarView.agenda => l10n.calendarViewAgenda,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(eventsStreamProvider);
    final tasks = ref.watch(tasksStreamProvider).value ?? const <TaskItem>[];
    final reminders = ref.watch(calendarReminderNotesProvider);
    final eventList = events.value ?? const <CalendarEvent>[];
    final data = CalendarData(
      events: eventList,
      tasks: tasks,
      reminders: reminders,
    );
    final wide = MediaQuery.sizeOf(context).width >= _kWideCalendar;
    final paged = _view != CalendarView.agenda;

    final titleText = Text(_title(l10n), overflow: TextOverflow.ellipsis);
    final bar = AppBar(
      titleSpacing: wide ? null : 8,
      title: _view == CalendarView.agenda && !wide
          ? InkWell(
              key: const ValueKey('calendar-month-toggle'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _monthOpen = !_monthOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: titleText),
                    Icon(
                      _monthOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      semanticLabel: _monthOpen
                          ? l10n.calendarHideMonth
                          : l10n.calendarShowMonth,
                    ),
                  ],
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (paged && wide)
                  IconButton(
                    tooltip: l10n.calendarPrevious,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _step(-1),
                  ),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.short),
                    child: KeyedSubtree(
                      key: ValueKey(_title(l10n)),
                      child: titleText,
                    ),
                  ),
                ),
                if (paged && wide)
                  IconButton(
                    tooltip: l10n.calendarNext,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _step(1),
                  ),
              ],
            ),
      actions: [
        IconButton(
          tooltip: l10n.calendarToday,
          icon: const Icon(Icons.today_outlined),
          onPressed: _goToday,
        ),
        PopupMenuButton<CalendarView>(
          key: const ValueKey('calendar-view-menu'),
          tooltip: l10n.calendarView,
          icon: Icon(_viewIcon(_view)),
          initialValue: _view,
          onSelected: (v) {
            if (v == _view) return;
            final dir = v.index < _view.index
                ? ZoomDirection.zoomOut
                : ZoomDirection.zoomIn;
            _setView(
              v,
              focus: switch (v) {
                CalendarView.week => weekStartOf(
                  _selected.month == _focus.month ||
                          _view == CalendarView.agenda
                      ? _selected
                      : _focus,
                  _firstDow,
                ),
                _ => _view == CalendarView.agenda ? _selected : _focus,
              },
              direction: dir,
            );
          },
          itemBuilder: (_) => [
            for (final v in CalendarView.values)
              PopupMenuItem(
                value: v,
                child: Row(
                  children: [
                    Icon(_viewIcon(v), size: 20),
                    const SizedBox(width: 12),
                    Text(_viewLabel(l10n, v)),
                  ],
                ),
              ),
          ],
        ),
        IconButton(
          key: const ValueKey('calendar-tasks'),
          tooltip: l10n.tasksTitle,
          icon: const Icon(Icons.task_alt),
          onPressed: () => unawaited(context.push('/tasks')),
        ),
        IconButton(
          tooltip: l10n.remindersTitle,
          icon: const Icon(Icons.alarm_outlined),
          onPressed: () => unawaited(context.push('/reminders')),
        ),
      ],
    );

    final now = widget.now ?? DateTime.now();
    // Yerel kopya: geçişte sönen eski görünüm de kendi türünde sayfa kursun
    // (kapanış `_view`i okusaydı yeni görünümün sayfalarını kurardı).
    final view = _view;
    final Widget current = switch (view) {
      CalendarView.agenda => _agendaView(context, data, wide),
      _ => _PagedView(
        key: _pagerKey,
        initialPage: _pageOf(_view, _focus),
        itemCount: switch (_view) {
          CalendarView.year => kYearPages,
          CalendarView.week => kWeekPages,
          _ => kMonthPages,
        },
        locked: _pinching,
        onPageChanged: (i) => setState(() {
          if (view != _view) return;
          _focus = _dateOfPage(i);
          if (_view == CalendarView.month &&
              (_selected.year != _focus.year ||
                  _selected.month != _focus.month)) {
            _selected =
                _focus.year == _today.year && _focus.month == _today.month
                ? _today
                : _focus;
          }
        }),
        itemBuilder: (context, i) => switch (view) {
          CalendarView.year => YearPage(
            year: 2000 + i,
            data: data,
            today: _today,
            firstDow: _firstDow,
            targets: _targets,
            onMonthTap: (m, at) =>
                _setView(CalendarView.month, focus: m, from: at),
          ),
          CalendarView.week => WeekPage(
            weekStart: weekAtIndex(i, _firstDow),
            data: data,
            today: _today,
            now: now,
            onSlotTap: (t) => unawaited(showEventEditor(context, start: t)),
            onEntryTap: _openEntry,
            onDayTap: (d) => unawaited(_showDay(d, data)),
          ),
          _ => MonthPage(
            month: monthAtIndex(i),
            data: data,
            today: _today,
            selected: _selected,
            firstDow: _firstDow,
            targets: _targets,
            onDayTap: (d) => unawaited(_showDay(d, data)),
            onEntryMove: _moveEntry,
            onDayLongPress: (d) {
              setState(() => _selected = d);
              unawaited(showEventEditor(context, day: d));
            },
          ),
        },
      ),
    };

    final duration = AppMotion.of(context, AppMotion.medium);
    final zoomIn = _lastZoom == ZoomDirection.zoomIn;
    final body = PinchZoomDetector(
      onZoom: _onZoom,
      onPreview: _onPreview,
      onPinchingChanged: (v) => setState(() => _pinching = v),
      child: ClipRect(
        key: _bodyKey,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: AppMotion.curveOf(context, Curves.easeOutCubic),
          switchOutCurve: AppMotion.curveOf(context, Curves.easeInCubic),
          layoutBuilder: (cur, prev) =>
              Stack(fit: StackFit.expand, children: [...prev, ?cur]),
          transitionBuilder: (child, animation) {
            final incoming =
                child.key == ValueKey('view-${_view.name}-$_epoch');
            // Yakınlaşırken yeni görünüm noktadan büyür, eskisi büyüyerek
            // söner; uzaklaşırken tersi.
            final from = incoming
                ? (zoomIn ? 0.55 : 1.6)
                : (zoomIn ? 1.6 : 0.55);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                alignment: _origin,
                scale: Tween<double>(begin: from, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey('view-${_view.name}-$_epoch'),
            child: ValueListenableBuilder<(double, Alignment)>(
              valueListenable: _preview,
              builder: (context, p, child) =>
                  Transform.scale(scale: p.$1, alignment: p.$2, child: child),
              child: current,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: HomeInBar(appBar: bar),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('calendar-new-event'),
        tooltip: l10n.calendarNewEvent,
        onPressed: _newEvent,
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }

  Widget _agendaView(BuildContext context, CalendarData data, bool wide) {
    final l10n = context.l10n;
    final gridStart = gridStartFor(_month, _firstDow);
    final busy = data
        .range(
          gridStart,
          DateTime(gridStart.year, gridStart.month, gridStart.day + 42),
        )
        .keys
        .toSet();
    void select(DateTime d) => setState(() {
      _selected = startOfDay(d);
      _focus = _selected;
      _month = monthOf(d);
      _windowDays = _kAgendaWindowDays;
      if (!wide) _monthOpen = false;
    });
    final grid = MonthGrid(
      month: _month,
      selected: _selected,
      busy: busy,
      now: _today,
      showHeader: wide,
      onSelect: select,
      onMonthChange: (delta) =>
          setState(() => _month = DateTime(_month.year, _month.month + delta)),
    );
    final isEmpty =
        data.events.isEmpty && data.tasks.isEmpty && data.reminders.isEmpty;
    final list = isEmpty
        ? EmptyState(
            icon: Icons.calendar_month_outlined,
            title: l10n.calendarEmpty,
            subtitle: l10n.calendarEmptyHint,
            actionLabel: l10n.calendarNewEvent,
            actionIcon: Icons.add,
            onAction: _newEvent,
          )
        : _AgendaList(
            key: ValueKey(dayKey(_selected)),
            from: _selected,
            days: _windowDays,
            today: _today,
            events: data.events,
            tasks: data.tasks,
            reminders: data.reminders,
            onMore: () => setState(() => _windowDays += _kAgendaWindowDays),
          );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: SingleChildScrollView(child: grid)),
          const VerticalDivider(width: 1),
          Expanded(child: list),
        ],
      );
    }
    return Column(
      children: [
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.short),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _monthOpen ? grid : const SizedBox(width: double.infinity),
        ),
        if (_monthOpen) const Divider(height: 1),
        Expanded(child: list),
      ],
    );
  }
}

/// Dönem sayfaları (yatay kaydırma). Kendi denetleyicisi var: görünüm
/// değişince eski sayfa geçiş bitene dek kendi denetleyicisiyle yaşar.
class _PagedView extends StatefulWidget {
  const _PagedView({
    super.key,
    required this.initialPage,
    required this.itemCount,
    required this.itemBuilder,
    required this.onPageChanged,
    required this.locked,
  });

  final int initialPage;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onPageChanged;

  /// İki parmak inmişken sayfa kaymasın.
  final bool locked;

  @override
  State<_PagedView> createState() => _PagedViewState();
}

class _PagedViewState extends State<_PagedView> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage.clamp(0, widget.itemCount - 1),
  );

  void animateToPage(int page) {
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? widget.initialPage;
    final target = page.clamp(0, widget.itemCount - 1);
    if ((target - current).abs() > 3) {
      _controller.jumpToPage(target);
    } else {
      unawaited(
        _controller.animateToPage(
          target,
          duration: AppMotion.of(context, AppMotion.medium),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  void step(int delta) {
    if (!_controller.hasClients) return;
    animateToPage((_controller.page?.round() ?? widget.initialPage) + delta);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.itemCount,
    physics: widget.locked
        ? const NeverScrollableScrollPhysics()
        : const PageScrollPhysics(),
    onPageChanged: widget.onPageChanged,
    itemBuilder: widget.itemBuilder,
  );
}

/// Ay/hafta görünümünde güne dokununca: o günün kayıtları + yeni etkinlik /
/// görev.
class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.today,
    required this.data,
    required this.onNewEvent,
    required this.onNewTask,
  });

  final DateTime day;
  final DateTime today;
  final CalendarData data;
  final VoidCallback onNewEvent;
  final VoidCallback onNewTask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries =
        data.range(day, DateTime(day.year, day.month, day.day + 1))[dayKey(
          day,
        )] ??
        const <AgendaEntry>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayHeader(day: day, today: today),
            Flexible(
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                      child: Text(
                        l10n.calendarNothingThisDay,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final e in entries)
                          switch (e) {
                            EventOccurrence occ => _EventTile(occurrence: occ),
                            TaskEntry t => _TaskTile(task: t.task),
                            ReminderEntry r => _ReminderTile(entry: r),
                          },
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onNewEvent,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(l10n.calendarNewEvent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onNewTask,
                      icon: const Icon(Icons.add_task),
                      label: Text(l10n.tasksNewTask),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    required this.onMore,
  });

  final DateTime from;
  final int days;
  final DateTime today;
  final List<CalendarEvent> events;
  final List<TaskItem> tasks;
  final List<Note> reminders;
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
    );
    final rows = <Object>[];
    final selectedKey = dayKey(from);
    if (!agenda.containsKey(selectedKey)) {
      rows
        ..add(from)
        ..add(l10n.calendarNothingThisDay);
    }
    for (final e in agenda.entries) {
      rows.add(parseDayKey(e.key)!);
      rows.addAll(e.value);
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
          DateTime day => _DayHeader(day: day, today: today),
          String text => Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          EventOccurrence occ => _EventTile(occurrence: occ),
          TaskEntry t => _TaskTile(task: t.task),
          ReminderEntry r => _ReminderTile(entry: r),
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
  const _DayHeader({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final text = isToday
        ? '${context.l10n.calendarToday} · ${DateFormat.MMMMEEEEd().format(day)}'
        : DateFormat.MMMMEEEEd().format(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isToday ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Satır kabuğu: solda renk şeridi, kart zemini.
class _EntryShell extends StatelessWidget {
  const _EntryShell({required this.accent, required this.child, this.onTap});

  final Color accent;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: child,
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
    return _EntryShell(
      accent: e.color != null ? Color(e.color!) : scheme.primary,
      onTap: () => showEventEditor(
        context,
        existing: e,
        occurrenceStart: occurrence.start,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title.isEmpty ? l10n.eventUntitled : e.title,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (e.repeats)
            Icon(Icons.repeat, size: 16, color: scheme.onSurfaceVariant),
          if (e.reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.notifications_none,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(calendarRepositoryProvider);
    return _EntryShell(
      accent: scheme.tertiary,
      onTap: () => showTaskEditor(context, existing: task),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: repo == null
                ? null
                : (v) => v == true
                      ? repo.completeTaskNow(task)
                      : repo.uncompleteTask(task),
          ),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (task.hasTime)
            Text(
              DateFormat.Hm().format(task.dueAt!),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
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
    return _EntryShell(
      accent: scheme.secondary,
      onTap: () => unawaited(context.pushNote(noteRoutePath(note.id))),
      child: Row(
        children: [
          Icon(Icons.alarm, size: 18, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? l10n.remindersUntitled : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${DateFormat.Hm().format(entry.at)} · ${l10n.calendarReminderTag}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
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
