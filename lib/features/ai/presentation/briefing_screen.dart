import '../../../app/app_frame.dart';
import '../../../app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/a11y/chip_roles.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/data/google_calendar_sync.dart';
import '../../calendar/domain/agenda.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../calendar/domain/day_key.dart';
import '../../calendar/domain/task_item.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../data/ai_gate.dart';
import '../data/daily_cache.dart';
import '../data/gemini_service.dart';
import 'ai_generate_prompt.dart';
import 'ai_text_result.dart';

/// Günlük brifing: bugünün hatırlatıcıları + son notlardaki yapılacaklar, tek
/// AI özetinde. Sonuç günde bir kez üretilip diske yazılır; ekranlar arası ve
/// uygulama yeniden açılışında korunur, "Yenile" ile hemen tazelenir.
final briefingProvider = AsyncNotifierProvider<BriefingNotifier, String>(
  BriefingNotifier.new,
);

/// Haftalık özet (PLAN §1.6): son 7 günün notları + tamamlanan görevleri ve
/// gelecek 7 günün takvim/hatırlatıcıları; günlük brifingle tek ekranda.
final weeklyBriefingProvider =
    AsyncNotifierProvider<WeeklyBriefingNotifier, String>(
      WeeklyBriefingNotifier.new,
    );

/// Haftalık brifing ham girdisini oluşturur; kilitli not içerikleri asla sızmaz.
String buildWeeklyBriefingInput({
  required DateTime now,
  required List<Note> notes,
  List<CalendarEvent> events = const [],
  List<TaskItem> tasks = const [],
}) {
  final today = startOfDay(now);
  final weekAgo = today.subtract(const Duration(days: 7));
  final nextWeek = today.add(const Duration(days: 8));
  final buf = StringBuffer();

  buf.writeln('SON 7 GÜN NOTLARI:');
  var noteCount = 0;
  for (final note in notes) {
    if (note.deletedAt != null || note.archivedAt != null || note.locked) {
      continue;
    }
    final stamp = note.updatedAt ?? note.createdAt;
    if (stamp == null || stamp.isBefore(weekAgo)) continue;
    final text = note.toPlainText().trim();
    if (text.isEmpty) continue;
    final snippet = text.length > 180 ? '${text.substring(0, 180)}…' : text;
    buf.writeln('- ${snippet.replaceAll('\n', ' / ')}');
    if (++noteCount >= 20) break;
  }
  if (noteCount == 0) buf.writeln('- (yok)');

  buf.writeln('\nSON 7 GÜNDE TAMAMLANAN GÖREVLER:');
  var doneCount = 0;
  for (final t in tasks) {
    if (t.deletedAt != null || !t.completed) continue;
    final at = t.completedAt ?? t.updatedAt;
    if (at == null || at.isBefore(weekAgo)) continue;
    buf.writeln('- ${t.title.trim()}');
    if (++doneCount >= 20) break;
  }
  if (doneCount == 0) buf.writeln('- (yok)');

  buf.writeln('\nAÇIK VE GECİKMİŞ GÖREVLER:');
  var openCount = 0;
  for (final t in tasks) {
    if (t.deletedAt != null || t.completed) continue;
    final due = t.due.isNotEmpty ? ' (${t.due})' : '';
    buf.writeln('- ${t.title.trim()}$due');
    if (++openCount >= 20) break;
  }
  if (openCount == 0) buf.writeln('- (yok)');

  buf.writeln('\nGELECEK 7 GÜN TAKVİM VE HATIRLATICILAR:');
  final agenda = buildAgenda(
    from: today,
    to: nextWeek,
    events: events,
    reminderNotes: notes,
    includeCompleted: false,
  );
  var upcomingCount = 0;
  for (final entry in agenda.entries) {
    final day = parseDayKey(entry.key);
    if (day == null) continue;
    final dayLabel = DateFormat('d MMM E', 'tr').format(day);
    for (final e in entry.value) {
      final label = switch (e) {
        EventOccurrence(:final event) =>
          event.title.trim().isEmpty ? '(etkinlik)' : event.title.trim(),
        ReminderEntry(:final note) =>
          note.displayTitle.trim().isNotEmpty
              ? note.displayTitle.trim()
              : note.locked
              ? '(kilitli not)'
              : note.toPlainText().split('\n').first,
        TaskEntry(:final task) => task.title.trim(),
        RoutineEntry(:final routine) => routine.title.trim(),
      };
      buf.writeln('- $dayLabel: $label');
      if (++upcomingCount >= 25) break;
    }
    if (upcomingCount >= 25) break;
  }
  if (upcomingCount == 0) buf.writeln('- (yok)');

  return buf.toString().trim();
}

class WeeklyBriefingNotifier extends StringDailyCache {
  @override
  String get cacheKey => 'cache_weekly_briefing';

  @override
  Future<String> compute() async {
    final notes = await ref.read(notesStreamProvider.future);
    final calendar = ref.read(calendarRepositoryProvider);
    final events = [
      ...?(calendar == null ? null : await calendar.watchEvents().first),
      ...ref.read(googleCalendarEventsProvider),
    ];
    final tasks = calendar == null
        ? const <TaskItem>[]
        : await calendar.watchTasks().first;
    final raw = buildWeeklyBriefingInput(
      now: DateTime.now(),
      notes: notes,
      events: events,
      tasks: tasks,
    );
    return ref.read(geminiServiceProvider).composeWeeklyBriefing(raw);
  }
}

class BriefingNotifier extends StringDailyCache {
  @override
  String get cacheKey => 'cache_briefing';

  @override
  Future<String> compute() async {
    // read: her not değişikliğinde brifingi yeniden üretme; günlük/Yenile ile.
    final notes = await ref.read(notesStreamProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final buffer = StringBuffer();

    // Bugünün ve yarının hatırlatıcıları
    buffer.writeln('HATIRLATICILAR:');
    var hasReminder = false;
    for (final note in notes) {
      final reminder = note.reminderAt;
      if (reminder == null || note.deletedAt != null) continue;
      if (reminder.isBefore(today) ||
          reminder.isAfter(tomorrow.add(const Duration(days: 1)))) {
        continue;
      }
      hasReminder = true;
      // Kilitli notun içeriği brifinge sızmasın; başlık yoksa jenerik ad.
      final label = note.displayTitle.trim().isNotEmpty
          ? note.displayTitle
          : note.locked
          ? '(kilitli not)'
          : note.toPlainText().split('\n').first;
      buffer.writeln(
        '- ${DateFormat('d MMM HH:mm').format(reminder)}: $label',
      );
    }
    if (!hasReminder) buffer.writeln('- (yok)');

    // Takvim ve görevler (TAKVIM F52.1): bugün, yarın, gecikmiş görevler.
    // Google etkinlikleri önbellekten (ağ beklenmez).
    final calendar = ref.read(calendarRepositoryProvider);
    final lines = calendarBriefingLines(
      now: now,
      events: [
        ...?(calendar == null ? null : await calendar.watchEvents().first),
        ...ref.read(googleCalendarEventsProvider),
      ],
      tasks: calendar == null ? const [] : await calendar.watchTasks().first,
      routines: calendar == null
          ? const []
          : await calendar.watchRoutines().first,
      routineLogs: calendar == null
          ? const {}
          : await calendar.watchRoutineLogs().first,
    );
    buffer.writeln('\nTAKVİM VE GÖREVLER:');
    if (lines.isEmpty) buffer.writeln('- (yok)');
    for (final l in lines.take(30)) {
      buffer.writeln(l);
    }

    // Son 3 günün notları
    buffer.writeln('\nSON NOTLAR:');
    final cutoff = now.subtract(const Duration(days: 3));
    var count = 0;
    for (final note in notes) {
      if (note.archivedAt != null || note.locked) continue;
      if (!((note.updatedAt ?? note.createdAt)?.isAfter(cutoff) ?? false)) {
        continue;
      }
      final text = note.toPlainText();
      buffer.writeln(
        '- ${text.length > 200 ? '${text.substring(0, 200)}…' : text}'
            .replaceAll('\n', ' / '),
      );
      if (++count >= 15) break;
    }
    if (count == 0) buffer.writeln('- (yok)');

    return ref.read(geminiServiceProvider).composeBriefing(buffer.toString());
  }
}

class BriefingScreen extends ConsumerStatefulWidget {
  const BriefingScreen({super.key, this.initialWeekly = false});

  final bool initialWeekly;

  @override
  ConsumerState<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends ConsumerState<BriefingScreen> {
  late bool _weekly = widget.initialWeekly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlimited = ref.watch(aiUnlimitedProvider);
    final value = _weekly
        ? ref.watch(weeklyBriefingProvider)
        : ref.watch(briefingProvider);
    final generatedToday = _weekly
        ? ref.read(weeklyBriefingProvider.notifier).generatedToday
        : ref.read(briefingProvider.notifier).generatedToday;

    void triggerRefresh() {
      if (_weekly) {
        ref.read(weeklyBriefingProvider.notifier).refresh();
      } else {
        ref.read(briefingProvider.notifier).refresh();
      }
    }

    void onRefresh() {
      if (!unlimited && generatedToday) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(l10n.aiGeneratedTodayInfo);
        return;
      }
      triggerRefresh();
    }

    final now = DateTime.now();
    final header = _weekly
        ? '${DateFormat('d MMM').format(now.subtract(const Duration(days: 6)))}'
              ' – ${DateFormat('d MMMM').format(now)}'
        : DateFormat('d MMMM EEEE').format(now);

    final needsManualGenerate =
        !unlimited && !generatedToday && !value.isLoading && !value.hasError;

    final switcher = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.s,
        AppSpace.l,
        AppSpace.xs,
      ),
      child: Wrap(
        spacing: AppSpace.s,
        children: [
          radioChip(
            ChoiceChip(
              key: const ValueKey('briefing-mode-daily'),
              label: Text(l10n.briefingDailyTab),
              selected: !_weekly,
              onSelected: (s) {
                if (s && _weekly) setState(() => _weekly = false);
              },
            ),
          ),
          radioChip(
            ChoiceChip(
              key: const ValueKey('briefing-mode-weekly'),
              label: Text(l10n.briefingWeeklyTab),
              selected: _weekly,
              onSelected: (s) {
                if (s && !_weekly) setState(() => _weekly = true);
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: HomeInBar(
        appBar: AppBar(
          title: Text(l10n.briefingTitle),
          actions: [
            if (!needsManualGenerate)
              IconButton(
                tooltip: l10n.refresh,
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switcher,
          Expanded(
            child: needsManualGenerate
                ? AiGeneratePrompt(
                    icon: _weekly
                        ? Icons.calendar_view_week_outlined
                        : Icons.wb_sunny_outlined,
                    buttonLabel: l10n.aiGenerate,
                    onGenerate: triggerRefresh,
                  )
                : AiTextResult(
                    value: value,
                    loadingText: _weekly
                        ? l10n.briefingWeeklyLoading
                        : l10n.briefingLoading,
                    emptyIcon: _weekly
                        ? Icons.calendar_view_week_outlined
                        : Icons.wb_sunny_outlined,
                    emptyTitle: _weekly
                        ? l10n.briefingWeeklyEmpty
                        : l10n.briefingEmpty,
                    header: header,
                    onRetry: onRefresh,
                    reportSource: _weekly ? 'weekly_briefing' : 'briefing',
                  ),
          ),
        ],
      ),
    );
  }
}
