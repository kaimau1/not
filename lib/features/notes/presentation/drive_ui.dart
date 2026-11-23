import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error_log.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/web_attachment_cache.dart';
import '../../../core/utils/web_blob.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../../app/theme/app_design.dart' show AppTone;
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
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

/// İLK GİRİŞTE DRIVE YÖNLENDİRMESİ (kullanıcı isteği 2026-11-21: "kişi ilk
/// defa girdiğinde Drive bağlaması için yönlendirme olmalı"): Android'de
/// Google hesabıyla giren, Drive'ı henüz bağlı OLMAYAN kullanıcıya hesap
/// başına BİR KEZ kısa levha. Sessiz bağlanma denemesine ([DriveConnectedNotifier])
/// süre tanınır; izin zaten verilmişse levha çıkmaz. "Sonra" da kaydedilir
/// (her açılışta sormaz); bağlantı Ayarlar → Ekler'de kalır.
Future<void> maybeShowDriveOnboarding(BuildContext context, WidgetRef ref) async {
  if (ref.read(attachmentSyncModeProvider) != AttachmentSyncMode.drive) return;
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'drive_onboard_shown_$uid';
  if (prefs.getBool(key) ?? false) return;
  await Future<void>.delayed(const Duration(seconds: 2));
  if (!context.mounted || ref.read(driveConnectedProvider)) return;
  if (prefs.getBool(key) ?? false) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  final connect = await showAppSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = ctx.l10n;
      final scheme = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          key: const ValueKey('drive-onboarding'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_to_drive_outlined,
                size: AppIconSize.l * 2,
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.driveOnboardTitle,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.driveOnboardBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('drive-onboarding-connect'),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.link),
                  label: Text(l10n.driveOnboardConnect),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.driveOnboardLater),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (connect == true && context.mounted) await connectDrive(context, ref);
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
  messenger.hideMessage();
  ref.read(localFilesRevisionProvider.notifier).bump();
  return localFileExists(attachment.localPath);
}

/// Bu sekmede Drive'dan veya yerel tarayıcı önbelleğinden çözülmüş ekin blob
/// adresli kopyası; yoksa aynı ek.
Attachment webDriveResolved(Attachment attachment) {
  final url =
      webDriveBlobUrls.value[attachment.driveId] ??
      webLocalBlobUrls.value[attachment.id];
  return url == null ? attachment : attachment.copyWith(downloadUrl: url);
}

/// Web'de ek içeriği bulutta değil, Drive'da ya da bu tarayıcının yerel
/// önbelleğinde mi (Storage adresi yok).
bool _waitsWebDrive(Attachment a) =>
    kIsWeb &&
    !a.isUploaded &&
    !a.skipsUpload &&
    !a.isWebVideo &&
    (a.isInDrive || webLocalCacheContains(a.id));

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
    final a = widget.attachment;
    if (webLocalCacheContains(a.id)) {
      if (webLocalBlobUrls.value.containsKey(a.id)) return;
      if (!_busy.add(a.id)) return;
      try {
        final local = await webAttachmentCache.get(webLocalCacheKey(a.id));
        if (local != null) {
          rememberWebLocalBlobUrl(
            a.id,
            createBlobUrl(local.bytes, local.mimeType),
          );
        }
      } finally {
        _busy.remove(a.id);
      }
      return;
    }
    final id = a.driveId;
    if (id.isEmpty) return;
    // Yeniden bağlanınca (yeni jeton) eskiden düşenler YENİDEN denenir
    // (kullanıcı bulgusu 2026-11-03: "Drive ekleri webe hâlâ gelmiyor" —
    // ilk denemede düşen ek sayfa yenilenene dek bir daha istenmiyordu).
    if (_failedAtRevision != webDriveTokenRevision.value) {
      _failed.clear();
      _failedAtRevision = webDriveTokenRevision.value;
    }
    if (_busy.contains(id)) return;
    if (!_busy.add(id)) return;
    try {
      final cached = await webAttachmentCache.get(webDriveCacheKey(id));
      if (cached != null) {
        rememberWebDriveBlobUrl(
          id,
          createBlobUrl(cached.bytes, a.mimeType),
        );
        return;
      }
      if (_failed.contains(id)) return;
      final store = ref.read(driveStoreProvider);
      if (store == null ||
          await ref.read(driveAuthProvider).accessToken() == null) {
        return;
      }
      final bytes = await store.downloadBytes(id);
      await webAttachmentCache.put(webDriveCacheKey(id), bytes, a.mimeType);
      rememberWebDriveBlobUrl(
        id,
        createBlobUrl(bytes, a.mimeType),
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
    // Jeton gelince (şeritteki "Göster" ya da başka kutu) veya önbellek
    // dolunca bu kutu da kendiliğinden güncellenir.
    return ListenableBuilder(
      listenable: Listenable.merge([
        webDriveBlobUrls,
        webLocalBlobUrls,
        webDriveTokenRevision,
        webAttachmentCache.revision,
      ]),
      builder: (context, _) {
        final url =
            (a.isInDrive ? webDriveBlobUrls.value[a.driveId] : null) ??
            webLocalBlobUrls.value[a.id];
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
              if (a.isInDrive) _failed.remove(a.driveId);
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
/// yok, Drive kimliği yok, bu tarayıcıda da yok — dosya ekleyen cihazdan
/// henüz çıkmamış.
bool webAttachmentStuckOnDevice(Attachment a) =>
    kIsWeb &&
    !a.skipsUpload &&
    !a.isWebVideo &&
    !a.isUploaded &&
    !a.isInDrive &&
    !webLocalCacheContains(a.id);

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
    return ListenableBuilder(
      listenable: Listenable.merge([
        webDriveBlobUrls,
        webLocalBlobUrls,
        webAttachmentCache.revision,
      ]),
      builder: (context, _) {
        final driveUrls = webDriveBlobUrls.value;
        final inDrive = [
          for (final a in widget.attachments)
            if (a.isInDrive &&
                _waitsWebDrive(a) &&
                !driveUrls.containsKey(a.driveId))
              a,
        ];
        final stuck = widget.attachments
            .where(webAttachmentStuckOnDevice)
            .length;
        final needsConnect = inDrive.isNotEmpty && !_hasToken;
        if (!needsConnect && stuck == 0) return const SizedBox.shrink();
        return Padding(
          key: const ValueKey('web-attachments-banner'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs,
          ),
          // P62 PA6: tek şerit kılığı (AppBanner, dikkat tonu).
          child: AppBanner(
            tone: AppTone.attention,
            icon: needsConnect
                ? Icons.add_to_drive_outlined
                : Icons.phone_android_outlined,
            title: needsConnect
                ? l10n.webDriveBanner(inDrive.length)
                : l10n.webAttachmentsOnPhone(stuck),
            trailing: needsConnect
                ? TextButton(
                    key: const ValueKey('web-attachments-connect'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTone.attention.colors(scheme).fg,
                    ),
                    onPressed: _busy ? null : () => _connect(inDrive.first),
                    child: Text(l10n.webDriveShow),
                  )
                : null,
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
  final localUrl = webLocalBlobUrls.value[attachment.id];
  if (localUrl != null) return attachment.copyWith(downloadUrl: localUrl);
  if (webLocalCacheContains(attachment.id)) {
    final local = await webAttachmentCache.get(webLocalCacheKey(attachment.id));
    if (local != null) {
      final url = createBlobUrl(local.bytes, local.mimeType);
      rememberWebLocalBlobUrl(attachment.id, url);
      return attachment.copyWith(downloadUrl: url);
    }
  }
  final driveUrl = attachment.isInDrive
      ? webDriveBlobUrls.value[attachment.driveId]
      : null;
  if (driveUrl != null) return attachment.copyWith(downloadUrl: driveUrl);
  if (attachment.isInDrive) {
    final idb = await webAttachmentCache.get(
      webDriveCacheKey(attachment.driveId),
    );
    if (idb != null) {
      final url = createBlobUrl(idb.bytes, attachment.mimeType);
      rememberWebDriveBlobUrl(attachment.driveId, url);
      return attachment.copyWith(downloadUrl: url);
    }
  }
  if (!context.mounted) return null;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showMessage(text);
  if (!attachment.isInDrive) {
    say(l10n.driveNeededForFile);
    return null;
  }
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
    if (context.mounted) {
      ref.read(driveConnectedProvider.notifier).set(true);
    }
  }
  say(l10n.driveDownloading);
  try {
    final bytes = await store.downloadBytes(attachment.driveId);
    await webAttachmentCache.put(
      webDriveCacheKey(attachment.driveId),
      bytes,
      attachment.mimeType,
    );
    final url = createBlobUrl(bytes, attachment.mimeType);
    rememberWebDriveBlobUrl(attachment.driveId, url);
    messenger.hideMessage();
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
    final connected = ref.watch(driveConnectedProvider);
    final store = ref.watch(driveStoreProvider);
    late final Widget driveTile;
    switch (mode) {
      case AttachmentSyncMode.storage:
        driveTile = ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_outlined),
          title: Text(l10n.attachmentSyncTitle),
          subtitle: Text(l10n.storageModeInfo),
        );
      case AttachmentSyncMode.textOnly:
        driveTile = ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.text_snippet_outlined),
          title: Text(l10n.textOnlyTitle),
          subtitle: Text(l10n.textOnlyInfo),
        );
      case AttachmentSyncMode.drive:
        if (!connected || store == null) {
          _quota = null;
          driveTile = ListTile(
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
        } else {
          _quota ??= store.quota();
          driveTile = ListTile(
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
    if (!kIsWeb) return driveTile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [driveTile, const _WebCacheTile()],
    );
  }
}

class _WebCacheTile extends StatefulWidget {
  const _WebCacheTile();

  @override
  State<_WebCacheTile> createState() => _WebCacheTileState();
}

class _WebCacheTileState extends State<_WebCacheTile> {
  late Future<WebCacheStats> _statsFuture;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = webAttachmentCache.stats();
    webAttachmentCache.revision.addListener(_onRevision);
  }

  @override
  void dispose() {
    webAttachmentCache.revision.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    if (!mounted) return;
    setState(() => _statsFuture = webAttachmentCache.stats());
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await webAttachmentCache.clearDriveCache();
    if (!mounted) return;
    setState(() {
      _clearing = false;
      _statsFuture = webAttachmentCache.stats();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(context.l10n.webCacheCleared);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<WebCacheStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final s = snap.data;
        final hasDriveCache = s != null && s.driveCount > 0;
        return ListTile(
          key: const ValueKey('web-cache-tile'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.offline_pin_outlined),
          title: Text(l10n.webCacheTitle),
          subtitle: Text(
            hasDriveCache
                ? l10n.webCacheInfo(s.driveCount, formatBytes(s.driveBytes))
                : l10n.webCacheEmpty,
          ),
          trailing: hasDriveCache
              ? TextButton(
                  key: const ValueKey('web-cache-clear'),
                  onPressed: _clearing ? null : _clear,
                  child: Text(l10n.webCacheClear),
                )
              : null,
        );
      },
    );
  }
}
