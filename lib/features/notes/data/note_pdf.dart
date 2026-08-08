import 'dart:io';

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/rich_text.dart';

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

  /// Kalın ve italik kesimler. `pdf` paketi bu kesimleri SENTEZLEMEZ: dosyası
  /// verilmezse `fontWeight: bold` yazan metin düz çıkar (kullanıcı bulgusu
  /// 2026-08-08: "yazı biçimi de aktarılmıyor").
  static const boldFontAsset = 'assets/fonts/PTSans-Bold.ttf';
  static const italicFontAsset = 'assets/fonts/PTSans-Italic.ttf';

  /// PDF üretimi (yerleşim + font alt kümeleme + görsel kodlama) compute()
  /// izolesinde koşar: 20 görselli bir not ana izolede saniyelerce kare
  /// düşürüyor, ilerleme çubuğu bile oynayamıyordu. Font baytları ve tarih
  /// etiketi ANA izolede hazırlanır — rootBundle ve yerel ayarlı DateFormat
  /// (sembolleri flutter_localizations ana izolede yükler) izolede yok.
  static Future<Uint8List> build({
    required String title,
    required String content,
    DateTime? date,
    List<ExportImage> images = const [],
    List<Color> palette = const [],
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final fontBytes = await rootBundle.load(fontAsset);
    final boldBytes = await rootBundle.load(boldFontAsset);
    final italicBytes = await rootBundle.load(italicFontAsset);
    final dateLabel = date == null
        ? null
        : DateFormat('d MMMM y').format(date);
    return compute(
      _buildInIsolate,
      _PdfRequest(
        title: title,
        content: content,
        dateLabel: dateLabel,
        images: images,
        fontBytes: fontBytes,
        boldBytes: boldBytes,
        italicBytes: italicBytes,
        // Renk paleti ANA izolede okunur: `Color` Flutter türü, izolede tema
        // yok. ARGB tamsayısına çevrilip taşınır.
        palette: [for (final c in palette) c.toARGB32()],
        format: format,
      ),
    );
  }

  static Future<Uint8List> _buildInIsolate(_PdfRequest r) async {
    final font = pw.Font.ttf(r.fontBytes);
    final bold = pw.Font.ttf(r.boldBytes);
    final italic = pw.Font.ttf(r.italicBytes);
    final title = r.title;
    final format = r.format;
    final doc = pw.Document(title: title.isEmpty ? 'Not' : title);
    final lines = parseLines(r.content);

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: bold,
          italic: italic,
          boldItalic: bold,
        ),
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
            _rich(
              title.trim(),
              const pw.TextStyle(fontSize: 21, lineSpacing: 2),
              r.palette,
            ),
          if (r.dateLabel != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                r.dateLabel!,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          if (title.trim().isNotEmpty || r.dateLabel != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
              child: pw.Divider(height: 1, color: PdfColors.grey400),
            ),
          // Görseller (el yazısı çizimleri dahil) NOTTAKİ YERLERİNE girer:
          // hangi satırdan önce durduğu, genişliği ve hizası nottan gelir.
          // Düzen bilgisi olmayan görsel (ör. paylaş menüsünden dışa aktarma)
          // eskisi gibi metnin sonuna eklenir.
          ..._withImages(lines, r.images, format, r.palette),
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
    List<int> palette,
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
      out.add(_lineWidget(lines[index], palette));
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

  static pw.Widget _lineWidget(PdfLine line, List<int> palette) =>
      switch (line.kind) {
        PdfLineKind.blank => pw.SizedBox(height: 8),
        PdfLineKind.paragraph => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _rich(line.text, _bodyStyle, palette),
        ),
        PdfLineKind.checked || PdfLineKind.unchecked => _row(
          _checkbox(line.kind == PdfLineKind.checked),
          line.text,
          palette,
          strike: line.kind == PdfLineKind.checked,
        ),
        PdfLineKind.numbered => _row(
          pw.SizedBox(
            width: 20,
            child: pw.Text(
              line.marker,
              style: const pw.TextStyle(
                fontSize: 11.5,
                color: PdfColors.grey700,
              ),
            ),
          ),
          line.text,
          palette,
        ),
        PdfLineKind.bullet => _row(
          pw.SizedBox(
            width: 14,
            child: pw.Text('•', style: const pw.TextStyle(fontSize: 11.5)),
          ),
          line.text,
          palette,
        ),
      };

  static const _bodyStyle = pw.TextStyle(fontSize: 11.5, lineSpacing: 2.5);

  /// Satır içi biçimi (kalın/italik/altı çizili/renk/boyut/opaklık) taşıyan
  /// metin parçası.
  ///
  /// İşaretler artık SÖKÜLMÜYOR, çözümlenip PDF'e uygulanıyor (kullanıcı
  /// bulgusu 2026-08-08: "yazı biçimi de aktarılmıyor"). Çözümleme
  /// uygulamayla TEK kopya: `richSegments` — ekranda da aynı ayrıştırıcı
  /// çalışıyor, iki yerde ayrı yazılsaydı çıktı nottakine benzemezdi.
  static pw.Widget _rich(String text, pw.TextStyle base, List<int> palette) {
    final segments = richSegments(text);
    if (segments.length == 1 && segments.first.mark.isEmpty) {
      return pw.Text(text, style: base);
    }
    return pw.RichText(
      text: pw.TextSpan(
        style: base,
        children: [
          for (final seg in segments)
            pw.TextSpan(text: seg.text, style: _styleOf(base, seg.mark, palette)),
        ],
      ),
    );
  }

  static pw.TextStyle _styleOf(
    pw.TextStyle base,
    RichMark mark,
    List<int> palette,
  ) {
    // TUZAK: `richStepValue` indeks null iken son kademeyi döner — boyutta bu
    // 2.0'dır, yani biçimsiz metin iki katına çıkardı. Kademe yoksa çarpan 1.
    final size =
        (base.fontSize ?? 11.5) *
        (mark.size == null ? 1.0 : richStepValue(kRichSizeSteps, mark.size));
    final opacity = mark.opacity == null
        ? 1.0
        : richStepValue(kRichOpacitySteps, mark.opacity);
    final argb = mark.color == null || palette.isEmpty
        ? null
        : palette[(mark.color! - 1).clamp(0, palette.length - 1)];
    return base.copyWith(
      fontSize: size,
      fontWeight: mark.bold ? pw.FontWeight.bold : null,
      fontStyle: mark.italic ? pw.FontStyle.italic : null,
      decoration: mark.underline ? pw.TextDecoration.underline : null,
      color: argb == null
          ? (opacity < 1 ? PdfColor(0, 0, 0, opacity) : null)
          : PdfColor(
              ((argb >> 16) & 0xFF) / 255,
              ((argb >> 8) & 0xFF) / 255,
              (argb & 0xFF) / 255,
              opacity,
            ),
    );
  }

  static pw.Widget _row(
    pw.Widget leading,
    String text,
    List<int> palette, {
    bool strike = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            leading,
            pw.Expanded(
              child: _rich(
                text,
                pw.TextStyle(
                  fontSize: 11.5,
                  lineSpacing: 2.5,
                  color: strike ? PdfColors.grey600 : null,
                  decoration: strike ? pw.TextDecoration.lineThrough : null,
                ),
                palette,
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

/// [NotePdf._buildInIsolate]'a taşınan istek — tüm alanlar izoleler arası
/// gönderilebilir (String/ByteData/Uint8List).
class _PdfRequest {
  const _PdfRequest({
    required this.title,
    required this.content,
    required this.dateLabel,
    required this.images,
    required this.fontBytes,
    required this.boldBytes,
    required this.italicBytes,
    required this.palette,
    required this.format,
  });

  final String title;
  final String content;
  final String? dateLabel;
  final List<ExportImage> images;
  final ByteData fontBytes;
  final ByteData boldBytes;
  final ByteData italicBytes;

  /// Satır içi renklerin ARGB karşılıkları (palet indeksleri notta saklanıyor).
  final List<int> palette;
  final PdfPageFormat format;
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
