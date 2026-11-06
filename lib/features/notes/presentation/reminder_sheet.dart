import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../domain/reminder_repeat.dart';

/// Hatırlatıcı levhasının sonucu: [at] null ise hatırlatıcı KALDIRILDI.
typedef ReminderChoice = ({DateTime? at, String repeat});

/// **TEK HATIRLATICI LEVHASI** (kullanıcı isteği 2026-11-06: "hatırlatmaları
/// ayarlamak, düzenlemek, silmek çok zor; ekrana uymuyor, alt tarafta telefon
/// düğmelerinin altına giriyor — baştan tasarla, kolaylaştır").
///
/// Eski akış zincirleme pencerelerdi: hızlı seçim levhası → (takvim → saat)
/// → HER SEFERİNDE tekrar penceresi; kaldırmak ise çipteki küçük ✕'ti. Artık
/// her şey TEK levhada ve hiçbir seçim levhayı kapatmaz:
/// - en üstte seçili zaman büyük yazıyla (ne kurduğunu hep görür),
/// - hızlı çipler (1 saat sonra · bu akşam · yarın · gelecek hafta),
/// - tarih ve saat iki düğme (yalnız değiştirilen açılır),
/// - tekrar çipleri satır içinde,
/// - altta "Kaldır" (yalnız varsa) ve "Kaydet"; vazgeç = aşağı çek / geri.
/// Kaydırılabilir; alt güvenli alan [showAppSheet]'te.
///
/// null = vazgeçildi.
Future<ReminderChoice?> showReminderSheet(
  BuildContext context, {
  DateTime? current,
  String repeat = '',
}) => showAppSheet<ReminderChoice>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => ReminderSheet(current: current, repeat: repeat),
);

@visibleForTesting
class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key, this.current, this.repeat = ''});

  final DateTime? current;
  final String repeat;

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late DateTime _at = _initial();
  late RepeatKind _kind = ReminderRepeat.parse(widget.repeat).kind;
  late final Set<int> _days = {
    ...(ReminderRepeat.parse(widget.repeat).kind == RepeatKind.weekly
        ? ReminderRepeat.parse(widget.repeat).days
        : [_at.weekday]),
  };

  DateTime _initial() {
    final now = DateTime.now();
    final c = widget.current;
    if (c != null && c.isAfter(now)) return c;
    // Yeni (ya da geçmişte kalmış) hatırlatıcı: bir saat sonrası, tam dakika.
    final t = now.add(const Duration(hours: 1));
    return DateTime(t.year, t.month, t.day, t.hour, t.minute);
  }

  bool get _past => !_at.isAfter(DateTime.now());

  ReminderRepeat _repeat() => switch (_kind) {
    RepeatKind.none => ReminderRepeat.none,
    RepeatKind.daily => ReminderRepeat.daily,
    RepeatKind.weekdays => ReminderRepeat.weekdays,
    RepeatKind.weekly => ReminderRepeat.weekly(_days),
    RepeatKind.monthly => ReminderRepeat.monthly.anchoredTo(_at),
    RepeatKind.yearly => ReminderRepeat.yearly.anchoredTo(_at),
  };

  /// Hızlı seçenekler: (ad, zaman). Geçmişe düşen "bu akşam" gösterilmez.
  List<(String, DateTime)> _quick(AppLocalizations l10n) {
    final now = DateTime.now();
    final inHour = now.add(const Duration(hours: 1));
    final tonight = DateTime(now.year, now.month, now.day, 18);
    final tomorrow = now.add(const Duration(days: 1));
    final week = now.add(const Duration(days: 7));
    return [
      (
        l10n.reminderQuickInHour,
        DateTime(
          inHour.year,
          inHour.month,
          inHour.day,
          inHour.hour,
          inHour.minute,
        ),
      ),
      if (tonight.isAfter(now)) (l10n.reminderQuickTonight, tonight),
      (
        l10n.reminderQuickTomorrow,
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9),
      ),
      (
        l10n.reminderQuickNextWeek,
        DateTime(week.year, week.month, week.day, 9),
      ),
    ];
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _at.isBefore(now) ? now : _at,
      // Geçmiş TARİH seçilemez: geçmişe kurulan hatırlatıcı hiç planlanmaz.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    setState(
      () =>
          _at = DateTime(date.year, date.month, date.day, _at.hour, _at.minute),
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (time == null || !mounted) return;
    setState(
      () =>
          _at = DateTime(_at.year, _at.month, _at.day, time.hour, time.minute),
    );
  }

  void _save() {
    if (_past) return;
    Navigator.pop<ReminderChoice>(context, (
      at: _at,
      repeat: _repeat().encode(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('d MMMM EEEE', locale).format(_at);
    final timeLabel = DateFormat('HH:mm', locale).format(_at);
    final names = DateFormat.E(locale).dateSymbols.SHORTWEEKDAYS;
    final quick = _quick(l10n);
    String kindLabel(RepeatKind k) => switch (k) {
      RepeatKind.none => l10n.repeatNone,
      RepeatKind.daily => l10n.repeatDaily,
      RepeatKind.weekdays => l10n.repeatWeekdays,
      RepeatKind.weekly => l10n.repeatWeekly,
      RepeatKind.monthly => l10n.repeatMonthly,
      RepeatKind.yearly => l10n.repeatYearly,
    };
    final hasExisting = widget.current != null;

    return Padding(
      // Klavye yok; yine de yatay ekranda taşmasın diye kaydırılır.
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reminderSheetTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            // SEÇİLİ ZAMAN — büyük, tek bakışta.
            Container(
              key: const ValueKey('reminder-sheet-summary'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: _past ? scheme.errorContainer : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _kind == RepeatKind.none ? Icons.alarm : Icons.repeat,
                    color: _past
                        ? scheme.onErrorContainer
                        : scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timeLabel,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _past
                                ? scheme.onErrorContainer
                                : scheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _past ? l10n.reminderInPast : dayLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _past
                                ? scheme.onErrorContainer
                                : scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, at) in quick)
                  ChoiceChip(
                    label: Text(label),
                    selected: at == _at,
                    onSelected: (_) => setState(() => _at = at),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('reminder-sheet-date'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      DateFormat('d MMM EEE', locale).format(_at),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('reminder-sheet-time'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(timeLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.repeatTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in RepeatKind.values)
                  ChoiceChip(
                    key: ValueKey('reminder-repeat-${k.name}'),
                    label: Text(kindLabel(k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            if (_kind == RepeatKind.weekly) ...[
              const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            Row(
              children: [
                if (hasExisting)
                  TextButton.icon(
                    key: const ValueKey('reminder-sheet-remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => Navigator.pop<ReminderChoice>(context, (
                      at: null,
                      repeat: '',
                    )),
                    icon: const Icon(Icons.alarm_off_outlined),
                    label: Text(l10n.reminderSheetRemove),
                  ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('reminder-sheet-save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 48),
                  ),
                  onPressed: _past ? null : _save,
                  child: Text(l10n.reminderSheetSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Levha sonucunu nota uygular — not ekranı ve Hatırlatıcılar ekranı aynı
/// yolu kullanır. Kaldırmada "Geri al" bildirimi (yanlış dokunuş ucuz olsun).
/// [write] (zaman, tekrar) yazar; zaman null = kaldır.
void applyReminderChoice(
  BuildContext context, {
  required ReminderChoice choice,
  required DateTime? previousAt,
  required String previousRepeat,
  required void Function(DateTime? at, String repeat) write,
}) {
  write(choice.at, choice.repeat);
  if (choice.at == null && previousAt != null && context.mounted) {
    showUndoSnackBar(
      context,
      message: context.l10n.reminderRemoved,
      undoLabel: context.l10n.undo,
      onUndo: () => write(previousAt, previousRepeat),
    );
  }
}
