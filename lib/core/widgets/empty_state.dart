import 'package:flutter/material.dart';

import '../friendly_error.dart';
import '../l10n_ext.dart';

/// Boş ekran açıklaması — isteğe bağlı bir ÇIKIŞ YOLU ile.
///
/// NEDEN eylem düğmesi: boş durumlar yalnız "burada bir şey yok" diyordu.
/// Kullanıcı boş bir klasöre girdiğinde oradan çıkıp ana ekrandaki "+"yı
/// bulmak zorundaydı; oysa o anda istediği şey belliydi — bir not eklemek.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Dolu ise açıklamanın altında bir düğme çizilir. [onAction] null ise
  /// düğme HİÇ çizilmez (etiket tek başına anlamsız).
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // Tam ikincil renk (F15.6): %70 saydamlık kırık beyaz ve
                  // kâğıt temada 4,5:1'in altına iniyordu.
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tek HATA görünümü (F16.4, 2026-10-31): liste ekranları yüklenemeyince
/// hep aynı simge, aynı okunur metin (F10.4 `friendlyError`) ve — verilirse
/// — "Tekrar dene". Ekranlar `EmptyState(icon: error_outline, …)`ı ayrı
/// ayrı kuruyordu.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      key: const ValueKey('error-state'),
      icon: Icons.error_outline,
      title: l10n.genericError(friendlyError(l10n, error)),
      actionLabel: onRetry == null ? null : l10n.retry,
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}
