import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../notes/domain/note.dart';
import '../domain/agenda.dart';
import '../domain/day_key.dart';
import '../domain/holidays.dart';
import 'calendar_views.dart';
import 'pinch_zoom.dart';

/// **HAFTA PANOSU** (kullanıcı isteği 2026-11-21: "güne çift tıklayınca onun
/// haftası açılsın ama hafta eski görünümde değil, daha büyük kareler
/// şeklinde, içerisinde not önizlemeleri olmalı"): haftanın 7 günü büyük
/// kâğıt karolarda (telefonda 2 sütun × 4 satır, genişte 4 × 2); karoda
/// günün kayıtları (saat + başlık) ve notların başlık + ilk satır önizlemesi.
/// Sekizinci yuva haftanın özeti. Saat çizelgesi gün sayfasında (karo
/// başlığına dokun).
///
/// Kaydırma yok: satır yükseklikleri sabit, sığmayan kayıt "+N" olur
/// (yerleşim hesabı karo başına bir kez, hücre içi ölçüm yok).
class WeekBoardPage extends StatelessWidget {
  const WeekBoardPage({
    super.key,
    required this.weekStart,
    required this.data,
    required this.today,
    required this.selected,
    required this.targets,
    required this.onDayTap,
    required this.onDayOpen,
    required this.onDayLongPress,
    required this.onEntryTap,
    required this.onNoteTap,
  });

  final DateTime weekStart;
  final CalendarData data;
  final DateTime today;
  final DateTime selected;
  final ZoomTargets targets;

  /// Karoya dokunuş: günün ayrıntısı (levha).
  final ValueChanged<DateTime> onDayTap;

  /// Karo başlığına dokunuş ya da karoya ÇİFT dokunuş: o günün saat
  /// çizelgesi (gün sayfası).
  final ValueChanged<DateTime> onDayOpen;
  final ValueChanged<DateTime> onDayLongPress;
  final ValueChanged<AgendaEntry> onEntryTap;
  final void Function(Note note, DateTime day) onNoteTap;

  @override
  Widget build(BuildContext context) {
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    final agenda = data.range(weekStart, end);
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    ];
    var plans = 0;
    var notes = 0;
    for (final d in days) {
      final k = dayKey(d);
      for (final e in agenda[k] ?? const <AgendaEntry>[]) {
        if (e is ReminderEntry && e.isDayLink) {
          notes++;
        } else {
          plans++;
        }
      }
    }
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 840 ? 4 : 2;
        final rows = (8 / cols).ceil();
        Widget slot(int i) {
          if (i >= 7) {
            return _WeekSummaryTile(plans: plans, notes: notes);
          }
          final d = days[i];
          final k = dayKey(d);
          return _WeekDayTile(
            key: targets.keyFor(('week-board-day', k), d),
            day: d,
            today: today,
            selected: selected,
            entries: agenda[k] ?? const [],
            holiday: data.holidays.on(d),
            onTap: onDayTap,
            onOpen: onDayOpen,
            onLongPress: onDayLongPress,
            onEntryTap: onEntryTap,
            onNoteTap: onNoteTap,
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s,
            AppSpace.xs,
            AppSpace.s,
            AppSpace.s,
          ),
          child: Column(
            spacing: AppSpace.s,
            children: [
              for (var r = 0; r < rows; r++)
                Expanded(
                  child: Row(
                    spacing: AppSpace.s,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < cols; col++)
                        Expanded(child: slot(r * cols + col)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Karodaki bir satırın türü ve sabit yüksekliği (yazı ölçeği ile çarpılır).
const _kEntryRow = 20.0;
const _kNoteRow = 42.0;
const _kMoreRow = 16.0;

sealed class _Row {
  const _Row();
  double get height;
}

class _EntryRow extends _Row {
  const _EntryRow(this.entry);
  final AgendaEntry entry;
  @override
  double get height => entry is ReminderEntry ? _kNoteRow : _kEntryRow;
}

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    super.key,
    required this.day,
    required this.today,
    required this.selected,
    required this.entries,
    required this.holiday,
    required this.onTap,
    required this.onOpen,
    required this.onLongPress,
    required this.onEntryTap,
    required this.onNoteTap,
  });

  final DateTime day;
  final DateTime today;
  final DateTime selected;
  final List<AgendaEntry> entries;
  final Holiday? holiday;
  final ValueChanged<DateTime> onTap;
  final ValueChanged<DateTime> onOpen;
  final ValueChanged<DateTime> onLongPress;
  final ValueChanged<AgendaEntry> onEntryTap;
  final void Function(Note note, DateTime day) onNoteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final isToday = day == today;
    final isSelected = day == selected && !isToday;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    final past = day.isBefore(today);
    // YALNIZ GÜNE BAĞLI NOTLAR (kullanıcı isteği 2026-11-22: "hafta
    // görünümünde notlar bağlanmamış olsa bile günlerde görülüyor, olmamalı;
    // o gün yazılanlar alt paneldeki listede yeter"): karoda günün kayıtları
    // ve "Bu güne not"la bağlı notlar (ajandada `ReminderEntry.isDayLink`).
    final rows = <_Row>[for (final e in entries) _EntryRow(e)];
    final tokens = AppTokens.fromTheme(theme);
    // HAFTA SONU RENKLİ (2026-11-22): ay ızgarasıyla aynı dil — hafta sonu
    // karosu ikincil tonla boyanır, numara/gün adı ikincil renkte; geçmiş
    // günler sönük yazılır, bugün dolgulu daire + vurgulu zemin.
    final weekendBg = Color.alphaBlend(
      scheme.secondaryContainer.withValues(alpha: AppAlpha.soft),
      tokens.card,
    );
    final dayFg = isToday
        ? scheme.onPrimary
        : weekend
        ? scheme.secondary
        : past
        ? scheme.onSurfaceVariant
        : scheme.onSurface;

    // Hafif dokunuş alanları (GestureDetector): hafta çevrilirken 7 karo
    // kurulur; InkWell/Material karo başına ~20 widget ekliyordu (S22).
    final header = GestureDetector(
      key: ValueKey('week-board-open-${dayKey(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(day),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xs,
          AppSpace.xxs,
          AppSpace.xs,
          AppSpace.xxs,
        ),
        child: Row(
          spacing: AppSpace.s,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle)
                  : null,
              child: Text(
                '${day.day}',
                style: text.sheetTitle.copyWith(
                  height: 1,
                  color: dayFg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Text(
                DateFormat.EEEE().format(day),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.label.copyWith(
                  color: isToday
                      ? scheme.primary
                      : weekend
                      ? scheme.secondary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      key: ValueKey('week-board-tile-${dayKey(day)}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(day),
      // Karoya çift dokunuş = gün sayfası (kullanıcı isteği 2026-11-22;
      // eskiden yalnız üstteki tarih alanı açıyordu).
      onDoubleTap: () => onOpen(day),
      onLongPress: () => onLongPress(day),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isToday
              ? scheme.primaryContainer.withValues(alpha: AppAlpha.soft)
              : weekend
              ? weekendBg
              : tokens.card,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: isToday || isSelected
                ? scheme.primary
                : weekend
                ? scheme.secondary.withValues(alpha: AppAlpha.disabled)
                : tokens.hairline,
            width: isToday || isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              if (holiday case final holiday?)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xxs),
                  child: HolidayChip(
                    holiday: holiday,
                    full: true,
                    height: kMonthChipOneLineWide * scale,
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    // Sığan satırlar (sabit yükseklik), kalanı "+N".
                    var room = box.maxHeight;
                    final shown = <_Row>[];
                    for (var i = 0; i < rows.length; i++) {
                      final h = rows[i].height * scale + AppSpace.xxs;
                      final left = rows.length - i - 1;
                      final need = h + (left > 0 ? _kMoreRow * scale : 0);
                      if (need > room) break;
                      shown.add(rows[i]);
                      room -= h;
                    }
                    final more = rows.length - shown.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.xxs,
                      children: [
                        for (final r in shown)
                          SizedBox(
                            height: r.height * scale,
                            child: switch (r) {
                              _EntryRow(:final entry) => _entry(
                                context,
                                entry,
                                scheme,
                                text,
                                l10n,
                              ),
                            },
                          ),
                        if (more > 0)
                          Text(
                            l10n.calendarMoreCount(more),
                            style: text.meta.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    AgendaEntry e,
    ColorScheme scheme,
    AppText text,
    AppLocalizations l10n,
  ) {
    final color = entryColor(e, scheme);
    if (e is ReminderEntry) {
      return _NotePreview(
        note: e.note,
        accent: color,
        time: e.allDay ? null : e.at,
        onTap: () => onNoteTap(e.note, day),
      );
    }
    final time = e.allDay ? null : e.at;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onEntryTap(e),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppAlpha.pressed),
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          child: Row(
            spacing: AppSpace.xs,
            children: [
              if (time != null)
                Text(
                  DateFormat.Hm().format(time),
                  style: text.meta.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              Expanded(
                child: Text(
                  entryTitle(e, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppWeight.medium,
                    decoration: e is TaskEntry && e.task.completed
                        ? TextDecoration.lineThrough
                        : null,
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

/// Notun mini önizlemesi: başlık + ilk satır (kilitli notta yalnız başlık).
class _NotePreview extends StatelessWidget {
  const _NotePreview({
    required this.note,
    required this.accent,
    required this.onTap,
    this.time,
  });

  final Note note;
  final Color accent;
  final DateTime? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final title = note.displayTitle.trim();
    final lines = note.locked
        ? <String>[]
        : [
            for (final l in note.toPlainText().split('\n'))
              if (l.trim().isNotEmpty) l.trim(),
          ];
    // Başlık yoksa ilk satır başlık olur; önizleme başlıktan sonraki satır.
    if (title.isNotEmpty && lines.isNotEmpty && lines.first == title) {
      lines.removeAt(0);
    }
    final head = title.isNotEmpty
        ? title
        : lines.isNotEmpty
        ? lines.removeAt(0)
        : l10n.untitledNote;
    final snippet = lines.isNotEmpty ? lines.first : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.xxs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                spacing: AppSpace.xs,
                children: [
                  Icon(
                    note.locked
                        ? Icons.lock_outline
                        : Icons.sticky_note_2_outlined,
                    size: 12,
                    color: accent,
                  ),
                  if (time != null)
                    Text(
                      DateFormat.Hm().format(time!),
                      style: text.meta.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      head,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.meta.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                  ),
                ],
              ),
              if (snippet.isNotEmpty)
                Text(
                  snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sekizinci yuva: haftanın kısa özeti.
class _WeekSummaryTile extends StatelessWidget {
  const _WeekSummaryTile({required this.plans, required this.notes});

  final int plans;
  final int notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final l10n = context.l10n;
    return DecoratedBox(
      key: const ValueKey('week-board-summary'),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: tokens.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpace.xs,
          children: [
            Text(
              l10n.calendarWeekSummaryTitle,
              style: text.section,
            ),
            Text(
              l10n.calendarWeekSummaryPlans(math.max(0, plans)),
              style: text.label.copyWith(color: scheme.onSurface),
            ),
            Text(
              l10n.calendarWeekSummaryNotes(math.max(0, notes)),
              style: text.label.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
