import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı isteği 2026-10-20: klasör şeridinin başında "Tümü" — klasörde
/// olan olmayan bütün notlar, arşiv hariç.
void main() {
  final notes = [
    Note(
      id: 'serbest',
      type: NoteType.text,
      title: 'a',
      updatedAt: DateTime(2026, 10, 3),
    ),
    Note(
      id: 'klasorde',
      type: NoteType.text,
      title: 'b',
      folderId: 'f1',
      updatedAt: DateTime(2026, 10, 2),
    ),
    Note(
      id: 'arsivde',
      type: NoteType.text,
      title: 'c',
      archivedAt: DateTime(2026, 10),
      updatedAt: DateTime(2026, 10),
    ),
  ];

  Future<ProviderContainer> ready() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    for (final p in [notesStreamProvider, foldersStreamProvider]) {
      final sub = c.listen(p, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
    }
    await c.read(notesStreamProvider.future);
    await c.read(foldersStreamProvider.future);
    return c;
  }

  List<String> ids(ProviderContainer c) =>
      c.read(filteredNotesProvider).requireValue.map((n) => n.id).toList();

  test('varsayılan: klasördeki not ana ekranda durmaz', () async {
    final c = await ready();
    expect(ids(c), ['serbest']);
  });

  test('"Tümü": klasördekiler de görünür, arşiv yine görünmez', () async {
    final c = await ready();
    c.read(showAllNotesProvider.notifier).set(true);
    expect(ids(c), ['serbest', 'klasorde']);
    expect(c.read(allNotesCountProvider), 2);
  });
}
