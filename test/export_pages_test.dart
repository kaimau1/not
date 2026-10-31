import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/pdf_export_screen.dart';

/// F10.2: PDF/Word dışa aktarma çok sayfalı notta yalnız ETKİN sayfayı
/// yazıyordu.
void main() {
  String label(int n) => 'Sayfa $n';

  test('bütün sayfalar sırayla, boş sayfa atlanır', () {
    const note = Note(
      id: 'p',
      type: NoteType.checklist,
      body: 'Etkin',
      activePage: 'b',
      textPages: [
        NoteTextPage(
          id: '',
          items: [NoteItem(id: '1', text: 'Süt')],
        ),
        NoteTextPage(id: 'b'),
        NoteTextPage(id: 'c'),
      ],
    );
    expect(
      exportContentOf(note, pageLabel: label),
      'Sayfa 1\n[ ] Süt\n\nSayfa 2\nEtkin',
    );
  });

  test('tek sayfada başlık yok', () {
    const note = Note(id: 't', type: NoteType.text, body: 'Yalnız');
    expect(exportContentOf(note, pageLabel: label), 'Yalnız');
  });
}
