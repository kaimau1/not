import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/web_blob.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/attachment_repository.dart';
import '../data/drive_store.dart';
import '../domain/attachment.dart';

/// Google Drive'ı BAĞLAR: onay ekranı açılır, ardından Drive'a gerçekten
/// ulaşılabildiği sınanır (Cloud projesinde Drive API kapalıysa bağlantı
/// "tamam" görünüp her yükleme sessizce düşerdi). Başarılıysa true.
Future<bool> connectDrive(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showMessage(text);
  final auth = ref.read(driveAuthProvider);
  try {
    if (!await auth.connect()) {
      say(l10n.driveConnectFailed(''));
      return false;
    }
    final probe = DriveStore(auth);
    final problem = await probe.probe();
    probe.close();
    if (problem != null) {
      say(
        problem.contains('accessNotConfigured') ||
                problem.contains('has not been used') ||
                problem.contains('SERVICE_DISABLED')
            ? l10n.driveApiDisabled
            : l10n.driveConnectFailed(problem),
      );
      return false;
    }
    ref.read(driveConnectedProvider.notifier).set(true);
    say(l10n.driveConnected);
    return true;
  } on GoogleSignInException catch (e) {
    // Kullanıcı onay ekranını kapattı: hata değil, sessiz.
    if (e.code == GoogleSignInExceptionCode.canceled) return false;
    say(l10n.driveConnectFailed(e.description ?? e.code.name));
    return false;
  } catch (e) {
    say(l10n.driveConnectFailed('$e'));
    return false;
  }
}

Future<void> disconnectDrive(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  await ref.read(driveAuthProvider).disconnect();
  ref.read(driveConnectedProvider.notifier).set(false);
  messenger
    ..hideCurrentSnackBar()
    ..showMessage(l10n.driveDisconnected);
}

/// Ek Drive'da ama BU cihazda yerel kopyası yoksa ŞİMDİ indirir (kullanıcı
/// eki açmak istedi — arka plan kuyruğunu beklemesin). Sonunda dosya
/// cihazdaysa true.
Future<bool> fetchAttachmentNow(
  BuildContext context,
  WidgetRef ref,
  Attachment attachment,
) async {
  if (localFileExists(attachment.localPath)) return true;
  if (!attachment.isInDrive) return false;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(attachmentRepositoryProvider);
  if (repo?.drive == null) {
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(l10n.driveNeededForFile);
    return false;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showMessage(l10n.driveDownloading);
  try {
    await repo!.fetchFromDrive(attachment);
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(l10n.attachmentFailed('$e'));
    return false;
  }
  messenger.hideCurrentSnackBar();
  ref.read(localFilesRevisionProvider.notifier).bump();
  return localFileExists(attachment.localPath);
}

/// Web'de Drive'dan indirilmiş eklerin `blob:` adresleri (sekme boyunca).
final _webDriveUrls = <String, String>{};

/// **WEB: DRIVE'DAKİ EKİ AÇ** (F4.4). Tarayıcıda yerel dosya yok: ek Drive'dan
/// belleğe indirilir ve `blob:` adresiyle (Storage'daki bir ekmiş gibi
/// `downloadUrl`'de) döner; görüntüleyiciler değişmeden açar. Jeton yoksa
/// (sayfa yeni açıldı / süre doldu) önce "Drive'a bağlan" sorulur — Google
/// penceresi bir DOKUNUŞLA açılmalı, o yüzden iletişim kutusunun düğmesinden.
Future<Attachment?> resolveWebDriveAttachment(
  BuildContext context,
  WidgetRef ref,
  Attachment attachment,
) async {
  final cached = _webDriveUrls[attachment.driveId];
  if (cached != null) return attachment.copyWith(downloadUrl: cached);
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showMessage(text);
  final store = ref.read(driveStoreProvider);
  if (store == null) {
    say(l10n.driveNeededForFile);
    return null;
  }
  final auth = ref.read(driveAuthProvider);
  if (await auth.accessToken() == null) {
    if (!context.mounted) return null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.add_to_drive_outlined),
        title: Text(l10n.driveWebConnectTitle),
        content: Text(l10n.driveWebConnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              var connected = false;
              try {
                connected = await auth.connect();
              } catch (e) {
                debugPrint('Drive (web) bağlanamadı: $e');
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, connected);
              }
            },
            child: Text(l10n.driveWebConnectButton),
          ),
        ],
      ),
    );
    if (ok != true) return null;
  }
  say(l10n.driveDownloading);
  try {
    final bytes = await store.downloadBytes(attachment.driveId);
    final url = createBlobUrl(bytes, attachment.mimeType);
    _webDriveUrls[attachment.driveId] = url;
    messenger.hideCurrentSnackBar();
    return attachment.copyWith(downloadUrl: url);
  } catch (e) {
    say(l10n.attachmentFailed('$e'));
    return null;
  }
}

/// Ayarlar → Senkron'un başındaki EK SENKRONU satırı: kip, bağlantı durumu,
/// Drive kullanımı ve Bağla / Bağlantıyı kes.
class AttachmentSyncTile extends ConsumerStatefulWidget {
  const AttachmentSyncTile({super.key});

  @override
  ConsumerState<AttachmentSyncTile> createState() => _AttachmentSyncTileState();
}

class _AttachmentSyncTileState extends ConsumerState<AttachmentSyncTile> {
  bool _busy = false;
  Future<({int used, int? limit})?>? _quota;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mode = ref.watch(attachmentSyncModeProvider);
    final store = ref.watch(driveStoreProvider);
    switch (mode) {
      case AttachmentSyncMode.storage:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_outlined),
          title: Text(l10n.attachmentSyncTitle),
          subtitle: Text(l10n.storageModeInfo),
        );
      case AttachmentSyncMode.textOnly:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.text_snippet_outlined),
          title: Text(l10n.textOnlyTitle),
          subtitle: Text(l10n.textOnlyInfo),
        );
      case AttachmentSyncMode.drive:
        break;
    }
    if (store == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.add_to_drive_outlined),
        title: Text(l10n.driveConnectTitle),
        subtitle: Text(l10n.driveConnectInfo),
        isThreeLine: true,
        trailing: FilledButton.tonal(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  await connectDrive(context, ref);
                  if (mounted) setState(() => _busy = false);
                },
          child: Text(l10n.driveConnect),
        ),
      );
    }
    _quota ??= store.quota();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.add_to_drive, color: theme.colorScheme.primary),
      title: Text(l10n.driveSectionTitle),
      subtitle: FutureBuilder<({int used, int? limit})?>(
        future: _quota,
        builder: (context, snap) {
          final q = snap.data;
          return Text(
            q == null
                ? l10n.driveConnectedInfo
                : '${l10n.driveConnectedInfo}\n${l10n.driveUsage(formatBytes(q.used), q.limit == null ? '∞' : formatBytes(q.limit!))}',
          );
        },
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: () async {
          await disconnectDrive(context, ref);
          if (mounted) setState(() => _quota = null);
        },
        child: Text(l10n.driveDisconnect),
      ),
    );
  }
}
