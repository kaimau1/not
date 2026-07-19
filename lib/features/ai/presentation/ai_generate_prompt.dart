import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';

/// Ücretsiz kullanıcıya, günlük AI içeriği (e-posta/öneri/brifing) otomatik
/// üretilmediğinde gösterilen "elle oluştur" istemi: kotayı boşa harcamamak
/// için içerik yalnızca bu düğmeyle, günde bir kez üretilir.
class AiGeneratePrompt extends StatelessWidget {
  const AiGeneratePrompt({
    super.key,
    required this.icon,
    required this.buttonLabel,
    required this.onGenerate,
  });

  final IconData icon;
  final String buttonLabel;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.aiDailyManualInfo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
