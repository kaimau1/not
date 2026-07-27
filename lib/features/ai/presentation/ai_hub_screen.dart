import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import 'read_document.dart';

/// Tüm yapay zekâ özelliklerinin tek giriş noktası. Eskiden dört ayrı yere
/// dağılmışlardı (üst bar ikonları, ⋮ menüsü, editör, mikrofon); artık üst
/// bardaki tek AI düğmesi burayı açar, her satır ne işe yaradığını söyler.
class AiHubScreen extends StatelessWidget {
  const AiHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = <(IconData, String, String, VoidCallback)>[
      (
        Icons.forum_outlined,
        l10n.chatTitle,
        l10n.hubChatInfo,
        () => context.push('/chat'),
      ),
      (
        Icons.wb_sunny_outlined,
        l10n.briefingTitle,
        l10n.hubBriefingInfo,
        () => context.push('/briefing'),
      ),
      (
        Icons.headphones_outlined,
        l10n.readDocument,
        l10n.hubReadInfo,
        () => pickAndReadDocument(context),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiHubTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final (icon, title, subtitle, onTap) in tiles)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    child: Icon(icon, size: 22),
                  ),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  onTap: onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
