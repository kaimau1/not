import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../auth/presentation/account_required.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../folders/data/folders_repository.dart';
import '../data/friends_repository.dart';
import '../domain/friend.dart';
import '../domain/friend_list.dart';

/// **KİŞİLER** — BAŞTAN yazıldı (kullanıcı isteği 2026-11-06: "kişiler
/// ekranının yeniden yazılması").
///
/// Üstte arama (kişi çoksa), bekleyen istekler kart olarak (Kabul / Reddet
/// tam düğme), arkadaşlar alfabetik ve baş harfe göre kümeli; kişiye dokun →
/// kişi kartı (e-posta kopyala, onunla paylaşılan klasörler, kaldır). Ekleme
/// tek levha: ad yazınca arar, tam e-posta yazınca doğrudan istek seçeneği
/// çıkar (eski iki sekme kalktı).
///
/// Yerel (anonim) hesapta e-posta olmadığı için bu ekran hiç açılmaz (bkz.
/// [openFriendsScreenOrExplain]).
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const FriendsScreen()));

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _add() => showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _AddFriendSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsStreamProvider);
    final friends = friendsAsync.value ?? const <Friend>[];
    final requests =
        ref.watch(incomingFriendRequestsProvider).value ??
        const <FriendRequest>[];
    final loading = friendsAsync.isLoading && friends.isEmpty;

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (friends.isEmpty && requests.isEmpty) {
      body = EmptyState(
        key: const ValueKey('friends-empty'),
        icon: Icons.people_outline,
        title: l10n.friendsEmptyTitle,
        subtitle: l10n.friendsEmpty,
        actionLabel: l10n.friendsAdd,
        actionIcon: Icons.person_add_alt_outlined,
        onAction: _add,
      );
    } else {
      body = ValueListenableBuilder<TextEditingValue>(
        valueListenable: _filter,
        builder: (context, value, _) {
          final shown = filterFriends(friends, value.text);
          final groups = groupFriends(shown);
          return CustomScrollView(
            key: const ValueKey('friends-list'),
            slivers: [
              if (friends.length >= 6)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SearchBar(
                      key: const ValueKey('friends-filter'),
                      controller: _filter,
                      elevation: const WidgetStatePropertyAll(0),
                      hintText: l10n.friendsFilterHint,
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (value.text.isNotEmpty)
                          IconButton(
                            tooltip: l10n.clear,
                            icon: const Icon(Icons.close),
                            onPressed: _filter.clear,
                          ),
                      ],
                    ),
                  ),
                ),
              if (requests.isNotEmpty) ...[
                _header(l10n.friendsRequestsTitle, requests.length),
                SliverList.list(
                  children: [
                    for (final r in requests) _RequestCard(request: r),
                  ],
                ),
              ],
              if (friends.isNotEmpty)
                _header(l10n.friendsListTitle, friends.length),
              if (friends.isNotEmpty && shown.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(l10n.friendsSearchEmpty)),
                  ),
                ),
              for (final g in groups) ...[
                SliverToBoxAdapter(child: _LetterLabel(g.letter)),
                SliverList.builder(
                  itemCount: g.people.length,
                  itemBuilder: (_, i) => _FriendRow(friend: g.people[i]),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.friendsTitle)),
      body: body,
      floatingActionButton: friends.isEmpty && requests.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('friends-add'),
              heroTag: 'friendsAdd',
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: Text(l10n.friendsAdd),
            ),
    );
  }

  Widget _header(String text, int count) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: SectionLabel('$text · $count'),
    ),
  );
}

/// Alfabe kümesi harfi.
class _LetterLabel extends StatelessWidget {
  const _LetterLabel(this.letter);
  final String letter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 10, 20, 2),
    child: Text(
      letter,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Ada göre kararlı renkli baş harf avatarı.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.label, this.size = 40});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final pairs = [
      (s.primaryContainer, s.onPrimaryContainer),
      (s.secondaryContainer, s.onSecondaryContainer),
      (s.tertiaryContainer, s.onTertiaryContainer),
    ];
    final (bg, fg) = pairs[label.hashCode.abs() % pairs.length];
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        child: Text(
          personInitial(label),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = friendLabel(friend.name, friend.email);
    final shared = ref
        .watch(foldersStreamProvider)
        .value
        ?.where((f) => f.sharedWith.contains(friend.uid))
        .length;
    final l10n = context.l10n;
    return ListTile(
      key: ValueKey('friend-${friend.uid}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: PersonAvatar(label: label),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        friend.name.trim().isEmpty ? l10n.friendsNoName : friend.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: shared == null || shared == 0
          ? const Icon(Icons.chevron_right)
          : Tooltip(
              message: l10n.friendsSharedFolders,
              child: Chip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.folder_shared_outlined, size: 16),
                label: Text('$shared'),
              ),
            ),
      onTap: () => showAppSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _FriendCard(friend: friend),
      ),
    );
  }
}

/// Kişi kartı: büyük avatar, ad, e-posta (kopyala), ne zamandan beri,
/// onunla paylaşılan klasörler, "Kişilerden kaldır".
class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friend});
  final Friend friend;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final label = friendLabel(friend.name, friend.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.friendsRemoveConfirmTitle),
        content: Text(l10n.friendsRemoveConfirmBody(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            key: const ValueKey('friend-remove-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.friendsRemove),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      unawaited(ref.read(friendsRepositoryProvider)?.removeFriend(friend.uid));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final label = friendLabel(friend.name, friend.email);
    final folders = [
      for (final f in ref.watch(foldersStreamProvider).value ?? const [])
        if (f.sharedWith.contains(friend.uid)) f,
    ];
    final since = friend.since;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersonAvatar(label: label, size: 72),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (friend.name.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                friend.email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: s.onSurfaceVariant,
                ),
              ),
            ],
            if (since != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.friendsSince(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(since),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: s.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('friend-copy-email'),
                    onPressed: () {
                      unawaited(
                        Clipboard.setData(ClipboardData(text: friend.email)),
                      );
                      ScaffoldMessenger.of(context)
                          .showMessage(l10n.friendsEmailCopied);
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: Text(l10n.friendsCopyEmail),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('friend-remove'),
                    style: OutlinedButton.styleFrom(foregroundColor: s.error),
                    onPressed: () => _remove(context, ref),
                    icon: const Icon(Icons.person_remove_outlined, size: 18),
                    label: Text(l10n.friendsRemove),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SectionLabel(l10n.friendsSharedFolders),
            ),
            const SizedBox(height: 4),
            if (folders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.friendsNoSharedFolders,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: s.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final f in folders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(f.iconData, color: f.accent),
                  title: Text(f.name),
                ),
          ],
        ),
      ),
    );
  }
}

/// Bekleyen istek kartı: kim, ne zaman; Reddet / Kabul et tam düğme.
class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});
  final FriendRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final label = friendLabel(request.fromName, request.fromEmail);
    return Card(
      key: ValueKey('request-${request.fromUid}'),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PersonAvatar(label: label),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        l10n.friendsWantsToConnect,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (request.fromName.trim().isNotEmpty)
                        Text(
                          request.fromEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('request-decline-${request.fromUid}'),
                    onPressed: () => ref
                        .read(friendsRepositoryProvider)
                        ?.declineRequest(request.fromUid),
                    child: Text(l10n.friendsDecline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('request-accept-${request.fromUid}'),
                    onPressed: () => ref
                        .read(friendsRepositoryProvider)
                        ?.acceptRequest(request),
                    child: Text(l10n.friendsAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kişi ekleme — TEK alan: ad (en az 3 harf) yazınca kayıtlı kullanıcılar
/// içinde arar (`functions/searchUsers`); tam bir e-posta yazınca en üstte
/// "Bu adrese istek gönder" çıkar (arama dizinine düşmemiş eski hesaplar
/// için eski e-posta akışı). Gönderilen satır "Gönderildi" olur.
class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet();

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<UserSearchResult>? _results;
  bool _searching = false;
  final _sent = <String>{};
  String? _sentEmail;
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
    setState(() {});
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    final repo = ref.read(friendsRepositoryProvider);
    final gen = ++_generation;
    if (repo == null || !FriendsRepository.isSearchableQuery(q)) {
      setState(() => _results = null);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await repo.searchUsers(q);
      if (mounted && gen == _generation) setState(() => _results = results);
    } on FirebaseFunctionsException catch (e) {
      // Sunucu reddi (F1.1): misafir oturum `permission-denied`, hız sınırı
      // `resource-exhausted` — sessiz "sonuç yok" yerine nedenini söyle.
      if (mounted && gen == _generation) {
        setState(() => _results = const []);
        final msg = switch (e.code) {
          'permission-denied' => context.l10n.friendsSearchNeedsGoogle,
          'resource-exhausted' => context.l10n.friendsSearchRateLimited,
          _ => null,
        };
        if (msg != null) ScaffoldMessenger.of(context).showMessage(msg);
      }
    } catch (_) {
      if (mounted && gen == _generation) setState(() => _results = const []);
    } finally {
      if (mounted && gen == _generation) setState(() => _searching = false);
    }
  }

  /// Ortak hata eşlemesi: istek gönderen iki yol aynı bildirimleri verir.
  Future<bool> _send(Future<void> Function(FriendsRepository) action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null) return false;
    try {
      await action(repo);
      messenger.showMessage(l10n.friendsRequestSent);
      return true;
    } on FriendNotFoundException {
      messenger.showMessage(l10n.friendsNotFound);
    } on SelfFriendException {
      messenger.showMessage(l10n.friendsSelf);
    } on AlreadyFriendException {
      messenger.showMessage(l10n.friendsAlready);
    } catch (e) {
      messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
    }
    return false;
  }

  Future<void> _sendToUid(String uid) async {
    if (await _send((r) => r.sendRequestToUid(uid)) && mounted) {
      setState(() => _sent.add(uid));
    }
  }

  Future<void> _sendToEmail(String email) async {
    if (await _send((r) => r.sendRequest(email)) && mounted) {
      setState(() => _sentEmail = email.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final q = _controller.text.trim();
    final email = looksLikeEmail(q) ? q : null;
    final results = _results;
    final friendUids = {
      for (final f in ref.watch(friendsStreamProvider).value ?? const []) f.uid,
    };
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(l10n.friendsAdd, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const ValueKey('friends-add-field'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (_) {
                  if (email != null) unawaited(_sendToEmail(email));
                },
                decoration: InputDecoration(
                  hintText: l10n.friendsSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 2,
              child: _searching ? const LinearProgressIndicator() : null,
            ),
            Expanded(
              child: ListView(
                children: [
                  if (email != null)
                    ListTile(
                      key: const ValueKey('friends-send-email'),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.alternate_email,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(l10n.friendsSendToEmail),
                      subtitle: Text(email),
                      trailing: _sentEmail == email.toLowerCase()
                          ? _SentBadge(label: l10n.friendsSent)
                          : FilledButton.tonal(
                              onPressed: () => _sendToEmail(email),
                              child: Text(l10n.friendsSendRequest),
                            ),
                    ),
                  if (results == null && email == null)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.friendsSearchTooShort,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else if (results != null &&
                      results.isEmpty &&
                      !_searching &&
                      email == null)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.friendsSearchEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  for (final r in results ?? const <UserSearchResult>[])
                    ListTile(
                      key: ValueKey('friends-result-${r.uid}'),
                      leading: PersonAvatar(
                        label: friendLabel(r.name, r.email),
                      ),
                      title: Text(friendLabel(r.name, r.email)),
                      subtitle: Text(r.email),
                      trailing: friendUids.contains(r.uid)
                          ? _SentBadge(label: l10n.friendsAlreadyShort)
                          : _sent.contains(r.uid)
                          ? _SentBadge(label: l10n.friendsSent)
                          : FilledButton.tonal(
                              onPressed: () => _sendToUid(r.uid),
                              child: Text(l10n.friendsSearchAdd),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentBadge extends StatelessWidget {
  const _SentBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 18, color: s.primary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: s.primary)),
      ],
    );
  }
}

/// Kişiler ekranını bulunduğu yerden emniyetle açar: anonim (yerel) hesapta
/// e-posta olmadığı için özellik anlamsız — düğme yerine bilgi verir.
void openFriendsScreenOrExplain(BuildContext context, WidgetRef ref) {
  if (ref.read(isAnonymousProvider)) {
    showAccountRequiredSheet(context, ref);
    return;
  }
  unawaited(FriendsScreen.open(context));
}
