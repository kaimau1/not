import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../smart_lists/domain/smart_item_meta.dart';
import '../../domain/list_mode.dart';
import '../../domain/note_item.dart';

@immutable
class ItemQuickMetaResult {
  const ItemQuickMetaResult({
    this.priority,
    this.dueDate,
    this.clearDueDate = false,
    this.toggleFocus = false,
    this.openPriceSheet = false,
    this.triggerBreakdown = false,
  });

  final ItemPriority? priority;
  final DateTime? dueDate;
  final bool clearDueDate;
  final bool toggleFocus;
  final bool openPriceSheet;
  final bool triggerBreakdown;
}

/// Kaydırmasız (swipe-free) madde ayrıntı ve hızlı işlem levhası.
///
/// Tek dokunuşla erteleme (Bugün / Yarın / Gelecek hafta / Tarih seç),
/// öncelik seçimi, proje odak sabitleme, fiyat düzenleme ve rutin kipinde
/// son 30 gün ısı haritası sunar.
Future<ItemQuickMetaResult?> showItemQuickMetaSheet(
  BuildContext context, {
  required NoteItem item,
  required ListMode mode,
  bool isFocused = false,
  bool canBreakdown = false,
}) => showAppSheet<ItemQuickMetaResult>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ItemQuickMetaSheet(
    item: item,
    mode: mode,
    isFocused: isFocused,
    canBreakdown: canBreakdown,
  ),
);

class _ItemQuickMetaSheet extends StatelessWidget {
  const _ItemQuickMetaSheet({
    required this.item,
    required this.mode,
    required this.isFocused,
    required this.canBreakdown,
  });

  final NoteItem item;
  final ListMode mode;
  final bool isFocused;
  final bool canBreakdown;

  DateTime _dayOffset(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = item.dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !context.mounted) return;
    Navigator.pop(
      context,
      ItemQuickMetaResult(
        dueDate: DateTime(picked.year, picked.month, picked.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final text = AppText.of(theme);

    String priorityLabel(ItemPriority p) => switch (p) {
      ItemPriority.none => l10n.itemPriorityNone,
      ItemPriority.low => l10n.quickDropPriorityLow,
      ItemPriority.medium => l10n.quickDropPriorityMedium,
      ItemPriority.high => l10n.quickDropPriorityHigh,
      ItemPriority.urgent => l10n.quickDropPriorityUrgent,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: item.text.trim().isEmpty
                ? l10n.itemQuickMeta
                : item.text.trim(),
          ),
          if (mode == ListMode.routine) ...[
            _RoutineHeatmapCard(item: item),
            const SizedBox(height: AppSpace.m),
          ],
          Text(
            l10n.itemQuickDueDate,
            style: text.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              ActionChip(
                key: const ValueKey('meta-due-today'),
                avatar: const Icon(Icons.today_outlined, size: 16),
                label: Text(l10n.itemDueToday),
                onPressed: () {
                  AppHaptics.tick();
                  Navigator.pop(
                    context,
                    ItemQuickMetaResult(dueDate: _dayOffset(0)),
                  );
                },
              ),
              ActionChip(
                key: const ValueKey('meta-due-tomorrow'),
                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: Text(l10n.itemDueTomorrow),
                onPressed: () {
                  AppHaptics.tick();
                  Navigator.pop(
                    context,
                    ItemQuickMetaResult(dueDate: _dayOffset(1)),
                  );
                },
              ),
              ActionChip(
                key: const ValueKey('meta-due-next-week'),
                avatar: const Icon(Icons.date_range_outlined, size: 16),
                label: Text(l10n.itemDueNextWeek),
                onPressed: () {
                  AppHaptics.tick();
                  Navigator.pop(
                    context,
                    ItemQuickMetaResult(dueDate: _dayOffset(7)),
                  );
                },
              ),
              ActionChip(
                key: const ValueKey('meta-due-pick'),
                avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text(
                  item.dueDate != null
                      ? DateFormat(
                          'd MMM',
                          l10n.localeName,
                        ).format(item.dueDate!)
                      : l10n.itemQuickDueDate,
                ),
                onPressed: () => _pickDate(context),
              ),
              if (item.dueDate != null)
                ActionChip(
                  key: const ValueKey('meta-due-clear'),
                  avatar: const Icon(Icons.close_rounded, size: 16),
                  label: Text(l10n.itemDueClear),
                  onPressed: () {
                    AppHaptics.tick();
                    Navigator.pop(
                      context,
                      const ItemQuickMetaResult(clearDueDate: true),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Text(
            l10n.itemQuickPriority,
            style: text.label.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final p in ItemPriority.values)
                ChoiceChip(
                  key: ValueKey('meta-priority-${p.name}'),
                  label: Text(priorityLabel(p)),
                  selected: item.priority == p,
                  onSelected: (_) {
                    AppHaptics.tick();
                    Navigator.pop(context, ItemQuickMetaResult(priority: p));
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            children: [
              if (mode == ListMode.shopping || mode == ListMode.general)
                FilledButton.tonalIcon(
                  key: const ValueKey('meta-edit-price'),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(l10n.itemQuickPrice),
                  onPressed: () => Navigator.pop(
                    context,
                    const ItemQuickMetaResult(openPriceSheet: true),
                  ),
                ),
              if (mode == ListMode.project)
                FilledButton.tonalIcon(
                  key: const ValueKey('meta-toggle-focus'),
                  icon: Icon(
                    isFocused
                        ? Icons.center_focus_weak_outlined
                        : Icons.center_focus_strong_outlined,
                    size: 18,
                  ),
                  label: Text(
                    isFocused ? l10n.itemQuickUnfocus : l10n.itemQuickFocus,
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    const ItemQuickMetaResult(toggleFocus: true),
                  ),
                ),
              if (canBreakdown)
                FilledButton.tonalIcon(
                  key: const ValueKey('meta-breakdown'),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(l10n.itemBreakdownAction),
                  onPressed: () => Navigator.pop(
                    context,
                    const ItemQuickMetaResult(triggerBreakdown: true),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rutin maddesi için `item.doneDays` tek gerçek kaynağından 30 günlük ısı haritası.
class _RoutineHeatmapCard extends StatelessWidget {
  const _RoutineHeatmapCard({required this.item});

  final NoteItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meta = HabitItemMeta.fromItem(item);
    final doneSet = meta.doneDays.toSet();
    final streak = item.streakCountAt(today);
    final best = item.bestStreak;

    return DecoratedBox(
      key: const ValueKey('routine-heatmap-card'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: AppIconSize.s,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  l10n.routineStreakDays(streak),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppWeight.strong,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.routineBestStreak(best),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            Text(
              l10n.routineLast30Days,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 29; i >= 0; i--)
                  () {
                    final day = today.subtract(Duration(days: i));
                    final done = doneSet.contains(isoDayKeyOf(day));
                    return SizedBox(
                      width: 16,
                      height: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: done
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
