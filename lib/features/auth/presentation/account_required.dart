import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/ai_policy.dart';

/// **MİSAFİRDE HESAP GEREKTİREN İŞLER** (F10.5, 2026-10-31).
///
/// KÖK NEDEN: Kişiler, Ortak çalışanlar, Kopya gönder ve Birlikte düzenle
/// misafirde ya hiç görünmüyor ya da dokununca tek satırlık bir bildirim
/// veriyordu; AI ekranları "30/30 puan" gösterip her araçta hata dönüyordu.
/// Artık girişler kilit rozetiyle görünür ([AccountLockBadge]) ve dokununca
/// hep AYNI levha açılır: neden + "Google ile giriş yap" (hesap BAĞLANIR,
/// notlar yerinde kalır — bkz. [linkGuestAccount]).
Future<void> showAccountRequiredSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline, size: 32, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                l10n.accountRequiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountRequiredBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('account-required-sign-in'),
                icon: const Icon(Icons.login),
                label: Text(l10n.signInWithGoogle),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  linkGuestAccount(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Misafirde kilitli girişin sonundaki küçük kilit (ekran okuyucu "Google
/// hesabı gerekir" der).
class AccountLockBadge extends StatelessWidget {
  const AccountLockBadge({super.key, this.size = 18});

  /// Simge köşesinde (ray, hızlı satır) 14.
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.accountRequiredBadge,
    child: Icon(
      Icons.lock_outline,
      size: size,
      semanticLabel: context.l10n.accountRequiredBadge,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Yapay zekâ neden kullanılamıyor + çözümü (F10.5 misafir kartından büyüdü,
/// F42.2): AI ekranlarında ve [showAiStatusSheet]te aynı kart.
class AiStatusCard extends ConsumerWidget {
  const AiStatusCard({super.key, this.onResolved});

  /// "Tekrar dene"den sonra (levha kendini kapatsın diye).
  final VoidCallback? onResolved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(aiAvailabilityProvider);
    final renews = status == AiAvailability.quotaOut
        ? ref.watch(aiQuotaRenewsAtProvider)
        : null;
    final title = aiStatusTitle(l10n, status);
    final body = switch (status) {
      AiAvailability.ready => '',
      AiAvailability.guest => l10n.guestAiBody,
      AiAvailability.needsKey => l10n.aiErrBuiltInOff,
      AiAvailability.webBuiltInOff => l10n.aiStatusWebOffBody,
      AiAvailability.quotaOut => l10n.aiStatusQuotaBody(
        renews == null
            ? ''
            : MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(renews),
                alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                  context,
                ),
              ),
      ),
      AiAvailability.turnedOff => l10n.aiOffBody,
      AiAvailability.paused => l10n.aiPausedBody,
      AiAvailability.needsPro => l10n.aiNeedsProBody,
      // Rıza (PL3 a): ne gönderilir, nereye, "yanılabilir", nasıl kapatılır.
      AiAvailability.consentNeeded => [
        l10n.aiConsentWhat,
        l10n.aiConsentWhere,
        l10n.aiConsentMistakes,
        l10n.aiConsentTurnOff,
      ].join('\n\n'),
    };
    if (status == AiAvailability.ready) return const SizedBox.shrink();
    final consent = status == AiAvailability.consentNeeded;
    // P62 PA4: ham Card yerine grup yüzeyi; renk dikkat rolü (aynen).
    return DecoratedBox(
      key: const ValueKey('ai-status-card'),
      decoration: AppSurface.group(
        Theme.of(context),
      ).copyWith(color: scheme.secondaryContainer),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  consent ? Icons.auto_awesome : Icons.lock_outline,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(color: scheme.onSecondaryContainer)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == AiAvailability.guest)
                  FilledButton.icon(
                    icon: const Icon(Icons.login),
                    label: Text(l10n.signInWithGoogle),
                    onPressed: () => linkGuestAccount(context, ref),
                  ),
                if (status == AiAvailability.needsKey ||
                    status == AiAvailability.webBuiltInOff)
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(aiBuiltInOffProvider.notifier).set(false);
                      onResolved?.call();
                    },
                    child: Text(l10n.retry),
                  ),
                // PL6 katman kapısı (yalnız Play): Pro ekranına.
                if (status == AiAvailability.needsPro)
                  FilledButton(
                    key: const ValueKey('ai-needs-pro'),
                    onPressed: () {
                      // Levha kapanınca bu bağlam ağaçtan düşer: önce al.
                      final router = GoRouter.of(context);
                      onResolved?.call();
                      unawaited(router.push('/premium'));
                    },
                    child: Text(l10n.aiNeedsProSee),
                  ),
                if (status == AiAvailability.turnedOff)
                  FilledButton.tonal(
                    key: const ValueKey('ai-turn-on'),
                    onPressed: () {
                      ref.read(aiTurnedOffProvider.notifier).set(false);
                      onResolved?.call();
                    },
                    child: Text(l10n.aiOffTurnOn),
                  ),
                if (consent) ...[
                  FilledButton(
                    key: const ValueKey('ai-consent-accept'),
                    onPressed: () {
                      ref.read(aiConsentProvider.notifier).accept();
                      onResolved?.call();
                    },
                    child: Text(l10n.aiConsentAccept),
                  ),
                  TextButton(
                    key: const ValueKey('ai-consent-decline'),
                    onPressed: onResolved,
                    child: Text(l10n.aiConsentDecline),
                  ),
                ],
                if (!consent &&
                    status != AiAvailability.turnedOff &&
                    status != AiAvailability.paused &&
                    status != AiAvailability.needsPro)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.key_outlined),
                    label: Text(l10n.guestAiAddKey),
                    onPressed: () => context.push('/settings?area=ai'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Durumun tek satırlık adı: kart başlığı ve düğme ipucu aynı metin.
String aiStatusTitle(AppLocalizations l10n, AiAvailability status) =>
    switch (status) {
      AiAvailability.ready => l10n.aiTitle,
      AiAvailability.guest => l10n.guestAiTitle,
      AiAvailability.needsKey => l10n.aiStatusBuiltInOffTitle,
      AiAvailability.webBuiltInOff => l10n.aiStatusWebOffTitle,
      AiAvailability.quotaOut => l10n.aiStatusQuotaTitle,
      AiAvailability.turnedOff => l10n.aiOffTitle,
      AiAvailability.paused => l10n.aiPausedTitle,
      AiAvailability.consentNeeded => l10n.aiConsentTitle,
      AiAvailability.needsPro => l10n.aiNeedsProTitle,
    };

/// Tek açıklama levhası (F42.2).
Future<void> showAiStatusSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      // Kaydırılabilir: rıza kartı (PL3) dört paragraf; kısa ekranda
      // düğmeler levhanın dışında kalmasın.
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiStatusCard(onResolved: () => Navigator.pop(sheetContext)),
          ],
        ),
      ),
    );

/// AI düğmesinin ilk satırı: hazır değilse açıklama levhası + false. Arka plan
/// işleri bunu ÇAĞIRMAZ (bildirim basmaz, sessizce geçer).
bool ensureAiReady(BuildContext context, WidgetRef ref) {
  if (ref.read(aiAvailabilityProvider) == AiAvailability.ready) return true;
  unawaited(showAiStatusSheet(context));
  return false;
}

/// AI düğmesi simgesi: hazırsa ✨, değilse kilit (durum basmadan görünür).
class AiIcon extends ConsumerWidget {
  const AiIcon({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = !ref.watch(aiAvailabilityProvider).looksLocked;
    // AI kimliği = tertiary (DENEYIM §2.2 K-D1). Dolu düğmenin içinde
    // (onPrimary) ya da devre dışıyken (saydam) miras renk kalır — okunurluk.
    final scheme = Theme.of(context).colorScheme;
    final inherited = IconTheme.of(context).color;
    final keep =
        !ready ||
        inherited == scheme.onPrimary ||
        (inherited != null && inherited.a < 1);
    return Icon(
      ready ? Icons.auto_awesome : Icons.lock_outline,
      size: size,
      color: keep ? null : scheme.tertiary,
    );
  }
}

/// Yapay zekâ kapalıyken araçları soluk ve dokunulamaz gösterir (açıklama
/// [AiStatusCard]da).
/// Çevrimdışı AI kartı (DENEYIM F79.6 (4)): [AiStatusCard] ile aynı yer ve
/// görünüş, kilit yerine bulut simgesi; eylem yok — bağlantı gelince
/// `isOfflineProvider` değişir, kart kendiliğinden kalkar.
class AiOfflineCard extends StatelessWidget {
  const AiOfflineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('ai-offline-card'),
      decoration: AppSurface.group(
        Theme.of(context),
      ).copyWith(color: scheme.secondaryContainer),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aiOfflineTitle,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aiOfflineBody,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class AiStatusDim extends StatelessWidget {
  const AiStatusDim({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) => locked
      ? IgnorePointer(child: Opacity(opacity: 0.45, child: child))
      : child;
}
