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
/// Görseller `word/media/` içine gömülür ve NOTTAKİ yerlerine, nottaki
/// oranları ve hizalarıyla girer — PDF ile aynı kural. Word'ün açamayacağı bir
/// tür gelirse (beklenmiyor; ekler jpg/png'ye normalize ediliyor) o görsel
/// sessizce atlanmaz — content-type tablosunda yaygın türlerin tamamı tanımlı.
abstract final class NoteDocx {
  /// Görselin sayfada kaplayabileceği en büyük alan (EMU): ~15,2 cm × ~19 cm
  /// (A4, 2 cm kenar boşluğuyla).
  static const _maxCx = 5760000;
  static const _maxCy = 7200000;

  /// Zip sıkıştırması (tüm görsel baytları üzerinde deflate) ana izolede
  /// kareyi düpedüz kilitliyordu — üretim compute() izolesine taşındı. Tarih
  /// etiketi ANA izolede biçimlenir: DateFormat'ın yerel sembollerini
  /// flutter_localizations yalnız ana izolede yükler.
  static Future<Uint8List> build({
    required String title,
    required String content,
    DateTime? date,
    List<ExportImage> images = const [],
  }) {
    final dateLabel = date == null
        ? null
        : DateFormat('d MMMM y', 'tr').format(date);
    return compute(
      _buildInIsolate,
      _DocxRequest(
        title: title,
        content: content,
        dateLabel: dateLabel,
        images: images,
      ),
    );
  }

  static Uint8List _buildInIsolate(_DocxRequest r) {
    final title = r.title;
    final content = r.content;
    final images = r.images;
    final body = StringBuffer();
    if (title.trim().isNotEmpty) {
      body.write(
        _p(
          _r(title.trim(), rPr: '<w:b/><w:sz w:val="42"/><w:szCs w:val="42"/>'),
        ),
      );
    }
    if (r.dateLabel != null) {
      body.write(
        _p(
          _r(
            r.dateLabel!,
            rPr:
                '<w:color w:val="777777"/><w:sz w:val="19"/><w:szCs w:val="19"/>',
          ),
        ),
      );
    }
    if (title.trim().isNotEmpty || r.dateLabel != null) {
      body.write(_p(''));
    }
    // Görseller NOTTAKİ YERLERİNE girer — kural PDF ile birebir aynı
    // (bkz. `NotePdf._withImages`): her görsel [ExportImage.line] ile verilen
    // satırdan ÖNCE gelir, düzen bilgisi olmayan görsel metnin sonuna eklenir.
    // DİKKAT: rId ve `word/media/` dosya adı ÖZGÜN [images] sırasını izler;
    // yerleşim sırası onu değiştirmemeli, yoksa görseller birbirinin yerine
    // gömülür. Bu yüzden sıralama indeksler üzerinden yapılır.
    final lines = NotePdf.parseLines(content);
    final placed = [
      for (var i = 0; i < images.length; i++)
        if (images[i].line != null) i,
    ]..sort((a, b) => images[a].line!.compareTo(images[b].line!));
    final trailing = [
      for (var i = 0; i < images.length; i++)
        if (images[i].line == null) i,
    ];
    var next = 0;
    for (var index = 0; index < lines.length; index++) {
      while (next < placed.length && images[placed[next]].line! <= index) {
        body.write(_imageParagraph(images[placed[next]], placed[next] + 1));
        next++;
      }
      final line = lines[index];
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
    for (; next < placed.length; next++) {
      body.write(_imageParagraph(images[placed[next]], placed[next] + 1));
    }
    for (final i in trailing) {
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

  /// Nottaki oranıyla ölçeklenmiş, nottaki hizasına yerleştirilmiş gömülü
  /// görsel paragrafı. Ölçekleme PDF'teki `NotePdf._imageWidget` ile aynı:
  /// genişlik satır genişliğinin [ExportImage.widthFraction] katı (düzen
  /// bilgisi yoksa tam genişlik), yükseklik oranla türetilir ve sayfayı
  /// aşarsa geri ölçeklenir.
  static String _imageParagraph(ExportImage img, int n) {
    final iw = img.width <= 0 ? 480.0 : img.width.toDouble();
    final ih = img.height <= 0 ? 360.0 : img.height.toDouble();
    var w = _maxCx * (img.widthFraction ?? 1).clamp(0.1, 1.0);
    var h = w * ih / iw;
    if (h > _maxCy) {
      h = _maxCy.toDouble();
      w = h * iw / ih;
    }
    final cx = w.round();
    final cy = h.round();
    final jc = switch (img.align) {
      ExportAlign.left => 'left',
      ExportAlign.center => 'center',
      ExportAlign.right => 'right',
    };
    return '<w:p><w:pPr><w:jc w:val="$jc"/></w:pPr><w:r><w:drawing>'
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

/// [NoteDocx._buildInIsolate]'a taşınan istek — tüm alanlar izoleler arası
/// gönderilebilir (String/Uint8List).
class _DocxRequest {
  const _DocxRequest({
    required this.title,
    required this.content,
    required this.dateLabel,
    required this.images,
  });

  final String title;
  final String content;
  final String? dateLabel;
  final List<ExportImage> images;
}
