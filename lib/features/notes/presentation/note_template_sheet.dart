import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/note_templates.dart';

/// Şablon seçim levhası (bkz. [NoteTemplate]): iki sütunlu kartlar — renkli
/// simge kutusu, ad ve ne ürettiğini söyleyen kısa açıklama. Seçilen şablon
/// döner; vazgeçilirse null.
Future<NoteTemplate?> showNoteTemplateSheet(BuildContext context) =>
    showModalBottomSheet<NoteTemplate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                child: Text(l10n.templatesTitle, style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(
                  l10n.templatesSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 480 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - 10 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final t in NoteTemplate.values)
                        SizedBox(
                          width: math.max(0, width),
                          child: _TemplateCard(
                            template: t,
                            onTap: () => Navigator.pop(sheetContext, t),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final NoteTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = template.accent;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(template.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.label(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
