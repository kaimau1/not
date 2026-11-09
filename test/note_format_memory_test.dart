import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_format_memory.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F56.3: son kullanılan gövde yazı boyutu/tipi yeni notlara geçer.
void main() {
  tearDown(NoteFormatMemory.resetForTest);

  test('hafıza saklanır, yeniden yüklenir; varsayılan silinir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    NoteFormatMemory.attach(prefs);
    expect(NoteFormatMemory.fontScale, 1);
    expect(NoteFormatMemory.fontFamily, isNull);

    NoteFormatMemory.rememberScale(1.3);
    NoteFormatMemory.rememberFamily('Lora');
    NoteFormatMemory.resetForTest();
    NoteFormatMemory.attach(prefs);
    expect(NoteFormatMemory.fontScale, 1.3);
    expect(NoteFormatMemory.fontFamily, 'Lora');

    NoteFormatMemory.rememberScale(1);
    NoteFormatMemory.rememberFamily(null);
    expect(prefs.getKeys(), isEmpty);
  });

  test('saçma değer yok sayılır', () async {
    SharedPreferences.setMockInitialValues({'note_last_font_scale': 40.0});
    NoteFormatMemory.attach(await SharedPreferences.getInstance());
    expect(NoteFormatMemory.fontScale, 1);
    NoteFormatMemory.rememberScale(0);
    expect(NoteFormatMemory.fontScale, 1);
  });

  test('yeni not son boyut ve tiple doğar', () async {
    SharedPreferences.setMockInitialValues({});
    NoteFormatMemory.attach(await SharedPreferences.getInstance());
    NoteFormatMemory.rememberScale(1.2);
    NoteFormatMemory.rememberFamily('Lora');
    final repo = NotesRepository(FakeFirebaseFirestore(), 'u1');
    final id = await repo.createNote(NoteType.text);
    final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    expect(note.fontScale, 1.2);
    expect(note.fontFamily, 'Lora');
  });
}
