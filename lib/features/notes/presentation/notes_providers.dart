import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

enum NoteFilter { all, text, checklist, ordered, pinned, starred }

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
        ? {for (final s in state) if (s != id) s}
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
    (list) => [for (final n in list) if (n.archivedAt != null) n],
  );
});

/// Arama + filtre + etiket uygulanmış, arşiv dışı not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);

  return notes.whenData((list) {
    // Boş notlar (yeni oluşturulup hiç doldurulmamış) listede gösterilmez;
    // editörden çıkışta zaten silinirler, arka plan temizliği de kalıntıyı
    // toplar. Böylece boş kart dashboard'da hiç belirmez.
    var result = [
      for (final n in list)
        if (n.archivedAt == null && !n.isEmpty) n,
    ];
    if (tag != null) {
      result = [for (final n in result) if (n.tags.contains(tag)) n];
    }
    result = switch (filter) {
      NoteFilter.all => result,
      NoteFilter.text =>
        [for (final n in result) if (n.type == NoteType.text) n],
      NoteFilter.checklist =>
        [for (final n in result) if (n.type == NoteType.checklist) n],
      NoteFilter.ordered =>
        [for (final n in result) if (n.type == NoteType.ordered) n],
      NoteFilter.pinned => [for (final n in result) if (n.pinned) n],
      NoteFilter.starred => [for (final n in result) if (n.starred) n],
    };
    if (query.isNotEmpty) {
      result = [for (final n in result) if (_matches(n, query)) n];
    }
    return result;
  });
});

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
