import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/semantic_search.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F18.17: ilgili notlar — AI yokken yerel yedek; kilitli/bağlı olan girmez.
void main() {
  test('yerel yedek: kelime örtüşmesi, kilitli ve zaten bağlı hariç', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const target = Note(
      id: 't',
      type: NoteType.text,
      title: 'Bahçe sulama planı',
      body: 'domates biber sulama',
      tagLinks: [NoteTagLink(label: 'x', attachmentId: 'note:linked')],
    );
    const notes = [
      target,
      Note(id: 'r', type: NoteType.text, title: 'Domates fideleri'),
      Note(id: 'u', type: NoteType.text, title: 'Fatura ödemeleri'),
      Note(id: 'l', type: NoteType.text, title: 'Domates gizli', locked: true),
      Note(id: 'linked', type: NoteType.text, title: 'Sulama saati'),
    ];
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 dinlenmeyen sağlayıcıyı duraklatır: önce dinlenir.
    container.listen(notesStreamProvider, (_, _) {});
    await container.read(notesStreamProvider.future);
    container.listen(relatedNotesProvider('t'), (_, _) {});
    final related = await container.read(relatedNotesProvider('t').future);
    expect(related.map((n) => n.id), ['r']);
  });
}
