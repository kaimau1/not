import 'dart:math' as math;
import 'dart:ui' show Rect;

/// Sayfadaki görsellerin ORTAK yerleşim matematiği: yeni görselin boş yeri,
/// sürüklerken kenar yapışması/çarpışması, kılavuz çizgileri ve seçili
/// görselleri satıra sığdırma. Hepsi saf işlev — widget'tan bağımsız,
/// doğrudan test edilir (bkz. `test/image_layout_test.dart`).
///
/// KÖK NEDEN (kullanıcı 2026-09-05: "birden fazla görsel eklendiğinde üst
/// üste başlıyor"): yerleşim İKİ ayrı yerde, iki ayrı kuralla yapılıyordu —
/// editörde yeni ekin yeri (`_placeNewImage`) ve tuvalde konumu yazılmamış
/// eklerin yığını (`_defaultTop`). İkisi de yalnız DİKEY yığıyordu:
///  * Editör tarafında yükseklik `pageWidth * displayWidth / oran` ile
///    ölçülüyordu; sayfa henüz ölçülmemişse `pageWidth` 0 oluyor, her görselin
///    "altı" kendi tepesi çıkıyor ve hepsi 16 dp arayla, yani pratikte ÜST
///    ÜSTE diziliyordu. Paylaşımdan/çoklu seçimden gelen görsellerde tam da bu
///    yol işliyor.
///  * Tuval tarafında yığın 8 dp'den başlıyordu ama sonuç `topLimit`'e
///    (başlığın altına) kırpılıyordu: `topLimit`in üstünde kalan HER görsel
///    aynı çizgiye çöküyordu.
/// Artık tek kaynak var: [packSlot] satırda önce YAN YANA yer arar, satır
/// dolunca alta iner ve hiçbir görselin üstüne binmez.

/// Görseller arası varsayılan boşluk (dp).
const double kImageGap = 8;

/// Eski (küçük tuval dönemi) kayıtlarda `Attachment.y` oranını dp'ye çevirmek
/// için kullanılan tuval yüksekliği. Eski notların görselleri aynı yerde
/// kalsın diye sabit; yeni kayıtlar `pageY`yi dp olarak yazar.
const double kLegacyCanvasHeight = 440;

/// Kenarların birbirine yapışma mesafesi (dp): sürüklenen kenar bu kadar
/// yaklaşınca hedefe oturur.
const double kImageSnap = 10;

/// Çarpışmanın "zorlama" eşiği (dp).
///
/// Kullanıcı isteği: "kenarların çarpışması modu olsun, zorlayınca üst üste
/// gelebilsin ancak ilk anda kenarlar çarpışsın iç içe geçmesin". İlk temasta
/// görsel komşusunun kenarında durur; parmak komşunun içine bu kadar
/// girmeye devam ederse engel kalkar ve görseller üst üste binebilir.
const double kImagePush = 28;

/// Yerleşim kılavuzu: sürükleme/boyutlandırma sırasında çizilen ince çizgi.
/// [vertical] ise `x = pos`, değilse `y = pos` (sayfa uzayında, dp).
class AlignGuide {
  const AlignGuide({required this.vertical, required this.pos});

  final bool vertical;
  final double pos;

  @override
  bool operator ==(Object other) =>
      other is AlignGuide &&
      other.vertical == vertical &&
      (other.pos - pos).abs() < 0.01;

  @override
  int get hashCode => Object.hash(vertical, pos.round());

  @override
  String toString() => '${vertical ? 'x' : 'y'}=${pos.toStringAsFixed(1)}';
}

/// İki kutu (aralarında [gap] payı bırakılarak) çakışıyor mu.
bool _hits(Rect a, Rect b, double gap) =>
    a.left < b.right + gap - 0.01 &&
    b.left < a.right + gap - 0.01 &&
    a.top < b.bottom + gap - 0.01 &&
    b.top < a.bottom + gap - 0.01;

/// Verilen boyuttaki görselin sayfada ÇAKIŞMAYAN yeri.
///
/// Arama [anchorTop]'tan başlar (imlecin ya da görünen alanın hizası): önce o
/// satırda soldan sağa boş yer bakılır — yani ikinci görsel birincinin YANINA
/// gider, üstüne değil. Satıra sığmazsa satırı kapatan görsellerin en yakın
/// altına inilir ve arama oradan sürer.
({double left, double top}) packSlot({
  required List<Rect> occupied,
  required double columnWidth,
  required double width,
  required double height,
  required double anchorTop,
  required double topLimit,
  double gap = kImageGap,
}) {
  final w = math.min(width, columnWidth);
  var top = math.max(anchorTop, topLimit);
  // Sonsuz döngü olamaz: her tur bir satır aşağı iner, satır sayısı da
  // kutu sayısıyla sınırlı. Yine de bir tavan konur.
  for (var guard = 0; guard <= occupied.length + 1; guard++) {
    final band = Rect.fromLTWH(0, top, math.max(columnWidth, w), height);
    final row = [
      for (final o in occupied)
        if (o.top < band.bottom + gap - 0.01 && band.top < o.bottom + gap - 0.01)
          o,
    ]..sort((a, b) => a.left.compareTo(b.left));
    if (row.isEmpty) return (left: 0, top: top);
    // Aday sol kenarlar: satırın başı ve satırdaki her görselin sağı.
    final xs = <double>[0, for (final o in row) o.right + gap];
    for (final x in xs) {
      if (x < 0 || x + w > columnWidth + 0.01) continue;
      final candidate = Rect.fromLTWH(x, top, w, height);
      if (!row.any((o) => _hits(o, candidate, gap))) {
        return (left: x, top: top);
      }
    }
    // Satır dolu: kesişenlerin EN YAKIN altına in.
    var next = double.infinity;
    for (final o in row) {
      final below = o.bottom + gap;
      if (below > top + 0.01 && below < next) next = below;
    }
    if (!next.isFinite) return (left: 0, top: top);
    top = next;
  }
  return (left: 0, top: top);
}

/// Sürüklenen görselin son yeri: kenarlar sayfaya ve komşulara YAPIŞIR,
/// hafif temasta çarpışıp durur, zorlanınca ([kImagePush] derinliğinden
/// sonra) üst üste binmeye izin verilir.
///
/// [rect] parmağın istediği (ham) kutu; [others] sayfadaki DİĞER görseller.
/// Dönen kılavuzlar hangi hizanın tuttuğunu gösterir (ekrana çizilir).
({double left, double top, List<AlignGuide> guides}) snapMove({
  required Rect rect,
  required List<Rect> others,
  required double columnWidth,
  required double topLimit,
  double snap = kImageSnap,
  double push = kImagePush,
}) {
  final w = rect.width;
  final h = rect.height;

  // ── Yatay yapışma: (sol kenarın hedefi, çizilecek kılavuz) ─────────────
  final xs = <(double, double)>[
    (0, 0),
    (columnWidth - w, columnWidth),
    ((columnWidth - w) / 2, columnWidth / 2),
  ];
  for (final o in others) {
    xs
      ..add((o.left, o.left)) // sol kenarlar aynı hizada
      ..add((o.right - w, o.right)) // sağ kenarlar aynı hizada
      ..add((o.right, o.right)) // solunu onun sağına yapıştır
      ..add((o.left - w, o.left)) // sağını onun soluna yapıştır
      ..add((o.center.dx - w / 2, o.center.dx)); // ortalar aynı hizada
  }
  var left = rect.left;
  double? guideX;
  var bestX = snap + 0.001;
  for (final (target, line) in xs) {
    final d = (target - rect.left).abs();
    if (d < bestX) {
      bestX = d;
      left = target;
      guideX = line;
    }
  }

  // ── Dikey yapışma ──────────────────────────────────────────────────────
  final ys = <(double, double)>[(topLimit, topLimit)];
  for (final o in others) {
    ys
      ..add((o.top, o.top))
      ..add((o.bottom - h, o.bottom))
      ..add((o.bottom, o.bottom))
      ..add((o.top - h, o.top))
      ..add((o.center.dy - h / 2, o.center.dy));
  }
  var top = rect.top;
  double? guideY;
  var bestY = snap + 0.001;
  for (final (target, line) in ys) {
    final d = (target - rect.top).abs();
    if (d < bestY) {
      bestY = d;
      top = target;
      guideY = line;
    }
  }

  final maxLeft = math.max(0.0, columnWidth - w);
  if (left.clamp(0.0, maxLeft) != left) {
    left = left.clamp(0.0, maxLeft).toDouble();
    guideX = null;
  }
  if (top < topLimit) {
    top = topLimit;
    guideY = topLimit;
  }

  // ── Çarpışma: hafif temasta kenardan dışarı it ─────────────────────────
  var r = Rect.fromLTWH(left, top, w, h);
  for (final o in others) {
    final ix = math.min(r.right, o.right) - math.max(r.left, o.left);
    final iy = math.min(r.bottom, o.bottom) - math.max(r.top, o.top);
    if (ix <= 0 || iy <= 0) continue;
    // Parmak komşunun DERİNİNE girdiyse kullanıcı bilerek zorluyor: geçsin.
    if (math.min(ix, iy) > push) continue;
    if (ix <= iy) {
      final toLeft = r.center.dx <= o.center.dx;
      final target = (toLeft ? o.left - w : o.right).clamp(0.0, maxLeft);
      guideX = target == (toLeft ? o.left - w : o.right)
          ? (toLeft ? o.left : o.right)
          : null;
      r = Rect.fromLTWH(target.toDouble(), r.top, w, h);
    } else {
      final toTop = r.center.dy <= o.center.dy;
      final target = math.max(topLimit, toTop ? o.top - h : o.bottom);
      guideY = target == (toTop ? o.top - h : o.bottom)
          ? (toTop ? o.top : o.bottom)
          : null;
      r = Rect.fromLTWH(r.left, target, w, h);
    }
  }

  return (
    left: r.left,
    top: r.top,
    guides: [
      if (guideX != null) AlignGuide(vertical: true, pos: guideX),
      if (guideY != null) AlignGuide(vertical: false, pos: guideY),
    ],
  );
}

/// Boyutlandırırken genişliği sayfaya, komşuların kenarlarına ve komşu
/// GENİŞLİĞİNE yapıştırır — "kılavuz kenar çizgileri çıksın ve diğer görselle
/// ve sayfa ile hizalamak kolay olsun".
///
/// Eşit genişliğe oturmak ortak bir çizgi üretmez; o durumda kılavuz çizilmez
/// ama genişlik yine de komşuyla birebir aynı olur.
({double width, List<AlignGuide> guides}) snapWidth({
  required double left,
  required double width,
  required List<Rect> others,
  required double columnWidth,
  double snap = kImageSnap,
}) {
  final right = left + width;
  final cands = <(double, double?)>[
    (columnWidth, columnWidth),
    (columnWidth / 2, columnWidth / 2),
  ];
  for (final o in others) {
    cands
      ..add((o.left, o.left))
      ..add((o.right, o.right))
      ..add((left + o.width, null)); // komşuyla EŞİT genişlik
  }
  var out = width;
  double? guide;
  var best = snap + 0.001;
  for (final (target, line) in cands) {
    if (target - left <= 0) continue;
    final d = (target - right).abs();
    if (d < best) {
      best = d;
      out = target - left;
      guide = line;
    }
  }
  return (
    width: out,
    guides: [if (guide != null) AlignGuide(vertical: true, pos: guide)],
  );
}

/// Seçili görsellerin ortak genişlik oranı ("boyutları eşitle").
///
/// Ortalama alınır: en büyüğe eşitlemek sayfayı taşırıyor, en küçüğe
/// eşitlemek okunmaz hâle getiriyordu.
double equalWidthFrac(List<double> fracs, {double minFrac = 0.15}) {
  if (fracs.isEmpty) return 0.5;
  var sum = 0.0;
  for (final f in fracs) {
    sum += f;
  }
  return (sum / fracs.length).clamp(minFrac, 1.0).toDouble();
}

/// [fitRowsLayout] sonucunda tek bir görselin yeri.
class RowFit {
  const RowFit({
    required this.widthFrac,
    required this.leftFrac,
    required this.top,
  });

  /// Sayfa genişliğinin oranı olarak genişlik (`Attachment.displayWidth`).
  final double widthFrac;

  /// Sayfa genişliğinin oranı olarak sol kenar (`Attachment.x`).
  final double leftFrac;

  /// Sayfanın tepesinden uzaklık, dp (`Attachment.pageY`).
  final double top;
}

/// Seçili görselleri satır(lar)a SIĞDIRIR: kenarları birbirine ve sayfanın
/// iki yanına yapışır, satır tam olarak sayfa genişliğini doldurur.
///
/// Kullanıcı isteği: "2 ya da 3 görseli bir satıra sığdır seçeneği olsun,
/// görselleri seçip sığdır deyince kenarlarını yapıştırarak ve sağ kenarına
/// da yapışacak şekilde muntazam sığdırsın".
///
/// Satırdaki genişlikler en-boy oranıyla ORANTILI dağıtılır: böylece satırdaki
/// bütün görsellerin yüksekliği eşit olur ve satır düzgün bir blok gibi durur
/// (aynı orandaki görsellerde bu, eşit genişlik demektir). Bir görsel
/// [minWidthFrac]'ın altına düşecekse satır eşit genişliğe döner.
///
/// [maxPerRow]'dan fazla görsel seçilirse satırlara dengeli bölünür
/// (6 görsel → 3 + 3, 5 görsel → 3 + 2).
List<RowFit> fitRowsLayout({
  required List<double> aspects,
  required double columnWidth,
  required double top,
  double gap = 0,
  double minWidthFrac = 0.15,
  int maxPerRow = 3,
}) {
  final n = aspects.length;
  if (n == 0 || columnWidth <= 0) return const [];
  final rows = math.max(1, (n / maxPerRow).ceil());
  final perRow = math.max(1, (n / rows).ceil());
  final out = <RowFit>[];
  var y = top;
  var i = 0;
  while (i < n) {
    final k = math.min(perRow, n - i);
    final slice = [
      for (var j = i; j < i + k; j++) aspects[j] > 0 ? aspects[j] : 1.0,
    ];
    final avail = columnWidth - gap * (k - 1);
    var sum = 0.0;
    for (final a in slice) {
      sum += a;
    }
    var widths = [for (final a in slice) avail * a / sum];
    if (widths.any((w) => w < minWidthFrac * columnWidth)) {
      widths = [for (var j = 0; j < k; j++) avail / k];
    }
    var x = 0.0;
    var rowHeight = 0.0;
    for (var j = 0; j < k; j++) {
      out.add(
        RowFit(
          widthFrac: widths[j] / columnWidth,
          leftFrac: x / columnWidth,
          top: y,
        ),
      );
      final h = widths[j] / slice[j];
      if (h > rowHeight) rowHeight = h;
      x += widths[j] + gap;
    }
    y += rowHeight + gap;
    i += k;
  }
  return out;
}
