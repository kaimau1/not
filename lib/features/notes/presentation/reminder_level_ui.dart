import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/reminder_level.dart';

/// Düzeyin simgesi (çipte ve seçicide aynı).
IconData reminderLevelIcon(ReminderLevel level) => switch (level) {
  ReminderLevel.low => Icons.notifications_none_rounded,
  ReminderLevel.normal => Icons.notifications_outlined,
  ReminderLevel.high => Icons.notifications_active_outlined,
  ReminderLevel.urgent => Icons.alarm_rounded,
};

String reminderLevelLabel(BuildContext context, ReminderLevel level) {
  final l10n = context.l10n;
  return switch (level) {
    ReminderLevel.low => l10n.reminderLevelLow,
    ReminderLevel.normal => l10n.reminderLevelNormal,
    ReminderLevel.high => l10n.reminderLevelHigh,
    ReminderLevel.urgent => l10n.reminderLevelUrgent,
  };
}

/// Az / orta / sık / acil seçimi (hatırlatıcı levhası ve görev levhası).
/// Altında seçilenin ne yaptığı tek satırla yazar.
class ReminderLevelPicker extends StatelessWidget {
  const ReminderLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selected = ReminderLevel.parse(value);
    final info = switch (selected) {
      ReminderLevel.low => l10n.reminderLevelLowInfo,
      ReminderLevel.normal => l10n.reminderLevelNormalInfo,
      ReminderLevel.high => l10n.reminderLevelHighInfo,
      ReminderLevel.urgent => l10n.reminderLevelUrgentInfo,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reminderLevelTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final level in ReminderLevel.values)
              ChoiceChip(
                key: ValueKey('reminder-level-${level.name}'),
                avatar: Icon(reminderLevelIcon(level), size: 18),
                label: Text(reminderLevelLabel(context, level)),
                selected: selected == level,
                onSelected: (_) => onChanged(level.id),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          info,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
