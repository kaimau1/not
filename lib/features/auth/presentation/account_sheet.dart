import 'account_required.dart';
import '../../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../inbox/presentation/shared_hub_screen.dart' show HubCountBadge;
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import 'auth_providers.dart';
import 'sign_out_actions.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/pop_in.dart';
import '../../../core/widgets/press_scale.dart';
import 'account_identity_card.dart';

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
          borderRadius: BorderRadius.circular(AppRadius.xl),
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
                      : const Icon(Icons.person_outline, size: AppIconSize.s),
                ),
                if (pending > 0)
                  PositionedDirectional(
                    top: 4,
                    end: 2,
                    child: IgnorePointer(
                      // İlk belirişte hafifçe büyüyerek (P62 PA2).
                      child: PopIn(
                        child: HubCountBadge(
                          count: pending,
                          color: scheme.error,
                        ),
                      ),
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
      final anonymous = ref.watch(isAnonymousProvider);
      final requests =
          ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
      final premium =
          !EntitlementGate.active ||
          ref.watch(effectiveTierProvider) == EntitlementTier.lifetime;

      void go(VoidCallback action) {
        Navigator.pop(sheetContext);
        action();
      }

      final paper = AppSurface.sheetCard(theme);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            0,
            AppSpace.l,
            AppSpace.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KİMLİK KARTI — ayarlardakiyle AYNI bileşen (P62 PA2, A7/H4).
              // Misafirde açıklama kartın altında (hap kısa kalsın, KT-7).
              AccountIdentityCard(
                footer: anonymous
                    ? Text(
                        l10n.accountSheetLocalInfo,
                        style: AppText.of(theme).meta,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpace.m),
              // KARE KISAYOLLAR — iki karo eşit boyda (alt yazı 2 satıra
              // kadar; boşsa boy yine eşit).
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Tile(
                        decoration: paper,
                        icon: AppIcons.friends,
                        label: l10n.friendsTitle,
                        trailing: anonymous
                            ? const AccountLockBadge()
                            : (requests > 0 ? _Badge(count: requests) : null),
                        onTap: () =>
                            go(() => openFriendsScreenOrExplain(context, ref)),
                      ),
                    ),
                    const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: _Tile(
                        decoration: paper,
                        icon: Icons.workspace_premium_outlined,
                        label: l10n.premiumTitle,
                        caption: premium ? null : l10n.premiumStatusFree,
                        onTap: () => go(() => context.push('/premium')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.m),
              // GRUPLU SATIRLAR
              _clipped(
                paper,
                Material(
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
              const SizedBox(height: AppSpace.m),
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

/// Kare kısayol kutusu: basınca hafifçe çöker (`PressScale`, H5).
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
    final text = AppText.of(theme);
    return PressScale(
      child: _clipped(
        decoration,
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.m),
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
                  const SizedBox(height: AppSpace.s),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.label.copyWith(fontWeight: AppWeight.strong),
                  ),
                  // Alt yazı en çok İKİ satır (H1: "Ücretsiz sürümü kulla…"
                  // tek satırda kesiliyordu).
                  if (caption != null)
                    Text(
                      caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.meta,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayı rozeti; sıfırsa oku (chevron) gösterir — boş bir "0" rozeti kullanıcıya
/// bir şey bekliyormuş gibi görünüyordu. İlk belirişte `PopIn`.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const Icon(Icons.chevron_right);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopIn(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          '$count',
          style: AppText.of(theme).badge.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}

/// Kâğıt yüzey + kırpma, Container'sız (P62 PA2, S30: levha açılış karesi
/// her bileşen kurulumunu sayar — Container fazladan bir kurulum).
Widget _clipped(BoxDecoration decoration, Widget child) => DecoratedBox(
  decoration: decoration,
  child: ClipRRect(
    borderRadius: decoration.borderRadius ?? BorderRadius.zero,
    child: child,
  ),
);
