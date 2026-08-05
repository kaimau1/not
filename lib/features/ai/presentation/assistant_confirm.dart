import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';

/// Asistanın `delete_note` aracı için onay kutusu (bkz. ChatController.send).
///
/// Not içeriği güvenilmez kaynaklardan gelebildiği için (paylaşım menüsü,
/// OCR, PDF metni) model bir "talimat notu"na kanıp silme çağırabilir;
/// yıkıcı araç kullanıcı onayı olmadan çalışmaz. Ekran bu arada kapanmışsa
/// onay verilmemiş sayılır.
Future<bool> confirmAssistantDelete(BuildContext context, String title) async {
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final approved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.delete),
      content: Text(l10n.assistantDeleteConfirm(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return approved ?? false;
}
