part of '../settings_screen.dart';

/// Tam Sürüm & Akıllı Kararlar (Decisions API) durum kartı: kalan karar
/// sayısı ve jeton bütçesini (`remainingCalls` / `remainingTokens`) gösterir;
/// dokununca Tam Sürüm ekranına (`/premium`) götürür.
class _BuiltInAiStatus extends ConsumerWidget {
  const _BuiltInAiStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = AppText.of(theme);
    final hasKey =
        (ref.watch(activeApiKeyProvider).value ?? '').trim().isNotEmpty;
    final ent = ref.watch(entitlementProvider).value ?? Entitlement.none;
    final paid =
        !EntitlementGate.active ||
        ref.watch(effectiveTierProvider) == EntitlementTier.lifetime;
    final hasCredits = paid || ent.decisionCredits > 0;
    final quota = ref.watch(decisionQuotaProvider);

    final (icon, title, subtitle) = hasKey
        ? (
            Icons.key,
            l10n.proTitle,
            l10n.decisionsQuotaByok,
          )
        : hasCredits
        ? (
            paid
                ? Icons.workspace_premium_outlined
                : Icons.auto_awesome_outlined,
            paid ? l10n.proStatusLifetime : l10n.proStatusFree,
            l10n.decisionsQuotaSummary(
              quota.remainingCalls,
              formatDecisionTokens(quota.remainingTokens),
            ),
          )
        : (
            Icons.auto_awesome_outlined,
            l10n.proStatusFree,
            l10n.decisionsQuotaFreeHint,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: InkWell(
        key: const ValueKey('settings-decisions-quota'),
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: () => context.push('/premium'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s),
                  child: Icon(
                    icon,
                    size: AppIconSize.s,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textStyle.rowTitle.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      subtitle,
                      style: textStyle.meta.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSize.m,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: AppAlpha.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Akıllı Kararlar bölümündeki form alanlarının ortak görünümü.
InputDecoration _aiFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: scheme.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
}

/// İleri seçenek: kullanıcının kendi Gemini API anahtarıyla (BYOK) sınırsız
/// `gemini-decision-1` Decisions kullanımı (maliyet \$0).
class _GeminiKeyEditor extends ConsumerStatefulWidget {
  const _GeminiKeyEditor();

  @override
  ConsumerState<_GeminiKeyEditor> createState() => _GeminiKeyEditorState();
}

class _GeminiKeyEditorState extends ConsumerState<_GeminiKeyEditor> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    if (!ref.read(proFeatureProvider(ProFeature.ownApiKey))) {
      openProScreen(context);
      return;
    }
    if (!await ensureAiConsent(context, ref)) return;
    if (!mounted) return;
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final valid = await ref
          .read(decisionServiceProvider)
          .validateGeminiKey(key);
      if (!valid) {
        messenger.showMessage(l10n.apiKeyInvalid);
        return;
      }
      await ref.read(apiKeyStoreProvider).save(AiProvider.gemini, key);
      ref.invalidate(activeApiKeyProvider);
      _controller.clear();
      messenger.showMessage(l10n.apiKeyValid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeKey() async {
    await ref.read(apiKeyStoreProvider).clear();
    ref.invalidate(activeApiKeyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowed = ref.watch(proFeatureProvider(ProFeature.ownApiKey));
    final storedKey = ref.watch(activeApiKeyProvider).value;
    final hasKey = storedKey != null && storedKey.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.key, size: AppIconSize.xs),
                  label: Text(
                    '${AiProvider.gemini.label}: ${l10n.apiKeySavedBadge}',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _removeKey,
                  child: Text(l10n.removeApiKey),
                ),
              ],
            ),
          ),
        if (!allowed) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const ProLockBadge(size: AppIconSize.m),
            title: Text(l10n.proRowOwnKey),
            subtitle: Text(l10n.proLockedBadge),
            trailing: OutlinedButton(
              onPressed: () => openProScreen(context),
              child: Text(l10n.proTitle),
            ),
          ),
        ] else ...[
          TextField(
            key: const ValueKey('settings-gemini-key-field'),
            controller: _controller,
            obscureText: true,
            decoration: _aiFieldDecoration(
              context,
              label: '${AiProvider.gemini.label} · ${l10n.apiKeyFieldLabel}',
              hint: AiProvider.gemini.keyHint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.decisionsByokInfo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(AiProvider.gemini.keyUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: AppIconSize.s),
              label: Text(l10n.getApiKey),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _validateAndSave,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(l10n.validateAndSave),
          ),
        ],
      ],
    );
  }
}

class _AiSwitchTile extends StatelessWidget {
  const _AiSwitchTile({
    super.key,
    required this.title,
    required this.info,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String info;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.m),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.rowTitle),
                  const SizedBox(height: AppSpace.xxs),
                  Text(info, style: text.meta),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// "Akıllı kararları kapat" (PLAN §1.5 PL3 c, Faz 1).
class _AiOffSwitch extends ConsumerWidget {
  const _AiOffSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      key: const ValueKey('settings-ai-off'),
      title: l10n.decisionsTurnOffTitle,
      info: l10n.decisionsTurnOffBody,
      value: ref.watch(aiTurnedOffProvider),
      onChanged: (value) => ref.read(aiTurnedOffProvider.notifier).set(value),
    );
  }
}

/// Play derlemesinde AI rızasını Ayarlar'dan açıp kapatma anahtarı.
class _AiConsentSwitch extends ConsumerWidget {
  const _AiConsentSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      key: const ValueKey('settings-ai-consent'),
      title: l10n.aiConsentTitle,
      info: l10n.aiConsentWhere,
      value: ref.watch(aiConsentProvider),
      onChanged: (value) {
        final n = ref.read(aiConsentProvider.notifier);
        if (value) {
          n.accept();
        } else {
          n.revoke();
        }
      },
    );
  }
}

/// Kendi Gemini anahtarı (BYOK), katlanır "İleri" bölümünde.
class _AdvancedAiSection extends ConsumerWidget {
  const _AdvancedAiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _ExpandTile(
      childrenPadding: const EdgeInsets.only(top: 14, bottom: 8),
      leading: const Icon(Icons.key_outlined),
      title: Text(l10n.decisionsByokTitle),
      subtitle: Text(
        l10n.decisionsSectionSubtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: const [_GeminiKeyEditor()],
    );
  }
}
