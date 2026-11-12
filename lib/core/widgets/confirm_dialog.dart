import 'package:flutter/material.dart';

import '../l10n_ext.dart';

/// **ORTAK ONAY PENCERESİ** (DENEYIM F76.4): başlık `AppText.sheetTitle`,
/// gövde `AppText.body` (ikisi de `AppTheme`'in `dialogTheme`'inden), düğmeler
/// sağda — solda "Vazgeç" (`TextButton`), sağda onay (`FilledButton`).
/// [destructive] ise onay düğmesi `error` tonunda (sil, kalıcı sil, boşalt).
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
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
  );
  return ok ?? false;
}
