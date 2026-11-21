import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/note_colors.dart';
import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../data/calendar_repository.dart';
import '../data/google_calendar_sync.dart';
import '../../notes/presentation/note_target_picker.dart';
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';
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

/// Etkinliğe veya güne bağlı notların zengin bento önizleme kartları
/// (dokununca not açılır; notun başlığı, gövde/madde önizlemesi, renk vurgusu,
/// ek/çizim rozetleri ve saati tek bakışta görünür).
class LinkedNotesList extends ConsumerWidget {
  const LinkedNotesList({
    super.key,
    required this.noteIds,
    this.onUnlink,
    this.times = const {},
    this.onSetTime,
    this.preloadedNotes,
    this.onNoteTap,
  });

  final List<String> noteIds;
  final ValueChanged<String>? onUnlink;

  /// Güne SAATLE bağlı notlar (not → gün başından dakika).
  final Map<String, int> times;

  /// Saat seç / tüm güne al (null dakika = tüm gün); null = düğme yok.
  final void Function(String noteId, int? minutes)? onSetTime;

  /// Varsa `notesStreamProvider`'ı yeniden dinlemeden doğrudan kullanılır.
  final List<Note>? preloadedNotes;

  /// Karta dokunulunca çalışır (ör. hızlı önizleme levhası); null = notu aç.
  final void Function(Note note, int? minutes)? onNoteTap;

  Future<void> _pickTime(BuildContext context, String id) async {
    final set = onSetTime;
    if (set == null) return;
    final l10n = context.l10n;
    final current = times[id];
    if (current != null) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l10n.calendarLinkTime),
                onTap: () => Navigator.pop(ctx, 'time'),
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: Text(l10n.calendarLinkAllDay),
                onTap: () => Navigator.pop(ctx, 'allday'),
              ),
            ],
          ),
        ),
      );
      if (choice == null || !context.mounted) return;
      if (choice == 'allday') {
        set(id, null);
        return;
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    set(id, picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteIds.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    final List<Note> resolved;
    if (preloadedNotes != null) {
      final byId = {for (final n in preloadedNotes!) n.id: n};
      resolved = [
        for (final id in noteIds)
          if (byId[id] case final note? when note.deletedAt == null) note,
      ];
    } else {
      final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
      final byId = {for (final n in notes) n.id: n};
      resolved = [
        for (final id in noteIds)
          if (byId[id] case final note? when note.deletedAt == null) note,
      ];
    }
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.s),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(
                    alpha: AppAlpha.soft,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    size: AppIconSize.xs,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(child: SectionLabel(l10n.calendarLinkedNotes)),
              DecoratedBox(
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
                    '${resolved.length}',
                    style: text.badge.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < resolved.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.s),
          _LinkedNotePreviewCard(
            note: resolved[i],
            minutes: times[resolved[i].id],
            onTap: () {
              final customTap = onNoteTap;
              if (customTap != null) {
                customTap(resolved[i], times[resolved[i].id]);
                return;
              }
              unawaited(context.pushNote(noteRoutePath(resolved[i].id)));
            },
            onPickTime: onSetTime == null
                ? null
                : () => unawaited(_pickTime(context, resolved[i].id)),
            onUnlink: onUnlink == null ? null : () => onUnlink!(resolved[i].id),
          ),
        ],
      ],
    );
  }
}

IconData _noteTypeIcon(NoteType type) => switch (type) {
  NoteType.checklist => Icons.checklist_rounded,
  NoteType.ordered => Icons.format_list_numbered_rounded,
  NoteType.pdf => Icons.picture_as_pdf_outlined,
  NoteType.slides => Icons.slideshow_outlined,
  NoteType.archive => AppIcons.archive,
  NoteType.text => Icons.sticky_note_2_outlined,
};

/// Takvim gün paneli / etkinlik levhası için zengin bento not önizleme kartı.
class _LinkedNotePreviewCard extends StatelessWidget {
  const _LinkedNotePreviewCard({
    required this.note,
    required this.minutes,
    required this.onTap,
    required this.onPickTime,
    required this.onUnlink,
  });

  final Note note;
  final int? minutes;
  final VoidCallback onTap;
  final VoidCallback? onPickTime;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final hasCustomColor =
        note.color != NoteColor.none || note.customColor != null;
    final surface = hasCustomColor
        ? NoteColors.noteSurfaceIn(theme, note)
        : scheme.surfaceContainer;
    final accent = NoteColors.noteInkIn(theme, note) ?? scheme.primary;
    final title = note.displayTitle.trim().isEmpty
        ? l10n.untitledNote
        : note.displayTitle.trim();

    final nonEmptyItems = [
      for (final item in note.items)
        if (!item.header && item.text.trim().isNotEmpty) item,
    ];
    final bodyPreview = note.body
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tags = [
      for (final t in note.tags)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    final images = note.attachments
        .where((a) => a.kind == AttachmentKind.image)
        .length;
    final docs = note.attachments
        .where(
          (a) =>
              a.kind == AttachmentKind.pdf || a.kind == AttachmentKind.slide,
        )
        .length;
    final audios = note.attachments
        .where((a) => a.kind == AttachmentKind.audio)
        .length;
    final hasInk = note.hasPageInk || note.pageInk.isNotEmpty;

    return Material(
      key: ValueKey('linked-note-${note.id}'),
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: accent.withValues(alpha: AppAlpha.soft),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: AppSpace.xs, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.m,
                    AppSpace.s,
                    AppSpace.s,
                    AppSpace.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _noteTypeIcon(note.type),
                            size: AppIconSize.s,
                            color: accent,
                          ),
                          const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.rowTitle.copyWith(
                                fontWeight: AppWeight.strong,
                              ),
                            ),
                          ),
                          if (onPickTime != null) ...[
                            const SizedBox(width: AppSpace.xs),
                            Material(
                              key: ValueKey('linked-note-time-${note.id}'),
                              color: minutes != null
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.s),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: onPickTime,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.s,
                                    vertical: AppSpace.xs,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: AppSpace.xs,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: AppIconSize.xs,
                                        color: minutes != null
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                      Text(
                                        minutes == null
                                            ? l10n.calendarLinkTime
                                            : formatHm(
                                                minutes! ~/ 60,
                                                minutes! % 60,
                                              ),
                                        style: text.badge.copyWith(
                                          color: minutes != null
                                              ? scheme.onPrimaryContainer
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (onUnlink != null)
                            IconButton(
                              tooltip: l10n.calendarUnlinkNote,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                Icons.link_off,
                                size: AppIconSize.s,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: onUnlink,
                            ),
                        ],
                      ),
                      if (note.locked) ...[
                        const SizedBox(height: AppSpace.xs),
                        Row(
                          spacing: AppSpace.xs,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: AppIconSize.xs,
                              color: scheme.onSurfaceVariant,
                            ),
                            Text(l10n.lockedNote, style: text.meta),
                          ],
                        ),
                      ] else if (nonEmptyItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        for (final item in nonEmptyItems.take(2))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpace.xxs,
                            ),
                            child: Row(
                              spacing: AppSpace.xs,
                              children: [
                                Icon(
                                  item.checked
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: AppIconSize.xs,
                                  color: item.checked
                                      ? accent
                                      : scheme.onSurfaceVariant,
                                ),
                                Expanded(
                                  child: Text(
                                    item.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.meta.copyWith(
                                      decoration: item.checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (nonEmptyItems.length > 2)
                          Text(
                            '+${nonEmptyItems.length - 2}',
                            style: text.badge.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ] else if (bodyPreview.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          bodyPreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.meta,
                        ),
                      ],
                      if (!note.locked &&
                          (tags.isNotEmpty ||
                              images > 0 ||
                              docs > 0 ||
                              audios > 0 ||
                              hasInk)) ...[
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xxs,
                          children: [
                            for (final tag in tags.take(3))
                              _PreviewTagChip(tag: tag),
                            if (images > 0)
                              _PreviewMetaChip(
                                icon: Icons.image_outlined,
                                label: '$images',
                              ),
                            if (docs > 0)
                              _PreviewMetaChip(
                                icon: Icons.description_outlined,
                                label: '$docs',
                              ),
                            if (audios > 0)
                              _PreviewMetaChip(
                                icon: AppIcons.voiceRecord,
                                label: '$audios',
                              ),
                            if (hasInk)
                              const _PreviewMetaChip(
                                icon: Icons.draw_outlined,
                                label: '✎',
                              ),
                          ],
                        ),
                      ],
                    ],
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

class _PreviewTagChip extends StatelessWidget {
  const _PreviewTagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: AppAlpha.strong),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xxs,
        ),
        child: Text(
          '#$tag',
          style: text.badge.copyWith(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _PreviewMetaChip extends StatelessWidget {
  const _PreviewMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: AppAlpha.muted,
        ),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.xxs,
          children: [
            Icon(icon, size: AppIconSize.xs, color: scheme.onSurfaceVariant),
            Text(
              label,
              style: text.badge.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Takvim hücresindeki veya alt paneldeki bir nota dokunulduğunda açılan
/// zengin hızlı önizleme levhası: başlık, etiketler, gövde/liste içeriği,
/// ek özeti ve tek dokunuşla tam editöre geçiş ("Notu aç").
Future<void> showCalendarNotePreviewSheet(
  BuildContext context, {
  required Note note,
  DateTime? day,
  int? minutes,
  VoidCallback? onOpenFull,
  VoidCallback? onPickTime,
  VoidCallback? onUnlink,
}) => showAppSheet<void>(
  context: context,
  builder: (sheetCtx) {
    final l10n = sheetCtx.l10n;
    final theme = Theme.of(sheetCtx);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final hasCustomColor =
        note.color != NoteColor.none || note.customColor != null;
    final headerBg = hasCustomColor
        ? NoteColors.noteSurfaceIn(theme, note)
        : scheme.surfaceContainerHigh;
    final accent = NoteColors.noteInkIn(theme, note) ?? scheme.primary;
    final title = note.displayTitle.trim().isEmpty
        ? l10n.untitledNote
        : note.displayTitle.trim();
    final nonEmptyItems = [
      for (final item in note.items)
        if (!item.header && item.text.trim().isNotEmpty) item,
    ];
    final bodyText = note.body.trim();
    final tags = [
      for (final t in note.tags)
        if (t.trim().isNotEmpty) t.trim(),
    ];
    final images = note.attachments
        .where((a) => a.kind == AttachmentKind.image)
        .length;
    final docs = note.attachments
        .where(
          (a) =>
              a.kind == AttachmentKind.pdf || a.kind == AttachmentKind.slide,
        )
        .length;
    final audios = note.attachments
        .where((a) => a.kind == AttachmentKind.audio)
        .length;
    final hasInk = note.hasPageInk || note.pageInk.isNotEmpty;
    final dayLabel = day == null ? null : DateFormat.MMMMEEEEd().format(day);
    final timeLabel = minutes == null
        ? null
        : formatHm(minutes ~/ 60, minutes % 60);

    return SafeArea(
      key: ValueKey('calendar-note-preview-${note.id}'),
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetCtx).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.m,
                AppSpace.s,
                AppSpace.m,
              ),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(
                  bottom: BorderSide(
                    color: accent.withValues(alpha: AppAlpha.soft),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: AppAlpha.soft),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.s),
                      child: Icon(
                        _noteTypeIcon(note.type),
                        size: AppIconSize.m,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.sheetTitle.copyWith(
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                        if (dayLabel != null || timeLabel != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            [
                              ?dayLabel,
                              ?timeLabel,
                            ].join(' · '),
                            style: text.meta.copyWith(color: accent),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onPickTime != null)
                    IconButton(
                      tooltip: l10n.calendarLinkTime,
                      icon: Icon(
                        Icons.schedule_outlined,
                        size: AppIconSize.m,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        onPickTime();
                      },
                    ),
                  if (onUnlink != null)
                    IconButton(
                      tooltip: l10n.calendarUnlinkNote,
                      icon: Icon(
                        Icons.link_off,
                        size: AppIconSize.m,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        onUnlink();
                      },
                    ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: Icon(
                      Icons.close_rounded,
                      size: AppIconSize.m,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.m,
                  AppSpace.l,
                  AppSpace.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tags.isNotEmpty) ...[
                      Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          for (final tag in tags) _PreviewTagChip(tag: tag),
                        ],
                      ),
                      const SizedBox(height: AppSpace.m),
                    ],
                    if (note.locked)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.m),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.m),
                          child: Row(
                            spacing: AppSpace.s,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: AppIconSize.m,
                                color: scheme.onSurfaceVariant,
                              ),
                              Expanded(
                                child: Text(
                                  l10n.lockedNote,
                                  style: text.body.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (nonEmptyItems.isNotEmpty) ...[
                      for (var i = 0; i < nonEmptyItems.length && i < 12; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.s),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpace.s,
                            children: [
                              if (note.type == NoteType.ordered)
                                Text(
                                  '${i + 1}.',
                                  style: text.meta.copyWith(
                                    fontWeight: AppWeight.strong,
                                    color: accent,
                                  ),
                                )
                              else
                                Icon(
                                  nonEmptyItems[i].checked
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: AppIconSize.s,
                                  color: nonEmptyItems[i].checked
                                      ? accent
                                      : scheme.onSurfaceVariant,
                                ),
                              Expanded(
                                child: Text(
                                  nonEmptyItems[i].text.trim(),
                                  style: text.body.copyWith(
                                    decoration: nonEmptyItems[i].checked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (nonEmptyItems.length > 12)
                        Text(
                          '+${nonEmptyItems.length - 12}',
                          style: text.meta,
                        ),
                    ] else if (bodyText.isNotEmpty)
                      Text(bodyText, style: text.body)
                    else
                      Text(
                        l10n.emptyNotes,
                        style: text.meta.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (!note.locked &&
                        (images > 0 || docs > 0 || audios > 0 || hasInk)) ...[
                      const SizedBox(height: AppSpace.m),
                      Wrap(
                        spacing: AppSpace.s,
                        runSpacing: AppSpace.xs,
                        children: [
                          if (images > 0)
                            _PreviewMetaChip(
                              icon: Icons.image_outlined,
                              label: '$images',
                            ),
                          if (docs > 0)
                            _PreviewMetaChip(
                              icon: Icons.description_outlined,
                              label: '$docs',
                            ),
                          if (audios > 0)
                            _PreviewMetaChip(
                              icon: AppIcons.voiceRecord,
                              label: '$audios',
                            ),
                          if (hasInk)
                            const _PreviewMetaChip(
                              icon: Icons.draw_outlined,
                              label: '✎',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.xs,
                AppSpace.l,
                AppSpace.m,
              ),
              child: FilledButton.icon(
                key: const ValueKey('calendar-note-preview-open'),
                icon: const Icon(Icons.open_in_new_rounded, size: AppIconSize.s),
                label: Text(l10n.openNote),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  if (onOpenFull != null) {
                    onOpenFull();
                  } else {
                    unawaited(context.pushNote(noteRoutePath(note.id)));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  },
);

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
