import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/doc_text.dart';

Uint8List _zip(Map<String, String> entries) {
  final archive = Archive();
  entries.forEach(
    (name, content) => archive.add(ArchiveFile.string(name, content)),
  );
  return ZipEncoder().encodeBytes(archive);
}

String _docx(String body) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:body>$body</w:body></w:document>';

String _slide(String body) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
    '<p:cSld><p:spTree><p:sp><p:txBody>$body</p:txBody></p:sp></p:spTree>'
    '</p:cSld></p:sld>';

void main() {
  group('docx', () {
    test('aynı paragraftaki metin parçaları tek satırda birleşir', () {
      // Word bir cümleyi biçim değiştikçe birden çok <w:r> parçasına böler;
      // her parça ayrı satır olsaydı metin didik didik okunurdu.
      final bytes = _zip({
        'word/document.xml': _docx(
          '<w:p><w:r><w:t>Merhaba </w:t></w:r><w:r><w:t>dünya</w:t></w:r></w:p>'
          '<w:p><w:r><w:t>İkinci satır</w:t></w:r></w:p>',
        ),
      });
      expect(
        extractDocSync('docx', bytes).trim().split('\n'),
        ['Merhaba dünya', 'İkinci satır'],
      );
    });

    test('metin kutusundaki iç paragraf iki kez okunmaz', () {
      final bytes = _zip({
        'word/document.xml': _docx(
          '<w:p><w:r><w:t>Dış</w:t></w:r>'
          '<w:txbxContent><w:p><w:r><w:t>İç</w:t></w:r></w:p></w:txbxContent>'
          '</w:p>',
        ),
      });
      expect(extractDocSync('docx', bytes).trim().split('\n'), ['Dışİç']);
    });

    test('document.xml yoksa hata verir', () {
      expect(
        () => extractDocSync('docx', _zip({'docProps/app.xml': '<a/>'})),
        throwsA(isA<DocTextException>()),
      );
    });
  });

  group('pptx', () {
    test('slaytlar sayısal sırayla okunur', () {
      // Asıl tuzak bu: dizgi sıralamasında slide10 < slide2 olduğu için
      // sunum karışık okunurdu.
      final bytes = _zip({
        'ppt/slides/slide10.xml': _slide(
          '<a:p><a:r><a:t>onuncu</a:t></a:r></a:p>',
        ),
        'ppt/slides/slide2.xml': _slide(
          '<a:p><a:r><a:t>ikinci</a:t></a:r></a:p>',
        ),
        'ppt/slides/slide1.xml': _slide(
          '<a:p><a:r><a:t>birinci</a:t></a:r></a:p>',
        ),
      });
      expect(
        extractDocSync('pptx', bytes).trim().split('\n'),
        ['birinci', 'ikinci', 'onuncu'],
      );
    });

    test('slayt yoksa hata verir', () {
      expect(
        () => extractDocSync('pptx', _zip({'ppt/presentation.xml': '<a/>'})),
        throwsA(isA<DocTextException>()),
      );
    });
  });

  group('düz metin kodlaması', () {
    test('UTF-8 olduğu gibi okunur', () {
      final bytes = Uint8List.fromList(utf8.encode('ışık ğ ş İ'));
      expect(decodeDocText(bytes), 'ışık ğ ş İ');
    });

    test('BOM atılır', () {
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('a')]);
      expect(decodeDocText(bytes), 'a');
    });

    test('CP1254 Türkçe harfleri bozulmadan çözülür', () {
      // Windows Not Defteri'nden çıkmış bir dosya: 0xFD=ı, 0xFE=ş, 0xF0=ğ.
      // Düz latin1 bunları ý, þ, ð yapardı.
      final bytes = Uint8List.fromList([0xFD, 0xFE, 0xF0, 0xDD]);
      expect(decodeDocText(bytes), 'ışğİ');
    });
  });

  test('desteklenmeyen uzantı reddedilir', () {
    expect(DocText.supports('a.docx'), isTrue);
    expect(DocText.supports('a.pptx'), isTrue);
    expect(DocText.supports('a.TXT'), isTrue);
    expect(DocText.supports('a.xlsx'), isFalse);
    expect(
      () => extractDocSync('xlsx', Uint8List(0)),
      throwsA(isA<DocTextException>()),
    );
  });
}
