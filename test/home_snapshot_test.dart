import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/home_snapshot.dart';

Note _note(
  String id, {
  String body = '',
  List<NoteItem> items = const [],
  bool locked = false,
  List<Attachment> attachments = const [],
}) => Note(
  id: id,
  type: NoteType.text,
  title: 'Başlık $id',
  body: body,
  items: items,
  locked: locked,
  attachments: attachments,
  pinned: id == 'a',
  updatedAt: DateTime(2026, 11, 4, 12),
);

/// F25.2: kart için kısaltılmış özet — gidiş-dönüş, uid ayrımı, gizlilik.
void main() {
  test('gidiş-dönüş: sıra, kart alanları, tarih korunur; gövde kısalır', () {
    final raw = encodeHomeSnapshot('u', [
      _note('a', body: 'x' * 5000),
      _note(
        'b',
        items: [
          for (var i = 0; i < 20; i++)
            NoteItem(id: '$i', text: 'madde $i', checked: i == 0),
        ],
      ),
    ]);
    final back = decodeHomeSnapshot('u', raw);
    expect(back.map((n) => n.id), ['a', 'b']);
    expect(back[0].pinned, isTrue);
    expect(back[0].title, 'Başlık a');
    expect(back[0].body.length, lessThan(400));
    expect(back[0].updatedAt, DateTime(2026, 11, 4, 12));
    expect(back[1].items, hasLength(20));
    expect(back[1].items.first.checked, isTrue);
    expect(back[1].items[3].text, 'madde 3');
    expect(back[1].items[15].text, '·');
    expect(raw.length, lessThan(6000));
  });

  test('en çok kHomeSnapshotNotes not', () {
    final raw = encodeHomeSnapshot('u', [
      for (var i = 0; i < 90; i++) _note('$i'),
    ]);
    expect(decodeHomeSnapshot('u', raw), hasLength(kHomeSnapshotNotes));
  });

  test('sabit notlar eski olsa da özete girer', () {
    final raw = encodeHomeSnapshot('u', [
      for (var i = 0; i < 40; i++) _note('$i'),
      _note('a'),
    ]);
    final ids = decodeHomeSnapshot('u', raw).map((n) => n.id);
    expect(ids.first, 'a');
    expect(ids, hasLength(kHomeSnapshotNotes));
  });

  test('başka hesap ve bozuk özet boş döner', () {
    final raw = encodeHomeSnapshot('u', [_note('a')]);
    expect(decodeHomeSnapshot('v', raw), isEmpty);
    expect(decodeHomeSnapshot('u', 'bozuk{'), isEmpty);
  });

  test('kilitli ve parola notunun içeriği diske yazılmaz', () {
    final raw = encodeHomeSnapshot('u', [
      _note('k', body: 'gizlimetin', locked: true),
      _note('p', body: 'şifre: benimparolam'),
    ]);
    expect(raw, isNot(contains('gizlimetin')));
    expect(raw, isNot(contains('benimparolam')));
  });

  test('çizim özette yok, ek kimliği var', () {
    final raw = encodeHomeSnapshot('u', [
      _note(
        'a',
        attachments: [
          Attachment(
            id: 'g1',
            kind: AttachmentKind.image,
            fileName: 'a.png',
            mimeType: 'image/png',
            sizeBytes: 3,
            bubbles: const [PageBubble(id: 'b', page: 0, x: 0, y: 0)],
          ),
        ],
      ),
    ]);
    final a = decodeHomeSnapshot('u', raw).single.attachments.single;
    expect(a.id, 'g1');
    expect(a.bubbles, isEmpty);
  });
}
