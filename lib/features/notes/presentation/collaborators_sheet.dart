import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/group_card.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friends_screen.dart';
import '../data/note_shares_repository.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/friendly_error.dart';
import '../../auth/presentation/account_required.dart';
import '../../../app/theme/app_tokens.dart';

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
    await showAccountRequiredSheet(context, ref);
    return;
  }
  final result = await showAppSheet<_SheetResult>(
    context: context,
    // SheetHeader'da ✕ var → tutamak yok (DENEYIM K-D7).
    showDragHandle: false,
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

Widget _ownerTile(
  BuildContext context, {
  required String name,
  required String badge,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final text = AppText.of(theme);
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      child: Icon(
        Icons.person_rounded,
        color: scheme.onPrimaryContainer,
        size: AppIconSize.m,
      ),
    ),
    title: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.body.copyWith(fontWeight: AppWeight.strong),
    ),
    trailing: DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xxs,
        ),
        child: Text(
          badge,
          style: text.badge.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    ),
  );
}

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
        ..showMessage(l10n.collaboratorsSaved);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.collaborators),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.m,
              ),
              child: Text(l10n.collaboratorsInfo, style: text.meta),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
              child: GroupCard(
                children: [
                  _ownerTile(
                    context,
                    name: me,
                    badge: l10n.collaboratorsOwner,
                  ),
                ],
              ),
            ),
            if (friends.isEmpty && strangers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.m,
                  AppSpace.l,
                  AppSpace.s,
                ),
                child: GroupCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpace.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.friendsEmpty, style: text.body),
                          const SizedBox(height: AppSpace.m),
                          FilledButton.tonalIcon(
                            onPressed: () => Navigator.pop(
                              context,
                              _SheetResult.openFriends,
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_outlined,
                              size: AppIconSize.s,
                            ),
                            label: Text(l10n.friendsAdd),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.l,
                  AppSpace.l,
                  AppSpace.s,
                ),
                child: SectionLabel(l10n.collaboratorsFriendsTitle),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  child: GroupCard(
                    children: [
                      for (final friend in friends)
                        CheckboxListTile(
                          key: ValueKey('collab-${friend.uid}'),
                          secondary: CircleAvatar(
                            backgroundColor: selected.containsKey(friend.uid)
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: AppIconSize.m,
                              color: selected.containsKey(friend.uid)
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            _label(friend),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: friend.name.isEmpty
                              ? null
                              : Text(
                                  friend.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.meta,
                                ),
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
                          secondary: CircleAvatar(
                            backgroundColor: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.person_off_outlined,
                              size: AppIconSize.m,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(
                            (selected[uid] ?? '').isEmpty
                                ? uid
                                : selected[uid]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.m,
                AppSpace.l,
                AppSpace.l,
              ),
              child: Row(
                children: [
                  if (friends.isNotEmpty || strangers.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context, _SheetResult.openFriends),
                      icon: const Icon(
                        Icons.person_add_alt_outlined,
                        size: AppIconSize.s,
                      ),
                      label: Text(l10n.friendsAdd),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpace.s),
                  FilledButton(
                    onPressed: _saving || _selected == null
                        ? null
                        : () => _save(initial),
                    child: _saving
                        ? const SizedBox(
                            width: AppIconSize.s,
                            height: AppIconSize.s,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.quickCaptureSave),
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

class _CollaboratorView extends ConsumerWidget {
  const _CollaboratorView({required this.noteId, required this.ownerId});

  final String noteId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final share = ref
        .watch(noteShareProvider((ownerId: ownerId, noteId: noteId)))
        .value;
    final myUid = ref.watch(currentUidProvider);
    final members = share?.sharedWith ?? const <String>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.collaborators),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.m,
              ),
              child: Text(l10n.collaboratorsOnlyOwner, style: text.meta),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                child: GroupCard(
                  children: [
                    _ownerTile(
                      context,
                      name: share?.ownerName ?? '',
                      badge: l10n.collaboratorsOwner,
                    ),
                    for (final uid in members)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: uid == myUid
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: AppIconSize.m,
                            color: uid == myUid
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          (share!.names[uid] ?? '').isEmpty
                              ? uid
                              : share.names[uid]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: uid == myUid
                            ? Icon(
                                Icons.check_circle,
                                color: scheme.primary,
                                size: AppIconSize.s,
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: AppAlpha.muted),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: AppIconSize.s),
                  label: Text(l10n.collaboratorsLeave),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.collaboratorsLeave),
                        content: Text(l10n.collaboratorsLeaveConfirm),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
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
                        showAppMessage(
                          context,
                          l10n.genericError(friendlyError(l10n, e)),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
