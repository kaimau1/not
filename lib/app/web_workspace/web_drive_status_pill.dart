import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../features/auth/presentation/account_sheet.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/notes/data/drive_store.dart';
import '../../features/notes/data/upload_queue.dart';
import '../../features/notes/presentation/drive_ui.dart';
import '../app_commands.dart';
import '../theme/app_tokens.dart';

/// Kenar çubuğunun altındaki canlı Drive ve bulut senkronu durum hapı.
///
/// Duruma göre tek bakışta neyin eksik ya da çalışır olduğunu söyler:
/// misafir -> Google bağla · Drive izinsiz -> Drive'a bağlan · yükleme
/// bekliyor/hatalı -> sayı · hazır -> bağlı.
class WebDriveStatusPill extends ConsumerStatefulWidget {
  const WebDriveStatusPill({super.key, required this.compact});

  final bool compact;

  @override
  ConsumerState<WebDriveStatusPill> createState() => _WebDriveStatusPillState();
}

class _WebDriveStatusPillState extends ConsumerState<WebDriveStatusPill> {
  bool _connecting = false;

  Future<void> _connectDrive() async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      await connectDrive(context, ref);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(Theme.of(context));
    final anonymous = ref.watch(isAnonymousProvider);
    final mode = ref.watch(attachmentSyncModeProvider);
    final driveConnected = ref.watch(driveConnectedProvider);
    final pending = ref.watch(pendingUploadsProvider);
    final progress = ref.watch(uploadProgressProvider);

    final IconData icon;
    final String label;
    final Color background;
    final Color foreground;
    final bool showReadyDot;
    final VoidCallback? onTap;

    if (anonymous) {
      icon = Icons.cloud_off_outlined;
      label = l10n.guestReminderConnect;
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      showReadyDot = false;
      onTap = () => unawaited(showAccountSheet(context));
    } else if (mode == AttachmentSyncMode.drive && !driveConnected) {
      icon = Icons.add_to_drive_outlined;
      label = l10n.driveWebConnectButton;
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      showReadyDot = false;
      onTap = _connecting ? null : () => unawaited(_connectDrive());
    } else if (progress.isNotEmpty ||
        pending.pending > 0 ||
        pending.failed > 0) {
      final hasFailure = pending.failed > 0;
      final count = progress.isNotEmpty
          ? progress.length
          : (hasFailure ? pending.pending + pending.failed : pending.pending);
      icon = hasFailure
          ? Icons.sync_problem_outlined
          : Icons.cloud_sync_outlined;
      label = hasFailure
          ? l10n.webDriveStatusAttention(count)
          : l10n.webDriveStatusSyncing(count);
      background = hasFailure ? scheme.errorContainer : scheme.primaryContainer;
      foreground = hasFailure
          ? scheme.onErrorContainer
          : scheme.onPrimaryContainer;
      showReadyDot = false;
      onTap = () => openSection(GoRouter.of(context), AppSection.settings);
    } else {
      final isDrive = mode == AttachmentSyncMode.drive;
      icon = isDrive ? Icons.add_to_drive_outlined : Icons.cloud_done_outlined;
      label = isDrive ? l10n.webDriveStatusConnected : l10n.webSyncCloudReady;
      background = scheme.surfaceContainerHigh;
      foreground = scheme.onSurface;
      showReadyDot = true;
      onTap = () => openSection(GoRouter.of(context), AppSection.settings);
    }

    if (widget.compact) {
      return Tooltip(
        message: label,
        child: Material(
          key: const ValueKey('web-drive-status-pill'),
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.m),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(icon, size: AppIconSize.m, color: foreground),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: Material(
        key: const ValueKey('web-drive-status-pill'),
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.m),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.m,
              vertical: AppSpace.s,
            ),
            child: Row(
              children: [
                if (_connecting)
                  SizedBox(
                    width: AppIconSize.s,
                    height: AppIconSize.s,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: AppIconSize.s, color: foreground),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.label.copyWith(
                      color: foreground,
                      fontWeight: AppWeight.medium,
                    ),
                  ),
                ),
                if (showReadyDot)
                  Container(
                    width: AppSpace.s,
                    height: AppSpace.s,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
