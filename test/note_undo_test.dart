import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_undo.dart';

Note _note({
  String body = '',
  List<NoteItem> items = const [],
  List<Attachment> attachments = const [],
}) => Note(
  id: 'n1',
  type: NoteType.text,
  body: body,
  items: items,
  attachments: attachments,
);

Attachment _image({double? displayWidth, double? pageY, bool asFile = false}) =>
    Attachment(
      id: 'a1',
      kind: AttachmentKind.image,
      fileName: 'a.jpg',
      mimeType: 'image/jpeg',
      displayWidth: displayWidth,
      pageY: pageY,
      asFile: asFile,
    );

void main() {
  final t0 = DateTime(2026, 8, 1, 9);

  test('art arda yazma TEK geri alma adimi olur', () {
    final stack = NoteUndoStack();
    var previous = _note();
    for (var i = 1; i <= 5; i++) {
      final next = _note(body: 'a' * i);
      stack.push(previous, next, now: t0.add(Duration(milliseconds: 120 * i)));
      previous = next;
    }
    expect(stack.length, 1, reason: 'her tus vurusu ayri adim oldu');
    expect(stack.pop()!.body, '');
  });

  test('yazma duraksayinca yeni adim acilir', () {
    final stack = NoteUndoStack();
    stack.push(_note(), _note(body: 'a'), now: t0);
    stack.push(
      _note(body: 'a'),
      _note(body: 'ab'),
      now: t0.add(const Duration(seconds: 5)),
    );
    expect(stack.length, 2);
    expect(stack.pop()!.body, 'a');
    expect(stack.pop()!.body, '');
  });

  test('yapi degisikligi zaman penceresine bakmadan adim acar', () {
    final stack = NoteUndoStack();
    final before = _note(items: const [NoteItem(id: 'i1', text: 'Sut')]);
    stack.push(before, _note(body: 'x', items: before.items), now: t0);
    // Ayni pencere icinde ama bu kez madde ISARETLENDI: ayri adim.
    stack.push(
      before,
      _note(items: const [NoteItem(id: 'i1', text: 'Sut', checked: true)]),
      now: t0.add(const Duration(milliseconds: 100)),
    );
    expect(stack.length, 2);
  });

  test('gorselin tasinmasi/boyutlanmasi ayri adimdir', () {
    final stack = NoteUndoStack();
    final before = _note(attachments: [_image(displayWidth: 0.3, pageY: 100)]);
    final after = _note(attachments: [_image(displayWidth: 0.6, pageY: 240)]);
    stack.push(before, after, now: t0);
    stack.push(after, after, now: t0.add(const Duration(milliseconds: 50)));
    expect(stack.length, 1);
    expect(stack.pop()!.attachments.single.displayWidth, 0.3);
  });

  test('tavan asilinca en eski adim duser', () {
    final stack = NoteUndoStack(limit: 3);
    for (var i = 0; i < 6; i++) {
      stack.push(
        _note(body: '$i'),
        _note(body: '${i + 1}'),
        now: t0.add(Duration(seconds: i * 5)),
      );
    }
    expect(stack.length, 3);
    expect(stack.pop()!.body, '5');
  });

  test('geri almadan sonraki yazma birlestirilmez', () {
    final stack = NoteUndoStack();
    stack.push(_note(), _note(body: 'a'), now: t0);
    expect(stack.pop()!.body, '');
    stack.push(
      _note(body: 'a'),
      _note(body: 'ab'),
      now: t0.add(const Duration(milliseconds: 10)),
    );
    expect(stack.length, 1, reason: 'geri almadan sonra yeni adim acilmadi');
  });

  test('isaretleme + ardindan gelen tasima TEK adimdir', () {
    // Isaretlenen oge once yerinde degisir, animasyon bitince (220 ms) listenin
    // sonuna tasinir. Iki ayri adim olsaydi ilk "Geri al" ogeyi isaretli halde
    // eski yerine koyup birakirdi.
    final stack = NoteUndoStack();
    const before = [
      NoteItem(id: 'a', text: 'Sut'),
      NoteItem(id: 'b', text: 'Ekmek'),
    ];
    const checked = [
      NoteItem(id: 'a', text: 'Sut', checked: true),
      NoteItem(id: 'b', text: 'Ekmek'),
    ];
    const moved = [
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'a', text: 'Sut', checked: true),
    ];
    stack.push(_note(items: before), _note(items: checked), now: t0);
    stack.push(
      _note(items: checked),
      _note(items: moved),
      now: t0.add(const Duration(milliseconds: 220)),
    );

    expect(stack.length, 1);
    expect(stack.pop()!.items.first.checked, isFalse);
  });

  test('bos yiginda pop null doner', () {
    expect(NoteUndoStack().pop(), isNull);
    expect(NoteUndoStack().canUndo, isFalse);
  });
}
