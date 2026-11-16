import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';

/// Kullanıcı bulgusu 2026-11-16: "maddeli not numaralıya çevrildiğinde
/// işaretliler de numaralandırılıyor".
void main() {
  test('işaretli madde numara almaz, sonrakiler sayımı sürdürür', () {
    const items = [
      NoteItem(id: '1', text: 'a'),
      NoteItem(id: '2', text: 'b', checked: true),
      NoteItem(id: '3', text: 'c'),
      NoteItem(id: 'h', text: 'Bölüm', header: true),
      NoteItem(id: '4', text: 'd', checked: true),
      NoteItem(id: '5', text: 'e'),
    ];
    expect(
      [for (var i = 0; i < items.length; i++) itemOrderNumber(items, i)],
      [1, null, 2, null, null, 1],
    );
  });
}
