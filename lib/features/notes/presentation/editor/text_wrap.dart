import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Alandaki seçimin PANOYA gidecek hali: sarma çapaları VE biçim işaretleri
/// temizlenmiş düz metin.
///
/// Sistem Kopyala/Kes alanın HAM metnini yazar; editördeki kopyalama yolları
/// (seçim menüsü + Ctrl+C/X) bunun yerine burayı kullanır — yoksa `**kalın**`
/// işaretleri ve görünmez çapa karakterleri (U+FFFC/U+2060) dışarı sızar.
String clipboardTextOf(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid || selection.isCollapsed) return '';
  final logical = stripWrapAnchors(value.text);
  return plainSelection(
    logical,
    wrapToLogicalOffset(value.text, selection.start),
    wrapToLogicalOffset(value.text, selection.end),
  );
}

/// Seçim menüsündeki varsayılan Kes/Kopyala öğelerini temiz-metin
/// sürümleriyle değiştirir; diğer öğeler (Yapıştır, Tümünü Seç...) aynen
/// kalır. Gövde, başlık ve liste maddelerinin menüleri buradan geçer.
List<ContextMenuButtonItem> cleanClipboardMenuItems(EditableTextState state) =>
    [
      for (final item in state.contextMenuButtonItems)
        if (item.type == ContextMenuButtonType.copy)
          ContextMenuButtonItem(
            type: ContextMenuButtonType.copy,
            onPressed: () => cleanClipboardAction(state, cut: false),
          )
        else if (item.type == ContextMenuButtonType.cut)
          ContextMenuButtonItem(
            type: ContextMenuButtonType.cut,
            onPressed: () => cleanClipboardAction(state, cut: true),
          )
        else
          item,
    ];

/// Seçim menüsünden temiz Kopyala/Kes: panoya işaretsiz/çapasız metin gider;
/// kes ham aralığı alandan siler (onChanged tetiklenir, kayıt olağan yoldan
/// akar), kopya varsayılan mobil davranış gibi seçimi imlece indirir.
void cleanClipboardAction(EditableTextState state, {required bool cut}) {
  final value = state.textEditingValue;
  final selection = value.selection;
  if (!selection.isValid || selection.isCollapsed) {
    state.hideToolbar();
    return;
  }
  final text = clipboardTextOf(value);
  if (text.isNotEmpty) {
    Clipboard.setData(ClipboardData(text: text));
  }
  state.userUpdateTextEditingValue(
    cut
        ? TextEditingValue(
            text: value.text.replaceRange(selection.start, selection.end, ''),
            selection: TextSelection.collapsed(offset: selection.start),
          )
        : value.copyWith(
            selection: TextSelection.collapsed(offset: selection.end),
          ),
    SelectionChangedCause.toolbar,
  );
  state.hideToolbar();
}

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

    // Satırı kesen görseller: her biri metni GENİŞ tarafına iter.
    //
    // Görselin yeri FİZİKSELdir (ölçülen x), dolgu ise MANTIKSAL satır başına/
    // sonuna konan bir çapa karakteridir. LTR'de satır başı fiziksel solda,
    // RTL'de fiziksel sağdadır — bu eşleme çevrilmezse RTL'de dolgu görselin
    // BULUNMADIĞI tarafa konur ve metin görselin üstüne biner.
    final ltr = direction == TextDirection.ltr;
    var indentStart = 0.0;
    var indentEnd = 0.0;
    for (final f in floats) {
      if (f.top < bottom && top < f.bottom) {
        final hugsLeft = columnWidth - f.right >= f.left;
        final pad = hugsLeft ? f.right : columnWidth - f.left;
        if (hugsLeft == ltr) {
          if (pad > indentStart) indentStart = pad;
        } else {
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
        // Metnin durması gereken FİZİKSEL x. LTR'de satır soldan akar, sınır
        // sağdaki görselin solu; RTL'de satır sağdan akar, sınır soldaki
        // görselin sağıdır (yani soldan `indentEnd` kadar içeride).
        ltr ? columnWidth - indentEnd : indentEnd,
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
  /// Bu kare için ölçüm zaten sıraya girdi mi (bkz. aşağıdaki `idle`).
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    // Sarma yalnız görsel varken (ya da tamponda temizlenecek çapa kalmışken)
    // iş yapar; ikisi de yoksa kare-sonu geri çağrısı hiç kurulmaz. Alan
    // başına kare başına bir kapanış, uzun bir madde listesinde satır sayısı
    // kadar boş iş demekti.
    final idle = widget.floats.isEmpty && widget.controller.isPlain;
    if (!_scheduled && !idle) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    return widget.child;
  }

  void _measure() {
    _scheduled = false;
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
      // Yön dizginin kendisini etkiler: dolgu MANTIKSAL satır başına konur,
      // görselin yeri ise FİZİKSELdir (bkz. planTextWrap). Geçilmezse Arapça
      // gibi sağdan sola dillerde metin görselin üstüne biner.
      direction: Directionality.of(context),
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
  TextDirection _direction = TextDirection.ltr;

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
    TextDirection direction = TextDirection.ltr,
  }) {
    if (_columnWidth == columnWidth &&
        _textScale == textScaleFactor &&
        _style == style &&
        _direction == direction &&
        sameFloatList(_floats, floats)) {
      return;
    }
    _floats = floats;
    _style = style;
    _columnWidth = columnWidth;
    _textScale = textScaleFactor;
    _direction = direction;
    _reflowKeepingSelection();
  }

  /// Mantıksal metni doğrudan yazar (AI sonucu, geri alma, not yükleme...).
  @override
  set text(String newText) {
    clearPendingFormat();
    _reflow(newText, newText.length);
  }

  // ---- Bekleyen biçim ---------------------------------------------------

  /// Seçim yokken biçim düğmesine basıldığında metne DOKUNULMAZ; biçim burada
  /// bekler ve bir sonraki yazılan metin işaretlerin İÇİNE girer.
  ///
  /// KÖK NEDEN (kullanıcı: "yine biçim verirken işaretler çıkıyor… boşluğa
  /// veya satır sonuna yapınca"): eskiden metne boş kutu (`~~`, `__`) yazılıp
  /// imleç arasına konuyordu. İçine bir şey yazılmazsa o işaretler notta ham
  /// markdown olarak kalıyordu; üstelik gizleme kalıbı (`_emptyBoxPattern`)
  /// yalnız `****`/`==:==` gibi kutuları tanıdığı için italik ve altı çizili
  /// kutuları EKRANDA da görünüyordu. Kutuyu hiç yazmamak hem çöpü bitiriyor
  /// hem de kalıbı genişletip `__init__` gibi gerçek metni kırpma riskini
  /// doğurmuyor.
  /// BİRDEN ÇOK biçim aynı anda bekleyebilir (kullanıcı: "biçim alanı
  /// Keep'teki gibi olmalı… birden çok açılabilmeli, açılanlarla yazmaya
  /// devam etmeli"). Keep'te B, I ve U aynı anda basılı kalır ve yazılan
  /// metin üçünü birden alır. Ekleme sırası KORUNUR (LinkedHashMap): önce
  /// basılan biçim dışta sarar, böylece işaretler düzgün iç içe geçer.
  final Map<RichFormat, int?> _pending = {};
  int? _pendingAt;

  bool get hasPendingFormat => _pending.isNotEmpty;

  /// Bekleyen biçimler — şerit hangi düğmeyi "basılı" göstereceğini buradan
  /// da okur (metinden gelen biçimlerin YANINDA).
  Map<RichFormat, int?> get pendingFormats => Map.unmodifiable(_pending);

  /// Biçmi bekleyenlere ekler, zaten bekliyorsa KALDIRIR (aç/kapa).
  ///
  /// İmleç yer değiştirmişse önceki bekleyenler düşer: bekleme "buradan
  /// itibaren yazılacak metin" demektir, imleç taşınınca niyet de biter.
  void togglePendingFormat(RichFormat format, int? index) {
    // Aç/kapa kararı flush'tan ÖNCE verilir: flush bekleyenleri temizlediği
    // için sonra bakılsaydı kapatılan biçim yeniden açılırdı.
    final wasPending =
        _pending.containsKey(format) && _pending[format] == index;
    final carry = <RichFormat, int?>{..._pending};
    if (wasPending) {
      carry.remove(format);
    } else {
      carry[format] = index;
    }
    // KOŞU ORTASINDA biçim değişimi (Word'de "kalın yaz, kalını kapat, düz
    // devam et"): o ana kadar yazılmış metin ÖNCE işaretlerine kavuşur, imleç
    // kutunun DIŞINA çıkar, KALAN biçimler yeni koşuda sürer. Yoksa kapatılan
    // biçim yazılan metne hiç uygulanmaz — kullanıcı "kalın yazamıyorum" derdi.
    if (pendingRange != null) {
      flushPendingFormat(caretOutside: true);
    }
    final caret = selection.baseOffset;
    _pending
      ..clear()
      ..addAll(carry);
    _pendingAt = caret;
    _pendingEnd = caret;
    // Şerit denetleyiciyi dinliyor: basış ANINDA düğme yanmalı
    // ("basınca direkt aktifleştiği belli olmalı").
    notifyListeners();
  }

  void clearPendingFormat() {
    if (_pending.isEmpty && _pendingAt == null) return;
    _pending.clear();
    _pendingAt = null;
    _pendingEnd = null;
  }

  /// Koşunun O ANA KADAR yazılmış son ucu ([_pendingAt] başı, bu sonu).
  ///
  /// İmleç koşunun dışına taşındığında (kullanıcı metnin başka bir yerine
  /// dokundu) sarılacak aralık buradan okunur; yoksa o ana kadar yazılmış
  /// metin biçimsiz kalırdı.
  int? _pendingEnd;

  /// Bekleyen biçimin CANLI aralığı: `[başlangıç, imleç)`. Bu aralık tamponda
  /// İŞARETSİZ durur ama EKRANDA biçimli çizilir (bkz. [buildTextSpan]).
  ///
  /// KULLANICI İSTEĞİ ("kalın butonuna basıp kalın yazamıyorum... Word'deki
  /// gibi olmalı"): eskiden yazılan harfler işaretler tampona girene kadar DÜZ
  /// görünüyor, biçim ancak kelime bitince beliriyordu. Artık biçim basılır
  /// basılmaz ekranda: tampona hiç dokunulmadan, yalnız çizim stiliyle.
  (int, int)? get pendingRange {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    final sel = selection;
    if (!sel.isValid || !sel.isCollapsed) return null;
    final caret = sel.baseOffset;
    if (at < 0 || caret <= at || at > text.length || caret > text.length) {
      return null;
    }
    return (at, caret);
  }

  /// Bekleyen biçimlerin birikmiş hâli (canlı önizlemenin stili).
  RichMark get pendingMark {
    var mark = RichMark.none;
    for (final entry in _pending.entries) {
      mark = mark.applied(entry.key, entry.value);
    }
    return mark;
  }

  /// Bekleyen biçimi metne YAZAR — koşu BİTTİĞİNDE.
  ///
  /// Çağrı yerleri: alan odaktan çıkıyor, imleç koşunun dışına taşındı, biçim
  /// kümesi değişti ya da not kaydediliyor. Yazacak bir şey yoksa yalnız
  /// beklemeyi düşürür.
  /// [caretOutside] true ise imleç KAPANIŞ işaretlerinin ARDINA konur.
  /// Biçmi KAPATAN kullanıcı bunu ister: "kalın yaz, kalını kapat, düz devam
  /// et"te imleç kutunun içinde kalsaydı sonraki metin de kalın olurdu.
  void flushPendingFormat({bool caretOutside = false}) {
    final wrapped = _wrapRun(value, caretOutside: caretOutside);
    if (wrapped != null) {
      super.value = _snapped(wrapped);
      clearPendingFormat();
      notifyListeners();
    } else {
      clearPendingFormat();
    }
  }

  /// Koşuyu (`[_pendingAt, imleç)`) işaretlerin içine alır.
  ///
  /// KÖK NEDEN — TAMPONA KOŞU BOYUNCA HİÇ DOKUNULMAZ (2026-08-07 / 12. tur;
  /// kullanıcı: "yine markdownlar çıkıyor, kalın butonuna basıp kalın
  /// yazamıyorum"):
  ///
  /// Sarma önce "IME oluşturma aralığı bitti" anında, sonra KELİME SINIRINDA
  /// yapılıyordu. İkisi de aynı hataya düşüyor: Gboard bir koşu boyunca kendi
  /// metin modelini tutar ve oluşturma aralığını arada bir kapatıp yeniden
  /// açar (otomatik düzeltme, tahmin, imleç güncellemesi, boşluk sonrası
  /// yeniden açılış). Tampona o anlarda işaret sokmak klavyenin konumlarını
  /// KAYDIRIR; Gboard bir sonraki tuşta bayat konumuna yazınca işaretler
  /// metnin ortasına dağılır ve EŞİ KALMAYAN işaret ham markdown olarak
  /// çizilir (`richSpans` eşleşmeyen işareti düz karakter sayar).
  ///
  /// Artık işaret, kullanıcı koşuyu BİTİRENE kadar hiç yazılmaz — yazdığı
  /// metin ekranda [pendingRange] sayesinde zaten biçimli görünür. Yani
  /// tamponda koşu başına TEK müdahale kalır ve o da klavyenin koşuyu
  /// bıraktığı andan sonradır.
  /// [endOverride] verilirse koşunun sonu ORADAN okunur. Koşuyu bitiren olay
  /// imleci koşunun DIŞINA taşımış olabilir (kullanıcı metnin ilerisine
  /// dokundu); o zaman gelen imleç koşunun sonu DEĞİLDİR ve aradaki metin
  /// yanlışlıkla biçimin içine alınırdı.
  TextEditingValue? _wrapRun(
    TextEditingValue next, {
    int? endOverride,
    bool caretOutside = false,
  }) {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    if (at < 0 || at > next.text.length) return null;
    // Koşunun sonu: imleç hâlâ koşunun içindeyse oradan, dışına taşındıysa
    // en son bilinen uçtan (bkz. [_pendingEnd]).
    final caret = next.selection.baseOffset;
    final inRun =
        next.selection.isCollapsed && caret > at && caret <= next.text.length;
    final end = endOverride ?? (inRun ? caret : (_pendingEnd ?? at));
    if (end <= at || end > next.text.length) return null;
    final typed = next.text.substring(at, end);
    if (typed.isEmpty) return null;
    // Bekleyenler İÇ İÇE sarılır; önce basılan en DIŞTA kalır.
    //
    // KÖK NEDEN — SATIR SONU koşuyu BÖLER (2026-08-07 / 14. tur): biçim
    // kalıbı satır sonuyla eşleşmiyor (`dotAll: false` — biçim satırda başlar,
    // satırda biter). Koşu içinde Enter'a basılıp devam edildiğinde
    // `**abc\ndef**` yazılıyordu; hiçbir eşleşme çıkmadığı için İKİ işaret de
    // ham markdown olarak çiziliyor ve nota öyle kaydediliyordu. Her satır
    // parçası artık AYRI sarılır: `**abc**\n**def**`.
    //
    // KÖK NEDEN — KELİME SINIRI: italik (`_`) ve altı çizili (`~`) işaretleri
    // kalıpta "iki yanında harf/rakam olmasın" şartı taşıyor, ama YAZAN taraf
    // bunu denetlemiyordu. Kelimenin ortasından başlayan bir koşu
    // `_ilk_sonrasi` üretiyor, kalıp eşleştiremiyor ve alt çizgiler ham
    // görünüyordu. Sarma artık gereken yerde kelime sınırına GENİŞLER.
    final needsBoundary = _pending.keys.any(richFormatNeedsWordBoundary);
    var from = at;
    var to = end;
    if (needsBoundary) {
      while (from > 0 && isRichWordChar(next.text[from - 1])) {
        from--;
      }
      while (to < next.text.length && isRichWordChar(next.text[to])) {
        to++;
      }
    }
    final segment = next.text.substring(from, to);
    final wrapped = StringBuffer();
    var suffixLength = 0;
    final lines = segment.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) wrapped.write('\n');
      final line = lines[i];
      // Boş satır sarılmaz: `****` boş kutusu üretmenin âlemi yok.
      if (line.isEmpty) continue;
      var body = line;
      var suffixOfLine = 0;
      for (final entry in _pending.entries.toList().reversed) {
        final marker = entry.key.marker;
        final index = entry.value;
        final prefix = richFormatTakesIndex(entry.key) && index != null
            ? '$marker$index:'
            : marker;
        body = '$prefix$body$marker';
        suffixOfLine += marker.length;
      }
      wrapped.write(body);
      // İmleç eşlemesi SON satırın sonekine bakar: imleç koşunun sonunda,
      // yani son satırın kapanış işaretlerinin önünde/ardında durur. Solunda
      // kalan bütün işaretler `grown` içinde toplanır.
      if (i == lines.length - 1) suffixLength = suffixOfLine;
    }
    final body = wrapped.toString();
    if (body == segment) return null;
    // Kaydırma: koşunun İÇİNE giren toplam işaret uzunluğu.
    final grown = body.length - segment.length;
    // İmleç bütün kapanış işaretlerinin ÖNÜNDE durur: koşu bittiği için
    // gerekmez ama kullanıcı aynı yerden yazmaya devam ederse metin kutunun
    // dışına düşmesin (Keep davranışı). Biçim KAPATILDIĞINDA tam tersi
    // gerekir: imleç kutunun dışına çıkar.
    final movedSelection = _shiftOffset(
      next.selection,
      at: from,
      end: to,
      prefixLength: grown - suffixLength,
      suffixLength: suffixLength,
      caretOutside: caretOutside,
    );
    return TextEditingValue(
      text: next.text.replaceRange(from, to, body),
      selection: movedSelection,
    );
  }

  /// Sarma sonrası imleci/seçimi yeni metne taşır: koşudan ÖNCEKİ konumlar
  /// yerinde kalır, koşunun İÇİ önek kadar, SONRASI önek+sonek kadar kayar.
  static TextSelection _shiftOffset(
    TextSelection selection, {
    required int at,
    required int end,
    required int prefixLength,
    required int suffixLength,
    bool caretOutside = false,
  }) {
    int move(int o) {
      if (o <= at) return o;
      if (o < end) return o + prefixLength;
      if (o == end) {
        return o + prefixLength + (caretOutside ? suffixLength : 0);
      }
      return o + prefixLength + suffixLength;
    }

    final base = selection.baseOffset;
    if (base < 0) return selection;
    final extent = selection.extentOffset < 0 ? base : selection.extentOffset;
    return TextSelection(baseOffset: move(base), extentOffset: move(extent));
  }

  /// Yeni bir değer gelirken koşunun durumunu günceller; koşu BİTTİYSE
  /// işaretleri yazar.
  ///
  /// Koşu SÜRÜYOR sayılması için değişimin imleçte yapılmış saf bir
  /// ekleme/silme olması gerekir: metin uzunluğundaki değişim ile imlecin
  /// hareketi BİREBİR aynı olmalı. Bu ölçüt, "kullanıcı yazmaya devam etti"
  /// ile "kullanıcı başka bir yere dokundu / uzağa yapıştırdı" durumlarını
  /// ayırır — ayırmasaydı metnin ilerisine dokunmak aradaki bütün metni
  /// koşunun içine alır ve hepsi kalın olurdu.
  TextEditingValue? _trackPendingRun(TextEditingValue next) {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    final caret = next.selection.baseOffset;
    final end = _pendingEnd ?? at;
    // SAF DÜZENLEME: metin uzunluğundaki değişim ile imlecin hareketi BİREBİR
    // aynıysa kullanıcı imlecin olduğu yerde yazıyor ya da siliyor demektir.
    // (İmleç koşunun başının ALTINA da inebilir — geri silme; koşu oradan
    // yeniden başlar.)
    final lengthDelta = next.text.length - text.length;
    final caretDelta = caret - end;
    final isEdit =
        next.selection.isCollapsed &&
        caret >= 0 &&
        caret <= next.text.length &&
        lengthDelta == caretDelta;
    if (isEdit) {
      // Koşu sürüyor: tampona DOKUNULMAZ, yalnız uç güncellenir. (Geri silme
      // de buraya düşer; koşu kısalır ama biçim niyeti yaşamaya devam eder.)
      //
      // İmleç koşunun BAŞININ altına inerse (kullanıcı yazdıklarını silip
      // daha da geriye gitti) koşu ORADAN yeniden başlar: yoksa uç bir daha
      // başlangıcı geçemez, `_wrapRun` hep null döner ve düğme yanık dururken
      // yazılan metin düz kaydedilirdi.
      if (caret < at) _pendingAt = caret;
      _pendingEnd = caret;
      return null;
    }
    // Koşu bitti. Metin de değiştiyse (uzağa yapıştırma, toplu silme) sarma
    // güvenle yapılamaz: niyet düşer ve yazılan metin biçimsiz kalır —
    // yanlış yere işaret sokup eşi olmayan ham markdown üretmekten yeğdir.
    if (end <= at || end > text.length || next.text != text) {
      clearPendingFormat();
      return null;
    }
    final wrapped = _wrapRun(
      TextEditingValue(text: text, selection: next.selection),
      endOverride: end,
    );
    clearPendingFormat();
    return wrapped;
  }

  @override
  set value(TextEditingValue newValue) {
    final wrapped = _trackPendingRun(newValue);
    if (wrapped != null) newValue = wrapped;
    if (_floats.isEmpty) {
      // Sarma yokken tampon kullanıcının metnidir; IME dokunulmadan geçer —
      // yalnız imleç görünmez işaretin ortasına düşerse kenara çekilir ve
      // işareti silen geri-silme gerçek karaktere yönlendirilir.
      _widths = const [];
      final fixed = _markerDelete(text, newValue);
      if (fixed != null) {
        super.value = fixed;
        return;
      }
      super.value = _snapped(_collapsed(text, newValue));
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
      // Görünmez işareti silen geri-silme, metnin kendisine yönlendirilir
      // (sarmasız yoldaki [_markerDelete] ile aynı gerekçe).
      final oldLogical = logicalText;
      if (logical.length == oldLogical.length - 1 &&
          isMarkerOffset(oldLogical, caret)) {
        final fixed = deleteThroughMarkers(oldLogical, caret + 1);
        if (fixed != null) {
          _reflow(fixed.text, fixed.caret);
          return;
        }
      }
      if (logical.length < oldLogical.length) {
        final collapsed = collapseEmptyMarkersAt(logical, caret);
        logical = collapsed.text;
        caret = collapsed.caret;
      }
      final previous = wrapToLogicalOffset(
        text,
        selection.baseOffset < 0 ? 0 : selection.baseOffset,
      );
      caret = snapOutOfMarkers(logical, caret, backward: caret < previous);
    }
    _reflow(logical, caret, extent);
  }

  /// Silmeden sonra imlecin iki yanında BOŞ işaret çifti kaldıysa toplar.
  ///
  /// Biçimli bir kelimenin son harfi silinince geriye iç içe boş işaretler
  /// kalıyor; hiçbiri eşleşmediğinden düz metin gibi çiziliyor ve kullanıcı
  /// sildikçe yeni işaretler beliriyormuş gibi görünüyordu.
  TextEditingValue _collapsed(String oldText, TextEditingValue newValue) {
    if (newValue.text.length >= oldText.length) return newValue;
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final result = collapseEmptyMarkersAt(newValue.text, selection.baseOffset);
    if (result.text == newValue.text) return newValue;
    return TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.caret),
    );
  }

  /// Geri silme GÖRÜNMEZ bir işareti mi sildi? Öyleyse silme metnin kendisine
  /// yönlendirilir (bkz. [deleteThroughMarkers]); değilse null döner ve
  /// düzenleyicinin kendi silmesi geçerli kalır.
  TextEditingValue? _markerDelete(String oldText, TextEditingValue newValue) {
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    if (newValue.text.length != oldText.length - 1) return null;
    final deleted = selection.baseOffset;
    if (!isMarkerOffset(oldText, deleted)) return null;
    final fixed = deleteThroughMarkers(oldText, deleted + 1);
    if (fixed == null) return null;
    return TextEditingValue(
      text: fixed.text,
      selection: TextSelection.collapsed(offset: fixed.caret),
    );
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
      direction: _direction,
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

  /// "Metin düz mü" taramasının önbelleği. buildTextSpan her çizimde çağrılır
  /// ve klavye açılış animasyonu boyunca AYNI metin için kare başına tam
  /// findLinks + stripRichMarkers taraması yapıyordu ("klavye açılırken
  /// kasma"nın bir parçası). Metin değişmediyse sonuç yeniden kullanılır.
  String? _scanText;
  bool _scanHasLink = false;
  bool _scanHasMarker = false;

  void _scanPlainness() {
    if (_scanText == text) return;
    _scanText = text;
    _scanHasLink = findLinks(text).isNotEmpty;
    _scanHasMarker = stripRichMarkers(text) != text;
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
    TextSpan span;
    if (_widths.isEmpty) {
      // Biçim işareti ya da bağlantı yoksa üst sınıfın span'i kullanılır
      // (IME davranışı olduğu gibi kalsın).
      _scanPlainness();
      if ((linkColor == null || !_scanHasLink) && !_scanHasMarker) {
        span = super.buildTextSpan(
          context: context,
          style: style,
          withComposing: withComposing,
        );
      } else {
        span =
            buildWrapSpan(
                  text,
                  const [],
                  style,
                  linkColor: linkColor,
                  rich: _rich,
                )
                as TextSpan;
      }
    } else {
      // Oluşturma aralığı (IME altı çizgisi) sarma sırasında atlanır: çapalar
      // aralığın konumunu kaydırır ve altı çizili bölge yanlış yere düşer.
      span =
          buildWrapSpan(text, _widths, style, linkColor: linkColor, rich: _rich)
              as TextSpan;
    }
    return _withPendingPreview(span, style);
  }

  /// BEKLEYEN biçimin canlı önizlemesi: koşunun aralığı ekranda biçimli
  /// çizilir, tampona hiç dokunulmadan (bkz. [pendingRange]).
  ///
  /// Önizleme çizim uzayında yapılır; sarma çapalı tamponda da aynı uzay
  /// geçerlidir (çapalar gerçek karakterlerdir, uzunluk korunur).
  TextSpan _withPendingPreview(TextSpan span, TextStyle? style) {
    final range = pendingRange;
    if (range == null) return span;
    final palette = _rich?.palette ?? const <Color>[];
    final mark = pendingMark;
    final restyled = restyleRange(
      span,
      range.$1,
      range.$2,
      (current) =>
          markStyle(current ?? style ?? const TextStyle(), mark, palette),
    );
    return restyled is TextSpan ? restyled : span;
  }
}
