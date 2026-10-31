import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/presentation/settings_screen.dart';

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
  const AccountLockBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.accountRequiredBadge,
    child: Icon(
      Icons.lock_outline,
      size: 18,
      semanticLabel: context.l10n.accountRequiredBadge,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Misafirde (kendi anahtarı yokken) AI ekranlarının puan çubuğu yerine
/// duran kart: neden kapalı + iki çıkış yolu.
class GuestAiCard extends ConsumerWidget {
  const GuestAiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('guest-ai-card'),
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
                    l10n.guestAiTitle,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.guestAiBody,
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text(l10n.signInWithGoogle),
                  onPressed: () => linkGuestAccount(context, ref),
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

/// Misafirde AI araçlarını soluk ve dokunulamaz gösterir (açıklama
/// [GuestAiCard]da).
class GuestAiDim extends StatelessWidget {
  const GuestAiDim({super.key, required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) => locked
      ? IgnorePointer(child: Opacity(opacity: 0.45, child: child))
      : child;
}
