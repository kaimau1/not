import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/ai_report.dart';

/// AI yanıtının altındaki küçük satır (PLAN §1.5 PL3 b, Play üretken AI
/// politikası): "AI yanılabilir" ipucu + isteğe bağlı "Bildir". Bildirim
/// kişisel veri göndermez ([AiReportService]); teşekkür bildirimi gösterir.
class AiResultNote extends ConsumerWidget {
  const AiResultNote({super.key, this.content, this.source});

  /// Bildirilecek yanıt; null ise yalnız ipucu (bildir düğmesi başka yerde).
  final String? content;

  /// Günlükte nereden geldiği (`ai_sheet`, `briefing`…).
  final String? source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final body = content;
    return Row(
      key: const ValueKey('ai-result-note'),
      children: [
        Icon(
          Icons.info_outline,
          size: AppIconSize.xs,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(child: Text(l10n.aiMayBeWrong, style: AppText.of(theme).meta)),
        if (body != null)
          TextButton.icon(
            key: const ValueKey('ai-report'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.flag_outlined, size: AppIconSize.xs),
            label: Text(l10n.aiReport),
            onPressed: () {
              ref
                  .read(aiReportServiceProvider)
                  .report(content: body, source: source ?? 'ai');
              ScaffoldMessenger.of(context).showMessage(l10n.aiReportThanks);
            },
          ),
      ],
    );
  }
}
