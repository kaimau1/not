import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/presentation/reminder_repeat_ui.dart';
import '../../notes/presentation/reminders_screen.dart'
    show maybeShowAutoStartHint;
import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import '../domain/recurrence.dart';
import '../data/google_calendar_sync.dart';
import 'google_calendar_ui.dart';

/// Hatırlatma seçenekleri (dakika). Google Takvim'in olağan değerleri.
const kTimedReminderChoices = [0, 10, 30, 60, 1440];

/// Tüm gün etkinliğinde: o gün 09:00 (0) ya da bir gün önce 09:00 (1440).
const kAllDayReminderChoices = [0, 1440];

/// Hatırlatmanın okunur adı.
String eventReminderLabel(AppLocalizations l10n, int? minutes, bool allDay) {
  if (minutes == null) return l10n.eventReminderNone;
  if (allDay) {
    return minutes == 0
        ? l10n.eventReminderAllDayMorning
        : l10n.eventReminderDays(minutes ~/ 1440);
  }
  if (minutes == 0) return l10n.eventReminderAtStart;
  if (minutes % 1440 == 0) return l10n.eventReminderDays(minutes ~/ 1440);
  if (minutes % 60 == 0) return l10n.eventReminderHours(minutes ~/ 60);
  return l10n.eventReminderMinutes(minutes);
}

/// Yeni etkinliğin varsayılan başlangıcı: bugünse bir sonraki tam saat,
/// başka günse 09:00.
DateTime defaultEventStart(DateTime day, DateTime now) {
  if (startOfDay(day) == startOfDay(now)) {
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }
  return DateTime(day.year, day.month, day.day, 9);
}

/// Etkinlik oluştur/düzenle levhası (F47.4). [existing] null ise yeni.
/// [occurrenceStart]: tekrarlıda dokunulan oluş ("yalnız bunu sil" için).
Future<void> showEventEditor(
  BuildContext context, {
  CalendarEvent? existing,
  DateTime? day,
  DateTime? start,
  DateTime? occurrenceStart,
  String? linkNoteId,
  String? initialTitle,
  String? initialDescription,
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => EventEditorSheet(
    existing: existing,
    day: day ?? start ?? DateTime.now(),
    start: start,
    occurrenceStart: occurrenceStart,
    linkNoteId: linkNoteId,
    initialTitle: initialTitle,
    initialDescription: initialDescription,
  ),
);

class EventEditorSheet extends ConsumerStatefulWidget {
  const EventEditorSheet({
    super.key,
    this.existing,
    required this.day,
    this.start,
    this.occurrenceStart,
    this.linkNoteId,
    this.initialTitle,
    this.initialDescription,
  });

  /// Fotoğraftan/metinden etkinlik taslağının açıklaması (F52.3).
  final String? initialDescription;

  /// Nottan açılan YENİ etkinlik (F49.1 "Takvime bağla → yeni etkinlik"):
  /// kaydedilince bu not etkinliğe bağlanır.
  final String? linkNoteId;
  final String? initialTitle;

  final CalendarEvent? existing;
  final DateTime day;

  /// Hafta ızgarasında dokunulan saat (yeni etkinliğin tam başı).
  final DateTime? start;
  final DateTime? occurrenceStart;

  @override
  ConsumerState<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<EventEditorSheet> {
  final _titleFocus = FocusNode();

  late final _title = TextEditingController(
    text: widget.existing?.title ?? widget.initialTitle,
  );
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _description = TextEditingController(
    text: widget.existing?.description ?? widget.initialDescription,
  );
  late bool _allDay = widget.existing?.allDay ?? false;
  late DateTime _start;
  late DateTime _end;
  late Recurrence _repeat = Recurrence.parse(widget.existing?.repeat);
  late int? _reminder;

  /// Yeni etkinlik nereye kaydedilsin (Faz 51). Varsayılan HER ZAMAN
  /// bütün cihazlarda görünen depo (Firestore). P48 (2026-11-12): Google
  /// bağlantısı cihaza özgü — K2'nin "bağlıysa Google" varsayılanıyla
  /// telefonda eklenen etkinlik, Google'ı bağlamamış tablet/webde hiç
  /// görünmüyordu. Google'a yazmak elle seçilir. (K2 sapması: sabah bakılacak.)
  late bool _toGoogle = widget.existing?.fromGoogle ?? false;

  @override
  void initState() {
    super.initState();
    // Klavye levha açıldıktan SONRA (bkz. [focusAfterRouteOpens]).
    if (widget.existing == null) focusAfterRouteOpens(this, _titleFocus);
    final e = widget.existing;
    if (e != null) {
      _start = e.start;
      _end = e.end;
      _reminder = e.reminders.isEmpty ? null : e.reminders.first;
    } else {
      _start = widget.start ?? defaultEventStart(widget.day, DateTime.now());
      _end = _start.add(const Duration(hours: 1));
      _reminder = 10;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _titleFocus.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Tüm günde bitiş HARİÇ saklanır; ekranda son gün (dahil) gösterilir.
  DateTime get _shownEnd =>
      _allDay ? _end.subtract(const Duration(days: 1)) : _end;

  void _setAllDay(bool v) {
    setState(() {
      _allDay = v;
      if (v) {
        _start = startOfDay(_start);
        final lastDay = startOfDay(_end);
        _end = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
        if (!_end.isAfter(_start)) {
          _end = DateTime(_start.year, _start.month, _start.day + 1);
        }
        _reminder = _reminder == null ? null : 0;
      } else {
        final base = defaultEventStart(_start, DateTime.now());
        _start = base;
        _end = base.add(const Duration(hours: 1));
        _reminder = _reminder == null ? null : 10;
      }
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _shownEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        final duration = _end.difference(_start);
        _start = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _start.hour,
          _start.minute,
        );
        _end = _start.add(duration);
      } else {
        final end = _allDay
            ? DateTime(picked.year, picked.month, picked.day + 1)
            : DateTime(
                picked.year,
                picked.month,
                picked.day,
                _end.hour,
                _end.minute,
              );
        _end = end.isAfter(_start) ? end : _fallbackEnd();
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        final duration = _end.difference(_start);
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        _end = _start.add(duration);
      } else {
        final end = DateTime(
          _end.year,
          _end.month,
          _end.day,
          picked.hour,
          picked.minute,
        );
        _end = end.isAfter(_start) ? end : _fallbackEnd();
      }
    });
  }

  DateTime _fallbackEnd() => _allDay
      ? DateTime(_start.year, _start.month, _start.day + 1)
      : _start.add(const Duration(hours: 1));

  Future<void> _pickRepeat() async {
    final picked = await pickReminderRepeat(
      context,
      current: _repeat.base,
      anchor: _start,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _repeat = picked.isNone
          ? Recurrence.none
          : _repeat.copyWith(base: picked).anchoredTo(_start),
    );
  }

  Future<void> _pickReminder() async {
    final l10n = context.l10n;
    final choices = _allDay ? kAllDayReminderChoices : kTimedReminderChoices;
    // -1 = hatırlatma yok (levha null'u "vazgeçildi" sayar).
    final picked = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in <int?>[null, ...choices])
              ListTile(
                leading: Icon(
                  m == _reminder
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(eventReminderLabel(l10n, m, _allDay)),
                onTap: () => Navigator.pop(ctx, m ?? -1),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _reminder = picked < 0 ? null : picked);
  }

  /// Etkinliğe bağlı notlar (Google'da `eventLinks`, yerelde `noteIds`).
  List<String> _linkedNoteIds(CalendarEvent existing) {
    if (existing.fromGoogle) {
      final links = ref.watch(eventLinksStreamProvider).value;
      return links?[existing.google?.id] ?? const [];
    }
    final events = ref.watch(eventsStreamProvider).value;
    final live = events?.where((e) => e.id == existing.id).firstOrNull;
    return live?.noteIds ?? existing.noteIds;
  }

  /// Düzenleyicideki alanlarla [base]'in yeni hâli (Google yolu).
  CalendarEvent _edited(CalendarEvent base) => base.copyWith(
    title: _title.text.trim(),
    location: _location.text.trim(),
    description: _description.text.trim(),
    allDay: _allDay,
    start: _start,
    end: _end.isAfter(_start) ? _end : _fallbackEnd(),
    repeat: _repeat.encode(),
    reminders: _reminder == null ? const [] : [_reminder!],
  );

  Future<void> _save() async {
    final repo = ref.read(calendarRepositoryProvider);
    if (repo == null) return;
    final base =
        widget.existing ?? CalendarEvent(id: '', start: _start, end: _end);
    if (_toGoogle) {
      final google = ref.read(googleCalendarProvider.notifier);
      if (!ref.read(googleCalendarProvider).canWrite &&
          !await google.connectWrite()) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showMessage(context.l10n.gcalWriteDenied);
        }
        return;
      }
      if (!mounted) return;
      unawaited(google.saveToGoogle(_edited(base)));
      Navigator.pop(context);
      return;
    }
    repo.saveEvent(
      base.copyWith(
        title: _title.text.trim(),
        location: _location.text.trim(),
        description: _description.text.trim(),
        allDay: _allDay,
        start: _start,
        end: _end.isAfter(_start) ? _end : _fallbackEnd(),
        repeat: _repeat.encode(),
        reminders: _reminder == null ? const [] : [_reminder!],
        noteIds: widget.existing == null && widget.linkNoteId != null
            ? [widget.linkNoteId!]
            : null,
      ),
    );
    final messengerContext = Navigator.of(context).context;
    Navigator.pop(context);
    if (_reminder != null && messengerContext.mounted) {
      unawaited(maybeShowAutoStartHint(messengerContext));
    }
  }

  Future<void> _delete() async {
    final event = widget.existing;
    final repo = ref.read(calendarRepositoryProvider);
    if (event == null || repo == null) return;
    final l10n = context.l10n;
    if (event.fromGoogle) {
      // Google'dan silme geri alınamaz (yeniden eklemek yeni kimlik verir):
      // önce sorulur.
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.gcalDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventDelete),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      unawaited(
        ref.read(googleCalendarProvider.notifier).deleteFromGoogle(event),
      );
      Navigator.pop(context);
      return;
    }
    var onlyThis = false;
    if (event.repeats && widget.occurrenceStart != null) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(l10n.eventDeleteRepeatingTitle),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventDeleteThis),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.eventDeleteAll),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      onlyThis = choice;
    }
    if (!mounted) return;
    if (onlyThis) {
      repo.skipOccurrence(event.id, widget.occurrenceStart!);
      Navigator.pop(context);
      return;
    }
    repo.trashEvent(event.id);
    final ctx = Navigator.of(context).context;
    Navigator.pop(context);
    if (ctx.mounted) {
      showUndoSnackBar(
        ctx,
        message: l10n.eventDeleted,
        undoLabel: l10n.undo,
        onUndo: () => repo.restoreEvent(event.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMEd();
    final timeFmt = DateFormat.Hm();

    Widget dateRow(String label, DateTime value, {required bool start}) => Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            onPressed: () => _pickDate(start: start),
            child: Text(dateFmt.format(value)),
          ),
        ),
        if (!_allDay)
          TextButton(
            onPressed: () => _pickTime(start: start),
            child: Text(timeFmt.format(value)),
          ),
      ],
    );

    // Klavye payı ayrı, ince widget'ta (bkz. [SheetInsetPadding]).
    return SheetInsetPadding(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: widget.existing == null
                  ? l10n.calendarNewEvent
                  : l10n.eventEditTitle,
              actions: [
                if (widget.existing != null)
                  IconButton(
                    tooltip: l10n.eventDelete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('event-title'),
                    controller: _title,
                    focusNode: _titleFocus,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      hintText: l10n.eventTitleHint,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => unawaited(_save()),
                  ),
                  // Nereye kaydedilsin (Faz 51): yalnız yeni etkinlikte ve
                  // Google Takvim bağlıyken.
                  if (widget.existing == null &&
                      ref.watch(googleCalendarProvider).connected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SegmentedButton<bool>(
                        key: const ValueKey('event-target'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.devices_outlined, size: 18),
                            label: Text(l10n.eventSaveLocal),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.cloud_outlined, size: 18),
                            label: Text(l10n.gcalTitle),
                          ),
                        ],
                        selected: {_toGoogle},
                        onSelectionChanged: (v) =>
                            setState(() => _toGoogle = v.first),
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.schedule_outlined),
                    title: Text(l10n.eventAllDay),
                    value: _allDay,
                    onChanged: _setAllDay,
                  ),
                  dateRow(l10n.eventStarts, _start, start: true),
                  dateRow(l10n.eventEnds, _shownEnd, start: false),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.repeat),
                    title: Text(l10n.repeatTitle),
                    subtitle: Text(reminderRepeatLabel(l10n, _repeat.base)),
                    onTap: _pickRepeat,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_none_outlined),
                    title: Text(l10n.eventReminder),
                    subtitle: Text(
                      eventReminderLabel(l10n, _reminder, _allDay),
                    ),
                    onTap: _pickReminder,
                  ),
                  const Divider(),
                  TextField(
                    controller: _location,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.place_outlined),
                      hintText: l10n.eventLocation,
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: _description,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.notes_outlined),
                      hintText: l10n.eventDescription,
                      border: InputBorder.none,
                    ),
                  ),
                  // Bağlı notlar + toplantı notu (F49.1): kayıtlı etkinlikte.
                  if (widget.existing case final existing?) ...[
                    const SizedBox(height: 8),
                    LinkedNotesList(
                      noteIds: _linkedNoteIds(existing),
                      onUnlink: (id) {
                        final repo = ref.read(calendarRepositoryProvider);
                        final g = existing.google;
                        existing.fromGoogle && g != null
                            ? repo?.unlinkNoteFromGoogleEvent(g.id, id)
                            : repo?.unlinkNoteFromEvent(existing.id, id);
                      },
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: const ValueKey('event-meeting-note'),
                        onPressed: () {
                          Navigator.pop(context);
                          unawaited(
                            openMeetingNote(
                              context,
                              ref,
                              existing,
                              widget.occurrenceStart ?? existing.start,
                            ),
                          );
                        },
                        icon: const Icon(Icons.note_add_outlined),
                        label: Text(l10n.calendarMeetingNote),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: const ValueKey('event-link-note'),
                        onPressed: () => unawaited(
                          linkExistingNote(context, ref, event: existing),
                        ),
                        icon: const Icon(Icons.link),
                        label: Text(l10n.calendarLinkExistingNote),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('event-save'),
                    onPressed: () => unawaited(_save()),
                    child: Text(l10n.eventSave),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
