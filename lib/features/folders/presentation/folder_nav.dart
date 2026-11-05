import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folder_activity.dart';

/// **KLASÖR = SÜZGEÇLİ ANA EKRAN** (kullanıcı isteği 2026-10-28; paylaşılan
/// klasör için TUTARLILIK K8, 2026-11-05). Kendi klasörüm de paylaşılan klasör
/// de ayrı sayfa açmaz: aynı ızgara, aynı şerit, aynı arama/Süz, geri tuşu
/// süzgeci kaldırır. [ownerId] başkasıysa notlar sahibinin koleksiyonundan
/// gelir (`sharedFolderSlivers`).
void openFolder(BuildContext context, String folderId, {String? ownerId}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final shared =
      ownerId != null && ownerId != container.read(currentUidProvider);
  container.read(noteFilterProvider.notifier).set(NoteFilter.all);
  container.read(selectedTagProvider.notifier).set(null);
  container.read(sharedHubOnHomeProvider.notifier).set(false);
  if (shared && container.read(showAllNotesProvider)) {
    container.read(showAllNotesProvider.notifier).set(false);
  }
  container.read(selectedFolderProvider.notifier).set(shared ? null : folderId);
  container
      .read(selectedSharedFolderProvider.notifier)
      .set(shared ? (ownerId: ownerId, folderId: folderId) : null);
  // Klasörü açmak oradaki her şeyi okunmuş sayar: rozet söner.
  container.read(folderSeenProvider.notifier).markSeen(folderId);
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  // Sayfasız rota (ör. klasör levhası) üstteyse ana ekrana kadar kapanır.
  Navigator.of(context).popUntil((route) => route.settings is Page);
  if (!isSplitShellLocation(router.state.uri.path)) router.go('/');
}
