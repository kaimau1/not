import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/text_merge.dart';

void main() {
  group('üç yönlü paragraf birleştirme (F4.1)', () {
    const base = 'Giriş\nOrta\nSon';

    test('farklı paragraflardaki değişikliklerin ikisi de korunur', () {
      final m = mergeText3(base, 'Giriş!\nOrta\nSon', 'Giriş\nOrta\nSon.');
      expect(m.text, 'Giriş!\nOrta\nSon.');
      expect(m.conflict, isFalse);
    });

    test('iki taraf da farklı yere satır ekler', () {
      final m = mergeText3(
        base,
        'Giriş\nYerel ek\nOrta\nSon',
        'Giriş\nOrta\nSon\nUzak ek',
      );
      expect(m.text, 'Giriş\nYerel ek\nOrta\nSon\nUzak ek');
    });

    test('silme bir tarafta, düzenleme başka yerde', () {
      final m = mergeText3('A\nB\nC\nD', 'A\nC\nD', 'A\nB\nC\nD!');
      expect(m.text, 'A\nC\nD!');
      expect(m.conflict, isFalse);
    });

    test('aynı paragraf farklı değişirse ikisi de tutulur', () {
      final m = mergeText3(
        base,
        'Giriş\nOrta (ben)\nSon',
        'Giriş\nOrta (o)\nSon',
      );
      expect(m.text, 'Giriş\nOrta (ben)\nOrta (o)\nSon');
      expect(m.conflict, isTrue);
    });

    test('kısa yollar: bir taraf değişmediyse öbürü', () {
      expect(mergeText3(base, base, 'x').text, 'x');
      expect(mergeText3(base, 'y', base).text, 'y');
      expect(mergeText3(base, 'z', 'z').text, 'z');
    });
  });

  group('madde birleştirme', () {
    NoteItem item(String id, String text, {bool checked = false}) =>
        NoteItem(id: id, text: text, checked: checked);

    test(
      'uzakta eklenen gelir, işaretlenen uygulanır, yerel düzenleme kalır',
      () {
        final base = [item('a', 'süt'), item('b', 'ekmek')];
        final local = [item('a', 'süt 2 lt'), item('b', 'ekmek')];
        final remote = [
          item('a', 'süt'),
          item('b', 'ekmek', checked: true),
          item('c', 'yumurta'),
        ];
        final merged = mergeItems3(base, local, remote);
        expect(merged.map((i) => i.text), ['süt 2 lt', 'ekmek', 'yumurta']);
        expect(merged[1].checked, isTrue);
      },
    );

    test('uzakta silinen madde yerelde dokunulmadıysa silinir', () {
      final base = [item('a', 'x'), item('b', 'y')];
      final merged = mergeItems3(base, base, [item('a', 'x')]);
      expect(merged.map((i) => i.id), ['a']);
    });
  });
}
