import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/domain/note.dart';
import '../data/calendar_repository.dart';
import '../data/google_calendar_sync.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
import 'event_editor.dart';

/// **NOT ↔ TAKVİM BAĞI** (TAKVIM_PLANI Faz 49).
///
/// Bağlar not belgesinde DEĞİL (sık yazılan büyük belge, §3): güne bağ
/// `dayLinks/{gün}`, yerel etkinliğe `events/{id}.noteIds`, Google
/// etkinliğine `eventLinks/{googleId}`. Notun bağları bu üçünden TERS
/// hesaplanır ([calendarLinksForNote]).
@immutable
class NoteCalendarLink {
  const NoteCalendarLink({required this.day, this.event});

  /// Bağın günü (etkinlikte başlangıç günü).
  final DateTime day;

  /// Etkinliğe bağsa etkinlik; güne bağsa null.
  final CalendarEvent? event;

  @override
  bool operator ==(Object other) =>
      other is NoteCalendarLink &&
      other.day == day &&
      other.event?.id == event?.id;

  @override
  int get hashCode => Object.hash(day, event?.id);
}

/// Saf hesap: [noteId]'nin gün ve etkinlik bağları, güne göre sıralı.
List<NoteCalendarLink> calendarLinksForNote(
  String noteId, {
  Map<String, List<String>> dayLinks = const {},
  Iterable<CalendarEvent> events = const [],
}) {
  final out = <NoteCalendarLink>[
    for (final e in dayLinks.entries)
      if (e.value.contains(noteId))
        if (parseDayKey(e.key) case final day?) NoteCalendarLink(day: day),
    for (final e in events)
      if (e.deletedAt == null && e.noteIds.contains(noteId))
        NoteCalendarLink(day: startOfDay(e.start), event: e),
  ]..sort((a, b) => a.day.compareTo(b.day));
  return out;
}

/// Editördeki notun bağları (tek not izlenir).
final noteCalendarLinksProvider =
    Provider.family<List<NoteCalendarLink>, String>((ref, noteId) {
      return calendarLinksForNote(
        noteId,
        dayLinks: ref.watch(dayLinksStreamProvider).value ?? const {},
        events: [
          ...?ref.watch(eventsStreamProvider).value,
          ...ref.watch(googleCalendarEventsProvider),
        ],
      );
    });

/// Günün notu başlığı: "6 Kasım Perşembe" (F49.1).
String dayNoteTitle(DateTime day, [String? locale]) =>
    DateFormat('d MMMM EEEE', locale).format(day);

/// **NOTTA BAĞ HAPI** (F49.2): başlığın altında "📅 6 Kas · Toplantı";
/// dokununca takvim o günde açılır. Bağ yoksa hiçbir şey çizmez.
class NoteCalendarPills extends ConsumerWidget {
  const NoteCalendarPills({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(noteCalendarLinksProvider(noteId));
    if (links.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final l in links.take(4))
            ActionChip(
              key: ValueKey('note-cal-${dayKey(l.day)}-${l.event?.id ?? ''}'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(
                Icons.event_outlined,
                size: 16,
                color: scheme.primary,
              ),
              label: Text(
                [
                  DateFormat.MMMd().format(l.day),
                  if (l.event case final e? when e.title.trim().isNotEmpty)
                    e.title.trim(),
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () =>
                  unawaited(context.push('/calendar?day=${dayKey(l.day)}')),
            ),
        ],
      ),
    );
  }
}

/// Not ⋮ → **Takvime bağla** (F49.1): güne / var olan etkinliğe / yeni
/// etkinlik. Var olan bağlar listede kaldırılabilir.
Future<void> showLinkNoteToCalendarSheet(BuildContext context, Note note) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _LinkSheet(note: note),
    );

class _LinkSheet extends ConsumerWidget {
  const _LinkSheet({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final repo = ref.watch(calendarRepositoryProvider);
    final links = ref.watch(noteCalendarLinksProvider(note.id));
    final now = DateTime.now();
    final soon = startOfDay(now);
    final upcoming =
        [
            ...?ref.watch(eventsStreamProvider).value,
            ...ref.watch(googleCalendarEventsProvider),
          ].where((e) => e.deletedAt == null && !e.end.isBefore(soon)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final linkedIds = {for (final l in links) l.event?.id};
    final messenger = ScaffoldMessenger.of(context);

    void linkEvent(CalendarEvent e) {
      if (repo == null) return;
      final g = e.google;
      if (e.fromGoogle && g != null) {
        repo.linkNoteToGoogleEvent(g.id, note.id);
      } else {
        repo.linkNoteToEvent(e.id, note.id);
      }
      Navigator.pop(context);
      messenger.showMessage(l10n.calendarLinked);
    }

    void unlink(NoteCalendarLink l) {
      if (repo == null) return;
      final e = l.event;
      final g = e?.google;
      if (e == null) {
        repo.unlinkNoteFromDay(dayKey(l.day), note.id);
      } else if (e.fromGoogle && g != null) {
        repo.unlinkNoteFromGoogleEvent(g.id, note.id);
      } else {
        repo.unlinkNoteFromEvent(e.id, note.id);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.calendarLinkNote, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final l in links)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(
                [
                  DateFormat.yMMMEd().format(l.day),
                  if (l.event case final e? when e.title.isNotEmpty) e.title,
                ].join(' · '),
              ),
              trailing: IconButton(
                tooltip: l10n.calendarUnlinkNote,
                icon: const Icon(Icons.link_off),
                onPressed: () => unlink(l),
              ),
            ),
          ListTile(
            key: const ValueKey('link-to-day'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.today_outlined),
            title: Text(l10n.calendarLinkToDay),
            onTap: () async {
              final day = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (day == null || repo == null) return;
              repo.linkNoteToDay(dayKey(day), note.id);
              if (context.mounted) Navigator.pop(context);
              messenger.showMessage(l10n.calendarLinked);
            },
          ),
          ListTile(
            key: const ValueKey('link-new-event'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_outlined),
            title: Text(l10n.calendarLinkNewEvent),
            onTap: () {
              final root = Navigator.of(context).context;
              Navigator.pop(context);
              unawaited(
                showEventEditor(
                  root,
                  day: now,
                  linkNoteId: note.id,
                  initialTitle: note.displayTitle.trim(),
                ),
              );
            },
          ),
          if (upcoming.isNotEmpty) ...[
            const Divider(),
            Text(l10n.calendarLinkToEvent, style: theme.textTheme.labelLarge),
            for (final e in upcoming.take(20))
              if (!linkedIds.contains(e.id))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    e.fromGoogle ? Icons.cloud_outlined : Icons.event_outlined,
                    color: e.color == null ? null : Color(e.color!),
                  ),
                  title: Text(
                    e.title.trim().isEmpty ? l10n.eventUntitled : e.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    e.allDay
                        ? DateFormat.yMMMEd().format(e.start)
                        : '${DateFormat.yMMMEd().format(e.start)} · '
                              '${DateFormat.Hm().format(e.start)}',
                  ),
                  onTap: () => linkEvent(e),
                ),
          ],
        ],
      ),
    );
  }
}
