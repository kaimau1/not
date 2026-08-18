import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../inbox/data/inbox_repository.dart';
import '../../inbox/presentation/inbox_screen.dart';
import 'auth_providers.dart';

/// **ANA EKRANIN HESAP SİMGESİ** — kullanıcı isteği 2026-08-18: "giriş
/// yapıldıysa üst alanda profil simgesi görülsün, yapılmadıysa yerel hesap
/// simgesi olsun."
///
/// Google hesabında kullanıcının kendi fotoğrafı, yerel (anonim) hesapta
/// telefon simgesi çizilir — hangi hesapla çalışıldığı bakışta anlaşılsın.
/// Bekleyen bir şey (arkadaşlık isteği, gelen not) varsa üstünde bir nokta
/// belirir; ana ekrandaki davet şeridi (bkz. `HomeInvites`) kapalıyken bile
/// kullanıcı bir şey olduğunu görür.
class AccountAvatarButton extends ConsumerWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;
    final anonymous = ref.watch(isAnonymousProvider);
    final photo = user?.photoURL;
    final pending =
        (ref.watch(incomingFriendRequestsProvider).value?.length ?? 0) +
        (ref.watch(inboxNotesProvider).value?.length ?? 0);
    return Tooltip(
      message: anonymous ? l10n.localAccountBadge : l10n.account,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showAccountSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            clipBehavior: Clip.none,
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
                    : Icon(
                        anonymous ? Icons.smartphone : Icons.person_outline,
                        size: 18,
                      ),
              ),
              if (pending > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hesap levhası: kimlik kartı + Kişiler / Gelen notlar / Hesap ayarları /
/// (yerel hesapta) Google'a bağlan.
///
/// Kullanıcı isteği 2026-08-18: "hesap seçeneklerini ana sayfadaki sağ
/// üstteki 3 noktaya da koy, profil bilgileri vs." Ayarların HESAP alanının
/// kısayolu: burada yalnız sık gereken üç yol var, yıkıcı işlemler (çıkış,
/// hesap silme) Ayarlar'da kalır ki yanlışlıkla dokunulmasın.
Future<void> showAccountSheet(BuildContext context) => showModalBottomSheet<
  void
>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => Consumer(
    builder: (sheetContext, ref, _) {
      final l10n = sheetContext.l10n;
      final scheme = Theme.of(sheetContext).colorScheme;
      final user = ref.watch(authStateProvider).value;
      final anonymous = ref.watch(isAnonymousProvider);
      final requests =
          ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
      final incoming = ref.watch(inboxNotesProvider).value?.length ?? 0;
      final name = (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : (user?.email?.trim().isNotEmpty ?? false)
          ? user!.email!.trim()
          : l10n.localAccountBadge;
      return SafeArea(
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
                    : Icon(anonymous ? Icons.smartphone : Icons.person_outline),
              ),
              title: Text(name),
              subtitle: Text(
                anonymous ? l10n.accountSheetLocalInfo : l10n.synced,
              ),
              isThreeLine: anonymous,
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
            ListTile(
              leading: const Icon(Icons.move_to_inbox_outlined),
              title: Text(l10n.inboxTitle),
              trailing: _Badge(count: incoming),
              onTap: () {
                Navigator.pop(sheetContext);
                InboxScreen.open(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(l10n.accountSettings),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/settings');
              },
            ),
            const SizedBox(height: 8),
          ],
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
