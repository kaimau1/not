import 'package:flutter/material.dart';

/// Metnin, üzerinde yüzen görsellerin ETRAFINDAN akmasını (Word'ün "kare
/// sarma"sı) sağlayan katman.
///
/// Flutter'ın satır kırıcısında "dışlama alanı" (exclusion rect) yoktur:
/// bir paragrafın her satırı aynı genişlikte kırılır. Kendi dizgicimizi
/// yazmak imleç/seçim/klavye(IME)/kopyala-yapıştır davranışlarını da elle
/// üstlenmek demek olurdu; bunun yerine görselin kestiği SATIRLARIN BAŞINA
/// görünmez bir dolgu (çapa) konur. Dolgu satırın genişliğini yer, kırıcı
/// kalan yere göre kırar — sonuç gerçek sarmadır, dizgici Flutter'da kalır.
///
/// Çapa, metin uzayında GERÇEK bir karakterdir (`￼`, OBJECT REPLACEMENT
/// CHARACTER). Bu şarttır: [TextEditingController.buildTextSpan] ile üretilen
/// span'in düz metni `controller.text` ile birebir aynı uzunlukta olmazsa
/// imleç ve seçim konumları kayar. Çapalar yalnız düzenleme tamponunda
/// yaşar; nota yazılan gövde [stripWrapAnchors] ile temizlenir.
///
/// SINIR: dolgu satır BAŞINA eklendiği için sarma yalnız SOL kenardaki
/// görseller için çalışır. Sağdaki bir görselin satırı sağdan kısaltması,
/// satır sonuna dolgu koymayı gerektirir; kırıcı o dolguya sıra gelmeden
/// satırı zaten kırdığı için bu mümkün değildir — sağa bırakılan görsel
/// [FloatBox.blocking] ile kendi satırını kaplar (metin üstünde/altında akar).
const String kWrapAnchorChar = '￼';
const int _kWrapAnchorCode = 0xFFFC;

/// Gövde metninin üzerinde yüzen bir görselin kapladığı dikey bant.
@immutable
class FloatBox {
  const FloatBox({
    required this.top,
    required this.width,
    required this.height,
    this.blocking = false,
  });

  /// Gövde metninin ilk satırının tepesinden uzaklık (dp). Negatif olabilir —
  /// görsel metnin başlamasından önce başlıyorsa ilk satırları da keser.
  final double top;

  /// Görselin metin sütununun SOL kenarından itibaren kapladığı genişlik (dp).
  /// Sarma bu kadar içeriden başlar.
  final double width;

  final double height;

  /// true ise görsel sütunun tamamını kapatır (sağa yaslı ya da sütunun
  /// çoğunu kaplayan görsel): kestiği satırlar tümüyle boşaltılır.
  final bool blocking;

  double get bottom => top + height;
}

/// [planTextWrap] sonucu: düzenleyiciye verilecek görüntü metni ve içindeki
/// çapaların (sırayla) genişlikleri.
@immutable
class WrapPlan {
  const WrapPlan(this.display, this.widths);

  final String display;
  final List<double> widths;

  bool get isEmpty => widths.isEmpty;
}

/// Metinden çapa karakterlerini söker. Nota/AI'a/dışa aktarmaya giden her
/// gövde bu süzgeçten geçer.
String stripWrapAnchors(String text) =>
    text.contains(kWrapAnchorChar) ? text.replaceAll(kWrapAnchorChar, '') : text;

/// [logical] metni [columnWidth] genişliğinde dizerken, [floats] görsellerinin
/// kestiği satırların başına ne genişlikte dolgu gerektiğini hesaplar.
///
/// Satırlar yukarıdan aşağı tek geçişte işlenir: bir satıra dolgu eklemek
/// yalnız ONDAN SONRAKİ satırların kırılımını değiştirdiği için, ekleme
/// sonrası aynı satır yeniden ölçülür ve geçiş kaldığı yerden sürer.
WrapPlan planTextWrap({
  required String logical,
  required TextStyle style,
  required double columnWidth,
  required List<FloatBox> floats,
  TextDirection direction = TextDirection.ltr,
  double textScaleFactor = 1.0,
}) {
  if (floats.isEmpty || logical.isEmpty || columnWidth <= 0) {
    return WrapPlan(logical, const []);
  }

  var display = logical;
  final widths = <double>[];
  final painter = TextPainter(
    textDirection: direction,
    textScaler: TextScaler.linear(textScaleFactor),
  );

  var line = 0;
  // Görsel sayısı azdır (not başına birkaç ek); tur sayısı satır sayısı +
  // eklenen dolgu kadardır. Tavan, beklenmedik bir kırılımda sonsuz döngüyü
  // engeller — aşılırsa o ana kadarki plan kullanılır (metin yine okunur).
  for (var guard = 0; guard < 512; guard++) {
    _layout(painter, display, widths, style, columnWidth);
    final metrics = painter.computeLineMetrics();
    if (line >= metrics.length) break;

    var top = 0.0;
    for (var i = 0; i < line; i++) {
      top += metrics[i].height;
    }
    final bottom = top + metrics[line].height;

    var indent = 0.0;
    var blocked = false;
    for (final f in floats) {
      if (f.top < bottom && top < f.bottom) {
        if (f.blocking) blocked = true;
        if (f.width > indent) indent = f.width;
      }
    }
    if (blocked) {
      // Sütunu kaplayan görsel: dolgu satırın tamamını yer, kırıcı o satıra
      // hiç kelime sığdıramaz ve metin görselin ALTINA iner. Satır başına
      // bir satır yüksekliği ilerlendiği için döngü görselin altında biter.
      indent = columnWidth;
    } else {
      // Yan yana akacak metne sütunun en az dörtte biri bırakılır; daha
      // darında metin harf harf kırılır ve okunmaz.
      final maxIndent = columnWidth * 0.75;
      if (indent > maxIndent) indent = maxIndent;
    }

    final start = _lineStartOffset(painter, display, top, metrics[line].height);
    final hasAnchor =
        start < display.length && display.codeUnitAt(start) == _kWrapAnchorCode;

    if (indent > 0 && !hasAnchor) {
      final anchorIndex = _anchorCountBefore(display, start);
      display = display.replaceRange(start, start, kWrapAnchorChar);
      widths.insert(anchorIndex, indent);
      continue; // aynı satırı yeni genişlikle yeniden ölç
    }
    line++;
  }

  painter.dispose();
  return WrapPlan(display, widths);
}

void _layout(
  TextPainter painter,
  String display,
  List<double> widths,
  TextStyle style,
  double columnWidth,
) {
  painter
    ..text = buildWrapSpan(display, widths, style)
    ..setPlaceholderDimensions([
      for (final w in widths)
        PlaceholderDimensions(
          size: Size(w, 0),
          alignment: PlaceholderAlignment.middle,
        ),
    ])
    ..layout(maxWidth: columnWidth);
}

/// Görüntü metnini, çapaları görünmez dolgu kutularına çevirerek span'e
/// dönüştürür. Ölçüm (TextPainter) ve çizim (TextField) aynı span'i kullanır;
/// ikisinin ayrışması imleç kaymasına yol açardı.
InlineSpan buildWrapSpan(String display, List<double> widths, TextStyle? style) {
  if (widths.isEmpty || !display.contains(kWrapAnchorChar)) {
    return TextSpan(text: display, style: style);
  }
  final parts = display.split(kWrapAnchorChar);
  final children = <InlineSpan>[TextSpan(text: parts.first, style: style)];
  for (var i = 1; i < parts.length; i++) {
    final w = i - 1 < widths.length ? widths[i - 1] : 0.0;
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(width: w, height: 0),
      ),
    );
    children.add(TextSpan(text: parts[i], style: style));
  }
  return TextSpan(style: style, children: children);
}

/// Dikeyde [top] ile başlayan satırın metindeki başlangıç konumu.
int _lineStartOffset(
  TextPainter painter,
  String display,
  double top,
  double height,
) {
  final pos = painter.getPositionForOffset(Offset(0, top + height / 2));
  final boundary = painter.getLineBoundary(pos);
  return boundary.start.clamp(0, display.length);
}

int _anchorCountBefore(String s, int offset) {
  var n = 0;
  for (var i = 0; i < offset && i < s.length; i++) {
    if (s.codeUnitAt(i) == _kWrapAnchorCode) n++;
  }
  return n;
}

/// Çapasız (mantıksal) metindeki konumu görüntü metnindeki konuma çevirir.
/// İmleç, görünmez dolgunun ARDINA konur — kullanıcı satır başında yazmaya
/// başladığında harf dolgunun soluna düşmez.
int wrapToDisplayOffset(String display, int logicalOffset) {
  var seen = 0;
  var i = 0;
  while (i < display.length && seen < logicalOffset) {
    if (display.codeUnitAt(i) != _kWrapAnchorCode) seen++;
    i++;
  }
  while (i < display.length && display.codeUnitAt(i) == _kWrapAnchorCode) {
    i++;
  }
  return i;
}

/// Görüntü metnindeki konumu çapasız (mantıksal) konuma çevirir.
int wrapToLogicalOffset(String display, int displayOffset) {
  final end = displayOffset.clamp(0, display.length);
  var seen = 0;
  for (var i = 0; i < end; i++) {
    if (display.codeUnitAt(i) != _kWrapAnchorCode) seen++;
  }
  return seen;
}

/// Gövde alanının denetleyicisi: kullanıcının yazdığı metni (mantıksal) ve
/// ekranda dizilen metni (çapalı) birbirine çevirir.
///
/// Kayan görsel yokken plan kimliktir ve denetleyici sıradan bir
/// [TextEditingController] gibi davranır (IME'nin oluşturma aralığı dahil
/// hiçbir şeye dokunulmaz) — sarma yalnız görsel varken devreye girer.
class WrapTextController extends TextEditingController {
  WrapTextController({super.text});

  List<double> _widths = const [];
  List<FloatBox> _floats = const [];
  TextStyle? _style;
  double _columnWidth = 0;
  double _textScale = 1.0;

  /// Nota yazılacak, çapasız gövde metni.
  String get logicalText => stripWrapAnchors(text);

  /// Kullanıcının gördüğü metni değiştirmeden dizgi girdilerini günceller
  /// (görsel taşınınca/boyutlanınca ya da sütun genişliği değişince).
  /// Girdiler aynıysa hiçbir şey yapmaz — her build'de çağrılabilir.
  void updateLayout({
    required List<FloatBox> floats,
    required TextStyle style,
    required double columnWidth,
    double textScaleFactor = 1.0,
  }) {
    if (_columnWidth == columnWidth &&
        _textScale == textScaleFactor &&
        _style == style &&
        _sameFloats(_floats, floats)) {
      return;
    }
    _floats = floats;
    _style = style;
    _columnWidth = columnWidth;
    _textScale = textScaleFactor;
    _reflow(logicalText, wrapToLogicalOffset(text, selection.baseOffset));
  }

  static bool _sameFloats(List<FloatBox> a, List<FloatBox> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].top != b[i].top ||
          a[i].width != b[i].width ||
          a[i].height != b[i].height ||
          a[i].blocking != b[i].blocking) {
        return false;
      }
    }
    return true;
  }

  /// Mantıksal metni doğrudan yazar (AI sonucu, geri alma, not yükleme...).
  @override
  set text(String newText) => _reflow(newText, newText.length);

  @override
  set value(TextEditingValue newValue) {
    if (_floats.isEmpty) {
      // Sarma yokken tampon kullanıcının metnidir; IME dokunulmadan geçer.
      _widths = const [];
      super.value = newValue;
      return;
    }
    final logical = stripWrapAnchors(newValue.text);
    final caret = wrapToLogicalOffset(
      newValue.text,
      newValue.selection.baseOffset < 0
          ? newValue.text.length
          : newValue.selection.baseOffset,
    );
    _reflow(logical, caret);
  }

  void _reflow(String logical, int logicalCaret) {
    final style = _style;
    if (style == null || _columnWidth <= 0 || _floats.isEmpty) {
      _widths = const [];
      final caret = logicalCaret.clamp(0, logical.length);
      super.value = TextEditingValue(
        text: logical,
        selection: TextSelection.collapsed(offset: caret),
      );
      return;
    }
    final plan = planTextWrap(
      logical: logical,
      style: style,
      columnWidth: _columnWidth,
      floats: _floats,
      textScaleFactor: _textScale,
    );
    _widths = plan.widths;
    final caret = wrapToDisplayOffset(
      plan.display,
      logicalCaret.clamp(0, logical.length),
    );
    super.value = TextEditingValue(
      text: plan.display,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_widths.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    // Oluşturma aralığı (IME altı çizgisi) sarma sırasında atlanır: çapalar
    // aralığın konumunu kaydırır ve altı çizili bölge yanlış yere düşer.
    return buildWrapSpan(text, _widths, style) as TextSpan;
  }
}
