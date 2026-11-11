import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../domain/day_key.dart';

/// Ayın ilk günü.
DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

/// Ay ızgarasının ilk hücresi (yerel ayarın haftabaşına göre) — 6 × 7 hücre.
DateTime gridStartFor(DateTime month, int firstDayOfWeekIndex) {
  final first = monthOf(month);
  // DateTime.weekday: 1 = Pazartesi … 7 = Pazar; Material: 0 = Pazar.
  final offset = (first.weekday % 7 - firstDayOfWeekIndex + 7) % 7;
  return DateTime(first.year, first.month, 1 - offset);
}

/// **AY IZGARASI** (TAKVIM_PLANI F47.2/F47.3, K7: kendi çizimimiz). Dolu
/// günlerin altında nokta; yatay kaydırma ay değiştirir. Hücre başına
/// sağlayıcı/abonelik YOK — [busy] üstten hazır gelir.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onMonthChange,
    this.showHeader = true,
    this.swipeEnabled = true,
    this.now,
  });

  final DateTime month;
  final DateTime selected;

  /// Kaydı olan günlerin anahtarları (`YYYY-MM-DD`).
  final Set<String> busy;
  final ValueChanged<DateTime> onSelect;

  /// −1 önceki ay, +1 sonraki ay.
  final ValueChanged<int> onMonthChange;
  final bool showHeader;

  /// Yatay kaydırmayla ay değişimi (Ayarlar → Takvim kaydırma).
  final bool swipeEnabled;

  /// Test için "bugün".
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final firstDow = material.firstDayOfWeekIndex;
    final start = gridStartFor(month, firstDow);
    final today = startOfDay(now ?? DateTime.now());
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: !swipeEnabled
          ? null
          : (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -200) onMonthChange(1);
              if (v > 200) onMonthChange(-1);
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader)
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.calendarPrevMonth,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => onMonthChange(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM().format(month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.calendarNextMonth,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => onMonthChange(1),
                  ),
                ],
              ),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          material.narrowWeekdays[(firstDow + i) % 7],
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var w = 0; w < 6; w++)
              Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: _DayCell(
                        day: DateTime(
                          start.year,
                          start.month,
                          start.day + w * 7 + d,
                        ),
                        inMonth:
                            DateTime(
                              start.year,
                              start.month,
                              start.day + w * 7 + d,
                            ).month ==
                            month.month,
                        today: today,
                        selected: selected,
                        busy: busy,
                        onTap: onSelect,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final DateTime today;
  final DateTime selected;
  final Set<String> busy;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final isSelected = day == startOfDay(selected);
    final hasItems = busy.contains(dayKey(day));
    final fg = isSelected
        ? scheme.onPrimary
        : isToday
        ? scheme.primary
        : inMonth
        ? scheme.onSurface
        : scheme.onSurfaceVariant.withValues(alpha: 0.55);
    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.yMMMMEEEEd().format(day),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(day),
        radius: 22,
        child: SizedBox(
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: fg,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasItems
                      ? (inMonth
                            ? scheme.primary
                            : scheme.primary.withValues(alpha: 0.4))
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
