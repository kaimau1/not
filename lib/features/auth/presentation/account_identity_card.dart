import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import 'auth_providers.dart';

/// **KİMLİK KARTI** (P62 PA2, plan_tasarim_A §3.2): avatar, ad, e-posta,
/// durum hapı — kâğıt yüzeyde (`AppSurface.paper`). Hesap levhasında,
/// Ayarlar kökünde ve Ayarlar → Hesap'ın tepesinde AYNI bileşen (eskiden üç
/// yerde iki ayrı kılık: levhada kâğıt, ayarlarda yarı saydam birincil).
///
/// [footer]: kartın altındaki parça (ayarlar kökünde misafirin "Giriş yap"
/// düğmesi — 2026-10-28 kullanıcı isteği; levhada misafir açıklaması).
class AccountIdentityCard extends ConsumerWidget {
  const AccountIdentityCard({super.key, this.footer});

  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final user = ref.watch(authStateProvider).value;
    final anonymous = ref.watch(isAnonymousProvider);
    final email = anonymous ? '' : (user?.email?.trim() ?? '');
    // Misafir (F79.2, D18): "Misafir" + "Yalnız bu cihazda" hapı.
    final name = anonymous
        ? l10n.profileGuestName
        : (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : email;
    final photo = anonymous ? null : user?.photoURL;
    final footer = this.footer;
    // Container DEĞİL: DecoratedBox + Padding bileşen kurmaz (S30).
    return DecoratedBox(
      key: const ValueKey('account-identity-card'),
      decoration: AppSurface.paper(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _avatar(scheme, photo, anonymous),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.rowTitle.copyWith(
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                      if (email.isNotEmpty && email != name)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.meta,
                        ),
                      const SizedBox(height: AppSpace.s),
                      // Anonim hesapta "Senkronize" YANILTICIYDI: veri başka
                      // cihazdan açılamaz. Hap gerçeği söyler; renk rolü
                      // dikkat (eskiden `tertiary` — yalnız yapay zekâ rolü, H2).
                      AccountStatusPill(
                        icon: anonymous
                            ? Icons.smartphone
                            : Icons.cloud_done_outlined,
                        label: anonymous ? l10n.localOnlyBadge : l10n.synced,
                        color: anonymous
                            ? AppTone.attention.colors(scheme).fg
                            : scheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (footer != null) ...[const SizedBox(height: AppSpace.m), footer],
          ],
        ),
      ),
    );
  }
}

/// Avatar: girişte fotoğraf (ağdan gelince SOLARAK — "pat" diye belirmez,
/// H5), misafirde kişi simgesi. Yer tutucu simge hep altta: boy değişmez.
/// Ayrı widget DEĞİL, işlev: levha açılış karesinde bir bileşen kurulumu
/// daha az (S30 mandalı).
const double _avatarRadius = 28;

Widget _avatar(ColorScheme scheme, String? photo, bool anonymous) {
  return CircleAvatar(
    radius: _avatarRadius,
    backgroundColor: anonymous
        ? scheme.surfaceContainerHighest
        : scheme.primaryContainer,
    foregroundColor: anonymous
        ? scheme.onSurfaceVariant
        : scheme.onPrimaryContainer,
    // Fotoğraf yoksa yalnız simge (fazladan katman kurulmaz, S30).
    child: photo == null
        ? const Icon(Icons.person_outline, size: AppIconSize.l)
        : Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.person_outline, size: AppIconSize.l),
              ClipOval(
                child: Image.network(
                  photo,
                  width: _avatarRadius * 2,
                  height: _avatarRadius * 2,
                  cacheWidth: 168,
                  cacheHeight: 168,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  frameBuilder: (context, child, frame, sync) => sync
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: AppMotion.of(context, AppMotion.quick),
                          curve: AppMotion.standard,
                          child: child,
                        ),
                ),
              ),
            ],
          ),
  );
}

/// Kimlik kartındaki durum hapı (Senkron / yalnız bu cihazda): en çok iki
/// satır (kesilmez, KT-7), köşe hap.
class AccountStatusPill extends StatelessWidget {
  const AccountStatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;

  /// Yazı + simge; zemin bunun × `AppAlpha.pressed`.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(Theme.of(context));
    return DecoratedBox(
      key: const ValueKey('account-status-pill'),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppAlpha.pressed),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.xs, color: color),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.meta.copyWith(
                  fontWeight: AppWeight.strong,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
