import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Word, PowerPoint ve düz metin dosyalarından okunabilir metin çıkarır.
///
/// DOCX ve PPTX aslında içinde XML tutan ZIP arşivleridir; ikisini birden
/// okuyan hazır bir Dart paketi yok. `archive` ve `xml` zaten bağımlılık
/// ağacındaydı, o yüzden bu çıkarma yeni paket ağırlığı getirmiyor.
abstract final class DocText {
  /// Açılabilen uzantılar; dosya seçicinin süzgeci de bunu kullanır.
  /// PDF burada yok — onun kendi metin katmanı çıkarıcısı var (`PdfText`).
  static const extensions = ['txt', 'md', 'docx', 'pptx'];

  static String extensionOf(String path) =>
      p.extension(path).toLowerCase().replaceFirst('.', '');

  static bool supports(String path) => extensions.contains(extensionOf(path));

  /// Dosyayı okuyup düz metne çevirir.
  ///
  /// Ayrıştırma ana iş parçacığını kilitlemesin diye [compute] üzerinden
  /// yapılır: 40 slaytlık bir sunumda unzip + XML ayrıştırma göz açıp
  /// kapayıncaya kadar sürmüyor, dönen çarkın takılması bunu ele veriyordu.
  static Future<String> extract(String path) async {
    final ext = extensionOf(path);
    if (!extensions.contains(ext)) throw DocTextException(ext);
    final bytes = await File(path).readAsBytes();
    return compute(_extract, (ext, bytes));
  }
}

@visibleForTesting
String extractDocSync(String ext, Uint8List bytes) => _extract((ext, bytes));

String _extract((String, Uint8List) input) {
  final (ext, bytes) = input;
  try {
    return switch (ext) {
      'txt' || 'md' => decodeDocText(bytes),
      'docx' => _fromEntry(bytes, 'word/document.xml'),
      'pptx' => _fromSlides(bytes),
      _ => throw DocTextException(ext),
    };
  } on ArchiveException {
    throw DocTextException(ext);
  } on XmlException {
    throw DocTextException(ext);
  }
}

/// Düz metin dosyaları kodlamalarını belirtmez. Önce UTF-8 denenir; Windows'ta
/// üretilmiş Türkçe .txt dosyaları çoğunlukla CP1254 olduğu için geri düşüş
/// latin1 + o kod sayfasına özgü baytların eşlenmesidir. Düz latin1 tek başına
/// ğ/ı/ş harflerini bozardı.
@visibleForTesting
String decodeDocText(Uint8List bytes) {
  var data = bytes;
  if (data.length >= 3 &&
      data[0] == 0xEF &&
      data[1] == 0xBB &&
      data[2] == 0xBF) {
    data = Uint8List.sublistView(data, 3);
  }
  try {
    return utf8.decode(data);
  } on FormatException {
    const cp1254 = {
      0x85: '…',
      0x91: '‘',
      0x92: '’',
      0x93: '“',
      0x94: '”',
      0x96: '–',
      0x97: '—',
      0xD0: 'Ğ',
      0xDD: 'İ',
      0xDE: 'Ş',
      0xF0: 'ğ',
      0xFD: 'ı',
      0xFE: 'ş',
    };
    final out = StringBuffer();
    for (final b in data) {
      out.write(cp1254[b] ?? String.fromCharCode(b));
    }
    return out.toString();
  }
}

String _fromEntry(Uint8List bytes, String entry) {
  for (final file in ZipDecoder().decodeBytes(bytes).files) {
    if (file.isFile && file.name == entry) {
      return _paragraphs(utf8.decode(file.readBytes() ?? [], allowMalformed: true));
    }
  }
  throw const DocTextException('docx');
}

final _slideEntry = RegExp(r'^ppt/slides/slide(\d+)\.xml$');

String _fromSlides(Uint8List bytes) {
  final slides = ZipDecoder()
      .decodeBytes(bytes)
      .files
      .where((f) => f.isFile && _slideEntry.hasMatch(f.name))
      .toList();
  if (slides.isEmpty) throw const DocTextException('pptx');
  // slide10, dizgi sıralamasında slide2'nin ÖNÜNE geçer — sunum baştan sona
  // karışık okunurdu. Sıralama slayt numarasına göre sayısal yapılır.
  slides.sort((a, b) => _slideNo(a.name).compareTo(_slideNo(b.name)));
  return slides
      .map(
        (f) => _paragraphs(
          utf8.decode(f.readBytes() ?? [], allowMalformed: true),
        ).trim(),
      )
      .where((text) => text.isNotEmpty)
      .join('\n');
}

int _slideNo(String name) =>
    int.tryParse(_slideEntry.firstMatch(name)?.group(1) ?? '') ?? 0;

/// DOCX ve PPTX'te metin aynı biçimde durur: paragraf `p`, metin parçası `t`.
/// Ad alanı farklı (`w:` / `a:`), o yüzden joker ad alanıyla aranıyor —
/// tek işlev ikisini de okuyor.
String _paragraphs(String xml) {
  final out = StringBuffer();
  for (final para in XmlDocument.parse(xml).findAllElements('p', namespaceUri: '*')) {
    // Metin kutuları paragraf içinde paragraf doğurur. Dıştaki zaten içteki
    // metni de topluyor; içteki ayrıca yazılırsa aynı cümle iki kez okunur.
    if (para.ancestors.whereType<XmlElement>().any((e) => e.localName == 'p')) {
      continue;
    }
    final line = para
        .findAllElements('t', namespaceUri: '*')
        .map((e) => e.innerText)
        .join()
        .trim();
    if (line.isNotEmpty) out.writeln(line);
  }
  return out.toString();
}

class DocTextException implements Exception {
  const DocTextException(this.extension);

  final String extension;

  @override
  String toString() => 'DocTextException($extension)';
}
