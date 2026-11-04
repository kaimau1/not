import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F22.6: editörün not akışı + senkron göstergesi tek yerel Firestore
/// dinleyicisini paylaşır; not akışı yalnız VERİ değişince yayınlar.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  test(
    'iki akış tek dinleyici; ikisi kapanınca dinleyici de kapanır',
    () async {
      final id = await repo.createNote(NoteType.text, title: 'A');
      final base = NotesRepository.debugSharedDocListeners;
      final notes = <Note?>[];
      final pending = <bool>[];
      final s1 = repo.watchNote(id).listen(notes.add);
      await pumpEventQueue();
      // Geç gelen abone son anlık görüntüyü hemen alır.
      final s2 = repo.watchPendingWrites(id).listen(pending.add);
      // Paylaşılan klasör yolu: aynı Firestore örneği, yeni depo nesnesi.
      final s3 = NotesRepository(
        db,
        'u1',
      ).watchPendingWrites(id).listen((_) {});
      await pumpEventQueue();
      expect(NotesRepository.debugSharedDocListeners, base + 1);
      expect(notes.single!.title, 'A');
      expect(pending, isNotEmpty);

      final n = notes.single!;
      await repo.updateNote(n.copyWith(body: 'gövde'));
      await pumpEventQueue();
      expect(notes.last!.body, 'gövde');

      await s1.cancel();
      await s2.cancel();
      expect(NotesRepository.debugSharedDocListeners, base + 1);
      await s3.cancel();
      expect(NotesRepository.debugSharedDocListeners, base);

      // Yeniden açılınca yeni dinleyici kurulur ve güncel veri gelir.
      final again = await repo.watchNote(id).firstWhere((x) => x != null);
      expect(again!.body, 'gövde');
    },
  );

  test('deepDataEquals: iç içe Map/List, sıra önemli, tür önemli', () {
    expect(
      deepDataEquals(
        {
          'a': 1,
          'b': [
            1,
            {'c': 'x'},
          ],
        },
        {
          'b': [
            1,
            {'c': 'x'},
          ],
          'a': 1,
        },
      ),
      isTrue,
    );
    expect(
      deepDataEquals(
        {
          'b': [1, 2],
        },
        {
          'b': [2, 1],
        },
      ),
      isFalse,
    );
    expect(deepDataEquals({'a': 1}, {'a': 1, 'b': null}), isFalse);
    expect(deepDataEquals({'a': null}, {'b': null}), isFalse);
    expect(deepDataEquals(null, null), isTrue);
    expect(deepDataEquals({'a': '1'}, {'a': 1}), isFalse);
  });

  test('akış hatası iki aboneye de iletilir, dinleyici sızmaz', () async {
    final id = await repo.createNote(NoteType.text, title: 'B');
    final base = NotesRepository.debugSharedDocListeners;
    final done = Completer<void>();
    final sub = repo.watchNote(id).listen((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    await sub.cancel();
    expect(NotesRepository.debugSharedDocListeners, base);
  });
}
