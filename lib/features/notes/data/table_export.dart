import 'dart:convert';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../app/theme/app_tokens.dart';
import '../domain/note.dart';
import '../domain/note_table.dart';
import 'note_pdf.dart';

/// Tablonun dosya çıktısı.
enum TableExportKind { image, pdf, word }

/// **TABLOYU GÖRSEL / PDF / WORD OLARAK PAYLAŞ** (kullanıcı isteği
/// 2026-11-23). Üçü de yapıdan ([NoteTable]) çizilir, ekrandaki kutudan
/// değil: tablo sabit bölmede, şeritte ya da ekranın dışındayken de aynı
/// sonuç. Başlık satırı kalın ve tonlu, sütun genişlikleri tablodakiyle aynı.
///
/// * Görsel: `dart:ui` ile çizilen PNG (beyaz zemin — mesajlaşmada saydam
///   PNG siyah görünür).
/// * PDF: Syncfusion `PdfGrid` (uygulamanın TEK PDF yazıcısı), not PDF'iyle
///   aynı gömülü yazı tipi (PT Sans — ı ğ ş İ var); uzun tablo sayfalara
///   bölünür, başlık satırı her sayfada tekrar eder.
/// * Word: `.docx` (zip + XML, `NoteDocx` ile aynı yol, yeni bağımlılık yok);
///   gerçek Word tablosu — Word'de hücreler düzenlenir.
abstract final class TableExport {
  /// Görselin mantıksal genişliği (px) ve ölçeği.
  static const double _imageWidth = 720;
  static const double _pad = 24;
  static const double _cellH = 12;
  static const double _cellV = 9;
  static const double _font = 15;
  static const double _titleFont = 19;
  static const double _radius = 10;
  static const _ink = Color(0xFF1F2523);
  static const _line = Color(0xFFC9D3CF);
  static const _headFill = Color(0xFFE6EEEA);

  /// Paylaşım: dosyayı üretir ve sistem paylaşımını açar.
  static Future<void> share(
    NoteTable table, {
    required String title,
    required TableExportKind kind,
  }) async {
    final name = NotePdf.safeFileName(title);
    final XFile file = switch (kind) {
      TableExportKind.image => XFile.fromData(
        await png(table, title: title),
        name: '$name.png',
        mimeType: 'image/png',
      ),
      TableExportKind.pdf => XFile.fromData(
        await pdf(table, title: title),
        name: '$name.pdf',
        mimeType: 'application/pdf',
      ),
      TableExportKind.word => XFile.fromData(
        docx(table, title: title),
        name: '$name.docx',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      ),
    };
    await SharePlus.instance.share(ShareParams(files: [file], subject: title));
  }

  // ── Görsel ──────────────────────────────────────────────────────────

  static TextPainter _painter(
    String text,
    double width, {
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) =>
      TextPainter(
        textAlign: align,
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: _ink,
            fontSize: _font,
            height: 1.35,
            fontWeight: bold ? AppWeight.strong : AppWeight.regular,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(minWidth: width < 1 ? 1 : width, maxWidth: width < 1 ? 1 : width);

  /// Tablonun PNG'si ([pixelRatio] kat çözünürlükte).
  static Future<Uint8List> png(
    NoteTable table, {
    String title = '',
    double pixelRatio = 2,
  }) async {
    const inner = _imageWidth - 2 * _pad;
    final colW = [for (final w in table.widths) w * inner];
    final painters = <List<TextPainter>>[];
    final rowH = <double>[];
    for (var r = 0; r < table.rows; r++) {
      final row = <TextPainter>[];
      var h = 0.0;
      for (var c = 0; c < table.columns; c++) {
        final tp = _painter(
          table.plainCell(r, c),
          colW[c] - 2 * _cellH,
          bold: table.header && r == 0,
          align: switch (table.alignOf(r, c)) {
            CellAlign.center => TextAlign.center,
            CellAlign.end => TextAlign.right,
            CellAlign.start => TextAlign.left,
          },
        );
        row.add(tp);
        if (tp.height > h) h = tp.height;
      }
      painters.add(row);
      rowH.add(h + 2 * _cellV);
    }
    TextPainter? titlePainter;
    if (title.trim().isNotEmpty) {
      titlePainter = TextPainter(
        text: TextSpan(
          text: title.trim(),
          style: const TextStyle(
            color: _ink,
            fontSize: _titleFont,
            fontWeight: AppWeight.strong,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: inner);
    }
    final titleH = titlePainter == null ? 0.0 : titlePainter.height + _pad / 2;
    final tableH = rowH.fold<double>(0, (a, b) => a + b);
    final height = _pad + titleH + tableH + _pad;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _imageWidth, height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    titlePainter?.paint(canvas, const Offset(_pad, _pad));
    final top = _pad + titleH;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(_pad, top, inner, tableH),
      const Radius.circular(_radius),
    );
    canvas.save();
    canvas.clipRRect(box);
    if (table.header) {
      canvas.drawRect(
        Rect.fromLTWH(_pad, top, inner, rowH.first),
        Paint()..color = _headFill,
      );
    }
    if (table.striped) {
      var sy = top;
      for (var r = 0; r < table.rows; r++) {
        if (!(table.header && r == 0) && r.isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(_pad, sy, inner, rowH[r]),
            Paint()..color = const Color(0xFFF4F7F5),
          );
        }
        sy += rowH[r];
      }
    }
    final line = Paint()
      ..color = _line
      ..strokeWidth = 1;
    var y = top;
    for (var r = 0; r < table.rows; r++) {
      var x = _pad;
      for (var c = 0; c < table.columns; c++) {
        painters[r][c].paint(canvas, Offset(x + _cellH, y + _cellV));
        x += colW[c];
        if (c < table.columns - 1) {
          canvas.drawLine(Offset(x, y), Offset(x, y + rowH[r]), line);
        }
      }
      y += rowH[r];
      if (r < table.rows - 1) {
        canvas.drawLine(Offset(_pad, y), Offset(_pad + inner, y), line);
      }
    }
    canvas.restore();
    canvas.drawRRect(
      box,
      Paint()
        ..color = _line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    for (final row in painters) {
      for (final tp in row) {
        tp.dispose();
      }
    }
    titlePainter?.dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (_imageWidth * pixelRatio).round(),
      (height * pixelRatio).round(),
    );
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// Notun tabloları (sayfadaki, bölmedeki, şeritteki — hepsi), ek sırasıyla.
  static List<NoteTable> tablesOf(Note note) => [
    for (final a in note.attachments)
      if (isNoteTable(a)) ?NoteTable.of(a),
  ];

  /// NOT PDF'i için tablolar GÖRSEL olarak (metnin sonunda, tam genişlik):
  /// not PDF'inin elle dizgisi tablo çizmez; görsel her yerde aynı görünür.
  static Future<List<ExportImage>> noteTableImages(Note note) async => [
    for (final t in tablesOf(note))
      await () async {
        final bytes = await png(t);
        final size = await _pngSize(bytes);
        return ExportImage(
          bytes: bytes,
          width: size.$1,
          height: size.$2,
          mimeType: 'image/png',
          widthFraction: 1,
        );
      }(),
  ];

  static Future<(int, int)> _pngSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = (frame.image.width, frame.image.height);
    frame.image.dispose();
    codec.dispose();
    return size;
  }

  // ── PDF ─────────────────────────────────────────────────────────────

  /// Tablonun PDF'i (A4, uzun tablo sayfalara bölünür).
  static Future<Uint8List> pdf(NoteTable table, {String title = ''}) async {
    final regular = (await rootBundle.load(NotePdf.fontAsset)).buffer
        .asUint8List();
    final bold = (await rootBundle.load(NotePdf.boldFontAsset)).buffer
        .asUint8List();
    final doc = PdfDocument();
    try {
      doc.pageSettings
        ..size = PdfPageSize.a4
        ..margins.all = 40;
      final page = doc.pages.add();
      final width = page.getClientSize().width;
      final body = PdfTrueTypeFont(regular, 10.5);
      final strong = PdfTrueTypeFont(bold, 10.5);
      var top = 0.0;
      if (title.trim().isNotEmpty) {
        final titleFont = PdfTrueTypeFont(bold, 16);
        page.graphics.drawString(
          title.trim(),
          titleFont,
          brush: PdfSolidBrush(PdfColor(31, 37, 35)),
          bounds: Rect.fromLTWH(0, 0, width, 24),
        );
        top = 32;
      }
      final pen = PdfPen(PdfColor(201, 211, 207), width: 0.7);
      final borders = PdfBorders(left: pen, top: pen, right: pen, bottom: pen);
      final padding = PdfPaddings(left: 6, right: 6, top: 4, bottom: 4);
      final grid = PdfGrid()..columns.add(count: table.columns);
      for (var c = 0; c < table.columns; c++) {
        grid.columns[c].width = table.widths[c] * width;
      }
      grid.style = PdfGridStyle(font: body, cellPadding: padding);
      var first = 0;
      if (table.header) {
        grid.headers.add(1);
        final head = grid.headers[0];
        for (var c = 0; c < table.columns; c++) {
          head.cells[c].value = table.plainCell(0, c);
          head.cells[c].stringFormat = _pdfAlign(table.alignOf(0, c));
          head.cells[c].style = PdfGridCellStyle(
            font: strong,
            backgroundBrush: PdfSolidBrush(PdfColor(230, 238, 234)),
            borders: borders,
            cellPadding: padding,
          );
        }
        first = 1;
      }
      for (var r = first; r < table.rows; r++) {
        final row = grid.rows.add();
        final zebra = table.striped && !(table.header && r == 0) && r.isOdd;
        for (var c = 0; c < table.columns; c++) {
          row.cells[c].value = table.plainCell(r, c);
          row.cells[c].stringFormat = _pdfAlign(table.alignOf(r, c));
          row.cells[c].style = PdfGridCellStyle(
            backgroundBrush: zebra
                ? PdfSolidBrush(PdfColor(244, 247, 245))
                : null,
            borders: borders,
            cellPadding: padding,
          );
        }
      }
      grid.draw(page: page, bounds: Rect.fromLTWH(0, top, width, 0));
      return Uint8List.fromList(await doc.save());
    } finally {
      doc.dispose();
    }
  }

  static PdfStringFormat _pdfAlign(CellAlign a) => PdfStringFormat(
    alignment: switch (a) {
      CellAlign.center => PdfTextAlignment.center,
      CellAlign.end => PdfTextAlignment.right,
      CellAlign.start => PdfTextAlignment.left,
    },
  );

  // ── Word ────────────────────────────────────────────────────────────

  /// A4, 2 cm kenar boşluklu sayfanın metin genişliği (twip).
  static const _docxWidth = 9638;

  /// Tablonun Word (`w:tbl`) XML'i — not belgesine de gömülebilir.
  static String docxTableXml(NoteTable table) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    const border = 'w:val="single" w:sz="4" w:space="0" w:color="C9D3CF"';
    final cols = [for (final w in table.widths) (w * _docxWidth).round()];
    final out = StringBuffer(
      '<w:tbl><w:tblPr><w:tblW w:w="$_docxWidth" w:type="dxa"/>'
      '<w:tblBorders><w:top $border/><w:left $border/><w:bottom $border/>'
      '<w:right $border/><w:insideH $border/><w:insideV $border/>'
      '</w:tblBorders><w:tblLayout w:type="fixed"/>'
      '<w:tblCellMar><w:left w:w="100" w:type="dxa"/>'
      '<w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>',
    );
    for (final w in cols) {
      out.write('<w:gridCol w:w="$w"/>');
    }
    out.write('</w:tblGrid>');
    for (var r = 0; r < table.rows; r++) {
      final head = table.header && r == 0;
      final zebra = table.striped && !head && r.isOdd;
      out.write('<w:tr>');
      if (head) out.write('<w:trPr><w:tblHeader/></w:trPr>');
      for (var c = 0; c < table.columns; c++) {
        out.write('<w:tc><w:tcPr><w:tcW w:w="${cols[c]}" w:type="dxa"/>');
        if (head) {
          out.write('<w:shd w:val="clear" w:color="auto" w:fill="E6EEEA"/>');
        } else if (zebra) {
          out.write('<w:shd w:val="clear" w:color="auto" w:fill="F4F7F5"/>');
        }
        out.write('</w:tcPr>');
        // Hücredeki her satır ayrı paragraf (Word'de Enter'la aynı).
        final jc = switch (table.alignOf(r, c)) {
          CellAlign.center => '<w:pPr><w:jc w:val="center"/></w:pPr>',
          CellAlign.end => '<w:pPr><w:jc w:val="right"/></w:pPr>',
          CellAlign.start => '',
        };
        for (final line in table.plainCell(r, c).split('\n')) {
          out.write('<w:p>$jc<w:r>');
          if (head) out.write('<w:rPr><w:b/></w:rPr>');
          out.write('<w:t xml:space="preserve">${esc(line)}</w:t></w:r></w:p>');
        }
        out.write('</w:tc>');
      }
      out.write('</w:tr>');
    }
    out.write('</w:tbl>');
    return out.toString();
  }

  /// Tablonun `.docx`'i (başlık + tablo).
  static Uint8List docx(NoteTable table, {String title = ''}) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final heading = title.trim().isEmpty
        ? ''
        : '<w:p><w:r><w:rPr><w:b/><w:sz w:val="32"/><w:szCs w:val="32"/>'
              '</w:rPr><w:t xml:space="preserve">${esc(title.trim())}</w:t>'
              '</w:r></w:p>';
    final document =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$heading${docxTableXml(table)}'
        // Word gövdenin tabloyla bitmesini kabul etmez: ardından paragraf.
        '<w:p/>'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/>'
        '</w:sectPr></w:body></w:document>';
    const contentTypes =
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
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
    ArchiveFile file(String name, String content) {
      final bytes = utf8.encode(content);
      return ArchiveFile(name, bytes.length, bytes);
    }

    final archive = Archive()
      ..addFile(file('[Content_Types].xml', contentTypes))
      ..addFile(file('_rels/.rels', packageRels))
      ..addFile(file('word/document.xml', document));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
