import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../data/quick_entry_memory.dart';
import '../../domain/list_mode.dart';
import '../../domain/note.dart';
import '../../domain/note_item.dart';
import '../../domain/smart_list.dart';

/// Liste notunun hemen üstünde duran, içeriğe göre şekil değiştiren kompakt
/// kip şeridi (ikincil ekran yok, her şey doğrudan not üzerinde).
class SmartListModeHeader extends StatelessWidget {
  const SmartListModeHeader({
    super.key,
    required this.note,
    required this.onChangeMode,
    this.onChangeResetSchedule,
    this.onChangeTimeSlot,
    this.groupByAisle = true,
    this.onToggleGroupByAisle,
    this.onOpenBarcode,
    this.onOpenReceipt,
    this.onOpenRecipes,
    this.onOpenAisleOrder,
    this.onResetTemplate,
    this.onCopyTemplate,
    this.onOpenPackingWizard,
    this.focusMode = false,
    this.focusVisibleCount = 0,
    this.onToggleFocusMode,
    this.onPickFocusItems,
    this.nudgeDismissed = false,
    this.onDismissNudge,
    this.accentColor,
  });

  final Note note;
  final ValueChanged<ListMode> onChangeMode;
  final void Function(ResetSchedule schedule, List<int> customDays)?
  onChangeResetSchedule;
  final ValueChanged<ContextTimeSlot>? onChangeTimeSlot;

  // Alışveriş kipi kontrolleri
  final bool groupByAisle;
  final VoidCallback? onToggleGroupByAisle;
  final VoidCallback? onOpenBarcode;
  final VoidCallback? onOpenReceipt;
  final VoidCallback? onOpenRecipes;
  final VoidCallback? onOpenAisleOrder;

  // Şablon kipi kontrolleri
  final VoidCallback? onResetTemplate;
  final VoidCallback? onCopyTemplate;
  final VoidCallback? onOpenPackingWizard;

  // Proje / Odak kipi kontrolleri
  final bool focusMode;
  final int focusVisibleCount;
  final VoidCallback? onToggleFocusMode;
  final VoidCallback? onPickFocusItems;

  // Genel kipte aşamalı kip önerisi (nudge)
  final bool nudgeDismissed;
  final VoidCallback? onDismissNudge;
  final Color? accentColor;

  static IconData modeIcon(ListMode mode) => switch (mode) {
    ListMode.general => Icons.checklist_rounded,
    ListMode.shopping => Icons.shopping_cart_outlined,
    ListMode.routine => Icons.repeat_rounded,
    ListMode.template => Icons.fact_check_outlined,
    ListMode.project => Icons.flag_outlined,
  };

  static String modeLabel(AppLocalizations l10n, ListMode mode) =>
      switch (mode) {
        ListMode.general => l10n.listModeGeneral,
        ListMode.shopping => l10n.listModeShopping,
        ListMode.routine => l10n.listModeRoutine,
        ListMode.template => l10n.listModeTemplate,
        ListMode.project => l10n.listModeProject,
      };

  static String scheduleLabel(AppLocalizations l10n, ResetSchedule s) =>
      switch (s) {
        ResetSchedule.none => l10n.listModeResetNone,
        ResetSchedule.daily => l10n.listModeResetDaily,
        ResetSchedule.weekly => l10n.listModeResetWeekly,
        ResetSchedule.customDays => l10n.listModeResetCustom,
      };

  static String slotLabel(AppLocalizations l10n, ContextTimeSlot slot) =>
      switch (slot) {
        ContextTimeSlot.any => l10n.listModeSlotAny,
        ContextTimeSlot.morning => l10n.listModeSlotMorning,
        ContextTimeSlot.evening => l10n.listModeSlotEvening,
        ContextTimeSlot.weekend => l10n.listModeSlotWeekend,
      };

  /// `general` kipteki listede en az 2 alışveriş veya rutin maddesi biriktiyse
  /// kullanıcıya nazikçe uygun kipe geçiş önerir.
  static ListMode? suggestedModeFor(Note note, String locale) {
    if (note.listMode != ListMode.general) return null;
    final items = [
      for (final i in note.items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    if (items.length < 2) return null;
    final grocery = groceryLexicon(locale);
    var groceryHits = 0;
    for (final i in items) {
      if (grocery.groupOf(i.text) >= 0) groceryHits++;
    }
    if (groceryHits >= 2 && groceryHits * 2 >= items.length) {
      return ListMode.shopping;
    }
    final habitLex = lexiconForSmartKind(SmartListKind.habits, locale);
    var habitHits = 0;
    for (final i in items) {
      if (habitLex.groupOf(i.text) >= 0) habitHits++;
    }
    if (habitHits >= 2 && habitHits * 2 >= items.length) {
      return ListMode.routine;
    }
    return null;
  }

  /// Liste kipi seçim alt levhasını açar (hem üst şeritten hem ⋮ menüsünden çağrılır).
  static Future<ListMode?> pickMode(
    BuildContext context, {
    required ListMode current,
  }) {
    final l10n = context.l10n;
    return showAppSheet<ListMode>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            0,
            AppSpace.l,
            AppSpace.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.listModeLabel),
              for (final m in ListMode.values)
                ListTile(
                  key: ValueKey('mode-option-${m.name}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  selected: current == m,
                  leading: Icon(modeIcon(m)),
                  title: Text(modeLabel(l10n, m)),
                  trailing: current == m
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    AppHaptics.tick();
                    Navigator.pop(sheetCtx, m);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openModeSheet(BuildContext context) async {
    final picked = await pickMode(context, current: note.listMode);
    if (picked != null && picked != note.listMode) {
      onChangeMode(picked);
    }
  }

  Future<void> _openRoutineScheduleSheet(BuildContext context) async {
    final l10n = context.l10n;
    var selectedSchedule = note.resetSchedule;
    var selectedDays = <int>{...note.resetCustomDays};
    var selectedSlot = note.contextTimeSlot;
    final dayLabels = l10n.localeName.startsWith('tr')
        ? const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final saved = await showAppSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(title: l10n.listModeResetSchedule),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final s in ResetSchedule.values)
                      ChoiceChip(
                        key: ValueKey('reset-sched-${s.name}'),
                        label: Text(scheduleLabel(l10n, s)),
                        selected: selectedSchedule == s,
                        onSelected: (_) => setSheet(() {
                          selectedSchedule = s;
                          if (s == ResetSchedule.customDays &&
                              selectedDays.isEmpty) {
                            selectedDays = {1, 3, 5};
                          }
                        }),
                      ),
                  ],
                ),
                if (selectedSchedule == ResetSchedule.customDays) ...[
                  const SizedBox(height: AppSpace.m),
                  Wrap(
                    spacing: AppSpace.xs,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          label: Text(dayLabels[d - 1]),
                          selected: selectedDays.contains(d),
                          onSelected: (on) => setSheet(() {
                            if (on) {
                              selectedDays.add(d);
                            } else if (selectedDays.length > 1) {
                              selectedDays.remove(d);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.m),
                Text(
                  l10n.listModeTimeSlot,
                  style: Theme.of(sheetCtx).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final slot in ContextTimeSlot.values)
                      ChoiceChip(
                        key: ValueKey('time-slot-${slot.name}'),
                        label: Text(slotLabel(l10n, slot)),
                        selected: selectedSlot == slot,
                        onSelected: (_) => setSheet(() => selectedSlot = slot),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.l),
                FilledButton(
                  key: const ValueKey('routine-schedule-save'),
                  onPressed: () => Navigator.pop(sheetCtx, true),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true) {
      final sorted = selectedDays.toList()..sort();
      onChangeResetSchedule?.call(selectedSchedule, sorted);
      if (selectedSlot != note.contextTimeSlot) {
        onChangeTimeSlot?.call(selectedSlot);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = accentColor ?? scheme.primary;
    final mode = note.listMode;
    final activeItems = [
      for (final i in note.items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final total = activeItems.length;
    final done = activeItems.where((i) => i.checked).length;
    final progress = total == 0 ? 0.0 : done / total;
    final nudge = !nudgeDismissed
        ? suggestedModeFor(note, l10n.localeName)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Tek dokunuşla kip değiştirme hapı
              ActionChip(
                key: const ValueKey('smart-mode-pill'),
                visualDensity: const VisualDensity(horizontal: -2),
                avatar: Icon(modeIcon(mode), size: AppIconSize.xs, color: accent),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      modeLabel(l10n, mode),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: AppWeight.strong,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.expand_more_rounded,
                      size: AppIconSize.xs,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                onPressed: () => _openModeSheet(context),
              ),

              // Genel kip: aşamalı kip önerisi
              if (mode == ListMode.general && nudge != null) ...[
                const SizedBox(width: AppSpace.s),
                InputChip(
                  key: ValueKey('mode-nudge-${nudge.name}'),
                  visualDensity: const VisualDensity(horizontal: -2),
                  avatar: Icon(modeIcon(nudge), size: AppIconSize.xs - 1, color: accent),
                  label: Text(
                    nudge == ListMode.shopping
                        ? l10n.listModeNudgeShopping
                        : l10n.listModeNudgeRoutine,
                    style: theme.textTheme.labelSmall,
                  ),
                  onPressed: () => onChangeMode(nudge),
                  onDeleted: onDismissNudge,
                ),
              ],

              // Alışveriş kipi: reyon gruplama + hafif modal araçlar
              if (mode == ListMode.shopping) ...[
                const SizedBox(width: AppSpace.xs),
                FilterChip(
                  key: const ValueKey('shopping-group-toggle'),
                  visualDensity: const VisualDensity(horizontal: -2),
                  selected: groupByAisle,
                  avatar: const Icon(Icons.category_outlined, size: AppIconSize.xs - 1),
                  label: Text(
                    l10n.shoppingGroupToggle,
                    style: theme.textTheme.labelSmall,
                  ),
                  onSelected: (_) => onToggleGroupByAisle?.call(),
                ),
                if (onOpenBarcode != null)
                  IconButton(
                    key: const ValueKey('shopping-tool-barcode'),
                    tooltip: l10n.shopBarcodeTitle,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: AppIconSize.s),
                    onPressed: onOpenBarcode,
                  ),
                if (onOpenReceipt != null)
                  IconButton(
                    key: const ValueKey('shopping-tool-receipt'),
                    tooltip: l10n.shopReceiptTitle,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.receipt_long_outlined, size: AppIconSize.s),
                    onPressed: onOpenReceipt,
                  ),
                if (onOpenRecipes != null)
                  IconButton(
                    key: const ValueKey('shopping-tool-recipes'),
                    tooltip: l10n.shopRecipesTitle,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.restaurant_menu_rounded, size: AppIconSize.s),
                    onPressed: onOpenRecipes,
                  ),
                if (onOpenAisleOrder != null)
                  IconButton(
                    key: const ValueKey('shopping-tool-aisle-order'),
                    tooltip: l10n.shopAisleOrderTooltip,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.swap_vert_rounded, size: AppIconSize.s),
                    onPressed: onOpenAisleOrder,
                  ),
              ],

              // Rutin kipi: günlük ilerleme + sıfırlama takvimi
              if (mode == ListMode.routine) ...[
                const SizedBox(width: AppSpace.s),
                Text(
                  l10n.routineTodayProgress(done, total),
                  key: const ValueKey('routine-progress'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: AppWeight.strong,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                ActionChip(
                  key: const ValueKey('routine-schedule-pill'),
                  visualDensity: const VisualDensity(horizontal: -2),
                  avatar: const Icon(Icons.schedule_rounded, size: AppIconSize.xs - 1),
                  label: Text(
                    scheduleLabel(l10n, note.resetSchedule),
                    style: theme.textTheme.labelSmall,
                  ),
                  onPressed: () => _openRoutineScheduleSheet(context),
                ),
              ],

              // Şablon kipi: tek dokunuşla sıfırla + yeni liste kopyala
              if (mode == ListMode.template) ...[
                const SizedBox(width: AppSpace.s),
                FilledButton.tonalIcon(
                  key: const ValueKey('template-reset-btn'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.m,
                      vertical: AppSpace.xs,
                    ),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: AppIconSize.xs),
                  label: Text(
                    l10n.templateResetReuse,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: AppWeight.strong,
                    ),
                  ),
                  onPressed: done > 0 ? onResetTemplate : null,
                ),
                if (onCopyTemplate != null) ...[
                  const SizedBox(width: AppSpace.xs),
                  IconButton(
                    key: const ValueKey('template-copy-btn'),
                    tooltip: l10n.templateCopyNew,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(AppIcons.duplicate, size: AppIconSize.s),
                    onPressed: onCopyTemplate,
                  ),
                ],
                if (note.listKind == 'packing' &&
                    onOpenPackingWizard != null) ...[
                  const SizedBox(width: AppSpace.xs),
                  IconButton(
                    key: const ValueKey('template-packing-wizard'),
                    tooltip: l10n.smartListTripWizard,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.luggage_outlined, size: AppIconSize.s),
                    onPressed: onOpenPackingWizard,
                  ),
                ],
              ],

              // Proje / Odak kipi: yüzde + tek tık Odak (3) + Odak seç
              if (mode == ListMode.project) ...[
                const SizedBox(width: AppSpace.s),
                Text(
                  l10n.projectProgressLabel(
                    (progress * 100).round(),
                    done,
                    total,
                  ),
                  key: const ValueKey('project-progress'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: AppWeight.strong,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                FilterChip(
                  key: const ValueKey('project-focus-toggle'),
                  visualDensity: const VisualDensity(horizontal: -2),
                  selected: focusMode,
                  avatar: Icon(
                    focusMode
                        ? Icons.center_focus_strong_rounded
                        : Icons.center_focus_weak_rounded,
                    size: AppIconSize.xs - 1,
                  ),
                  label: Text(
                    focusMode ? l10n.projectFocusExit : l10n.projectFocusToggle,
                    style: theme.textTheme.labelSmall,
                  ),
                  onSelected: (_) => onToggleFocusMode?.call(),
                ),
                if (onPickFocusItems != null) ...[
                  const SizedBox(width: AppSpace.xs),
                  IconButton(
                    key: const ValueKey('project-focus-pick'),
                    tooltip: l10n.projectFocusPick,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tune_rounded, size: AppIconSize.s),
                    onPressed: onPickFocusItems,
                  ),
                ],
              ],
            ],
          ),
        ),
        if ((mode == ListMode.routine || mode == ListMode.project) &&
            total > 0) ...[
          const SizedBox(height: AppSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              key: ValueKey('mode-progress-bar-${mode.name}'),
              value: progress,
              minHeight: 4,
              color: accent,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
        if (mode == ListMode.project && focusMode && total > 0) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.projectFocusActive(focusVisibleCount, total - done),
            key: const ValueKey('project-focus-banner'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: AppWeight.medium,
            ),
          ),
        ],
      ],
    );
  }
}

/// Proje kipinde odaklanılacak en fazla 3 maddeyi seçen kompakt levha.
Future<Set<String>?> showProjectFocusPickerSheet(
  BuildContext context, {
  required List<NoteItem> items,
  required Set<String> selectedIds,
}) {
  final open = [
    for (final i in items)
      if (!i.header && !i.checked && i.text.trim().isNotEmpty) i,
  ];
  final chosen = <String>{...selectedIds};
  final l10n = context.l10n;
  return showAppSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            0,
            AppSpace.l,
            AppSpace.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.projectFocusPick),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in open)
                      CheckboxListTile(
                        value: chosen.contains(item.id),
                        title: Text(
                          item.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (v) => setSheet(() {
                          if (v == true) {
                            if (chosen.length >= 3) {
                              chosen.remove(chosen.first);
                            }
                            chosen.add(item.id);
                          } else {
                            chosen.remove(item.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.m),
              FilledButton(
                key: const ValueKey('project-focus-save'),
                onPressed: () => Navigator.pop(sheetCtx, chosen),
                child: Text(l10n.ok),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
