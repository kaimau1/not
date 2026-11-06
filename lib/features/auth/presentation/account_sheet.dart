import 'account_required.dart';
import '../../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/data/ai_gate.dart';
import '../../inbox/presentation/shared_hub_screen.dart' show HubCountBadge;
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import 'auth_providers.dart';
import 'sign_out_actions.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../app/theme/app_tokens.dart';

/// **ANA EKRANIN HESAP SİMGESİ** — kullanıcı isteği 2026-08-18: "giriş
/// yapıldıysa üst alanda profil simgesi görülsün, yapılmadıysa yerel hesap
/// simgesi olsun."
///
/// Google hesabında kullanıcının kendi fotoğrafı, yerel (misafir) hesapta
/// kişi simgesi çizilir. Bekleyen bir şey (arkadaşlık isteği, gelen not,
/// okunmamış ortak not) varsa köşede sayı rozeti belirir.
class AccountAvatarButton extends ConsumerWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;
    final anonymous = ref.watch(isAnonymousProvider);
    final photo = user?.photoURL;
    final pending = ref.watch(accountPendingCountProvider);
    // TEK AVATAR (F11.1, kullanıcı kararı 2026-10-31): üst çubuktaki ayrı
    // "Gelen ve paylaşılanlar" düğmesi buraya katıldı. Bekleyen her şey
    // (arkadaşlık isteği, gelen not, okunmamış ortak not) SAYI rozeti olur.
    // Misafirde telefon değil kişi simgesi — telefon "cihaz" gibi okunuyordu.
    final name = anonymous ? l10n.localAccountBadge : l10n.account;
    return Tooltip(
      message: pending > 0 ? '$name ($pending)' : name,
      child: Semantics(
        button: true,
        child: InkWell(
          key: const ValueKey('home-account-avatar'),
          borderRadius: BorderRadius.circular(24),
          onTap: () => showAccountSheet(context),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: anonymous
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer,
                  foregroundColor: anonymous
                      ? scheme.onSurfaceVariant
                      : scheme.onPrimaryContainer,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo != null
                      ? null
                      : const Icon(Icons.person_outline, size: 18),
                ),
                if (pending > 0)
                  PositionedDirectional(
                    top: 4,
                    end: 2,
                    child: IgnorePointer(
                      child: HubCountBadge(count: pending, color: scheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar rozetinin sayısı: bekleyen arkadaşlık isteği. Gelen ve
/// paylaşılanlar 2026-10-31'den beri klasör şeridinde "Gelen" çipi (kendi
/// rozetiyle; bkz. SharedHubChip) — avatar onu artık saymaz.
final accountPendingCountProvider = Provider<int>((ref) {
  return ref.watch(
    incomingFriendRequestsProvider.select((s) => s.value?.length ?? 0),
  );
});

/// **PROFİL LEVHASI** — baştan yazıldı (kullanıcı isteği 2026-11-06: "profil
/// menüsü yeni temaya, yeni stile uyumlu olsun"). "Masa ve kâğıt" teması:
/// kimlik kâğıt renginde ince çizgili bir kartta (büyük avatar, ad, e-posta,
/// senkron/yerel hapı); altında iki kare kısayol (Kişiler, Premium); sonra
/// tek kartta gruplanmış satırlar (Hesap ayarları, Hesap değiştir); en altta
/// ayrı duran "Oturumu kapat". Hesap SİLME Ayarlar'da kalır. Değiştir ve
/// çıkış onay ister; misafirde çıkış kırmızıdır (veri kaybı).
Future<void> showAccountSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  // İçeriğe göre boylanır, sığmazsa kayar (alçak pencerede son satır
  // kesiliyordu).
  isScrollControlled: true,
  builder: (sheetContext) => Consumer(
    builder: (sheetContext, ref, _) {
      final l10n = sheetContext.l10n;
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final tokens = AppTokens.of(sheetContext);
      final user = ref.watch(authStateProvider).value;
      final anonymous = ref.watch(isAnonymousProvider);
      final requests =
          ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
      final premium = ref.watch(premiumProvider).value ?? false;
      final email = user?.email?.trim() ?? '';
      final name = (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : email.isNotEmpty
          ? email
          : l10n.localAccountBadge;
      final photo = user?.photoURL;

      void go(VoidCallback action) {
        Navigator.pop(sheetContext);
        action();
      }

      BoxDecoration paper() => BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(color: tokens.hairline),
        boxShadow: tokens.cardShadow,
      );

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KİMLİK KARTI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: paper(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: anonymous
                          ? scheme.surfaceContainerHighest
                          : scheme.primaryContainer,
                      foregroundColor: anonymous
                          ? scheme.onSurfaceVariant
                          : scheme.onPrimaryContainer,
                      backgroundImage: photo != null
                          ? NetworkImage(photo)
                          : null,
                      child: photo != null
                          ? null
                          : const Icon(Icons.person_outline, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (email.isNotEmpty && email != name)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 6),
                          _StatusPill(
                            icon: anonymous
                                ? Icons.phone_android_outlined
                                : Icons.cloud_done_outlined,
                            label: anonymous
                                ? l10n.accountSheetLocalInfo
                                : l10n.synced,
                            color: anonymous ? scheme.tertiary : scheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // KARE KISAYOLLAR
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      decoration: paper(),
                      icon: AppIcons.friends,
                      label: l10n.friendsTitle,
                      trailing: anonymous
                          ? const AccountLockBadge()
                          : (requests > 0 ? _Badge(count: requests) : null),
                      onTap: () =>
                          go(() => openFriendsScreenOrExplain(context, ref)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tile(
                      decoration: paper(),
                      icon: Icons.workspace_premium_outlined,
                      label: l10n.premiumTitle,
                      caption: premium ? null : l10n.premiumStatusFree,
                      onTap: () => go(() => context.push('/premium')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // GRUPLU SATIRLAR
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: paper(),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.manage_accounts_outlined),
                        title: Text(l10n.accountSettings),
                        trailing: const Icon(Icons.chevron_right),
                        // `?area=account`: Ayarlar hesap alanı açık gelsin.
                        onTap: () =>
                            go(() => context.push('/settings?area=account')),
                      ),
                      Divider(height: 1, color: tokens.hairline),
                      ListTile(
                        key: const ValueKey('account-switch'),
                        leading: const Icon(Icons.switch_account_outlined),
                        title: Text(l10n.switchAccount),
                        onTap: () => go(() => confirmAndSwitchAccount(context)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ÇIKIŞ — ayrı, kenarlı (FilledButton DEĞİL: onay iletişim
              // kutusunun düğmesiyle karışmasın).
              OutlinedButton.icon(
                key: const ValueKey('account-sign-out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: anonymous ? scheme.error : null,
                  side: BorderSide(
                    color: anonymous ? scheme.error : tokens.hairline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
                onPressed: () => go(() => confirmAndSignOut(context)),
              ),
            ],
          ),
        ),
      );
    },
  ),
);

/// Kimlik kartındaki durum hapı (Senkron / yalnız bu cihazda).
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Kare kısayol kutusu.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.decoration,
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.trailing,
  });

  final BoxDecoration decoration;
  final IconData icon;
  final String label;
  final String? caption;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: scheme.primary),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  caption ?? ' ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayı rozeti; sıfırsa oku (chevron) gösterir — boş bir "0" rozeti kullanıcıya
/// bir şey bekliyormuş gibi görünüyordu.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const Icon(Icons.chevron_right);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}
