import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../data/calendar_repository.dart';
import '../data/google_calendar_sync.dart';
import '../domain/agenda.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import 'calendar_screen.dart' show calendarReminderNotesProvider;
import 'calendar_views.dart';
import 'month_grid.dart';

/// **TAKVİM ZEMİNİ** (kullanıcı isteği 2026-11-06: "dashboard'ın arka planını
/// takvim yap; başlıklar normal görünür ama not kartlarının geri kalanı
/// yüksek oranda saydamlaşır — arka plan seçiminde seçenek olarak").
///
/// Ana ekranın kart ızgarasının ARKASINDA bu ayın ızgarası: gün numarası,
/// bugünün halkası ve her günün ilk birkaç kaydı (etkinlik, görev,
/// hatırlatıcı — ajandayla aynı kaynak, `buildAgenda`). Kartlar bu kipte
/// `CardSeeThrough` ile saydamlaşır (bkz. note_card.dart).
///
/// Dokunulmaz (IgnorePointer): ızgara jestleri olduğu gibi kalır. Tek
/// RepaintBoundary — kaydırma karesinde yeniden çizilmez; yalnız takvim
/// verisi değişince kurulur (abonelik kart başına değil, burada TEK).
class CalendarBackdrop extends ConsumerWidget {
  const CalendarBackdrop({super.key, this.now});

  /// Test için "bugün".
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = CalendarData(
      events: [
        ...?ref.watch(eventsStreamProvider).value,
        ...ref.watch(googleCalendarEventsProvider),
      ],
      tasks: ref.watch(tasksStreamProvider).value ?? const <TaskItem>[],
      reminders: ref.watch(calendarReminderNotesProvider),
      routines: ref.watch(routinesStreamProvider).value ?? const [],
      routineLogs: ref.watch(routineLogsStreamProvider).value ?? const {},
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: CalendarBackdropGrid(
          data: data,
          today: startOfDay(now ?? DateTime.now()),
        ),
      ),
    );
  }
}

/// Saf çizim (sağlayıcısız; test edilebilir).
class CalendarBackdropGrid extends StatelessWidget {
  const CalendarBackdropGrid({
    super.key,
    required this.data,
    required this.today,
  });

  final CalendarData data;
  final DateTime today;

  /// Hücre başına en çok kaç kayıt adı yazılır (gerisi "+N").
  static const maxEntries = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final firstDow = material.firstDayOfWeekIndex;
    final month = monthOf(today);
    final start = gridStartFor(month, firstDow);
    final end = DateTime(start.year, start.month, start.day + 42);
    final agenda = data.range(start, end);
    final line = scheme.outlineVariant.withValues(alpha: 0.7);
    final faint = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    Widget cell(DateTime day) {
      final inMonth = day.month == month.month;
      final isToday = day == today;
      final entries = agenda[dayKey(day)] ?? const <AgendaEntry>[];
      final numberStyle = theme.textTheme.titleMedium?.copyWith(
        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
        color: isToday
            ? scheme.onPrimary
            : (inMonth ? scheme.onSurfaceVariant : faint),
      );
      return Container(
        decoration: BoxDecoration(
          color: isToday ? scheme.primary.withValues(alpha: 0.08) : null,
          border: Border(
            top: BorderSide(color: line, width: 0.6),
            left: BorderSide(color: line, width: 0.6),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 3, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: isToday
                  ? BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Text('${day.day}', style: numberStyle),
            ),
            const SizedBox(height: 2),
            for (final e in entries.take(maxEntries))
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 10,
                      margin: const EdgeInsetsDirectional.only(end: 3),
                      decoration: BoxDecoration(
                        color: entryColor(e, scheme),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entryTitle(e, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: inMonth ? scheme.onSurfaceVariant : faint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (entries.length > maxEntries)
              Text(
                '+${entries.length - maxEntries}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: faint,
                ),
              ),
          ],
        ),
      );
    }

    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Text(
                DateFormat.yMMMM().format(month),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Text(
                      material.narrowWeekdays[(firstDow + i) % 7],
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var row = 0; row < 6; row++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: ClipRect(
                          child: cell(
                            DateTime(
                              start.year,
                              start.month,
                              start.day + row * 7 + col,
                            ),
                          ),
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
