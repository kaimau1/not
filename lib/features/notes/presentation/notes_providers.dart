import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

enum NoteFilter { all, text, checklist, ordered, pinned }

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

/// Arama + filtre uygulanmış not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(noteFilterProvider);

  return notes.whenData((list) {
    var result = list;
    result = switch (filter) {
      NoteFilter.all => result,
      NoteFilter.text =>
        [for (final n in result) if (n.type == NoteType.text) n],
      NoteFilter.checklist =>
        [for (final n in result) if (n.type == NoteType.checklist) n],
      NoteFilter.ordered =>
        [for (final n in result) if (n.type == NoteType.ordered) n],
      NoteFilter.pinned => [for (final n in result) if (n.pinned) n],
    };
    if (query.isNotEmpty) {
      result = [for (final n in result) if (_matches(n, query)) n];
    }
    return result;
  });
});

bool _matches(Note note, String query) {
  if (note.title.toLowerCase().contains(query)) return true;
  if (note.body.toLowerCase().contains(query)) return true;
  for (final item in note.items) {
    if (item.text.toLowerCase().contains(query)) return true;
  }
  for (final attachment in note.attachments) {
    if (attachment.fileName.toLowerCase().contains(query)) return true;
  }
  return false;
}
