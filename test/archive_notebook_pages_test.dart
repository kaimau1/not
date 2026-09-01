import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
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

  test(
    'bölümsüz girdiler Genel sayfasında (eski defterler olduğu gibi açılır)',
    () {
      final note = _notebook(
        pages: ['Seyahat'],
        items: const [NoteItem(id: 'i1', text: 'eski not')],
        attachments: [_file('eski')],
      );
      final general = archiveEntriesOf(note, '');
      expect(general.length, 2);
      expect(archiveEntriesOf(note, 'Seyahat'), isEmpty);
    },
  );

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
    expect(archiveEntriesOf(note, 'A').map((e) => e.text?.id), ['a']);
    expect(archiveEntriesOf(note, 'B').map((e) => e.text?.id), ['b']);
  });

  // ————————————————————————————————— SAYFAYA DOĞRUDAN YAZMA
  //
  // Kullanıcı bulgusu 2026-09-01 (ekran görüntüsüyle): "metin yazamıyorum,
  // yazmak için bu alan açılıyor — direk sayfaya yazılabilmeli." Sayfanın
  // serbest yazısı kayıtta AYRI bir alan değil, sayfanın ilk sade metin
  // girdisi (bkz. archivePageText): eski defterler göç etmeden açılsın.

  test('sayfanın serbest yazısı ilk SADE metin girdisidir', () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [
        NoteItem(id: 'i1', text: 'uçuş saati 09:40', section: 'Seyahat'),
        NoteItem(id: 'i2', text: 'başka bir şey', section: 'Seyahat'),
      ],
    );
    expect(archivePageText(note, 'Seyahat')?.id, 'i1');
  });

  test('BAŞLIKLI ya da dosyaya bağlı girdi sayfanın yazısı SAYILMAZ', () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [
        NoteItem(
          id: 'baslikli',
          text: 'alıntı',
          title: 'Bilet',
          section: 'Seyahat',
        ),
        NoteItem(
          id: 'bagli',
          text: 'not',
          attachmentId: 'a1',
          section: 'Seyahat',
        ),
        NoteItem(id: 'yazi', text: 'sayfanın yazısı', section: 'Seyahat'),
      ],
    );
    // Blokların ikisi de listede ÖNCE geliyor ama yazı olan üçüncüsü.
    expect(archivePageText(note, 'Seyahat')?.id, 'yazi');
  });

  test('yazısı olmayan sayfada null döner (ilk harfte girdi oluşur)', () {
    final note = _notebook(pages: ['Boş']);
    expect(archivePageText(note, 'Boş'), isNull);
  });

  test('bloklar ve dosyalar yazının DIŞINDA listelenir', () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [
        NoteItem(id: 'yazi', text: 'sayfanın yazısı', section: 'Seyahat'),
        NoteItem(
          id: 'blok',
          text: 'alıntı',
          title: 'Bilet',
          section: 'Seyahat',
        ),
      ],
      attachments: [_file('bilet', section: 'Seyahat')],
    );
    final extras = archivePageExtras(note, 'Seyahat');
    expect(
      [for (final e in extras) e.text?.id ?? e.file!.id],
      ['blok', 'bilet'],
      reason: 'Serbest yazı listeden çıkar, kalanlar sırasını korur',
    );
  });

  test('Genel sayfasının yazısı da bölümsüz ilk sade girdidir', () {
    final note = _notebook(
      pages: ['Seyahat'],
      items: const [
        NoteItem(id: 'genel', text: 'eski not'),
        NoteItem(id: 'sayfali', text: 'uçuş', section: 'Seyahat'),
      ],
    );
    expect(archivePageText(note, '')?.id, 'genel');
    expect(archivePageText(note, 'Seyahat')?.id, 'sayfali');
  });

  // ————————————————————————————————— OTOMATİK SAYFA
  //
  // "Sayfa geçişinde yeni sayfa ekle çıkmadan oto geçiş olmalı": defterin
  // sonundaki boş yaprağın adı diyalog sormadan üretiliyor.

  test('otomatik sayfa adı kaçıncı YAPRAK olduğunu söyler (Genel dahil)', () {
    String label(int n) => 'Sayfa $n';
    expect(archiveAutoPageName(_notebook(), label), 'Sayfa 2');
    expect(archiveAutoPageName(_notebook(pages: ['A']), label), 'Sayfa 3');
  });

  test('ad çakışırsa numara ilerler — iki sayfa aynı adı taşıyamaz', () {
    String label(int n) => 'Sayfa $n';
    // Kullanıcı tek sayfasını elle "Sayfa 3" diye adlandırmış olabilir; ad
    // girdileri sayfaya bağlayan ANAHTAR, ikizlenirse girdiler karışır.
    final note = _notebook(pages: ['Sayfa 3']);
    expect(archiveAutoPageName(note, label), 'Sayfa 4');
  });

  // ————————————————————————————————— KÂĞIT DESENİ

  test('kâğıt deseni varsayılan çizgili, tanınmayan kimlik ona düşer', () {
    expect(
      const Note(id: 'n', type: NoteType.archive).archivePaper,
      ArchivePaper.lined,
    );
    expect(ArchivePaper.fromId('grid'), ArchivePaper.grid);
    expect(ArchivePaper.fromId('gelecekte-eklenen'), ArchivePaper.lined);
    expect(ArchivePaper.fromId(null), ArchivePaper.lined);
  });

  test('desen copyWith ile değişir, kimliği kayda yazılan dizedir', () {
    const note = Note(id: 'n', type: NoteType.archive);
    expect(
      note.copyWith(archivePaper: ArchivePaper.dots).archivePaper.id,
      'dots',
    );
  });

  // ————————————————————————————————— SAYFAYA YAZMANIN KURALI
  //
  // Yazı alanı 600 ms'de bir kaydediyor; kuralın kendisi saf bir işlev
  // (archiveWriteText) ve üç tuzağı da burada ölçülüyor.

  test('boş yaprağa yazmak SAYFAYI da açar (diyalog yok)', () {
    final note = _notebook();
    final next = archiveWriteText(
      note,
      page: 'Sayfa 2',
      text: 'ilk cümle',
      id: 'yeni',
    );
    expect(next.archivePages, ['Sayfa 2']);
    expect(next.items.single.id, 'yeni');
    expect(next.items.single.section, 'Sayfa 2');
  });

  test('Genel sayfasına yazmak sayfa AÇMAZ', () {
    final next = archiveWriteText(
      _notebook(),
      page: '',
      text: 'not',
      id: 'yeni',
    );
    expect(next.archivePages, isEmpty);
    expect(next.items.single.section, '');
  });

  test('hatırlanan kimlik BAŞKA sayfadaysa ikinci girdi açılmaz', () {
    // Çağıran, ilk harfte ürettiği kimliği sayfa adına göre hatırlıyor. O
    // girdi arada başka bir sayfaya taşınmış olabilir (⋮ → "Başka sayfaya
    // taşı"): aynı kimlikle ikinci bir girdi eklemek yazıyı ikizlerdi.
    final note = _notebook(
      pages: ['Sayfa 2', 'Sayfa 3'],
      items: const [NoteItem(id: 'w1', text: 'taşınmış', section: 'Sayfa 3')],
    );
    final next = archiveWriteText(
      note,
      page: 'Sayfa 2',
      text: 'yeni yazı',
      id: 'w1',
    );
    expect(next.items.length, 1);
    expect(next.items.single.text, 'yeni yazı');
    expect(next.items.single.section, 'Sayfa 2');
  });

  test('var olan yazı değiştirilir, yeni girdi eklenmez', () {
    final note = _notebook(
      pages: ['Sayfa 2'],
      items: const [NoteItem(id: 'w1', text: 'eski', section: 'Sayfa 2')],
    );
    final next = archiveWriteText(
      note,
      page: 'Sayfa 2',
      text: 'yeni',
      id: 'baska-kimlik',
    );
    expect(next.items.length, 1);
    expect(next.items.single.id, 'w1');
    expect(next.items.single.text, 'yeni');
  });

  test('metin tümüyle silinince girdi de silinir', () {
    final note = _notebook(
      items: const [NoteItem(id: 'w1', text: 'eski')],
    );
    expect(
      archiveWriteText(note, page: '', text: '   ', id: 'w1').items,
      isEmpty,
    );
  });

  test('değişiklik yoksa AYNI kayıt döner (boşuna yazım olmaz)', () {
    final note = _notebook(
      items: const [NoteItem(id: 'w1', text: 'aynı')],
    );
    expect(
      identical(archiveWriteText(note, page: '', text: 'aynı', id: 'w1'), note),
      isTrue,
    );
    // Boş sayfaya boş metin de yazım üretmez.
    final bos = _notebook();
    expect(
      identical(archiveWriteText(bos, page: 'Sayfa 2', text: '', id: 'x'), bos),
      isTrue,
    );
  });

  test('yazmak BAŞLIKLI bloklara dokunmaz', () {
    final note = _notebook(
      pages: ['Sayfa 2'],
      items: const [
        NoteItem(
          id: 'blok',
          text: 'alıntı',
          title: 'Bilet',
          section: 'Sayfa 2',
        ),
      ],
    );
    final next = archiveWriteText(
      note,
      page: 'Sayfa 2',
      text: 'serbest yazı',
      id: 'w1',
    );
    expect(next.items.length, 2);
    expect(next.items.first.id, 'blok');
    expect(next.items.last.text, 'serbest yazı');
  });
}
