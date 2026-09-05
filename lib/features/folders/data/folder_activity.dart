/// **PAYLAŞILAN KLASÖRDE HAREKET** (kullanıcı isteği 2026-09-04: "paylaşılan
/// notlarda karşı taraf yeni bir not eklediğinde veya bir notta değişiklik
/// yaptığında veya sohbet kısmında bir mesaj attığında … ana sayfada basit
/// bir işaretçi olmalı, mesela o klasör simgesinin sağ üstünde 1, 2 gibi").
///
/// İki kaynak, tek sayaç: klasördeki NOTLARIN değişmesi ve SOHBETE mesaj
/// düşmesi. "Okundu" damgası cihazda (SharedPreferences) durur — okuma
/// durumu kişiseldir, buluta yazılırsa iki cihaz birbirinin rozetini
/// söndürürdü.
///
/// **Kendi yazdığım sayılmaz**: notta `updatedBy`, mesajda `senderId` beni
/// gösteriyorsa hareket bana ait demektir (bkz. [Note.updatedBy]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/settings/settings_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import '../domain/note_folder.dart';
import 'folder_chat_repository.dart';
import 'folders_repository.dart';

/// Klasör başına "en son ne zaman baktım" (ms). Rozet ve bildirim aynı
/// damgaya bakar: bildirimi gördüğüm anda rozet de sıfırlanmalı.
final folderSeenProvider =
    NotifierProvider<FolderSeenNotifier, Map<String, int>>(
      FolderSeenNotifier.new,
    );

class FolderSeenNotifier extends Notifier<Map<String, int>> {
  static const _key = 'folder_seen_v1';

  @override
  Map<String, int> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): (entry.value as num).toInt(),
      };
    } catch (_) {
      // Bozuk kayıt rozeti kilitlemesin: temiz sayfa.
      return const {};
    }
  }

  /// Klasöre BAKILDI: o ana kadarki her şey okunmuş sayılır.
  void markSeen(String folderId, [DateTime? at]) {
    if (folderId.isEmpty) return;
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if ((state[folderId] ?? 0) >= now) return;
    state = {...state, folderId: now};
    unawaited(
      ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state)),
    );
  }

  DateTime seenAt(String folderId) =>
      DateTime.fromMillisecondsSinceEpoch(state[folderId] ?? 0);
}

/// Rozete yazılan sayının tavanı: "9+" yazan klasik Android rozeti.
const int kFolderBadgeMax = 9;

/// Bir klasördeki OKUNMAMIŞ hareket sayısı (not + mesaj).
///
/// [ownerId] klasörün sahibi: kendi klasörümde de rozet çıkar (birileriyle
/// paylaştığım klasöre karşı taraf not eklemiş olabilir).
final folderUnreadProvider =
    Provider.family<int, ({String ownerId, String folderId})>((ref, key) {
      final me = ref.watch(currentUidProvider);
      if (me == null) return 0;
      final seen = ref.watch(folderSeenProvider);
      final since = DateTime.fromMillisecondsSinceEpoch(
        seen[key.folderId] ?? 0,
      );
      // İLK AÇILIŞTA rozet ÇIKMAZ: damga hiç yoksa "her şey okunmuş" sayılır.
      // Aksi hâlde uygulamayı ilk kuran kullanıcı, klasörün bütün geçmişi
      // kadar okunmamış görürdü.
      if (since.millisecondsSinceEpoch == 0) return 0;
      final notes = ref.watch(sharedFolderNotesProvider(key)).value;
      final messages = ref.watch(folderMessagesProvider(key.folderId)).value;
      return countFolderUnread(
        notes: notes ?? const [],
        messages: messages ?? const [],
        since: since,
        me: me,
      );
    });

/// Saf sayım kuralı (testle ölçülüyor): [since]'ten SONRA gelen, BAŞKASININ
/// yaptığı hareketler.
int countFolderUnread({
  required List<Note> notes,
  required List<FolderMessage> messages,
  required DateTime since,
  required String me,
}) {
  var count = 0;
  for (final note in notes) {
    final at = note.updatedAt;
    if (at == null || !at.isAfter(since)) continue;
    if (note.updatedBy == me) continue;
    count++;
  }
  for (final message in messages) {
    final at = message.createdAt;
    if (at == null || !at.isAfter(since)) continue;
    if (message.senderId == me) continue;
    count++;
  }
  return count;
}

/// Ana ekranda izlenecek KLASÖRLER: bana paylaşılanlar + benim paylaştığım
/// klasörler. Paylaşılmamış bir klasörde "karşı taraf" yok, boşuna
/// dinlenmez.
final watchedSharedFoldersProvider =
    Provider<List<({String ownerId, String folderId, String name})>>((ref) {
      final me = ref.watch(currentUidProvider);
      final mine = ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
      final shared =
          ref.watch(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[];
      return [
        if (me != null)
          for (final folder in mine)
            if (folder.isShared)
              (ownerId: me, folderId: folder.id, name: folder.name),
        for (final share in shared)
          (
            ownerId: share.ownerId,
            folderId: share.folderId,
            name: share.name,
          ),
      ];
    });

/// Ana ekrandaki TOPLAM okunmamış sayısı (klasör çipinin/menünün rozeti).
final sharedUnreadTotalProvider = Provider<int>((ref) {
  var total = 0;
  for (final folder in ref.watch(watchedSharedFoldersProvider)) {
    total += ref.watch(
      folderUnreadProvider((
        ownerId: folder.ownerId,
        folderId: folder.folderId,
      )),
    );
  }
  return total;
});
