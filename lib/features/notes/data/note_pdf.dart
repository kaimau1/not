import 'dart:io';
import 'dart:math' as math;

import 'dart:ui' show Color, Offset, Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../core/utils/rich_text.dart';
import '../../../core/utils/web_blob.dart';

/// Notu paylaşılabilir bir PDF'e çevirir (Syncfusion — uygulamadaki TEK PDF
/// yazma kütüphanesi; görüntüleme pdfrx'te).
///
/// Yerleşim elle yapılır: satır içi biçim (kalın/italik/renk/boyut) bir
/// satırda karışık yazı tipi ister, Syncfusion'ın hazır metin öğesi tek yazı
/// tipiyle çizer. Kelimeler ölçülüp satırlara dizilir, sayfa dolunca yeni
/// sayfaya geçilir.
///
/// Font gömmek zorunlu: hazır Helvetica WinAnsi kodlamalı, içinde ı ğ ş İ YOK.
abstract final class NotePdf {
  static const fontAsset = 'assets/fonts/PTSans-Regular.ttf';

  /// Kalın ve italik kesimler — sentezlenmez, dosyası verilmezse düz çıkar.
  static const boldFontAsset = 'assets/fonts/PTSans-Bold.ttf';
  static const italicFontAsset = 'assets/fonts/PTSans-Italic.ttf';

  /// PDF üretimi compute() izolesinde koşar (20 görselli not ana izolede
  /// saniyelerce kare düşürüyordu). Font baytları ve tarih etiketi ANA
  /// izolede hazırlanır — rootBundle ve yerel ayarlı DateFormat izolede yok.
  static Future<Uint8List> build({
    required String title,
    required String content,
    DateTime? date,
    List<ExportImage> images = const [],
    List<Color> palette = const [],
  }) async {
    final fontBytes = await rootBundle.load(fontAsset);
    final boldBytes = await rootBundle.load(boldFontAsset);
    final italicBytes = await rootBundle.load(italicFontAsset);
    final dateLabel = date == null ? null : DateFormat('d MMMM y').format(date);
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
        // `Color` izolede tema olmadan anlamsız: ARGB tamsayısı taşınır.
        palette: [for (final c in palette) c.toARGB32()],
      ),
    );
  }

  static Future<Uint8List> _buildInIsolate(_PdfRequest r) async {
    final w = _PdfWriter(r);
    w.render();
    return w.save();
  }

  /// Satır yüksekliği (punto + satır aralığı) — bir görselin YANINA kaç satır
  /// sığdığı bununla hesaplanır.
  static const _lineHeight = 16.0;

  /// Görsel metnin YANINA konabilir mi, konacaksa hangi kenara?
  /// Ortalanmış ya da genişliğin %70'inden büyük görsel float OLMAZ.
  static ExportAlign? _floatSide(ExportImage image) {
    final frac = (image.widthFraction ?? 1).clamp(0.1, 1.0);
    if (frac > 0.7) return null;
    return switch (image.align) {
      ExportAlign.left => ExportAlign.left,
      ExportAlign.right => ExportAlign.right,
      ExportAlign.center => null,
    };
  }

  /// Görselin sayfadaki ölçüsü (oran korunur, sayfaya sığdırılır).
  static ({double w, double h}) _imageSize(
    ExportImage image,
    double contentWidth,
    double maxHeight,
  ) {
    final iw = image.width <= 0 ? 480.0 : image.width.toDouble();
    final ih = image.height <= 0 ? 360.0 : image.height.toDouble();
    var w = contentWidth * (image.widthFraction ?? 1).clamp(0.1, 1.0);
    var h = w * ih / iw;
    if (h > maxHeight) {
      h = maxHeight;
      w = h * iw / ih;
    }
    return (w: w, h: h);
  }

  /// PDF'i geçici dosyaya yazar; hem önizleme hem paylaşma bunu kullanır.
  ///
  /// Web'de ÇAĞRILMAMALI: `dart:io File`/`path_provider` web'de gerçek bir
  /// dosya sistemine bağlı değil, çağrıldığında "Unsupported operation"
  /// fırlatırdı (kullanıcı bulgusu — PDF/görsel ekleme web'de patlıyordu).
  /// Web için bkz. [webBlobUrl].
  static Future<String> writeTemp(Uint8List bytes, String title) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${safeFileName(title)}.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Web karşılığı: dosyaya yazmak yerine bellekteki byte'ları bir
  /// `blob:` URL'ine sarar. Dönen URL, `Attachment.downloadUrl` alanına
  /// konup `isUploaded: true` işaretlenirse mevcut önizleyici/paylaşım
  /// akışları (Storage'dan gelen bir PDF'miş gibi) değişiklik gerektirmeden
  /// çalışır.
  static String webBlobUrl(Uint8List bytes) =>
      createBlobUrl(bytes, 'application/pdf');

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

  static final _checkboxPattern = RegExp(r'^\s*\[([ xX])\]\s*(.*)$');
  static final _numberedPattern = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');
  static final _bulletPattern = RegExp(r'^\s*[-•*]\s+(.*)$');
}

/// Sayfa sayfa yerleşim yapan yazıcı (bkz. [NotePdf]).
class _PdfWriter {
  _PdfWriter(this.r)
    : _regular = r.fontBytes.buffer.asUint8List(
        r.fontBytes.offsetInBytes,
        r.fontBytes.lengthInBytes,
      ),
      _bold = r.boldBytes.buffer.asUint8List(
        r.boldBytes.offsetInBytes,
        r.boldBytes.lengthInBytes,
      ),
      _italic = r.italicBytes.buffer.asUint8List(
        r.italicBytes.offsetInBytes,
        r.italicBytes.lengthInBytes,
      );

  final _PdfRequest r;
  final Uint8List _regular;
  final Uint8List _bold;
  final Uint8List _italic;

  static const _left = 52.0;
  static const _right = 52.0;
  static const _top = 56.0;
  static const _bottom = 44.0;
  static const _bodySize = 11.5;
  static const _bodySpacing = 2.5;

  final doc = PdfDocument();
  late PdfPage _page;
  double _y = _top;
  final _fonts = <String, PdfFont>{};

  double get _pageWidth => _page.getClientSize().width;
  double get _pageHeight => _page.getClientSize().height;
  double get _contentWidth => _pageWidth - _left - _right;

  /// Sayfa altındaki numara şeridi için ayrılan pay.
  double get _limit => _pageHeight - _bottom - 18;

  PdfFont _font(
    bool bold,
    bool italic,
    double size, {
    bool under = false,
    bool strike = false,
  }) {
    final key = '$bold$italic$size$under$strike';
    return _fonts[key] ??= PdfTrueTypeFont(
      bold ? _bold : (italic ? _italic : _regular),
      size,
      multiStyle: [
        if (under) PdfFontStyle.underline,
        if (strike) PdfFontStyle.strikethrough,
      ],
    );
  }

  void _newPage() {
    _page = doc.pages.add();
    _y = _top;
  }

  void _ensure(double h) {
    if (_y + h > _limit && _y > _top) _newPage();
  }

  void render() {
    doc.pageSettings.size = PdfPageSize.a4;
    doc.pageSettings.margins.all = 0;
    if (r.title.isNotEmpty) doc.documentInformation.title = r.title;
    _newPage();
    final title = r.title.trim();
    if (title.isNotEmpty) {
      _rich(title, 21, 2, _left, _contentWidth);
    }
    if (r.dateLabel != null) {
      _y += 4;
      _plain(r.dateLabel!, 9.5, PdfColor(117, 117, 117));
    }
    if (title.isNotEmpty || r.dateLabel != null) {
      _y += 12;
      _page.graphics.drawLine(
        PdfPen(PdfColor(189, 189, 189), width: 1),
        Offset(_left, _y),
        Offset(_pageWidth - _right, _y),
      );
      _y += 7;
    }
    _withImages(NotePdf.parseLines(r.content));
    _footers();
  }

  Uint8List save() {
    final bytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
    return bytes;
  }

  void _footers() {
    final count = doc.pages.count;
    final font = _font(false, false, 9);
    for (var i = 0; i < count; i++) {
      final page = doc.pages[i];
      final size = page.getClientSize();
      page.graphics.drawString(
        '${i + 1} / $count',
        font,
        brush: PdfSolidBrush(PdfColor(117, 117, 117)),
        bounds: Rect.fromLTWH(
          _left,
          size.height - _bottom - 12,
          size.width - _left - _right,
          12,
        ),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }
  }

  void _plain(String text, double size, PdfColor color) {
    final font = _font(false, false, size);
    final h = size * 1.3;
    _ensure(h);
    _page.graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(color),
      bounds: Rect.fromLTWH(_left, _y, _contentWidth, h),
    );
    _y += h;
  }

  /// Satırları ve görselleri nottaki sıraya göre birleştirir: her görsel,
  /// [ExportImage.line] ile verilen satırdan ÖNCE gelir.
  ///
  /// METİN GÖRSELİN YANINDAN AKAR: sayfa genişliğinin en çok %70'ini kaplayan
  /// ve bir kenara yaslı görsel FLOAT sayılır; yüksekliği kadar satır onun
  /// yanındaki sütuna dizilir. Ortalanmış ya da geniş görsel tam genişlik
  /// blok kalır. Görsel sayfanın yarısından uzunsa yanına konacak satır
  /// sayısı sayfaya sığacak kadarla sınırlanır.
  void _withImages(List<PdfLine> lines) {
    final placed = [
      for (final i in r.images)
        if (i.line != null) i,
    ]..sort((a, b) => a.line!.compareTo(b.line!));
    final trailing = [
      for (final i in r.images)
        if (i.line == null) i,
    ];
    final maxHeight = _limit - _top - 6;
    var next = 0;
    var index = 0;
    while (index < lines.length) {
      if (next < placed.length && placed[next].line! <= index) {
        final image = placed[next++];
        final size = NotePdf._imageSize(image, _contentWidth, maxHeight);
        final float = NotePdf._floatSide(image);
        final capacity = math.min(
          (size.h / NotePdf._lineHeight).floor(),
          (maxHeight * 0.5 / NotePdf._lineHeight).floor(),
        );
        final beside = <PdfLine>[];
        if (float != null && capacity > 0) {
          while (beside.length < capacity && index < lines.length) {
            if (next < placed.length && placed[next].line! <= index) break;
            beside.add(lines[index++]);
          }
        }
        if (beside.isEmpty) {
          _imageBlock(image, size);
          continue;
        }
        _ensure(size.h + 12);
        _y += 6;
        final top = _y;
        final imageLeft = float == ExportAlign.left
            ? _left
            : _pageWidth - _right - size.w;
        _drawImage(image, Rect.fromLTWH(imageLeft, top, size.w, size.h));
        final columnLeft = float == ExportAlign.left
            ? _left + size.w + 12
            : _left;
        final columnWidth = _contentWidth - size.w - 12;
        for (final l in beside) {
          _line(l, columnLeft, columnWidth);
        }
        _y = math.max(_y, top + size.h) + 6;
        continue;
      }
      _line(lines[index], _left, _contentWidth);
      index++;
    }
    for (; next < placed.length; next++) {
      final image = placed[next];
      _imageBlock(image, NotePdf._imageSize(image, _contentWidth, maxHeight));
    }
    for (final image in trailing) {
      _imageBlock(image, NotePdf._imageSize(image, _contentWidth, maxHeight));
    }
  }

  void _imageBlock(ExportImage image, ({double w, double h}) size) {
    _ensure(size.h + 12);
    _y += 6;
    final left = switch (image.align) {
      ExportAlign.left => _left,
      ExportAlign.right => _pageWidth - _right - size.w,
      ExportAlign.center => _left + (_contentWidth - size.w) / 2,
    };
    _drawImage(image, Rect.fromLTWH(left, _y, size.w, size.h));
    _y += size.h + 6;
  }

  /// PdfBitmap yalnız JPEG/PNG okur; başka biçim (WebP, GIF…) PNG'ye çevrilir.
  void _drawImage(ExportImage image, Rect bounds) {
    PdfBitmap? bitmap;
    try {
      bitmap = PdfBitmap(image.bytes);
    } catch (_) {
      final decoded = img.decodeImage(image.bytes);
      if (decoded == null) return;
      bitmap = PdfBitmap(img.encodePng(decoded));
    }
    _page.graphics.drawImage(bitmap, bounds);
  }

  void _line(PdfLine line, double x, double width) {
    switch (line.kind) {
      case PdfLineKind.blank:
        _y += 8;
      case PdfLineKind.paragraph:
        _rich(line.text, _bodySize, _bodySpacing, x, width);
        _y += 4;
      case PdfLineKind.checked || PdfLineKind.unchecked:
        final checked = line.kind == PdfLineKind.checked;
        _leading(
          x,
          width,
          18,
          line.text,
          strike: checked,
          draw: (y) {
            _checkbox(x, y + 2, checked);
          },
        );
      case PdfLineKind.numbered:
        _leading(
          x,
          width,
          20,
          line.text,
          draw: (y) {
            _page.graphics.drawString(
              line.marker,
              _font(false, false, _bodySize),
              brush: PdfSolidBrush(PdfColor(97, 97, 97)),
              bounds: Rect.fromLTWH(x, y, 20, _bodySize * 1.3),
            );
          },
        );
      case PdfLineKind.bullet:
        _leading(
          x,
          width,
          14,
          line.text,
          draw: (y) {
            _page.graphics.drawString(
              '•',
              _font(false, false, _bodySize),
              brush: PdfSolidBrush(PdfColor(0, 0, 0)),
              bounds: Rect.fromLTWH(x, y, 14, _bodySize * 1.3),
            );
          },
        );
    }
  }

  void _leading(
    double x,
    double width,
    double indent,
    String text, {
    bool strike = false,
    required void Function(double y) draw,
  }) {
    _ensure(_bodySize * 1.3 + _bodySpacing);
    final top = _y;
    final page = _page;
    _rich(
      text,
      _bodySize,
      _bodySpacing,
      x + indent,
      width - indent,
      strike: strike,
    );
    // Satır başı işareti metnin İLK satırıyla aynı sayfada.
    final saved = _page;
    _page = page;
    draw(top);
    _page = saved;
    _y += 5;
  }

  /// Onay kutusu glif değil çizim: PT Sans'ta ✓ ve ☐ YOK.
  void _checkbox(double x, double y, bool checked) {
    final g = _page.graphics;
    final box = Rect.fromLTWH(x, y, 11, 11);
    g.drawRectangle(
      pen: PdfPen(PdfColor(120, 144, 156), width: .8),
      brush: checked ? PdfSolidBrush(PdfColor(69, 90, 100)) : null,
      bounds: box,
    );
    if (checked) {
      final pen = PdfPen(PdfColor(255, 255, 255), width: 1.4);
      g
        ..drawLine(
          pen,
          Offset(x + 2.4, y + 11 - 5.6),
          Offset(x + 4.5, y + 11 - 3.2),
        )
        ..drawLine(
          pen,
          Offset(x + 4.5, y + 11 - 3.2),
          Offset(x + 8.6, y + 11 - 7.7),
        );
    }
  }

  /// Satır içi biçimi (kalın/italik/altı çizili/renk/boyut/opaklık) taşıyan
  /// metni [x]..[x]+[width] aralığına sarar. Çözümleme uygulamayla TEK kopya:
  /// `richSegments` — ekranda da aynı ayrıştırıcı çalışıyor.
  void _rich(
    String text,
    double baseSize,
    double spacing,
    double x,
    double width, {
    bool strike = false,
  }) {
    final runs = <_Run>[];
    for (final seg in richSegments(text)) {
      final run = _runStyle(seg.mark, baseSize, strike);
      for (final m in RegExp(r'\S+\s*|\s+').allMatches(seg.text)) {
        runs.add(_Run(m.group(0)!, run.font, run.brush, run.size, run.opacity));
      }
    }
    if (runs.isEmpty) {
      _y += baseSize * 1.3 + spacing;
      return;
    }
    var line = <(double, _Run)>[];
    var lineWidth = 0.0;
    var lineSize = baseSize;
    void flush() {
      final h = lineSize * 1.3 + spacing;
      _ensure(h);
      for (final (dx, run) in line) {
        _drawRun(run, x + dx, _y + (lineSize - run.size), h);
      }
      _y += h;
      line = [];
      lineWidth = 0;
      lineSize = baseSize;
    }

    for (var run in runs) {
      var w = run.font.measureString(run.text).width;
      final trimmed = run.font.measureString(run.text.trimRight()).width;
      if (lineWidth + trimmed > width && line.isNotEmpty) flush();
      // Tek kelime bile sığmıyorsa harf harf bölünür.
      while (trimmed > width && run.text.length > 1 && w > width) {
        var cut = run.text.length - 1;
        while (cut > 1 &&
            run.font.measureString(run.text.substring(0, cut)).width > width) {
          cut--;
        }
        line.add((0, run.copy(run.text.substring(0, cut))));
        lineSize = math.max(lineSize, run.size);
        flush();
        run = run.copy(run.text.substring(cut));
        w = run.font.measureString(run.text).width;
      }
      line.add((lineWidth, run));
      lineWidth += w;
      lineSize = math.max(lineSize, run.size);
    }
    if (line.isNotEmpty) flush();
  }

  void _drawRun(_Run run, double x, double y, double h) {
    final g = _page.graphics;
    if (run.opacity < 1) {
      g.save();
      g.setTransparency(run.opacity);
    }
    g.drawString(
      run.text,
      run.font,
      brush: run.brush,
      bounds: Rect.fromLTWH(
        x,
        y,
        run.font.measureString(run.text).width + 2,
        h,
      ),
    );
    if (run.opacity < 1) g.restore();
  }

  ({PdfFont font, PdfBrush brush, double size, double opacity}) _runStyle(
    RichMark mark,
    double base,
    bool strike,
  ) {
    // TUZAK: `richStepValue` indeks null iken son kademeyi döner — boyutta bu
    // 2.0'dır, yani biçimsiz metin iki katına çıkardı. Kademe yoksa çarpan 1.
    final size =
        base *
        (mark.size == null ? 1.0 : richStepValue(kRichSizeSteps, mark.size));
    final opacity = mark.opacity == null
        ? 1.0
        : richStepValue(kRichOpacitySteps, mark.opacity);
    final palette = r.palette;
    final argb = mark.color == null || palette.isEmpty
        ? null
        : palette[(mark.color! - 1).clamp(0, palette.length - 1)];
    final color = argb != null
        ? PdfColor((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF)
        : strike
        ? PdfColor(117, 117, 117)
        : PdfColor(0, 0, 0);
    return (
      font: _font(
        mark.bold,
        mark.italic,
        size,
        under: mark.underline,
        strike: strike,
      ),
      brush: PdfSolidBrush(color),
      size: size,
      opacity: opacity,
    );
  }
}

class _Run {
  const _Run(this.text, this.font, this.brush, this.size, this.opacity);

  final String text;
  final PdfFont font;
  final PdfBrush brush;
  final double size;
  final double opacity;

  _Run copy(String text) => _Run(text, font, brush, size, opacity);
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
