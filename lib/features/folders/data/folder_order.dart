import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/stable_value.dart';

import '../../notes/data/notes_repository.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/note_folder.dart';
import 'folders_repository.dart';

/// **KLASÖR SIRALAMASI** (kullanıcı isteği 2026-09-26: "klasör sıralaması
/// ayarlama").
///
/// Klasörler eskiden yalnız ADA göre diziliyordu (depo akışı öyle
/// sıralıyor). Sık kullanılan klasörü başa almanın, yeni açılanı öne
/// çıkarmanın yolu yoktu; yana çekişle klasörler arasında gezilmeye
/// başlayınca (bkz. `nextHomeSwipeStop`) sıra doğrudan gezinme sırası da
/// oldu — kullanıcının belirlemesi şart.
enum FolderSort {
  /// Elle: klasör rafında/ayarlarda sürükleyerek verilen sıra.
  manual,

  /// Ada göre (A → Z) — eski tek davranış.
  name,

  /// En yeni klasör önce.
  newest,

  /// En çok notu olan önce.
  noteCount,
}

final folderSortProvider = NotifierProvider<FolderSortNotifier, FolderSort>(
  FolderSortNotifier.new,
);

class FolderSortNotifier extends Notifier<FolderSort> {
  static const _key = 'folder_sort';

  @override
  FolderSort build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    // Varsayılan AD: güncellemeyle kullanıcının alışık olduğu sıra
    // değişmesin. Elle sıralayan kullanıcı ilk sürüklemede elle sıraya geçer.
    return FolderSort.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => FolderSort.name,
    );
  }

  void set(FolderSort value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.name);
  }
}

/// Klasörleri [sort]a göre dizer (saf — testli).
///
/// [counts] klasör kimliği → not sayısı; yalnız [FolderSort.noteCount]
/// kullanır. Eşitlikte her ölçüt ADA düşer ki sıra kararlı olsun (akışın
/// her yayınında aynı sayıdaki iki klasör yer değiştirmesin).
List<NoteFolder> sortFolders(
  List<NoteFolder> folders,
  FolderSort sort, {
  Map<String, int> counts = const {},
}) {
  int byName(NoteFolder a, NoteFolder b) {
    final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  final list = [...folders];
  switch (sort) {
    case FolderSort.name:
      list.sort(byName);
    case FolderSort.manual:
      list.sort((a, b) {
        final ao = a.order;
        final bo = b.order;
        // Hiç sıralanmamış (yeni) klasörler sona, kendi aralarında ada göre.
        if (ao == null && bo == null) return byName(a, b);
        if (ao == null) return 1;
        if (bo == null) return -1;
        final c = ao.compareTo(bo);
        return c != 0 ? c : byName(a, b);
      });
    case FolderSort.newest:
      list.sort((a, b) {
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null && bt == null) return byName(a, b);
        // Tarihi henüz sunucudan gelmemiş klasör az önce açılmıştır: en yeni.
        if (at == null) return -1;
        if (bt == null) return 1;
        final c = bt.compareTo(at);
        return c != 0 ? c : byName(a, b);
      });
    case FolderSort.noteCount:
      list.sort((a, b) {
        final c = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        return c != 0 ? c : byName(a, b);
      });
  }
  return list;
}

/// Klasör kimliği → içindeki (arşivlenmemiş, boş olmayan) not sayısı.
final folderNoteCountsProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesStreamProvider).value;
  if (notes == null) return const {};
  final counts = <String, int>{};
  for (final n in notes) {
    final id = n.folderId;
    if (id == null || n.archivedAt != null || n.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  // Sayılar değişmedikçe AYNI harita (F2.1): yoksa her not yazımında klasör
  // rafı ve sayıya göre sıralı klasör listesi yeniden kuruluyordu.
  return ref.watch(_folderNoteCountsBox).keep(counts, sameMap);
});

final _folderNoteCountsBox = Provider<StableBox<Map<String, int>>>(
  (ref) => StableBox(),
);

/// Kullanıcının KENDİ klasörleri, seçili [FolderSort] ile sıralı. Gizli
/// klasörler DAHİL — süzmek tüketicinin işi (bazı yerler gizlileri kimlik
/// doğrulamasıyla gösteriyor).
final orderedFoldersProvider = Provider<List<NoteFolder>>((ref) {
  final folders =
      ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
  final sort = ref.watch(folderSortProvider);
  // Sayaçlar YALNIZ sayıya göre sıralamada izlenir: her not yazımında
  // değişiyorlar, koşulsuz izlense klasör rafı her tuşta yeniden dizilirdi.
  final counts = sort == FolderSort.noteCount
      ? ref.watch(folderNoteCountsProvider)
      : const <String, int>{};
  return sortFolders(folders, sort, counts: counts);
});

/// Ana ekranda GÖRÜNEN kendi klasörlerim, kullanıcının sırasıyla: gizli
/// klasörler yalnız o oturumda açığa çıkarıldıysa.
final visibleOrderedFoldersProvider = Provider<List<NoteFolder>>((ref) {
  final revealHidden = ref.watch(hiddenFoldersRevealedProvider);
  return [
    for (final f in ref.watch(orderedFoldersProvider))
      if (!f.hidden || revealHidden) f,
  ];
});
