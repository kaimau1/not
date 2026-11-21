import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../domain/spell_review.dart';
import 'auto_spell.dart';

/// **TOPLU YAZIM DENETİMİ LEVHASI** (Y-5, 17K §3.3).
///
/// Nottaki bütün olası yazım yanlışlarını bağlamıyla listeler; her madde için
/// öneri seçimi, "Sözlüğe ekle" ve "Atla" sunar. "Tümünü düzelt (N)" kesin
/// önerisi olan tüm yanlışları tek seferde seçer; dönen harita editörde tek
/// Geri Al adımıyla uygulanır.
Future<Map<int, String>> showSpellReviewSheet(
  BuildContext context, {
  required List<SpellFinding> findings,
  void Function(String word)? onAddToDictionary,
}) async {
  final chosen = <int, String>{};
  await showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheet) => _SpellReviewSheet(
      findings: findings,
      chosen: chosen,
      onAddToDictionary: onAddToDictionary ?? AutoSpell.addToDictionary,
    ),
  );
  return chosen;
}

class _SpellReviewSheet extends StatefulWidget {
  const _SpellReviewSheet({
    required this.findings,
    required this.chosen,
    required this.onAddToDictionary,
  });

  final List<SpellFinding> findings;
  final Map<int, String> chosen;
  final void Function(String word) onAddToDictionary;

  @override
  State<_SpellReviewSheet> createState() => _SpellReviewSheetState();
}

class _SpellReviewSheetState extends State<_SpellReviewSheet> {
  final Set<int> _dismissed = {};

  List<SpellFinding> get _remaining => [
    for (final f in widget.findings)
      if (!_dismissed.contains(f.id) && !widget.chosen.containsKey(f.id)) f,
  ];

  int get _autoFixCount => _remaining.where((f) => f.autoFixable).length;

  void _pick(SpellFinding f, String suggestion) {
    setState(() => widget.chosen[f.id] = suggestion);
  }

  void _skip(SpellFinding f) {
    setState(() => _dismissed.add(f.id));
  }

  void _addDictionary(SpellFinding f) {
    widget.onAddToDictionary(f.word);
    setState(() {
      for (final other in widget.findings) {
        if (other.lower == f.lower) _dismissed.add(other.id);
      }
    });
  }

  void _fixAll() {
    for (final f in _remaining) {
      if (f.autoFixable) {
        widget.chosen[f.id] = f.suggestions.first;
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final remaining = _remaining;
    final autoCount = _autoFixCount;
    final chosenCount = widget.chosen.length;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.spellReviewAction,
            badge: remaining.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: AppAlpha.pressed),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${remaining.length}',
                      style: text.badge.copyWith(color: scheme.primary),
                    ),
                  ),
          ),
          if (remaining.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.xxl,
                AppSpace.xl,
                AppSpace.xxxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: AppSpace.xxxl + AppSpace.s,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpace.m),
                  Text(
                    chosenCount > 0
                        ? l10n.spellReviewFixed(chosenCount)
                        : l10n.spellReviewClean,
                    style: text.rowTitle,
                    textAlign: TextAlign.center,
                  ),
                  if (chosenCount == 0) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      l10n.spellReviewCleanHint,
                      style: text.meta,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.m,
                ),
                itemCount: remaining.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.s),
                itemBuilder: (context, index) => _FindingCard(
                  finding: remaining[index],
                  tokens: tokens,
                  scheme: scheme,
                  text: text,
                  onPick: (s) => _pick(remaining[index], s),
                  onDictionary: () => _addDictionary(remaining[index]),
                  onSkip: () => _skip(remaining[index]),
                ),
              ),
            ),
          if (autoCount > 0 || chosenCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.s,
                AppSpace.l,
                AppSpace.l,
              ),
              child: Row(
                children: [
                  if (chosenCount > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const ValueKey('spell-review-apply'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, kMinInteractiveDimension),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.spellReviewApply(chosenCount)),
                      ),
                    ),
                    if (autoCount > 0) const SizedBox(width: AppSpace.s),
                  ],
                  if (autoCount > 0)
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('spell-review-fix-all'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, kMinInteractiveDimension),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                        ),
                        onPressed: _fixAll,
                        icon: const Icon(
                          Icons.done_all_rounded,
                          size: AppIconSize.s,
                        ),
                        label: Text(l10n.spellReviewFixAll(autoCount)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({
    required this.finding,
    required this.tokens,
    required this.scheme,
    required this.text,
    required this.onPick,
    required this.onDictionary,
    required this.onSkip,
  });

  final SpellFinding finding;
  final AppTokens tokens;
  final ColorScheme scheme;
  final AppText text;
  final ValueChanged<String> onPick;
  final VoidCallback onDictionary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = finding.hint ? scheme.secondary : scheme.error;
    return Container(
      key: ValueKey('spell-finding-${finding.id}'),
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: tokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: text.body.copyWith(color: scheme.onSurfaceVariant),
                    children: [
                      if (finding.before.isNotEmpty)
                        TextSpan(text: finding.before),
                      TextSpan(
                        text: finding.word,
                        style: text.body.copyWith(
                          color: accent,
                          fontWeight: AppWeight.strong,
                          decoration: TextDecoration.underline,
                          decorationColor: accent,
                        ),
                      ),
                      if (finding.after.isNotEmpty)
                        TextSpan(text: finding.after),
                    ],
                  ),
                ),
              ),
              if (finding.hint) ...[
                const SizedBox(width: AppSpace.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: AppAlpha.pressed),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Text(
                    l10n.spellReviewHintBadge,
                    style: text.badge.copyWith(color: scheme.secondary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            children: [
              for (final s in finding.suggestions)
                ActionChip(
                  key: ValueKey('spell-suggest-${finding.id}-$s'),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(s),
                  onPressed: () => onPick(s),
                ),
              TextButton.icon(
                key: ValueKey('spell-dict-${finding.id}'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinInteractiveDimension),
                ),
                onPressed: onDictionary,
                icon: const Icon(Icons.book_outlined, size: AppIconSize.xs),
                label: Text(l10n.spellAddToDictionary),
              ),
              TextButton(
                key: ValueKey('spell-skip-${finding.id}'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinInteractiveDimension),
                ),
                onPressed: onSkip,
                child: Text(l10n.spellReviewSkip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
