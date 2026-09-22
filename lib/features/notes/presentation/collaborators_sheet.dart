import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friends_screen.dart';
import '../data/note_shares_repository.dart';

/// **ORTAK ÇALIŞANLAR** levhası — Keep'teki "Ortak çalışan" düğmesinin
/// karşılığı (kullanıcı isteği 2026-09-22: "ortak not butonu keepteki gibi").
///
/// İki yüzü var:
/// * **Sahip** ([ownerId] null): arkadaş listesinden kişileri işaretler,
///   Kaydet'e basınca liste tek yazımla aynaya düşer (bkz.
///   [NoteSharesRepository.setCollaborators]). Anlık yazım yerine TOPLU
///   kayıt bilinçli: her dokunuşta yazılsaydı kararsız bir işaretleme,
///   karşı tarafın ekranında notun belirip kaybolmasına yol açardı.
/// * **Ortak çalışan** ([ownerId] dolu): kimlerle paylaşıldığını görür,
///   yalnız kendini çıkarabilir ("Paylaşımdan ayrıl").
Future<void> showCollaboratorsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String noteId,
  String? ownerId,
}) async {
  // Yerel (anonim) hesapta arkadaş kavramı yok — klasör paylaşımıyla aynı
  // açıklama (bkz. openFriendsScreenOrExplain).
  if (ownerId == null && ref.read(isAnonymousProvider)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendsNeedsAccount)));
    return;
  }
  final result = await showModalBottomSheet<_SheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Geniş ekranda levha ekranın tamamına yayılmasın; okunur bir sütun.
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => ownerId == null
        ? _OwnerView(noteId: noteId)
        : _CollaboratorView(noteId: noteId, ownerId: ownerId),
  );
  if (!context.mounted) return;
  switch (result) {
    // Levhanın kendi bağlamı kapandıktan sonra kullanılamaz; arkadaş
    // ekranı levhayı AÇAN bağlamdan açılır.
    case _SheetResult.openFriends:
      openFriendsScreenOrExplain(context, ref);
    // Paylaşımdan ayrılan kullanıcı artık bu notu okuyamaz: editörü kapat.
    case _SheetResult.left:
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    case null:
      break;
  }
}

enum _SheetResult { openFriends, left }

class _OwnerView extends ConsumerStatefulWidget {
  const _OwnerView({required this.noteId});

  final String noteId;

  @override
  ConsumerState<_OwnerView> createState() => _OwnerViewState();
}

class _OwnerViewState extends ConsumerState<_OwnerView> {
  /// uid → görünen ad. Levha açılınca mevcut aynadan doldurulur.
  Map<String, String>? _selected;
  bool _saving = false;

  String _label(Friend f) => f.name.isEmpty ? f.email : f.name;

  Future<void> _save(Map<String, String> initial) async {
    final selected = _selected ?? initial;
    final repo = ref.read(noteSharesRepositoryProvider);
    if (repo == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await repo.setCollaborators(widget.noteId, selected);
      if (mounted) Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.collaboratorsSaved)));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final friends = ref.watch(friendsStreamProvider).value ?? const <Friend>[];
    final share = ref.watch(myNoteSharesProvider).value?[widget.noteId];
    final initial = share?.names.isNotEmpty ?? false
        ? Map<String, String>.of(share!.names)
        : {for (final uid in share?.sharedWith ?? const <String>[]) uid: ''};
    final selected = _selected ?? initial;
    // Aynada olup artık arkadaş listemde olmayan kişi de görünsün ve
    // çıkarılabilsin — aksi hâlde arkadaşlıktan çıkan biri notta sonsuza
    // dek görünmez biçimde kalırdı.
    final friendIds = {for (final f in friends) f.uid};
    final strangers = [
      for (final uid in selected.keys)
        if (!friendIds.contains(uid)) uid,
    ];
    final user = ref.watch(authStateProvider).value;
    final me = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? '');

    void toggle(String uid, String name, bool on) => setState(() {
      final next = Map<String, String>.of(selected);
      if (on) {
        next[uid] = name;
      } else {
        next.remove(uid);
      }
      _selected = next;
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.collaborators,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.collaboratorsInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person, color: scheme.onPrimaryContainer),
              ),
              title: Text(me),
              subtitle: Text(l10n.collaboratorsOwner),
            ),
            const Divider(height: 8),
            if (friends.isEmpty && strangers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.friendsEmpty),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, _SheetResult.openFriends),
                      icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                      label: Text(l10n.friendsAdd),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  l10n.collaboratorsFriendsTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final friend in friends)
                        CheckboxListTile(
                          key: ValueKey('collab-${friend.uid}'),
                          contentPadding: EdgeInsets.zero,
                          secondary: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(_label(friend)),
                          subtitle: friend.name.isEmpty
                              ? null
                              : Text(friend.email),
                          value: selected.containsKey(friend.uid),
                          onChanged: _saving
                              ? null
                              : (on) => toggle(
                                  friend.uid,
                                  _label(friend),
                                  on ?? false,
                                ),
                        ),
                      for (final uid in strangers)
                        CheckboxListTile(
                          key: ValueKey('collab-$uid'),
                          contentPadding: EdgeInsets.zero,
                          secondary: const CircleAvatar(
                            child: Icon(Icons.person_off_outlined),
                          ),
                          title: Text(
                            (selected[uid] ?? '').isEmpty
                                ? uid
                                : selected[uid]!,
                          ),
                          value: true,
                          onChanged: _saving
                              ? null
                              : (on) => toggle(uid, selected[uid] ?? '', false),
                        ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _SheetResult.openFriends),
                  icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                  label: Text(l10n.friendsAdd),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving || _selected == null
                      ? null
                      : () => _save(initial),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.quickCaptureSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CollaboratorView extends ConsumerWidget {
  const _CollaboratorView({required this.noteId, required this.ownerId});

  final String noteId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final share = ref
        .watch(noteShareProvider((ownerId: ownerId, noteId: noteId)))
        .value;
    final myUid = ref.watch(currentUidProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.collaborators,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.collaboratorsOnlyOwner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person, color: scheme.onPrimaryContainer),
              ),
              title: Text(share?.ownerName ?? ''),
              subtitle: Text(l10n.collaboratorsOwner),
            ),
            for (final uid in share?.sharedWith ?? const <String>[])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  (share!.names[uid] ?? '').isEmpty ? uid : share.names[uid]!,
                ),
                trailing: uid == myUid
                    ? Icon(Icons.check_circle, color: scheme.primary, size: 18)
                    : null,
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.collaboratorsLeave),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.collaboratorsLeave),
                      content: Text(l10n.collaboratorsLeaveConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(l10n.collaboratorsLeave),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  final repo = ref.read(noteSharesRepositoryProvider);
                  if (repo == null) return;
                  try {
                    await repo.leave(ownerId, noteId);
                    if (context.mounted) {
                      Navigator.pop(context, _SheetResult.left);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.genericError('$e'))),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
