import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../calendar/presentation/line_task_chip.dart' show pickLineTime;

/// Süre levhasının sonucu: [at] null = süre KALDIRILDI.
typedef ExpiryChoice = ({DateTime? at});

/// **ZAMANLI NOT** (kullanıcı isteği 2026-11-16: "not bir zaman kadar kalır
/// sonra arşivlenir"). Hazır süreler + tarih/saat seç + kaldır. null = vazgeçildi.
/// [now] testler için.
Future<ExpiryChoice?> pickNoteExpiry(
  BuildContext context, {
  DateTime? current,
  DateTime? now,
}) async {
  final l10n = context.l10n;
  final t = now ?? DateTime.now();
  final presets = <String, DateTime>{
    '1d': t.add(const Duration(days: 1)),
    '3d': t.add(const Duration(days: 3)),
    '1w': t.add(const Duration(days: 7)),
    '1m': DateTime(t.year, t.month + 1, t.day, t.hour, t.minute),
  };
  final action = await showActionMenuSheet(
    context,
    ActionMenu(
      title: l10n.noteExpiry,
      quick: [
        MenuAction('1d', l10n.noteExpiryDay, Icons.hourglass_top),
        MenuAction('3d', l10n.noteExpiry3Days, Icons.hourglass_top),
        MenuAction('1w', l10n.noteExpiryWeek, Icons.hourglass_bottom),
        MenuAction('1m', l10n.noteExpiryMonth, Icons.hourglass_bottom),
        MenuAction('pick', l10n.noteExpiryPick, Icons.edit_calendar_outlined),
      ],
      sections: [
        if (current != null)
          MenuSection(noteExpiryChipText(l10n, current), [
            MenuAction(
              'remove',
              l10n.noteExpiryRemove,
              Icons.hourglass_disabled_outlined,
            ),
          ]),
      ],
    ),
  );
  if (action == null || !context.mounted) return null;
  if (action == 'remove') return (at: null);
  if (action == 'pick') {
    final at = await pickLineTime(context, initial: current);
    return at == null ? null : (at: at);
  }
  final at = presets[action];
  return at == null ? null : (at: at);
}

/// "16 Kas 14:00 arşivlenir" — editör çipi ve levha başlığı.
String noteExpiryChipText(AppLocalizations l10n, DateTime at) =>
    l10n.noteExpiryChip(DateFormat('d MMM HH:mm').format(at));

/// Kartın kısa kalan süresi: "2 g" / "5 sa" / "30 dk".
String noteExpiryLeft(AppLocalizations l10n, DateTime at, DateTime now) {
  final left = at.difference(now);
  if (left.inDays >= 1) return l10n.noteExpiryLeftDays(left.inDays);
  if (left.inHours >= 1) return l10n.noteExpiryLeftHours(left.inHours);
  return l10n.noteExpiryLeftMinutes(left.inMinutes < 1 ? 1 : left.inMinutes);
}
