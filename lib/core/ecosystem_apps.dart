import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme/app_tokens.dart';
import 'l10n_ext.dart';
import 'play_build.dart';
import '../features/settings/settings_providers.dart';

/// Kardeş uygulama **Dosyalarım** ile iki yönlü paylaşım, belge açma ve ortak
/// ekosistem tanıtım kartı.
abstract final class EcosystemApps {
  static const String dosyaOkuyucuPackage = 'com.dosyaokuyucu.dosya_okuyucu';
  static final Uri dosyaOkuyucuPlayUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$dosyaOkuyucuPackage',
  );
  static final Uri dosyaOkuyucuMarketUri = Uri.parse(
    'market://details?id=$dosyaOkuyucuPackage',
  );

  static const String _promoHiddenUntilKey = 'dosyalarim_promo_hidden_until';
  static const Duration promoHideDuration = Duration(days: 30);

  static bool shouldShowPromo(SharedPreferences prefs, {DateTime? now}) {
    final until = prefs.getInt(_promoHiddenUntilKey) ?? 0;
    return (now ?? DateTime.now()).millisecondsSinceEpoch >= until;
  }

  static Future<void> dismissPromo(
    SharedPreferences prefs, {
    DateTime? now,
  }) async {
    final next = (now ?? DateTime.now()).add(promoHideDuration);
    await prefs.setInt(_promoHiddenUntilKey, next.millisecondsSinceEpoch);
  }

  /// Play Store üzerinden Dosyalarım sayfasını açar (Android'de market://, web/masaüstünde https://).
  static Future<bool> openDosyaOkuyucuStore() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (await launchUrl(
        dosyaOkuyucuMarketUri,
        mode: LaunchMode.externalApplication,
      )) {
        return true;
      }
    }
    return launchUrl(dosyaOkuyucuPlayUri, mode: LaunchMode.externalApplication);
  }

  /// Bir yerel belgeyi ya da not özetini sistem paylaşım sayfası üzerinden
  /// Dosyalarım uygulamasına veya seçilen alıcıya gönderir.
  static Future<void> handoffToDosyaOkuyucu({
    String? filePath,
    String? text,
    String? subject,
  }) async {
    if (filePath != null &&
        filePath.isNotEmpty &&
        await File(filePath).exists()) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: text, subject: subject),
      );
      return;
    }
    if (text != null && text.trim().isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(text: text.trim(), subject: subject),
      );
      return;
    }
    await openDosyaOkuyucuStore();
  }
}

/// Dosyalarım kardeş uygulaması için zorlamasız Bento tanıtım kartı.
/// Kapatılınca 30 gün gizlenir; sayaç/açılır reklam yoktur.
class CrossAppPromoCard extends ConsumerStatefulWidget {
  const CrossAppPromoCard({super.key, this.onDismissed});

  final VoidCallback? onDismissed;

  @override
  ConsumerState<CrossAppPromoCard> createState() => _CrossAppPromoCardState();
}

class _CrossAppPromoCardState extends ConsumerState<CrossAppPromoCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    if (PlayBuild.enabled || _hidden) return const SizedBox.shrink();
    final prefs = ref.watch(sharedPreferencesProvider);
    if (!EcosystemApps.shouldShowPromo(prefs)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);

    return DecoratedBox(
      key: const ValueKey('cross-app-dosyalarim-card'),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: tokens.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s),
                    child: Icon(
                      Icons.folder_copy_outlined,
                      size: AppIconSize.l,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.ecosystemDosyalarimTitle, style: text.rowTitle),
                      const SizedBox(height: AppSpace.xs),
                      Text(l10n.ecosystemDosyalarimSubtitle, style: text.meta),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('cross-app-promo-dismiss'),
                  tooltip: l10n.ecosystemDismiss,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close,
                    size: AppIconSize.s,
                    color: scheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() => _hidden = true);
                    unawaited(EcosystemApps.dismissPromo(prefs));
                    widget.onDismissed?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                key: const ValueKey('cross-app-promo-cta'),
                onPressed: () =>
                    unawaited(EcosystemApps.openDosyaOkuyucuStore()),
                icon: const Icon(Icons.open_in_new, size: AppIconSize.s),
                label: Text(l10n.ecosystemGetApp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
