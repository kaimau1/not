import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../domain/reminder_repeat.dart';

/// Tekrarın okunur adı ("Her gün", "Her hafta: Pzt, Çar"…) — F18.14.
String reminderRepeatLabel(AppLocalizations l10n, ReminderRepeat r) {
  switch (r.kind) {
    case RepeatKind.none:
      return l10n.repeatNone;
    case RepeatKind.daily:
      return l10n.repeatDaily;
    case RepeatKind.weekdays:
      return l10n.repeatWeekdays;
    case RepeatKind.weekly:
      final names = DateFormat.E().dateSymbols.SHORTWEEKDAYS;
      // SHORTWEEKDAYS pazardan başlar (0 = Pazar); ISO 7 = Pazar.
      final days = [for (final d in r.days) names[d % 7]].join(', ');
      return l10n.repeatWeeklyOn(days);
    case RepeatKind.monthly:
      return l10n.repeatMonthly;
    case RepeatKind.yearly:
      return l10n.repeatYearly;
  }
}

/// Tekrar seçimi; null = vazgeçildi. [anchor] seçilen çalma anı (haftalık
/// varsayılan günü ve aylık/yıllık günü ondan).
Future<ReminderRepeat?> pickReminderRepeat(
  BuildContext context, {
  required ReminderRepeat current,
  required DateTime anchor,
}) {
  return showDialog<ReminderRepeat>(
    context: context,
    builder: (ctx) => _RepeatDialog(current: current, anchor: anchor),
  );
}

class _RepeatDialog extends StatefulWidget {
  const _RepeatDialog({required this.current, required this.anchor});
  final ReminderRepeat current;
  final DateTime anchor;

  @override
  State<_RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<_RepeatDialog> {
  late RepeatKind _kind = widget.current.kind;
  late final Set<int> _days = widget.current.kind == RepeatKind.weekly
      ? widget.current.days.toSet()
      : {widget.anchor.weekday};

  ReminderRepeat _result() => switch (_kind) {
    RepeatKind.none => ReminderRepeat.none,
    RepeatKind.daily => ReminderRepeat.daily,
    RepeatKind.weekdays => ReminderRepeat.weekdays,
    RepeatKind.weekly => ReminderRepeat.weekly(_days),
    RepeatKind.monthly => ReminderRepeat.monthly.anchoredTo(widget.anchor),
    RepeatKind.yearly => ReminderRepeat.yearly.anchoredTo(widget.anchor),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = DateFormat.E().dateSymbols.SHORTWEEKDAYS;
    String label(RepeatKind k) => switch (k) {
      RepeatKind.none => l10n.repeatNone,
      RepeatKind.daily => l10n.repeatDaily,
      RepeatKind.weekdays => l10n.repeatWeekdays,
      RepeatKind.weekly => l10n.repeatWeekly,
      RepeatKind.monthly => l10n.repeatMonthly,
      RepeatKind.yearly => l10n.repeatYearly,
    };
    return AlertDialog(
      title: Text(l10n.repeatTitle),
      content: SingleChildScrollView(
        child: RadioGroup<RepeatKind>(
          groupValue: _kind,
          onChanged: (v) => setState(() => _kind = v ?? RepeatKind.none),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in RepeatKind.values) ...[
                RadioListTile<RepeatKind>(
                  contentPadding: EdgeInsets.zero,
                  value: k,
                  title: Text(label(k)),
                ),
                if (k == RepeatKind.weekly && _kind == RepeatKind.weekly)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(names[d % 7]),
                          selected: _days.contains(d),
                          onSelected: (on) => setState(() {
                            if (on) {
                              _days.add(d);
                            } else if (_days.length > 1) {
                              _days.remove(d);
                            }
                          }),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _result()),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
