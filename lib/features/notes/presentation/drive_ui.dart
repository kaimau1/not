import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error_log.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/web_blob.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/attachment_repository.dart';
import '../data/drive_store.dart';
import '../domain/attachment.dart';
import '../../../core/friendly_error.dart';

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
    say(l10n.driveConnectFailed(friendlyError(l10n, e)));
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
      ..showMessage(l10n.attachmentFailed(friendlyError(l10n, e)));
    return false;
  }
  messenger.hideCurrentSnackBar();
  ref.read(localFilesRevisionProvider.notifier).bump();
  return localFileExists(attachment.localPath);
}

/// Web'de Drive'dan indirilmiş eklerin `blob:` adresleri (sekme boyunca).
/// Değişince açık [WebDriveGate]'ler yeniden bakar.
final _webDriveUrls = ValueNotifier<Map<String, String>>(const {});

void _rememberWebDriveUrl(String driveId, String url) =>
    _webDriveUrls.value = {..._webDriveUrls.value, driveId: url};

/// Bu sekmede Drive'dan inmiş ekin blob adresli kopyası; inmediyse aynı ek.
Attachment webDriveResolved(Attachment attachment) {
  final url = _webDriveUrls.value[attachment.driveId];
  return url == null ? attachment : attachment.copyWith(downloadUrl: url);
}

/// Web'de ekin içeriği Drive'da mı (dosya yok, Storage adresi de yok).
bool _waitsWebDrive(Attachment a) =>
    kIsWeb && a.isInDrive && !a.isUploaded;

/// **WEB: DRIVE'DAKİ EKİ NOTUN İÇİNDE GÖSTER** (kullanıcı bulgusu 2026-11-02:
/// "web'de ekler gelmiyor"). KÖK NEDEN: Android'de Google hesabının ekleri
/// Drive'a gider, `downloadUrl` boştur; görsel, kart, ek şeridi ve PDF bu
/// durumda yalnız bulut simgesi çiziyor, Drive'dan hiç istemiyordu (indirme
/// yalnız ek şeridinden dokununca vardı). Ölçüm: Storage CORS'u `*`, Wasm'da
/// ağ görseli yükleniyor — sorun gösterimde değil, bu yolun eksikliğinde.
///
/// Jeton varsa ek kendiliğinden iner; yoksa dokununca "Drive'a bağlan" sorulur
/// (Google penceresi ancak bir dokunuşla açılır). Bağlandıktan sonra açık
/// kutular sırayla iner. Android'de ve Storage'daki ekte hiçbir şey yapmaz.
class WebDriveGate extends ConsumerStatefulWidget {
  const WebDriveGate({
    super.key,
    required this.attachment,
    required this.builder,
  });

  final Attachment attachment;

  /// İçerik hazır: ek, `downloadUrl`'i dolu kopyayla verilir.
  final Widget Function(BuildContext context, Attachment attachment) builder;

  @override
  ConsumerState<WebDriveGate> createState() => _WebDriveGateState();
}

class _WebDriveGateState extends ConsumerState<WebDriveGate> {
  /// Aynı ek birkaç kutuda açıkken bir kez iner; başarısız olan kendiliğinden
  /// yeniden denenmez (izin yok, ek başkasının Drive'ında) — dokunuş dener.
  static final _busy = <String>{};
  static final _failed = <String>{};
  static int _failedAtRevision = 0;

  Future<void> _fetch() async {
    final id = widget.attachment.driveId;
    // Yeniden bağlanınca (yeni jeton) eskiden düşenler YENİDEN denenir
    // (kullanıcı bulgusu 2026-11-03: "Drive ekleri webe hâlâ gelmiyor" —
    // ilk denemede düşen ek sayfa yenilenene dek bir daha istenmiyordu).
    if (_failedAtRevision != webDriveTokenRevision.value) {
      _failed.clear();
      _failedAtRevision = webDriveTokenRevision.value;
    }
    if (_busy.contains(id) || _failed.contains(id)) return;
    final store = ref.read(driveStoreProvider);
    if (store == null || await ref.read(driveAuthProvider).accessToken() == null) {
      return;
    }
    if (!_busy.add(id)) return;
    try {
      final bytes = await store.downloadBytes(id);
      _rememberWebDriveUrl(
        id,
        createBlobUrl(bytes, widget.attachment.mimeType),
      );
    } catch (e) {
      debugPrint('Drive eki inmedi ($id): $e');
      ErrorLog.record('web-drive-fetch', e);
      _failed.add(id);
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(l10n.attachmentFailed(friendlyError(l10n, e)));
      }
    } finally {
      _busy.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    if (!_waitsWebDrive(a)) return widget.builder(context, a);
    // Jeton gelince (şeritteki "Göster" ya da başka kutu) bu kutu da iner.
    return ListenableBuilder(
      listenable: Listenable.merge([_webDriveUrls, webDriveTokenRevision]),
      builder: (context, _) {
        final url = _webDriveUrls.value[a.driveId];
        if (url != null) {
          return widget.builder(context, a.copyWith(downloadUrl: url));
        }
        unawaited(_fetch());
        // Görselin önizlemesi varsa asıl dosya inene dek o çizilir (Storage,
        // izin gerekmez); not şeridi "Göster" ile tam boyu indirir.
        if (a.kind == AttachmentKind.image && a.thumbUrl.isNotEmpty) {
          return widget.builder(context, a.copyWith(downloadUrl: a.thumbUrl));
        }
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: scheme.surfaceContainerHigh,
          child: InkWell(
            key: ValueKey('web-drive-${a.id}'),
            onTap: () {
              _failed.remove(a.driveId);
              unawaited(resolveWebDriveAttachment(context, ref, a));
            },
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_to_drive_outlined,
                      color: scheme.onSurfaceVariant,
                      semanticLabel: context.l10n.webDriveTapToOpen,
                    ),
                    if (box.maxWidth >= 120 && box.maxHeight >= 72)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Text(
                          context.l10n.webDriveTapToOpen,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Web'de bu ekin içeriğine HİÇBİR yoldan ulaşılamıyor mu: Storage adresi
/// yok, Drive kimliği yok — dosya ekleyen cihazdan (telefon) henüz çıkmamış.
bool webAttachmentStuckOnDevice(Attachment a) =>
    kIsWeb &&
    !a.skipsUpload &&
    !a.isWebVideo &&
    !a.isUploaded &&
    !a.isInDrive;

/// **WEB: NOTUN EKLERİ İÇİN TEK ŞERİT** (kullanıcı bulgusu 2026-11-02: "ekler
/// hâlâ webte gelmiyor"). İki ayrı durum açıkça söylenir:
/// * Ekler Drive'da, bu sekmede izin yok → "N ek Google Drive'da · Göster":
///   TEK dokunuşla bağlanır ve hepsi iner (eskiden her kutuya ayrı ayrı
///   dokunmak gerekiyordu, şerit yoktu).
/// * Ekler telefondan hiç çıkmamış (Drive telefonda bağlanmamış) → nasıl
///   düzeltileceğini söyler; web'in yapabileceği bir şey yok.
class WebAttachmentsBanner extends ConsumerStatefulWidget {
  const WebAttachmentsBanner({super.key, required this.attachments});

  final List<Attachment> attachments;

  @override
  ConsumerState<WebAttachmentsBanner> createState() =>
      _WebAttachmentsBannerState();
}

class _WebAttachmentsBannerState extends ConsumerState<WebAttachmentsBanner> {
  bool _busy = false;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    webDriveTokenRevision.addListener(_check);
    _check();
  }

  @override
  void dispose() {
    webDriveTokenRevision.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final token = await ref.read(driveAuthProvider).accessToken();
    if (mounted && (token != null) != _hasToken) {
      setState(() => _hasToken = token != null);
    }
  }

  Future<void> _connect(Attachment first) async {
    setState(() => _busy = true);
    // Diyalog + bağlan + ilk eki indir; jeton gelince öbür kutular kendisi
    // iner (bkz. WebDriveGate).
    await resolveWebDriveAttachment(context, ref, first);
    await _check();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: _webDriveUrls,
      builder: (context, urls, _) {
        final inDrive = [
          for (final a in widget.attachments)
            if (_waitsWebDrive(a) && !urls.containsKey(a.driveId)) a,
        ];
        final stuck = widget.attachments
            .where(webAttachmentStuckOnDevice)
            .length;
        final needsConnect = inDrive.isNotEmpty && !_hasToken;
        if (!needsConnect && stuck == 0) return const SizedBox.shrink();
        return Padding(
          key: const ValueKey('web-attachments-banner'),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Material(
            color: scheme.secondaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              child: Row(
                children: [
                  Icon(
                    needsConnect
                        ? Icons.add_to_drive_outlined
                        : Icons.phone_android_outlined,
                    size: 20,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      needsConnect
                          ? l10n.webDriveBanner(inDrive.length)
                          : l10n.webAttachmentsOnPhone(stuck),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (needsConnect)
                    TextButton(
                      key: const ValueKey('web-attachments-connect'),
                      onPressed: _busy ? null : () => _connect(inDrive.first),
                      child: Text(l10n.webDriveShow),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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
  final cached = _webDriveUrls.value[attachment.driveId];
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
                // Sessiz yutma YOK (2026-11-03): açılır pencere engeli, hesap
                // uyuşmazlığı vb. kullanıcıya söylenmeden "ekler gelmiyor"
                // olarak kalıyordu.
                debugPrint('Drive (web) bağlanamadı: $e');
                ErrorLog.record('web-drive-connect', e);
                say(l10n.attachmentFailed(friendlyError(l10n, e)));
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
    _rememberWebDriveUrl(attachment.driveId, url);
    messenger.hideCurrentSnackBar();
    return attachment.copyWith(downloadUrl: url);
  } catch (e) {
    say(l10n.attachmentFailed(friendlyError(l10n, e)));
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
