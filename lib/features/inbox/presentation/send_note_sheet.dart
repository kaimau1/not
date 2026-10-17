import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../notes/domain/note.dart';
import '../data/inbox_repository.dart';
import '../../../core/widgets/app_sheet.dart';

/// **NOTU ARKADAŞA GÖNDER** (kullanıcı isteği 2026-08-18: "not paylaş
/// seçeneği de lazım"). Arkadaş listesinden seçilen kişinin GELEN NOTLAR
/// kutusuna bir kopya bırakır (bkz. [InboxRepository]).
///
/// Klasör paylaşımından farkı bilerek: bu tek seferlik bir GÖNDERİMDİR,
/// ortak bir alan değil — alıcı kabul edince not onun olur.
Future<void> showSendNoteToFriendSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  // Yerel (anonim) hesapta arkadaş kavramı yok: e-posta olmadan kimse
  // bulunamaz, kural da arkadaşlık kanıtı arar.
  if (ref.read(isAnonymousProvider)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendsNeedsAccount)));
    return;
  }
  await showAppSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, sheetRef, _) {
        final l10n = sheetContext.l10n;
        final friends =
            sheetRef.watch(friendsStreamProvider).value ?? const <Friend>[];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sendNoteTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sendNoteInfo,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.friendsEmpty),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            openFriendsScreenOrExplain(context, ref);
                          },
                          icon: const Icon(
                            Icons.person_add_alt_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.friendsAdd),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final friend in friends)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                friend.name.isEmpty
                                    ? friend.email
                                    : friend.name,
                              ),
                              subtitle: Text(friend.email),
                              trailing: const Icon(Icons.send_outlined),
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                await _send(context, ref, note, friend);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _send(
  BuildContext context,
  WidgetRef ref,
  Note note,
  Friend friend,
) async {
  final l10n = context.l10n;
  final repo = ref.read(inboxRepositoryProvider);
  if (repo == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final label = friend.name.isEmpty ? friend.email : friend.name;
  try {
    await repo.sendNote(note, friend.uid);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.sendNoteSent(label))));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
  }
}
