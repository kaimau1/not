import '../../../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Seçilen alan yakalandıktan sonra çıkan levha: önizleme + panoya kopyala.
Future<void> showAreaActions(
  BuildContext context,
  Uint8List png, {
  ValueChanged<String>? onInsertToNote,
}) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => _AreaActionsSheet(png: png),
);

class _AreaActionsSheet extends StatelessWidget {
  const _AreaActionsSheet({required this.png});

  final Uint8List png;

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    var ok = true;
    try {
      await Pasteboard.writeImage(png);
    } catch (_) {
      ok = false;
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(ok ? l10n.areaCopied : l10n.areaCaptureFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.areaAskTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.memory(png, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _copy(context),
              icon: const Icon(AppIcons.copy),
              label: Text(l10n.areaCopyImage),
            ),
          ],
        ),
      ),
    );
  }
}
