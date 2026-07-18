import 'package:flutter/material.dart';

import 'countdown_bar.dart';

/// Silme sonrası "geri al" bildirimi. Sistem gezinme çubuğunun ÜSTÜnde yüzer
/// (floating) — böylece geri tuşlarının altında kalıp örtüşmez — ve kalan
/// süre bir geri sayım çubuğuyla görünür, kendiliğinden kapanır.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            const SizedBox(height: 10),
            CountdownBar(duration: duration, color: scheme.inversePrimary),
          ],
        ),
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}
