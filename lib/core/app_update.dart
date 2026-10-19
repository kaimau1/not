import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n_ext.dart';

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
const int kClientDataVersion = 2;

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
