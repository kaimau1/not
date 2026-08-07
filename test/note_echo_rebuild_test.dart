import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

/// KÖK NEDEN (kasma — kullanıcı: "yeni öğe eklemesem bile kasma devam
/// ediyor"): Firestore'un gecikme telafisi editörün KENDİ kaydını da anında
/// bir anlık görüntü olarak geri gönderiyor. Akış dinleyicisi bunu koşulsuz
/// `setState` ile karşılıyordu, yani yazarken (debounce 0,5 sn / en geç 3 sn)
/// düzenli aralıklarla 4000 satırlık editör build'i — sayfa tuvali, sarma
/// ölçümü, bütün madde satırları — boşuna koşuyordu.
///
/// [sameRenderedNote] o yankıyı tanır: metnin KENDİSİ dışarıdadır (onu
/// alanların denetleyicileri çiziyor), ama çizimi etkileyen her alan içeridir.
void main() {
  const base = Note(
    id: '1',
    type: NoteType.checklist,
    title: 'Alışveriş',
    body: 'not',
    items: [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek', checked: true),
    ],
  );

  test('aynı içerik → yeniden çizim YOK', () {
    expect(sameRenderedNote(base, base.copyWith()), isTrue);
  });

  test('madde METNİ değişti → yeniden çizim YOK (alan kendi çiziyor)', () {
    final typed = base.copyWith(
      items: [
        const NoteItem(id: 'a', text: 'Süt 2 lt'),
        const NoteItem(id: 'b', text: 'Ekmek', checked: true),
      ],
    );
    expect(sameRenderedNote(base, typed), isTrue);
  });

  test('işaret / sıra / madde sayısı değişti → yeniden çizim ŞART', () {
    expect(
      sameRenderedNote(
        base,
        base.copyWith(
          items: [
            const NoteItem(id: 'a', text: 'Süt', checked: true),
            const NoteItem(id: 'b', text: 'Ekmek', checked: true),
          ],
        ),
      ),
      isFalse,
    );
    expect(
      sameRenderedNote(
        base,
        base.copyWith(
          items: [
            ...base.items,
            const NoteItem(id: 'c', text: ''),
          ],
        ),
      ),
      isFalse,
    );
  });

  test('gövde DOLULUĞU değişti → yeniden çizim ŞART (tuval ipucu)', () {
    expect(sameRenderedNote(base, base.copyWith(body: 'başka')), isTrue);
    expect(sameRenderedNote(base, base.copyWith(body: '   ')), isFalse);
  });

  test('başka cihazdan gelen meta değişikliği → yeniden çizim ŞART', () {
    expect(sameRenderedNote(base, base.copyWith(pinned: true)), isFalse);
    expect(
      sameRenderedNote(base, base.copyWith(color: NoteColor.red)),
      isFalse,
    );
    expect(sameRenderedNote(base, base.copyWith(title: 'Yeni')), isFalse);
    expect(sameRenderedNote(base, base.copyWith(tags: ['ev'])), isFalse);
    expect(sameRenderedNote(base, base.copyWith(fontScale: 1.2)), isFalse);
    expect(
      sameRenderedNote(base, base.copyWith(reminderAt: DateTime(2026, 8, 8))),
      isFalse,
    );
  });
}
