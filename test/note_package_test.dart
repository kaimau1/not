import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_package.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Not paketi: notu BASKA BIR NOT KULLANICISINA gonderme bicimi. Kilitlenen
/// sey su: paket gidip geldiginde not "her seyiyle" ayni kalmali — ekler,
/// sayfa notlari, cizimler ve PDF uzerindeki BALONLAR dahil.
void main() {
  Note buildNote() => Note(
    id: 'yerel-kimlik',
    type: NoteType.pdf,
    title: 'Toplanti',
    body: 'govde',
    items: const [NoteItem(id: 'i1', text: 'madde', checked: true)],
    pageNotes: const {'ek1#p2': 'ikinci sayfanin notu'},
    attachments: [
      Attachment(
        id: 'ek1',
        kind: AttachmentKind.pdf,
        fileName: 'rapor.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 3,
        // Gonderenin hesabina ait alanlar: pakete GIRMEMELI.
        storagePath: 'users/gonderen/notes/n1/ek1_rapor.pdf',
        downloadUrl: 'https://ornek/indir',
        localPath: '/veri/gonderen/ek1.pdf',
        ink: const [
          InkStroke(page: 1, color: 0xFF112233, width: 0.01, points: [0.1, 0.2]),
        ],
        bubbles: const [
          PageBubble(
            id: 'b1',
            page: 2,
            x: 0.25,
            y: 0.75,
            text: 'burayi duzelt',
            color: 0xFFEF5350,
            collapsed: true,
          ),
        ],
        pageIds: const ['p1', 'p2'],
      ),
    ],
    tags: const ['is'],
    color: NoteColor.values.last,
    fontScale: 1.4,
  );

  test('gidis-donus notun icerigini ve gorunumunu korur', () {
    final source = buildNote();
    final package = readNotePackage(
      buildNotePackage(source, {'ek1': Uint8List.fromList([1, 2, 3])}),
    );
    final note = package.note;

    expect(note.type, NoteType.pdf);
    expect(note.title, 'Toplanti');
    expect(note.body, 'govde');
    expect(note.items.single.checked, isTrue);
    expect(note.pageNotes['ek1#p2'], 'ikinci sayfanin notu');
    expect(note.tags, ['is']);
    expect(note.color, source.color);
    expect(note.fontScale, 1.4);
    // Kimlik TASINMAZ: alici notu kendi deposunda olusturur.
    expect(note.id, isEmpty);
  });

  test('PDF uzerindeki balonlar pakete girer ve aynen doner', () {
    final package = readNotePackage(
      buildNotePackage(buildNote(), const {}),
    );
    final bubble = package.note.attachments.single.bubbles.single;
    expect(bubble.id, 'b1');
    expect(bubble.page, 2);
    expect(bubble.x, 0.25);
    expect(bubble.y, 0.75);
    expect(bubble.text, 'burayi duzelt');
    expect(bubble.color, 0xFFEF5350);
    expect(bubble.collapsed, isTrue);
  });

  test('cizimler ve sayfa kimlikleri de tasinir', () {
    final attachment = readNotePackage(
      buildNotePackage(buildNote(), const {}),
    ).note.attachments.single;
    expect(attachment.ink.single.color, 0xFF112233);
    expect(attachment.ink.single.points, [
      closeTo(0.1, 1e-7),
      closeTo(0.2, 1e-7),
    ]);
    // Sayfa notlarinin anahtari ek KIMLIGINE bagli: kimlik korunmazsa
    // paketten gelen notun sayfa notlari kaybolur.
    expect(attachment.id, 'ek1');
    expect(attachment.pageIds, ['p1', 'p2']);
  });

  test('gonderenin depo/cihaz alanlari pakete YAZILMAZ', () {
    final json = encodeNoteJson(buildNote());
    final raw = json['attachments'] as List;
    final map = raw.single as Map<String, dynamic>;
    expect(map.containsKey('storagePath'), isFalse);
    expect(map.containsKey('downloadUrl'), isFalse);
    expect(map.containsKey('localPath'), isFalse);
  });

  test('ek baytlari kimligine gore paketten cikar', () {
    final bytes = Uint8List.fromList([9, 8, 7]);
    final package = readNotePackage(
      buildNotePackage(buildNote(), {'ek1': bytes}),
    );
    expect(package.files['ek1'], bytes);
  });

  test('zip olmayan dosya FormatException verir', () {
    expect(
      () => readNotePackage(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<FormatException>()),
    );
  });

  test('gelecekteki bir bicim surumu reddedilir', () {
    expect(
      () => decodeNoteJson({'v': NotePackage.formatVersion + 1}),
      throwsA(isA<FormatException>()),
    );
  });

  test('dosya adi baslikliktan turer, yasak karakterler ayiklanir', () {
    final note = Note(id: 'x', type: NoteType.text, title: 'a/b:c*d');
    expect(notePackageFileName(note, fallback: 'Not'), 'a b c d.notpaket');
  });

  test('baslik yoksa yedek ad kullanilir', () {
    final note = Note(id: 'x', type: NoteType.text);
    expect(notePackageFileName(note, fallback: 'Not'), 'Not.notpaket');
  });
}
