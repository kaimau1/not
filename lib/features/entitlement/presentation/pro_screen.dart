import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_frame.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/ecosystem_apps.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/group_card.dart';
import '../../../core/widgets/sheet_header.dart' show SectionLabel;
import '../../../core/widgets/undo_snackbar.dart' show showAppMessage;
import '../../ai/data/api_key_store.dart';
import '../../ai/data/decisions/decision_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/presentation/settings_screen.dart' show linkGuestAccount;
import '../data/billing_products.dart';
import '../data/billing_service.dart';
import '../data/entitlement_service.dart';
import '../domain/entitlement.dart';

/// **TAM SÜRÜM EKRANI** (PLAN §2.3 & §3, Faz 1).
///
/// 2 net katman: **Lite (Ücretsiz, Reklamsız)** vs **Tam Sürüm (Tek Seferlik,
/// Ömür Boyu — 750 Akıllı Karar dahil)** + isteğe bağlı tüketilebilir
/// **+1.000 Akıllı Karar Paketi**. Abonelik yoktur.
///
/// Hak ekranda HİÇ yazılmaz: satın alma sunucuda doğrulanır, durum kartı
/// `entitlements/{uid}`'i izler ([effectiveTierProvider]).
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final billing = ref.read(billingProvider.notifier);
      unawaited(billing.start());
      unawaited(billing.recover(quiet: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(billingProvider.select((s) => s.noticeId), (_, _) {
      final n = ref.read(billingProvider).notice;
      if (n == null) return;
      showAppMessage(context, billingNoticeText(l10n, n));
    });
    final billing = ref.watch(billingProvider);
    final tier = ref.watch(effectiveTierProvider);
    final entitlement =
        ref.watch(entitlementProvider).value ?? Entitlement.none;
    final quota = ref.watch(decisionQuotaProvider);
    final hasOwnKey =
        (ref.watch(activeApiKeyProvider).value ?? '').trim().isNotEmpty;
    final guest =
        ref.watch(isAnonymousProvider) || ref.watch(currentUidProvider) == null;

    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(title: Text(l10n.proTitle))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            key: const ValueKey('pro-screen'),
            padding: EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _StatusCard(
                tier: tier,
                entitlement: entitlement,
                quota: quota,
                hasOwnKey: hasOwnKey,
              ),
              _Section(l10n.proTiersTitle),
              _TierTable(current: tier),
              if (billing.status != BillingStatus.off) ...[
                _Section(l10n.proBuyTitle),
                ..._buy(context, billing, entitlement, guest),
              ],
              const SizedBox(height: AppSpace.l),
              const CrossAppPromoCard(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buy(
    BuildContext context,
    BillingState billing,
    Entitlement entitlement,
    bool guest,
  ) {
    final l10n = context.l10n;
    final notifier = ref.read(billingProvider.notifier);
    switch (billing.status) {
      case BillingStatus.off:
        return const [];
      case BillingStatus.elsewhere:
        return [
          AppBanner(
            key: const ValueKey('pro-elsewhere'),
            icon: Icons.phone_android_outlined,
            title: l10n.proElsewhere,
          ),
        ];
      case BillingStatus.loading:
        return [
          GroupCard(
            children: [
              ListTile(
                leading: const SizedBox.square(
                  dimension: AppIconSize.l,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text(l10n.proLoading),
              ),
            ],
          ),
        ];
      case BillingStatus.unavailable:
        return [
          AppBanner(
            icon: Icons.cloud_off_outlined,
            title: l10n.proUnavailable,
            trailing: TextButton(
              onPressed: () => notifier.start(retry: true),
              child: Text(l10n.retry),
            ),
          ),
        ];
      case BillingStatus.ready:
        break;
    }
    final locked = billing.busy || guest;
    final lifetime = billing.offer(BillingPlan.lifetime);
    final pack = billing.offer(BillingPlan.decisionPack1000);
    return [
      if (guest) ...[
        AppBanner(
          key: const ValueKey('pro-guest'),
          icon: Icons.login,
          title: l10n.proGuest,
          trailing: TextButton(
            onPressed: () => linkGuestAccount(context, ref),
            child: Text(l10n.signInWithGoogle),
          ),
        ),
        const SizedBox(height: AppSpace.m),
      ],
      GroupCard(
        children: [
          if (billing.busy) const LinearProgressIndicator(),
          if (lifetime != null)
            entitlement.lifetimeOwned
                ? ListTile(
                    key: const ValueKey('pro-lifetime-owned'),
                    title: Text(l10n.proPlanLifetime),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(width: AppSpace.xs),
                        Text(l10n.proOwned),
                      ],
                    ),
                  )
                : _OfferTile(
                    offer: lifetime,
                    enabled: !locked,
                    onBuy: () => notifier.buy(lifetime),
                  ),
          if (pack != null && entitlement.lifetimeOwned)
            _OfferTile(
              offer: pack,
              enabled: !locked,
              onBuy: () => notifier.buy(pack),
            ),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('pro-restore'),
          icon: const Icon(Icons.restore),
          label: Text(l10n.proRestore),
          onPressed: locked ? null : notifier.recover,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
        child: Text(
          l10n.proTerms,
          style: AppText.of(Theme.of(context)).meta.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];
  }
}

/// Bildirimin metni (SnackBar).
String billingNoticeText(AppLocalizations l10n, BillingNotice n) => switch (n) {
  BillingNotice.pending => l10n.proNoticePending,
  BillingNotice.canceled => l10n.proNoticeCanceled,
  BillingNotice.failed => l10n.proNoticeFailed,
  BillingNotice.verifyFailed => l10n.proNoticeVerifyFailed,
  BillingNotice.otherAccount => l10n.proNoticeOtherAccount,
  BillingNotice.guest => l10n.proGuest,
  BillingNotice.done => l10n.proNoticeDone,
  BillingNotice.restored => l10n.proNoticeRestored,
  BillingNotice.nothingToRestore => l10n.proNoticeNothing,
};

/// Karar jeton sayısını kompakt biçimler (`600.000` / `120K`).
String formatDecisionTokens(int tokens) {
  if (tokens >= 1000) {
    final k = (tokens / 1000).round();
    return '${k}K';
  }
  return NumberFormat.decimalPattern().format(tokens);
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.tier,
    required this.entitlement,
    required this.quota,
    required this.hasOwnKey,
  });

  final EntitlementTier tier;
  final Entitlement entitlement;
  final DecisionQuotaSnapshot quota;
  final bool hasOwnKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = AppText.of(theme);
    final paid = !EntitlementGate.active || tier == EntitlementTier.lifetime;
    final hasCredits = paid || entitlement.decisionCredits > 0;
    final title = paid ? l10n.proStatusLifetime : l10n.proStatusFree;
    final quotaLine = hasOwnKey
        ? l10n.decisionsQuotaByok
        : hasCredits
        ? l10n.decisionsQuotaSummary(
            quota.remainingCalls,
            formatDecisionTokens(quota.remainingTokens),
          )
        : l10n.decisionsQuotaFreeHint;

    return GroupCard(
      key: const ValueKey('pro-status'),
      color: paid ? scheme.primaryContainer : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                paid
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
                size: AppIconSize.l,
                color: paid ? scheme.onPrimaryContainer : scheme.primary,
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textStyle.rowTitle.copyWith(
                        color: paid ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      quotaLine,
                      key: const ValueKey('pro-decision-quota'),
                      style: textStyle.meta.copyWith(
                        color: paid
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// PLAN §3 iki katman tablosu (Lite vs Tam Sürüm — abonelik yok).
class _TierTable extends StatelessWidget {
  const _TierTable({required this.current});

  final EntitlementTier current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = AppText.of(theme);
    final rows = <(String, List<Object>)>[
      (l10n.proRowBasics, [true, true]),
      (l10n.proRowUnlimited, [true, true]),
      (l10n.proRowSync, [l10n.proSyncPeriodic, l10n.proSyncInstant]),
      (l10n.proRowAttachments, [l10n.proAttachDrive, l10n.proAttachCloud]),
      (l10n.proRowAi, [false, l10n.proDecisionsIncluded]),
      (l10n.proRowHistory, [false, true]),
      (l10n.proRowLooks, [false, true]),
      (l10n.proRowOwnKey, [false, true]),
    ];
    final tiers = [l10n.proTierFree, l10n.proTierLifetime];

    Widget row(Widget label, List<Widget> cells) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.l,
        vertical: AppSpace.m,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: label),
          for (final c in cells) Expanded(flex: 2, child: Center(child: c)),
        ],
      ),
    );

    Widget cell(Object v) => switch (v) {
      true => Icon(
        Icons.check,
        size: AppIconSize.m,
        semanticLabel: l10n.proIncluded,
      ),
      false => Icon(
        Icons.remove,
        size: AppIconSize.m,
        color: theme.colorScheme.onSurfaceVariant,
        semanticLabel: l10n.proNotIncluded,
      ),
      _ => Text('$v', style: text.meta, textAlign: TextAlign.center),
    };

    return GroupCard(
      key: const ValueKey('pro-tiers'),
      children: [
        row(const SizedBox.shrink(), [
          for (var i = 0; i < tiers.length; i++)
            Text(
              tiers[i],
              textAlign: TextAlign.center,
              style: text.label.copyWith(
                color: i == current.index ? theme.colorScheme.primary : null,
                fontWeight: i == current.index ? AppWeight.strong : null,
              ),
            ),
        ]),
        for (final (label, cells) in rows)
          row(Text(label, style: text.body), [for (final c in cells) cell(c)]),
      ],
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.enabled,
    required this.onBuy,
  });

  final BillingOffer offer;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final price = offer.price;
    final (title, subtitle) = switch (offer.plan) {
      BillingPlan.lifetime => (l10n.proPlanLifetime, l10n.proPriceOnce(price)),
      BillingPlan.decisionPack1000 => (
        l10n.proPlanDecisionPack,
        l10n.proPriceOnce(price),
      ),
    };
    return ListTile(
      key: ValueKey('pro-offer-${offer.plan.name}'),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: OutlinedButton(
        onPressed: enabled ? onBuy : null,
        child: Text(l10n.proBuy),
      ),
    );
  }
}

/// Bölüm başlığı: ayarlardaki grup etiketiyle aynı (`SectionLabel`).
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.s,
      AppSpace.xl,
      AppSpace.s,
      AppSpace.s,
    ),
    child: SectionLabel(text),
  );
}
