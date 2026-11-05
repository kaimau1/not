import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ai/data/ai_gate.dart';

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
    };
    if (status == AiAvailability.ready) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('ai-status-card'),
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: scheme.onSecondaryContainer),
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
    };

/// Tek açıklama levhası (F42.2).
Future<void> showAiStatusSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
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
  Widget build(BuildContext context, WidgetRef ref) => Icon(
    ref.watch(aiAvailabilityProvider) == AiAvailability.ready
        ? Icons.auto_awesome
        : Icons.lock_outline,
    size: size,
  );
}

/// Yapay zekâ kapalıyken araçları soluk ve dokunulamaz gösterir (açıklama
/// [AiStatusCard]da).
class AiStatusDim extends StatelessWidget {
  const AiStatusDim({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) => locked
      ? IgnorePointer(child: Opacity(opacity: 0.45, child: child))
      : child;
}
