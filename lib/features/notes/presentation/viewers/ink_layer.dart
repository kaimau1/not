import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../../core/l10n_ext.dart';
import '../../domain/arrow.dart';
import '../../domain/attachment.dart';
import 'ink_pen.dart';
import 'ink_tools.dart';

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
    : _ink = [...initial] {
    // Son kullanılan kalem ([InkToolMemory]): her çizim ekranı yeni
    // denetleyici kurduğundan seçim her açılışta siyah tükenmeze dönüyordu.
    final penIndex = InkToolMemory.pen;
    if (penIndex != null && penIndex >= 0 && penIndex < InkPen.values.length) {
      pen = InkPen.values[penIndex];
    }
    final rememberedColor = InkToolMemory.color;
    if (rememberedColor != null) color = Color(rememberedColor);
    final rememberedWidth = InkToolMemory.width;
    widthPx = rememberedWidth == null
        ? pen.defaultWidth
        : pen.clampWidth(rememberedWidth);
    opacity = InkToolMemory.opacity;
    penOnly = InkToolMemory.penOnly;
    pressure = InkToolMemory.pressure;
    shapeSnap = InkToolMemory.shapeSnap;
    partialEraser = InkToolMemory.partialEraser;
  }

  /// Çizim değişince güncel çizgi listesiyle çağrılır (kaydetme).
  final ValueChanged<List<InkStroke>> onChanged;

  List<InkStroke> _ink;
  List<InkStroke> get ink => _ink;

  bool editing = false;
  bool eraser = false;

  /// **OK** aracı seçili mi? Açıkken parmak serbest çizmez: bastığı yer okun
  /// KUYRUĞU, kaldırdığı yer UCU olur (kullanıcı isteği 2026-08-08: "bir de ok
  /// işareti çekme istiyorum"). Elle çizilen ok hiçbir zaman düz çıkmıyor.
  bool arrow = false;

  /// Seçili ŞEKİL (düz çizgi / dikdörtgen / elips); null = serbest çizim.
  /// Ok gibi bastığın yerden kaldırdığın yere çizilir, kayda sıradan çizgi
  /// olarak yazılır ([inkShapePoints]).
  InkShape? shape;

  /// Kullanıcının seçtiği renk — SAYDAMLIKSIZ hâli. Çizgiye yazılırken
  /// kalemin saydamlığı uygulanır ([penColor]).
  Color color = kInkPalette.first;

  /// Kalem türü (tükenmez / keçeli / fosforlu).
  InkPen pen = InkPen.pen;

  /// Ekrandaki (ölçeklenmiş) sayfa üzerinde piksel kalınlık; kaydedilirken
  /// sayfa genişliğinin oranına çevrilir.
  double widthPx = InkPen.pen.defaultWidth;

  /// Tükenmez/keçeli ŞEFFAFLIĞI (0,1–1). Fosforlunun saydamlığı sabit:
  /// türü saydamlıktan okunuyor (bkz. ink_pen.dart).
  double opacity = 1;

  /// **YALNIZ KALEMLE YAZ** (kullanıcı isteği 2026-10-23: "parmakla basınca
  /// yazmayıp kalemle yazması, parmakla yakınlaştırma ve kaydırma"): açıkken
  /// parmak ÇİZMEZ — tek parmak kaydırır, iki parmak yakınlaştırır
  /// ([InkNavLayer]); kalem (ve fare) çizer. Avuç içi de böylece çizmez.
  /// İlk kalem dokunuşunda kendiliğinden açılır (kullanıcı elle seçmediyse).
  bool penOnly = false;

  /// Basınç algısı: kalemle çizilen çizginin kalınlığı bastırmaya göre değişir.
  bool pressure = true;

  /// Basılı tutunca şekle dönüştür (bkz. [recognizeInkShape]).
  bool shapeSnap = true;

  /// Kısmi silgi: yalnız silginin değdiği kısım silinir, çizgi bölünür.
  bool partialEraser = false;

  // ── KEMENT (seçim) ────────────────────────────────────────────────────
  // Kullanıcı isteği 2026-10-30: "Samsung Notes gibi özelliklerimiz olsun".
  // Kement aracı açıkken çizilen kapalı eğrinin içindeki çizgiler seçilir;
  // seçimin içinden sürüklemek onları TAŞIR, renk seçmek BOYAR, "Sil" atar.

  /// Kement aracı seçili mi.
  bool lasso = false;

  /// Çizilmekte olan kementin noktaları (oranlı) ve sayfası.
  List<double>? _lassoPath;
  int? _lassoPage;

  /// Seçili çizgiler (nesne kimliğiyle — çizgiler değişmez, taşıma yenisini
  /// kurar).
  List<InkStroke> _selected = const [];
  List<InkStroke> get selected => _selected;
  bool get hasSelection => _selected.isNotEmpty;

  /// Seçimin sayfası (seçim tek sayfada olur).
  int? get selectionPage => _selected.isEmpty ? null : _selected.first.page;

  /// Kement noktaları (çizimi sürerken; [page] sayfasında değilse null).
  List<double>? lassoPathOn(int page) => _lassoPage == page ? _lassoPath : null;

  /// Seçimin oranlı çevreleyen kutusu.
  Rect? get selectionBounds {
    if (_selected.isEmpty) return null;
    var l = double.infinity, t = double.infinity;
    var r = -double.infinity, b = -double.infinity;
    for (final s in _selected) {
      for (var i = 0; i + 1 < s.points.length; i += 2) {
        l = math.min(l, s.points[i]);
        r = math.max(r, s.points[i]);
        t = math.min(t, s.points[i + 1]);
        b = math.max(b, s.points[i + 1]);
      }
    }
    if (l > r || t > b) return null;
    return Rect.fromLTRB(l, t, r, b);
  }

  bool _moving = false;
  double _moveX = 0, _moveY = 0;

  /// Kalemin HAVADAKİ yeri (S Pen gibi yaklaşmayı bildiren kalemler): sayfa
  /// ve yerel konum. Katman ucun kalınlığında bir önizleme çizer.
  final hover = ValueNotifier<(int, Offset)?>(null);

  // ── BASILI TUTUNCA ŞEKİL ──────────────────────────────────────────────
  Timer? _holdTimer;
  double _holdX = 0, _holdY = 0;

  /// Etkin çizginin sayfa boyu (şekil tanıma piksel uzayında yapılır).
  Size _activeSize = Size.zero;

  /// Etkin çizgi şekle oturdu: kalkana dek uzamaz.
  bool _snapped = false;

  /// Çizgiye yazılan renk: seçilen renk + kalemin saydamlığı (+ şeffaflık).
  Color get penColor => pen == InkPen.highlighter
      ? pen.apply(color)
      : color.withAlpha((pen.alpha * opacity).round().clamp(26, 255));

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

  /// Çizime kabul edilen parmak/kalem kimlikleri: "yalnız kalem"de parmak
  /// sayılmaz, kalkışı da sayacı düşürmez.
  final Set<int> _accepted = {};

  /// Kalemin yan düğmesi basılıyken ya da kalem TERS çevrilmişken (silgi
  /// ucu) bu çizgi boyunca silgi — araç değiştirmeden sil.
  bool _tempEraser = false;
  bool get _erasing => eraser || _tempEraser;

  /// Şekil/ok çiziminin başlangıç noktası (oranlı).
  double _startX = 0, _startY = 0;

  /// Geri al / yinele: her jestten ÖNCEKİ çizgi listesi (listeler
  /// paylaşımlı, kopya değil — çizgiler değişmez). Silgiyle silinen de geri
  /// gelir (eskiden geri al yalnız son çizgiyi kaldırıyordu).
  final List<List<InkStroke>> _history = [];
  final List<List<InkStroke>> _future = [];
  static const _historyMax = 100;
  List<InkStroke>? _gestureBase;

  bool get canUndo => _history.isNotEmpty || _ink.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;

  /// Bu oturumda bir kalem (stylus) görüldü mü — araç çubuğu "yalnız kalem"
  /// düğmesini öne çıkarır.
  static bool stylusSeen = false;

  /// [InkNavLayer] iki parmak jestini sürerken true: sayfa katmanı çizim
  /// girdisini tamamen yok sayar (parmaklardan biri sayfa dışına — kenar
  /// boşluğuna — düşse bile çizgi başlamaz/uzamaz).
  bool _nav = false;

  /// Kalem (stylus) şu an ekrana değiyor mu — [InkNavLayer] bu sırada
  /// parmakları (avuç içi) yok sayar.
  bool get stylusDown => _stylusDown > 0;
  int _stylusDown = 0;

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
    if (value) {
      arrow = false;
      shape = null;
      _leaveLasso();
    }
    notifyListeners();
  }

  /// Kement aracını açar/kapatır; kapanınca seçim bırakılır.
  void setLasso(bool value) {
    if (lasso == value) return;
    lasso = value;
    if (value) {
      eraser = false;
      arrow = false;
      shape = null;
    } else {
      _leaveLasso();
    }
    notifyListeners();
  }

  void _leaveLasso() {
    lasso = false;
    _lassoPath = null;
    _lassoPage = null;
    _selected = const [];
    _moving = false;
  }

  /// Seçimi bırakır (araç kement kalır).
  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected = const [];
    notifyListeners();
  }

  /// Seçili çizgileri siler.
  void deleteSelection() {
    if (_selected.isEmpty) return;
    final gone = _selected.toSet();
    _pushHistory(_ink);
    _ink = [
      for (final s in _ink)
        if (!gone.contains(s)) s,
    ];
    _selected = const [];
    _dirty = true;
    save();
    notifyListeners();
  }

  /// Seçili çizgileri [value] rengine boyar; her çizgi kendi saydamlığını
  /// (fosforlu/şeffaf kalem) korur.
  void _recolorSelection(Color value) {
    final map = <InkStroke, InkStroke>{
      for (final s in _selected)
        s: InkStroke(
          page: s.page,
          color: value.withAlpha((s.color >> 24) & 0xFF).toARGB32(),
          width: s.width,
          points: s.points,
          arrow: s.arrow,
          pressures: s.pressures,
        ),
    };
    _pushHistory(_ink);
    _ink = [for (final s in _ink) map[s] ?? s];
    _selected = [for (final s in _selected) map[s]!];
    _dirty = true;
    save();
  }

  void setShapeSnap(bool value) {
    shapeSnap = value;
    InkToolMemory.saveShapeSnap(value);
    notifyListeners();
  }

  void setPartialEraser(bool value) {
    partialEraser = value;
    InkToolMemory.savePartialEraser(value);
    notifyListeners();
  }

  /// Ok aracını açar/kapatır. Kalem türü ve renk AYNEN geçerli kalır: ok da
  /// bir çizgidir, yalnız ucuna başlık çizilir.
  void setArrow(bool value) {
    if (arrow == value) return;
    arrow = value;
    if (value) {
      eraser = false;
      shape = null;
      _leaveLasso();
    }
    notifyListeners();
  }

  /// Şekil aracını seçer (null = serbest çizim). Kalem türü/renk geçerli.
  void setShape(InkShape? value) {
    shape = value;
    if (value != null) {
      eraser = false;
      arrow = false;
      _leaveLasso();
    }
    notifyListeners();
  }

  void setColor(Color value) {
    // Kementle seçim varken renk SEÇİMİ boyar; kalemin rengi de değişir ki
    // ardından yazılan aynı renkte olsun.
    if (_selected.isNotEmpty) _recolorSelection(value);
    color = value;
    eraser = false;
    if (!kInkPalette.contains(value)) {
      InkToolMemory.rememberColor(value.toARGB32());
    }
    _remember();
    notifyListeners();
  }

  /// Kalem türünü değiştirir. Kalınlık türün kendi aralığına taşınır:
  /// fosforluya geçip 3 px'te kalmak "fosforlu çalışmıyor" izlenimi veriyordu.
  void setPen(InkPen value) {
    if (pen == value && !eraser && !arrow && shape == null && !lasso) return;
    final wasDefault = widthPx == pen.defaultWidth;
    pen = value;
    eraser = false;
    arrow = false;
    shape = null;
    _leaveLasso();
    widthPx = wasDefault ? value.defaultWidth : value.clampWidth(widthPx);
    _remember();
    notifyListeners();
  }

  void setWidth(double value) {
    widthPx = pen.clampWidth(value);
    _remember();
    notifyListeners();
  }

  void setOpacity(double value) {
    opacity = value.clamp(0.1, 1.0).toDouble();
    _remember();
    notifyListeners();
  }

  /// "Yalnız kalemle yaz"ı açar/kapatır. [chosen]: kullanıcının kendi
  /// seçimi (bir daha kendiliğinden açılmaz).
  void setPenOnly(bool value, {bool chosen = true}) {
    penOnly = value;
    InkToolMemory.savePenOnly(value, chosen: chosen);
    notifyListeners();
  }

  void setPressure(bool value) {
    pressure = value;
    InkToolMemory.savePressure(value);
    notifyListeners();
  }

  void _remember() => InkToolMemory.saveTool(
    color: color.toARGB32(),
    pen: pen.index,
    width: widthPx,
    opacity: opacity,
  );

  void save() {
    if (!_dirty) return;
    _dirty = false;
    onChanged(_ink);
  }

  void _pushHistory(List<InkStroke> before) {
    _history.add(before);
    if (_history.length > _historyMax) _history.removeAt(0);
    _future.clear();
  }

  void undo() {
    _selected = const [];
    if (_history.isNotEmpty) {
      _future.add(_ink);
      _ink = _history.removeLast();
    } else if (_ink.isNotEmpty) {
      // Önceki oturumdan gelen çizim: eskisi gibi son çizgi kalkar.
      _future.add(_ink);
      _ink = _ink.sublist(0, _ink.length - 1);
    } else {
      return;
    }
    _dirty = true;
    save();
    notifyListeners();
  }

  void redo() {
    _selected = const [];
    if (_future.isEmpty) return;
    _history.add(_ink);
    _ink = _future.removeLast();
    _dirty = true;
    save();
    notifyListeners();
  }

  void clear() {
    if (_ink.isEmpty) return;
    _pushHistory(_ink);
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
    _selected = const [];
    _lassoPath = null;
    // Dışarıdan gelen liste geçmişi geçersiz kılar (geri al eski listeye
    // dönüp başka cihazın çizimini silmesin).
    _history.clear();
    _future.clear();
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
          x.arrow != y.arrow ||
          x.points.length != y.points.length) {
        return false;
      }
    }
    return true;
  }

  static bool _sameInstances(List<InkStroke> a, List<InkStroke> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  /// İki parmak gezinme başladı: başlamış çizgiyi geri al, çizimi askıya al.
  void beginNav() {
    if (_nav) return;
    _nav = true;
    _holdTimer?.cancel();
    _lassoPath = null;
    _moving = false;
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

  /// Bu tür girdi çizer mi: "yalnız kalem" açıkken parmak çizmez (kalem,
  /// ters kalem ve fare çizer).
  bool accepts(PointerDeviceKind kind) =>
      !penOnly || kind != PointerDeviceKind.touch;

  /// [pointer] verilirse dokunuş türüne göre süzülür (bkz. [accepts]);
  /// [pressure] 0–1 (kalemde), [stylusEraser] yan düğme / ters uç.
  void pointerDown(
    int page,
    Offset local,
    Size size, {
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    double? pressure,
    bool stylusEraser = false,
  }) {
    final stylus =
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
    if (stylus) {
      _stylusDown++;
      stylusSeen = true;
      // İlk kalem dokunuşu: kullanıcı seçmediyse "yalnız kalem" açılır —
      // kalemle yazarken avuç içi/parmak çizgi bırakmasın.
      if (!penOnly && !InkToolMemory.penOnlyChosen) {
        setPenOnly(true, chosen: false);
      }
    }
    if (pointer != null) {
      if (!accepts(kind)) return;
      _accepted.add(pointer);
    }
    _pointers++;
    if (_nav) return;
    if (_pointers > 1) {
      // İkinci parmak = yakınlaştırma/kaydırma niyeti: yeni başlamış çizgiyi
      // geri al ki ekranda kırıntı kalmasın.
      if (_active != null) _ink = [..._ink]..remove(_active);
      _active = null;
      _holdTimer?.cancel();
      _lassoPath = null;
      _moving = false;
      notifyListeners();
      return;
    }
    hover.value = null;
    _gestureBase = _ink;
    _tempEraser = stylusEraser;
    if (lasso && !_tempEraser) {
      final x = local.dx / size.width;
      final y = local.dy / size.height;
      final bounds = selectionBounds;
      if (bounds != null &&
          selectionPage == page &&
          bounds.inflate(0.03).contains(Offset(x, y))) {
        _moving = true;
        _moveX = x;
        _moveY = y;
      } else {
        _selected = const [];
        _lassoPath = [x, y];
        _lassoPage = page;
      }
      notifyListeners();
      return;
    }
    if (_erasing) {
      _eraseAt(page, local, size);
      notifyListeners();
      return;
    }
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    _startX = x;
    _startY = y;
    final shape = this.shape;
    final usePressure =
        this.pressure && stylus && pressure != null && !arrow && shape == null;
    final stroke = InkStroke(
      page: page,
      color: penColor.toARGB32(),
      width: widthPx / size.width,
      // Ok İKİ noktayla doğar (kuyruk + uç); uç parmakla birlikte taşınır.
      points: arrow
          ? [x, y, x, y]
          : shape != null
          ? inkShapePoints(shape, x, y, x, y)
          : [x, y],
      arrow: arrow,
      pressures: usePressure ? [pressure] : null,
    );
    _dirty = true;
    _active = stroke;
    _activeSize = size;
    _snapped = false;
    _holdX = x;
    _holdY = y;
    _ink = [..._ink, stroke];
    notifyListeners();
  }

  /// Kalem/parmak çizginin sonunda kıpırdamadan durdu: çizgi tanınan şekle
  /// oturur (bkz. [recognizeInkShape]).
  void _snapActive() {
    final active = _active;
    if (active == null || _pointers != 1 || _nav || active.arrow) return;
    final size = _activeSize;
    if (size.isEmpty) return;
    final px = <Offset>[
      for (var i = 0; i + 1 < active.points.length; i += 2)
        Offset(
          active.points[i] * size.width,
          active.points[i + 1] * size.height,
        ),
    ];
    final found = recognizeInkShape(px);
    if (found == null) return;
    final points = inkShapePoints(
      found.shape,
      found.a.dx / size.width,
      found.a.dy / size.height,
      found.b.dx / size.width,
      found.b.dy / size.height,
    );
    // Basınç noktaya bağlı; şekil düzgün kalınlıkla çizilir.
    final snapped = InkStroke(
      page: active.page,
      color: active.color,
      width: active.width,
      points: points,
    );
    _ink = [for (final s in _ink) identical(s, active) ? snapped : s];
    _active = snapped;
    _snapped = true;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    hover.dispose();
    super.dispose();
  }

  void pointerMove(
    int page,
    Offset local,
    Size size, {
    int? pointer,
    double? pressure,
  }) {
    if (pointer != null && !_accepted.contains(pointer)) return;
    if (_nav || _pointers != 1) return;
    if (lasso && !_tempEraser) {
      final x = local.dx / size.width;
      final y = local.dy / size.height;
      if (_moving) {
        _translateSelection(x - _moveX, y - _moveY);
        _moveX = x;
        _moveY = y;
      } else if (_lassoPage == page) {
        _lassoPath?.addAll([x, y]);
      }
      notifyListeners();
      return;
    }
    if (_erasing) {
      _eraseAt(page, local, size);
      notifyListeners();
      return;
    }
    final active = _active;
    if (active == null || _snapped) return;
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    // OK: nokta EKLENMEZ, ucu taşınır — parmak nereye giderse ok oraya bakar.
    if (active.arrow) {
      active.points[2] = x;
      active.points[3] = y;
      notifyListeners();
      return;
    }
    final shape = this.shape;
    if (shape != null) {
      active.points
        ..clear()
        ..addAll(inkShapePoints(shape, _startX, _startY, x, y));
      notifyListeners();
      return;
    }
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
    final pressures = active.pressures;
    if (pressures != null) {
      pressures.add(pressure ?? (pressures.isEmpty ? 0.5 : pressures.last));
    }
    // Kıpırtı (kalemin titremesi) beklemeyi sıfırlamaz: zamanlayıcı ancak
    // uç gerçekten yol alınca yeniden kurulur.
    if (shapeSnap && math.max((x - _holdX).abs(), (y - _holdY).abs()) > 0.006) {
      _holdX = x;
      _holdY = y;
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 550), _snapActive);
    }
    notifyListeners();
  }

  /// Seçimi oranlı (dx, dy) kadar taşır.
  void _translateSelection(double dx, double dy) {
    if (_selected.isEmpty || (dx == 0 && dy == 0)) return;
    final map = <InkStroke, InkStroke>{
      for (final s in _selected)
        s: s.copyWith(
          points: [
            for (var i = 0; i < s.points.length; i++)
              s.points[i] + (i.isEven ? dx : dy),
          ],
        ),
    };
    _ink = [for (final s in _ink) map[s] ?? s];
    _selected = [for (final s in _selected) map[s]!];
    _dirty = true;
  }

  /// Kement kapandı: içinde kalan çizgiler seçilir (noktalarının yarısından
  /// çoğu çokgenin içinde olan).
  void _closeLasso() {
    final path = _lassoPath;
    final page = _lassoPage;
    _lassoPath = null;
    if (path == null || page == null || path.length < 6) return;
    final picked = <InkStroke>[];
    for (final s in _ink) {
      if (s.page != page) continue;
      final samples = _sampled(s);
      var inside = 0;
      final n = samples.length ~/ 2;
      for (var i = 0; i + 1 < samples.length; i += 2) {
        if (inkPointInPolygon(samples[i], samples[i + 1], path)) inside++;
      }
      if (n > 0 && inside * 2 > n) picked.add(s);
    }
    _selected = picked;
    if (picked.isNotEmpty) HapticFeedback.selectionClick();
  }

  void pointerUp({
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
  }) {
    if (kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus) {
      _stylusDown = math.max(0, _stylusDown - 1);
    }
    if (pointer != null && !_accepted.remove(pointer)) return;
    _pointers = math.max(0, _pointers - 1);
    if (_pointers > 0) {
      notifyListeners();
      return;
    }
    _tempEraser = false;
    _holdTimer?.cancel();
    _snapped = false;
    if (lasso) {
      if (_moving) {
        _moving = false;
      } else {
        _closeLasso();
      }
    }
    // Ok ya da şekille yalnız DOKUNULDUYSA (sürüklenmediyse) ortada yönü
    // olmayan bir kırıntı kalır: atılır.
    final active = _active;
    if (active != null && (active.arrow || shape != null)) {
      final xs = [
        for (var i = 0; i < active.points.length; i += 2) active.points[i],
      ];
      final ys = [
        for (var i = 1; i < active.points.length; i += 2) active.points[i],
      ];
      final dx = xs.reduce(math.max) - xs.reduce(math.min);
      final dy = ys.reduce(math.max) - ys.reduce(math.min);
      if (dx < 0.01 && dy < 0.01) {
        _ink = [..._ink]..remove(active);
      }
    }
    _active = null;
    final base = _gestureBase;
    _gestureBase = null;
    if (base != null && !_sameInstances(base, _ink)) _pushHistory(base);
    save();
    notifyListeners();
  }

  void _eraseAt(int page, Offset local, Size size) {
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    if (partialEraser) {
      _erasePartAt(page, x, y);
      return;
    }
    final kept = <InkStroke>[];
    for (final s in _ink) {
      var hit = false;
      if (s.page == page) {
        // OK yalnız İKİ nokta taşır; gövdesine dokunmak da silmeli, yoksa
        // yalnız uçlarından yakalanan bir çizgi olurdu. Düz çizgi ve
        // dikdörtgenin kenarları da seyrek noktalı — aynı örnekleme.
        final samples = _sampled(s);
        for (var i = 0; i < samples.length; i += 2) {
          if ((samples[i] - x).abs() < _eraseRadius &&
              (samples[i + 1] - y).abs() < _eraseRadius) {
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

  /// KISMİ SİLGİ: çizgi yalnız silginin değdiği yerden kesilir, kalan
  /// parçalar ayrı çizgiler olur (basınç parçalarla taşınır). Ok bütün
  /// silinir — yarım ok anlamsız.
  void _erasePartAt(int page, double x, double y) {
    bool near(double px, double py) =>
        (px - x).abs() < _eraseRadius && (py - y).abs() < _eraseRadius;
    var changed = false;
    final out = <InkStroke>[];
    for (final s in _ink) {
      if (s.page != page) {
        out.add(s);
        continue;
      }
      final sampled = _sampled(s);
      var touched = false;
      for (var i = 0; i + 1 < sampled.length; i += 2) {
        if (near(sampled[i], sampled[i + 1])) {
          touched = true;
          break;
        }
      }
      if (!touched) {
        out.add(s);
        continue;
      }
      changed = true;
      if (s.arrow) continue;
      // Seyrek çizgide (şekil) örnek noktalarla kesilir; basınç yoksa kaybı
      // yok, varsa nokta başına eşleştiği için yalnız yoğun çizgide taşınır.
      final dense = identical(sampled, s.points);
      final pressures = dense && s.hasPressure ? s.pressures : null;
      var run = <double>[];
      var runQ = <double>[];
      void flush() {
        if (run.length >= 4) {
          out.add(
            InkStroke(
              page: s.page,
              color: s.color,
              width: s.width,
              points: run,
              pressures: pressures == null ? null : runQ,
            ),
          );
        }
        run = <double>[];
        runQ = <double>[];
      }

      for (var i = 0; i + 1 < sampled.length; i += 2) {
        if (near(sampled[i], sampled[i + 1])) {
          flush();
        } else {
          run.addAll([sampled[i], sampled[i + 1]]);
          if (pressures != null) runQ.add(pressures[i ~/ 2]);
        }
      }
      flush();
    }
    if (!changed) return;
    _dirty = true;
    _ink = out;
  }

  /// Silgi için çizginin örnek noktaları: ardışık iki nokta arası silgi
  /// yarıçapından uzaksa ara noktalar eklenir (ok, düz çizgi, dikdörtgen).
  static List<double> _sampled(InkStroke s) {
    final p = s.points;
    if (p.length < 4) return p;
    var sparse = false;
    for (var i = 2; i + 1 < p.length; i += 2) {
      if ((p[i] - p[i - 2]).abs() > _eraseRadius ||
          (p[i + 1] - p[i - 1]).abs() > _eraseRadius) {
        sparse = true;
        break;
      }
    }
    if (!sparse) return p;
    final out = <double>[p[0], p[1]];
    for (var i = 2; i + 1 < p.length; i += 2) {
      final dx = p[i] - p[i - 2];
      final dy = p[i + 1] - p[i - 1];
      final steps = math.max(
        1,
        (math.max(dx.abs(), dy.abs()) / _eraseRadius).ceil(),
      );
      for (var k = 1; k <= steps; k++) {
        final t = k / steps;
        out
          ..add(p[i - 2] + dx * t)
          ..add(p[i - 1] + dy * t);
      }
    }
    return out;
  }
}

/// Bir sayfanın/slaytın üstüne serilen dokunma + çizim katmanı. İçeren
/// widget'ın tüm alanını kaplar (sayfa boyutu [LayoutBuilder]'dan alınır).
class InkPageLayer extends StatelessWidget {
  const InkPageLayer({super.key, required this.controller, required this.page});

  final InkController controller;

  /// 1 tabanlı sayfa/slayt numarası.
  final int page;

  /// Kalemin basıncı 0–1 aralığında; basınç bildirmeyen girdide null.
  static double? _pressure(PointerEvent e) {
    if (e.kind != PointerDeviceKind.stylus &&
        e.kind != PointerDeviceKind.invertedStylus) {
      return null;
    }
    final range = e.pressureMax - e.pressureMin;
    if (range <= 0) return null;
    return ((e.pressure - e.pressureMin) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Çizim kapalıyken katman dokunmayı hiç görmez.
      ignoring: !controller.editing,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          // Kalem HAVADA (S Pen yaklaşması): ucun kalınlığı/silgi halkası
          // önizlenir. Fare de aynı yoldan gelir — onda önizleme yok.
          void onHover(PointerEvent e) {
            if (e.kind != PointerDeviceKind.stylus &&
                e.kind != PointerDeviceKind.invertedStylus) {
              return;
            }
            controller.hover.value = (page, e.localPosition);
          }

          void onExit(PointerEvent e) {
            if (controller.hover.value?.$1 == page) {
              controller.hover.value = null;
            }
          }

          return MouseRegion(
            opaque: false,
            onHover: onHover,
            onExit: onExit,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) => controller.pointerDown(
                page,
                e.localPosition,
                size,
                pointer: e.pointer,
                kind: e.kind,
                pressure: _pressure(e),
                stylusEraser:
                    e.kind == PointerDeviceKind.invertedStylus ||
                    e.buttons & kSecondaryStylusButton != 0,
              ),
              onPointerMove: (e) => controller.pointerMove(
                page,
                e.localPosition,
                size,
                pointer: e.pointer,
                pressure: _pressure(e),
              ),
              onPointerUp: (e) =>
                  controller.pointerUp(pointer: e.pointer, kind: e.kind),
              onPointerCancel: (e) =>
                  controller.pointerUp(pointer: e.pointer, kind: e.kind),
              // Yalnız çizgiler değişince yeniden boyanır; görüntüleyici (PDF/slayt)
              // yeniden kurulmaz — bu yüzden çizim sırasında jest bozulmaz.
              // RepaintBoundary: tek bir çizgi uzarken üstteki PDF/slayt
              // katmanının yeniden boyanmasına gerek yok.
              child: RepaintBoundary(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    final painter = InkPainter(
                      controller.ink,
                      page,
                      revision: controller.revision,
                    );
                    // Ekran okuyucu (F4.7): tuval kendisi okunamaz; en azından
                    // sayfada çizim olduğu ve kaç çizgi olduğu söylenir.
                    return Semantics(
                      image: true,
                      label: painter.strokes.isEmpty
                          ? null
                          : context.l10n.inkSemantics(painter.strokes.length),
                      child: CustomPaint(
                        painter: painter,
                        foregroundPainter: _InkOverlayPainter.of(
                          controller,
                          page,
                          Theme.of(context).colorScheme.primary,
                        ),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Kement çizgisi, seçimin çerçevesi ve kalemin havadaki ucunun önizlemesi.
class _InkOverlayPainter extends CustomPainter {
  _InkOverlayPainter({
    required this.lassoPath,
    required this.selection,
    required this.accent,
    required this.hover,
  }) : super(repaint: hover);

  /// Sayfanın o anki kement/seçim durumu; havadaki kalem kendi
  /// dinleyicisiyle ([_HoverLook]) yalnız bu boyayıcıyı tazeler.
  static _InkOverlayPainter? of(
    InkController controller,
    int page,
    Color accent,
  ) => _InkOverlayPainter(
    lassoPath: controller.lassoPathOn(page),
    selection: controller.selectionPage == page
        ? controller.selectionBounds
        : null,
    accent: accent,
    hover: _HoverLook(controller, page),
  );

  final List<double>? lassoPath;
  final Rect? selection;
  final Color accent;
  final _HoverLook hover;

  @override
  void paint(Canvas canvas, Size size) {
    final path = lassoPath;
    if (path != null && path.length >= 4) {
      final p = Path()..moveTo(path[0] * size.width, path[1] * size.height);
      for (var i = 2; i + 1 < path.length; i += 2) {
        p.lineTo(path[i] * size.width, path[i + 1] * size.height);
      }
      canvas
        ..drawPath(p, Paint()..color = accent.withValues(alpha: 0.08))
        ..drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = accent,
        );
    }
    final sel = selection;
    if (sel != null) {
      final rect = Rect.fromLTRB(
        sel.left * size.width,
        sel.top * size.height,
        sel.right * size.width,
        sel.bottom * size.height,
      ).inflate(8);
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()..color = accent.withValues(alpha: 0.06),
        )
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = accent,
        );
    }
    final at = hover.position;
    if (at != null) {
      final controller = hover.controller;
      if (controller.eraser) {
        canvas.drawCircle(
          at,
          InkController._eraseRadius * size.width,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = accent,
        );
      } else if (!controller.lasso) {
        canvas.drawCircle(
          at,
          math.max(1.5, controller.widthPx / 2),
          Paint()..color = controller.penColor,
        );
      }
    }
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_InkOverlayPainter old) =>
      !identical(old.lassoPath, lassoPath) ||
      (lassoPath?.length ?? 0) != (old.lassoPath?.length ?? 0) ||
      old.selection != selection ||
      old.accent != accent;
}

/// Havadaki kalemin bu sayfadaki yeri — yalnız önizleme yeniden boyanır.
class _HoverLook extends Listenable {
  _HoverLook(this.controller, this.page);

  final InkController controller;
  final int page;

  Offset? get position {
    final value = controller.hover.value;
    return value != null && value.$1 == page ? value.$2 : null;
  }

  @override
  void addListener(VoidCallback listener) =>
      controller.hover.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.hover.removeListener(listener);
}

/// Kalem ayarları levhası: kalınlık önizlemesi, ŞEFFAFLIK, basınç algısı,
/// "yalnız kalemle yaz", son kullanılan renkler ve tümünü temizle.
class InkSettingsSheet extends StatelessWidget {
  const InkSettingsSheet({super.key, required this.controller});

  final InkController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pen = controller.pen;
    final highlighter = pen == InkPen.highlighter;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.inkSettings,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // ÖNİZLEME: seçili kalem, renk, kalınlık ve şeffaflıkla örnek
            // bir dalga — ayar değişince anında görünür.
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: CustomPaint(
                painter: _PenPreviewPainter(
                  color: controller.penColor,
                  width: controller.widthPx,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 96, child: Text(l10n.inkWidth)),
                Expanded(
                  child: Slider(
                    value: pen.clampWidth(controller.widthPx),
                    min: pen.minWidth,
                    max: pen.maxWidth,
                    label: controller.widthPx.toStringAsFixed(0),
                    onChanged: controller.setWidth,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(controller.widthPx.toStringAsFixed(0)),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 96, child: Text(l10n.inkOpacity)),
                Expanded(
                  child: Slider(
                    // Fosforlunun saydamlığı sabit (türü ondan okunuyor).
                    value: highlighter ? 0.4 : controller.opacity,
                    min: 0.1,
                    divisions: 9,
                    label:
                        '%${((highlighter ? 0.4 : controller.opacity) * 100).round()}',
                    onChanged: highlighter ? null : controller.setOpacity,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '%${((highlighter ? 0.4 : controller.opacity) * 100).round()}',
                  ),
                ),
              ],
            ),
            if (InkToolMemory.recentColors.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.inkRecentColors, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in InkToolMemory.recentColors)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => controller.setColor(Color(c)),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: controller.color.toARGB32() == c
                                ? scheme.primary
                                : scheme.outlineVariant,
                            width: controller.color.toARGB32() == c ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.draw),
              title: Text(l10n.inkPenOnlyTitle),
              subtitle: Text(l10n.inkPenOnlyInfo),
              value: controller.penOnly,
              onChanged: controller.setPenOnly,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.line_weight),
              title: Text(l10n.inkPressureTitle),
              subtitle: Text(l10n.inkPressureInfo),
              value: controller.pressure,
              onChanged: controller.setPressure,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.auto_fix_high),
              title: Text(l10n.inkShapeSnapTitle),
              subtitle: Text(l10n.inkShapeSnapInfo),
              value: controller.shapeSnap,
              onChanged: controller.setShapeSnap,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.cleaning_services_outlined),
              title: Text(l10n.inkPartialEraserTitle),
              subtitle: Text(l10n.inkPartialEraserInfo),
              value: controller.partialEraser,
              onChanged: controller.setPartialEraser,
            ),
            _AutoStylusSwitch(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note),
              title: Text(l10n.inkStylusTipsTitle),
              subtitle: Text(l10n.inkStylusTips),
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: controller.ink.isEmpty
                  ? null
                  : () {
                      controller.clear();
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.clearInk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kalem ayarı önizlemesi: bir S dalgası.
class _PenPreviewPainter extends CustomPainter {
  _PenPreviewPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(16, size.height / 2);
    final span = size.width - 32;
    for (var i = 1; i <= 40; i++) {
      final t = i / 40;
      path.lineTo(
        16 + span * t,
        size.height / 2 + math.sin(t * math.pi * 2) * size.height * 0.22,
      );
    }
    canvas.drawPath(path, inkPaint(color, width));
  }

  @override
  bool shouldRepaint(covariant _PenPreviewPainter old) =>
      old.color != color || old.width != width;
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

  /// Kalem (stylus) gezinmeye karışmaz; kalem yazarken ekrana değen parmak
  /// (avuç içi) da gezinme sayılmaz.
  bool _ignored(PointerEvent e) =>
      e.kind == PointerDeviceKind.stylus ||
      e.kind == PointerDeviceKind.invertedStylus ||
      e.kind == PointerDeviceKind.mouse ||
      widget.controller.stylusDown;

  void _down(PointerDownEvent e) {
    if (!widget.enabled || _ignored(e)) return;
    _pts[e.pointer] = e.localPosition;
    if (_pts.length == 1 && widget.controller.penOnly) {
      // "Yalnız kalem": tek parmak KAYDIRIR (çizmez).
      _lastFocal = e.localPosition;
      _lastDist = null;
    } else if (_pts.length == 2) {
      // "Yalnız kalem"de parmak zaten çizmiyor; iptal edilecek çizgi kalemin
      // olabilir — dokunma.
      if (!widget.controller.penOnly) widget.controller.beginNav();
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
    if (_pts.length == 1 && widget.controller.penOnly) {
      final matrix = widget.getMatrix();
      final last = _lastFocal;
      _lastFocal = e.localPosition;
      if (matrix == null || last == null) return;
      final pan = e.localPosition - last;
      var m = Matrix4.translationValues(pan.dx, pan.dy, 0).multiplied(matrix);
      if (widget.clampToBounds) m = _clamp(m);
      widget.setMatrix(m);
      return;
    }
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
    if (_pts.length == 1 && widget.controller.penOnly) {
      // İki parmaktan biri kalktı: kalan parmakla kaydırma sürer.
      widget.controller.endNav();
      _lastFocal = _pts.values.first;
      _lastDist = null;
    } else if (_pts.length < 2) {
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
      if (s.hasPressure && !s.arrow) {
        _paintPressure(canvas, size, s);
        continue;
      }
      final paint = inkPaint(Color(s.color), s.width * size.width);
      if (s.arrow && s.points.length >= 4) {
        final tail = Offset(
          s.points[0] * size.width,
          s.points[1] * size.height,
        );
        final head = Offset(
          s.points[2] * size.width,
          s.points[3] * size.height,
        );
        final geo = arrowGeometry(tail, head, s.width * size.width);
        canvas
          ..drawLine(tail, geo.lineEnd, paint)
          ..drawPath(
            Path()
              ..moveTo(head.dx, head.dy)
              ..lineTo(geo.left.dx, geo.left.dy)
              ..lineTo(geo.right.dx, geo.right.dy)
              ..close(),
            Paint()
              ..color = Color(s.color)
              ..style = PaintingStyle.fill,
          );
        continue;
      }
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

  /// Basınçlı çizgi: her parça kendi kalınlığıyla. Saydam renkte parçalar
  /// birleşim yerlerinde üst üste binip koyu boncuklar bırakmasın diye
  /// çizgi OPAK çizilip katman saydamlıkla birleştirilir.
  static void _paintPressure(Canvas canvas, Size size, InkStroke s) {
    final color = Color(s.color);
    final translucent = color.a < 1;
    final base = s.width * size.width;
    final p = s.points;
    final q = s.pressures!;
    final paint = inkPaint(translucent ? color.withAlpha(255) : color, base)
      ..strokeCap = StrokeCap.round;
    if (translucent) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((color.a * 255).round(), 0, 0, 0),
      );
    }
    if (p.length == 2) {
      canvas.drawCircle(
        Offset(p[0] * size.width, p[1] * size.height),
        base * inkPressureFactor(q[0]) / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      for (var i = 2; i + 1 < p.length; i += 2) {
        final j = i ~/ 2;
        paint.strokeWidth = base * inkPressureFactor((q[j - 1] + q[j]) / 2);
        canvas.drawLine(
          Offset(p[i - 2] * size.width, p[i - 1] * size.height),
          Offset(p[i] * size.width, p[i + 1] * size.height),
          paint,
        );
      }
    }
    if (translucent) canvas.restore();
  }

  /// KÖK NEDEN: burası KOŞULSUZ `true` döndürüyordu — çizgiler hiç
  /// değişmemişken bile (görüntüleyicinin her yeniden çiziminde) tüm katman
  /// yeniden rasterize ediliyordu.
  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) =>
      oldDelegate.revision != revision || oldDelegate.page != page;
}

/// "Kalemi otomatik algıla" (cihaz tercihi, [InkToolMemory.autoStylus]):
/// denetleyiciye bağlı değil — editör kalem dokunuşunda buna bakar.
class _AutoStylusSwitch extends StatefulWidget {
  @override
  State<_AutoStylusSwitch> createState() => _AutoStylusSwitchState();
}

class _AutoStylusSwitchState extends State<_AutoStylusSwitch> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.edit_note),
      title: Text(l10n.inkAutoStylusTitle),
      subtitle: Text(l10n.inkAutoStylusInfo),
      value: InkToolMemory.autoStylus,
      onChanged: (value) =>
          setState(() => InkToolMemory.saveAutoStylus(value)),
    );
  }
}
