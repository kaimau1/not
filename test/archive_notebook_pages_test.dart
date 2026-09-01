import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_note_screen.dart';

/// **DEFTERİN SAYFALARI** (yeniden tasarım, kullanıcı isteği 2026-09-01:
/// "kişiye özel bir defter olsun, her sayfasında notlar resimler ekler
/// olacak, sayfaları çevirecek kişi").
///
/// Eski ekran içeriği TÜRÜNE göre dört otomatik sekmeye bölüyordu (Görseller /
/// Videolar / Belgeler / Metinler); bir konuya ait fotoğraf, PDF ve not asla
/// yan yana gelemiyordu. Yeni model sayfayı KONU birimi yapar: aynı sayfada
/// metin de dosya da durur.
Note _notebook({
  List<String> pages = const [],
  List<NoteItem> items = const [],
  List<Attachment> attachments = const [],
}) => Note(
  id: 'n1',
  type: NoteType.archive,
  archivePages: pages,
  items: items,
  attachments: attachments,
);

Attachment _file(String id, {String section = ''}) => Attachment(
  id: id,
  kind: AttachmentKind.image,
  fileName: '$id.jpg',
  mimeType: 'image/jpeg',
  section: section,
);

void main() {
  test('ilk sayfa her zaman Genel (adı kayda yazılmaz)', () {
    final names = archivePageNames(_notebook(pages: ['Faturalar']));
    expect(names, ['', 'Faturalar']);
  });

  test('bir sayfada metin ve dosya BİRLİKTE durur', () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [NoteItem(id: 'i1', text: 'uçuş saati', section: 'Seyahat')],
      attachments: [_file('bilet', section: 'Seyahat')],
    );
    final entries = archiveEntriesOf(note, 'Seyahat');
    expect(entries.length, 2);
    expect(entries.first.text?.id, 'i1');
    expect(entries.last.file?.id, 'bilet');
  });

  test('bölümsüz girdiler Genel sayfasında (eski defterler olduğu gibi açılır)',
      () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [NoteItem(id: 'i1', text: 'eski not')],
      attachments: [_file('eski')],
    );
    final general = archiveEntriesOf(note, '');
    expect(general.length, 2);
    expect(archiveEntriesOf(note, 'Seyahat'), isEmpty);
  });

  test('ÖKSÜZ bölüm Genel\'e düşer — girdi hiçbir sayfada kaybolmaz', () {
    // Sayfa başka bir cihazdan silinmiş; girdinin üstündeki ad duruyor.
    final note = _notebook(
      pages: ['Duran'],
      items: const [NoteItem(id: 'i1', text: 'öksüz', section: 'Silinmiş')],
      attachments: [_file('öksüz', section: 'Silinmiş')],
    );
    final general = archiveEntriesOf(note, '');
    expect(general.length, 2);
    expect(archiveEntriesOf(note, 'Duran'), isEmpty);
  });

  test('sayfa süzgeci yalnız KENDİ sayfasını döndürür', () {
    final note = _notebook(
      pages: ['A', 'B'],
      items: const [
        NoteItem(id: 'a', text: 'a', section: 'A'),
        NoteItem(id: 'b', text: 'b', section: 'B'),
      ],
    );
    expect(
      archiveEntriesOf(note, 'A').map((e) => e.text?.id),
      ['a'],
    );
    expect(
      archiveEntriesOf(note, 'B').map((e) => e.text?.id),
      ['b'],
    );
  });
}
