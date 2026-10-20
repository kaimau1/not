import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/data/folders_repository.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';

/// **ANA EKRANIN DAVET ŞERİDİ** — kullanıcı isteği 2026-08-18: "arkadaşlık
/// isteği geldiğinde ana sayfada görülsün" ve "klasör paylaşıldığında kabul
/// et veya reddet seçeneği olsun."
///
/// Eskiden ikisi de yalnız Ayarlar → Kişiler altında görülüyordu: davet eden
/// kişi "gönderdim" diyor, karşı taraf hiçbir şey görmüyordu. Şerit yalnız
/// BEKLEYEN bir şey varken çizilir; boşken ana ekrandan tek piksel yemez.
class HomeInvites extends ConsumerWidget {
  const HomeInvites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests =
        ref.watch(incomingFriendRequestsProvider).value ??
        const <FriendRequest>[];
    final invites =
        ref.watch(folderInvitesProvider).value ?? const <SharedFolderRef>[];
    if (requests.isEmpty && invites.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          for (final r in requests) _FriendRequestCard(request: r),
          for (final i in invites) _FolderInviteCard(invite: i),
        ],
      ),
    );
  }
}

/// Ortak gövde: simge + iki satır yazı + Reddet/Kabul et. İki kart da aynı
/// biçimi kullanır ki kullanıcı "bekleyen bir şey" örüntüsünü bir kez
/// öğrensin.
class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAccept,
    required this.onDecline,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onTertiaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onDecline, child: Text(l10n.friendsDecline)),
          FilledButton.tonal(
            onPressed: onAccept,
            child: Text(l10n.friendsAccept),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestCard extends ConsumerWidget {
  const _FriendRequestCard({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = request.fromName.trim().isEmpty
        ? request.fromEmail
        : request.fromName;
    final messenger = ScaffoldMessenger.of(context);
    return _InviteCard(
      icon: Icons.person_add_alt_outlined,
      title: l10n.friendRequestBanner(name),
      subtitle: request.fromEmail,
      onDecline: () =>
          ref.read(friendsRepositoryProvider)?.declineRequest(request.fromUid),
      onAccept: () async {
        final repo = ref.read(friendsRepositoryProvider);
        if (repo == null) return;
        try {
          await repo.acceptRequest(request);
          messenger.showMessage(l10n.friendRequestAccepted);
        } catch (e) {
          messenger.showMessage(l10n.genericError('$e'));
        }
      },
    );
  }
}

class _FolderInviteCard extends ConsumerWidget {
  const _FolderInviteCard({required this.invite});

  final SharedFolderRef invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Daveti kimin gönderdiği arkadaş listesinden çözülür: ayna yalnız uid
    // taşıyor ve paylaşım zaten arkadaşlık gerektiriyor (bkz. shareFolder).
    final owner = (ref.watch(friendsStreamProvider).value ?? const <Friend>[])
        .where((f) => f.uid == invite.ownerId)
        .firstOrNull;
    final messenger = ScaffoldMessenger.of(context);
    return _InviteCard(
      icon: Icons.folder_shared_outlined,
      title: l10n.folderInviteBody(invite.name),
      subtitle: owner == null
          ? l10n.folderInviteTitle
          : (owner.name.isEmpty ? owner.email : owner.name),
      onDecline: () async {
        final repo = ref.read(foldersRepositoryProvider);
        if (repo == null) return;
        try {
          await repo.declineInvite(invite);
          messenger.showMessage(l10n.folderInviteDeclined);
        } catch (e) {
          messenger.showMessage(l10n.genericError('$e'));
        }
      },
      onAccept: () async {
        final repo = ref.read(foldersRepositoryProvider);
        if (repo == null) return;
        try {
          await repo.acceptInvite(invite);
          messenger.showMessage(l10n.folderInviteAccepted);
        } catch (e) {
          messenger.showMessage(l10n.genericError('$e'));
        }
      },
    );
  }
}
