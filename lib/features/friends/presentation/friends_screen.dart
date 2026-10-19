import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';
import '../../../core/widgets/app_sheet.dart';

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

  Future<void> _addFriend(BuildContext context, WidgetRef ref) => showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _AddFriendSheet(),
  );
}

/// Arkadaş ekleme: iki sekme — tüm kullanıcılar içinde ad/e-posta ile arama
/// (kullanıcı isteği 2026-08-21, bkz. `functions/searchUsers`) ve eski tam
/// e-posta akışı (arananın hiç arama dizinine düşmemiş olabileceği köşe
/// durumlar için, ör. henüz `userSearch` yazılmadan önce oluşmuş hesaplar).
class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet();

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  final _emailController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<UserSearchResult>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _tab.dispose();
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _query.trim();
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null || !FriendsRepository.isSearchableQuery(q)) {
      setState(() => _results = q.isEmpty ? null : const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await repo.searchUsers(q);
      if (mounted) setState(() => _results = results);
    } on FirebaseFunctionsException catch (e) {
      // Sunucu reddi (F1.1): misafir oturum `permission-denied`, hız sınırı
      // `resource-exhausted` — sessiz "sonuç yok" yerine nedenini söyle.
      if (mounted) {
        setState(() => _results = const []);
        final msg = switch (e.code) {
          'permission-denied' => context.l10n.friendsSearchNeedsGoogle,
          'resource-exhausted' => context.l10n.friendsSearchRateLimited,
          _ => null,
        };
        if (msg != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendToUid(String uid) async {
    final l10n = context.l10n;
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.sendRequestToUid(uid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsRequestSent)));
      }
    } on SelfFriendException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsSelf)));
      }
    } on AlreadyFriendException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsAlready)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
      }
    }
  }

  Future<void> _sendToEmail() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.sendRequest(email);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsRequestSent)));
      }
    } on FriendNotFoundException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsNotFound)));
      }
    } on SelfFriendException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsSelf)));
      }
    } on AlreadyFriendException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.friendsAlready)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.friendsAdd, style: Theme.of(context).textTheme.titleMedium),
          ),
          TabBar(
            controller: _tab,
            tabs: [
              Tab(text: l10n.friendsSearchTab),
              Tab(text: l10n.friendsSearchEmailTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _searchTab(context, scrollController),
                _emailTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchTab(BuildContext context, ScrollController scrollController) {
    final l10n = context.l10n;
    final results = _results;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.friendsSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (_searching) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: results == null
              ? Center(
                  child: Text(
                    l10n.friendsSearchTooShort,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : results.isEmpty
              ? Center(
                  child: Text(
                    l10n.friendsSearchEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final r = results[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(r.name.isEmpty ? r.email : r.name),
                      subtitle: Text(r.email),
                      trailing: TextButton(
                        onPressed: () => _sendToUid(r.uid),
                        child: Text(l10n.friendsSearchAdd),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emailTab(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: l10n.friendsAddEmailHint),
            onSubmitted: (_) => _sendToEmail(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _sendToEmail,
            child: Text(l10n.friendsSendRequest),
          ),
        ],
      ),
    );
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
