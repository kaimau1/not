import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/shared_note_activity.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Kullanıcı bulgusu 2026-11-05: "gelen klasöründe dosya olmasa da 1
/// görünüyor" — çip yetim aynayı da sayıyordu.
void main() {
  test('Gelen sayısı yalnız listede çizilen ortak notları sayar', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        currentUidProvider.overrideWithValue('ben'),
        sharedNotesWithMeProvider.overrideWith(
          (ref) => Stream.value(const [
            NoteShare(ownerId: 'o', noteId: 'canli'),
            NoteShare(ownerId: 'o', noteId: 'silinmis'),
            NoteShare(ownerId: 'o', noteId: 'cop'),
            NoteShare(ownerId: 'ben', noteId: 'kendi'),
          ]),
        ),
        ownedNoteStreamProvider.overrideWith(
          (ref, key) => Stream.value(switch (key.noteId) {
            'canli' => const Note(id: 'canli', type: NoteType.text),
            'cop' => Note(
              id: 'cop',
              type: NoteType.text,
              deletedAt: DateTime(2026),
            ),
            'kendi' => const Note(id: 'kendi', type: NoteType.text),
            _ => null,
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(sharedNotesVisibleCountProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(container.read(sharedNotesVisibleCountProvider), 1);
  });
}
