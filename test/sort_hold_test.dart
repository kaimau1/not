import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F26.3 (AKICILIK_PLANI, K9): editörü açık not otomatik kayıtta listede
/// tepeye zıplamaz; tutma bırakılınca bir kez yerine oturur.
void main() {
  Note n(String id, int day) => Note(
    id: id,
    type: NoteType.text,
    title: id,
    updatedAt: DateTime(2026, 8, day),
  );

  late StreamController<List<Note>> stream;

  Future<ProviderContainer> ready(List<Note> first) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    stream = StreamController<List<Note>>.broadcast();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) async* {
          yield first;
          yield* stream.stream;
        }),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    for (final p in [notesStreamProvider, foldersStreamProvider]) {
      final sub = c.listen(p, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
    }
    final sub = c.listen(filteredNotesProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(notesStreamProvider.future);
    await c.read(foldersStreamProvider.future);
    return c;
  }

  List<String> ids(ProviderContainer c) =>
      c.read(filteredNotesProvider).requireValue.map((n) => n.id).toList();

  Future<void> emit(List<Note> notes) async {
    stream.add(notes);
    await pumpEventQueue();
  }

  for (final sort in [NoteSort.updated, NoteSort.manual]) {
    test('$sort: açık not kayıtta yerinde, bırakınca tepeye', () async {
      // Elle sıralamada akış depo sırasıyla gelir (yeni → eski).
      final c = await ready([n('a', 3), n('b', 2), n('c', 1)]);
      c.read(noteSortProvider.notifier).set(sort);
      expect(ids(c), ['a', 'b', 'c']);

      c.read(sortHeldNoteIdsProvider.notifier).hold('c');
      expect(ids(c), ['a', 'b', 'c']);
      // Otomatik kayıt: c tazelendi (depo onu tepeye koyar).
      await emit([n('c', 9), n('a', 3), n('b', 2)]);
      expect(ids(c), ['a', 'b', 'c']);
      expect(
        c.read(filteredNotesProvider).requireValue.last.updatedAt,
        DateTime(2026, 8, 9),
        reason: 'kart içeriği güncel, yalnız yeri sabit',
      );

      c.read(sortHeldNoteIdsProvider.notifier).release('c');
      expect(ids(c), ['c', 'a', 'b']);
    });
  }

  test('yeniden tutulunca güncel zaman çapa olur', () async {
    final c = await ready([n('a', 3), n('b', 2)]);
    c.read(noteSortProvider.notifier).set(NoteSort.updated);
    c.read(sortHeldNoteIdsProvider.notifier).hold('b');
    expect(ids(c), ['a', 'b']);
    c.read(sortHeldNoteIdsProvider.notifier).release('b');
    await emit([n('b', 9), n('a', 3)]);
    expect(ids(c), ['b', 'a']);
    // Kapanıştan vazgeçildi → yeniden tutuldu: yerinde (tepede) kalır.
    c.read(sortHeldNoteIdsProvider.notifier).hold('b');
    await emit([n('b', 10), n('a', 3)]);
    expect(ids(c), ['b', 'a']);
  });
}
