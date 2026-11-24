import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';
import '../l10n_ext.dart';

/// **ORTAK ONAY PENCERESİ** (DENEYIM F76.4): başlık `AppText.sheetTitle`,
/// gövde `AppText.body` (ikisi de `AppTheme`'in `dialogTheme`'inden), düğmeler
/// sağda — solda "Vazgeç" (`TextButton`), sağda onay (`FilledButton`).
/// [destructive] ise onay düğmesi `error` tonunda (sil, kalıcı sil, boşalt).
///
/// Açılış/kapanış hareketi: yumuşak ölçek (0,94 → 1,0) + solma; "Hareketi
/// azalt" açıkken doğrusal kısa solma (yalnız boyama katmanı).
///
/// Dönüş: onaylandıysa true; vazgeçildi ya da dışına dokunuldu ise false.
///
/// *Tuzak:* profil levhasına `FilledButton` koyma (test onay kutusunu onunla
/// bulur) — bu yardımcı yalnız pencere açar, levhaya düğme eklemez.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  String? cancelLabel,
}) async {
  final reduced = !motionOf(context);
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: AppAlpha.scrim),
    transitionDuration: reduced ? AppMotion.reduced : AppMotion.short,
    pageBuilder: (dialogContext, _, _) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const ValueKey('confirm-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel ?? dialogContext.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-ok'),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
    transitionBuilder: (dialogContext, animation, _, child) {
      if (!motionOf(dialogContext)) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curve = CurveTween(
        curve: animation.status == AnimationStatus.reverse
            ? AppMotion.exit
            : AppMotion.enter,
      );
      return FadeTransition(
        opacity: animation.drive(curve),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).chain(curve).animate(animation),
          child: child,
        ),
      );
    },
  );
  return ok ?? false;
}
