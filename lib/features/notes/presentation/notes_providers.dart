import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

enum NoteFilter { all, text, checklist, ordered, pinned, starred }

/// Dashboard sıralama ölçütü. [manual] = akışın varsayılanı (elle sürükleme /
/// oluşturma sırası); diğerleri istemci tarafında yeniden sıralar.
enum NoteSort { manual, updated, created, title }

/// Seçili sıralama ölçütü (kalıcı). Sabitlenmiş notlar dashboard'da yine ayrı
/// bir bölümde toplanır; sıralama her bölümün kendi içinde uygulanır.
final noteSortProvider = NotifierProvider<NoteSortNotifier, NoteSort>(
  NoteSortNotifier.new,
);

class NoteSortNotifier extends Notifier<NoteSort> {
  static const _key = 'note_sort';

  @override
  NoteSort build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return NoteSort.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => NoteSort.manual,
    );
  }

  void set(NoteSort value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.name);
  }
}

/// Ana ekranda görünen filtre çipleri. "Tümü" her zaman görünür; gerisi
/// kullanıcı isteğine bağlıdır. Varsayılanda tip filtreleri (metin/liste/
/// sıralı) gizlidir — sayfa sade kalır, isteyen filtre menüsünden ekler.
///
/// Sıralı liste (Set değil): kullanıcı filtre menüsünden çipleri sürükleyip
/// yeniden dizebilir; sıra kalıcıdır ve çip barında aynen uygulanır.
final visibleNoteFiltersProvider =
    NotifierProvider<VisibleNoteFiltersNotifier, List<NoteFilter>>(
      VisibleNoteFiltersNotifier.new,
    );

class VisibleNoteFiltersNotifier extends Notifier<List<NoteFilter>> {
  static const _key = 'visible_filters';
  static const _defaults = [NoteFilter.pinned, NoteFilter.starred];

  @override
  List<NoteFilter> build() {
    final stored = ref.watch(sharedPreferencesProvider).getStringList(_key);
    if (stored == null) return _defaults;
    // Kayıtlı sırayı koru; geçersiz/yinelenen adları ve "Tümü"yü ele.
    final result = <NoteFilter>[];
    for (final name in stored) {
      for (final filter in NoteFilter.values) {
        if (filter.name == name &&
            filter != NoteFilter.all &&
            !result.contains(filter)) {
          result.add(filter);
        }
      }
    }
    return result;
  }

  void _persist(List<NoteFilter> next) {
    ref.read(sharedPreferencesProvider).setStringList(_key, [
      for (final f in next) f.name,
    ]);
  }

  void toggle(NoteFilter filter) {
    if (filter == NoteFilter.all) return;
    final next = state.contains(filter)
        ? [
            for (final f in state)
              if (f != filter) f,
          ]
        : [...state, filter];
    state = next;
    _persist(next);
    // Gizlenen filtre o an seçiliyse listeyi kilitlemesin.
    if (!next.contains(ref.read(noteFilterProvider)) &&
        ref.read(noteFilterProvider) != NoteFilter.all) {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    }
  }

  /// Görünür filtrelerin sırasını değiştirir (filtre menüsünde sürükle-bırak).
  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(target, item);
    state = next;
    _persist(next);
  }
}

/// Ana ekran filtre barı genişletildi mi? (madde 4) Kapalıyken tek satır
/// kompakt çip; açıkken klasör ve etiketler bölümler hâlinde tam görünür.
/// Çip barında etiket çipleri görünsün mü (kullanıcı tercihi, kalıcı).
/// Filtreler gibi gizlenebilir: çok etiketi olan kullanıcıda satır şişiyordu.
final showTagChipsProvider = NotifierProvider<ShowTagChipsNotifier, bool>(
  ShowTagChipsNotifier.new,
);

class ShowTagChipsNotifier extends Notifier<bool> {
  static const _key = 'show_tag_chips';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Çip barında klasör çipleri görünsün mü (kullanıcı tercihi, kalıcı).
final showFolderChipsProvider = NotifierProvider<ShowFolderChipsNotifier, bool>(
  ShowFolderChipsNotifier.new,
);

class ShowFolderChipsNotifier extends Notifier<bool> {
  static const _key = 'show_folder_chips';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final filtersExpandedProvider =
    NotifierProvider<FiltersExpandedNotifier, bool>(
      FiltersExpandedNotifier.new,
    );

class FiltersExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Seçili klasör (null = klasör filtresi yok).
final selectedFolderProvider =
    NotifierProvider<SelectedFolderNotifier, String?>(
      SelectedFolderNotifier.new,
    );

class SelectedFolderNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Ana ekran mikrofon widget'ı (notlar://voice) dokunulunca ayarlanan
/// tüketilebilir bayrak; dashboard bunu görüp Sesli Not Asistanı'nı bas-başlat
/// modunda başlatır (ayrı /voice ekranı yerine tek tutarlı sistem).
/// [take] tam bir kez tüketir: uygulama başka ekrandayken gelen istek de
/// (dashboard henüz dinlemiyorken) kaybolmaz — dashboard mount olunca okur;
/// dashboard'a her dönüşte yeniden tetiklenmez (bayrak tüketilmiştir).
final voiceAutostartProvider = NotifierProvider<VoiceAutostartNotifier, bool>(
  VoiceAutostartNotifier.new,
);

class VoiceAutostartNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// İstek varsa true döner ve bayrağı düşürür (tek seferlik).
  bool take() {
    if (!state) return false;
    state = false;
    return true;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final noteFilterProvider = NotifierProvider<NoteFilterNotifier, NoteFilter>(
  NoteFilterNotifier.new,
);

class NoteFilterNotifier extends Notifier<NoteFilter> {
  @override
  NoteFilter build() => NoteFilter.all;

  void set(NoteFilter value) => state = value;
}

/// Anlamsal (AI) arama modu açık mı?
final semanticSearchEnabledProvider =
    NotifierProvider<SemanticSearchEnabledNotifier, bool>(
      SemanticSearchEnabledNotifier.new,
    );

class SemanticSearchEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Çoklu seçim modu: seçili not id'leri (boş küme = seçim modu kapalı).
final selectedNoteIdsProvider =
    NotifierProvider<SelectedNoteIdsNotifier, Set<String>>(
      SelectedNoteIdsNotifier.new,
    );

class SelectedNoteIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    state = state.contains(id)
        ? {
            for (final s in state)
              if (s != id) s,
          }
        : {...state, id};
  }

  void clear() => state = const {};
}

/// Seçili etiket (null = etiket filtresi yok).
final selectedTagProvider = NotifierProvider<SelectedTagNotifier, String?>(
  SelectedTagNotifier.new,
);

class SelectedTagNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Aktif (arşivlenmemiş) notlarda geçen tüm etiketler, alfabetik.
final allTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final tags = <String>{
    for (final note in notes)
      if (note.archivedAt == null) ...note.tags,
  };
  final sorted = tags.toList()..sort();
  return sorted;
});

/// Etiket → kullanım sayısı (aktif notlarda). Ana sayfadaki çip satırı en
/// sık kullanılanları öne alıp gerisini "+N" arkasına gizler.
final tagCountsProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final counts = <String, int>{};
  for (final note in notes) {
    if (note.archivedAt != null) continue;
    for (final tag in note.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
});

/// Arşivlenmiş notlar (arşiv ekranı için).
final archivedNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  return notes.whenData(
    (list) => [
      for (final n in list)
        if (n.archivedAt != null) n,
    ],
  );
});

/// Arama + filtre + etiket + klasör uygulanmış, arşiv dışı not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final sort = ref.watch(noteSortProvider);

  return notes.whenData((list) {
    // Boş notlar (yeni oluşturulup hiç doldurulmamış) listede gösterilmez;
    // editörden çıkışta zaten silinirler, arka plan temizliği de kalıntıyı
    // toplar. Böylece boş kart dashboard'da hiç belirmez.
    var result = [
      for (final n in list)
        if (n.archivedAt == null && !n.isEmpty) n,
    ];
    if (folderId != null) {
      result = [
        for (final n in result)
          if (n.folderId == folderId) n,
      ];
    }
    if (tag != null) {
      result = [
        for (final n in result)
          if (n.tags.contains(tag)) n,
      ];
    }
    result = switch (filter) {
      NoteFilter.all => result,
      NoteFilter.text => [
        for (final n in result)
          if (n.type == NoteType.text) n,
      ],
      NoteFilter.checklist => [
        for (final n in result)
          if (n.type == NoteType.checklist) n,
      ],
      NoteFilter.ordered => [
        for (final n in result)
          if (n.type == NoteType.ordered) n,
      ],
      NoteFilter.pinned => [
        for (final n in result)
          if (n.pinned) n,
      ],
      NoteFilter.starred => [
        for (final n in result)
          if (n.starred) n,
      ],
    };
    if (query.isNotEmpty) {
      result = [
        for (final n in result)
          if (_matches(n, query)) n,
      ];
    }
    return _sortedNotes(result, sort);
  });
});

/// Seçili ölçüte göre notları sıralar. [NoteSort.manual] akıştan gelen sırayı
/// (orderIndex → updatedAt) korur; başlığa göre sıralamada başlıksız notlar
/// sona düşer.
List<Note> _sortedNotes(List<Note> notes, NoteSort sort) {
  if (sort == NoteSort.manual) return notes;
  final list = [...notes];
  int dateDesc(DateTime? a, DateTime? b) {
    final at = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }

  switch (sort) {
    case NoteSort.manual:
      break;
    case NoteSort.updated:
      list.sort((a, b) => dateDesc(a.updatedAt, b.updatedAt));
    case NoteSort.created:
      list.sort((a, b) => dateDesc(a.createdAt, b.createdAt));
    case NoteSort.title:
      list.sort((a, b) {
        final at = a.title.trim().toLowerCase();
        final bt = b.title.trim().toLowerCase();
        if (at.isEmpty && bt.isEmpty) return dateDesc(a.updatedAt, b.updatedAt);
        if (at.isEmpty) return 1;
        if (bt.isEmpty) return -1;
        return at.compareTo(bt);
      });
  }
  return list;
}

bool _matches(Note note, String query) {
  if (note.title.toLowerCase().contains(query)) return true;
  // Kilitli notun içeriği aramaya sızmasın; yalnızca başlıktan bulunur.
  if (note.locked) return false;
  if (note.body.toLowerCase().contains(query)) return true;
  for (final item in note.items) {
    if (item.text.toLowerCase().contains(query)) return true;
  }
  for (final attachment in note.attachments) {
    if (attachment.fileName.toLowerCase().contains(query)) return true;
  }
  for (final tag in note.tags) {
    if (tag.toLowerCase().contains(query)) return true;
  }
  return false;
}
