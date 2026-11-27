part of 'calendar_screen.dart';

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
/// **TAKVİMDEN ÇIKIŞ GARANTİSİ** (kullanıcı bulgusu 2026-11-22: "artıya
/// basıp geri dendiğinde takvim ana ekranından geliyor, oradan geri
/// dendiğinde dashboard'a dönmüyor"). Açık panel yoksa ([BackCloses]) geri
/// ekranı AÇIKÇA kapatır: yığında alt sayfa varsa pop, yoksa (takvim
/// yığının dibinde kaldıysa) ana ekran. Ekranın `build`inin dışında (rota
/// sarmalayıcısı) — ajandada her kare kurulan ağaca widget eklemez (S34).
class CalendarExitScope extends ConsumerWidget {
  const CalendarExitScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop || BackCloses.handling(context)) return;
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        goHome(ref, router);
      }
    },
    child: child,
  );
}


/// Takvim kaydını açar (etkinlik/görev düzenleyici, rutin, not).
void openCalendarEntry(BuildContext context, AgendaEntry e) {
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

  /// Hafta / gün ızgarasında sürükle-bırak ile gün + saate taşıma (P92).
void moveCalendarEntryToTime(
  BuildContext context,
  WidgetRef ref,
  AgendaEntry entry,
  DateTime target,
) {
    final moved = movedToDateTime(entry, target);
    if (moved == null) return;
    applyCalendarMove(
      context,
      ref,
      entry,
      moved,
      label: '${DateFormat.MMMEd().format(target)} ${DateFormat.Hm().format(target)}',
    );
  }

void applyCalendarMove(
    BuildContext context,
    WidgetRef ref,
    AgendaEntry entry,
    Object moved, {
    required String label,
  }) {
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
        final r = entry as ReminderEntry;
        final beforeMinutes = r.linkTimed ? r.at.hour * 60 + r.at.minute : null;
        calendar.moveDayLink(from, to, noteId, minutes);
        undo = () => calendar.moveDayLink(to, from, noteId, beforeMinutes);
      default:
        return;
    }
    unawaited(AppHaptics.tick());
    final l10n = context.l10n;
    showUndoSnackBar(
      context,
      message: l10n.calendarMoved(label),
      undoLabel: l10n.undo,
      onUndo: undo,
    );
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

/// "Bu güne not" (F49.1): her dokunuşta güne YENİ bir not bağlanır.
///
/// BAŞLIK BOŞ (kullanıcı isteği 2026-11-22: "bu güne not dendiğinde başlık
/// oto atılmasın; not boş olsa bile yanlışlıkla açılsa bile kaydediliyor"):
/// eskiden başlık günün adıydı ("22 Kasım Pazar") → not hiç boş sayılmıyor,
/// yanlışlıkla açılıp kapanan not kalıyordu. Artık başlıksız açılır; boş
/// kalırsa editör çıkışta siler (bağ, silinmiş notu göstermez). Gün takvimde
/// bağın kendisinden görünür. [minutes] verilirse not o güne SAATLİ bağlanır
/// (gün sayfasında saate dokununca).
///
/// SİYAH EKRAN (kullanıcı bulgusu 2026-11-07): not ham `/note/:id` yoluyla
/// push ediliyordu; takvim SplitShell kabuğunun DIŞINDA olduğundan ikinci
/// bir kabuk kuruluyordu (bkz. [notePushPath]). Yol konuma göre seçilir.
Future<void> openDayNote(
  BuildContext context,
  WidgetRef ref,
  DateTime day, {
  bool popFirst = false,
  int? minutes,
}) async {
  final notes = ref.read(notesRepositoryProvider);
  final calendar = ref.read(calendarRepositoryProvider);
  if (notes == null || calendar == null) return;
  final key = dayKey(day);
  final router = GoRouter.of(context);
  if (popFirst) Navigator.pop(context);
  final id = await notes.createNote(NoteType.text);
  calendar.linkNoteToDay(key, id);
  if (minutes != null) calendar.setDayLinkTime(key, id, minutes);
  unawaited(router.pushNote(noteRoutePath(id)));
}

/// Takvimdeki "+" düğmesi: ayardaki eyleme göre (varsayılan NOT) ekler
/// (kullanıcı isteği 2026-11-22). Not için önce küçük bir levhada tarih
/// gösterilir — varsayılan [day] (seçili gün; seçim yoksa bugün), dokununca
/// değiştirilebilir — sonra not o güne bağlı açılır.
Future<void> calendarAdd(BuildContext context, WidgetRef ref, DateTime day) {
  switch (ref.read(calendarAddActionProvider)) {
    case CalendarAddAction.event:
      return showEventEditor(context, day: day);
    case CalendarAddAction.task:
      return showTaskEditor(context, due: day);
    case CalendarAddAction.note:
      return showAppSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _NewDayNoteSheet(day: startOfDay(day)),
      );
  }
}

/// "+ → Not" levhası: tarih (değiştirilebilir) + "Notu yaz".
class _NewDayNoteSheet extends ConsumerStatefulWidget {
  const _NewDayNoteSheet({required this.day});

  final DateTime day;

  @override
  ConsumerState<_NewDayNoteSheet> createState() => _NewDayNoteSheetState();
}

class _NewDayNoteSheetState extends ConsumerState<_NewDayNoteSheet> {
  late DateTime _day = widget.day;

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _day = startOfDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = AppText.of(theme);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.m,
          children: [
            Text(l10n.calendarNewDayNoteTitle, style: text.sheetTitle),
            OutlinedButton.icon(
              key: const ValueKey('new-day-note-date'),
              onPressed: _pick,
              icon: const Icon(Icons.event_outlined, size: AppIconSize.s),
              label: Text(DateFormat.yMMMMEEEEd().format(_day)),
            ),
            FilledButton.icon(
              key: const ValueKey('new-day-note-open'),
              onPressed: () =>
                  unawaited(openDayNote(context, ref, _day, popFirst: true)),
              icon: const Icon(Icons.edit_note, size: AppIconSize.s),
              label: Text(l10n.calendarNewDayNoteOpen),
            ),
          ],
        ),
      ),
    );
  }
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
    required this.onFullPage,
    required this.onNewEvent,
    required this.onNewTask,
    this.onOpenTimeline,
  });

  final DateTime day;
  final DateTime today;
  final CalendarData data;

  /// Tam sayfa takvime geç (paneli kapatır) — tek yol bu düğme.
  final VoidCallback onFullPage;
  final VoidCallback onNewEvent;
  final VoidCallback onNewTask;
  final VoidCallback? onOpenTimeline;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
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

    return RepaintBoundary(
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: tokens.card,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              side: BorderSide(color: tokens.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                    children: [
                      const SizedBox(height: AppSpace.s),
                      Container(
                        width: 38,
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
                            if (widget.onOpenTimeline != null)
                              IconButton.filledTonal(
                                key: const ValueKey('day-panel-open-timeline'),
                                style: IconButton.styleFrom(
                                  backgroundColor: scheme.surfaceContainerHigh,
                                  foregroundColor: scheme.primary,
                                ),
                                tooltip: l10n.calendarViewWeek,
                                icon: const Icon(
                                  Icons.view_day_outlined,
                                  size: AppIconSize.s,
                                ),
                                onPressed: widget.onOpenTimeline,
                              ),
                            IconButton.filledTonal(
                              key: const ValueKey('day-panel-close'),
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHigh,
                                foregroundColor: scheme.onSurfaceVariant,
                              ),
                              tooltip: l10n.calendarFullPage,
                              icon: const Icon(
                                Icons.fullscreen_rounded,
                                size: AppIconSize.s,
                              ),
                              onPressed: widget.onFullPage,
                            ),
                          ],
                        ),
                      ),
                    ],
                ),
                Divider(height: 1, color: tokens.hairline),
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
                onDelete: () => deleteNoteFromCalendar(context, note),
              ),
            ),
            onSetTime: calendar == null
                ? null
                : (id, minutes) => calendar.setDayLinkTime(key, id, minutes),
            onUnlink: (id) => calendar?.unlinkNoteFromDay(key, id),
            onDelete: (note) => deleteNoteFromCalendar(context, note),
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
                    onDelete: () => deleteNoteFromCalendar(context, n),
                  ),
                ),
              ),
          ],
        ),
      // TEK SATIR hızlı eylemler (kullanıcı isteği 2026-11-22: "alt alandaki
      // butonlar çok yer kaplıyor, 2 satır kaplamasına gerek yok"): eski 2×2
      // bento (~104 dp) yerine simge üstte, kısa etiket altta dört karo
      // (~56 dp). Tam ad ipucu/erişilebilirlik etiketinde. "Not" her
      // dokunuşta güne YENİ bir not ekler (birden fazla not desteklenir).
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          AppSpace.m,
          AppSpace.l,
          AppSpace.m,
        ),
        child: Row(
          spacing: AppSpace.s,
          children: [
            Expanded(
              child: _DayActionTile(
                key: const ValueKey('day-new-event'),
                icon: Icons.event_outlined,
                label: l10n.calendarAddEvent,
                tooltip: l10n.calendarNewEvent,
                bg: scheme.primaryContainer,
                fg: scheme.onPrimaryContainer,
                onTap: onNewEvent,
              ),
            ),
            Expanded(
              child: _DayActionTile(
                key: const ValueKey('day-new-task'),
                icon: Icons.add_task_rounded,
                label: l10n.calendarAddTask,
                tooltip: l10n.tasksNewTask,
                bg: scheme.secondaryContainer,
                fg: scheme.onSecondaryContainer,
                onTap: onNewTask,
              ),
            ),
            Expanded(
              child: _DayActionTile(
                key: const ValueKey('day-note'),
                icon: Icons.note_add_outlined,
                label: l10n.calendarAddNote,
                tooltip: l10n.calendarDayNote,
                bg: scheme.surfaceContainerHigh,
                fg: scheme.onSurface,
                iconColor: scheme.primary,
                onTap: () => unawaited(
                  openDayNote(context, ref, day, popFirst: !embedded),
                ),
              ),
            ),
            Expanded(
              child: _DayActionTile(
                key: const ValueKey('day-link-note'),
                icon: Icons.link_rounded,
                label: l10n.relatedNotesLink,
                tooltip: l10n.calendarLinkExistingNote,
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
    required this.tooltip,
    required this.bg,
    required this.fg,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final Color bg;
  final Color fg;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.m),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs,
                vertical: AppSpace.s,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.xs,
                children: [
                  Icon(icon, size: AppIconSize.s, color: iconColor ?? fg),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.meta.copyWith(
                      color: fg,
                      fontWeight: AppWeight.strong,
                    ),
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

