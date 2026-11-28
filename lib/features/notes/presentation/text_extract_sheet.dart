import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/list_ai_service.dart';
import '../domain/list_mode.dart';
import '../domain/note_item.dart';
import '../domain/text_item_extractor.dart';

/// **"Metinden ayıkla" alt levhası** (Faz 3):
///
/// 1. Katman (0 kredi, anlık): Yapıştırılan WhatsApp mesajı, tarif veya uzun
///    metinden [TextItemExtractor.extractLocal] ile temiz maddeleri çıkarır.
/// 2. Katman (isteğe bağlı, 1 kredi): Kullanıcı açıkça "Yapay zekâ ile
///    netleştir" düğmesine basarsa [ListAiService.extractItems] çağrılır; kota
///    doluysa yerel ayıklama korunur ve ince bilgi bildirimi gösterilir.
Future<List<NoteItem>?> showTextExtractSheet(
  BuildContext context,
  WidgetRef ref, {
  String initialText = '',
  required ListMode mode,
  Map<String, int> learnedGroups = const {},
  bool noteLocked = false,
}) => showAppSheet<List<NoteItem>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TextExtractSheet(
    initialText: initialText,
    mode: mode,
    learnedGroups: learnedGroups,
    noteLocked: noteLocked,
  ),
);

/// **Proje kipi "Alt adımlara böl" onay levhası** (Faz 3):
///
/// [ListAiService.breakdownTask] sonucunu düzenlenebilir / seçilebilir liste
/// olarak sunar; kullanıcı onayladığında seçili alt adımlar ana maddenin altına
/// `parentId` ile eklenir.
Future<List<String>?> showTaskBreakdownSheet(
  BuildContext context, {
  required String parentTaskText,
  required List<String> initialSteps,
}) => showAppSheet<List<String>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TaskBreakdownSheet(
    parentTaskText: parentTaskText,
    initialSteps: initialSteps,
  ),
);

class _TextExtractSheet extends ConsumerStatefulWidget {
  const _TextExtractSheet({
    required this.initialText,
    required this.mode,
    required this.learnedGroups,
    required this.noteLocked,
  });

  final String initialText;
  final ListMode mode;
  final Map<String, int> learnedGroups;
  final bool noteLocked;

  @override
  ConsumerState<_TextExtractSheet> createState() => _TextExtractSheetState();
}

class _TextExtractSheetState extends ConsumerState<_TextExtractSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  List<ExtractedItemDraft> _drafts = const [];
  bool _refining = false;
  bool _parsedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_parsedOnce) {
      _parsedOnce = true;
      _parseLocal(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseLocal(String raw) {
    final locale = context.l10n.localeName;
    final next = TextItemExtractor.extractLocal(
      raw,
      mode: widget.mode,
      locale: locale,
      learnedGroups: widget.learnedGroups,
    );
    setState(() => _drafts = next);
  }

  Future<void> _refineWithAi() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty || _refining) return;
    setState(() => _refining = true);
    final l10n = context.l10n;
    try {
      final res = await ref
          .read(listAiServiceProvider)
          .extractItems(
            raw,
            mode: widget.mode,
            locale: l10n.localeName,
            learnedGroups: widget.learnedGroups,
            noteLocked: widget.noteLocked,
          );
      if (!mounted) return;
      if (res.quotaReached) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(l10n.listAiQuotaReached);
      }
      if (res.items.isNotEmpty) {
        setState(() => _drafts = res.items);
      }
    } finally {
      if (mounted) setState(() => _refining = false);
    }
  }

  void _confirm() {
    const uuid = Uuid();
    final selected = [
      for (final d in _drafts)
        if (d.selected)
          NoteItem(
            id: uuid.v4(),
            text: d.item.text,
            category: d.item.category,
            quantity: d.item.quantity,
            unit: d.item.unit,
            price: d.item.price,
            priority: d.item.priority,
            dueDate: d.item.dueDate,
            extras: d.item.extras,
          ),
    ];
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedCount = _drafts.where((d) => d.selected).length;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SheetInsetPadding(
        extra: AppSpace.l,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.playlist_add_check_rounded,
                    size: AppIconSize.m,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: Text(
                      l10n.textExtractTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                  ),
                  if (!widget.noteLocked && _controller.text.trim().isNotEmpty)
                    TextButton.icon(
                      key: const ValueKey('text-extract-ai-btn'),
                      onPressed: _refining
                          ? null
                          : () => unawaited(_refineWithAi()),
                      icon: _refining
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.auto_awesome_outlined,
                              size: AppIconSize.xs,
                            ),
                      label: Text(l10n.textExtractRefineAi),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
              TextField(
                key: const ValueKey('text-extract-input'),
                controller: _controller,
                minLines: 2,
                maxLines: 5,
                onChanged: _parseLocal,
                decoration: InputDecoration(
                  hintText: l10n.textExtractHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpace.s),
              if (_drafts.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _drafts.length,
                    itemBuilder: (context, i) {
                      final d = _drafts[i];
                      final metaParts = <String>[
                        if (d.item.quantity != null)
                          '${d.item.quantity == d.item.quantity!.roundToDouble() ? d.item.quantity!.toInt() : d.item.quantity}${d.item.unit.isNotEmpty ? ' ${d.item.unit}' : ''}',
                        if (d.item.price != null)
                          '${d.item.price!.toStringAsFixed(d.item.price! == d.item.price!.roundToDouble() ? 0 : 2)} ₺',
                      ];
                      return CheckboxListTile(
                        key: ValueKey('text-extract-item-$i'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: d.selected,
                        onChanged: (v) {
                          setState(() {
                            _drafts = [
                              for (var k = 0; k < _drafts.length; k++)
                                k == i
                                    ? _drafts[k].copyWith(selected: v ?? false)
                                    : _drafts[k],
                            ];
                          });
                        },
                        title: Text(
                          d.item.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: metaParts.isEmpty
                            ? null
                            : Text(
                                metaParts.join(' · '),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpace.s),
              FilledButton(
                key: const ValueKey('text-extract-confirm'),
                onPressed: selectedCount == 0 ? null : _confirm,
                child: Text(l10n.textExtractAddSelected(selectedCount)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBreakdownSheet extends StatefulWidget {
  const _TaskBreakdownSheet({
    required this.parentTaskText,
    required this.initialSteps,
  });

  final String parentTaskText;
  final List<String> initialSteps;

  @override
  State<_TaskBreakdownSheet> createState() => _TaskBreakdownSheetState();
}

class _TaskBreakdownSheetState extends State<_TaskBreakdownSheet> {
  late final List<TextEditingController> _controllers = [
    for (final s in widget.initialSteps) TextEditingController(text: s),
  ];
  late final List<bool> _selected = [
    for (var i = 0; i < widget.initialSteps.length; i++) true,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedCount = [
      for (var i = 0; i < _controllers.length; i++)
        if (_selected[i] && _controllers[i].text.trim().isNotEmpty) i,
    ].length;

    return SheetInsetPadding(
      extra: AppSpace.l,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: AppIconSize.m,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.itemBreakdownTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppWeight.strong,
                        ),
                      ),
                      Text(
                        widget.parentTaskText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            if (_controllers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
                child: Text(
                  l10n.itemBreakdownEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _controllers.length,
                  itemBuilder: (context, i) => Row(
                    children: [
                      Checkbox(
                        value: _selected[i],
                        onChanged: (v) =>
                            setState(() => _selected[i] = v ?? false),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpace.m),
            FilledButton(
              key: const ValueKey('breakdown-apply-btn'),
              onPressed: selectedCount == 0
                  ? null
                  : () {
                      final steps = [
                        for (var i = 0; i < _controllers.length; i++)
                          if (_selected[i] &&
                              _controllers[i].text.trim().isNotEmpty)
                            _controllers[i].text.trim(),
                      ];
                      Navigator.of(context).pop(steps);
                    },
              child: Text(l10n.itemBreakdownApply),
            ),
          ],
        ),
      ),
    );
  }
}
