import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gizli klasör: klasörün notları ana ekranda (arama dahil) görünmez ve
/// etiketleri çip barına sızmaz. ⋮ → "Gizli klasörler" kimlik doğrulamasıyla
/// o oturum boyunca açılır — bu durumda notlar yeniden listeye girer.
void main() {
  const folders = [
    NoteFolder(id: 'gizli', name: 'Kişisel', hidden: true),
    NoteFolder(id: 'acik', name: 'İş'),
  ];
  const notes = [
    Note(
      id: 'n-gizli',
      type: NoteType.text,
      title: 'Banka şifreleri',
      body: 'gizli içerik',
      folderId: 'gizli',
      tags: ['finans'],
    ),
    Note(
      id: 'n-acik',
      type: NoteType.text,
      title: 'Toplantı',
      body: 'gündem',
      folderId: 'acik',
      tags: ['iş'],
    ),
    Note(id: 'n-klasorsuz', type: NoteType.text, title: 'Serbest not'),
  ];

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        foldersStreamProvider.overrideWith((ref) => Stream.value(folders)),
      ],
    );
  }

  /// Akışların ilk değerini bekle. Dinleyici şart: dinlenmeyen bir
  /// StreamProvider yükleme durumunda kalır ve `.future` hiç tamamlanmaz.
  Future<ProviderContainer> ready() async {
    final c = await makeContainer();
    addTearDown(c.dispose);
    for (final p in [notesStreamProvider, foldersStreamProvider]) {
      final sub = c.listen(p, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
    }
    await c.read(notesStreamProvider.future);
    await c.read(foldersStreamProvider.future);
    return c;
  }

  test('gizli klasörün notu listeye girmez', () async {
    final c = await ready();
    final ids = c
        .read(filteredNotesProvider)
        .requireValue
        .map((n) => n.id)
        .toList();
    expect(ids, ['n-acik', 'n-klasorsuz']);
  });

  test('gizli klasörün notu ARAMAYLA da bulunmaz', () async {
    final c = await ready();
    c.read(searchQueryProvider.notifier).set('şifre');
    expect(c.read(filteredNotesProvider).requireValue, isEmpty);
  });

  test('gizli klasörün etiketi Süz levhasına sızmaz', () async {
    final c = await ready();
    expect(c.read(allTagsProvider), ['iş']);
  });

  test('gizlilik açılınca notlar geri gelir', () async {
    final c = await ready();
    c.read(hiddenFoldersRevealedProvider.notifier).set(true);

    final ids = c
        .read(filteredNotesProvider)
        .requireValue
        .map((n) => n.id)
        .toList();
    expect(ids, ['n-gizli', 'n-acik', 'n-klasorsuz']);
    expect(c.read(allTagsProvider), ['finans', 'iş']);
  });

  test('gizli klasör kimlikleri klasör akışından türetilir', () async {
    final c = await ready();
    expect(c.read(hiddenFolderIdsProvider), {'gizli'});
  });
}
