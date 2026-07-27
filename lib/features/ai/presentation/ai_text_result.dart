import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/gemini_service.dart';

/// Düz metin döndüren AI çıktılarının (brifing, öneriler, haftalık özet)
/// ortak gövdesi: yükleniyor / hata + "Tekrar dene" / boş durum / başlık +
/// metin kartı. Ekranlar yalnız metinlerini ve ikonlarını verir.
class AiTextResult extends StatelessWidget {
  const AiTextResult({
    super.key,
    required this.value,
    required this.loadingText,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.header,
    required this.onRetry,
  });

  final AsyncValue<String> value;

  /// Üretim sürerken gösterilen satır ("Brifing hazırlanıyor…" gibi).
  final String loadingText;
  final IconData emptyIcon;
  final String emptyTitle;

  /// Metin kartının üstündeki küçük gri satır (tarih ya da açıklama).
  final String header;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return value.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(loadingText),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e is GeminiException && e.isAuthError
                    ? l10n.aiNoApiKey
                    : l10n.aiError(e.toString()),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ),
      data: (text) {
        if (text.isEmpty) {
          return EmptyState(icon: emptyIcon, title: emptyTitle);
        }
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              header,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: SelectableText(text, style: theme.textTheme.bodyMedium),
            ),
          ],
        );
      },
    );
  }
}
