import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Notu paylaşılabilir bir PDF'e çevirir.
///
/// `printing` paketi bilerek eklenmedi: dosya üretilip `share_plus` ile
/// paylaşılıyor, önizleme de zaten kurulu olan `pdfrx` ile yapılıyor. Böylece
/// native kod taşıyan bir bağımlılık daha girmiyor.
///
/// Font gömmek zorunlu: `pdf` paketinin hazır Helvetica'sı WinAnsi kodlamalı,
/// içinde ı ğ ş İ YOK — Türkçe not olduğu gibi bozuk çıkardı.
abstract final class NotePdf {
  static const fontAsset = 'assets/fonts/PTSans-Regular.ttf';

  static pw.Font? _font;

  static Future<pw.Font> _loadFont() async =>
      _font ??= pw.Font.ttf(await rootBundle.load(fontAsset));

  static Future<Uint8List> build({
    required String title,
    required String content,
    DateTime? date,
    List<ExportImage> images = const [],
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final font = await _loadFont();
    final doc = pw.Document(title: title.isEmpty ? 'Not' : title);
    final lines = parseLines(content);

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: font),
        margin: const pw.EdgeInsets.fromLTRB(52, 56, 52, 44),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          if (title.trim().isNotEmpty)
            pw.Text(
              title.trim(),
              style: pw.TextStyle(fontSize: 21, lineSpacing: 2),
            ),
          if (date != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                DateFormat('d MMMM y', 'tr').format(date),
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          if (title.trim().isNotEmpty || date != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
              child: pw.Divider(height: 1, color: PdfColors.grey400),
            ),
          // Görseller (el yazısı çizimleri dahil) NOTTAKİ YERLERİNE girer:
          // hangi satırdan önce durduğu, genişliği ve hizası nottan gelir.
          // Düzen bilgisi olmayan görsel (ör. paylaş menüsünden dışa aktarma)
          // eskisi gibi metnin sonuna eklenir.
          ..._withImages(lines, images, format),
        ],
      ),
    );
    return doc.save();
  }

  /// Satırları ve görselleri nottaki sıraya göre birleştirir: her görsel,
  /// [ExportImage.line] ile verilen satırdan ÖNCE gelir.
  static List<pw.Widget> _withImages(
    List<PdfLine> lines,
    List<ExportImage> images,
    PdfPageFormat format,
  ) {
    final placed = [
      for (final i in images)
        if (i.line != null) i,
    ]..sort((a, b) => a.line!.compareTo(b.line!));
    final trailing = [
      for (final i in images)
        if (i.line == null) i,
    ];
    final out = <pw.Widget>[];
    var next = 0;
    for (var index = 0; index < lines.length; index++) {
      while (next < placed.length && placed[next].line! <= index) {
        out.add(_imageWidget(placed[next++], format));
      }
      out.add(_lineWidget(lines[index]));
    }
    for (; next < placed.length; next++) {
      out.add(_imageWidget(placed[next], format));
    }
    out.addAll([for (final i in trailing) _imageWidget(i, format)]);
    return out;
  }

  /// Görseli nottaki oranıyla ölçekler; sayfadan taşmasın diye yükseklik de
  /// sınırlanır (MultiPage taşan tek parçayı bölemez, hata verirdi).
  static pw.Widget _imageWidget(ExportImage image, PdfPageFormat format) {
    final contentWidth = format.width - 52 - 52;
    final maxHeight = format.height - 56 - 44 - 24;
    final iw = image.width <= 0 ? 480.0 : image.width.toDouble();
    final ih = image.height <= 0 ? 360.0 : image.height.toDouble();
    var w = contentWidth * (image.widthFraction ?? 1).clamp(0.1, 1.0);
    var h = w * ih / iw;
    if (h > maxHeight) {
      h = maxHeight;
      w = h * iw / ih;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Align(
        alignment: switch (image.align) {
          ExportAlign.left => pw.Alignment.centerLeft,
          ExportAlign.right => pw.Alignment.centerRight,
          ExportAlign.center => pw.Alignment.center,
        },
        child: pw.Image(
          pw.MemoryImage(image.bytes),
          width: w,
          height: h,
          fit: pw.BoxFit.contain,
        ),
      ),
    );
  }

  /// PDF'i geçici dosyaya yazar; hem önizleme hem paylaşma bunu kullanır.
  static Future<String> writeTemp(Uint8List bytes, String title) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${safeFileName(title)}.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String safeFileName(String title) {
    final cleaned = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'not';
    return cleaned.length <= 60 ? cleaned : cleaned.substring(0, 60).trim();
  }

  /// Düz metni satır türlerine ayırır.
  ///
  /// Not içeriği düzenlenebilir tek bir metin kutusunda tutuluyor; yapı
  /// `Note.toPlainText()`'in zaten ürettiği işaretlerden okunuyor. Böylece
  /// kullanıcı dışa aktarmadan önce maddeleri serbestçe ekleyip silebiliyor,
  /// işaretli/işaretsiz durumu da metinle birlikte taşınıyor.
  /// Word dışa aktarma (NoteDocx) da aynı ayrıştırmayı kullanır — iki çıktı
  /// yapıyı hiçbir zaman farklı yorumlamaz.
  static List<PdfLine> parseLines(String content) {
    final out = <PdfLine>[];
    for (final raw in content.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        out.add(const PdfLine(PdfLineKind.blank, ''));
        continue;
      }
      final checkbox = _checkboxPattern.firstMatch(line);
      if (checkbox != null) {
        final checked = checkbox.group(1)!.toLowerCase() == 'x';
        out.add(
          PdfLine(
            checked ? PdfLineKind.checked : PdfLineKind.unchecked,
            checkbox.group(2)!,
          ),
        );
        continue;
      }
      final numbered = _numberedPattern.firstMatch(line);
      if (numbered != null) {
        out.add(
          PdfLine(
            PdfLineKind.numbered,
            numbered.group(2)!,
            marker: '${numbered.group(1)}.',
          ),
        );
        continue;
      }
      final bullet = _bulletPattern.firstMatch(line);
      if (bullet != null) {
        out.add(PdfLine(PdfLineKind.bullet, bullet.group(1)!));
        continue;
      }
      out.add(PdfLine(PdfLineKind.paragraph, line.trimLeft()));
    }
    // Sondaki boş satırlar PDF'te bir işe yaramıyor, sayfa da şişiriyor.
    while (out.isNotEmpty && out.last.kind == PdfLineKind.blank) {
      out.removeLast();
    }
    return out;
  }

  static pw.Widget _lineWidget(PdfLine line) => switch (line.kind) {
    PdfLineKind.blank => pw.SizedBox(height: 8),
    PdfLineKind.paragraph => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        line.text,
        style: const pw.TextStyle(fontSize: 11.5, lineSpacing: 2.5),
      ),
    ),
    PdfLineKind.checked || PdfLineKind.unchecked => _row(
      _checkbox(line.kind == PdfLineKind.checked),
      line.text,
      strike: line.kind == PdfLineKind.checked,
    ),
    PdfLineKind.numbered => _row(
      pw.SizedBox(
        width: 20,
        child: pw.Text(
          line.marker,
          style: const pw.TextStyle(fontSize: 11.5, color: PdfColors.grey700),
        ),
      ),
      line.text,
    ),
    PdfLineKind.bullet => _row(
      pw.SizedBox(
        width: 14,
        child: pw.Text('•', style: const pw.TextStyle(fontSize: 11.5)),
      ),
      line.text,
    ),
  };

  static pw.Widget _row(pw.Widget leading, String text, {bool strike = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            leading,
            pw.Expanded(
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  fontSize: 11.5,
                  lineSpacing: 2.5,
                  color: strike ? PdfColors.grey600 : null,
                  decoration: strike ? pw.TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      );

  /// Onay kutusu glif değil çizim: PT Sans'ta ✓ (U+2713) ve ☐ (U+2610) YOK,
  /// karakterle yazılsa .notdef kutucuğu basardı.
  static pw.Widget _checkbox(bool checked) => pw.Container(
    width: 11,
    height: 11,
    margin: const pw.EdgeInsets.only(top: 2, right: 7),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.blueGrey400, width: .8),
      borderRadius: pw.BorderRadius.circular(2),
      color: checked ? PdfColors.blueGrey700 : null,
    ),
    child: checked
        ? pw.CustomPaint(
            size: const PdfPoint(11, 11),
            painter: (canvas, size) {
              // PDF'te başlangıç noktası SOL ALT, y yukarı büyür.
              canvas
                ..setStrokeColor(PdfColors.white)
                ..setLineWidth(1.4)
                ..moveTo(2.4, 5.6)
                ..lineTo(4.5, 3.2)
                ..lineTo(8.6, 7.7)
                ..strokePath();
            },
          )
        : null,
  );

  static final _checkboxPattern = RegExp(r'^\s*\[([ xX])\]\s*(.*)$');
  static final _numberedPattern = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');
  static final _bulletPattern = RegExp(r'^\s*[-•*]\s+(.*)$');
}

/// Dışa aktarmaya (PDF/Word) girecek bir görsel: baytlar + piksel boyutları
/// (sayfaya ölçeklemek için) + tür (Word'de dosya uzantısı bundan seçilir).
class ExportImage {
  const ExportImage({
    required this.bytes,
    required this.width,
    required this.height,
    this.mimeType = 'image/jpeg',
    this.line,
    this.widthFraction,
    this.align = ExportAlign.center,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String mimeType;

  /// Görselin nota göre yeri: metnin KAÇINCI satırından önce gelmeli.
  /// null ise (düzen bilgisi yok) metnin sonuna eklenir.
  final int? line;

  /// Sayfa genişliğine oranı (nottaki boyutu). null ise tam genişlik.
  final double? widthFraction;

  /// Yatay hizası — nottaki x konumundan gelir.
  final ExportAlign align;

  String get extension => switch (mimeType) {
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
}

/// Dışa aktarılan görselin yatay hizası (nottaki x konumundan türetilir).
enum ExportAlign { left, center, right }

enum PdfLineKind { blank, paragraph, checked, unchecked, bullet, numbered }

class PdfLine {
  const PdfLine(this.kind, this.text, {this.marker = ''});

  final PdfLineKind kind;
  final String text;
  final String marker;

  @override
  String toString() => '$kind($marker$text)';
}
