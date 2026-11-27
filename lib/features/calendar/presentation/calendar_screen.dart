import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_commands.dart' show goHome;
import '../../../app/app_frame.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/back_closes.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/sentence_select.dart' show lastPointerIsMouse;
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/app_background_layers.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../settings/presentation/appearance_studio_sheet.dart';
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
import 'month_grid.dart';
import 'pinch_zoom.dart';
import 'task_editor.dart';
import 'week_board.dart';
import '../../../core/haptics.dart';

part 'calendar_panels.dart';
part 'calendar_agenda_day.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.now,
    this.initialDay,
    this.initialView,
  });

  /// Açılınca seçili gün (`/calendar?day=YYYY-MM-DD`, notun bağ hapından).
  final DateTime? initialDay;

  /// Açılış görünümü (`&view=week`: ana ekran şeridinde güne çift dokunuş);
  /// verilmezse son kullanılan.
  final String? initialView;

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
  late CalendarView _view =
      CalendarView.values
          .where((v) => v.name == widget.initialView)
          .firstOrNull ??
      _storedView();

  /// **GÜN PANELİ** (kullanıcı isteği 2026-11-21): ay görünümünde varsayılan
  /// olarak seçili günün paneli altta açıktır; takvimi ya da tutamağı aşağı
  /// çekince panel kapanıp uzun ay görünümüne geçer. null = uzun ay görünümü.
  late DateTime? _panelDay = _selected;

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
  bool _zoomFromPinch = false;
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

  /// Ekran açıkken Google Takvim 15 dk'da bir tazelenir (K8). Arka planda durur.
  Timer? _googleTimer;
  AppLifecycleListener? _googleLife;
  DateTime? _lastGoogleSyncAt;

  void _startGoogleTimer() {
    _googleTimer?.cancel();
    _googleTimer = Timer.periodic(
      GoogleCalendarController.refreshEvery,
      (_) => _refreshGoogle(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePinchHint();
      _refreshGoogle();
    });
    _startGoogleTimer();
    _googleLife = AppLifecycleListener(
      onHide: () {
        _googleTimer?.cancel();
        _googleTimer = null;
      },
      onPause: () {
        _googleTimer?.cancel();
        _googleTimer = null;
      },
      onShow: _onGoogleResume,
      onResume: _onGoogleResume,
    );
  }

  void _onGoogleResume() {
    if (!mounted) return;
    if (_googleTimer == null) _startGoogleTimer();
    final last = _lastGoogleSyncAt;
    if (last == null ||
        DateTime.now().difference(last) >=
            GoogleCalendarController.refreshEvery) {
      _refreshGoogle();
    }
  }

  void _refreshGoogle() {
    if (!mounted) return;
    _lastGoogleSyncAt = DateTime.now();
    unawaited(ref.read(googleCalendarProvider.notifier).refresh());
    // Görevler ajandada da görünür (F50.4).
    unawaited(ref.read(googleTasksProvider.notifier).sync());
  }

  void _maybePinchHint() {
    if (!mounted ||
        _view == CalendarView.agenda ||
        kIsWeb ||
        lastPointerIsMouse()) {
      return;
    }
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
    _googleLife?.dispose();
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
        onDelete: () => deleteNoteFromCalendar(context, note),
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
      onDayDoubleTap: _openWeekOf,
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
                        onOpen: () => setState(() => _panelDay = _selected),
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

  Widget _weekPage(int i, CalendarData data) {
    final firstDow = _firstDow;
    final hit = _weekPages[i];
    if (hit != null &&
        identical(hit.$1, data) &&
        hit.$2 == _today &&
        hit.$3 == firstDow &&
        hit.$4 == _selected) {
      return hit.$5;
    }
    final weekStart = weekAtIndex(i, firstDow);
    // HAFTA PANOSU (kullanıcı isteği 2026-11-21): saat çizelgesi yerine
    // büyük karolar + not önizlemeleri; saat çizelgesi gün sayfasında.
    final Widget page = WeekBoardPage(
      weekStart: weekStart,
      data: data,
      today: _today,
      selected: _selected,
      targets: _targets,
      onDayTap: (d) => unawaited(_showDay(d, data)),
      // Karo başlığı: o günün saat çizelgesi (eskiden haftada üstteki
      // güne dokunuş, kullanıcı isteği 2026-11-07).
      onDayOpen: _openDayPage,
      onDayLongPress: (d) {
        setState(() => _selected = d);
        unawaited(showEventEditor(context, day: d));
      },
      onEntryTap: _openEntry,
      onNoteTap: _openNotePreview,
    );
    // Yalnız canlı sayfalar (görünen + komşu) tutulur.
    if (_weekPages.length > 6) _weekPages.clear();
    _weekPages[i] = (data, _today, firstDow, _selected, page);
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
  }) {
    if (view == _view && focus == null) return;
    unawaited(AppHaptics.tick());
    setState(() {
      // Ay her yoldan (geri, kıstırma, yıl) PANELLİ açılır — tam sayfa yalnız
      // düğmeyle (2026-11-22). Seçili gün görünecek ayda değilse panel o
      // ayın gününe geçer (bu ay → bugün, başka ay → ayın 1'i).
      if (view == CalendarView.month) {
        final m = focus ?? _focus;
        if (_selected.year != m.year || _selected.month != m.month) {
          _selected = m.year == _today.year && m.month == _today.month
              ? _today
              : DateTime(m.year, m.month);
        }
        _panelDay = _selected;
      } else {
        _panelDay = null;
      }
      _lastZoom = direction;
      _zoomFromPinch = from != null;
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
          // İÇİNDE BULUNULAN AY açıksa yakınlaşma BU HAFTAYA gider
          // (kullanıcı isteği 2026-11-22); başka ayda parmakların altındaki
          // hafta (yoksa seçili gün / ayın başı).
          final thisMonth =
              _focus.year == _today.year && _focus.month == _today.month;
          final week = thisMonth
              ? weekStartOf(_today, _firstDow)
              : _targets.at(global) ??
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
      // Açık gün paneli de bugüne geçer (kullanıcı bulgusu 2026-11-22:
      // "Bugün'e basınca alttaki alan hâlâ 20 Kasım gösteriyor").
      if (_panelDay != null) _panelDay = _today;
    });
    _pagerKey.currentState?.animateToPage(_pageOf(_view, _today));
  }

  void _step(int delta) => _pagerKey.currentState?.step(delta);

  Future<void> _newEvent() => showEventEditor(context, day: _addDay());

  /// "+" düğmesi (ayardaki eylem; varsayılan not).
  Future<void> _add() => calendarAdd(context, ref, _addDay());

  /// Yeni kaydın günü: seçili gün (görünen ayda değilse ayın 1'i / bugün).
  DateTime _addDay() =>
      _view != CalendarView.month ||
          (_selected.year == _focus.year && _selected.month == _focus.month)
      ? _selected
      : (_focus.year == _today.year && _focus.month == _today.month
            ? _today
            : DateTime(_focus.year, _focus.month));

  void _openEntry(AgendaEntry e) => openCalendarEntry(context, e);

  /// Sürükle-bırak ile güne taşıma (F47.5); "Geri al" eski hâli yazar.
  void _moveEntry(AgendaEntry entry, DateTime day) {
    final moved = movedToDay(entry, day);
    if (moved == null) return;
    applyCalendarMove(
      context,
      ref,
      entry,
      moved,
      label: DateFormat.MMMEd().format(day),
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

  /// Ay hücresine çift dokunuş (kullanıcı isteği 2026-11-21; önceden gün
  /// sayfası): o günün HAFTASI büyük karolu hafta panosunda açılır.
  void _openWeekOf(DateTime day) {
    _selected = startOfDay(day);
    _setView(CalendarView.week, focus: weekStartOf(_selected, _firstDow));
  }

  /// Gün sayfası — tek günlük saat çizelgesi, ileri/geri gün.
  ///
  /// YÖNLENDİRİCİ ROTASI (kullanıcı bulgusu 2026-11-22: "artıya basıp geri
  /// dendiğinde takvim ana ekranından geliyor, oradan geri dendiğinde
  /// dashboard'a dönmüyor"): gün sayfası `Navigator.push` ile SAYFASIZ
  /// açılıyordu; üstüne go_router ile not push edilince yönlendirici sayfa
  /// listesini yeniden kurup sayfasız rotayı düşürüyor, geri yığını
  /// karışıyordu. Artık `/calendar-day?d=` yolu (bkz. router).
  void _openDayPage(DateTime day) {
    setState(() => _selected = startOfDay(day));
    unawaited(context.push('/calendar-day?d=${dayKey(startOfDay(day))}'));
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
            Icon(icon, size: AppIconSize.m),
            const SizedBox(width: 12),
            Flexible(child: Text(text)),
          ],
        ),
      );

  /// GÖRÜNÜM DÜĞMELERİ (kullanıcı isteği 2026-11-21: "ay hafta yıl seçimi
  /// direkt açık olsun, basılarak seçilsin butonlarla"): menü yerine başlığın
  /// altında hep görünen bölmeli düğme. AYNI örnek döner (görünüm/dil
  /// değişmedikçe): ajandada mini ay kaydırılırken ekran her karede kuruluyor,
  /// bölmeli düğme her seferinde ~90 widget ekliyordu (perf S34).
  ///
  /// YENİ TASARIM (kullanıcı isteği 2026-11-22: "ay, yıl, hafta, ajanda yazan
  /// yer çok kaba duruyor"; "bugüne git bulması çok zor, bugünde olmadığımı da
  /// anlamıyorum"): çerçeveli `SegmentedButton` yerine yumuşak kapsül + kayan
  /// seçim hapı; yanında hep görünen BUGÜN hapı. Görünen dönem bugünü
  /// içermiyorsa hap dolgulu vurgu rengine döner ve bugünün yönünü ok ile
  /// gösterir (üst çubuktaki küçük simge kalktı, ay başlığına yer kaldı).
  (CalendarView, AppLocalizations, int, PreferredSizeWidget)? _viewBarCache;
  (CalendarView, AppLocalizations, Widget)? _switcherCache;

  /// Görünen dönemin bugüne göre yönü: 0 = bugünü içeriyor, 1 = gelecekte
  /// (bugün geride), -1 = geçmişte (bugün ileride).
  int _awayFromToday() {
    int cmp(DateTime a, DateTime b) => a.compareTo(b).sign;
    return switch (_view) {
      CalendarView.year => (_focus.year - _today.year).sign,
      CalendarView.month => cmp(monthOf(_focus), monthOf(_today)),
      CalendarView.week => cmp(
        weekStartOf(_focus, _firstDow),
        weekStartOf(_today, _firstDow),
      ),
      CalendarView.agenda => cmp(_selected, _today),
    };
  }

  PreferredSizeWidget _viewBar(AppLocalizations l10n) {
    final away = _awayFromToday();
    final hit = _viewBarCache;
    if (hit != null &&
        hit.$1 == _view &&
        identical(hit.$2, l10n) &&
        hit.$3 == away) {
      return hit.$4;
    }
    // Seçici yalnız görünüm/dil değişince yeniden kurulur: hafta kaydırırken
    // bugüne göre yön değişse de AYNI örnek döner (perf S22/S34).
    final sw = _switcherCache;
    final switcher = sw != null && sw.$1 == _view && identical(sw.$2, l10n)
        ? sw.$3
        : _ViewSwitcher(
            key: const ValueKey('calendar-view-menu'),
            view: _view,
            labels: {
              for (final v in CalendarView.values) v: _viewLabel(l10n, v),
            },
            onPick: _pickView,
          );
    _switcherCache = (_view, l10n, switcher);
    final bar = PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.s,
        ),
        child: Row(
          spacing: AppSpace.s,
          children: [
            Expanded(child: switcher),
            _TodayPill(
              key: const ValueKey('calendar-today'),
              label: l10n.calendarToday,
              day: _today.day,
              away: away,
              onTap: _goToday,
            ),
          ],
        ),
      ),
    );
    _viewBarCache = (_view, l10n, away, bar);
    return bar;
  }

  /// Görünüm düğmesinden seçim: yön, sıraya göre yakınlaşma/uzaklaşma.
  void _pickView(CalendarView v) {
    if (v == _view) return;
    final dir = v.index < _view.index
        ? ZoomDirection.zoomOut
        : ZoomDirection.zoomIn;
    _setView(
      v,
      focus: switch (v) {
        CalendarView.week => weekStartOf(
          _selected.month == _focus.month || _view == CalendarView.agenda
              ? _selected
              : _focus,
          _firstDow,
        ),
        _ => _view == CalendarView.agenda ? _selected : _focus,
      },
      direction: dir,
    );
  }

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

    final backgroundLayers = buildAppBackgroundLayers(context, ref);
    final hasBackground = backgroundLayers.isNotEmpty;

    // AY BELLİ OLSUN (kullanıcı isteği 2026-11-22: "başlık biraz daha
    // büyüsün"): üst çubuğun varsayılanı yerine ekran başlığı rolü, bir boy
    // büyük.
    final titleStyle = AppText.of(Theme.of(context)).screenTitle;
    final titleText = Text(
      _title(l10n),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: titleStyle.copyWith(
        fontSize: (titleStyle.fontSize ?? 20) + 2,
        height: 1.2,
      ),
    );
    final bar = AppBar(
      backgroundColor: hasBackground ? Colors.transparent : null,
      systemOverlayStyle: hasBackground ? statusBarOverZemin(context) : null,
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
      bottom: _viewBar(l10n),
      actions: [
        // ANA MENÜ (kullanıcı isteği 2026-11-22): takvimden tek dokunuşla
        // ana ekrana (geniş ekranda raydaki 🏠 zaten var).
        if (!wide)
          IconButton(
            key: const ValueKey('calendar-home'),
            tooltip: l10n.goHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goHome(ref, GoRouter.of(context)),
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
            'appearance' => showAppearanceStudio(
              context,
              contextMode: AppearanceContext.calendar,
            ),
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
            _menuItem(
              'appearance',
              AppIcons.appearance,
              l10n.settingsAppearance,
            ),
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
          CalendarView.week => _weekPage(i, data),
          _ => _monthPage(i, data, _panelDay != null && !wide, !wide),
        },
      ),
    };

    final duration = AppMotion.of(
      context,
      _zoomFromPinch ? AppMotion.medium : AppMotion.short,
    );
    final zoomIn = _lastZoom == ZoomDirection.zoomIn;
    final body = PinchZoomDetector(
      // Yıl ve ay görünümünde dikey kaydırma yok: düz tekerlek geçiş yapar.
      // Hafta/gün görünümü tekerlekle kayar; orada Ctrl + tekerlek geçer.
      wheelZoom: _view == CalendarView.year || _view == CalendarView.month,
      onZoom: _onZoom,
      onPreview: _onPreview,
      onPinchingChanged: (v) => setState(() => _pinching = v),
      child: ClipRect(
        key: _bodyKey,
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
          switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
          layoutBuilder: (cur, prev) =>
              Stack(fit: StackFit.expand, children: [...prev, ?cur]),
          transitionBuilder: (child, animation) {
            final incoming =
                child.key == ValueKey('view-${_view.name}-$_epoch');
            // Kıstırmayla / aya dokunarak geçişte odaktan derin yakınlaşma;
            // üst çubuktaki düğmeyle geçişte sakin, hafif ölçek + solma.
            final from = _zoomFromPinch
                ? (incoming ? (zoomIn ? 0.55 : 1.6) : (zoomIn ? 1.6 : 0.55))
                : (incoming ? (zoomIn ? 0.96 : 1.03) : (zoomIn ? 1.03 : 0.96));
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                alignment: _zoomFromPinch ? _origin : Alignment.center,
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
    final scaffold = Scaffold(
      backgroundColor: hasBackground ? Colors.transparent : null,
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
              tooltip: l10n.calendarAddActionTitle,
              onPressed: _add,
              child: const Icon(Icons.add),
            ),
      // GERİ SIRAYLA (kullanıcı isteği 2026-11-21): açık gün paneli kendi
      // [BackCloses]'uyla kapanır (seçimi de bırakır); panel kapalıyken
      // seçili gün bırakılır; hafta/yıl görünümü aya döner; ancak bunların
      // hiçbiri yokken ekran kapanır.
      // Ajandada geri adımı yok: sarmalayıcı hiç kurulmaz (perf S34 —
      // mini ay kaydırılırken ekran her karede yeniden kuruluyor).
      body: _view == CalendarView.agenda
          ? _withDayPanel(body, data, wide)
          : BackCloses(
              open: _backStep(wide) != null,
              onClose: () => _backStep(wide)?.call(),
              child: _withDayPanel(body, data, wide),
            ),
    );
    if (!hasBackground) return scaffold;
    return Stack(children: [...backgroundLayers, scaffold]);
  }

  /// Geri tuşunun bu ekrandaki sıradaki adımı; null = ekran kapanır.
  VoidCallback? _backStep(bool wide) {
    switch (_view) {
      case CalendarView.week:
        return () {
          final mid = DateTime(_focus.year, _focus.month, _focus.day + 3);
          _setView(
            CalendarView.month,
            focus: monthOf(mid),
            direction: ZoomDirection.zoomOut,
          );
        };
      case CalendarView.year:
        return () => _setView(
          CalendarView.month,
          focus: _focus.year == _today.year
              ? monthOf(_today)
              : DateTime(_focus.year),
        );
      case CalendarView.month:
        // TAM SAYFA GERİYLE GELMEZ (kullanıcı isteği 2026-11-22: "tam sayfa
        // takvim görünümü geri yapılınca gelmesin, sadece tam sayfa butonu
        // ile ulaşılsın"): açık panel geriyle KAPANMAZ; başka gün seçiliyse
        // geri önce bugüne döner, sonra ekran kapanır. Tam sayfadayken geri
        // paneli (bugünle) geri açar.
        if (wide) return null;
        if (_panelDay == null) {
          return () => setState(() {
            _selected = _today;
            _panelDay = _today;
          });
        }
        if (_selected == _today) return null;
        return () => setState(() {
          _selected = _today;
          _panelDay = _today;
        });
      case CalendarView.agenda:
        return null;
    }
  }

  void _handleGridVerticalEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dy = _gridDragDy;
    _gridDragDy = 0;
    // DARALMA YOK (kullanıcı isteği 2026-11-21: "takvim ekstradan yukarı
    // daralmasına gerek yok"): panel açıkken aşağı çekiş uzun takvime geçer,
    // yukarı çekiş bir şey yapmaz; uzun takvimde yukarı çekiş paneli açar.
    // Panel AÇIKKEN aşağı çekiş artık tam sayfaya geçmez (2026-11-22: tam
    // sayfa yalnız düğmeyle).
    if (_panelDay == null && (v < -180 || dy < -36)) {
      unawaited(AppHaptics.tick());
      setState(() => _panelDay = _selected);
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
        // SİSTEM ÇUBUĞU (kullanıcı bulgusu 2026-11-21: "ekrana sığmıyor,
        // alt telefon tuşlarıyla çakışıyor"): kenardan kenara ekranda panel
        // kapalıyken takvim gezinme çubuğunun ÜSTÜNDE biter. Açık panel
        // zemini alta kadar uzanır, kendi içeriği payı alır.
        final inset = open ? 0.0 : MediaQuery.paddingOf(context).bottom;
        // UZUN EKRAN (kullanıcı 2026-11-24: "alt alanda çok ölü boşluk"):
        // panel ekranın yarısını ancak içeriğin doğal boyuna (başlık + boş
        // kart + notlar + eylem satırı ≈ 280 dp) dek alır; artan yükseklik
        // ay ızgarasına gider (günler uzar, etkinlik adları sığar). Fazla
        // içerik panelde kayar; tam görünüm düğmesi yine var.
        final panelH = math.min(
          c.maxHeight * 0.5,
          280 + MediaQuery.paddingOf(context).bottom,
        );
        final gridH = open
            ? c.maxHeight - panelH
            : math.max(0.0, c.maxHeight - inset);
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
                  // Panel kapanınca gün seçimi de bırakılır (kullanıcı
                  // isteği 2026-11-21: geri önce seçimi bırakmalı, sonra
                  // ana menü — kapalı panelin "^ 29 Eki" hapı kalmasın).
                  onFullPage: () => setState(() => _panelDay = null),
                  onOpenTimeline: () => _openDayPage(day),
                  onNewEvent: () =>
                      unawaited(showEventEditor(context, day: day)),
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
