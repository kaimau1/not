import '../features/settings/settings_providers.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n_ext.dart';
import 'widgets/undo_snackbar.dart' show rootScaffoldMessengerKey;

/// **İSTEMCİ VERİ SÜRÜMÜ** (F1.5, 2026-10-19). Bu derlemenin güvenle
/// okuyup YAZABİLDİĞİ veri biçiminin numarası. Yeni bir sürüm, eski
/// istemcinin bozacağı bir biçim getirdiğinde (yeni ek türü, alanın anlamı
/// değişti) bu sayı artırılır; sonra Firestore konsolunda `config/app`
/// belgesinin `minClient` alanı aynı sayıya çekilir — eski istemciler
/// "Güncelle" şeridini görür, editör salt okunur açılır.
///
/// NEDEN derleme numarası (`package_info` build number) DEĞİL: web derlemesi
/// `--build-number` almıyor, hep 1. Sabit her platformda aynı anlamı taşır.
///
/// 2 (Faz 3): defter → sayfalı not (F3.5), büyük notların çizim/balon/PDF
/// işaretleri ayrı belgede (F3.13). Eski istemci bölünmüş notun çizimlerini
/// görmez; telefonlar güncellenince `minClient: 2` yazılmalı.
///
/// 3 (2026-10-20): yıldız ve çerçeve yeniden AYRI alanlar. 2'deki istemci
/// `starred`ı sabit sayar ve her yazımda `starred: false` yazar (yıldızları
/// siler), yalnız çerçeveli notu renkli zemin gösterir. Telefonlar bu
/// sürüme geçince `minClient: 3` yazılmalı.
const int kClientDataVersion = 3;

/// İndirme adresi: CI her `[apk]` derlemesini GitHub Releases'a koyar.
const String kReleasesUrl = 'https://github.com/kaimau1/not/releases/latest';

/// `config/app.minClient` — kural: herkes okur, istemci yazamaz.
/// Belge/alan yoksa ya da okunamazsa 0 (kapı kapalı).
final minClientVersionProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .map((d) => (d.data()?['minClient'] as num?)?.toInt() ?? 0)
      .handleError((Object _) {});
});

/// **"Yeni sürüm var"** (F18.21, 2026-11-02): CI `release` işi Release'i
/// yayınlayınca `config/app` belgesine `latestBuild` (koşu numarası =
/// versionCode) ve `latestName` (`1.1.N`) yazar. APK elle kurulduğu için
/// telefon yeni sürümden habersizdi. Belge yoksa/okunamazsa null.
final latestReleaseProvider = StreamProvider<({int build, String name})?>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .map((d) {
        final build = (d.data()?['latestBuild'] as num?)?.toInt();
        if (build == null || build <= 0) return null;
        return (build: build, name: d.data()?['latestName'] as String? ?? '');
      })
      .handleError((Object _) {});
});

/// Bu kurulumun derleme numarası (PackageInfo; okunamazsa null).
final installedBuildProvider = FutureProvider<int?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber);
  } catch (_) {
    return null;
  }
});

/// Yeni sürüm adı (yalnız Android — web her zaman son sürümdür); yoksa null.
final newVersionAvailableProvider = Provider<String?>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  final latest = ref.watch(latestReleaseProvider).value;
  final installed = ref.watch(installedBuildProvider).value;
  return isNewerBuild(latest?.build, installed)
      ? (latest!.name.isEmpty ? '${latest.build}' : latest.name)
      : null;
});

@visibleForTesting
bool isNewerBuild(int? latest, int? installed) =>
    latest != null && installed != null && installed > 1 && latest > installed;

/// Yeni sürümü BİR KEZ (sürüm başına) kısa bir bildirimle söyler; sonrası
/// Ayarlar → Hakkında'daki satırda.
class NewVersionNotice extends ConsumerStatefulWidget {
  const NewVersionNotice({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NewVersionNotice> createState() => _NewVersionNoticeState();
}

class _NewVersionNoticeState extends ConsumerState<NewVersionNotice> {
  static const _prefsKey = 'update_notice_shown_for';

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(newVersionAvailableProvider, (prev, next) {
      if (next == null || next == prev) return;
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getString(_prefsKey) == next) return;
      prefs.setString(_prefsKey, next);
      final messenger = rootScaffoldMessengerKey.currentState;
      final l10n = context.l10n;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.updateAvailable(next)),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l10n.updateDownload,
            onPressed: openReleasesPage,
          ),
        ),
      );
    });
    return widget.child;
  }
}

/// Bu istemci güncellenmeden veri YAZMAMALI mı?
final updateRequiredProvider = Provider<bool>((ref) {
  final min = ref.watch(minClientVersionProvider).value ?? 0;
  return isUpdateRequired(min);
});

@visibleForTesting
bool isUpdateRequired(int minClient, {int current = kClientDataVersion}) =>
    current < minClient;

Future<void> openReleasesPage() =>
    launchUrl(Uri.parse(kReleasesUrl), mode: LaunchMode.externalApplication);

/// Uygulamanın tepesindeki "güncelle" şeridi; kapı kapalıyken ağaca hiçbir
/// şey eklemez.
class UpdateRequiredBanner extends ConsumerWidget {
  const UpdateRequiredBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateRequiredProvider)) return child;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: scheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.system_update, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.updateRequiredBody,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: openReleasesPage,
                    child: Text(l10n.updateAction),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Bu sürümün tanımadığı (daha yeni sürümde eklenmiş) eke dokunulunca:
/// açılmaz, düzenlenmez — yalnız neden açılmadığı söylenir.
Future<void> showUnsupportedAttachmentDialog(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update),
      title: Text(l10n.attachmentUnsupportedTitle),
      content: Text(l10n.attachmentUnsupportedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            openReleasesPage();
          },
          child: Text(l10n.updateAction),
        ),
      ],
    ),
  );
}
