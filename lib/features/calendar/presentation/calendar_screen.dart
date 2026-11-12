import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../core/widgets/back_closes.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/calendar_repository.dart';
import '../data/holiday_source.dart';
import '../data/task_note_sync.dart';
import '../data/google_calendar_sync.dart';
import '../data/google_tasks_sync.dart';
import '../domain/agenda.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/holidays.dart';
import '../domain/task_item.dart';
import 'calendar_entry_delete.dart';
import 'calendar_views.dart';
import 'calendar_ics_ui.dart';
import 'event_editor.dart';
import 'routines_screen.dart';
import 'google_calendar_ui.dart';
import 'note_calendar_links.dart';
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

/// Takvim görünümlerinin ortak verisi (ay/hafta ekranı ve gün sayfası aynı
/// kaynaktan okur).
final calendarDataProvider = Provider<CalendarData>((ref) {
  final events = ref.watch(eventsStreamProvider);
  final google = ref.watch(googleCalendarEventsProvider);
  return CalendarData(
    events: [...?events.value, ...google],
    tasks: ref.watch(tasksStreamProvider).value ?? const <TaskItem>[],
    reminders: ref.watch(calendarReminderNotesProvider),
    routines: ref.watch(routinesStreamProvider).value ?? const [],
    routineLogs: ref.watch(routineLogsStreamProvider).value ?? const {},
    holidays: ref.watch(holidayCalendarProvider),
  );
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
  const CalendarScreen({super.key, this.now, this.initialDay});

  /// Açılınca seçili gün (`/calendar?day=YYYY-MM-DD`, notun bağ hapından).
  final DateTime? initialDay;

  /// Test için "şimdi".
  final DateTime? now;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _today = startOfDay(widget.now ?? DateTime.now());
  late DateTime _selected = widget.initialDay == null
      ? _today
      : startOfDay(widget.initialDay!);

  /// Görünen dönemin içindeki bir gün (ay/hafta/yıl sayfası bundan).
  late DateTime _focus = _selected;
  late CalendarView _view = _storedView();

  // Ajanda görünümü.
  late DateTime _month = monthOf(_selected);
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

  /// Ekran açıkken Google Takvim 15 dk'da bir tazelenir (K8).
  Timer? _googleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePinchHint();
      _refreshGoogle();
    });
    _googleTimer = Timer.periodic(
      GoogleCalendarController.refreshEvery,
      (_) => _refreshGoogle(),
    );
  }

  void _refreshGoogle() {
    if (!mounted) return;
    unawaited(ref.read(googleCalendarProvider.notifier).refresh());
    // Görevler ajandada da görünür (F50.4).
    unawaited(ref.read(googleTasksProvider.notifier).sync());
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
    _googleTimer?.cancel();
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
        if (zoomIn) {
          // Hafta → gün: odaktaki gün (haftanın içindeyse seçili gün).
          final day = _targets.at(global) ?? _selected;
          final end = _focus.add(const Duration(days: 7));
          _setView(
            CalendarView.agenda,
            focus: !day.isBefore(_focus) && day.isBefore(end) ? day : _focus,
            from: global,
          );
          return;
        }
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

  Future<void> _newEvent() => showEventEditor(
    context,
    day:
        _view != CalendarView.month ||
            (_selected.year == _focus.year && _selected.month == _focus.month)
        ? _selected
        : (_focus.year == _today.year && _focus.month == _today.month
              ? _today
              : DateTime(_focus.year, _focus.month)),
  );

  void _openEntry(AgendaEntry e) {
    switch (e) {
      case EventOccurrence(:final event, :final start) when event.fromGoogle:
        unawaited(showGoogleEventSheet(context, event, start));
      case EventOccurrence(:final event, :final start):
        unawaited(
          showEventEditor(context, existing: event, occurrenceStart: start),
        );
      case TaskEntry(:final task):
        unawaited(showTaskEditor(context, existing: task));
      case RoutineEntry(:final routine, :final day):
        unawaited(showRoutineDaySheet(context, routine, day));
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

  /// Güne çift dokunuş (kullanıcı isteği 2026-11-07): yalnız o günün
  /// sayfası — tek günlük saat çizelgesi, ileri/geri gün.
  void _openDayPage(DateTime day) {
    setState(() => _selected = startOfDay(day));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CalendarDayScreen(
            day: startOfDay(day),
            today: _today,
            now: widget.now,
            onEntryTap: _openEntry,
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (_view) {
    CalendarView.year => '${_focus.year}',
    CalendarView.month => DateFormat.yMMMM().format(_focus),
    CalendarView.week => () {
      final s = weekStartOf(_focus, _firstDow);
      final e = DateTime(s.year, s.month, s.day + 6);
      // Kısa başlık: "16 Kas – 22 Kas 2026" telefonda "…" ile kesiliyordu.
      // Aynı ay "16–22 Kasım", ay aşımı "30 Kas – 6 Ara"; yıl yalnız bu
      // yıl değilse.
      final year = e.year != _today.year ? ' ${e.year}' : '';
      if (s.month == e.month) {
        return '${s.day}–${e.day} ${DateFormat.MMMM().format(e)}$year';
      }
      return '${DateFormat.MMMd().format(s)} – ${DateFormat.MMMd().format(e)}'
          '$year';
    }(),
    CalendarView.agenda => DateFormat.yMMMM().format(_month),
  };

  PopupMenuItem<String> _menuItem(String value, IconData icon, String text) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Flexible(child: Text(text)),
          ],
        ),
      );

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
    final data = ref.watch(calendarDataProvider);
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
                // İLERİ/GERİ (kullanıcı isteği 2026-11-07): dar ekranda da
                // var; yalnız kaydırma bilinmiyordu. Sıkı düğme — ay başlığına
                // yer kalsın (bkz. aşağıdaki "AY BAŞLIĞI GÖRÜNMÜYORDU").
                if (paged)
                  IconButton(
                    key: const ValueKey('calendar-step-left'),
                    tooltip: l10n.calendarPrevious,
                    visualDensity: wide ? null : VisualDensity.compact,
                    constraints: wide
                        ? null
                        : const BoxConstraints(minWidth: 36, minHeight: 40),
                    padding: wide ? null : EdgeInsets.zero,
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
                // İLERİ/GERİ (kullanıcı isteği 2026-11-07): dar ekranda da
                // var; yalnız kaydırma bilinmiyordu. Sıkı düğme — ay başlığına
                // yer kalsın (bkz. aşağıdaki "AY BAŞLIĞI GÖRÜNMÜYORDU").
                if (paged)
                  IconButton(
                    key: const ValueKey('calendar-step-right'),
                    tooltip: l10n.calendarNext,
                    visualDensity: wide ? null : VisualDensity.compact,
                    constraints: wide
                        ? null
                        : const BoxConstraints(minWidth: 36, minHeight: 40),
                    padding: wide ? null : EdgeInsets.zero,
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
        // AY BAŞLIĞI GÖRÜNMÜYORDU (kullanıcı bulgusu 2026-11-06: "takvimde
        // hangi ay olduğu görülmüyor"): telefonda yedi simge başlığı sıfıra
        // sıkıştırıyordu. Dar ekranda görevler/hatırlatıcılar/rutinler/
        // Google/.ics tek ⋮ menüde; başlığa yer kalıyor.
        if (wide) ...[
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
          IconButton(
            key: const ValueKey('calendar-routines'),
            tooltip: l10n.routinesTitle,
            icon: const Icon(kRoutineIcon),
            onPressed: () => unawaited(context.push('/routines')),
          ),
          if (ref.watch(googleCalendarAvailableProvider))
            IconButton(
              key: const ValueKey('calendar-google'),
              tooltip: l10n.gcalTitle,
              icon: Icon(
                ref.watch(googleCalendarProvider.select((s) => s.connected))
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_outlined,
              ),
              onPressed: () => unawaited(showGoogleCalendarSheet(context)),
            ),
        ],
        PopupMenuButton<String>(
          key: const ValueKey('calendar-more'),
          onSelected: (v) => unawaited(switch (v) {
            'tasks' => context.push('/tasks'),
            'reminders' => context.push('/reminders'),
            'routines' => context.push('/routines'),
            'google' => showGoogleCalendarSheet(context),
            'export' => exportCalendarIcs(context, ref),
            'holidays' => Future(
              () => ref.read(showHolidaysProvider.notifier).toggle(),
            ),
            _ => importCalendarIcs(context, ref),
          }),
          itemBuilder: (_) => [
            if (!wide) ...[
              _menuItem('tasks', Icons.task_alt, l10n.tasksTitle),
              _menuItem('reminders', Icons.alarm_outlined, l10n.remindersTitle),
              _menuItem('routines', kRoutineIcon, l10n.routinesTitle),
              if (ref.read(googleCalendarAvailableProvider))
                _menuItem(
                  'google',
                  ref.read(googleCalendarProvider).connected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_outlined,
                  l10n.gcalTitle,
                ),
              const PopupMenuDivider(),
            ],
            CheckedPopupMenuItem(
              key: const ValueKey('calendar-holidays-toggle'),
              value: 'holidays',
              checked: ref.read(showHolidaysProvider),
              child: Text(l10n.calendarHolidays),
            ),
            const PopupMenuDivider(),
            _menuItem('export', Icons.ios_share, l10n.calendarIcsExport),
            _menuItem(
              'import',
              Icons.file_open_outlined,
              l10n.calendarIcsImport,
            ),
          ],
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
        locked: _pinching || !ref.watch(calendarSwipeProvider),
        onPageChanged: (i) => setState(() {
          if (view != _view) return;
          // Sayfa çevirince seçim DEĞİŞMEZ (kullanıcı isteği 2026-11-08):
          // eskiden her ayın 1'i kendiliğinden çerçeveye alınıyordu. "Yeni"
          // gibi seçili güne bakan işler görünen ayda seçim yoksa ayın
          // ilk gününü kullanır (bkz. [_newEvent]).
          _focus = _dateOfPage(i);
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
            // Üstteki güne dokununca o günün sayfası (kullanıcı isteği
            // 2026-11-07; önceden alttan levha açılıyordu).
            onDayTap: _openDayPage,
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
            onDayDoubleTap: _openDayPage,
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
      // Yıl ve ay görünümünde dikey kaydırma yok: düz tekerlek geçiş yapar.
      // Hafta/gün görünümü tekerlekle kayar; orada Ctrl + tekerlek geçer.
      wheelZoom:
          _view == CalendarView.year || _view == CalendarView.month,
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
      // Takvimde yazı alanı yok; klavye yalnız üstteki levhalarda açılır.
      // Boyut değişseydi ay ızgarası/sayfalar klavyenin HER KARESİNDE yeniden
      // yerleşirdi (yeni etkinlik kasması, 2026-11-06).
      resizeToAvoidBottomInset: false,
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
      swipeEnabled: ref.watch(calendarSwipeProvider),
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
        // Açık ay paneli geri tuşuyla önce kapanır (bkz. [BackCloses]).
        BackCloses(
          open: _monthOpen,
          onClose: () => setState(() => _monthOpen = false),
          child: const SizedBox.shrink(),
        ),
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

/// "Bu güne not" (F49.1): güne bağlı, başlığı günün adı olan not varsa
/// açar; yoksa oluşturur ve güne bağlar.
///
/// SİYAH EKRAN (kullanıcı bulgusu 2026-11-07): not ham `/note/:id` yoluyla
/// push ediliyordu; takvim SplitShell kabuğunun DIŞINDA olduğundan ikinci
/// bir kabuk kuruluyordu (bkz. [notePushPath]). Yol konuma göre seçilir.
Future<void> openDayNote(
  BuildContext context,
  WidgetRef ref,
  DateTime day, {
  bool popFirst = false,
}) async {
  final notes = ref.read(notesRepositoryProvider);
  final calendar = ref.read(calendarRepositoryProvider);
  if (notes == null || calendar == null) return;
  final key = dayKey(day);
  final title = dayNoteTitle(day);
  final linked = ref.read(dayLinksStreamProvider).value?[key] ?? const [];
  final all = ref.read(notesStreamProvider).value ?? const <Note>[];
  final existing = all
      .where(
        (n) =>
            linked.contains(n.id) &&
            n.deletedAt == null &&
            n.title.trim() == title,
      )
      .firstOrNull;
  // Sayfasız rota (gün sayfası) bilgisi pop'tan ÖNCE alınır.
  final router = GoRouter.of(context);
  final route = ModalRoute.of(context);
  final pageless = !popFirst && route != null && route.settings is! Page;
  if (popFirst) Navigator.pop(context);
  final id =
      existing?.id ?? await notes.createNote(NoteType.text, title: title);
  if (existing == null) calendar.linkNoteToDay(key, id);
  final path = noteRoutePath(id);
  unawaited(
    pageless
        ? router.push('$kOutsideShellNotePrefix$path')
        : router.pushNote(path),
  );
}

/// Ay/hafta görünümünde güne dokununca: o günün kayıtları + yeni etkinlik /
/// görev.
/// Bir günün levhası (kayıtlar + sil + yeni etkinlik/görev) — takvim
/// ekranının dışından da (ana ekrandaki 10 günlük şerit) açılır.
Future<void> showCalendarDaySheet(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) {
  final d = startOfDay(day);
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _DaySheet(
      day: d,
      today: startOfDay(DateTime.now()),
      data: ref.read(calendarDataProvider),
      onNewEvent: () {
        Navigator.pop(ctx);
        unawaited(showEventEditor(context, day: d));
      },
      onNewTask: () {
        Navigator.pop(ctx);
        unawaited(showTaskEditor(context, due: d));
      },
    ),
  );
}

/// Gün levhası/ajanda satırı + sağda tek dokunuşla sil (bkz.
/// [quickDeleteEntry]).
Widget _withQuickDelete(AgendaEntry e, Widget tile) => !canQuickDelete(e)
    ? tile
    : Row(
        children: [
          Expanded(child: tile),
          QuickDeleteButton(entry: e),
        ],
      );

class _DaySheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = dayKey(day);
    final linked = ref.watch(dayLinksStreamProvider).value?[key] ?? const [];
    // O gün yazılan/düzenlenen notlar (F49.3) — açılır bölüm.
    final written = [
      for (final n in ref.watch(notesStreamProvider).value ?? const <Note>[])
        if (n.deletedAt == null &&
            n.archivedAt == null &&
            !linked.contains(n.id) &&
            n.updatedAt != null &&
            startOfDay(n.updatedAt!) == day)
          n,
    ];
    // CANLI veri (açılıştaki anlık görüntü değil): levhadan silinen ya da
    // düzenlenen kayıt hemen kaybolsun/güncellensin.
    final source = ref.watch(calendarDataProvider);
    final entries =
        source.range(day, DateTime(day.year, day.month, day.day + 1))[dayKey(
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
            if (data.holidays.on(day) case final h?)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: HolidayChip(
                    holiday: h,
                    full: true,
                    height: 22,
                    estimatedLabel: l10n.calendarHolidayEstimated,
                  ),
                ),
              ),
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
                          _withQuickDelete(
                            e,
                            switch (e) {
                              EventOccurrence occ =>
                                _EventTile(occurrence: occ),
                              TaskEntry t => _TaskTile(task: t.task),
                              ReminderEntry r => _ReminderTile(entry: r),
                              RoutineEntry r => _RoutineTile(entry: r),
                            },
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinkedNotesList(
                noteIds: linked,
                onUnlink: (id) => ref
                    .read(calendarRepositoryProvider)
                    ?.unlinkNoteFromDay(key, id),
              ),
            ),
            if (written.isNotEmpty)
              ExpansionTile(
                key: const ValueKey('day-written-notes'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(l10n.calendarDayWrittenNotes(written.length)),
                children: [
                  for (final n in written.take(30))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: Text(
                        n.displayTitle.trim().isEmpty
                            ? l10n.untitledNote
                            : n.displayTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () =>
                          unawaited(context.pushNote(noteRoutePath(n.id))),
                    ),
                ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('day-note'),
                      onPressed: () => unawaited(
                        openDayNote(context, ref, day, popFirst: true),
                      ),
                      icon: const Icon(Icons.edit_note),
                      label: Text(l10n.calendarDayNote),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('day-link-note'),
                      onPressed: () => unawaited(
                        linkExistingNote(context, ref, dayKey: key),
                      ),
                      icon: const Icon(Icons.link),
                      label: Text(l10n.calendarLinkExistingNote),
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
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final base = isToday
        ? '${context.l10n.calendarToday} · ${DateFormat.MMMMEEEEd().format(day)}'
        : DateFormat.MMMMEEEEd().format(day);
    final text = holiday == null ? base : '$base · ${holiday!.name}';
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
                : (v) => setTaskCompleted(ref, task, v == true),
          ),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.of(Theme.of(context)).rowTitle.copyWith(
                decoration: task.completed ? TextDecoration.lineThrough : null,
                color: task.completed ? scheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (task.hasTime)
            Text(
              DateFormat.Hm().format(task.dueAt!),
              style: AppText.of(Theme.of(context)).meta,
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
          Icon(Icons.alarm, size: 18, color: scheme.secondary),
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
                  '${DateFormat.Hm().format(entry.at)} · ${l10n.calendarReminderTag}',
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
            size: 18,
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
    required this.today,
    required this.onEntryTap,
    this.now,
  });

  final DateTime day;
  final DateTime today;
  final ValueChanged<AgendaEntry> onEntryTap;

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
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _goToday() {
    if (!_controller.hasClients) return;
    final i = _kCenter + widget.today.difference(widget.day).inDays;
    _controller.jumpToPage(i.clamp(0, 2 * _kCenter));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(calendarDataProvider);
    final now = widget.now ?? DateTime.now();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          DateFormat.yMMMMEEEEd().format(_day),
          overflow: TextOverflow.ellipsis,
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.calendarNewEvent,
        onPressed: () => unawaited(showEventEditor(context, day: _day)),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
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
                today: widget.today,
                now: now,
                onSlotTap: (t) => unawaited(showEventEditor(context, start: t)),
                onEntryTap: widget.onEntryTap,
                onDayTap: (_) {},
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 88, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          unawaited(showTaskEditor(context, due: _day)),
                      icon: const Icon(Icons.add_task),
                      label: Text(
                        l10n.tasksNewTask,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('day-page-note'),
                      onPressed: () =>
                          unawaited(openDayNote(context, ref, _day)),
                      icon: const Icon(Icons.edit_note),
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
        ],
      ),
    );
  }
}
