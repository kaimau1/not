import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';
import '../../shopping/presentation/shop_budget_bar.dart';
import '../domain/smart_item_meta.dart';
import 'habit_tracker_workspace.dart';
import 'moving_planner_workspace.dart';
import 'packing_planner_workspace.dart';
import 'smart_domain_workspace.dart';
import 'workout_planner_workspace.dart';

/// Editör başlığının altındaki tek hapın simgesi.
IconData smartWorkspaceIcon(SmartListKind kind) =>
    kSmartKindSpecs[kind]?.icon ?? Icons.auto_awesome_outlined;

/// Editör başlığının altındaki tek hapın kısa canlı özeti.
String smartWorkspacePillLabel(
  Note note,
  SmartListKind kind,
  AppLocalizations l10n,
) {
  final items = [
    for (final i in note.items)
      if (!i.header && i.text.trim().isNotEmpty) i,
  ];
  final done = items.where((i) => i.checked).length;
  final total = items.length;
  return switch (kind) {
    SmartListKind.habits => () {
      final todayKey = isoDayKey(DateTime.now());
      final todayDone = items
          .where((i) => HabitItemMeta.fromItem(i).isDoneOn(todayKey))
          .length;
      return l10n.smartPillHabit(todayDone, total);
    }(),
    SmartListKind.moving => l10n.smartPillMoving(done, total),
    SmartListKind.packing => l10n.smartPillPacking(done, total),
    SmartListKind.workout => l10n.smartPillWorkout(done, total),
    SmartListKind.cleaning => l10n.smartPillCleaning(done, total),
    SmartListKind.gifts => l10n.smartPillGifts(done, total),
    SmartListKind.watchlist => l10n.smartPillWatchlist(total - done),
    SmartListKind.expense => () {
      var sum = 0.0;
      for (final i in items) {
        sum += ExpenseItemMeta.fromItem(i).amount ?? 0;
      }
      return l10n.smartPillExpense(ShopBudgetBar.formatTl(sum));
    }(),
    _ => l10n.smartPillDefault((total - done).clamp(0, total)),
  };
}

/// Akıllı liste türüne özgü etkileşimli çalışma alanını açar
/// (alışveriş editördeki StoreModeScreen ile açılır).
Future<void> openSmartWorkspace(
  BuildContext context, {
  required SmartListKind kind,
  required String title,
  required List<NoteItem> initialItems,
  required List<NoteItem> Function(List<NoteItem> updated) onReplaceItems,
  ValueListenable<List<NoteItem>>? liveItems,
}) {
  final Widget screen = switch (kind) {
    SmartListKind.habits => HabitTrackerWorkspace(
      title: title,
      initialItems: initialItems,
      liveItems: liveItems,
      onReplaceItems: onReplaceItems,
    ),
    SmartListKind.moving => MovingPlannerWorkspace(
      title: title,
      initialItems: initialItems,
      liveItems: liveItems,
      onReplaceItems: onReplaceItems,
    ),
    SmartListKind.packing => PackingPlannerWorkspace(
      title: title,
      initialItems: initialItems,
      liveItems: liveItems,
      onReplaceItems: onReplaceItems,
    ),
    SmartListKind.workout => WorkoutPlannerWorkspace(
      title: title,
      initialItems: initialItems,
      liveItems: liveItems,
      onReplaceItems: onReplaceItems,
    ),
    _ => SmartDomainWorkspace(
      kind: kind,
      title: title,
      initialItems: initialItems,
      liveItems: liveItems,
      onReplaceItems: onReplaceItems,
    ),
  };
  return Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (_) => screen));
}
