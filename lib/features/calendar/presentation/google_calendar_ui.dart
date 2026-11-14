import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../data/calendar_repository.dart';
import '../data/google_calendar_sync.dart';
import '../../notes/presentation/note_target_picker.dart';
import '../domain/calendar_event.dart';
import 'event_editor.dart';
import 'google_failure.dart';

/// Google Takvim bağlantısı: bağla, gösterilen takvimler, yenile, kaldır
/// (TAKVIM_PLANI F48.1/F48.2).
Future<void> showGoogleCalendarSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _GoogleCalendarSheet(),
    );

class _GoogleCalendarSheet extends ConsumerWidget {
  const _GoogleCalendarSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(googleCalendarProvider);
    final controller = ref.read(googleCalendarProvider.notifier);
    final synced = state.syncedAt;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.gcalTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.gcalInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (!state.connected)
            FilledButton.icon(
              key: const ValueKey('gcal-connect'),
              onPressed: state.loading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Levha kapanmış olabilir: kabın kendisinden oku.
                      final container = ProviderScope.containerOf(
                        context,
                        listen: false,
                      );
                      final ok = await controller.connect();
                      if (!ok) {
                        showGoogleConnectFailure(
                          messenger,
                          l10n,
                          container.read(googleCalendarProvider).error,
                          fallback: l10n.gcalConnectFailed,
                          apiName: 'Google Calendar API',
                          apiHost: 'calendar-json.googleapis.com',
                        );
                      }
                    },
              icon: const Icon(Icons.link),
              label: Text(l10n.gcalConnect),
            ),
          // Konsolda API kapalıysa kalıcı açıklama (bildirim kaybolup
          // gidiyordu; F19.B10 adımı kullanıcının işi).
          if (!state.connected && googleErrorIsServiceDisabled(state.error))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.googleApiDisabled('Google Calendar API'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (state.connected) ...[
            Text(l10n.gcalCalendars, style: theme.textTheme.labelLarge),
            for (final c in state.calendars)
              CheckboxListTile(
                key: ValueKey('gcal-cal-${c.id}'),
                contentPadding: EdgeInsets.zero,
                value: state.isShown(c),
                onChanged: (v) => unawaited(controller.setShown(c.id, v!)),
                secondary: CircleAvatar(
                  radius: 8,
                  backgroundColor: c.color == null
                      ? theme.colorScheme.primary
                      : Color(c.color!),
                ),
                title: Text(c.summary, overflow: TextOverflow.ellipsis),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    synced == null
                        ? ''
                        : l10n.gcalSyncedAt(DateFormat.Hm().format(synced)),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (state.loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () => unawaited(controller.refresh(force: true)),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.gcalRefresh),
                  ),
              ],
            ),
            if (state.pending > 0)
              Text(
                l10n.gcalPending(state.pending),
                style: theme.textTheme.bodySmall,
              ),
            if (state.error != null)
              Text(
                l10n.gcalError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            TextButton.icon(
              onPressed: () => unawaited(controller.disconnect()),
              icon: const Icon(Icons.link_off),
              label: Text(l10n.gcalDisconnect),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etkinlikten açılan toplantı notunun gövdesi (F49.1; Google ve yerel).
String meetingNoteBody(CalendarEvent event, DateTime start, String locale) {
  final end = start.add(event.duration);
  final when = event.allDay
      ? DateFormat.yMMMMEEEEd(locale).format(start)
      : '${DateFormat.yMMMMEEEEd(locale).format(start)} · '
            '${DateFormat.Hm(locale).format(start)}–'
            '${DateFormat.Hm(locale).format(end)}';
  return [
    when,
    if (event.location.trim().isNotEmpty) event.location.trim(),
    if (event.description.trim().isNotEmpty) '',
    if (event.description.trim().isNotEmpty) event.description.trim(),
  ].join('\n');
}

/// Etkinlikten toplantı notu açar ve etkinliğe bağlar (F48.4 Google,
/// F49.1 yerel). Not açılır.
Future<void> openMeetingNote(
  BuildContext context,
  WidgetRef ref,
  CalendarEvent event,
  DateTime start,
) async {
  final notes = ref.read(notesRepositoryProvider);
  final calendar = ref.read(calendarRepositoryProvider);
  if (notes == null || calendar == null) return;
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final id = await notes.createNote(
    NoteType.text,
    title: event.title.trim().isEmpty ? l10n.eventUntitled : event.title.trim(),
    body: meetingNoteBody(event, start, locale),
  );
  final google = event.google;
  if (event.fromGoogle && google != null) {
    calendar.linkNoteToGoogleEvent(google.id, id);
  } else {
    calendar.linkNoteToEvent(event.id, id);
  }
  if (context.mounted) unawaited(context.pushNote(noteRoutePath(id)));
}

/// Var olan bir notu güne ([dayKey]) ya da etkinliğe ([event]) bağlar:
/// "Nota ekle" seçicisiyle (bkz. [showNoteTargetPicker]) not seçilir; üstteki
/// boş "Yeni not" kartı da seçilebilir — o durumda başlıksız yeni not açılıp
/// bağlanır. Tek dokunuşla bağlama (2026-11-08).
Future<void> linkExistingNote(
  BuildContext context,
  WidgetRef ref, {
  String? dayKey,
  CalendarEvent? event,
}) async {
  final notes = ref.read(notesRepositoryProvider);
  final calendar = ref.read(calendarRepositoryProvider);
  if (notes == null || calendar == null) return;
  final target = await showNoteTargetPicker(context);
  if (target == null) return;
  final picked = target.note;
  final id = picked?.id ?? await notes.createNote(NoteType.text);
  if (dayKey != null) {
    calendar.linkNoteToDay(dayKey, id);
  } else if (event != null) {
    final google = event.google;
    if (event.fromGoogle && google != null) {
      calendar.linkNoteToGoogleEvent(google.id, id);
    } else {
      calendar.linkNoteToEvent(event.id, id);
    }
  }
  if (picked == null && context.mounted) {
    unawaited(context.pushNote(noteRoutePath(id)));
  }
}

/// Etkinliğe bağlı notların satırları (dokununca not açılır).
class LinkedNotesList extends ConsumerWidget {
  const LinkedNotesList({super.key, required this.noteIds, this.onUnlink});

  final List<String> noteIds;
  final ValueChanged<String>? onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteIds.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    final byId = {for (final n in notes) n.id: n};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calendarLinkedNotes,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        for (final id in noteIds)
          if (byId[id] case final note? when note.deletedAt == null)
            ListTile(
              key: ValueKey('linked-note-$id'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(
                note.displayTitle.trim().isEmpty
                    ? l10n.untitledNote
                    : note.displayTitle,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: onUnlink == null
                  ? null
                  : IconButton(
                      tooltip: l10n.calendarUnlinkNote,
                      icon: const Icon(Icons.link_off),
                      onPressed: () => onUnlink!(id),
                    ),
              onTap: () => unawaited(context.pushNote(noteRoutePath(id))),
            ),
      ],
    );
  }
}

/// Google etkinliğinin ayrıntısı (salt okunur, F48.3/F48.4).
Future<void> showGoogleEventSheet(
  BuildContext context,
  CalendarEvent event,
  DateTime start,
) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _GoogleEventSheet(event: event, start: start),
);

class _GoogleEventSheet extends ConsumerWidget {
  const _GoogleEventSheet({required this.event, required this.start});

  final CalendarEvent event;
  final DateTime start;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final link = event.extras['htmlLink'];
    final googleId = event.google?.id ?? '';
    final linked =
        ref.watch(eventLinksStreamProvider).value?[googleId] ?? const [];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.title.trim().isEmpty ? l10n.eventUntitled : event.title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(_whenLabel(context, l10n), style: theme.textTheme.bodyMedium),
          if (event.location.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(event.location)),
              ],
            ),
          ],
          if (event.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(event.description.trim()),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.gcalReadOnly,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LinkedNotesList(
            noteIds: linked,
            onUnlink: (id) => ref
                .read(calendarRepositoryProvider)
                ?.unlinkNoteFromGoogleEvent(googleId, id),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('gcal-meeting-note'),
                onPressed: () {
                  Navigator.pop(context);
                  unawaited(openMeetingNote(context, ref, event, start));
                },
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.calendarMeetingNote),
              ),
              TextButton.icon(
                key: const ValueKey('gcal-link-note'),
                onPressed: () =>
                    unawaited(linkExistingNote(context, ref, event: event)),
                icon: const Icon(Icons.link),
                label: Text(l10n.calendarLinkExistingNote),
              ),
              // Tekrarlı serinin oluşu Google'da düzenlenir (K3: "yalnız bu /
              // tümü" Google'ın işi); tekil etkinlik burada (Faz 51).
              if (event.extras['recurringEventId'] == null)
                TextButton.icon(
                  key: const ValueKey('gcal-edit'),
                  onPressed: () {
                    final root = Navigator.of(context).context;
                    Navigator.pop(context);
                    unawaited(
                      showEventEditor(
                        root,
                        existing: event,
                        occurrenceStart: start,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.gcalEdit),
                ),
              if (link is String)
                TextButton.icon(
                  onPressed: () => unawaited(
                    launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.gcalOpenInGoogle),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _whenLabel(BuildContext context, AppLocalizations l10n) {
    final day = DateFormat.yMMMMEEEEd().format(start);
    if (event.allDay) return day;
    final end = start.add(event.duration);
    return '$day · ${DateFormat.Hm().format(start)}–'
        '${DateFormat.Hm().format(end)}';
  }
}
