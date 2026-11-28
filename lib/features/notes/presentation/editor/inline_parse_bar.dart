import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../domain/inline_item_parser.dart';
import '../../domain/list_mode.dart';
import '../../domain/note_item.dart';

/// Liste üstü canlı doğal dil ayrıştırıcı çubuğu.
///
/// Yazarken miktar (`2 kg domates`), açık para birimli fiyat (`kahve 180 tl`),
/// zaman (`yarın 10:00 kargo`), `#etiket` ve `!öncelik` kalıplarını yakalar ve
/// satır altında silinebilir (`×`) önizleme çipleri olarak gösterir.
/// Kullanıcı bir çipi `×` ile kapatırsa o desen ayrıştırılmadan ham metin
/// olarak korunur.
class InlineParseBar extends StatefulWidget {
  const InlineParseBar({
    super.key,
    required this.mode,
    required this.onAddItem,
    this.learnedGroups = const {},
    this.onTagsDetected,
    this.onLargePaste,
    this.accentColor,
  });

  final ListMode mode;
  final ValueChanged<NoteItem> onAddItem;
  final Map<String, int> learnedGroups;
  final ValueChanged<List<String>>? onTagsDetected;

  /// Kullanıcı 80+ karakter veya 3+ satır metin yapıştırırsa Faz 3 "Metinden
  /// ayıkla" akışını öneren geri çağrı.
  final ValueChanged<String>? onLargePaste;
  final Color? accentColor;

  @override
  State<InlineParseBar> createState() => _InlineParseBarState();
}

class _InlineParseBarState extends State<InlineParseBar> {
  static const _uuid = Uuid();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final ValueNotifier<InlineParsedItem?> _parsedN = ValueNotifier(null);
  final ValueNotifier<Set<InlineParsedChipKind>> _dismissedN = ValueNotifier(
    const {},
  );
  final ValueNotifier<String?> _pasteCandidateN = ValueNotifier(null);
  String _prevText = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _parsedN.dispose();
    _dismissedN.dispose();
    _pasteCandidateN.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final trimmed = value.trim();
    final jump = value.length - _prevText.length;
    _prevText = value;
    if (trimmed.isEmpty) {
      _parsedN.value = null;
      _dismissedN.value = const {};
      _pasteCandidateN.value = null;
      return;
    }
    final lineCount = value
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    if (widget.onLargePaste != null &&
        ((jump >= 32 && trimmed.length >= 80) || lineCount >= 3)) {
      _pasteCandidateN.value = value;
    } else if (trimmed.length < 40 && lineCount <= 1) {
      _pasteCandidateN.value = null;
    }

    final locale = context.l10n.localeName;
    _parsedN.value = InlineItemParser.parse(
      value,
      mode: widget.mode,
      locale: locale,
      learnedGroups: widget.learnedGroups,
    );
  }

  void _dismissKind(InlineParsedChipKind kind) {
    _dismissedN.value = {..._dismissedN.value, kind};
  }

  void _submit() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    final locale = context.l10n.localeName;
    final parsed =
        _parsedN.value ??
        InlineItemParser.parse(
          raw,
          mode: widget.mode,
          locale: locale,
          learnedGroups: widget.learnedGroups,
        );
    final dismissed = _dismissedN.value;
    final item = parsed.toNoteItem(id: _uuid.v4(), dismissed: dismissed);
    if (item.text.trim().isEmpty) return;
    final activeTags = dismissed.contains(InlineParsedChipKind.tag)
        ? const <String>[]
        : parsed.tags;
    _ctrl.clear();
    _prevText = '';
    _parsedN.value = null;
    _dismissedN.value = const {};
    _pasteCandidateN.value = null;
    AppHaptics.tick();
    widget.onAddItem(item);
    if (activeTags.isNotEmpty) widget.onTagsDetected?.call(activeTags);
  }

  String _chipText(BuildContext context, InlineParsedChip chip) {
    final l10n = context.l10n;
    return switch (chip.kind) {
      InlineParsedChipKind.priority => switch (chip.label) {
        'urgent' => '! ${l10n.quickDropPriorityUrgent}',
        'high' => '! ${l10n.quickDropPriorityHigh}',
        'medium' => '! ${l10n.quickDropPriorityMedium}',
        'low' => '! ${l10n.quickDropPriorityLow}',
        _ => chip.label,
      },
      InlineParsedChipKind.dueDate => () {
        final dt = _parsedN.value?.dueDate;
        if (dt == null) return chip.label;
        final hasTime = dt.hour != 0 || dt.minute != 0;
        final fmt = hasTime
            ? DateFormat('d MMM HH:mm', l10n.localeName)
            : DateFormat('d MMM', l10n.localeName);
        return fmt.format(dt);
      }(),
      _ => chip.label,
    };
  }

  IconData _chipIcon(InlineParsedChipKind kind) => switch (kind) {
    InlineParsedChipKind.quantity => Icons.scale_outlined,
    InlineParsedChipKind.price => Icons.payments_outlined,
    InlineParsedChipKind.dueDate => Icons.event_outlined,
    InlineParsedChipKind.priority => Icons.flag_outlined,
    InlineParsedChipKind.tag => Icons.tag_rounded,
    InlineParsedChipKind.category => Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = widget.accentColor ?? scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: AppAlpha.disabled),
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpace.s),
              Icon(Icons.add_rounded, size: AppIconSize.s, color: accent),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: TextField(
                  key: const ValueKey('inline-parse-field'),
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.done,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    // Kipe göre ipucu: rutin listede "domates" örneği
                    // kipleri birbirine karıştırıyordu (kullanıcı 2026-11-28).
                    hintText: switch (widget.mode) {
                      ListMode.shopping => l10n.listModeQuickAddHint,
                      ListMode.routine => l10n.listModeQuickAddHintRoutine,
                      ListMode.project => l10n.listModeQuickAddHintProject,
                      ListMode.template ||
                      ListMode.general => l10n.listModeQuickAddHintGeneral,
                    },
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: AppAlpha.muted),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              ValueListenableBuilder<InlineParsedItem?>(
                valueListenable: _parsedN,
                builder: (_, parsed, _) {
                  if (parsed == null) return const SizedBox.shrink();
                  return IconButton(
                    key: const ValueKey('inline-parse-submit'),
                    tooltip: l10n.quickDropAdd,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                      size: AppIconSize.s,
                      color: accent,
                    ),
                    onPressed: _submit,
                  );
                },
              ),
            ],
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _pasteCandidateN,
          builder: (context, pasted, _) {
            if (pasted == null || widget.onLargePaste == null) {
              return const SizedBox.shrink();
            }
            final approx = pasted
                .split(RegExp(r'[\n,;]+'))
                .where((s) => s.trim().length >= 2)
                .length;
            if (approx < 2) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionChip(
                  key: const ValueKey('inline-parse-paste-extract'),
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    Icons.playlist_add_check_rounded,
                    size: AppIconSize.xs,
                    color: accent,
                  ),
                  label: Text(l10n.textExtractPasteBanner(approx)),
                  onPressed: () {
                    final raw = pasted;
                    _ctrl.clear();
                    _prevText = '';
                    _parsedN.value = null;
                    _pasteCandidateN.value = null;
                    widget.onLargePaste!(raw);
                  },
                ),
              ),
            );
          },
        ),
        ListenableBuilder(
          listenable: Listenable.merge([_parsedN, _dismissedN]),
          builder: (context, _) {
            final parsed = _parsedN.value;
            if (parsed == null || parsed.chips.isEmpty) {
              return const SizedBox.shrink();
            }
            final dismissed = _dismissedN.value;
            final visible = [
              for (final c in parsed.chips)
                if (!dismissed.contains(c.kind)) c,
            ];
            if (visible.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xxs,
                children: [
                  for (final chip in visible)
                    InputChip(
                      key: ValueKey('inline-chip-${chip.kind.name}'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(
                        _chipIcon(chip.kind),
                        size: AppIconSize.xs - 2,
                        color: accent,
                      ),
                      label: Text(
                        _chipText(context, chip),
                        style: theme.textTheme.labelSmall,
                      ),
                      onDeleted: () => _dismissKind(chip.kind),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
