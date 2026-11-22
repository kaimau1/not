import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Kullanıcı bulgusu 2026-11-22: "Varsayılan" yazı tipine dönülemiyordu —
/// null tip `toMap`'ten düşüyor (S16 bayt bütçesi), `merge: true` yazımı
/// kayıttaki eski tipi koruyordu. Dönüş `clearFontFamily` ile açıkça yazılır.
void main() {
  test('varsayılana dönüş kayıttaki eski tipi siler', () async {
    final repo = NotesRepository(FakeFirebaseFirestore(), 'u1');
    final id = await repo.createNote(NoteType.text);
    await repo.updateFieldsAndWait(id, {'fontFamily': 'Lora'});
    var note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    expect(note.fontFamily, 'Lora');

    // Editörün kaydı: tip null → alan haritada yok, merge eskiyi korur.
    final reset = note.copyWith(clearFontFamily: true);
    expect(reset.toMap().containsKey('fontFamily'), isFalse);
    repo.clearFontFamily(id);
    note = (await repo
        .watchNote(id)
        .firstWhere((n) => n != null && n.fontFamily == null))!;
    expect(note.fontFamily, isNull);
  });
}
