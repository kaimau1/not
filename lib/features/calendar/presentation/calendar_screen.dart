import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../core/app_icons.dart';
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
import '../../../core/haptics.dart';

/// Hatırlatıcılı notlar (gizli klasör bastırması Hatırlatıcılar ekranıyla
/// aynı kural). İlgisiz bir not düzenlendiğinde takvim/ana ekran şeridi
/// yeniden kurulmaz (`_NoteListSlice` eşitliğiyle süzülür).
final calendarReminderNotesProvider = Provider<List<Note>>((ref) {
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final slice = ref.watch(
    notesStreamProvider.select((async) {
      final notes = async.value ?? const <Note>[];
      return _NoteListSlice([
        for (final n in notes)
          if (n.reminderAt != null &&
              (n.folderId == null || !suppressed.contains(n.folderId)))
            n,
      ]);
    }),
  );
  return slice.notes;
});

/// Zamanlı notlar (U4, `expiresAt`): arşivlenmemiş, gizli klasörde değil.
final calendarTimedNotesProvider = Provider<List<Note>>((ref) {
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final slice = ref.watch(
    notesStreamProvider.select((async) {
      final notes = async.value ?? const <Note>[];
      return _NoteListSlice([
        for (final n in notes)
          if (n.expiresAt != null &&
              n.archivedAt == null &&
              n.deletedAt == null &&
              (n.folderId == null || !suppressed.contains(n.folderId)))
            n,
      ]);
    }),
  );
  return slice.notes;
});

/// Güne bağlı notlar (silinmemiş, gizli klasörde olmayan), saatleriyle.
/// Yalnızca gerçekten bağlı notların özeti dinlenir; bağlı olmayan notlarda
/// yapılan her yazım/otomatik kayıt ana ekran şeridini ve takvimi tetiklemez.
final calendarDayNotesProvider = Provider<Map<String, List<DayNote>>>((ref) {
  final links = ref.watch(dayLinksStreamProvider).value ?? const {};
  if (links.isEmpty) return const {};
  final times = ref.watch(dayLinkTimesStreamProvider).value ?? const {};
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final linkedIds = <String>{
    for (final list in links.values) ...list,
  };
  final slice = ref.watch(
    notesStreamProvider.select((async) {
      final notes = async.value ?? const <Note>[];
      return _NoteListSlice([
        for (final n in notes)
          if (linkedIds.contains(n.id) &&
              n.deletedAt == null &&
              (n.folderId == null || !suppressed.contains(n.folderId)))
            n,
      ]);
    }),
  );
  final byId = {for (final n in slice.notes) n.id: n};
  final out = <String, List<DayNote>>{};
  for (final e in links.entries) {
    final list = <DayNote>[
      for (final id in e.value)
        if (byId[id] case final n?) (note: n, minutes: times[e.key]?[id]),
    ];
    if (list.isNotEmpty) out[e.key] = list;
  }
  return out;
});

/// Takvim görünümlerini ilgilendiren alanlara göre değer eşitliği sunan dilim.
class _NoteListSlice {
  const _NoteListSlice(this.notes);

  final List<Note> notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _NoteListSlice || other.notes.length != notes.length) {
      return false;
    }
    for (var i = 0; i < notes.length; i++) {
      final a = notes[i], b = other.notes[i];
      if (a.id != b.id ||
          a.title != b.title ||
          a.body != b.body ||
          a.items.length != b.items.length ||
          a.attachments.length != b.attachments.length ||
          a.hasPageInk != b.hasPageInk ||
          a.color != b.color ||
          a.customColor != b.customColor ||
          a.locked != b.locked ||
          a.reminderAt != b.reminderAt ||
          a.reminderRepeat != b.reminderRepeat ||
          a.expiresAt != b.expiresAt ||
          a.archivedAt != b.archivedAt ||
          a.deletedAt != b.deletedAt ||
          a.folderId != b.folderId) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    for (final n in notes)
      Object.hash(
        n.id,
        n.title,
        n.body.length,
        n.items.length,
        n.reminderAt,
        n.expiresAt,
        n.deletedAt,
      ),
  ]);
}

/// Takvim görünümlerinin ortak verisi (ay/hafta ekranı ve gün sayfası aynı
/// kaynaktan okur).
final calendarDataProvider = Provider<CalendarData>((ref) {
  final events = ref.watch(eventsStreamProvider);
  final google = ref.watch(googleCalendarEventsProvider);
  return CalendarData(
    events: [...?events.value, ...google],
    tasks: ref.watch(tasksStreamProvider).value ?? const <TaskItem>[],
    reminders: ref.watch(calendarReminderNotesProvider),
    timedNotes: ref.watch(calendarTimedNotesProvider),
    routines: ref.watch(routinesStreamProvider).value ?? const [],
    routineLogs: ref.watch(routineLogsStreamProvider).value ?? const {},
    holidays: ref.watch(holidayCalendarProvider),
    dayNotes: ref.watch(calendarDayNotesProvider),
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

  /// **GÜN PANELİ** (kullanıcı isteği 2026-11-21): ay görünümünde varsayılan
  /// olarak seçili günün paneli altta açıktır; takvimi ya da tutamağı aşağı
  /// çekince panel kapanıp uzun ay görünümüne geçer. null = uzun ay görünümü.
  late DateTime? _panelDay = _selected;

  /// Panel açıkken takvim daha da daraltıldı (tutamak yukarı çekildi).
  bool _panelCompact = false;

  /// Takvim üstündeki dikey sürükleme birikimi (aşağı çekince uzun takvim).
  double _gridDragDy = 0;

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

  /// Hafta sayfası önbelleği (P46, bütçe S22): sayfa çevrilince
  /// `onPageChanged` → `setState` ekranı yeniden kurar; girdisi değişmeyen
  /// sayfa AYNI örnek dönerse alt ağacı (≈ 330 widget) hiç kurulmaz. Eskiden
  /// her çevirişte giden ve gelen hafta baştan kuruluyordu. "Şimdi" çizgisi
  /// dakikada bir tazelenir (anahtar: dakika).
  final _weekPages = <int, (CalendarData, DateTime, int, DateTime, Widget)>{};

  /// Ay sayfası önbelleği: panelde başka güne geçerken veya sayfa çevirirken
  /// girdisi değişmeyen ay sayfaları baştan kurulmaz (42 hücre × LayoutBuilder).
  final _monthPages =
      <int, (CalendarData, DateTime, DateTime?, int, bool, bool, Widget)>{};

  void _openNotePreview(Note note, DateTime day) {
    final normalized = startOfDay(day);
    setState(() {
      _selected = normalized;
      if (_panelDay != null) _panelDay = normalized;
    });
    final key = dayKey(normalized);
    final times =
        ref.read(dayLinkTimesStreamProvider).value?[key] ??
        const <String, int>{};
    final linkedIds =
        ref.read(dayLinksStreamProvider).value?[key] ?? const <String>[];
    final calendar = ref.read(calendarRepositoryProvider);
    final isLinked = linkedIds.contains(note.id);
    unawaited(
      showCalendarNotePreviewSheet(
        context,
        note: note,
        day: normalized,
        minutes: times[note.id],
        onUnlink: isLinked && calendar != null
            ? () => calendar.unlinkNoteFromDay(key, note.id)
            : null,
      ),
    );
  }

  Widget _monthPage(int i, CalendarData data, bool compact, bool mobile) {
    final month = monthAtIndex(i);
    final firstDow = _firstDow;
    final selectedInMonth =
        _selected.year == month.year && _selected.month == month.month
        ? _selected
        : null;
    final hit = _monthPages[i];
    if (hit != null &&
        identical(hit.$1, data) &&
        hit.$2 == _today &&
        hit.$3 == selectedInMonth &&
        hit.$4 == firstDow &&
        hit.$5 == compact &&
        hit.$6 == mobile) {
      return hit.$7;
    }
    Widget page = MonthPage(
      month: month,
      compact: compact,
      data: data,
      today: _today,
      selected: _selected,
      firstDow: firstDow,
      targets: _targets,
      onDayTap: (d) => unawaited(_showDay(d, data)),
      onNoteTap: _openNotePreview,
      onEntryMove: _moveEntry,
      onDayDoubleTap: _openDayPage,
      onDayLongPress: (d) {
        setState(() => _selected = d);
        unawaited(showEventEditor(context, day: d));
      },
    );
    if (mobile) {
      page = GestureDetector(
        key: const ValueKey('calendar-month-drag-zone'),
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => _gridDragDy = 0,
        onVerticalDragUpdate: (d) => _gridDragDy += d.delta.dy,
        onVerticalDragEnd: _handleGridVerticalEnd,
        child: compact
            ? page
            : Stack(
                children: [
                  page,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpace.s,
                    child: Center(
                      child: _OpenDayPanelPill(
                        selected: _selected,
                        onOpen: () => setState(() {
                          _panelDay = _selected;
                          _panelCompact = false;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }
    if (_monthPages.length > 6) _monthPages.clear();
    _monthPages[i] = (
      data,
      _today,
      selectedInMonth,
      firstDow,
      compact,
      mobile,
      page,
    );
    return page;
  }

  Widget _weekPage(int i, CalendarData data, DateTime now) {
    final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final firstDow = _firstDow;
    final hit = _weekPages[i];
    if (hit != null &&
        identical(hit.$1, data) &&
        hit.$2 == _today &&
        hit.$3 == firstDow &&
        hit.$4 == minute) {
      return hit.$5;
    }
    final page = WeekPage(
      weekStart: weekAtIndex(i, firstDow),
      data: data,
      today: _today,
      now: now,
      onSlotTap: (t) => unawaited(showEventEditor(context, start: t)),
      onEntryTap: _openEntry,
      // Üstteki güne dokununca o günün sayfası (kullanıcı isteği
      // 2026-11-07; önceden alttan levha açılıyordu).
      onDayTap: _openDayPage,
    );
    // Yalnız canlı sayfalar (görünen + komşu) tutulur.
    if (_weekPages.length > 6) _weekPages.clear();
    _weekPages[i] = (data, _today, firstDow, minute, page);
    return page;
  }

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
    bool openPanel = true,
  }) {
    if (view == _view && focus == null) return;
    unawaited(AppHaptics.tick());
    setState(() {
      _panelCompact = false;
      _panelDay = view == CalendarView.month && openPanel ? _selected : null;
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
        _setView(
          CalendarView.month,
          focus: month,
          from: global,
          openPanel: false,
        );
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
          openPanel: false,
        );
      case CalendarView.agenda:
        if (zoomIn) return;
        _setView(
          CalendarView.month,
          focus: monthOf(_selected),
          from: global,
          direction: ZoomDirection.zoomOut,
          openPanel: false,
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
        final r = entry as ReminderEntry;
        final before = r.note;
        if (r.expiry) {
          notes.setExpiry(moved.id, moved.expiresAt);
          undo = () => notes.setExpiry(before.id, before.expiresAt);
        } else {
          notes.setReminder(moved.id, moved.reminderAt);
          undo = () => notes.setReminder(before.id, before.reminderAt);
        }
      case DayLinkMove(:final noteId, :final from, :final to, :final minutes):
        if (calendar == null) return;
        calendar.moveDayLink(from, to, noteId, minutes);
        undo = () => calendar.moveDayLink(to, from, noteId, minutes);
      default:
        return;
    }
    AppHaptics.tick();
    final l10n = context.l10n;
    showUndoSnackBar(
      context,
      message: l10n.calendarMoved(DateFormat.MMMEd().format(day)),
      undoLabel: l10n.undo,
      onUndo: undo,
    );
  }

  Future<void> _showDay(DateTime day, CalendarData data) {
    final wide = MediaQuery.sizeOf(context).width >= _kWideCalendar;
    if (!wide && _view == CalendarView.month) {
      setState(() {
        _selected = startOfDay(day);
        _panelDay = _selected;
      });
      return Future.value();
    }
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
              borderRadius: BorderRadius.circular(AppRadius.s),
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
          CalendarView.week => _weekPage(i, data, now),
          _ => _monthPage(i, data, _panelDay != null && !wide, !wide),
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

    final dayPanelOpen =
        _panelDay != null && !wide && _view == CalendarView.month;
    return Scaffold(
      // Takvimde yazı alanı yok; klavye yalnız üstteki levhalarda açılır.
      // Boyut değişseydi ay ızgarası/sayfalar klavyenin HER KARESİNDE yeniden
      // yerleşirdi (yeni etkinlik kasması, 2026-11-06).
      resizeToAvoidBottomInset: false,
      appBar: HomeInBar(appBar: bar),
      // Alt gün paneli açıkken kendi 2×2 hızlı eylem kartları vardır;
      // FAB onların üstüne binmesin diye gizlenir.
      floatingActionButton: dayPanelOpen
          ? null
          : FloatingActionButton(
              key: const ValueKey('calendar-new-event'),
              tooltip: l10n.calendarNewEvent,
              onPressed: _newEvent,
              child: const Icon(Icons.add),
            ),
      body: _withDayPanel(body, data, wide),
    );
  }

  void _handleGridVerticalEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dy = _gridDragDy;
    _gridDragDy = 0;
    if (_panelDay != null) {
      // Aşağı çekince: önce yarı panelden tam uzun takvime (veya hızlı
      // çekişte doğrudan tam uzun takvime).
      if (v > 180 || dy > 36) {
        unawaited(AppHaptics.tick());
        setState(() {
          if (_panelCompact && v <= 600 && dy <= 96) {
            _panelCompact = false;
          } else {
            _panelDay = null;
            _panelCompact = false;
          }
        });
      } else if (v < -180 || dy < -36) {
        if (!_panelCompact) {
          unawaited(AppHaptics.tick());
          setState(() => _panelCompact = true);
        }
      }
    } else if (v < -180 || dy < -36) {
      // Uzun takvimde yukarı çekince: gün panelini geri aç.
      unawaited(AppHaptics.tick());
      setState(() {
        _panelDay = _selected;
        _panelCompact = false;
      });
    }
  }

  /// Ay görünümünde gün paneli açıkken takvim üstte daralır, panel altta.
  /// Takvimin kabı (ilk çocuk `SizedBox`) iki durumda AYNI: sayfalayıcı
  /// durumunu ve kaydırma konumunu korur; hafta/ajandada sıfır ek widget.
  Widget _withDayPanel(Widget body, CalendarData data, bool wide) {
    final day = _panelDay;
    final open = day != null && !wide && _view == CalendarView.month;
    return LayoutBuilder(
      builder: (context, c) {
        final gridH = open
            ? c.maxHeight * (_panelCompact ? 0.34 : 0.5)
            : c.maxHeight;
        return Column(
          children: [
            SizedBox(height: gridH, child: body),
            if (open)
              Expanded(
                child: _DayPanel(
                  key: const ValueKey('calendar-day-panel'),
                  day: day,
                  today: _today,
                  data: data,
                  compact: _panelCompact,
                  onCompact: (v) => setState(() => _panelCompact = v),
                  onClose: () => setState(() {
                    _panelDay = null;
                    _panelCompact = false;
                  }),
                  onNewEvent: () => unawaited(showEventEditor(context, day: day)),
                  onNewTask: () => unawaited(showTaskEditor(context, due: day)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _agendaView(BuildContext context, CalendarData data, bool wide) {
    final l10n = context.l10n;
    // Ayın ızgarasındaki dolu günler: mini ay sayfası KURULURKEN bir kez
    // (komşu ay çekiş başlayınca kendi ayıyla).
    Set<String> busyOf(DateTime month) {
      final gridStart = gridStartFor(month, _firstDow);
      return data
          .range(
            gridStart,
            DateTime(gridStart.year, gridStart.month, gridStart.day + 42),
          )
          .keys
          .toSet();
    }
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
      busyOf: busyOf,
      busyKey: data,
      now: _today,
      showHeader: wide,
      onSelect: select,
      swipeEnabled: ref.watch(calendarSwipeProvider),
      // Seçim DEĞİŞMEZ (2026-11-08): yalnız görünen ay.
      onMonthChanged: (month) => setState(() => _month = month),
    );
    final isEmpty =
        data.events.isEmpty &&
        data.tasks.isEmpty &&
        data.reminders.isEmpty &&
        data.timedNotes.isEmpty &&
        data.dayNotes.isEmpty;
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
            timedNotes: data.timedNotes,
            dayNotes: data.dayNotes,
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
    return _MonthPanel(
      open: _monthOpen,
      grid: grid,
      onClose: () => setState(() => _monthOpen = false),
      list: list,
    );
  }
}

/// **TELEFONDA MİNİ AY PANELİ** (P62 PA8, plan_tasarim_A §6.2; R2): ajanda
/// listesinin boyu animasyonla DEĞİŞMEZ — eskiden `AnimatedSize` listeyi
/// açılış / kapanış boyunca her karede yeniden diziyordu (S35: 28 kare).
/// Boy TEK ADIMDA, hareket boyamada: açılışta ızgara listenin ALTINDA kurulup
/// ölçülür, liste `Transform` ile ızgara boyu kadar aşağı kayar, bitince üst
/// payı ızgara boyu olur (öteleme 0, aynı piksel); kapanışta üst pay hemen 0,
/// öteleme ızgara boyundan 0'a, bitince ızgara ağaçtan düşer. Listeyi saran
/// zincir iki durumda AYNI (kaydırma konumu korunur).
class _MonthPanel extends StatefulWidget {
  const _MonthPanel({
    required this.open,
    required this.grid,
    required this.onClose,
    required this.list,
  });

  final bool open;
  final Widget grid;
  final VoidCallback onClose;
  final Widget list;

  @override
  State<_MonthPanel> createState() => _MonthPanelState();
}

class _MonthPanelState extends State<_MonthPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shift = AnimationController(vsync: this);
  final _gridKey = GlobalKey();

  /// Izgara ağaçta mı (açık ya da kapanış sürüyor).
  late bool _gridShown = widget.open;

  /// Açılış oturdu: liste üst payı ızgara boyu.
  late bool _settled = widget.open;
  double _gridHeight = 0;

  @override
  void initState() {
    super.initState();
    if (widget.open) _measureThen(() {});
  }

  @override
  void didUpdateWidget(_MonthPanel old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    if (widget.open) {
      _gridShown = true;
      _measureThen(_openSlide);
    } else {
      _closeSlide();
    }
  }

  /// Izgara kurulduktan SONRAKİ karede boyunu ölçer (ExpandReveal kalıbı).
  void _measureThen(VoidCallback next) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gridHeight = _gridKey.currentContext?.size?.height ?? 0;
      if (!widget.open) return;
      next();
      if (_settled) setState(() {});
    });
  }

  void _openSlide() {
    _shift.duration = AppMotion.of(context, AppMotion.short);
    _shift.value = 0;
    unawaited(
      _shift
          .animateTo(1, curve: AppMotion.curveOf(context, AppMotion.enter))
          .whenComplete(() {
            if (!mounted || !widget.open) return;
            setState(() => _settled = true);
            _shift.value = 0;
          }),
    );
  }

  void _closeSlide() {
    final d = AppMotion.exitOf(AppMotion.of(context, AppMotion.short));
    _settled = false; // didUpdateWidget içinden: kurulum zaten gelir
    _shift.value = 1;
    unawaited(
      _shift
          .animateTo(
            0,
            duration: d,
            curve: AppMotion.curveOf(context, AppMotion.exit),
          )
          .whenComplete(() {
            if (mounted && !widget.open) setState(() => _gridShown = false);
          }),
    );
  }

  @override
  void dispose() {
    _shift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      children: [
        if (_gridShown)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              key: _gridKey,
              mainAxisSize: MainAxisSize.min,
              children: [widget.grid, const Divider(height: 1)],
            ),
          )
        else
          const SizedBox.shrink(),
        Positioned.fill(
          top: _settled ? _gridHeight : 0,
          child: AnimatedBuilder(
            animation: _shift,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _shift.value * _gridHeight),
              child: child,
            ),
            // Opak zemin: açılışın ilk karesinde ızgara listenin içinden
            // görünmesin.
            child: ColoredBox(
              color: background,
              child: Column(
                children: [
                  // Açık ay paneli geri tuşuyla önce kapanır (bkz. [BackCloses]).
                  BackCloses(
                    open: widget.open,
                    onClose: widget.onClose,
                    child: const SizedBox.shrink(),
                  ),
                  Expanded(child: widget.list),
                ],
              ),
            ),
          ),
        ),
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
          curve: AppMotion.emphasized,
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

/// "Bu güne not" (F49.1): [createNew] true ise aynı güne birden fazla not
/// eklenebilmesi için her seferinde yeni bir not oluşturur ve güne bağlar
/// (ilk not günün adını, sonrakiler `"<gün> · N"` başlığını alır).
/// [createNew] false ise güne bağlı gün notu varsa onu açar, yoksa kurar.
///
/// SİYAH EKRAN (kullanıcı bulgusu 2026-11-07): not ham `/note/:id` yoluyla
/// push ediliyordu; takvim SplitShell kabuğunun DIŞINDA olduğundan ikinci
/// bir kabuk kuruluyordu (bkz. [notePushPath]). Yol konuma göre seçilir.
Future<void> openDayNote(
  BuildContext context,
  WidgetRef ref,
  DateTime day, {
  bool popFirst = false,
  bool createNew = false,
}) async {
  final notes = ref.read(notesRepositoryProvider);
  final calendar = ref.read(calendarRepositoryProvider);
  if (notes == null || calendar == null) return;
  final key = dayKey(day);
  final baseTitle = dayNoteTitle(day);
  final linked = ref.read(dayLinksStreamProvider).value?[key] ?? const [];
  final all = ref.read(notesStreamProvider).value ?? const <Note>[];
  final activeLinked = [
    for (final n in all)
      if (linked.contains(n.id) && n.deletedAt == null) n,
  ];
  final existing = createNew
      ? null
      : activeLinked.where((n) => n.title.trim() == baseTitle).firstOrNull;
  final title = existing != null
      ? baseTitle
      : activeLinked.isEmpty
      ? baseTitle
      : '$baseTitle · ${activeLinked.length + 1}';
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

/// Takvimin altındaki gün paneli: tutamak (yukarı çek = takvimi daha da
/// daralt, aşağı çek = önce genişlet sonra kapat), gün başlığı + özet rozeti,
/// ✕ ve günün kayıtları + zengin önizlemeli bağlı notları. Geri tuşu önce
/// paneli kapatır ([BackCloses]). `RepaintBoundary` + `SlideTransition` ile
/// açılış GPU katmanında akar, takvim ızgarasını yeniden boyamaz.
class _DayPanel extends StatefulWidget {
  const _DayPanel({
    super.key,
    required this.day,
    required this.today,
    required this.data,
    required this.compact,
    required this.onCompact,
    required this.onClose,
    required this.onNewEvent,
    required this.onNewTask,
  });

  final DateTime day;
  final DateTime today;
  final CalendarData data;
  final bool compact;
  final ValueChanged<bool> onCompact;
  final VoidCallback onClose;
  final VoidCallback onNewEvent;
  final VoidCallback onNewTask;

  @override
  State<_DayPanel> createState() => _DayPanelState();
}

class _DayPanelState extends State<_DayPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.short,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _enter, curve: AppMotion.enter));

  @override
  void initState() {
    super.initState();
    unawaited(_enter.forward());
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _drag(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -150) {
      widget.onCompact(true);
    } else if (v > 150) {
      if (widget.compact) {
        widget.onCompact(false);
      } else {
        widget.onClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final key = dayKey(widget.day);
    final dayEntries =
        widget.data.range(
          widget.day,
          DateTime(widget.day.year, widget.day.month, widget.day.day + 1),
        )[key] ??
        const <AgendaEntry>[];
    final linkedCount = widget.data.dayNotes[key]?.length ?? 0;
    final planCount = dayEntries
        .where((e) => !(e is ReminderEntry && e.isDayLink))
        .length;
    final totalCount = planCount + linkedCount;

    return BackCloses(
      open: true,
      onClose: widget.onClose,
      child: RepaintBoundary(
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragEnd: _drag,
                  onTap: () => widget.onCompact(!widget.compact),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpace.s),
                      Container(
                        width: 36,
                        height: AppSpace.xs,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: AppAlpha.disabled,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.l,
                          AppSpace.s,
                          AppSpace.s,
                          AppSpace.xs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.day == widget.today
                                          ? '${l10n.calendarToday} · ${DateFormat.MMMMEEEEd().format(widget.day)}'
                                          : DateFormat.MMMMEEEEd()
                                                .format(widget.day),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.sheetTitle.copyWith(
                                        color: widget.day == widget.today
                                            ? scheme.primary
                                            : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (totalCount > 0) ...[
                                    const SizedBox(width: AppSpace.s),
                                    DecoratedBox(
                                      key: const ValueKey('day-panel-count'),
                                      decoration: ShapeDecoration(
                                        color: scheme.primaryContainer,
                                        shape: const StadiumBorder(),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpace.s,
                                          vertical: AppSpace.xxs,
                                        ),
                                        child: Text(
                                          '$totalCount',
                                          style: text.badge.copyWith(
                                            color: scheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              key: const ValueKey('day-panel-compact'),
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHigh,
                                foregroundColor: scheme.onSurfaceVariant,
                              ),
                              tooltip: widget.compact
                                  ? l10n.calendarExpandMonth
                                  : l10n.calendarCollapseMonth,
                              icon: Icon(
                                widget.compact
                                    ? Icons.expand_more_rounded
                                    : Icons.expand_less_rounded,
                                size: AppIconSize.m,
                              ),
                              onPressed: () =>
                                  widget.onCompact(!widget.compact),
                            ),
                            IconButton.filledTonal(
                              key: const ValueKey('day-panel-close'),
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHigh,
                                foregroundColor: scheme.onSurfaceVariant,
                              ),
                              tooltip: l10n.calendarDayPanelClose,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: AppIconSize.s,
                              ),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
                ),
                Expanded(
                  child: _DaySheet(
                    day: widget.day,
                    today: widget.today,
                    data: widget.data,
                    embedded: true,
                    onNewEvent: widget.onNewEvent,
                    onNewTask: widget.onNewTask,
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

class _DaySheet extends ConsumerWidget {
  const _DaySheet({
    required this.day,
    required this.today,
    required this.data,
    required this.onNewEvent,
    required this.onNewTask,
    this.embedded = false,
  });

  final DateTime day;
  final DateTime today;
  final CalendarData data;
  final VoidCallback onNewEvent;
  final VoidCallback onNewTask;

  /// Takvimin ALTINDA gömülü panel (ay görünümü, telefon): levha değil,
  /// içerik tek kaydırılabilir liste; boy sınırı yok.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final key = dayKey(day);
    final linked = ref.watch(dayLinksStreamProvider).value?[key] ?? const [];
    final times =
        ref.watch(dayLinkTimesStreamProvider).value?[key] ??
        const <String, int>{};
    // CANLI veri (açılıştaki anlık görüntü değil): levhadan silinen ya da
    // düzenlenen kayıt hemen kaybolsun/güncellensin. Güne bağlı notlar
    // aşağıda zengin önizleme kartlarında ("Bağlı notlar") — burada tekrar yok.
    final source = ref.watch(calendarDataProvider);
    final dayNoteEntries = source.dayNotes[key] ?? const <DayNote>[];
    final linkedNotes = [for (final dn in dayNoteEntries) dn.note];
    final linkedIds = {for (final n in linkedNotes) n.id};
    // O gün yazılan/düzenlenen notlar (F49.3) — yalnız o gün değişenleri seçer.
    final written = ref
        .watch(
          notesStreamProvider.select((async) {
            final all = async.value ?? const <Note>[];
            return _NoteListSlice([
              for (final n in all)
                if (n.deletedAt == null &&
                    n.archivedAt == null &&
                    !linkedIds.contains(n.id) &&
                    n.updatedAt != null &&
                    startOfDay(n.updatedAt!) == day)
                  n,
            ]);
          }),
        )
        .notes;
    final entries = [
      for (final e
          in source.range(
                day,
                DateTime(day.year, day.month, day.day + 1),
              )[key] ??
              const <AgendaEntry>[])
        if (!(e is ReminderEntry && e.isDayLink)) e,
    ];
    final calendar = ref.read(calendarRepositoryProvider);
    final hasAnyContent = entries.isNotEmpty || linkedNotes.isNotEmpty;
    final emptyCard = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.s,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.m,
          ),
          child: Row(
            spacing: AppSpace.s,
            children: [
              Icon(
                Icons.event_available_outlined,
                size: AppIconSize.m,
                color: scheme.onSurfaceVariant,
              ),
              Expanded(
                child: Text(
                  l10n.calendarNothingThisDay,
                  style: text.body.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final tiles = [
      for (final e in entries)
        _withQuickDelete(e, switch (e) {
          EventOccurrence occ => _EventTile(occurrence: occ),
          TaskEntry t => _TaskTile(task: t.task),
          ReminderEntry r => _ReminderTile(entry: r),
          RoutineEntry r => _RoutineTile(entry: r),
        }),
    ];
    final holiday = data.holidays.on(day);
    final holidayChip = holiday == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: HolidayChip(
                holiday: holiday,
                full: true,
                height: 22,
                estimatedLabel: l10n.calendarHolidayEstimated,
              ),
            ),
          );
    final below = <Widget>[
      if (linkedNotes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            AppSpace.s,
            AppSpace.l,
            AppSpace.xs,
          ),
          child: LinkedNotesList(
            noteIds: linked,
            preloadedNotes: linkedNotes,
            times: times,
            onNoteTap: (note, minutes) => unawaited(
              showCalendarNotePreviewSheet(
                context,
                note: note,
                day: day,
                minutes: minutes,
                onUnlink: calendar == null
                    ? null
                    : () => calendar.unlinkNoteFromDay(key, note.id),
              ),
            ),
            onSetTime: calendar == null
                ? null
                : (id, minutes) => calendar.setDayLinkTime(key, id, minutes),
            onUnlink: (id) => calendar?.unlinkNoteFromDay(key, id),
          ),
        ),
      if (written.isNotEmpty)
        ExpansionTile(
          key: const ValueKey('day-written-notes'),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
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
                onTap: () => unawaited(
                  showCalendarNotePreviewSheet(
                    context,
                    note: n,
                    day: day,
                  ),
                ),
              ),
          ],
        ),
      // 2×2 dengeli bento hızlı eylem kartları (yeni etkinlik · yeni görev /
      // bu güne yeni not · mevcut notu bağla). "Bu güne not" her dokunuşta
      // güne YENİ bir not ekler (birden fazla not desteklenir).
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          AppSpace.m,
          AppSpace.l,
          AppSpace.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s,
          children: [
            Row(
              spacing: AppSpace.s,
              children: [
                Expanded(
                  child: _DayActionTile(
                    icon: Icons.event_outlined,
                    label: l10n.calendarNewEvent,
                    bg: scheme.primaryContainer,
                    fg: scheme.onPrimaryContainer,
                    onTap: onNewEvent,
                  ),
                ),
                Expanded(
                  child: _DayActionTile(
                    icon: Icons.add_task_rounded,
                    label: l10n.tasksNewTask,
                    bg: scheme.secondaryContainer,
                    fg: scheme.onSecondaryContainer,
                    onTap: onNewTask,
                  ),
                ),
              ],
            ),
            Row(
              spacing: AppSpace.s,
              children: [
                Expanded(
                  child: _DayActionTile(
                    key: const ValueKey('day-note'),
                    icon: Icons.note_add_outlined,
                    label: l10n.calendarDayNote,
                    bg: scheme.surfaceContainerHigh,
                    fg: scheme.onSurface,
                    iconColor: scheme.primary,
                    onTap: () => unawaited(
                      openDayNote(
                        context,
                        ref,
                        day,
                        popFirst: !embedded,
                        createNew: true,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _DayActionTile(
                    key: const ValueKey('day-link-note'),
                    icon: Icons.link_rounded,
                    label: l10n.calendarLinkExistingNote,
                    bg: scheme.surfaceContainerHigh,
                    fg: scheme.onSurface,
                    iconColor: scheme.primary,
                    onTap: () => unawaited(
                      linkExistingNote(context, ref, dayKey: key),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    if (embedded) {
      return ListView(
        key: ValueKey('day-panel-$key'),
        padding: EdgeInsets.only(
          bottom: AppSpace.l + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          ?holidayChip,
          if (!hasAnyContent)
            emptyCard
          else if (tiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.s,
                AppSpace.l,
                0,
              ),
              child: Column(children: tiles),
            ),
          ...below,
        ],
      );
    }
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
            ?holidayChip,
            if (!hasAnyContent)
              emptyCard
            else if (tiles.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  children: tiles,
                ),
              ),
            ...below,
          ],
        ),
      ),
    );
  }
}

/// Gün panelinin altındaki dengeli bento işlem karosu (48 dp dokunma alanı).
class _DayActionTile extends StatelessWidget {
  const _DayActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.m,
              vertical: AppSpace.s,
            ),
            child: Row(
              spacing: AppSpace.s,
              children: [
                Icon(icon, size: AppIconSize.s, color: iconColor ?? fg),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.label.copyWith(
                      color: fg,
                      fontWeight: AppWeight.strong,
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
        borderRadius: BorderRadius.circular(AppRadius.m),
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
          Icon(
            entry.isDayLink
                ? Icons.sticky_note_2_outlined
                : entry.expiry
                ? AppIcons.archive
                : Icons.alarm,
            size: 18,
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
        curve: AppMotion.emphasized,
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
                      onPressed: () => unawaited(
                        openDayNote(context, ref, _day, createNew: true),
                      ),
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
    return GestureDetector(
      key: const ValueKey('calendar-open-day-panel'),
      onTap: onOpen,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -120) onOpen();
      },
      child: Material(
        color: scheme.surfaceContainerHigh.withValues(alpha: AppAlpha.strong),
        shape: StadiumBorder(
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
          ),
        ),
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
                color: scheme.onSurfaceVariant,
              ),
              Text(
                DateFormat.MMMd().format(selected),
                style: AppText.of(theme).badge.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
