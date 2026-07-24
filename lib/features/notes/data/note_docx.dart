import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'note_pdf.dart';

/// Notu Word (.docx) belgesine çevirir — YENİ BAĞIMLILIK YOK: .docx bir zip
/// içinde birkaç XML'dir; zip zaten `archive` (slaytlar) ile açılıp
/// kapatılabiliyor, XML'ler ise şablondan üretiliyor. Satır yapısı (madde/
/// numara/onay kutusu) [NotePdf.parseLines] ile PDF'tekiyle birebir aynı
/// kurallardan okunur — iki çıktı hiçbir zaman farklı yorumlamaz.
///
/// Görseller `word/media/` içine gömülür ve metnin ardından tam satır
/// genişliğinde eklenir. Word'ün açamayacağı bir tür gelirse (beklenmiyor;
/// ekler jpg/png'ye normalize ediliyor) o görsel sessizce atlanmaz —
/// content-type tablosunda yaygın türlerin tamamı tanımlı.
abstract final class NoteDocx {
  /// px → EMU (English Metric Unit, 96 dpi): Word çizim boyut birimi.
  static const _emuPerPx = 9525;

  /// Görselin sayfada kaplayabileceği en büyük alan (EMU): ~15,2 cm × ~19 cm
  /// (A4, 2 cm kenar boşluğuyla).
  static const _maxCx = 5760000;
  static const _maxCy = 7200000;

  static Uint8List build({
    required String title,
    required String content,
    DateTime? date,
    List<ExportImage> images = const [],
  }) {
    final body = StringBuffer();
    if (title.trim().isNotEmpty) {
      body.write(
        _p(
          _r(title.trim(), rPr: '<w:b/><w:sz w:val="42"/><w:szCs w:val="42"/>'),
        ),
      );
    }
    if (date != null) {
      body.write(
        _p(
          _r(
            DateFormat('d MMMM y', 'tr').format(date),
            rPr:
                '<w:color w:val="777777"/><w:sz w:val="19"/><w:szCs w:val="19"/>',
          ),
        ),
      );
    }
    if (title.trim().isNotEmpty || date != null) {
      body.write(_p(''));
    }
    for (final line in NotePdf.parseLines(content)) {
      body.write(switch (line.kind) {
        PdfLineKind.blank => _p(''),
        PdfLineKind.paragraph => _p(_r(line.text)),
        PdfLineKind.checked => _p(
          _r(
            '☑ ${line.text}',
            rPr: '<w:strike/><w:color w:val="777777"/>',
          ),
        ),
        PdfLineKind.unchecked => _p(_r('☐ ${line.text}')),
        PdfLineKind.numbered => _p(_r('${line.marker} ${line.text}')),
        PdfLineKind.bullet => _p(_r('• ${line.text}')),
      });
    }
    for (var i = 0; i < images.length; i++) {
      body.write(_imageParagraph(images[i], i + 1));
    }

    final document =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document'
        ' xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        ' xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"'
        ' xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
        ' xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<w:body>$body'
        '<w:sectPr>'
        '<w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/>'
        '</w:sectPr>'
        '</w:body></w:document>';

    final rels = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    );
    for (var i = 0; i < images.length; i++) {
      rels.write(
        '<Relationship Id="rIdImg${i + 1}"'
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"'
        ' Target="media/image${i + 1}.${images[i].extension}"/>',
      );
    }
    rels.write('</Relationships>');

    const contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="jpg" ContentType="image/jpeg"/>'
        '<Default Extension="jpeg" ContentType="image/jpeg"/>'
        '<Default Extension="png" ContentType="image/png"/>'
        '<Default Extension="gif" ContentType="image/gif"/>'
        '<Default Extension="webp" ContentType="image/webp"/>'
        '<Override PartName="/word/document.xml"'
        ' ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>';

    const packageRels =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1"'
        ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"'
        ' Target="word/document.xml"/>'
        '</Relationships>';

    final archive = Archive()
      ..addFile(_textFile('[Content_Types].xml', contentTypes))
      ..addFile(_textFile('_rels/.rels', packageRels))
      ..addFile(_textFile('word/document.xml', document))
      ..addFile(_textFile('word/_rels/document.xml.rels', rels.toString()));
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      archive.addFile(
        ArchiveFile(
          'word/media/image${i + 1}.${img.extension}',
          img.bytes.length,
          img.bytes,
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Belgeyi geçici dosyaya yazar (paylaşım için); ad kuralı PDF ile ortak.
  static Future<String> writeTemp(Uint8List bytes, String title) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${NotePdf.safeFileName(title)}.docx'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static ArchiveFile _textFile(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _p(String runs) => '<w:p>$runs</w:p>';

  static String _r(String text, {String rPr = ''}) =>
      '<w:r>${rPr.isEmpty ? '' : '<w:rPr>$rPr</w:rPr>'}'
      '<w:t xml:space="preserve">${_esc(text)}</w:t></w:r>';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Satır genişliğine (üst sınırlarla) ölçeklenmiş gömülü görsel paragrafı.
  static String _imageParagraph(ExportImage img, int n) {
    var cx = (img.width <= 0 ? 480 : img.width) * _emuPerPx;
    var cy = (img.height <= 0 ? 360 : img.height) * _emuPerPx;
    if (cx > _maxCx) {
      cy = cy * _maxCx ~/ cx;
      cx = _maxCx;
    }
    if (cy > _maxCy) {
      cx = cx * _maxCy ~/ cy;
      cy = _maxCy;
    }
    return '<w:p><w:r><w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$cx" cy="$cy"/>'
        '<wp:docPr id="$n" name="Resim $n"/>'
        '<a:graphic>'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic>'
        '<pic:nvPicPr><pic:cNvPr id="$n" name="Resim $n"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="rIdImg$n"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
        '</pic:pic></a:graphicData></a:graphic>'
        '</wp:inline></w:drawing></w:r></w:p>';
  }
}
