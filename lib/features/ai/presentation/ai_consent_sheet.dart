import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../data/ai_policy.dart';

/// Play derlemesinde ilk akıllı karar kullanımı öncesinde KVKK/AI rızası
/// ister. Zaten onaylıysa veya Play rızası gerekmiyorsa pencere açmadan
/// `true` döner; AI ayarlardan tümden kapatılmışsa `false` döner.
Future<bool> ensureAiConsent(BuildContext context, WidgetRef ref) async {
  if (ref.read(aiTurnedOffProvider)) return false;
  if (!AiConsentNotifier.required || ref.read(aiConsentProvider)) {
    return true;
  }
  final l10n = context.l10n;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_outlined),
      title: Text(l10n.aiConsentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.aiConsentWhat),
          const SizedBox(height: 8),
          Text(l10n.aiConsentWhere),
          const SizedBox(height: 8),
          Text(l10n.aiConsentMistakes),
          const SizedBox(height: 8),
          Text(l10n.aiConsentTurnOff),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(l10n.aiConsentDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: Text(l10n.aiConsentAccept),
        ),
      ],
    ),
  );
  if (accepted == true) {
    ref.read(aiConsentProvider.notifier).accept();
    return true;
  }
  return false;
}
