import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/rich_text.dart';

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
/// SAĞ kenardaki görsel için dolgu satır SONUNA konur. Kırıcının dolguyu bir
/// alt satıra kaçırmaması için dolgudan önce bir KELİME BİRLEŞTİRİCİ
/// (U+2060 WORD JOINER) yazılır: birleştirici kendinden önce ve sonra satır
/// kırılmasını yasaklar, böylece dolgu satırın son kelimesine yapışır ve
/// kalan kelimeler bir alt satıra iner — satır sağdan kısalmış olur.
const String kWrapAnchorChar = '￼';
const int _kWrapAnchorCode = 0xFFFC;

/// Sağ kenar dolgusunu son kelimeye yapıştıran görünmez birleştirici.
const String kWrapGlueChar = '⁠';
const int _kWrapGlueCode = 0x2060;

/// Sarmanın metne bırakacağı en az genişlik (sütun oranı). Bundan darına
/// sıkıştırılan metin harf harf kırılıp okunmaz hâle gelir; o satırlar
/// tümüyle boşaltılır ve metin görselin ALTINA iner.
const double _kMinUsableFraction = 0.25;

/// Oranın yanında MUTLAK bir taban (dp): dar bir sütunda dörtte bir de birkaç
/// karaktere düşebiliyor. Yazı ölçeğiyle birlikte büyür.
const double _kMinUsableWidth = 72;

/// Gövde metninin üzerinde yüzen bir görselin kapladığı dikey bant.
///
/// Yatay sınırlar metin sütununun sol kenarına göredir: [left] görselin
/// başladığı, [right] bittiği nokta. Metin, görselin GENİŞ olan tarafından
/// akar (Word'ün dar boşluğa metin sıkıştırmaması gibi); iki yana birden
/// bölmek tek bir TextField'da mümkün değil.
@immutable
class FloatBox {
  const FloatBox({
    required this.top,
    required this.left,
    required this.right,
    required this.height,
  });

  /// Gövde metninin ilk satırının tepesinden uzaklık (dp). Negatif olabilir —
  /// görsel metnin başlamasından önce başlıyorsa ilk satırları da keser.
  final double top;

  /// Görselin metin sütununun sol kenarına göre sol/sağ sınırı (dp).
  final double left;
  final double right;

  final double height;

  double get bottom => top + height;
}

/// İki bant listesi aynı mı (gereksiz yeniden dizgiyi önlemek için).
bool sameFloatList(List<FloatBox> a, List<FloatBox> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].top != b[i].top ||
        a[i].left != b[i].left ||
        a[i].right != b[i].right ||
        a[i].height != b[i].height) {
      return false;
    }
  }
  return true;
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
    (text.contains(kWrapAnchorChar) || text.contains(kWrapGlueChar))
    ? text.replaceAll(kWrapAnchorChar, '').replaceAll(kWrapGlueChar, '')
    : text;

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
  RichTextTheme? rich,
}) {
  if (floats.isEmpty || columnWidth <= 0) {
    return WrapPlan(logical, const []);
  }

  var display = logical;
  final widths = <double>[];
  final painter = TextPainter(
    textDirection: direction,
    textScaler: TextScaler.linear(textScaleFactor),
  );

  var line = 0;
  // Sağ dolgusu bir kez denenmiş satırlar. Dolgu, kırıcı onu son kelimeye
  // yapıştıramazsa (ör. satırda hiç boşluk yok) bir daha denenmez — yoksa
  // aynı satır sonsuza dek yeniden dolgulanırdı.
  final rightPadded = <int>{};
  // Görsel sayısı azdır (not başına birkaç ek); tur sayısı satır sayısı +
  // eklenen dolgu kadardır. Tavan, beklenmedik bir kırılımda sonsuz döngüyü
  // engeller — aşılırsa o ana kadarki plan kullanılır (metin yine okunur).
  for (var guard = 0; guard < 512; guard++) {
    _layout(painter, display, widths, style, columnWidth, rich);
    final metrics = painter.computeLineMetrics();
    // Boş tamponun ölçülecek satırı yoktur ama imleç ilk satırdadır: soldaki
    // görsel onu sağa itmezse imleç görselin ÜSTÜNDE yanıp söner.
    if (line >= metrics.length && !(line == 0 && display.isEmpty)) break;

    var top = 0.0;
    for (var i = 0; i < line && i < metrics.length; i++) {
      top += metrics[i].height;
    }
    final lineHeight = line < metrics.length
        ? metrics[line].height
        : painter.preferredLineHeight;
    final bottom = top + lineHeight;

    // Satırı kesen görseller: her biri metni GENİŞ tarafına iter — soldaki
    // görsel satır başına, sağdaki satır sonuna dolgu koydurur.
    var indentStart = 0.0;
    var indentEnd = 0.0;
    for (final f in floats) {
      if (f.top < bottom && top < f.bottom) {
        if (columnWidth - f.right >= f.left) {
          if (f.right > indentStart) indentStart = f.right;
        } else {
          final pad = columnWidth - f.left;
          if (pad > indentEnd) indentEnd = pad;
        }
      }
    }
    if (indentStart < 0) indentStart = 0;
    if (indentEnd < 0) indentEnd = 0;
    if (indentStart + indentEnd > 0 &&
        columnWidth - indentStart - indentEnd <
            math.max(
              columnWidth * _kMinUsableFraction,
              _kMinUsableWidth * textScaleFactor,
            )) {
      // Kalan yer okunur bir satıra yetmiyor: dolgu satırın TAMAMINI yer,
      // kırıcı o satıra hiç kelime sığdıramaz ve metin görselin ALTINA iner.
      // Satır başına bir satır yüksekliği ilerlendiği için döngü görselin
      // altında biter.
      indentStart = columnWidth;
      indentEnd = 0;
    }

    final range = _lineRange(painter, display, top, lineHeight);
    final start = range.start;
    final hasStartAnchor =
        start < display.length && display.codeUnitAt(start) == _kWrapAnchorCode;

    if (indentStart > 0 && !hasStartAnchor) {
      display = display.replaceRange(start, start, kWrapAnchorChar);
      widths.insert(_anchorCountBefore(display, start), indentStart);
      continue; // aynı satırı yeni genişlikle yeniden ölç
    }

    // Satır zaten dar sütuna sığıyorsa dolguya gerek yok — sığan metni
    // kırmaya ya da aşağı itmeye kalkmak boşuna satır harcar.
    final lineWidth = line < metrics.length ? metrics[line].width : 0.0;
    final overflowsIntoFloat = lineWidth > columnWidth - indentEnd;

    if (indentEnd > 0 && overflowsIntoFloat && rightPadded.add(line)) {
      final cut = _rightPadOffset(
        painter,
        display,
        start,
        range.end,
        columnWidth - indentEnd,
        top + lineHeight / 2,
      );
      if (cut >= 0) {
        display = display.replaceRange(
          cut,
          cut,
          '$kWrapGlueChar$kWrapAnchorChar',
        );
        widths.insert(_anchorCountBefore(display, cut), indentEnd);
        continue;
      }
      // cut == -1: satırda kırılacak boşluk yok (tek uzun kelime). Sağa dolgu
      // konamıyor ve kelime görselin altından geçip üstüne biniyordu. Çözüm
      // soldaki geniş görselle aynı: satırı TÜMÜYLE boşalt, kelime bir alt
      // satıra insin. Görselin bandı bitene dek satırlar böyle boşaltılır.
      if (!hasStartAnchor) {
        display = display.replaceRange(start, start, kWrapAnchorChar);
        widths.insert(_anchorCountBefore(display, start), columnWidth);
        continue;
      }
    }
    line++;
  }

  painter.dispose();
  return WrapPlan(display, widths);
}

/// Satır sonu dolgusunun gireceği konum: [limitX]'e kadar sığan SON kelimenin
/// hemen ardı. Kelime bölünmez, dolgudan sonraki boşluk kırılma noktası olur.
/// Uygun yer yoksa -1.
int _rightPadOffset(
  TextPainter painter,
  String display,
  int start,
  int end,
  double limitX,
  double midY,
) {
  if (end <= start || limitX <= 0) return -1;
  var cut = painter
      .getPositionForOffset(Offset(limitX, midY))
      .offset
      .clamp(start, end);
  // Sınırın üstündeki kelimenin başına dön, sonra öndeki boşlukları at:
  // dolgu son harfin hemen ardına yapışmalı ki kırılma boşlukta olsun.
  while (cut > start && display.codeUnitAt(cut - 1) != 0x20) {
    cut--;
  }
  while (cut > start && display.codeUnitAt(cut - 1) == 0x20) {
    cut--;
  }
  return cut > start ? cut : -1;
}

void _layout(
  TextPainter painter,
  String display,
  List<double> widths,
  TextStyle style,
  double columnWidth,
  RichTextTheme? rich,
) {
  painter
    // Ölçüm de biçimi uygular: KALIN ve İTALİK metin daha geniş dizilir,
    // ölçüm bunu görmezse satırlar çizimden farklı kırılır ve imleç kayar.
    ..text = buildWrapSpan(display, widths, style, rich: rich)
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
/// [linkColor] verilirse metindeki bağlantılar renklendirilir. Ölçüm yolu
/// bunu null bırakır; renk ve alt çizgi satır genişliğini değiştirmediğinden
/// ölçüm ile çizim yine aynı planı üretir.
///
/// ponytail: sarma çapası bir adresin ORTASINA düşerse (çok uzun URL, görselin
/// yanında kırılıyorsa) adres iki parçaya bölünür ve o parçalar link sayılmaz;
/// sarmasız satırlarda ve normal uzunluktaki adreslerde sorun yok.
InlineSpan buildWrapSpan(
  String display,
  List<double> widths,
  TextStyle? style, {
  Color? linkColor,
  RichTextTheme? rich,
}) {
  List<InlineSpan> parts(String text) => rich == null
      ? linkSpans(text, style, linkColor)
      : richSpans(
          text,
          style,
          linkColor: linkColor,
          palette: rich.palette,
          markerColor: rich.markerColor,
        );

  if (widths.isEmpty || !display.contains(kWrapAnchorChar)) {
    final spans = parts(display);
    return spans.length == 1 && spans.first is TextSpan
        ? spans.first as TextSpan
        : TextSpan(style: style, children: spans);
  }
  final segments = display.split(kWrapAnchorChar);
  final children = <InlineSpan>[...parts(segments.first)];
  for (var i = 1; i < segments.length; i++) {
    final w = i - 1 < widths.length ? widths[i - 1] : 0.0;
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SizedBox(width: w, height: 0),
      ),
    );
    children.addAll(parts(segments[i]));
  }
  return TextSpan(style: style, children: children);
}

/// Biçimlendirmenin çizim ayarları. Ölçüm ve çizim AYNI değeri kullanmalı;
/// aksi hâlde kalın/italik metnin genişliği ikisinde ayrışır ve imleç kayar.
@immutable
class RichTextTheme {
  const RichTextTheme({required this.palette, required this.markerColor});

  /// Renk indeksinin (1..n) karşılığı renkler.
  final List<Color> palette;

  /// Biçim işaretlerinin (sönük) rengi.
  final Color markerColor;

  @override
  bool operator ==(Object other) =>
      other is RichTextTheme &&
      other.markerColor == markerColor &&
      other.palette.length == palette.length;

  @override
  int get hashCode => Object.hash(markerColor, palette.length);
}

/// Dikeyde [top] ile başlayan satırın metindeki aralığı.
({int start, int end}) _lineRange(
  TextPainter painter,
  String display,
  double top,
  double height,
) {
  if (display.isEmpty) return (start: 0, end: 0);
  final pos = painter.getPositionForOffset(Offset(0, top + height / 2));
  final boundary = painter.getLineBoundary(pos);
  final start = boundary.start.clamp(0, display.length);
  return (start: start, end: boundary.end.clamp(start, display.length));
}

int _anchorCountBefore(String s, int offset) {
  var n = 0;
  for (var i = 0; i < offset && i < s.length; i++) {
    if (s.codeUnitAt(i) == _kWrapAnchorCode) n++;
  }
  return n;
}

bool _isAnchorCode(int c) => c == _kWrapAnchorCode || c == _kWrapGlueCode;

/// Çapasız (mantıksal) metindeki konumu görüntü metnindeki konuma çevirir.
/// İmleç SATIR BAŞI dolgusunun ARDINA konur — kullanıcı satır başında yazmaya
/// başladığında harf (ve imleç) dolgunun soluna, yani görselin üstüne düşmez.
/// Satır SONU dolgusunun ise ÖNÜNDE kalır: imleç son harfin hemen ardında
/// durur, sütunun sağ kenarına atlamaz. İkisi birleştiriciyle ayırt edilir.
int wrapToDisplayOffset(String display, int logicalOffset) {
  var seen = 0;
  var i = 0;
  while (i < display.length && seen < logicalOffset) {
    if (!_isAnchorCode(display.codeUnitAt(i))) seen++;
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
    if (!_isAnchorCode(display.codeUnitAt(i))) seen++;
  }
  return seen;
}

/// Bir metin alanını sarar, alanın SAYFA üzerindeki yerini ölçer ve sayfa
/// uzayında verilen görsel bantlarını ([floats]) alanın kendi metin uzayına
/// çevirip denetleyicisine aktarır.
///
/// Gövde metni ve liste maddeleri aynı yolu kullanır: her alan kendi sol
/// kenarını ve genişliğini bildiğinden çağıranın kenar boşluğu/satır yüksekliği
/// hesaplaması gerekmez. Ölçüm yerleşimden SONRA yapılır (kare sonu), sonuç
/// değişmediyse [WrapTextController.updateLayout] hiçbir şey yapmaz — bu yüzden
/// her build'de çağrılması döngü yaratmaz.
class WrapFieldMeasure extends StatefulWidget {
  const WrapFieldMeasure({
    super.key,
    required this.controller,
    required this.style,
    required this.floats,
    required this.pageBox,
    required this.child,
  });

  final WrapTextController controller;
  final TextStyle style;

  /// Görsellerin sayfa uzayındaki bantları.
  final List<FloatBox> floats;

  /// Sayfa (tuval) içeriğinin kök kutusu — konumlar buna göre ölçülür.
  final RenderBox? Function() pageBox;

  final Widget child;

  @override
  State<WrapFieldMeasure> createState() => _WrapFieldMeasureState();
}

class _WrapFieldMeasureState extends State<WrapFieldMeasure> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return widget.child;
  }

  void _measure() {
    if (!mounted) return;
    // Görsel yok ve tampon zaten temiz: hiçbir şey ölçme. (Görsel silinince
    // bir kez daha ölçülür ki kalan çapalar temizlensin.)
    if (widget.floats.isEmpty && widget.controller.isPlain) return;
    final box = context.findRenderObject();
    final page = widget.pageBox();
    if (box is! RenderBox || !box.hasSize || page == null || !page.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: page);
    final width = box.size.width;
    if (width <= 0) return;
    final bottom = origin.dy + box.size.height;
    widget.controller.updateLayout(
      floats: [
        for (final f in widget.floats)
          // Alanı hiç kesmeyen görsel plana girmez: gereksiz yeniden dizgi
          // (ve uzun listede satır başına ölçüm) olmasın.
          if (f.bottom > origin.dy && f.top < bottom && f.right > origin.dx)
            FloatBox(
              top: f.top - origin.dy,
              left: (f.left - origin.dx).clamp(0.0, width).toDouble(),
              right: (f.right - origin.dx).clamp(0.0, width).toDouble(),
              height: f.height,
            ),
      ],
      style: widget.style,
      columnWidth: width,
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
    );
  }
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
  RichTextTheme? _rich;
  TextStyle? _style;
  double _columnWidth = 0;
  double _textScale = 1.0;

  /// Nota yazılacak, çapasız gövde metni.
  String get logicalText => stripWrapAnchors(text);

  /// Biçimlendirmenin çizim ayarları (renk paleti + işaret rengi). Tema
  /// bağımlı olduğu için dışarıdan verilir; değişince dizgi tazelenir çünkü
  /// kalın/italik metnin genişliği satır kırılımını etkiler.
  set richTheme(RichTextTheme? value) {
    if (_rich == value) return;
    _rich = value;
    if (_floats.isNotEmpty && _style != null && _columnWidth > 0) {
      _reflowKeepingSelection();
    }
  }

  /// Mantıksal metni ve imleç/seçim konumunu birlikte yazar (biçim uygulama).
  ///
  /// [extent] verilirse seçim KORUNUR: biçim uygulanan metin seçili kalır ve
  /// kullanıcı üst üste iki biçim verebilir (kalın + renk).
  void setLogical(String logical, int caret, [int? extent]) =>
      _reflow(logical, caret, extent);

  /// Metni değiştirmeden yeniden dizer; imleç VE seçim olduğu gibi kalır.
  ///
  /// KÖK NEDEN (v1.0.168): burası eskiden imleci topluyordu. Yazı tipi/boyut
  /// değişmek ya da bir görselin taşınması dizgiyi tazeliyor, tazeleme de
  /// kullanıcının seçimini siliyordu — sarma çapası bulunan bir notta metin
  /// seçmek imkânsızdı ("yazı tipi değiştiğinde sayfada yazıları seçemiyorum").
  void _reflowKeepingSelection() {
    final base = selection.baseOffset;
    final extent = selection.extentOffset;
    _reflow(
      logicalText,
      wrapToLogicalOffset(text, base < 0 ? text.length : base),
      extent < 0 || extent == base ? null : wrapToLogicalOffset(text, extent),
    );
  }

  /// Tamponda hiç dolgu yok (sarma kapalı) — sıradan bir denetleyici gibi.
  bool get isPlain => _widths.isEmpty;

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
        sameFloatList(_floats, floats)) {
      return;
    }
    _floats = floats;
    _style = style;
    _columnWidth = columnWidth;
    _textScale = textScaleFactor;
    _reflowKeepingSelection();
  }

  /// Mantıksal metni doğrudan yazar (AI sonucu, geri alma, not yükleme...).
  @override
  set text(String newText) => _reflow(newText, newText.length);

  @override
  set value(TextEditingValue newValue) {
    if (_floats.isEmpty) {
      // Sarma yokken tampon kullanıcının metnidir; IME dokunulmadan geçer —
      // yalnız imleç görünmez işaretin ortasına düşerse kenara çekilir.
      _widths = const [];
      super.value = _snapped(newValue);
      return;
    }
    var logical = stripWrapAnchors(newValue.text);
    final rawBase = newValue.selection.baseOffset < 0
        ? newValue.text.length
        : newValue.selection.baseOffset;
    final rawExtent = newValue.selection.extentOffset < 0
        ? rawBase
        : newValue.selection.extentOffset;
    var caret = wrapToLogicalOffset(newValue.text, rawBase);
    // Seçim (uzun basıp metin işaretleme) çapalı tamponda da korunur; yalnız
    // imleç taşınırsa extent null kalır.
    int? extent = rawExtent == rawBase
        ? null
        : wrapToLogicalOffset(newValue.text, rawExtent);
    // SATIR BAŞINDA GERİ SİLME: imleç satır başı dolgusunun hemen ardındadır,
    // dolayısıyla geri silme gerçek metni değil DOLGUYU siler. Eski hâlinde
    // dolgu bir sonraki dizgide yeniden konuyor, kullanıcıya "silme satır
    // başında duruyor, üst satıra geçmiyor" gibi görünüyordu. Mantıksal metin
    // hiç değişmeden tampon kısaldıysa niyet açıktır: ÖNCEKİ karakteri sil
    // (satır başındaki karakter satır sonu ise satırlar birleşir).
    if (logical == logicalText &&
        newValue.text.length < text.length &&
        caret > 0) {
      logical = logical.replaceRange(caret - 1, caret, '');
      caret--;
      extent = null;
    }
    // GÖRÜNMEZ BİÇİM İŞARETLERİ: imleç işaretin ortasına düşerse kullanıcıya
    // "imleç kıpırdamıyor / geri silme çalışmıyor" gibi görünür (silinen şey
    // görünmeyen bir yıldızdır). Konum gerçek bir karakterin sınırına, gidilen
    // yöne doğru çekilir.
    if (extent == null) {
      final previous = wrapToLogicalOffset(
        text,
        selection.baseOffset < 0 ? 0 : selection.baseOffset,
      );
      caret = snapOutOfMarkers(logical, caret, backward: caret < previous);
    }
    _reflow(logical, caret, extent);
  }

  /// Sarma KAPALIYKEN imleci görünmez işaretlerin dışına çeker (sarma açıkken
  /// aynı iş [value] içinde, çapasız uzayda yapılır).
  TextEditingValue _snapped(TextEditingValue newValue) {
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final previous = value.selection.baseOffset;
    final caret = snapOutOfMarkers(
      newValue.text,
      selection.baseOffset,
      backward: previous >= 0 && selection.baseOffset < previous,
    );
    if (caret == selection.baseOffset) return newValue;
    return newValue.copyWith(
      selection: TextSelection.collapsed(offset: caret),
      // Oluşturma aralığı (IME) kaydırılan imleçle tutarsız kalır.
      composing: TextRange.empty,
    );
  }

  void _reflow(String logical, int logicalCaret, [int? logicalExtent]) {
    final style = _style;
    // Aynı değeri yeniden yazmak seçim katmanını (tutamaklar, araç çubuğu)
    // yeniden kurar: boyut kaydırıcısı sürüklenirken her karede tazelenen
    // dizgi, tutamakların TİTREMESİNE yol açıyordu. Değişen bir şey yoksa
    // dokunma.
    if (style == null || _columnWidth <= 0 || _floats.isEmpty) {
      _widths = const [];
      final caret = logicalCaret.clamp(0, logical.length);
      final extent = logicalExtent?.clamp(0, logical.length);
      _write(
        TextEditingValue(
          text: logical,
          selection: extent == null || extent == caret
              ? TextSelection.collapsed(offset: caret)
              : TextSelection(baseOffset: caret, extentOffset: extent),
        ),
      );
      return;
    }
    final plan = planTextWrap(
      logical: logical,
      style: style,
      columnWidth: _columnWidth,
      floats: _floats,
      textScaleFactor: _textScale,
      rich: _rich,
    );
    _widths = plan.widths;
    final caret = wrapToDisplayOffset(
      plan.display,
      logicalCaret.clamp(0, logical.length),
    );
    final extent = logicalExtent == null
        ? null
        : wrapToDisplayOffset(
            plan.display,
            logicalExtent.clamp(0, logical.length),
          );
    _write(
      TextEditingValue(
        text: plan.display,
        selection: extent == null || extent == caret
            ? TextSelection.collapsed(offset: caret)
            : TextSelection(baseOffset: caret, extentOffset: extent),
      ),
    );
  }

  /// Değer gerçekten değiştiyse yazar (bkz. [_reflow] içindeki not).
  void _write(TextEditingValue next) {
    if (next.text == value.text && next.selection == value.selection) return;
    super.value = next;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Yazarken (IME oluşturma aralığı açıkken) span'e dokunulmaz: klavyenin
    // altı çizili öneri bölgesi bizim ürettiğimiz parçalarda kayardı. Metin
    // oturunca link rengi zaten gelir.
    final composing = withComposing && value.isComposingRangeValid;
    final linkColor = composing ? null : Theme.of(context).colorScheme.primary;
    if (_widths.isEmpty) {
      // Biçim işareti ya da bağlantı yoksa üst sınıfın span'i kullanılır
      // (IME davranışı olduğu gibi kalsın).
      if ((linkColor == null || findLinks(text).isEmpty) &&
          stripRichMarkers(text) == text) {
        return super.buildTextSpan(
          context: context,
          style: style,
          withComposing: withComposing,
        );
      }
      return buildWrapSpan(
            text,
            const [],
            style,
            linkColor: linkColor,
            rich: _rich,
          )
          as TextSpan;
    }
    // Oluşturma aralığı (IME altı çizgisi) sarma sırasında atlanır: çapalar
    // aralığın konumunu kaydırır ve altı çizili bölge yanlış yere düşer.
    return buildWrapSpan(
          text,
          _widths,
          style,
          linkColor: linkColor,
          rich: _rich,
        )
        as TextSpan;
  }
}
