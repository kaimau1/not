import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/speech_segments.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/video_time.dart';

part 'text_wrap_controller.dart';

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

/// Bandın altındaki ilk boş satıra konan "imleç evi" dolgusunun genişliği.
/// Sıfır olamaz: sıfır genişlikte bir kutu dolu satıra da sığar ve imleç yine
/// üstteki dolgu satırının sağ ucunda kalırdı (bkz. [planTextWrap]).
const double _kCaretHomeWidth = 1;

/// Sağ kenar dolgusunu son kelimeye yapıştıran görünmez birleştirici.
const String kWrapGlueChar = '⁠';
const int _kWrapGlueCode = 0x2060;

/// Sarmanın metne bırakacağı en az genişlik (sütun oranı). Bundan darına
/// sıkıştırılan metin harf harf kırılıp okunmaz hâle gelir; o satırlar
/// tümüyle boşaltılır ve metin görselin ALTINA iner.
///
/// **0.25 → 0.35** (kullanıcı bulgusu 2026-08-10, ekran görüntüsü): sayfanın
/// ORTASINA konmuş bir görsel iki yanında da dörtte birden biraz fazla yer
/// bırakıyor, yani eski eşiği geçiyordu. Kalan şeritte satıra on beş karakter
/// sığıyor ve metin "NLDESB/" · "270726/0050/01" gibi parçalara bölünüyordu —
/// teknik olarak sarma çalışıyor, okunuşu bozuk. Sütunun en az üçte biri
/// kalmıyorsa metin artık görselin yanına sıkışmıyor, altına iniyor.
const double _kMinUsableFraction = 0.35;

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
    this.block = false,
  });

  /// Yanında okunur yer bırakmayan kutu: liste maddesi etrafından bölünerek
  /// akmaz, satırın tamamı altına iner (bkz. `_FloatRow`); gövde metni yine
  /// satır satır akar.
  final bool block;

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
        a[i].height != b[i].height ||
        a[i].block != b[i].block) {
      return false;
    }
  }
  return true;
}

/// [planTextWrap] sonucu: düzenleyiciye verilecek görüntü metni ve içindeki
/// çapaların (sırayla) genişlikleri.
@immutable
class WrapPlan {
  const WrapPlan(
    this.display,
    this.widths, {
    this.frozenDisplay = -1,
    this.frozenLogical = -1,
  });

  final String display;
  final List<double> widths;

  /// Planın görsel bandını KAPSAYAN öneki: `display[0, frozenDisplay)` ve
  /// onun mantıksal karşılığı `logical[0, frozenLogical)`. Önek bir
  /// PARAGRAF sonunda (satır sonu karakterinin önünde) biter ve bütün
  /// çapalar onun içindedir; ardından gelen metin görselin bandının altında
  /// kalır, dolgu almaz. -1 = önek yok (metnin tamamı ölçüldü).
  ///
  /// Neden: yazarken plan her tuşta yeniden kuruluyordu. Değişiklik önekin
  /// ÖTESİNDEYSE (görselin altında yazılıyorsa) önek birebir aynı kalır —
  /// plan yeniden ölçülmeden, önek + yeni kuyruk olarak kurulur (bkz.
  /// [WrapTextController]).
  final int frozenDisplay;
  final int frozenLogical;

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

/// `[top, bottom)` satırını kesen bantların o satıra bıraktığı dolgular:
/// [start] MANTIKSAL satır başına, [end] satır sonuna konacak genişlik.
///
/// Metin bandın GENİŞ olan tarafından akar (Word'ün dar boşluğa metin
/// sıkıştırmaması gibi). Kalan yer okunur bir satıra yetmiyorsa [start]
/// `columnWidth` döner: satırın tamamı dolgudur ve metin bandın ALTINA iner.
///
/// **İPUCU DA BURAYI ÇAĞIRIR** (bkz. `note_images.dart` → `hintPlacement`).
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-30, ekran görüntüsü: "imleç kaymıyor
/// ama ipucu başka yerde hâlâ"): bu karar iki yerde AYRI yazılmıştı ve
/// ORTADA duran bir görselde zıt sonuç veriyordu — plan `hugsLeft` ile metni
/// görselin sağına akıtırken, ipucu `left > 0` olan her görseli "sağ kenarda"
/// sayıp yalnız daraltıyor ve kendini ALTINA indiriyordu. Ölçüm (300 dp sütun,
/// bant left 35 → right 85): imleç dx 85 / dy 0, ipucu dx 0 / dy 60. Aynı
/// dikiş 16 ve 29 Ağustos'ta da patladığı için hesap tek kaynağa bağlandı.
({double start, double end}) wrapLineIndents({
  required List<FloatBox> floats,
  required double columnWidth,
  required double top,
  required double bottom,
  TextDirection direction = TextDirection.ltr,
  double textScaleFactor = 1.0,
}) {
  // Görselin yeri FİZİKSELdir (ölçülen x), dolgu ise MANTIKSAL satır başına/
  // sonuna konan bir çapa karakteridir. LTR'de satır başı fiziksel solda,
  // RTL'de fiziksel sağdadır — bu eşleme çevrilmezse RTL'de dolgu görselin
  // BULUNMADIĞI tarafa konur ve metin görselin üstüne biner.
  final ltr = direction == TextDirection.ltr;
  var start = 0.0;
  var end = 0.0;
  for (final f in floats) {
    if (f.right <= 0 || f.left >= columnWidth) continue;
    if (f.top < bottom && top < f.bottom) {
      final hugsLeft = columnWidth - f.right >= f.left;
      final pad = hugsLeft ? f.right : columnWidth - f.left;
      if (hugsLeft == ltr) {
        if (pad > start) start = pad;
      } else {
        if (pad > end) end = pad;
      }
    }
  }
  if (start < 0) start = 0;
  if (end < 0) end = 0;
  if (start + end > 0 &&
      columnWidth - start - end <
          math.max(
            columnWidth * _kMinUsableFraction,
            _kMinUsableWidth * textScaleFactor,
          )) {
    // Kalan yer okunur bir satıra yetmiyor: dolgu satırın TAMAMINI yer,
    // kırıcı o satıra hiç kelime sığdıramaz ve metin görselin ALTINA iner.
    return (start: columnWidth, end: 0.0);
  }
  return (start: start, end: end);
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

  // ---- YALNIZ BANDI KAPSAYAN ÖNEK ÖLÇÜLÜR --------------------------------
  //
  // KÖK NEDEN (kullanıcı 2026-10-16: "program genelinde yazı yazarken FPS
  // düşüşü", "görseller sürüklenirken aşırı kasma"): plan her turda METNİN
  // TAMAMINI diziyor ve satır başına bir tur dönüyordu — maliyet
  // O(satır × metin). Görselli bir notta HER TUŞTA (ve görsel sürüklenirken
  // HER KAREDE) koşuyor. Ölçüm (test ortamı): 700 karakter 45 ms,
  // 2.800 karakter 325 ms, 8.500 karakter ~2 sn.
  //
  // Dolgu yalnız görselin BANDINI kesen satırlara konur; bandın altındaki
  // satırların kırılımı plana hiçbir şey katmaz. Satır kırıcı açgözlüdür ve
  // bir PARAGRAF sonundan (satır sonu) önceki satırlar ondan sonra gelen
  // metinden etkilenmez (biçim işaretleri de satır sonunu aşmaz — bkz.
  // rich_text `_formatPattern`). Bu yüzden ölçüm, bandın altına en az iki
  // satır taşan bir paragraf önekiyle sınırlanır; önek yetmezse büyütülür.
  var bandBottom = -double.infinity;
  for (final f in floats) {
    if (f.bottom > bandBottom) bandBottom = f.bottom;
  }
  final fontSize = (style.fontSize ?? 14) * textScaleFactor;
  final lineGuess = fontSize * (style.height ?? 1.2);
  // Satıra sığan karakter tahmini BİLEREK cömert (dar harf ~0,3 em): önek
  // kısa gelirse ölçüm bir kez daha yapılır, uzun gelirse yalnız biraz
  // fazla metin dizilir.
  final charsPerLine = math.max(8, (columnWidth / (fontSize * 0.3)).ceil());
  var minChars =
      ((math.max(0.0, bandBottom) / lineGuess).ceil() + 4) * charsPerLine;
  int prefixEndFor(int from) {
    if (from >= display.length) return display.length;
    final nl = display.indexOf('\n', from);
    return nl < 0 ? display.length : nl;
  }

  var prefixEnd = prefixEndFor(minChars);

  /// [at] konumuna [s] eklenir; önekin sınırı da kayar.
  void insertAt(int at, String s) {
    display = display.replaceRange(at, at, s);
    if (at <= prefixEnd) prefixEnd += s.length;
  }

  var laidOut = false;

  /// `[start, end)` satırını bütünüyle boşaltır: varsa satır içi sağ
  /// dolgularını temizler (metin görselin altına inince eski kırılım
  /// kalmasın), satır başındaki dolguyu tam sütun genişliğine çıkarır.
  void emptyLine(int start, int end) {
    final safeStart = start.clamp(0, display.length);
    var safeEnd = end.clamp(safeStart, display.length);
    for (var i = safeEnd - 1; i > safeStart; i--) {
      if (display.codeUnitAt(i) == _kWrapAnchorCode &&
          display.codeUnitAt(i - 1) == _kWrapGlueCode) {
        final anchorIdx = _anchorCountBefore(display, i);
        if (anchorIdx < widths.length) widths.removeAt(anchorIdx);
        display = display.replaceRange(i - 1, i + 1, '');
        if (i - 1 < prefixEnd) {
          prefixEnd = math.max(0, prefixEnd - 2);
        }
        safeEnd = math.min(safeEnd, display.length);
        i--;
      }
    }
    final isStartAnchor =
        safeStart < display.length &&
        display.codeUnitAt(safeStart) == _kWrapAnchorCode &&
        (safeStart == 0 || display.codeUnitAt(safeStart - 1) != _kWrapGlueCode);
    final idx = _anchorCountBefore(display, safeStart);
    if (isStartAnchor && idx < widths.length && widths[idx] < columnWidth) {
      widths[idx] = columnWidth;
    } else {
      insertAt(safeStart, kWrapAnchorChar);
      widths.insert(idx, columnWidth);
    }
    laidOut = false;
  }

  var metrics = const <LineMetrics>[];
  void layoutPrefix() {
    for (;;) {
      final text = prefixEnd >= display.length
          ? display
          : display.substring(0, prefixEnd);
      final anchors = prefixEnd >= display.length
          ? widths.length
          : _anchorCountBefore(display, prefixEnd);
      _layout(
        painter,
        text,
        anchors >= widths.length ? widths : widths.sublist(0, anchors),
        style,
        columnWidth,
        rich,
      );
      if (prefixEnd >= display.length ||
          painter.height >= bandBottom + painter.preferredLineHeight * 2) {
        break;
      }
      minChars = math.max(minChars * 2, prefixEnd + 1);
      prefixEnd = prefixEndFor(minChars);
    }
    metrics = painter.computeLineMetrics();
  }

  var line = 0;
  // Satır başı LTR'de fiziksel solda, RTL'de sağdadır (bkz. [wrapLineIndents]).
  final ltr = direction == TextDirection.ltr;
  // Sağ dolgusu bir kez denenmiş satırlar. Dolgu, kırıcı onu son kelimeye
  // yapıştıramazsa (ör. satırda hiç boşluk yok) bir daha denenmez — yoksa
  // aynı satır sonsuza dek yeniden dolgulanırdı.
  final rightPadded = <int>{};
  // Görsel sayısı azdır (not başına birkaç ek); tur sayısı satır sayısı +
  // eklenen dolgu kadardır. Tavan, beklenmedik bir kırılımda sonsuz döngüyü
  // engeller — aşılırsa o ana kadarki plan kullanılır (metin yine okunur).
  for (var guard = 0; guard < 512; guard++) {
    if (!laidOut) {
      layoutPrefix();
      laidOut = true;
    }

    // SATIR TEPESİ `LineMetrics`TEN TOPLANMAZ (kullanıcı bulgusu 2026-08-30,
    // ekran görüntüsü: imleç yazının çok altında):
    // `forceStrutHeight: true` her satırı taban stilin yüksekliğine kilitler,
    // ama `LineMetrics.height` KİLİTLENMEMİŞ boyu bildiriyor — yalnız dolgu
    // taşıyan bir satır için bu, dolgu kutusunun boyudur ([wrapAnchorHeight],
    // yarım punto). Ölçüm: 30 dolgu satırı `metrics[i].height`e göre 7 dp
    // (toplam 210) ama boyacının gerçek boyu 600 dp, yani 30 × 20. Toplam
    // 20/7 kat kayıyor ve plan bandı aşmak için gereken satır sayısını üçe
    // katlayarak sayıyordu. Çıpa kilitli olduğu için satır adımı SABİTTİR.
    final lineHeight = painter.preferredLineHeight;
    final top = line * lineHeight;
    final bottom = top + lineHeight;

    // Satır bütün bantların ALTINDA: buradan sonraki hiçbir satır dolgu
    // almaz (bkz. [wrapLineIndents]) — eski geçiş metnin sonuna kadar boşuna
    // yürüyordu. Boş tamponun imleç evi dalı (aşağıda) bandın altında da iş
    // görür; o yüzden yalnız metin varken.
    if (logical.isNotEmpty && top >= bandBottom) break;

    // Satırı kesen görsellerin bu satıra bıraktığı dolgular. İPUCU DA AYNI
    // İŞLEVİ ÇAĞIRIR (bkz. [wrapLineIndents]).
    final indents = wrapLineIndents(
      floats: floats,
      columnWidth: columnWidth,
      top: top,
      bottom: bottom,
      direction: direction,
      textScaleFactor: textScaleFactor,
    );
    final indentStart = indents.start;
    final indentEnd = indents.end;

    // ---- TAMPONUN SONU: satır yok ama İMLEÇ var ---------------------------
    //
    // KÖK NEDEN (kullanıcı bulgusu 2026-08-29 — "klavyeyi bir kez açıp
    // kapatınca imleç kayboldu, yazamadım; sonra fark ettim ki yazı görselin
    // arkasına geçmiş"): aşağıdaki geçiş metnin VAR OLAN satırlarını iter ve
    // satır başına bir satır ilerler, yani yeterince metin varsa döngü
    // görselin altında biter. Boş (ya da görselin bandından KISA) tamponda
    // itilecek satır yoktur: eski kod tek bir dolgu satırı ekleyip duruyordu,
    // imleç 400 px'lik görselin altına değil yalnız BİR satır aşağı iniyordu —
    // yani hâlâ görselin arkasında. İpucu metni ise ayrı bir yoldan
    // (`hintPlacement`) görselin ALTINA konduğu için ipucu bir yeri, imleç
    // başka yeri gösteriyordu.
    //
    // Çözüm: tampon bittiğinde durma; imlecin oturduğu SANAL satır hâlâ bir
    // bandı kesiyorsa dolgu eklemeye devam et. Bant bitince [indentStart] 0
    // olur ve döngü kendiliğinden kapanır.
    if (line >= metrics.length) {
      // BU DAL YALNIZ BOŞ TAMPON YA DA SONDAKİ BOŞ SATIR (`...\n`) İÇİNDİR:
      // metnin son satırında Enter ile tam genişlik görselin bandına inilince
      // imleç görselin altında ve satır başında yanıp sönsün.
      final trailingBlankPushed =
          logical.endsWith('\n') &&
          display.isNotEmpty &&
          display.codeUnitAt(display.length - 1) == _kWrapAnchorCode &&
          widths.isNotEmpty &&
          widths.last >= columnWidth;
      if (logical.isNotEmpty && !trailingBlankPushed) break;
      if (indentStart <= 0) {
        // BANT BİTTİ — imlecin oturacağı satır artık boşta. Ama tamponun
        // sonundaki dolgular satırı TAMAMEN kapladıysa "metnin sonu" konumu o
        // satırın SAĞ UCUDUR: imleç görselin bittiği yerin solunda değil,
        // sütunun sağ kenarında yanıp sönerdi. Bandın altındaki ilk boş satıra
        // saç teli genişliğinde bir çapa konur — kırıcı onu alt satıra atar
        // (dolu satıra 1 dp bile sığmaz), imleç de ipucunun ("Not…") çizildiği
        // yere, satır başına oturur.
        if (display.isNotEmpty &&
            display.codeUnitAt(display.length - 1) == _kWrapAnchorCode &&
            widths.isNotEmpty &&
            widths.last >= columnWidth) {
          insertAt(display.length, kWrapAnchorChar);
          widths.add(_kCaretHomeWidth);
          laidOut = false;
        }
        break;
      }
      // Dolgu metnin SONUNA eklenir (bu satırın "başı" orasıdır); çapa
      // sırası korunduğu için genişlik de listenin sonuna gider.
      insertAt(display.length, kWrapAnchorChar);
      widths.add(indentStart);
      laidOut = false;
      // Görselin YANINDA okunur yer varsa imleç oraya oturdu, iş bitti —
      // dar bir görsel imleci gereksiz yere aşağı itmemeli.
      if (indentStart < columnWidth) break;
      // Satırın tamamı kapalı: imleç hâlâ görselin arkasında, bir alt
      // satırdan devam et.
      continue;
    }

    final range = _lineRange(painter, display, top, lineHeight);
    final start = range.start;
    final hasStartAnchor =
        start < display.length && display.codeUnitAt(start) == _kWrapAnchorCode;

    if (indentStart > 0 && !hasStartAnchor) {
      insertAt(start, kWrapAnchorChar);
      widths.insert(_anchorCountBefore(display, start), indentStart);
      laidOut = false;
      continue; // aynı satırı yeni genişlikle yeniden ölç
    }

    // Satır zaten dar sütuna sığıyorsa dolguya gerek yok — sığan metni
    // kırmaya ya da aşağı itmeye kalkmak boşuna satır harcar.
    final m = line < metrics.length ? metrics[line] : null;
    final overflowsIntoFloat =
        m != null &&
        (ltr
            ? m.left + m.width > columnWidth - indentEnd + 0.5
            : m.left < indentEnd - 0.5);

    if (indentEnd > 0 && overflowsIntoFloat && rightPadded.add(line)) {
      final startIdx = _anchorCountBefore(display, start);
      final startAnchorWidth = hasStartAnchor && startIdx < widths.length
          ? widths[startIdx]
          : 0.0;
      final cut = _rightPadOffset(
        painter,
        display,
        start,
        range.end,
        columnWidth: columnWidth,
        indentEnd: indentEnd,
        startAnchorWidth: startAnchorWidth,
        ltr: ltr,
        midY: top + lineHeight / 2,
      );
      if (cut >= 0) {
        insertAt(cut, '$kWrapGlueChar$kWrapAnchorChar');
        widths.insert(_anchorCountBefore(display, cut), indentEnd);
        laidOut = false;
        continue;
      }
      // cut == -1: satırda kırılacak yer yok (tek uzun kelime ya da sol+sağ
      // görseller arası çok dar). Satır bütünüyle boşaltılır, metin alt
      // satıra iner.
      emptyLine(start, range.end);
      continue;
    }
    line++;
  }

  // ---- SON DENETİM: hiçbir satır görselin ÜSTÜNE binmemeli ---------------
  //
  // KÖK NEDEN (kullanıcı bulgusu 2026-08-10 — "metin modunda görselin altında
  // kalıyor", ekran görüntüsünde satırın bir bölümü görselin arkasında):
  // yukarıdaki geçiş dolguyu satır SIRASINA göre koyuyor ve bir satıra dolgu
  // eklemek SONRAKİ satırların kırılımını değiştiriyor. Kimi durumda satır
  // dolgusuz kalıyordu — en belirgini, satır sonu dolgusunun (birleştirici +
  // çapa) kırıcı tarafından bir alt satırın BAŞINA atılması: o satır artık
  // "başında çapa var" sayıldığı için satır başı dolgusu da almıyor ve metin
  // görselin bandına giriyordu. Görseller metnin ÜSTÜNE çizildiğinden o
  // satırlar okunmaz oluyordu.
  //
  // Burada plan bir kez daha ölçülür ve satırların GERÇEK kutuları görsel
  // bantlarıyla karşılaştırılır; hâlâ binen satır tümüyle boşaltılır (metin
  // görselin altına iner). Düzgün sarılmış satırlara dokunulmaz — yalnız
  // gerçekten binenlere. Her düzeltme bir satırı boşalttığı için ilerleme
  // garantili: boşalan satırda metin kalmaz, bir sonraki turda atlanır.
  //
  // SATIRLAR MOTORDAN OKUNUR, SAYILARAK BULUNMAZ: satır aralıkları
  // `getLineBoundary` ile metnin başından yürünerek çıkarılır. İlk sürüm
  // satır tepelerini `LineMetrics.height` toplayarak buluyordu; boşaltılmış
  // satır (yalnız çapa taşıyan) metinli satırdan KISA olabildiği için o
  // toplam kayıyor, `_lineRange` başka bir satırı döndürüyor ve binen satır
  // denetimden kaçıyordu (CI'da yakalandı). Dikey karşılaştırma da kutuların
  // kendi üst/altını kullanır — hiçbir yerde tahmin yok.
  for (var pass = 0; pass < 128; pass++) {
    if (!laidOut) {
      layoutPrefix();
      laidOut = true;
    }
    var repaired = false;
    var offset = 0;
    // Yalnız ÖLÇÜLEN önek denetlenir (bandı kapsıyor, bkz. [layoutPrefix]).
    final measured = math.min(prefixEnd, display.length);
    while (offset < measured) {
      final boundary = painter.getLineBoundary(TextPosition(offset: offset));
      final start = boundary.start.clamp(0, measured);
      final end = boundary.end.clamp(start, measured);
      offset = end > offset ? end : offset + 1;
      final text = _lineTextRange(display, (start: start, end: end));
      if (text == null) continue; // satırda çizilen metin yok
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: text.start, extentOffset: text.end),
      );
      if (boxes.isEmpty) continue;
      var left = double.infinity;
      var right = -double.infinity;
      var boxTop = double.infinity;
      var boxBottom = -double.infinity;
      for (final box in boxes) {
        if (box.left < left) left = box.left;
        if (box.right > right) right = box.right;
        if (box.top < boxTop) boxTop = box.top;
        if (box.bottom > boxBottom) boxBottom = box.bottom;
      }
      // Satırlar yukarıdan aşağı gelir: bandların altına inen ilk satırdan
      // sonra hiçbir satır görsele binemez.
      if (boxTop >= bandBottom) break;
      // Bir dp'lik pay: dolgu tam görselin kenarında bittiğinde yuvarlama
      // farkı yüzünden satırı boşuna aşağı itmeyelim.
      final hits = floats.any(
        (f) =>
            f.top < boxBottom &&
            boxTop < f.bottom &&
            right > f.left + 1 &&
            left < f.right - 1,
      );
      if (!hits) continue;
      emptyLine(start, end);
      repaired = true;
      break; // düzen değişti: baştan ölç
    }
    if (!repaired) break;
  }

  painter.dispose();
  if (prefixEnd >= display.length) return WrapPlan(display, widths);
  var invisible = 0;
  for (var i = 0; i < prefixEnd; i++) {
    if (_isAnchorCode(display.codeUnitAt(i))) invisible++;
  }
  return WrapPlan(
    display,
    widths,
    frozenDisplay: prefixEnd,
    frozenLogical: prefixEnd - invisible,
  );
}

/// Önceki plan [previous] ([previousLogical] için kurulmuş), [logical]
/// için de geçerliyse önek + yeni kuyruk olarak yeniden kullanır; değilse
/// null. Geçerlilik: iki metin önekin sonundaki satır sonu DAHİL aynı —
/// değişiklik görselin bandının altında kalmış (bkz. [WrapPlan.frozenDisplay]).
/// Plan girdilerinin (stil, genişlik, bantlar) aynı olduğunu çağıran sağlar.
WrapPlan? reuseWrapPlan(
  WrapPlan previous,
  String previousLogical,
  String logical,
) {
  final fl = previous.frozenLogical;
  if (fl < 0 || fl >= logical.length || fl >= previousLogical.length) {
    return null;
  }
  if (logical.codeUnitAt(fl) != 0x0A) return null;
  // Kısa yol: önek gerçekten aynı mı (satır sonu dahil).
  for (var i = fl; i >= 0; i--) {
    if (logical.codeUnitAt(i) != previousLogical.codeUnitAt(i)) return null;
  }
  return WrapPlan(
    previous.display.substring(0, previous.frozenDisplay) +
        logical.substring(fl),
    previous.widths,
    frozenDisplay: previous.frozenDisplay,
    frozenLogical: fl,
  );
}

/// Satırın ÇİZİLEN metin aralığı: baştaki/sondaki görünmez karakterler
/// (çapa, birleştirici, satır sonu) ve BOŞLUKLAR dışarıda bırakılır. Metin
/// kalmıyorsa null.
///
/// Boşluklar neden dışarıda: yumuşak satır sonundaki boşluk sarma sınırının
/// ÖTESİNE yerleştirilir (Flutter satır sonu boşluğunu satır genişliğine
/// saymaz ama kutusunu üretir). O kutuya bakıp "satır görsele bindi" demek
/// sahte alarm olurdu — ekranda görünen bir şey yok. Binme sorusunun cevabı
/// yalnız GÖRÜNÜR harflerdir.
({int start, int end})? _lineTextRange(
  String display,
  ({int start, int end}) range,
) {
  bool invisible(int code) =>
      code == _kWrapAnchorCode ||
      code == _kWrapGlueCode ||
      code == 0x0A || // \n
      code == 0x0D || // \r
      code == 0x09 || // sekme
      code == 0x20; // boşluk
  var start = range.start;
  var end = range.end;
  while (start < end && invisible(display.codeUnitAt(start))) {
    start++;
  }
  while (end > start && invisible(display.codeUnitAt(end - 1))) {
    end--;
  }
  return end > start ? (start: start, end: end) : null;
}

/// Satır sonu dolgusunun gireceği konum: `[start, end)` satırında fiziksel
/// sınırı geçmeden sığan SON kelimenin (veya gerekirse `-`/`/` bölümünün)
/// hemen ardı. Kelime bölünmez; uygun yer yoksa -1 döner.
int _rightPadOffset(
  TextPainter painter,
  String display,
  int start,
  int end, {
  required double columnWidth,
  required double indentEnd,
  required double startAnchorWidth,
  required bool ltr,
  required double midY,
}) {
  final limitX = ltr ? columnWidth - indentEnd : indentEnd;
  if (end <= start || columnWidth - indentEnd <= 0) return -1;

  bool fits(int cut) {
    final vis = _lineTextRange(display, (start: start, end: cut));
    if (vis == null) return false;
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: vis.start, extentOffset: vis.end),
    );
    if (boxes.isEmpty) return false;
    if (ltr) {
      for (final b in boxes) {
        if (b.right > columnWidth - indentEnd - 0.5) return false;
      }
      return true;
    }
    var minLeft = double.infinity;
    var maxRight = -double.infinity;
    for (final b in boxes) {
      if (b.left < minLeft) minLeft = b.left;
      if (b.right > maxRight) maxRight = b.right;
    }
    return startAnchorWidth + (maxRight - minLeft) <=
        columnWidth - indentEnd - 0.5;
  }

  final probe = painter
      .getPositionForOffset(Offset(limitX, midY))
      .offset
      .clamp(start, end);
  final maxCut = math.min(end, probe + 1);

  // İlk geçiş: boşluk/sekme öncesindeki son tam kelime sınırı.
  for (var i = maxCut; i > start; i--) {
    final prev = display.codeUnitAt(i - 1);
    if (prev == 0x20 || prev == 0x09 || _isAnchorCode(prev)) continue;
    final atBoundary =
        i == end ||
        display.codeUnitAt(i) == 0x20 ||
        display.codeUnitAt(i) == 0x09;
    if (atBoundary && fits(i)) return i;
  }

  // İkinci geçiş (uzun URL veya tireli/eğik çizgili parça): `-` ya da `/`.
  for (var i = maxCut; i > start + 1; i--) {
    final prev = display.codeUnitAt(i - 1);
    if (prev == 0x2D || prev == 0x2F) {
      if (fits(i)) return i;
    }
  }
  return -1;
}

/// Dolgu kutusunun YÜKSEKLİĞİ.
///
/// KÖK NEDEN (kullanıcı: "imleç resim varken sorunlu, arkasında ya da altında
/// kalıyor… resmin solunda ama yazmaya başlayınca sağa yazdı"): dolgu kutuları
/// `Size(w, 0)` ile, yani YÜKSEKLİĞİ SIFIR kuruluyordu. İmlecin ekrandaki yeri
/// `TextPainter`ın kutu ölçümlerinden gelir; yüksekliği sıfır olan kutu
/// dejenere bir dikdörtgendir ve imleç ölçümü onu atlayıp satır başına (yani
/// görselin ÜSTÜNE) düşüyordu. Yazma konumu doğruydu — yalnız imleç yanlış
/// yerde yanıp sönüyor, kullanıcı harfin nereye gideceğini bilemiyordu.
///
/// Yükseklik metnin kendi yüksekliğinin ALTINDA tutulur (yarım punto) ve kutu
/// satırın ORTASINA hizalanır: satır yüksekliğini büyütmez, yani sarma planı
/// ve satır kırılımları hiç değişmez.
double wrapAnchorHeight(TextStyle? style) =>
    math.max(1.0, (style?.fontSize ?? 14) * 0.5);

/// Metin alanının SATIR YÜKSEKLİĞİ ÇIPASI — ölçüm ile çizimin ortak kilidi.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-30, ekran görüntüsü: "son imleç
/// güncellemesinden sonra ciddi kayma mevcut, daha kötü oldu"):
/// `EditableText` `strutStyle` verilmediğinde `StrutStyle.fromTextStyle(style,
/// forceStrutHeight: true)` kullanır — yani ÇİZİMDE her satır, içinde ne
/// olursa olsun, taban stilin yüksekliğine kilitlenir. Sarmayı planlayan
/// [TextPainter] ise ÇIPASIZ ölçüyordu ve iki taraf şu iki durumda ayrışıyordu:
///
/// 1. **Yalnız dolgu taşıyan satır** (metin görselin altına itilirken üretilen
///    boş satır): çizimde tam satır yüksekliği, ölçümde yalnız dolgu kutusunun
///    boyu ([wrapAnchorHeight] — yarım punto, ~7 dp). Plan bir görselin bandını
///    aşmak için gereken satır sayısını üçe-dörde katlayarak sayıyor, ekranda o
///    satırlar tam boy çizilince metin ve imleç görselin ÇOK ALTINA düşüyordu.
///    2026-08-29'daki "imleç görselin arkasında kalmasın" düzeltmesi bu sayımı
///    boş tamponda da çalıştırdığı için kayma o turda GÖRÜNÜR hâle geldi.
/// 2. **Satır içi büyütülmüş yazı** (biçim çubuğunun punto kademeleri): çizimde
///    çıpaya kilitli, ölçümde daha uzun.
///
/// Çözüm tek satır: ölçüm de AYNI çıpayı kullanır. Alanlara çıpa ayrıca
/// AÇIKÇA verilir (bkz. note_editor_screen / items_editor) — böylece eşleşme
/// `EditableText`in varsayılanına değil, bu işleve bağlıdır.
StrutStyle wrapStrutStyle(TextStyle style) =>
    StrutStyle.fromTextStyle(style, forceStrutHeight: true);

void _layout(
  TextPainter painter,
  String display,
  List<double> widths,
  TextStyle style,
  double columnWidth,
  RichTextTheme? rich,
) {
  final height = wrapAnchorHeight(style);
  painter
    // SATIR YÜKSEKLİĞİ ÇIPASI: alan her satırı taban stile kilitliyor, ölçüm
    // de aynı kilidi kullanmalı (bkz. [wrapStrutStyle] — kaymanın kök nedeni).
    ..strutStyle = wrapStrutStyle(style)
    // Ölçüm de biçimi uygular: KALIN ve İTALİK metin daha geniş dizilir,
    // ölçüm bunu görmezse satırlar çizimden farklı kırılır ve imleç kayar.
    ..text = buildWrapSpan(display, widths, style, rich: rich)
    ..setPlaceholderDimensions([
      for (final w in widths)
        PlaceholderDimensions(
          size: Size(w, height),
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
  Iterable<String> attachmentNames = const [],
  Map<String, Color>? tagChipColors,
  bool videoTimestamps = false,
}) {
  List<InlineSpan> parts(String text) => rich == null
      ? linkSpans(
          text,
          style,
          linkColor,
          attachmentNames: attachmentNames,
          tagChipColors: tagChipColors,
          videoTimestamps: videoTimestamps,
        )
      : richSpans(
          text,
          style,
          linkColor: linkColor,
          palette: rich.palette,
          markerColor: rich.markerColor,
          background: rich.background,
          attachmentNames: attachmentNames,
          tagChipColors: tagChipColors,
          videoTimestamps: videoTimestamps,
        );

  if (widths.isEmpty || !display.contains(kWrapAnchorChar)) {
    final spans = parts(display);
    return spans.length == 1 && spans.first is TextSpan
        ? spans.first as TextSpan
        : TextSpan(style: style, children: spans);
  }
  // Çapalar (U+FFFC) ve birleştiriciler (U+2060) mantıksal metin biçim
  // ayrıştırıldıktan SONRA yerlerine eklenir; böylece çok satırlı **kalın**,
  // ==vurgu==, %%renk%%, bağlantı ve ek etiketleri satır kırılımında ham
  // işarete bozulmaz.
  final logicalBuf = StringBuffer();
  final splices = <({int at, bool anchor, double width})>[];
  var anchorIdx = 0;
  var logicalLen = 0;
  for (var i = 0; i < display.length; i++) {
    final code = display.codeUnitAt(i);
    if (code == _kWrapAnchorCode) {
      final w = anchorIdx < widths.length ? widths[anchorIdx] : 0.0;
      anchorIdx++;
      splices.add((at: logicalLen, anchor: true, width: w));
    } else if (code == _kWrapGlueCode) {
      splices.add((at: logicalLen, anchor: false, width: 0.0));
    } else {
      logicalBuf.writeCharCode(code);
      logicalLen++;
    }
  }
  final logical = logicalBuf.toString();
  final baseSpans = parts(logical);
  // Kutunun yüksekliği ÖLÇÜMDEKİYLE aynı olmalı (bkz. [wrapAnchorHeight]):
  // ikisi ayrışırsa satırlar farklı kırılır ve imleç kayar.
  final anchorHeight = wrapAnchorHeight(style);
  var pos = 0;
  var spliceIdx = 0;

  void flushAt(int targetPos, List<InlineSpan> out, TextStyle? contextStyle) {
    while (spliceIdx < splices.length && splices[spliceIdx].at == targetPos) {
      final s = splices[spliceIdx++];
      if (s.anchor) {
        out.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: s.width, height: anchorHeight),
          ),
        );
      } else {
        final glueBase = contextStyle ?? style;
        out.add(
          TextSpan(
            text: kWrapGlueChar,
            style: glueBase?.copyWith(
              decoration: TextDecoration.none,
              backgroundColor: const Color(0x00000000),
            ),
          ),
        );
      }
    }
  }

  List<InlineSpan> walkList(List<InlineSpan> nodes, TextStyle? inheritedStyle) {
    final out = <InlineSpan>[];
    for (final node in nodes) {
      if (node is! TextSpan) {
        flushAt(pos, out, inheritedStyle);
        out.add(node);
        pos += 1;
        continue;
      }
      final effStyle = inheritedStyle?.merge(node.style) ?? node.style;
      final t = node.text;
      final nodeChildren = node.children;
      if (t != null && t.isNotEmpty) {
        final from = pos;
        var local = 0;
        final textPieces = nodeChildren != null && nodeChildren.isNotEmpty
            ? <InlineSpan>[]
            : out;
        while (local < t.length) {
          flushAt(pos, textPieces, effStyle);
          final nextAt = spliceIdx < splices.length
              ? splices[spliceIdx].at
              : from + t.length;
          final endAt = math.min(t.length, math.max(local, nextAt - from));
          if (endAt > local) {
            textPieces.add(
              TextSpan(
                text: t.substring(local, endAt),
                style: node.style,
                recognizer: node.recognizer,
                semanticsLabel: node.semanticsLabel,
              ),
            );
            pos += endAt - local;
            local = endAt;
          }
        }
        if (nodeChildren != null && nodeChildren.isNotEmpty) {
          final walkedChildren = walkList(nodeChildren, effStyle);
          out.add(
            TextSpan(
              style: node.style,
              children: [...textPieces, ...walkedChildren],
              recognizer: node.recognizer,
              semanticsLabel: node.semanticsLabel,
            ),
          );
        }
      } else if (nodeChildren != null && nodeChildren.isNotEmpty) {
        out.add(
          TextSpan(
            style: node.style,
            children: walkList(nodeChildren, effStyle),
            recognizer: node.recognizer,
            semanticsLabel: node.semanticsLabel,
          ),
        );
      } else {
        out.add(node);
      }
    }
    return out;
  }

  final children = walkList(baseSpans, style);
  flushAt(logical.length, children, style);
  return TextSpan(style: style, children: children);
}

/// Biçimlendirmenin çizim ayarları. Ölçüm ve çizim AYNI değeri kullanmalı;
/// aksi hâlde kalın/italik metnin genişliği ikisinde ayrışır ve imleç kayar.
@immutable
class RichTextTheme {
  const RichTextTheme({
    required this.palette,
    required this.markerColor,
    this.background,
  });

  /// Renk indeksinin (1..n) karşılığı renkler.
  final List<Color> palette;

  /// Biçim işaretlerinin (sönük) rengi.
  final Color markerColor;

  /// Metnin çizildiği zemin (notun rengi): renkli yazı buna göre okunur
  /// hâle getirilir (bkz. `markStyle`). null = renkler olduğu gibi.
  final Color? background;

  @override
  bool operator ==(Object other) =>
      other is RichTextTheme &&
      other.markerColor == markerColor &&
      other.background == background &&
      other.palette.length == palette.length;

  @override
  int get hashCode => Object.hash(markerColor, background, palette.length);
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

/// [c] sarma çapası ya da yapıştırıcısı mı (görünmez, düzenleme tamponuna
/// özgü karakterler — bkz. [kWrapAnchorChar], [kWrapGlueChar]).
bool isWrapAnchorCode(int c) => _isAnchorCode(c);

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

/// Metni mantıksal bir tampona İMLECİN yerine ekler.
///
/// KULLANICI BULGUSU 2026-08-30: "not içerisindeki sesli yazma butonu, nota
/// ekle dendiğinde imlecin olduğu yere eklemiyor, en başa metin notu olarak
/// ekliyor." Dikte/OCR gibi akışlar metni notun SONUNA yığıyordu; kullanıcı
/// cümlenin ortasında konuşup devam edemiyordu.
///
/// Eklenen parça kelimeye yapışmasın diye iki yanına GEREKTİĞİ KADAR boşluk
/// konur (satır sonu ve var olan boşluk yeni boşluk doğurmaz). Dönen imleç
/// eklenen metnin SONUNDADIR: kullanıcı kaldığı yerden yazmaya devam eder.
({String text, int caret}) insertAtCaret(
  String logical,
  int caret,
  String insert,
) {
  final at = caret.clamp(0, logical.length);
  final trimmed = insert.trim();
  if (trimmed.isEmpty) return (text: logical, caret: at);
  bool blank(String ch) => ch.trim().isEmpty;
  final before = at > 0 && !blank(logical[at - 1]) ? ' ' : '';
  final after = at < logical.length && !blank(logical[at]) ? ' ' : '';
  final piece = '$before$trimmed$after';
  return (
    text: logical.replaceRange(at, at, piece),
    caret: at + before.length + trimmed.length,
  );
}

/// **CANLI DİKTE YAZIMI** — konuşulan sözü imlecin yerine, KENDİ yazdığı
/// aralığın üstüne yazar.
///
/// Cihazın tanıyıcısı her olayda o ana kadarki TAM metni gönderir ve önceki
/// bir kelimeyi SONRADAN düzeltebilir ("bir" → "birkaç"). Gelen parçayı
/// imlece eklemek metni ikizler; bu yüzden dikte boyunca yazılan aralık
/// ([at]..[at]+[length]) hatırlanır ve her olayda yenisiyle DEĞİŞTİRİLİR.
/// Aralığın dışı — kullanıcının dikte sürerken elle yazdığı harfler dahil —
/// hiç ellenmez.
///
/// Eklenen parça kelimeye yapışmasın diye iki yanına GEREKTİĞİ KADAR boşluk
/// konur ([insertAtCaret] ile aynı kural). Dönen `length` bir sonraki olayda
/// değiştirilecek aralığın uzunluğudur (boşluklar dahil), `caret` ise
/// konuşulan sözün SONUDUR — kullanıcı oradan yazmaya devam edebilir.
/// **DİKTE METNİNİ BİRLEŞTİRME** — yazılan metin geriye gitmez, satır
/// bölünmez.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-09-02, üç ekran görüntüsüyle: "önce
/// yazıyor, sonra alt satıra yazıyor, sonra geri birleştiriyor"): tanıyıcı her
/// olayda o ana kadarki TAM metni gönderiyor ve bu metin bazen KISALIYOR
/// (yeni ara sonuç önceki segmentin tekrarını düşürünce) ya da segment
/// sınırında SATIR SONU kazanıyor (köprü parçaları `\n` ile birleştiriyor —
/// bkz. MainActivity.joined). Gelen metin olduğu gibi yazılınca kullanıcı,
/// yazdığı cümlenin bölünüp yeniden birleştiğini, hatta kısalıp geri geldiğini
/// görüyordu. Android'in kendi klavye diktesi bunu yapmaz: yazılan metin
/// yalnız SONUNDAN uzar.
///
/// Kural bu yüzden üç satır:
///  * Satır sonları ve katlanmış boşluklar TEK boşluğa iner — dikte bir
///    paragraf yazar, liste değil.
///  * Yeni metin, yazılanın KISALTILMIŞ hâliyse yok sayılır (geriye gitme).
///  * Kalan her durumda yeni metin yazılır (uzama ya da kuyruk düzeltmesi).
String dictationMerge(String shown, String spoken) {
  final next = spoken.replaceAll(RegExp(r'\s+'), ' ').trim();
  final current = shown.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (next.isEmpty) return current;
  if (current.isEmpty) return next;
  // Kısalma: tanıyıcı bir kelimeyi geri aldı. Kullanıcı onu SÖYLEDİ; silmek,
  // ekranda yazının kaybolup geri gelmesi demek.
  // İstisna: kısalan kuyruk yeni metinde zaten varsa o kuyruk bir KLONDU
  // (yerli taraf geri aldı) — kalırsa cümle iki kez yazılı kalır.
  if (current.startsWith(next) && !droppedTailIsRepeat(current, next)) {
    return current;
  }
  return next;
}

/// Dikte aralığını AI düzeltmesiyle değiştirir (F42.4). Aralıktaki metin bu
/// arada değiştiyse (yazıldı, silindi) ya da düzeltme aynıysa null: kullanıcının
/// yazdığının üstüne yazılmaz.
({String text, int caret})? dictationFixed(
  String logical,
  int at,
  String spoken,
  String fixed,
) {
  final end = at + spoken.length;
  if (at < 0 || end > logical.length) return null;
  if (logical.substring(at, end) != spoken) return null;
  if (fixed.isEmpty || fixed == spoken) return null;
  return (text: logical.replaceRange(at, end, fixed), caret: at + fixed.length);
}

({String text, int caret, int length}) dictationReplace(
  String logical,
  int at,
  int length,
  String spoken,
) {
  final piece = spoken.trim();
  final start = at.clamp(0, logical.length);
  final end = (start + length).clamp(start, logical.length);
  if (piece.isEmpty) {
    return (text: logical, caret: end, length: end - start);
  }
  bool blank(String ch) => ch.trim().isEmpty;
  final before = start > 0 && !blank(logical[start - 1]) ? ' ' : '';
  final after = end < logical.length && !blank(logical[end]) ? ' ' : '';
  final inserted = '$before$piece$after';
  return (
    text: logical.replaceRange(start, end, inserted),
    caret: start + before.length + piece.length,
    length: inserted.length,
  );
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
    this.textTop = 0,
    this.minTop,
    this.floatsListenable,
    this.remeasureListenable,
  });

  /// Bantların canlı kaynağı (verilince [floats] yok sayılır): değişince bu
  /// katman yalnız yeniden ölçer — ne kendisi ne alan kurulur (2026-11-24,
  /// kök kurulumsuz bant dağıtımı).
  final ValueListenable<List<FloatBox>>? floatsListenable;

  /// Üstteki satır/başlık kayınca yeniden ölçüm isteyen ikincil bildirim.
  final Listenable? remeasureListenable;

  List<FloatBox> get _floatsNow => floatsListenable?.value ?? floats;

  final WrapTextController controller;
  final TextStyle style;

  /// Verilirse yalnız metnin ilk satırından en az bu kadar (dp, metin
  /// uzayında) AŞAĞIDA başlayan görseller plana girer; daha yukarıdakileri
  /// çağıran başka yoldan işler (liste maddesinde satırın tamamı kayar).
  final double? minTop;

  /// Alanın ÜST KENARI ile İLK METİN SATIRI arasındaki boşluk (dp) —
  /// `InputDecoration.contentPadding`in üst yarısı.
  ///
  /// KÖK NEDEN: bantlar alanın kutusuna göre ölçülüyor, sarma planı ise METİN
  /// uzayında çalışıyor (satır 0'ın tepesi = 0). İkisi arasındaki dolgu
  /// düşülmezse plan bandı olduğundan yukarıda sanır: metin görselin altına
  /// dolgu kadar FAZLA itilir, imleç ile ipucu ayrı satırlara düşer.
  final double textTop;

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
  void initState() {
    super.initState();
    widget.floatsListenable?.addListener(_schedule);
    widget.remeasureListenable?.addListener(_schedule);
  }

  @override
  void didUpdateWidget(WrapFieldMeasure old) {
    super.didUpdateWidget(old);
    if (old.floatsListenable != widget.floatsListenable) {
      old.floatsListenable?.removeListener(_schedule);
      widget.floatsListenable?.addListener(_schedule);
    }
    if (old.remeasureListenable != widget.remeasureListenable) {
      old.remeasureListenable?.removeListener(_schedule);
      widget.remeasureListenable?.addListener(_schedule);
    }
  }

  @override
  void dispose() {
    widget.floatsListenable?.removeListener(_schedule);
    widget.remeasureListenable?.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    // Sarma yalnız görsel varken (ya da tamponda temizlenecek çapa kalmışken)
    // iş yapar; ikisi de yoksa kare-sonu geri çağrısı hiç kurulmaz. Alan
    // başına kare başına bir kapanış, uzun bir madde listesinde satır sayısı
    // kadar boş iş demekti.
    final idle = widget._floatsNow.isEmpty && widget.controller.isPlain;
    if (_scheduled || idle) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }

  /// `RenderEditable`ın satır genişliğinden düştüğü imleç payı
  /// (`kWindowedCaretMargin` ile aynı — döngüsel importsuz sabit).
  static const double _kFieldCaretMargin = 3.0;

  void _measure() {
    _scheduled = false;
    if (!mounted) return;
    // Görsel yok ve tampon zaten temiz: hiçbir şey ölçme. (Görsel silinince
    // bir kez daha ölçülür ki kalan çapalar temizlensin.)
    final floatsNow = widget._floatsNow;
    if (floatsNow.isEmpty && widget.controller.isPlain) return;
    final box = context.findRenderObject();
    final page = widget.pageBox();
    if (box is! RenderBox || !box.hasSize || page == null || !page.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: page);
    final width = box.size.width;
    final effectiveWidth = math.max(0.0, width - _kFieldCaretMargin);
    if (effectiveWidth <= 0) return;
    // Metnin başladığı çizgi: alanın tepesi + iç dolgu (bkz. [textTop]).
    final textOrigin = origin.dy + widget.textTop;
    // TextField stili temanın bodyLarge'ının üstüne birleştirir; ölçüm de
    // aynı birleşmiş stili kullanırsa harf aralığı/satır kırılımı birebir tutar.
    final mergedStyle =
        (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).merge(
          widget.style,
        );
    final localFloats = <FloatBox>[];
    for (final f in floatsNow) {
      if (f.bottom <= textOrigin ||
          f.right <= origin.dx ||
          f.left >= origin.dx + effectiveWidth) {
        continue;
      }
      if (widget.minTop != null &&
          (f.block || f.top - textOrigin < widget.minTop!)) {
        continue;
      }
      final left = (f.left - origin.dx).clamp(0.0, effectiveWidth).toDouble();
      final right = (f.right - origin.dx).clamp(0.0, effectiveWidth).toDouble();
      if (right <= left) continue;
      localFloats.add(
        FloatBox(
          top: f.top - textOrigin,
          left: left,
          right: right,
          height: f.height,
        ),
      );
    }
    widget.controller.updateLayout(
      floats: localFloats,
      style: mergedStyle,
      columnWidth: effectiveWidth,
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
      // Yön dizginin kendisini etkiler: dolgu MANTIKSAL satır başına konur,
      // görselin yeri ise FİZİKSELdir (bkz. planTextWrap). Geçilmezse Arapça
      // gibi sağdan sola dillerde metin görselin üstüne biner.
      direction: Directionality.of(context),
    );
  }
}
