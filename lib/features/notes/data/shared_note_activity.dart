/// **BENİMLE PAYLAŞILAN NOTTA HAREKET** (kullanıcı bulgusu 2026-10-17:
/// "paylaşılanlar iletişim zor, yeni bir şey geldiğinde anlaşılmıyor").
///
/// Paylaşılan KLASÖRÜN rozeti vardı (bkz. `folder_activity.dart`), tek tek
/// paylaşılan notun (ortak not, bkz. [NoteShare]) hiçbir izi yoktu: biri
/// beni bir notuna ekleyince ya da notu değiştirince ancak "Benimle
/// paylaşılanlar" sayfasını kendim açıp bakarsam görüyordum.
///
/// İki tür "yeni": (1) beni YENİ eklediler — bu cihazda o paylaşıma hiç
/// bakılmadı; (2) bakıldıktan SONRA başkası notu değiştirdi
/// (`updatedBy` ben değilim). "Okundu" damgası cihazda durur — klasör
/// rozetiyle aynı gerekçe: okuma durumu kişiseldir.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import 'note_shares_repository.dart';
import 'notes_repository.dart';

/// Paylaşım kimliği ([NoteShare.id]) → en son bakış (ms). Boş anahtar
/// ([kSharedSeenBaseline]) bu cihazın izlemeye BAŞLADIĞI an: o yokken hiçbir
/// şey "yeni" sayılmaz (güncellemeyi kuran kullanıcı, eski paylaşımların
/// hepsini yeni görmesin).
final sharedNoteSeenProvider =
    NotifierProvider<SharedNoteSeenNotifier, Map<String, int>>(
      SharedNoteSeenNotifier.new,
    );

const String kSharedSeenBaseline = '';

/// Damganın anahtarı — paylaşım aynasının kimliğiyle aynı ([NoteShare.id]).
String sharedNoteKey(String ownerId, String noteId) =>
    NoteShare.shareIdOf(ownerId, noteId);

class SharedNoteSeenNotifier extends Notifier<Map<String, int>> {
  static const _key = 'shared_note_seen_v1';

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
      return const {};
    }
  }

  void _save() => unawaited(
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state)),
  );

  /// İlk kez izlemeye başlarken o an var olan paylaşımlar "görülmüş" sayılır.
  /// Damga zaten varsa hiçbir şey yapmaz.
  void adopt(Iterable<String> shareIds) {
    if (state.containsKey(kSharedSeenBaseline)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    state = {kSharedSeenBaseline: now, for (final id in shareIds) id: now};
    _save();
  }

  /// Paylaşılan nota BAKILDI (editörde açık): o ana kadarki her şey okundu.
  void markSeen(String shareId, [DateTime? at]) {
    if (shareId.isEmpty) return;
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    if ((state[shareId] ?? 0) >= now) return;
    state = {...state, shareId: now};
    _save();
  }

  /// Artık paylaşılmayan notların damgaları birikmesin.
  void retain(Set<String> liveIds) {
    final stale = [
      for (final id in state.keys)
        if (id != kSharedSeenBaseline && !liveIds.contains(id)) id,
    ];
    if (stale.isEmpty) return;
    state = {...state}..removeWhere((id, _) => stale.contains(id));
    _save();
  }
}

/// Saf kural (testle ölçülüyor): paylaşılan not bana göre YENİ mi?
bool isSharedNoteUnread({
  required Note note,
  required int? seenMs,
  required int? baselineMs,
  required String me,
}) {
  // Henüz izlemeye başlanmadı: rozet yok.
  if (baselineMs == null) return false;
  // Son dokunuş benim: yeni bir şey yok.
  if (note.updatedBy == me) return false;
  // Bu cihazda hiç bakılmamış paylaşım = beni yeni eklediler.
  if (seenMs == null) return true;
  final at = note.updatedAt;
  return at != null && at.millisecondsSinceEpoch > seenMs;
}

/// Benimle paylaşılan notlardan YENİ olanların paylaşım kimlikleri.
final sharedNoteUnreadProvider = Provider<Set<String>>((ref) {
  final me = ref.watch(currentUidProvider);
  if (me == null) return const {};
  final seen = ref.watch(sharedNoteSeenProvider);
  final baseline = seen[kSharedSeenBaseline];
  if (baseline == null) return const {};
  final out = <String>{};
  for (final share
      in ref.watch(sharedNotesWithMeProvider).value ?? const <NoteShare>[]) {
    final note = ref
        .watch(
          ownedNoteStreamProvider((
            ownerId: share.ownerId,
            noteId: share.noteId,
          )),
        )
        .value;
    if (note == null || note.deletedAt != null) continue;
    if (isSharedNoteUnread(
      note: note,
      seenMs: seen[share.id],
      baselineMs: baseline,
      me: me,
    )) {
      out.add(share.id);
    }
  }
  return out;
});
