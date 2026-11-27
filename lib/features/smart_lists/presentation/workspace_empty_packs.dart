import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/smart_lexicon_v2.dart';
import '../../notes/domain/smart_list.dart';

/// Başlangıç paketindeki eksik maddeleri `NoteItem` olarak üretir.
List<NoteItem> buildStarterPackItems(
  SmartStarterPack pack,
  List<NoteItem> existing, {
  required bool isTr,
}) {
  final names = pack.items(isTr: isTr);
  final have = {for (final i in existing) i.text.trim().toLowerCase()};
  final fresh = <NoteItem>[];
  for (var i = 0; i < names.length; i++) {
    final t = names[i].trim();
    if (t.isEmpty || have.contains(t.toLowerCase())) continue;
    final ex = pack.extrasByIndex[i];
    fresh.add(
      NoteItem(
        id: const Uuid().v4(),
        text: t,
        extras: ex == null ? const {} : Map<String, dynamic>.from(ex),
      ),
    );
  }
  return fresh;
}

/// Çalışma alanı boşken açılan tek dokunuşlu başlangıç paketleri ve sihirbaz
/// kartı — kullanıcı doğrudan hazır akışı keşfeder.
class WorkspaceEmptyPacks extends StatelessWidget {
  const WorkspaceEmptyPacks({
    super.key,
    required this.kind,
    required this.onApplyPack,
    this.onWizard,
    this.wizardLabel,
    this.wizardIcon,
  });

  final SmartListKind kind;
  final ValueChanged<SmartStarterPack> onApplyPack;
  final VoidCallback? onWizard;
  final String? wizardLabel;
  final IconData? wizardIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');
    final spec = kSmartKindSpecs[kind];
    final accent = spec?.accent ?? scheme.primary;
    final packs = spec?.starterPacks ?? const <SmartStarterPack>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.l,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.l),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: AppAlpha.hairline),
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: accent.withValues(alpha: AppAlpha.pressed),
            ),
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: AppAlpha.pressed),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: Icon(
                    spec?.icon ?? Icons.auto_awesome_outlined,
                    size: AppIconSize.l,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec?.desc(isTr: isTr) ?? l10n.smartListWorkspaceEmpty,
                      style: text.rowTitle,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      l10n.smartListWorkspaceEmpty,
                      style: text.meta.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (onWizard != null && wizardLabel != null) ...[
          const SizedBox(height: AppSpace.m),
          Material(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.l),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onWizard,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Row(
                  children: [
                    Icon(
                      wizardIcon ?? Icons.auto_fix_high_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: Text(
                        wizardLabel!,
                        style: text.rowTitle.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (packs.isNotEmpty) ...[
          const SizedBox(height: AppSpace.l),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s),
            child: Text(
              l10n.smartListStarterPacks,
              style: text.section.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          for (final pack in packs) ...[
            Material(
              color: tokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.l),
                side: BorderSide(color: tokens.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('workspace-pack-${pack.id}'),
                onTap: () {
                  unawaited(AppHaptics.thud());
                  onApplyPack(pack);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.m),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: AppAlpha.pressed),
                          borderRadius: BorderRadius.circular(AppRadius.m),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.s),
                          child: Icon(
                            pack.icon,
                            size: AppIconSize.m,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pack.name(isTr: isTr), style: text.rowTitle),
                            const SizedBox(height: AppSpace.xxs),
                            Text(
                              pack.desc(isTr: isTr),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.meta.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.s),
                      Icon(Icons.add_circle_outline_rounded, color: accent),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ],
      ],
    );
  }
}
