import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    // §2.3 (F79.5): simge 32, 72 dp nötr dairede; başlık `rowTitle`,
    // açıklama `body`; dikeyde %38'de (tam ortada değil — göz biraz yukarıda
    // arar). Sınırsız yükseklikte (kaydırılan liste) `Align` çocuğa sarılır.
    return Align(
      alignment: const Alignment(0, -0.24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.l),
            Text(title, textAlign: TextAlign.center, style: text.rowTitle),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                // Tam ikincil renk (F15.6): %70 saydamlık kırık beyaz ve
                // kâğıt temada 4,5:1'in altına iniyordu.
                style: text.body.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add, size: AppIconSize.s),
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
///
/// F79.6 (çevrimdışı turu): başlık eskiden "Bir şeyler ters gitti: <iki
/// cümle>" idi — boş hâl başlığı ölçüsünde üç satırlık bir paragraf. Artık
/// başlık kısa ("Bağlantı yok" / "Yüklenemedi"), neden ve ne yapılacağı
/// açıklamada; bağlantı yokken simge bulut (ekranlardaki bekleyen-yükleme
/// diliyle aynı), hata simgesi yalnız gerçek hatada.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = classifyError(error) == ErrorKind.offline;
    return EmptyState(
      key: const ValueKey('error-state'),
      icon: offline ? Icons.cloud_off_outlined : Icons.error_outline,
      title: offline ? l10n.errorStateOfflineTitle : l10n.errorStateTitle,
      subtitle: friendlyError(l10n, error),
      actionLabel: onRetry == null ? null : l10n.retry,
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}
