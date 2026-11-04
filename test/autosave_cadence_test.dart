import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/core/utils/debouncer.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

/// F22.2 / F22.3 (AKICILIK_PLANI): otomatik kayıt seyrek ve istemci saatli.
void main() {
  testWidgets('F22.2: editör kaydı ~2 sn boşlukta, aralıksız yazımda en geç '
      '10 sn', (tester) async {
    expect(kEditorSaveDelay, const Duration(seconds: 2));
    expect(kEditorSaveMaxWait, const Duration(seconds: 10));
    {
      final d = Debouncer(delay: kEditorSaveDelay, maxWait: kEditorSaveMaxWait);
      var saves = 0;
      // Saniyede 2 tuş, 12 sn aralıksız: sessizlik hiç 2 sn'yi bulmuyor.
      for (var i = 0; i < 24; i++) {
        d(() => saves++);
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(saves, 1, reason: '10. saniyede tek kayıt (üst sınır)');
      await tester.pump(const Duration(seconds: 2));
      expect(saves, 2, reason: 'yazım bitince 2 sn sonra son kayıt');
      d(() => saves++);
      d.flush();
      expect(saves, 3, reason: 'çıkış kapısında beklemeden');
    }
  });

  test(
    'F22.3: istemci saatli kayıt updatedAt yazar, sonra sunucu damgası',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = NotesRepository(db, 'u1');
      final id = await repo.createNote(NoteType.text, title: 'a');
      final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
      final before = DateTime.now();
      await repo.updateNote(note.copyWith(body: 'b'), clientTime: true);
      final snap = await db
          .collection(AppConstants.usersCollection)
          .doc('u1')
          .collection(AppConstants.notesCollection)
          .doc(id)
          .get();
      expect(snap.data()!['body'], 'b');
      final at = (snap.data()!['updatedAt'] as dynamic).toDate() as DateTime;
      expect(at.isBefore(before.subtract(const Duration(seconds: 5))), isFalse);
      await repo.updateFieldsAndWait(id, const {});
      final again = await db
          .collection(AppConstants.usersCollection)
          .doc('u1')
          .collection(AppConstants.notesCollection)
          .doc(id)
          .get();
      expect(again.data()!['updatedAt'], isNotNull);
    },
  );
}
