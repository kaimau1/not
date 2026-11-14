import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/attachment.dart';

/// **TEK EK DURUM DİLİ (TUTARLILIK F40.4).** Şeritte rozet, yüzende boş kutu,
/// kartta yer tutucu ayrı ayrı anlatıyordu. Durum tek yerde, simge + metin tek
/// yerde; her görünüm aynı rozeti çizer, dokununca aynı açıklama.
enum AttachmentStatus {
  /// Her şey yerinde: rozet yok.
  none,
  uploading,
  queued,
  failed,
  overLimit,
  waitingOwner,
  notSynced,

  /// Web: dosya eklendiği telefondan hiç çıkmamış.
  onPhone,

  /// Büyük dosya yalnız bu cihazda (F65.9): buluta hiç gitmez.
  deviceOnly,

  /// Büyük dosya başka cihazda kaldı (F65.9): indirme denenmez.
  otherDevice,
}

/// Saf: görünümden bağımsız durum (test edilir).
AttachmentStatus attachmentStatusOf(
  Attachment a, {
  required bool hasLocal,
  bool foreign = false,
  bool web = kIsWeb,
  bool uploading = false,
  int failedAttempts = 0,
  int limitMb = 0,
  bool textOnly = false,
}) {
  if (a.localOnly) {
    return hasLocal ? AttachmentStatus.deviceOnly : AttachmentStatus.otherDevice;
  }
  if (a.isWebVideo || a.skipsUpload) return AttachmentStatus.none;
  if (hasLocal) {
    // Görüntülü not ve "yalnız metin" kipi buluta hiç gitmez: çark yalan olurdu.
    if (a.isSynced || a.kind == AttachmentKind.video || textOnly) {
      return AttachmentStatus.none;
    }
    if (limitMb > 0 && a.sizeBytes > limitMb * 1024 * 1024) {
      return AttachmentStatus.overLimit;
    }
    if (failedAttempts >= 3) return AttachmentStatus.failed;
    return uploading ? AttachmentStatus.uploading : AttachmentStatus.queued;
  }
  if (a.isUploaded || a.isInDrive) return AttachmentStatus.none;
  if (web) return AttachmentStatus.onPhone;
  return foreign ? AttachmentStatus.waitingOwner : AttachmentStatus.notSynced;
}

IconData attachmentStatusIcon(AttachmentStatus status) => switch (status) {
  AttachmentStatus.none => Icons.check,
  AttachmentStatus.uploading => Icons.cloud_upload_outlined,
  AttachmentStatus.queued => Icons.schedule,
  AttachmentStatus.failed => Icons.refresh,
  AttachmentStatus.overLimit => Icons.cloud_off_outlined,
  AttachmentStatus.waitingOwner => Icons.hourglass_empty,
  AttachmentStatus.notSynced => Icons.cloud_sync_outlined,
  AttachmentStatus.onPhone => Icons.phone_android_outlined,
  AttachmentStatus.deviceOnly => Icons.phone_android_outlined,
  AttachmentStatus.otherDevice => Icons.devices_other_outlined,
};

String attachmentStatusText(BuildContext context, AttachmentStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    AttachmentStatus.none => '',
    AttachmentStatus.uploading => l10n.attachmentUploading,
    AttachmentStatus.queued => l10n.attachmentUploadQueued,
    AttachmentStatus.failed => l10n.attachmentUploadFailed,
    AttachmentStatus.overLimit => l10n.syncLimitInfo,
    AttachmentStatus.waitingOwner => l10n.attachmentWaitingOwner,
    AttachmentStatus.notSynced => l10n.attachmentNotSynced,
    AttachmentStatus.onPhone => l10n.webAttachmentsOnPhone(1),
    AttachmentStatus.deviceOnly => l10n.attachmentDeviceOnly,
    AttachmentStatus.otherDevice => l10n.attachmentOtherDevice,
  };
}

/// Aynı açıklama levhası (kısa metin + varsa tek eylem).
Future<void> showAttachmentStatusSheet(
  BuildContext context,
  AttachmentStatus status, {
  VoidCallback? onRetry,
}) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Column(
      key: const ValueKey('attachment-status-sheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(attachmentStatusIcon(status)),
            const SizedBox(width: 12),
            Expanded(child: Text(attachmentStatusText(sheet, status))),
          ],
        ),
        // Bekleyen ekte de (F65.4): üstel bekleme saatlere tırmanmış olabilir.
        if (onRetry != null &&
            (status == AttachmentStatus.failed ||
                status == AttachmentStatus.queued)) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.tonal(
              onPressed: () {
                Navigator.pop(sheet);
                onRetry();
              },
              child: Text(
                status == AttachmentStatus.queued
                    ? sheet.l10n.attachmentUploadNow
                    : sheet.l10n.retry,
              ),
            ),
          ),
        ],
      ],
    ),
  ),
);

/// Küçük rozet (sol üst köşe). [progress]: sürerken gösterge (şerit).
class AttachmentStatusBadge extends StatelessWidget {
  const AttachmentStatusBadge({
    super.key,
    required this.status,
    this.progress,
    this.onRetry,
  });

  final AttachmentStatus status;
  final Widget? progress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == AttachmentStatus.none) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final failed = status == AttachmentStatus.failed;
    return Tooltip(
      message: attachmentStatusText(context, status),
      child: Material(
        key: ValueKey('attachment-status-${status.name}'),
        color: failed ? scheme.error : Colors.black54,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              showAttachmentStatusSheet(context, status, onRetry: onRetry),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child:
                progress ??
                Icon(
                  attachmentStatusIcon(status),
                  size: 12,
                  color: failed ? scheme.onError : Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}

/// Dosyası bu cihazda olmayan ekin kutusu: aynı simge + aynı açıklama.
class AttachmentStatusPlaceholder extends StatelessWidget {
  const AttachmentStatusPlaceholder({
    super.key,
    required this.status,
    this.showText = false,
    this.width,
    this.interactive = true,
  });

  final AttachmentStatus status;
  final bool showText;
  final double? width;

  /// false: dokunuş üst katmanın (kartta notu açar, şeritte Drive'dan indirir).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = attachmentStatusText(context, status);
    return Semantics(
      label: text,
      button: true,
      child: GestureDetector(
        behavior: interactive
            ? HitTestBehavior.opaque
            : HitTestBehavior.deferToChild,
        onTap: interactive
            ? () => showAttachmentStatusSheet(context, status)
            : null,
        child: Container(
          key: ValueKey('attachment-status-${status.name}'),
          width: width,
          color: scheme.surfaceContainerHigh,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                attachmentStatusIcon(status),
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              if (showText) ...[
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
