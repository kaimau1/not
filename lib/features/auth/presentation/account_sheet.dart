import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../ai/data/ai_gate.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../inbox/presentation/shared_hub_screen.dart';
import 'auth_providers.dart';
import '../../../core/widgets/app_sheet.dart';

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
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
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

/// Avatar rozetinin sayısı: bekleyen arkadaşlık isteği + Gelen ve
/// paylaşılanlar rozeti (kabul bekleyen gelen not + okunmamış ortak not).
final accountPendingCountProvider = Provider<int>((ref) {
  final requests = ref.watch(
    incomingFriendRequestsProvider.select((s) => s.value?.length ?? 0),
  );
  return requests + ref.watch(sharedHubBadgeProvider);
});

/// Hesap levhası: kimlik kartı + Kişiler / Gelen ve paylaşılanlar / Premium /
/// Hesap ayarları.
///
/// Kullanıcı isteği 2026-08-18: "hesap seçeneklerini ana sayfadaki sağ
/// üstteki 3 noktaya da koy, profil bilgileri vs." Ayarların HESAP alanının
/// kısayolu: burada yalnız sık gereken üç yol var, yıkıcı işlemler (çıkış,
/// hesap silme) Ayarlar'da kalır ki yanlışlıkla dokunulmasın.
Future<void> showAccountSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  // İçeriğe göre boylanır, sığmazsa kayar: varsayılan levha ekranın 9/16'sıyla
  // sınırlı ve alçak pencerede (yatay telefon, küçük web penceresi) son satır
  // "Hesap ayarları" kesiliyordu.
  isScrollControlled: true,
  builder: (sheetContext) => Consumer(
    builder: (sheetContext, ref, _) {
      final l10n = sheetContext.l10n;
      final scheme = Theme.of(sheetContext).colorScheme;
      final user = ref.watch(authStateProvider).value;
      final anonymous = ref.watch(isAnonymousProvider);
      final requests =
          ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
      final incoming = ref.watch(sharedHubBadgeProvider);
      final premium = ref.watch(premiumProvider).value ?? false;
      final email = user?.email?.trim() ?? '';
      final name = (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : email.isNotEmpty
          ? email
          : l10n.localAccountBadge;
      // Kullanıcı bulgusu 2026-08-29: "hesap bilgisi yetersiz". Levha yalnız
      // adı ve tek satırlık bir durumu gösteriyordu; hangi e-postayla giriş
      // yapıldığı ve planın ne olduğu hiçbir yerde görünmüyordu. E-posta
      // ADIN ALTINDA yazılır (ad zaten e-posta ise tekrarlanmaz).
      final details = [
        if (email.isNotEmpty && email != name) email,
        anonymous ? l10n.accountSheetLocalInfo : l10n.synced,
      ].join('\n');
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: anonymous
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer,
                  foregroundColor: anonymous
                      ? scheme.onSurfaceVariant
                      : scheme.onPrimaryContainer,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL != null
                      ? null
                      : const Icon(Icons.person_outline),
                ),
                title: Text(name),
                subtitle: Text(details),
                isThreeLine: details.contains('\n'),
              ),
              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(l10n.friendsTitle),
                trailing: _Badge(count: requests),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openFriendsScreenOrExplain(context, ref);
                },
              ),
              // GELEN VE PAYLAŞILANLAR (F11.1): üst çubuktaki ayrı düğme
              // kalktı; gelen kopyalar ve ortak notlar tek ekranda.
              ListTile(
                key: const ValueKey('account-sheet-shared-hub'),
                leading: const Icon(Icons.move_to_inbox_outlined),
                title: Text(l10n.sharedHubTitle),
                trailing: _Badge(count: incoming),
                onTap: () {
                  Navigator.pop(sheetContext);
                  SharedHubScreen.open(context);
                },
              ),
              // Plan da hesabın bir parçası: hangi sürümde olduğunu görmek için
              // Ayarlar'ın dibine inmek gerekiyordu.
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.premiumTitle),
                subtitle: premium ? null : Text(l10n.premiumStatusFree),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/premium');
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(l10n.accountSettings),
                trailing: const Icon(Icons.chevron_right),
                // `?area=account` OLMADAN Ayarlar "Görünüm" açık geliyordu ve
                // "Hesap ayarları"na basan kullanıcı kapalı bir hesap kartıyla
                // karşılaşıyordu (kullanıcı bulgusu 2026-08-29: "hesap
                // ayarlarına ulaşmak zor ve anlaşılır değil").
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/settings?area=account');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  ),
);

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
