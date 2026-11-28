import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../domain/ghost_suggestion_engine.dart';
import '../../domain/list_mode.dart';

/// **HAYALET ÖNERİ BÖLÜMÜ (KURAL 1 — YALNIZ GEÇİCİ UI KATMANI)** (Faz 3):
///
/// Listenin en altında soluk metin/çerçeve rengiyle (katmanlı `Opacity`
/// widget'ı OLMADAN) 2–3 bağlamsal öneri gösterir.
/// - Tek dokunuş: öneriyi gerçek bir `NoteItem` olarak nota ekler.
/// - `×` düğmesi: öneriyi 24 saatliğine gizler (`SharedPreferences`).
class GhostSuggestionsSection extends StatelessWidget {
  const GhostSuggestionsSection({
    super.key,
    required this.suggestions,
    required this.mode,
    required this.onAccept,
    required this.onDismiss,
  });

  final List<GhostSuggestion> suggestions;
  final ListMode mode;
  final ValueChanged<GhostSuggestion> onAccept;
  final ValueChanged<GhostSuggestion> onDismiss;

  String _reasonLabel(AppLocalizations l10n, GhostSuggestion s) =>
      switch (s.reason) {
        GhostSuggestionReason.overdue => l10n.ghostReasonDue,
        GhostSuggestionReason.pairing => l10n.ghostReasonPair,
        GhostSuggestionReason.frequent => l10n.ghostReasonFrequent,
        GhostSuggestionReason.essential =>
          mode == ListMode.routine
              ? l10n.ghostReasonRoutine
              : l10n.ghostReasonTemplate,
      };

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // S16 / katmansız solukluk: Opacity widget'ı yerine renk alfası kullanılır.
    final mutedText = scheme.onSurface.withValues(alpha: AppAlpha.disabled);
    final mutedSub = scheme.onSurfaceVariant.withValues(alpha: AppAlpha.disabled);
    final borderColor = scheme.outlineVariant.withValues(alpha: AppAlpha.disabled);

    return Padding(
      key: const ValueKey('ghost-suggestions-section'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.xs),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: AppIconSize.xs - 2, color: mutedSub),
                const SizedBox(width: AppSpace.xs),
                Text(
                  l10n.ghostSuggestionsTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: mutedSub,
                    fontWeight: AppWeight.strong,
                  ),
                ),
              ],
            ),
          ),
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: ValueKey('ghost-accept-${s.id}'),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        onTap: () => onAccept(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.m,
                            vertical: AppSpace.s,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: AppIconSize.s - 2,
                                color: mutedText,
                              ),
                              const SizedBox(width: AppSpace.s),
                              Expanded(
                                child: Text(
                                  s.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: mutedText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                _reasonLabel(l10n, s),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: mutedSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('ghost-dismiss-${s.id}'),
                      tooltip: l10n.close,
                      icon: Icon(
                        Icons.close_rounded,
                        size: AppIconSize.s - 2,
                        color: mutedSub,
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => onDismiss(s),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
