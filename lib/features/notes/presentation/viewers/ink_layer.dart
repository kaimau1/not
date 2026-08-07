import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'ink_pen.dart';

/// PDF ve slayt görüntüleyicilerinin ortak elle-yazma katmanı. Çizim dosyaya
/// gömülmez; sayfa/slayt oranlı (0–1) vektör olarak [InkStroke] listesinde
/// tutulur ve [onChanged] ile üst katmana (ek → not → Firestore) verilir.
///
/// TEK parmak çizer, İKİ parmak yakınlaştırır: katman jest arenasına girmeyen
/// [Listener] kullanır (dokunuş alttaki görüntüleyiciye de ulaşır). Çizim
/// modunda görüntüleyicinin `panEnabled`'ı kapalı, `scaleEnabled`'ı açık
/// bırakılır — tek parmak çizer, iki parmak yakınlaştırır. İkinci parmak inince
/// başlamış çizgi iptal edilir ki iki parmak jesti çizime dönüşmesin.
class InkController extends ChangeNotifier {
  InkController({required List<InkStroke> initial, required this.onChanged})
    : _ink = [...initial];

  /// Çizim değişince güncel çizgi listesiyle çağrılır (kaydetme).
  final ValueChanged<List<InkStroke>> onChanged;

  List<InkStroke> _ink;
  List<InkStroke> get ink => _ink;

  bool editing = false;
  bool eraser = false;

  /// Kullanıcının seçtiği renk — SAYDAMLIKSIZ hâli. Çizgiye yazılırken
  /// kalemin saydamlığı uygulanır ([penColor]).
  Color color = kInkPalette.first;

  /// Kalem türü (tükenmez / keçeli / fosforlu).
  InkPen pen = InkPen.pen;

  /// Ekrandaki (ölçeklenmiş) sayfa üzerinde piksel kalınlık; kaydedilirken
  /// sayfa genişliğinin oranına çevrilir.
  double widthPx = InkPen.pen.defaultWidth;

  /// Çizgiye yazılan renk: seçilen renk + kalemin saydamlığı.
  Color get penColor => pen.apply(color);

  /// Çizgiler her değiştiğinde artan sayaç — [InkPainter.shouldRepaint]
  /// bunun üzerinden karar verir (liste kimliğine bakmak yetmiyor: aynı liste
  /// nesnesi yerinde uzatılıyor).
  int _revision = 0;
  int get revision => _revision;

  /// Her bildirimde sayaç artar. Böylece boyayıcı "denetleyici gerçekten
  /// değişti mi" sorusunu ucuza yanıtlar; üst ağacın yeniden kurulması tek
  /// başına yeniden boyama SEBEBİ olmaz.
  @override
  void notifyListeners() {
    _revision++;
    super.notifyListeners();
  }

  int _pointers = 0;
  InkStroke? _active;
  bool _dirty = false;

  /// [InkNavLayer] iki parmak jestini sürerken true: sayfa katmanı çizim
  /// girdisini tamamen yok sayar (parmaklardan biri sayfa dışına — kenar
  /// boşluğuna — düşse bile çizgi başlamaz/uzamaz).
  bool _nav = false;

  /// Silginin çizgiye "değmiş" sayıldığı yarıçap (sayfa oranı).
  static const _eraseRadius = 0.02;

  void setEditing(bool value) {
    if (editing == value) return;
    editing = value;
    if (!editing) save();
    notifyListeners();
  }

  void setEraser(bool value) {
    eraser = value;
    notifyListeners();
  }

  void setColor(Color value) {
    color = value;
    eraser = false;
    notifyListeners();
  }

  /// Kalem türünü değiştirir. Kalınlık türün kendi aralığına taşınır:
  /// fosforluya geçip 3 px'te kalmak "fosforlu çalışmıyor" izlenimi veriyordu.
  void setPen(InkPen value) {
    if (pen == value && !eraser) return;
    final wasDefault = widthPx == pen.defaultWidth;
    pen = value;
    eraser = false;
    widthPx = wasDefault ? value.defaultWidth : value.clampWidth(widthPx);
    notifyListeners();
  }

  void setWidth(double value) {
    widthPx = pen.clampWidth(value);
    notifyListeners();
  }

  void save() {
    if (!_dirty) return;
    _dirty = false;
    onChanged(_ink);
  }

  void undo() {
    if (_ink.isEmpty) return;
    _dirty = true;
    _ink = _ink.sublist(0, _ink.length - 1);
    save();
    notifyListeners();
  }

  void clear() {
    if (_ink.isEmpty) return;
    _dirty = true;
    _ink = [];
    save();
    notifyListeners();
  }

  /// Çizgileri DIŞARIDAN gelen listeyle değiştirir ([onChanged] tetiklenmez).
  ///
  /// Aynı ekin iki ayrı görüntüleyicide açık olduğu durum için: PDF notunun
  /// panosu çizimleri salt gösterir, düzenleme tam ekranda yapılır ve oradan
  /// dönen yeni liste panonun kendi denetleyicisine buradan işlenir. Kaydetme
  /// yolu tetiklenmez — bu bir kullanıcı çizimi değil, zaten kaydedilmiş
  /// çizimin kopyalanmasıdır.
  void replace(List<InkStroke> strokes) {
    // İÇERİK karşılaştırması: çağıranlar liste KİMLİĞİNE bakıyordu, ama
    // `Note.fromDoc` her anlık görüntüde yeni liste kuruyor — yani her
    // Firestore yankısında (kendi yazımımızınki dahil) katman boşuna
    // tazeleniyordu.
    if (_sameStrokes(_ink, strokes)) return;
    _dirty = false;
    _ink = [...strokes];
    notifyListeners();
  }

  static bool _sameStrokes(List<InkStroke> a, List<InkStroke> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.page != y.page ||
          x.color != y.color ||
          x.width != y.width ||
          x.points.length != y.points.length) {
        return false;
      }
    }
    return true;
  }

  /// İki parmak gezinme başladı: başlamış çizgiyi geri al, çizimi askıya al.
  void beginNav() {
    if (_nav) return;
    _nav = true;
    if (_active != null) {
      _ink = [..._ink]..remove(_active);
      _active = null;
    }
    notifyListeners();
  }

  /// İki parmak gezinme bitti (parmak sayısı 2'nin altına indi).
  void endNav() {
    _nav = false;
  }

  void pointerDown(int page, Offset local, Size size) {
    _pointers++;
    if (_nav) return;
    if (_pointers > 1) {
      // İkinci parmak = yakınlaştırma/kaydırma niyeti: yeni başlamış çizgiyi
      // geri al ki ekranda kırıntı kalmasın.
      if (_active != null) _ink = [..._ink]..remove(_active);
      _active = null;
      notifyListeners();
      return;
    }
    if (eraser) {
      _eraseAt(page, local, size);
      notifyListeners();
      return;
    }
    final stroke = InkStroke(
      page: page,
      color: penColor.toARGB32(),
      width: widthPx / size.width,
      points: [local.dx / size.width, local.dy / size.height],
    );
    _dirty = true;
    _active = stroke;
    _ink = [..._ink, stroke];
    notifyListeners();
  }

  void pointerMove(int page, Offset local, Size size) {
    if (_nav || _pointers != 1) return;
    if (eraser) {
      _eraseAt(page, local, size);
      notifyListeners();
      return;
    }
    final active = _active;
    if (active == null) return;
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    // Çok yakın noktalar atlanır: çizim yumuşar, Firestore'a giden liste şişmez.
    final n = active.points.length;
    if (math.max(
          (active.points[n - 2] - x).abs(),
          (active.points[n - 1] - y).abs(),
        ) <
        0.002) {
      return;
    }
    active.points.addAll([x, y]);
    notifyListeners();
  }

  void pointerUp() {
    _pointers = math.max(0, _pointers - 1);
    if (_pointers > 0) {
      notifyListeners();
      return;
    }
    _active = null;
    save();
    notifyListeners();
  }

  void _eraseAt(int page, Offset local, Size size) {
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    final kept = <InkStroke>[];
    for (final s in _ink) {
      var hit = false;
      if (s.page == page) {
        for (var i = 0; i < s.points.length; i += 2) {
          if ((s.points[i] - x).abs() < _eraseRadius &&
              (s.points[i + 1] - y).abs() < _eraseRadius) {
            hit = true;
            break;
          }
        }
      }
      if (!hit) kept.add(s);
    }
    if (kept.length == _ink.length) return;
    _dirty = true;
    _ink = kept;
  }
}

/// Bir sayfanın/slaytın üstüne serilen dokunma + çizim katmanı. İçeren
/// widget'ın tüm alanını kaplar (sayfa boyutu [LayoutBuilder]'dan alınır).
class InkPageLayer extends StatelessWidget {
  const InkPageLayer({super.key, required this.controller, required this.page});

  final InkController controller;

  /// 1 tabanlı sayfa/slayt numarası.
  final int page;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Çizim kapalıyken katman dokunmayı hiç görmez.
      ignoring: !controller.editing,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) =>
                controller.pointerDown(page, e.localPosition, size),
            onPointerMove: (e) =>
                controller.pointerMove(page, e.localPosition, size),
            onPointerUp: (_) => controller.pointerUp(),
            onPointerCancel: (_) => controller.pointerUp(),
            // Yalnız çizgiler değişince yeniden boyanır; görüntüleyici (PDF/slayt)
            // yeniden kurulmaz — bu yüzden çizim sırasında jest bozulmaz.
            // RepaintBoundary: tek bir çizgi uzarken üstteki PDF/slayt
            // katmanının yeniden boyanmasına gerek yok.
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => CustomPaint(
                  painter: InkPainter(
                    controller.ink,
                    page,
                    revision: controller.revision,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Çizim modunda ekranın altında beliren araç çubuğu: kalem türleri (tükenmez /
/// keçeli / fosforlu), silgi, renkler, kalınlık, geri al, temizle.
///
/// El yazısı notu ekranı ile PDF/slayt/görsel üstü çizim AYNI çubuğu kullanır:
/// seçenekler iki yerde ayrı ayrı yazılırsa biri güncellenip diğeri geride
/// kalıyor, kullanıcı "burada var orada yok" durumuyla karşılaşıyordu.
class InkToolbar extends StatelessWidget {
  const InkToolbar({super.key, required this.controller, this.hint});

  final InkController controller;

  /// Çubuğun altındaki tek satırlık ipucu (null = ipucu yok). PDF/slayt
  /// üstünde iki parmak jesti anlatılır; el yazısı ekranında gerekmez.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  /// Kalem türü düğmesi: seçiliyken dolgulu, ucu seçili renkte.
  Widget _penButton(
    BuildContext context,
    InkPen pen,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = !controller.eraser && controller.pen == pen;
    return IconButton(
      tooltip: label,
      isSelected: selected,
      // Sıkı yoğunluk: üç kalem + silgi + geri al + temizle tek satıra
      // sığmalı (360 dp telefonda taşıyordu).
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        // Seçili kalemin simgesi çizilen renkte: hangi kalemin hangi renkte
        // olduğu tek bakışta görünür.
        color: selected ? controller.penColor : scheme.onSurfaceVariant,
      ),
      onPressed: () => controller.setPen(pen),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pen = controller.pen;
    final hintText = hint;
    return SafeArea(
      top: false,
      child: Material(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _penButton(
                    context,
                    InkPen.pen,
                    Icons.edit,
                    l10n.penBallpoint,
                  ),
                  _penButton(
                    context,
                    InkPen.marker,
                    Icons.brush,
                    l10n.penMarker,
                  ),
                  _penButton(
                    context,
                    InkPen.highlighter,
                    Icons.format_color_fill,
                    l10n.penHighlighter,
                  ),
                  IconButton(
                    tooltip: l10n.eraser,
                    isSelected: controller.eraser,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    onPressed: () => controller.setEraser(true),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.undo,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.undo),
                    onPressed: controller.ink.isEmpty ? null : controller.undo,
                  ),
                  IconButton(
                    tooltip: l10n.clearInk,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: controller.ink.isEmpty ? null : controller.clear,
                  ),
                ],
              ),
              Row(
                children: [
                  for (final color in kInkPalette)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => controller.setColor(color),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            // Seçili renk vurgulu; diğerleri (özellikle beyaz açık
                            // zeminde) ince çerçeveyle görünür kalır.
                            border: Border.all(
                              color:
                                  !controller.eraser &&
                                      controller.color == color
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              width:
                                  !controller.eraser &&
                                      controller.color == color
                                  ? 3
                                  : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Slider(
                      // Aralık kalem türüne göre: fosforlu 12 px'te kalsaydı
                      // vurgulama işe yaramazdı.
                      value: pen.clampWidth(controller.widthPx),
                      min: pen.minWidth,
                      max: pen.maxWidth,
                      onChanged: controller.setWidth,
                    ),
                  ),
                ],
              ),
              if (hintText != null)
                Text(
                  hintText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Çizim modunda İKİ PARMAK yakınlaştırma + kaydırmayı görüntüleyicinin
/// dönüşüm matrisine kendisi uygular. Görüntüleyicinin kendi jest tanıyıcısına
/// güvenilmez: hem Flutter hem pdfrx InteractiveViewer'ı, mesafe değişmeden
/// birlikte hareket eden iki parmağı "pan" sayar ve `panEnabled:false`'ta
/// (çizim modu) tamamen yok sayar — "yazarken kaydıramıyorum" hatasının kökü.
///
/// Katman jest arenasına girmeyen [Listener] ile TÜM parmakları (sayfa dışı —
/// kenar boşluğu — dahil) sayar; ikinci parmak iner inmez [InkController.beginNav]
/// ile çizimi askıya alır ve odak/mesafe farkından matrisi günceller. Çizim
/// modunda görüntüleyicinin `panEnabled` VE `scaleEnabled`'ı kapatılmalıdır ki
/// jest çifte işlenmesin.
class InkNavLayer extends StatefulWidget {
  const InkNavLayer({
    super.key,
    required this.enabled,
    required this.controller,
    required this.getMatrix,
    required this.setMatrix,
    required this.minScale,
    required this.maxScale,
    this.clampToBounds = false,
    required this.child,
  });

  /// Yalnız çizim modunda aktif; kapalıyken dokunuşlara hiç karışmaz.
  final bool enabled;

  final InkController controller;

  /// Görüntüleyicinin güncel dönüşümü (hazır değilse null dönebilir).
  final Matrix4? Function() getMatrix;

  /// Yeni dönüşümü görüntüleyiciye yazar (görüntüleyici kendi sınırlarını
  /// ayrıca uygulayabilir — pdfrx `value` setter'ı konumu normalleştirir).
  final ValueChanged<Matrix4> setMatrix;

  /// Toplam ölçek bu aralıkta tutulur.
  final double minScale;
  final double maxScale;

  /// true ise çeviri, içeriğin (bu katmanla aynı boyutta varsayılır) görünür
  /// alanı örtmesini koruyacak şekilde kırpılır (Flutter InteractiveViewer'lı
  /// slayt görünümü — doğrudan controller yazımı IV sınır denetiminden geçmez).
  final bool clampToBounds;

  final Widget child;

  @override
  State<InkNavLayer> createState() => _InkNavLayerState();
}

class _InkNavLayerState extends State<InkNavLayer> {
  /// Basılı parmaklar: pointer id → katman-yerel konum.
  final Map<int, Offset> _pts = {};
  Offset? _lastFocal;
  double? _lastDist;

  void _reset() {
    _lastFocal = null;
    _lastDist = null;
  }

  (Offset, double) _focalAndDist() {
    final pts = _pts.values.toList();
    final focal = (pts[0] + pts[1]) / 2;
    return (focal, (pts[0] - pts[1]).distance);
  }

  void _down(PointerDownEvent e) {
    if (!widget.enabled) return;
    _pts[e.pointer] = e.localPosition;
    if (_pts.length == 2) {
      widget.controller.beginNav();
      final (focal, dist) = _focalAndDist();
      _lastFocal = focal;
      _lastDist = dist;
    } else if (_pts.length > 2) {
      _reset();
    }
  }

  void _move(PointerMoveEvent e) {
    if (!widget.enabled || !_pts.containsKey(e.pointer)) return;
    _pts[e.pointer] = e.localPosition;
    if (_pts.length != 2) return;
    final matrix = widget.getMatrix();
    if (matrix == null) return;
    final (focal, dist) = _focalAndDist();
    final lastFocal = _lastFocal, lastDist = _lastDist;
    _lastFocal = focal;
    _lastDist = dist;
    if (lastFocal == null || lastDist == null || lastDist <= 0 || dist <= 0) {
      return;
    }
    final scale = matrix.getMaxScaleOnAxis();
    // Toplam ölçek [minScale, maxScale] dışına çıkmayacak kadar ölçekle.
    final k =
        (scale * (dist / lastDist)).clamp(widget.minScale, widget.maxScale) /
        scale;
    final pan = focal - lastFocal;
    var m = Matrix4.translationValues(pan.dx, pan.dy, 0).multiplied(matrix);
    if (k != 1) {
      m = Matrix4.translationValues(focal.dx, focal.dy, 0)
          .multiplied(Matrix4.diagonal3Values(k, k, 1))
          .multiplied(Matrix4.translationValues(-focal.dx, -focal.dy, 0))
          .multiplied(m);
    }
    if (widget.clampToBounds) m = _clamp(m);
    widget.setMatrix(m);
  }

  void _up(int pointer) {
    if (_pts.remove(pointer) == null) return;
    if (_pts.length < 2) {
      widget.controller.endNav();
      _reset();
    } else {
      final (focal, dist) = _focalAndDist();
      _lastFocal = focal;
      _lastDist = dist;
    }
  }

  /// İçerik bu katmanla aynı boyutta: çeviri, görüntü alanında boşluk
  /// açılmayacak aralığa kırpılır.
  Matrix4 _clamp(Matrix4 m) {
    final box = context.size;
    if (box == null || box.isEmpty) return m;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final x = t.x.clamp(box.width * (1 - s), 0.0).toDouble();
    final y = t.y.clamp(box.height * (1 - s), 0.0).toDouble();
    return Matrix4.translationValues(
      x,
      y,
      0,
    ).multiplied(Matrix4.diagonal3Values(s, s, 1));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (e) => _up(e.pointer),
      onPointerCancel: (e) => _up(e.pointer),
      child: widget.child,
    );
  }
}

/// Bir sayfa/slaydın çizgilerini oranlardan ekran boyutuna ölçekleyerek çizer.
class InkPainter extends CustomPainter {
  InkPainter(List<InkStroke> strokes, this.page, {this.revision = 0})
    // SAYFA SÜZGECİ ÖNCEDEN: `paint` her karede TÜM belgenin çizgilerini
    // geziyordu (başka sayfalarınkini de). Uzun bir çizim oturumunda her yeni
    // nokta, o ana kadarki bütün noktaların yeniden taranması demekti —
    // "kasma birikip artıyor" tarifinin çizim tarafındaki karşılığı.
    : strokes = [
        for (final s in strokes)
          if (s.page == page) s,
      ];

  final List<InkStroke> strokes;
  final int page;

  /// Denetleyicinin değişim sayacı: [shouldRepaint] buna bakar.
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = inkPaint(Color(s.color), s.width * size.width);
      if (s.points.length == 2) {
        canvas.drawCircle(
          Offset(s.points[0] * size.width, s.points[1] * size.height),
          s.width * size.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()
        ..moveTo(s.points[0] * size.width, s.points[1] * size.height);
      for (var i = 2; i < s.points.length; i += 2) {
        path.lineTo(s.points[i] * size.width, s.points[i + 1] * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// KÖK NEDEN: burası KOŞULSUZ `true` döndürüyordu — çizgiler hiç
  /// değişmemişken bile (görüntüleyicinin her yeniden çiziminde) tüm katman
  /// yeniden rasterize ediliyordu.
  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) =>
      oldDelegate.revision != revision || oldDelegate.page != page;
}
