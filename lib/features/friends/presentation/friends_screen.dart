import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';

/// **KİŞİLER** — arkadaş listesi, bekleyen istekler, e-postayla ekleme.
///
/// Kullanıcı isteği 2026-08-18: "kişiler kullanıcıya dışarıdan
/// belirleyebilmeli" — herhangi bir e-posta girilip aranabilir, kayıtlı bir
/// hesabın sahibiyse istek gider. Yerel (anonim) hesapta e-posta olmadığı
/// için bu ekran hiç açılmaz (bkz. çağıran yerdeki gate).
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const FriendsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final friends = ref.watch(friendsStreamProvider).value ?? const [];
    final requests = ref.watch(incomingFriendRequestsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        actions: [
          IconButton(
            tooltip: l10n.friendsAdd,
            icon: const Icon(Icons.person_add_alt_outlined),
            onPressed: () => _addFriend(context, ref),
          ),
        ],
      ),
      body: friends.isEmpty && requests.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.friendsEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _addFriend(context, ref),
                      icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                      label: Text(l10n.friendsAdd),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (requests.isNotEmpty) ...[
                  _sectionLabel(context, l10n.friendsRequestsTitle),
                  for (final r in requests) _RequestTile(request: r),
                ],
                if (friends.isNotEmpty) ...[
                  _sectionLabel(context, l10n.friendsListTitle),
                  for (final f in friends) _FriendTile(friend: f),
                ],
              ],
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.friendsAdd),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: l10n.friendsAddEmailHint),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.friendsSendRequest),
          ),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty || !context.mounted) return;
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.sendRequest(email.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsRequestSent)));
      }
    } on FriendNotFoundException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsNotFound)));
      }
    } on SelfFriendException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsSelf)));
      }
    } on AlreadyFriendException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsAlready)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
      }
    }
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(request.fromName.isEmpty ? request.fromEmail : request.fromName),
      subtitle: Text(request.fromEmail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.friendsDecline,
            icon: const Icon(Icons.close),
            onPressed: () => ref
                .read(friendsRepositoryProvider)
                ?.declineRequest(request.fromUid),
          ),
          IconButton(
            tooltip: l10n.friendsAccept,
            icon: const Icon(Icons.check),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () =>
                ref.read(friendsRepositoryProvider)?.acceptRequest(request),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(friend.name.isEmpty ? friend.email : friend.name),
      subtitle: Text(friend.email),
      trailing: IconButton(
        tooltip: l10n.friendsRemove,
        icon: const Icon(Icons.person_remove_outlined),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.friendsRemoveConfirmTitle),
              content: Text(
                l10n.friendsRemoveConfirmBody(
                  friend.name.isEmpty ? friend.email : friend.name,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.friendsRemove),
                ),
              ],
            ),
          );
          if (ok == true) {
            ref.read(friendsRepositoryProvider)?.removeFriend(friend.uid);
          }
        },
      ),
    );
  }
}

/// Kişiler ekranını bulunduğu yerden emniyetle açar: anonim (yerel) hesapta
/// e-posta olmadığı için özellik anlamsız — düğme yerine bilgi verir.
void openFriendsScreenOrExplain(BuildContext context, WidgetRef ref) {
  if (ref.read(isAnonymousProvider)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendsNeedsAccount)));
    return;
  }
  FriendsScreen.open(context);
}
