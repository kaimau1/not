import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_docx.dart';
import 'package:notlar/features/notes/data/note_pdf.dart';

/// docx görselleri NOTTAKİ yerine koyuyor mu — PDF ile aynı kural.
///
/// Önceden görseller ne olursa olsun metnin SONUNA yığılıyordu. Yerleşim
/// eklenirken asıl tuzak şu: rId ve `word/media/` dosya adı özgün [images]
/// sırasından üretiliyor, yerleşim ise sırayı değiştiriyor. İkisi karışırsa
/// görseller birbirinin yerine gömülür ve bu gözle ancak Word'de açınca
/// fark edilir — bu yüzden test id eşleşmesini ayrıca doğruluyor.
void main() {
  String documentXml(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final f in archive.files) {
      if (f.name == 'word/document.xml') {
        return utf8.decode(f.content as List<int>);
      }
    }
    fail('word/document.xml paketten çıkmadı');
  }

  ExportImage image({
    int? line,
    double? widthFraction,
    ExportAlign align = ExportAlign.center,
    String mimeType = 'image/png',
  }) => ExportImage(
    bytes: Uint8List.fromList(const [1, 2, 3, 4]),
    width: 400,
    height: 300,
    mimeType: mimeType,
    line: line,
    widthFraction: widthFraction,
    align: align,
  );

  test('görseller nottaki satırlarına giriyor, düzensizler sona kalıyor', () async {
    // Sıra bilerek karışık: trailing görsel ÖNCE geliyor ki yerleşim
    // sıralaması ile rId sıralaması birbirine karışırsa test kırılsın.
    final xml = documentXml(
      await NoteDocx.build(
        title: '',
        content: 'bir\niki\nüç',
        images: [
          image(), // rIdImg1 — düzen bilgisi yok, sona
          image(line: 0, widthFraction: 0.5, align: ExportAlign.right),
          image(line: 2, align: ExportAlign.left), // rIdImg3
        ],
      ),
    );

    int at(String needle) {
      final i = xml.indexOf(needle);
      expect(i, isNonNegative, reason: '$needle belgede yok');
      return i;
    }

    // Beklenen belge sırası: img2 · bir · iki · img3 · üç · img1
    expect(at('rIdImg2'), lessThan(at('>bir<')));
    expect(at('>bir<'), lessThan(at('>iki<')));
    expect(at('>iki<'), lessThan(at('rIdImg3')));
    expect(at('rIdImg3'), lessThan(at('>üç<')));
    expect(at('>üç<'), lessThan(at('rIdImg1')));
  });

  test('rId, özgün sıradaki medya dosyasını gösteriyor', () async {
    final bytes = await NoteDocx.build(
      title: '',
      content: 'bir\niki',
      images: [
        image(mimeType: 'image/png'),
        image(line: 0, mimeType: 'image/jpeg'),
      ],
    );
    final rels = ZipDecoder()
        .decodeBytes(bytes)
        .files
        .firstWhere((f) => f.name == 'word/_rels/document.xml.rels');
    final xml = utf8.decode(rels.content as List<int>);

    // Yerleşimde ikinci görsel başa geçiyor; rId eşleşmesi ÖZGÜN sırayı
    // izlemeli, yoksa png ile jpg birbirinin yerine gömülür.
    expect(xml, contains('Id="rIdImg1"'));
    expect(xml, contains('Target="media/image1.png"'));
    expect(xml, contains('Target="media/image2.jpg"'));
  });

  test('nottaki oran ve hiza uygulanıyor', () async {
    final xml = documentXml(
      await NoteDocx.build(
        title: '',
        content: 'bir',
        images: [image(line: 0, widthFraction: 0.5, align: ExportAlign.right)],
      ),
    );

    // Genişlik = satır genişliğinin yarısı; yükseklik 400x300 oranından.
    expect(xml, contains('cx="2880000" cy="2160000"'));
    expect(xml, contains('<w:jc w:val="right"/>'));
  });

  test('düzen bilgisi olmayan görsel tam genişlikte ve ortada', () async {
    final xml = documentXml(
      await NoteDocx.build(title: '', content: 'bir', images: [image()]),
    );

    expect(xml, contains('cx="5760000" cy="4320000"'));
    expect(xml, contains('<w:jc w:val="center"/>'));
  });
}
