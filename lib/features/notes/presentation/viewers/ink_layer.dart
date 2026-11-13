import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/hold_progress_ring.dart';
import '../../domain/attachment.dart';
import '../../domain/ink_pack.dart';
import 'ink_pen.dart';
import 'ink_recognize.dart';
import 'ink_stroke_paint.dart';
import 'ink_tools.dart';
import '../../../../app/theme/app_tokens.dart';

/// PDF ve slayt görüntüleyicilerinin ortak elle-yazma katmanı. Çizim dosyaya
/// gömülmez; sayfa/slayt oranlı (0–1) vektör olarak [InkStroke] listesinde
/// tutulur ve [onChanged] ile üst katmana (ek → not → Firestore) verilir.
///
/// TEK parmak çizer, İKİ parmak yakınlaştırır: katman jest arenasına girmeyen
/// [Listener] kullanır (dokunuş alttaki görüntüleyiciye de ulaşır). Çizim
/// modunda görüntüleyicinin `panEnabled`'ı kapalı, `scaleEnabled`'ı açık
/// bırakılır — tek parmak çizer, iki parmak yakınlaştırır. İkinci parmak inince
/// başlamış çizgi iptal edilir ki iki parmak jesti çizime dönüşmesin.
/// Basılı tutma jestlerinin (şekle oturt, silgi önerisi) bekleme süresi.
const kInkHoldDuration = Duration(milliseconds: 550);

/// Bekleyen basılı tutma jesti (bkz. [InkController.holdProgress]).
@immutable
class InkHoldProgress {
  const InkHoldProgress({
    required this.page,
    required this.at,
    required this.eraser,
    required this.serial,
    required this.duration,
  });

  final int page;

  /// Oranlı (0–1) konum.
  final Offset at;

  /// true = silgi önerisi, false = şekle oturt.
  final bool eraser;
  final int serial;
  final Duration duration;
}

class InkController extends ChangeNotifier {
  InkController({required List<InkStroke> initial, required this.onChanged})
    : _ink = [...initial] {
    // Araç KOPYALANMAZ (F63.2): aşağıdaki alanlar [InkToolMemory]'yi okur —
    // tepside seçilen silgi/renk her yüzeyde aynı anda geçerli.
    InkToolMemory.openSession();
    InkToolMemory.toolRev.addListener(_onToolChanged);
  }

  /// **ETKİN YÜZEY** (KALEM K4): son çizim dokunuşunu alan denetleyici.
  /// Editörün tepsisi geri al / yineleyi buna yollar (bkz. `PenTray`).
  /// Kapanan denetleyici kendini bırakır.
  static InkController? active;

  /// Araç başka bir yüzeyden değişti (ya da bu yüzeyden: tek yol).
  void _onToolChanged() {
    // Kement başka yerden bırakıldıysa buradaki seçim de bırakılır.
    if (!lasso && !_fixEdit && (_selected.isNotEmpty || _lassoPath != null)) {
      _selected = const [];
      _lassoPath = null;
      _lassoPage = null;
      _moving = false;
      _resizing = false;
    }
    notifyListeners();
  }

  /// Araç değişti: bütün açık denetleyiciler (bu dahil) dinleyicisine söyler.
  void _toolChanged() => InkToolMemory.toolChanged();

  /// Çizgi bitince tanınan şekil için düzeltme işaretçisi (bkz.
  /// [suggestion]).
  bool get shapeSuggest => InkToolMemory.shapeSuggest;
  set shapeSuggest(bool value) => InkToolMemory.shapeSuggest = value;

  /// Son çizginin düzeltme önerisi: katman sağ altına küçük işaretçi koyar;
  /// dokununca [applySuggestion]. Ayrı bildirici: çizgileri yeniden boyatmaz.
  /// Zamanlayıcısız: bir sonraki dokunuşta / geri alda kalkar.
  final suggestion = ValueNotifier<InkSuggestion?>(null);

  /// Çarpının ilk kolu / okun gövdesi için bir önceki serbest çizgi.
  InkStroke? _lastFree;
  DateTime _lastFreeAt = DateTime(0);
  Size _lastFreeSize = Size.zero;

  void setShapeSuggest(bool value) {
    shapeSuggest = value;
    InkToolMemory.saveShapeSuggest(value);
    if (!value) dismissSuggestion();
    _toolChanged();
  }

  void dismissSuggestion() => suggestion.value = null;

  /// **BASILI TUT = SİLGİ** (kullanıcı isteği 2026-11-08: "parmakla yapılan
  /// kalem yazılarının üzerine basılı tutunca silgi butonu çıksın, silgi
  /// seçilsin"). Parmak var olan bir çizginin üstünde kıpırdamadan 550 ms
  /// durunca o noktada küçük silgi düğmesi belirir; dokununca silgi aracı
  /// seçilir. O basışın bıraktığı nokta silinir. Ayrı bildirici: çizgileri
  /// yeniden boyatmaz. Bedel: yalnız parmak İNİŞİNDE o sayfanın çizgilerine
  /// tek yakınlık taraması (çizim karesinde iş yok).
  final eraserOffer = ValueNotifier<({int page, Offset at})?>(null);
  Timer? _eraserHold;
  Offset? _eraserHoldAt;

  /// **JEST DOLUM HALKASI** (kullanıcı isteği 2026-11-09: "jestler için ilk
  /// algılanıp yapılana kadar dolum çubuğu olsun"): basılı tutma jesti
  /// (şekle oturt / silgi önerisi) beklerken o noktada dolan halka. [serial]
  /// her yeniden kurulumda artar — halka baştan dolar. null = bekleyen jest
  /// yok. Ayrı bildirici: çizgileri yeniden boyatmaz.
  final holdProgress = ValueNotifier<InkHoldProgress?>(null);
  int _holdSerial = 0;

  void _showHold(int page, double x, double y, {required bool eraser}) {
    holdProgress.value = InkHoldProgress(
      page: page,
      at: Offset(x, y),
      eraser: eraser,
      serial: ++_holdSerial,
      duration: kInkHoldDuration,
    );
  }

  void _clearHold() {
    if (holdProgress.value != null) holdProgress.value = null;
  }

  /// Silgi önerisini kabul et: silgi seçilir, öneri kalkar.
  void acceptEraserOffer() {
    eraserOffer.value = null;
    setEraser(true);
  }

  bool _inkNear(int page, double x, double y) {
    const r = _eraseRadius * 1.5;
    for (final s in _ink) {
      if (s.page != page) continue;
      final samples = _sampled(s);
      for (var i = 0; i + 1 < samples.length; i += 2) {
        if ((samples[i] - x).abs() < r && (samples[i + 1] - y).abs() < r) {
          return true;
        }
      }
    }
    return false;
  }

  void _offerEraser(int page) {
    _clearHold();
    final at = _eraserHoldAt;
    _eraserHold = null;
    if (at == null || _pointers != 1 || _active == null) return;
    // Basışın bıraktığı nokta gider; parmak kalkana dek çizim sürmez.
    final base = _gestureBase;
    if (base != null) _ink = base;
    _active = null;
    _snapped = true;
    eraserOffer.value = (page: page, at: at);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Katmanın üstündeki bir düğme (düzeltme işaretçisi) bu dokunuşu aldı:
  /// çizim ona hiç başlamaz. KÖK NEDEN (kullanıcı bildirimi 2026-11-08,
  /// "kalemle oto düzelt onayına basılamıyor"): kalemin inişi önce çizimi
  /// başlatıp öneriyi siliyordu, işaretçi kalkışı hiç görmüyordu.
  void claimPointer(int pointer) => _claimed.add(pointer);
  final Set<int> _claimed = {};

  static List<Offset> _pixels(InkStroke s, Size size) => [
    for (var i = 0; i + 1 < s.points.length; i += 2)
      Offset(s.points[i] * size.width, s.points[i + 1] * size.height),
  ];

  /// Biten serbest çizgiye öneri arar (saf geometri, `ink_recognize.dart`).
  void _suggestFor(InkStroke stroke, Size size) {
    if (size.isEmpty) return;
    final marks = InkToolMemory.markFix != false && pen != InkPen.highlighter;
    if (!shapeSuggest && !marks) return;
    final prevStroke = _lastFree;
    final prev =
        prevStroke != null &&
            prevStroke.page == stroke.page &&
            _lastFreeSize == size &&
            DateTime.now().difference(_lastFreeAt) <
                const Duration(milliseconds: 2500) &&
            _ink.any((s) => identical(s, prevStroke))
        ? prevStroke
        : null;
    _lastFree = stroke;
    _lastFreeAt = DateTime.now();
    _lastFreeSize = size;
    final fix = recognizeInkFix(
      _pixels(stroke, size),
      previous: prev == null ? null : _pixels(prev, size),
      shapes: shapeSuggest,
      marks: marks,
    );
    if (fix == null) return;
    final replacements = [
      for (final f in fix.strokes)
        InkStroke(
          page: stroke.page,
          color: stroke.color,
          width: stroke.width,
          arrow: f.arrow,
          points: [
            for (final p in f.points) ...[
              p.dx / size.width,
              p.dy / size.height,
            ],
          ],
        ),
    ];
    var right = 0.0, bottom = 0.0;
    for (final r in replacements) {
      for (var i = 0; i + 1 < r.points.length; i += 2) {
        right = math.max(right, r.points[i]);
        bottom = math.max(bottom, r.points[i + 1]);
      }
    }
    suggestion.value = InkSuggestion(
      kind: fix.kind,
      page: stroke.page,
      anchor: Offset(right, bottom),
      originals: [?(fix.usesPrevious ? prev : null), stroke],
      replacements: replacements,
      needsConsent: fix.isMark && InkToolMemory.markFix == null,
    );
  }

  /// Öneriyi uygular: özgün çizgi(ler) temiz hâliyle değişir; geri al eski
  /// hâline döndürür.
  void applySuggestion() {
    final s = suggestion.value;
    dismissSuggestion();
    if (s == null) return;
    bool isOriginal(InkStroke x) => s.originals.any((o) => identical(o, x));
    final at = _ink.indexWhere(isOriginal);
    if (at < 0 || s.originals.any((o) => !_ink.any((x) => identical(x, o)))) {
      return;
    }
    _pushHistory(_ink);
    final kept = [
      for (final x in _ink)
        if (!isOriginal(x)) x,
    ];
    final insertAt = math.min(at, kept.length);
    _ink = [
      ...kept.sublist(0, insertAt),
      ...s.replacements,
      ...kept.sublist(insertAt),
    ];
    _lastFree = null;
    _selected = [...s.replacements];
    _fixEdit = !lasso;
    _dirty = true;
    save();
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  /// Çizim değişince güncel çizgi listesiyle çağrılır (kaydetme).
  final ValueChanged<List<InkStroke>> onChanged;

  List<InkStroke> _ink;
  List<InkStroke> get ink => _ink;

  bool editing = false;

  // Araç alanları [InkToolMemory]'de durur (tek araç durumu, F63.2).
  bool get eraser => InkToolMemory.eraser;
  set eraser(bool value) => InkToolMemory.eraser = value;

  /// **OK** aracı seçili mi? Açıkken parmak serbest çizmez: bastığı yer okun
  /// KUYRUĞU, kaldırdığı yer UCU olur (kullanıcı isteği 2026-08-08: "bir de ok
  /// işareti çekme istiyorum"). Elle çizilen ok hiçbir zaman düz çıkmıyor.
  bool get arrow => InkToolMemory.arrow;
  set arrow(bool value) => InkToolMemory.arrow = value;

  /// Seçili ŞEKİL (düz çizgi / dikdörtgen / elips); null = serbest çizim.
  /// Ok gibi bastığın yerden kaldırdığın yere çizilir, kayda sıradan çizgi
  /// olarak yazılır ([inkShapePoints]).
  InkShape? get shape => InkToolMemory.shape;
  set shape(InkShape? value) => InkToolMemory.shape = value;

  /// Kullanıcının seçtiği renk — SAYDAMLIKSIZ hâli. Çizgiye yazılırken
  /// kalemin saydamlığı uygulanır ([penColor]).
  Color get color =>
      Color(InkToolMemory.color ?? kInkPalette.first.toARGB32());
  set color(Color value) => InkToolMemory.color = value.toARGB32();

  /// Kalem türü (tükenmez / keçeli / fosforlu).
  InkPen get pen {
    final i = InkToolMemory.pen;
    return i != null && i >= 0 && i < InkPen.values.length
        ? InkPen.values[i]
        : InkPen.pen;
  }

  set pen(InkPen value) => InkToolMemory.pen = value.index;

  /// Ekrandaki (ölçeklenmiş) sayfa üzerinde piksel kalınlık; kaydedilirken
  /// sayfa genişliğinin oranına çevrilir.
  double get widthPx {
    final w = InkToolMemory.width;
    return w == null ? pen.defaultWidth : pen.clampWidth(w);
  }

  set widthPx(double value) => InkToolMemory.width = value;

  /// Tükenmez/keçeli ŞEFFAFLIĞI (0,1–1). Fosforlunun saydamlığı sabit:
  /// türü saydamlıktan okunuyor (bkz. ink_pen.dart).
  double get opacity => InkToolMemory.opacity;
  set opacity(double value) => InkToolMemory.opacity = value;

  /// **YALNIZ KALEMLE YAZ** (kullanıcı isteği 2026-10-23: "parmakla basınca
  /// yazmayıp kalemle yazması, parmakla yakınlaştırma ve kaydırma"): açıkken
  /// parmak ÇİZMEZ — tek parmak kaydırır, iki parmak yakınlaştırır
  /// ([InkNavLayer]); kalem (ve fare) çizer. Avuç içi de böylece çizmez.
  /// İlk kalem dokunuşunda kendiliğinden açılır (kullanıcı elle seçmediyse).
  bool get penOnly => InkToolMemory.penOnly;
  set penOnly(bool value) => InkToolMemory.penOnly = value;

  /// Basınç algısı: kalemle çizilen çizginin kalınlığı bastırmaya göre değişir.
  bool get pressure => InkToolMemory.pressure;
  set pressure(bool value) => InkToolMemory.pressure = value;

  /// Basılı tutunca şekle dönüştür (bkz. [recognizeInkShape]).
  bool get shapeSnap => InkToolMemory.shapeSnap;
  set shapeSnap(bool value) => InkToolMemory.shapeSnap = value;

  /// Kısmi silgi: yalnız silginin değdiği kısım silinir, çizgi bölünür.
  bool get partialEraser => InkToolMemory.partialEraser;
  set partialEraser(bool value) => InkToolMemory.partialEraser = value;

  // ── KEMENT (seçim) ────────────────────────────────────────────────────
  // Kullanıcı isteği 2026-10-30: "Samsung Notes gibi özelliklerimiz olsun".
  // Kement aracı açıkken çizilen kapalı eğrinin içindeki çizgiler seçilir;
  // seçimin içinden sürüklemek onları TAŞIR, renk seçmek BOYAR, "Sil" atar.

  /// Kement aracı seçili mi.
  bool get lasso => InkToolMemory.lasso;
  set lasso(bool value) => InkToolMemory.lasso = value;

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

  /// Seçim köşesinden BOYUTLANDIRILIYOR (kement seçimi ve düzeltilmiş şekil).
  bool _resizing = false;

  /// Düzeltme önerisi uygulandı: temiz şekil SEÇİLİ kalır — kalem aracındayken
  /// de kutusundan sürüklenip taşınır, sağ alt tutamaktan boyutlanır; kutunun
  /// dışına inen ilk dokunuş seçimi bırakıp normal çizer (kullanıcı isteği
  /// 2026-11-08: "x ve tik bir şekil olsun, yeri boyutu ayarlanabilsin").
  bool _fixEdit = false;

  /// Boyut tutamağının dokunma yarıçapı (piksel).
  static const _handleRadius = 24.0;

  /// [local] (piksel) seçimin sağ alt tutamağında mı.
  bool _onHandle(Offset local, Size size) {
    final b = selectionBounds;
    if (b == null) return false;
    final corner = Offset(b.right * size.width + 8, b.bottom * size.height + 8);
    return (local - corner).distance <= _handleRadius;
  }

  /// **DÖNDÜRME** (kullanıcı isteği 2026-11-09: "şekilleri tanıdıktan sonra
  /// döndüremiyorum"): seçim kutusunun üst ortasındaki tutamak. Dönüş PİKSEL
  /// uzayında yapılır (oranlı uzayda en/boy farklı, şekil bozulurdu).
  bool _rotating = false;
  Offset _rotCenterPx = Offset.zero;
  double _rotLast = 0;
  Size _rotSize = Size.zero;

  /// Döndürme tutamağının kutunun üstünden uzaklığı (piksel).
  static const rotateHandleGap = 30.0;

  bool _onRotateHandle(Offset local, Size size) {
    final b = selectionBounds;
    if (b == null) return false;
    final at = Offset(
      b.center.dx * size.width,
      b.top * size.height - 8 - rotateHandleGap,
    );
    return (local - at).distance <= _handleRadius;
  }

  void _rotateSelectionBy(double radians) {
    final w = _rotSize.width, h = _rotSize.height;
    if (w <= 0 || h <= 0) return;
    final c = math.cos(radians), sn = math.sin(radians);
    final cx = _rotCenterPx.dx, cy = _rotCenterPx.dy;
    final map = <InkStroke, InkStroke>{
      for (final st in _selected)
        st: st.copyWith(
          points: [
            for (var i = 0; i + 1 < st.points.length; i += 2) ...[
              (cx +
                      (st.points[i] * w - cx) * c -
                      (st.points[i + 1] * h - cy) * sn) /
                  w,
              (cy +
                      (st.points[i] * w - cx) * sn +
                      (st.points[i + 1] * h - cy) * c) /
                  h,
            ],
          ],
        ),
    };
    _ink = [for (final st in _ink) map[st] ?? st];
    _selected = [for (final st in _selected) map[st]!];
    _dirty = true;
  }

  /// **ÇİFT DOKUNUŞLA YENİDEN SEÇ** (2026-11-09: "ilk tanıyınca hareket
  /// ettirebiliyorum ama sonra sabitleniyor"): çizginin üstüne iki kez hızlı
  /// dokununca o çizgi seçilir — taşı, boyutla, döndür. Dokunuşların
  /// bıraktığı noktalar geri alınır.
  ({DateTime at, int page, double x, double y, List<InkStroke> before})?
  _lastTap;

  InkStroke? _strokeNear(int page, double x, double y) {
    const r = _eraseRadius * 1.5;
    for (final s in _ink.reversed) {
      if (s.page != page) continue;
      final samples = _sampled(s);
      for (var i = 0; i + 1 < samples.length; i += 2) {
        if ((samples[i] - x).abs() < r && (samples[i + 1] - y).abs() < r) {
          return s;
        }
      }
    }
    return null;
  }

  /// Dokunuşun bıraktığı nokta mı (kayma yok denecek kadar küçük).
  static bool _isDot(InkStroke s) {
    if (s.points.length < 2) return false;
    var l = s.points[0], r = l, t = s.points[1], b = t;
    for (var i = 0; i + 1 < s.points.length; i += 2) {
      l = math.min(l, s.points[i]);
      r = math.max(r, s.points[i]);
      t = math.min(t, s.points[i + 1]);
      b = math.max(b, s.points[i + 1]);
    }
    return r - l < 0.006 && b - t < 0.006;
  }

  /// Seçimi sol üst köşesi sabit kalarak [x],[y]'ye (sağ alt) ölçekler.
  void _scaleSelectionTo(double x, double y) {
    final b = selectionBounds;
    if (b == null) return;
    final sx = b.width < 1e-4 ? 1.0 : math.max(0.01, x - b.left) / b.width;
    final sy = b.height < 1e-4 ? 1.0 : math.max(0.01, y - b.top) / b.height;
    final map = <InkStroke, InkStroke>{
      for (final st in _selected)
        st: st.copyWith(
          points: [
            for (var i = 0; i < st.points.length; i++)
              i.isEven
                  ? b.left + (st.points[i] - b.left) * sx
                  : b.top + (st.points[i] - b.top) * sy,
          ],
        ),
    };
    _ink = [for (final st in _ink) map[st] ?? st];
    _selected = [for (final st in _selected) map[st]!];
    _dirty = true;
  }

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

  /// Oturan şekil DÜZ ÇİZGİYSE sabit ucu (oranlı): kalem kalkana dek öbür
  /// uç kalemi izler (F55.2, 2026-11-09 — Squid/Notein övgüsü). Değilse null.
  Offset? _snapLineFrom;

  /// Çizgiye yazılan renk: seçilen renk + kalemin saydamlığı (+ şeffaflık).
  Color get penColor => pen.fixedOpacity != null
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
    _checkCommitted();
    super.notifyListeners();
  }

  /// **BİTMİŞ ÇİZGİ SÜRÜMÜ** (F62.1, B4): yalnız etkin çizgi DIŞINDAKİ
  /// çizgi kümesi değişince artar (çizgi sonu, silgi, geri al, yerine koy,
  /// taşıma). Bitmiş katman ([CommittedInkPainter]) yalnız buna bağlı: kalem
  /// ilerlerken sayfadaki binlerce çizgi yeniden boyanmaz, yalnız etkin çizgi.
  ///
  /// Ayrı ayrı her yolda artırmak yerine [notifyListeners] karşılaştırır:
  /// serbest çizimde liste ve etkin çizgi aynı nesne kalır (nokta yerinde
  /// eklenir) → tek kimlik bakışı; liste değişince O(N) kimlik karşılaştırma.
  /// ponytail: kement taşıma/döndürme sürerken seçili çizgiler bitmiş
  /// katmanda kalır (her harekette bitmiş katman boyanır — bugünkü maliyet).
  final committedRev = ValueNotifier<int>(0);
  List<InkStroke>? _seenInk;
  InkStroke? _seenActive;
  List<InkStroke> _committed = const [];
  final Map<int, List<InkStroke>> _committedByPage = {};

  /// Çizilmekte olan çizgi (bitmiş katmanda çizilmez).
  InkStroke? get activeStroke => _active;

  void _checkCommitted() {
    if (identical(_ink, _seenInk) && identical(_active, _seenActive)) return;
    _seenInk = _ink;
    _seenActive = _active;
    final active = _active;
    final committed = active == null
        ? _ink
        : [
            for (final s in _ink)
              if (!identical(s, active)) s,
          ];
    if (_sameInstances(committed, _committed)) return;
    _committed = committed;
    _committedByPage.clear();
    committedRev.value++;
  }

  /// [page] sayfasının bitmiş çizgileri ([committedRev] başına bir kez süzülür).
  List<InkStroke> strokesOf(int page) {
    _checkCommitted();
    return _committedByPage[page] ??= [
      for (final s in _committed)
        if (s.page == page) s,
    ];
  }

  int _pointers = 0;
  InkStroke? _active;
  bool _dirty = false;

  /// Çizime kabul edilen parmak/kalem kimlikleri: "yalnız kalem"de parmak
  /// sayılmaz, kalkışı da sayacı düşürmez.
  final Map<int, PointerDeviceKind> _accepted = {};

  /// AVUÇ REDDİ (tablet bulgusu 2026-11-07: "kalemle yazarken elle de
  /// yazabiliyor, kalem algılanmıyor"): kalem ekrandayken ya da az önce
  /// (havada yaklaşırken / kalkalı [_palmWindow]) gelen parmak dokunuşu avuç
  /// içidir — çizmez, metne de gitmez. Eskiden avuç "ikinci parmak" sayılıp
  /// KALEMİN çizgisini iptal ediyordu.
  DateTime _stylusAt = DateTime(0);
  static const _palmWindow = Duration(milliseconds: 400);

  /// Kalem havada görüldü/dokundu/kalktı.
  void noteStylus() => _stylusAt = DateTime.now();

  /// Bu dokunuş avuç içi mi (bkz. [_stylusAt]).
  bool isPalm(PointerDeviceKind kind) =>
      kind == PointerDeviceKind.touch &&
      (_stylusDown > 0 || DateTime.now().difference(_stylusAt) < _palmWindow);

  /// Sayfa katmanı bu dokunuşu üstlenir mi: çizen girdi ya da (kalem
  /// yazabiliyorken) yutulacak avuç.
  bool claims(PointerDeviceKind kind) =>
      accepts(kind) || (isPalm(kind) && accepts(PointerDeviceKind.stylus));

  /// Kalem kipi KAPALIYKEN kalemin tek başına dokunuşu (yazının arasında
  /// değil, [_isolatedTap] sessizlikten sonra, kıpırdamadan) çizmez —
  /// alttaki kutucuğa/bağlantıya/metne tıklar. Yazarken konan nokta (i, ö)
  /// yazının arasında kaldığı için çizilir.
  bool passStylusTaps = false;
  DateTime _lastStrokeEnd = DateTime(0);
  static const _isolatedTap = Duration(milliseconds: 1200);

  /// Kalem dokunuşunun "tık" sayıldığı en çok kayma (dp).
  static const stylusTapSlop = 4.0;
  Offset? _tapStart;

  bool stylusTapMayPass(PointerDeviceKind kind) =>
      passStylusTaps &&
      !eraser &&
      !lasso &&
      (kind == PointerDeviceKind.stylus ||
          kind == PointerDeviceKind.invertedStylus) &&
      DateTime.now().difference(_lastStrokeEnd) > _isolatedTap;

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

  /// Ekrana değen kalem sayısı (bkz. [isPalm]).
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
    _toolChanged();
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
    _toolChanged();
  }

  void _leaveLasso() {
    lasso = false;
    _lassoPath = null;
    _lassoPage = null;
    _selected = const [];
    _moving = false;
    _resizing = false;
    _fixEdit = false;
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
    _toolChanged();
  }

  void setPartialEraser(bool value) {
    partialEraser = value;
    InkToolMemory.savePartialEraser(value);
    _toolChanged();
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
    _toolChanged();
  }

  /// Şekil aracını seçer (null = serbest çizim). Kalem türü/renk geçerli.
  void setShape(InkShape? value) {
    shape = value;
    if (value != null) {
      eraser = false;
      arrow = false;
      _leaveLasso();
    }
    _toolChanged();
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
    _toolChanged();
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
    _toolChanged();
  }

  /// Sabitlenebilir şu anki kalem (bkz. [InkToolMemory.presets]).
  InkPreset get currentPreset =>
      InkPreset(pen: pen.index, color: color.toARGB32(), width: widthPx);

  /// Sabitlenmiş kalemi tek dokunuşla seçer: tür, renk, kalınlık.
  void applyPreset(InkPreset p) {
    if (p.pen < 0 || p.pen >= InkPen.values.length) return;
    final value = InkPen.values[p.pen];
    pen = value;
    eraser = false;
    arrow = false;
    shape = null;
    _leaveLasso();
    color = Color(p.color);
    widthPx = value.clampWidth(p.width);
    _remember();
    _toolChanged();
  }

  void setWidth(double value) {
    widthPx = pen.clampWidth(value);
    _remember();
    _toolChanged();
  }

  void setOpacity(double value) {
    opacity = value.clamp(0.1, 1.0).toDouble();
    _remember();
    _toolChanged();
  }

  /// "Yalnız kalemle yaz"ı açar/kapatır. [chosen]: kullanıcının kendi
  /// seçimi (bir daha kendiliğinden açılmaz).
  void setPenOnly(bool value, {bool chosen = true}) {
    penOnly = value;
    InkToolMemory.savePenOnly(value, chosen: chosen);
    _toolChanged();
  }

  void setPressure(bool value) {
    pressure = value;
    InkToolMemory.savePressure(value);
    _toolChanged();
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
    dismissSuggestion();
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
    dismissSuggestion();
    _selected = const [];
    if (_future.isEmpty) return;
    _history.add(_ink);
    _ink = _future.removeLast();
    _dirty = true;
    save();
    notifyListeners();
  }

  void clear() {
    dismissSuggestion();
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
    dismissSuggestion();
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
    _clearHold();
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
      (allowedKinds == null || allowedKinds!.contains(kind)) &&
      (!penOnly || kind != PointerDeviceKind.touch);

  /// Yalnız bu girdiler çizer; null = hepsi. Sayfa katmanında kalem kipi
  /// kapalıyken yalnız kalem geçer, parmak ve fare metne gider.
  Set<PointerDeviceKind>? allowedKinds;

  /// Çizgi çizilirken değil, dışarıdan (geri al, başka cihaz) gelen çizgileri
  /// alır; geçmişe girmez.
  void replaceAll(List<InkStroke> strokes) {
    if (_pointers > 0) return;
    _ink = strokes;
    _selected = [];
    notifyListeners();
  }

  /// Şu an çizim sürüyor mu.
  bool get drawing => _pointers > 0;

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
      // Her mürekkep katmanında (çizim ekranı, paket, görüntüleyici) kalıcı
      // işaret — eskiden yalnız editör içeriğinde (F63.4).
      InkToolMemory.noteStylusEver();
      noteStylus();
      _dropPalms();
      // İlk kalem dokunuşu: kullanıcı seçmediyse "yalnız kalem" açılır —
      // kalemle yazarken avuç içi/parmak çizgi bırakmasın.
      if (!penOnly && !InkToolMemory.penOnlyChosen) {
        setPenOnly(true, chosen: false);
      }
    }
    if (pointer != null) {
      // Düzeltme işaretçisine basan dokunuş çizgi başlatmaz (bkz.
      // [claimPointer]); kalemin sayacı yukarıda zaten işlendi.
      if (_claimed.remove(pointer)) return;
      if (!accepts(kind) || isPalm(kind)) return;
      _accepted[pointer] = kind;
    }
    if (!identical(active, this)) {
      active = this;
      // Tepsi geri al/yineleyi bu yüzeye bağlasın.
      _toolChanged();
    }
    _tapStart = _pointers == 0 && stylusTapMayPass(kind) ? local : null;
    _pointers++;
    if (_nav) return;
    if (_pointers > 1) {
      // İkinci parmak = yakınlaştırma/kaydırma niyeti: yeni başlamış çizgiyi
      // geri al ki ekranda kırıntı kalmasın.
      if (_active != null) _ink = [..._ink]..remove(_active);
      _active = null;
      _holdTimer?.cancel();
      _clearHold();
      _lassoPath = null;
      _moving = false;
      notifyListeners();
      return;
    }
    hover.value = null;
    if (suggestion.value != null) dismissSuggestion();
    if (eraserOffer.value != null) eraserOffer.value = null;
    _gestureBase = _ink;
    _tempEraser = stylusEraser;
    // Seçim tutamağı / düzeltilmiş şeklin kutusu: taşı ya da boyutlandır.
    if ((lasso || _fixEdit) && !_tempEraser && selectionPage == page) {
      final x = local.dx / size.width;
      final y = local.dy / size.height;
      final bounds = selectionBounds;
      if (bounds != null && _onRotateHandle(local, size)) {
        _pushHistory(_ink);
        _rotating = true;
        _rotSize = size;
        _rotCenterPx = Offset(
          bounds.center.dx * size.width,
          bounds.center.dy * size.height,
        );
        _rotLast = math.atan2(
          local.dy - _rotCenterPx.dy,
          local.dx - _rotCenterPx.dx,
        );
        notifyListeners();
        return;
      }
      final onHandle = _onHandle(local, size);
      final inside =
          bounds != null && bounds.inflate(0.03).contains(Offset(x, y));
      if (onHandle || (_fixEdit && inside)) {
        _pushHistory(_ink);
        _resizing = onHandle;
        _moving = !onHandle;
        _moveX = x;
        _moveY = y;
        notifyListeners();
        return;
      }
    }
    if (_fixEdit) {
      _fixEdit = false;
      _selected = const [];
    }
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
    _snapLineFrom = null;
    _holdX = x;
    _holdY = y;
    // Yakınlık, yeni noktanın KENDİSİ eklenmeden önce ölçülür.
    final onInk =
        kind == PointerDeviceKind.touch &&
        !arrow &&
        shape == null &&
        _inkNear(page, x, y);
    _ink = [..._ink, stroke];
    _eraserHold?.cancel();
    _eraserHold = null;
    if (onInk) {
      _eraserHoldAt = Offset(x, y);
      _eraserHold = Timer(kInkHoldDuration, () => _offerEraser(page));
      _showHold(page, x, y, eraser: true);
    }
    notifyListeners();
  }

  /// Kalem/parmak çizginin sonunda kıpırdamadan durdu: çizgi tanınan şekle
  /// oturur (bkz. [recognizeInkShape]).
  void _snapActive() {
    _clearHold();
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
    // Kapalı şekil önce (kare/daire düzgün, zorlanınca serbest — bkz.
    // [recognizeClosedShape]); yoksa düz çizgi.
    final closed = recognizeClosedShape(px);
    final found = closed == null ? recognizeInkShape(px) : null;
    if (closed == null && (found == null || found.shape != InkShape.line)) {
      return;
    }
    final points = closed != null
        ? [
            for (final p in closed.outline) ...[
              p.dx / size.width,
              p.dy / size.height,
            ],
          ]
        : inkShapePoints(
            found!.shape,
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
    // Düz çizgide kaleme uzak uç sabit kalır, yakın uç kalemle taşınır.
    if (closed == null && points.length == 4) {
      final pen = Offset(_holdX, _holdY);
      final a = Offset(points[0], points[1]);
      final b = Offset(points[2], points[3]);
      _snapLineFrom = (a - pen).distance >= (b - pen).distance ? a : b;
    } else {
      _snapLineFrom = null;
    }
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  @override
  void dispose() {
    InkToolMemory.toolRev.removeListener(_onToolChanged);
    InkToolMemory.closeSession();
    if (identical(active, this)) active = null;
    _holdTimer?.cancel();
    _clearHold();
    _eraserHold?.cancel();
    holdProgress.dispose();
    hover.dispose();
    suggestion.dispose();
    eraserOffer.dispose();
    committedRev.dispose();
    super.dispose();
  }

  void pointerMove(
    int page,
    Offset local,
    Size size, {
    int? pointer,
    double? pressure,
  }) {
    if (pointer != null && !_accepted.containsKey(pointer)) return;
    if (_nav || _pointers != 1) return;
    final tap = _tapStart;
    if (tap != null && (local - tap).distance > stylusTapSlop) {
      _tapStart = null;
    }
    if (_rotating) {
      final a = math.atan2(
        local.dy - _rotCenterPx.dy,
        local.dx - _rotCenterPx.dx,
      );
      _rotateSelectionBy(a - _rotLast);
      _rotLast = a;
      notifyListeners();
      return;
    }
    if (_resizing || (_fixEdit && _moving)) {
      final x = local.dx / size.width;
      final y = local.dy / size.height;
      if (_resizing) {
        _scaleSelectionTo(x, y);
      } else {
        _translateSelection(x - _moveX, y - _moveY);
      }
      _moveX = x;
      _moveY = y;
      notifyListeners();
      return;
    }
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
    final lineFrom = _snapLineFrom;
    if (active != null && _snapped && lineFrom != null) {
      // Oturmuş düz çizginin ucu kalemle gider (F55.2).
      final moved = InkStroke(
        page: active.page,
        color: active.color,
        width: active.width,
        points: [
          lineFrom.dx,
          lineFrom.dy,
          local.dx / size.width,
          local.dy / size.height,
        ],
      );
      _ink = [for (final s in _ink) identical(s, active) ? moved : s];
      _active = moved;
      notifyListeners();
      return;
    }
    if (active == null || _snapped) return;
    final x = local.dx / size.width;
    final y = local.dy / size.height;
    final holdAt = _eraserHoldAt;
    if (_eraserHold != null &&
        holdAt != null &&
        math.max((x - holdAt.dx).abs(), (y - holdAt.dy).abs()) > 0.01) {
      _eraserHold?.cancel();
      _eraserHold = null;
      _clearHold();
    }
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
      _clearHold();
      _holdTimer = Timer(kInkHoldDuration, _snapActive);
      _showHold(active.page, x, y, eraser: false);
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

  /// Avuç kalemden ÖNCE değdiyse başlattığı her şey (çizgi, silgi, kement)
  /// geri alınır; kalem temiz başlar.
  void _dropPalms() {
    if (_nav) return;
    final palms = [
      for (final e in _accepted.entries)
        if (e.value == PointerDeviceKind.touch) e.key,
    ];
    if (palms.isEmpty) return;
    palms.forEach(_accepted.remove);
    _pointers = math.max(0, _pointers - palms.length);
    final base = _gestureBase;
    if (base != null) _ink = base;
    _gestureBase = null;
    _active = null;
    _holdTimer?.cancel();
    _clearHold();
    _lassoPath = null;
    _moving = false;
  }

  /// Sistem dokunuşu iptal etti (Android avuç içini böyle bildirir): parmağın
  /// çizdiği çizgi kalmaz.
  void pointerCancel({
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
  }) {
    if (kind == PointerDeviceKind.touch &&
        _pointers == 1 &&
        pointer != null &&
        _accepted.containsKey(pointer)) {
      final base = _gestureBase;
      if (base != null) _ink = base;
      _gestureBase = null;
      _active = null;
    }
    pointerUp(pointer: pointer, kind: kind);
  }

  void pointerUp({
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
  }) {
    final stylus =
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
    if (stylus) {
      _stylusDown = math.max(0, _stylusDown - 1);
      noteStylus();
    }
    if (pointer != null) _claimed.remove(pointer);
    if (pointer != null && _accepted.remove(pointer) == null) return;
    _pointers = math.max(0, _pointers - 1);
    if (_pointers > 0) {
      notifyListeners();
      return;
    }
    if (_tapStart != null) {
      // Tek başına kalem tıkı: alttaki metne/kutucuğa gitti, nokta çizilmez.
      _tapStart = null;
      final base = _gestureBase;
      if (base != null) _ink = base;
      _gestureBase = null;
      _active = null;
    } else if (stylus) {
      _lastStrokeEnd = DateTime.now();
    }
    final wasErasing = _erasing;
    final wasSnapped = _snapped;
    _snapLineFrom = null;
    _tempEraser = false;
    _holdTimer?.cancel();
    _clearHold();
    _eraserHold?.cancel();
    _eraserHold = null;
    _snapped = false;
    if (_rotating || _resizing || (_fixEdit && _moving)) {
      _rotating = false;
      _resizing = false;
      _moving = false;
      save();
    } else if (lasso) {
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
    if (active != null &&
        !wasErasing &&
        !lasso &&
        !active.arrow &&
        shape == null &&
        base != null &&
        _isDot(active)) {
      final x = active.points[0], y = active.points[1];
      final prev = _lastTap;
      final now = DateTime.now();
      if (prev != null &&
          prev.page == active.page &&
          now.difference(prev.at) < const Duration(milliseconds: 400) &&
          (prev.x - x).abs() < 0.03 &&
          (prev.y - y).abs() < 0.03) {
        _lastTap = null;
        _ink = prev.before;
        _dirty = true;
        save();
        final hit = _strokeNear(active.page, x, y);
        if (hit != null) {
          _selected = [hit];
          _fixEdit = true;
          HapticFeedback.selectionClick();
          notifyListeners();
          return;
        }
      } else {
        _lastTap = (at: now, page: active.page, x: x, y: y, before: base);
      }
    } else {
      _lastTap = null;
    }
    // F61.2: serbest çizgi kalkışta sadeleşir (RDP, ~0,3 dp): kayıt ve
    // bellek küçülür, görünüm değişmez. Ok / şekil / oturmuş çizgi hariç.
    var done = active;
    // ponytail: dolma kalem sadeleşmez — hızı nokta ARALIĞINDAN okunuyor,
    // RDP düz yerde noktaları seyreltip çizgiyi incelterdi (F62.5).
    if (done != null &&
        !done.arrow &&
        shape == null &&
        !wasErasing &&
        !wasSnapped &&
        !lasso &&
        !inkIsFountain(done.color)) {
      final i = _ink.indexWhere((s) => identical(s, done));
      final r = i < 0
          ? null
          : simplifyStroke(
              done.points,
              kInkSimplifyTolerance,
              pressures: done.pressures,
            );
      if (r != null && !identical(r.points, done.points)) {
        done = InkStroke(
          page: done.page,
          color: done.color,
          width: done.width,
          points: r.points,
          pressures: r.pressures,
        );
        _ink = [..._ink]..[i] = done;
      }
    }
    if (base != null && !_sameInstances(base, _ink)) _pushHistory(base);
    save();
    // Serbest çizgi bitti: şekil / tik / çarpı önerisi (tutup oturtulmuşsa
    // zaten şekil). ponytail: sadeleşmiş çizgiden tanınır (sapma ≤ 0,3 dp;
    // tanıyıcı kendisi köşegenin %10'uyla sadeleştiriyor).
    if (done != null &&
        !done.arrow &&
        shape == null &&
        !wasErasing &&
        !wasSnapped &&
        !lasso &&
        _ink.any((s) => identical(s, done))) {
      _suggestFor(done, _activeSize);
    }
    notifyListeners();
  }

  /// [s] çizgisinin noktaları [page] sayfasının koordinatında hangi dikey
  /// kaymayla okunur; komşu sayfa değilse null.
  ///
  /// **SAYFADAN TAŞAN ÇİZGİ SİLİNMİYORDU** (kullanıcı bulgusu 2026-11-13:
  /// "PDF'te alt sayfadan üst sayfaya doğru kalemle yazılıyor ama
  /// silinmiyor"): çizgi başladığı sayfaya kaydedilir, öbür sayfaya taşan
  /// kısmı o sayfanın dışındaki (y < 0 ya da y > 1) noktalardır; silgi
  /// yalnız aynı sayfanın çizgilerine bakıyordu. Komşu sayfanın çizgisi bir
  /// sayfa boyu kaydırılarak denenir (sayfa arası boşluk silgi yarıçapının
  /// altında).
  static double? _pageShift(InkStroke s, int page) {
    final d = s.page - page;
    if (d == 0) return 0;
    if (d.abs() != 1) return null;
    return d.toDouble();
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
      final shift = _pageShift(s, page);
      if (shift != null) {
        // OK yalnız İKİ nokta taşır; gövdesine dokunmak da silmeli, yoksa
        // yalnız uçlarından yakalanan bir çizgi olurdu. Düz çizgi ve
        // dikdörtgenin kenarları da seyrek noktalı — aynı örnekleme.
        final samples = _sampled(s);
        for (var i = 0; i < samples.length; i += 2) {
          if ((samples[i] - x).abs() < _eraseRadius &&
              (samples[i + 1] + shift - y).abs() < _eraseRadius) {
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
  /// parçalar ayrı çizgiler olur. Ok bütün silinir — yarım ok anlamsız.
  ///
  /// **SİLERKEN YAZI BOYU DEĞİŞİYORDU** (kullanıcı bulgusu 2026-11-13):
  /// parçalar örneklenmiş (ara noktalı) listeden kuruluyordu — seyrek
  /// noktalı çizgide basınç DÜŞÜYOR (×1'e), dolma kalemde nokta aralığı
  /// değiştiği için hız inceltmesi de değişiyordu; kalan yazı kalınlaşıyor/
  /// inceliyordu. Artık parçalar ÖZGÜN noktalardan ve basınçlardan kesilir;
  /// silgi iki nokta arasından geçiyorsa (seyrek şekil) parça orada kesilir.
  void _erasePartAt(int page, double x, double y) {
    const r = _eraseRadius;
    var changed = false;
    final out = <InkStroke>[];
    for (final s in _ink) {
      final shift = _pageShift(s, page);
      if (shift == null) {
        out.add(s);
        continue;
      }
      final ey = y - shift;
      bool near(double px, double py) =>
          (px - x).abs() < r && (py - ey).abs() < r;
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
      final pts = s.points;
      final pressures = s.hasPressure ? s.pressures : null;
      // a → b parçası silginin karesinden geçiyor mu (uçlar dışarıdayken).
      bool crosses(double ax, double ay, double bx, double by) {
        final dx = bx - ax, dy = by - ay;
        final len2 = dx * dx + dy * dy;
        if (len2 < 1e-12) return false;
        final t = (((x - ax) * dx + (ey - ay) * dy) / len2).clamp(0.0, 1.0);
        return near(ax + dx * t, ay + dy * t);
      }

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

      for (var i = 0; i + 1 < pts.length; i += 2) {
        final px = pts[i], py = pts[i + 1];
        if (near(px, py)) {
          flush();
          continue;
        }
        if (run.length >= 2 &&
            crosses(run[run.length - 2], run[run.length - 1], px, py)) {
          flush();
        }
        run.addAll([px, py]);
        if (pressures != null) runQ.add(pressures[i ~/ 2]);
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
/// Bekleyen çizim düzeltmesi (bkz. [InkController.suggestion]).
class InkSuggestion {
  const InkSuggestion({
    required this.kind,
    required this.page,
    required this.anchor,
    required this.originals,
    required this.replacements,
    this.needsConsent = false,
  });

  final InkFixKind kind;
  final int page;

  /// Temiz şeklin sağ alt köşesi (oranlı).
  final Offset anchor;
  final List<InkStroke> originals;
  final List<InkStroke> replacements;

  /// Tik/çarpı ilk kez: önce "otomatik düzeltme açılsın mı" sorulur.
  final bool needsConsent;
}

class InkPageLayer extends StatelessWidget {
  const InkPageLayer({
    super.key,
    required this.controller,
    required this.page,
    this.uniform = false,
  });

  final InkController controller;

  /// y de GENİŞLİĞE oranlanır (kare birim): katmanın boyu değişse de çizim
  /// yerinde kalır, silgi yarıçapı iki eksende aynıdır. Uzayan not sayfası
  /// için (bkz. `PageInkStack`); PDF/görsel sayfasının oranı sabit.
  final bool uniform;

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
          final size = uniform
              ? Size.square(constraints.maxWidth)
              : Size(constraints.maxWidth, constraints.maxHeight);
          // Kalem HAVADA (S Pen yaklaşması): ucun kalınlığı/silgi halkası
          // önizlenir. Fare de aynı yoldan gelir — onda önizleme yok.
          void onHover(PointerEvent e) {
            if (e.kind != PointerDeviceKind.stylus &&
                e.kind != PointerDeviceKind.invertedStylus) {
              return;
            }
            controller.noteStylus();
            controller.hover.value = (page, e.localPosition);
          }

          void onExit(PointerEvent e) {
            if (controller.hover.value?.$1 == page) {
              controller.hover.value = null;
            }
          }

          final layer = MouseRegion(
            opaque: false,
            // Artı imleç: alttaki metnin "I" imleci kalırsa göz ucuna bakar,
            // tıklama ise ortasından olur — çizgi "biraz yukarıda" çıkıyordu
            // (kullanıcı bulgusu 2026-11-02).
            cursor: SystemMouseCursors.precise,
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
                  controller.pointerCancel(pointer: e.pointer, kind: e.kind),
              // Yalnız çizgiler değişince yeniden boyanır; görüntüleyici (PDF/slayt)
              // yeniden kurulmaz — bu yüzden çizim sırasında jest bozulmaz.
              // RepaintBoundary: tek bir çizgi uzarken üstteki PDF/slayt
              // katmanının yeniden boyanmasına gerek yok.
              child: RepaintBoundary(
                // F62.1: widget YENİDEN KURULMAZ; iki boyayıcı kendi
                // bildiricisini dinler. Bitmiş çizgiler kendi
                // RepaintBoundary'sinde, yalnız [committedRev] ile boyanır;
                // etkin çizgi + kement/seçim/havadaki uç her harekette.
                child: ValueListenableBuilder<int>(
                  valueListenable: controller.committedRev,
                  builder: (context, _, child) {
                    // Ekran okuyucu (F4.7): tuval kendisi okunamaz; en azından
                    // sayfada çizim olduğu ve kaç çizgi olduğu söylenir.
                    final count = controller.strokesOf(page).length;
                    return Semantics(
                      image: count > 0,
                      label: count == 0 ? null : context.l10n.inkSemantics(count),
                      child: child,
                    );
                  },
                  child: _paintStack(context, size),
                ),
              ),
            ),
          );
          // Düzeltme işaretçisi Listener'ın ÜSTÜNDE: dokunuşu çizime gitmez.
          return Stack(
            clipBehavior: Clip.none,
            children: [
              layer,
              ValueListenableBuilder<InkHoldProgress?>(
                valueListenable: controller.holdProgress,
                builder: (context, h, _) {
                  if (h == null || h.page != page) {
                    return const SizedBox.shrink();
                  }
                  const ring = 44.0;
                  // Parmağın/kalemin ALTINDA kalmasın: noktanın üstünde
                  // (yer yoksa altında).
                  var top = h.at.dy * size.height - ring - 24;
                  if (top < 0) top = h.at.dy * size.height + 24;
                  return Positioned(
                    left: h.at.dx * size.width - ring / 2,
                    top: top,
                    child: HoldProgressRing(
                      restartKey: h.serial,
                      duration: h.duration,
                      size: ring,
                      icon: h.eraser
                          ? Icons.auto_fix_normal_outlined
                          : Icons.category_outlined,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<({int page, Offset at})?>(
                valueListenable: controller.eraserOffer,
                builder: (context, o, _) {
                  if (o == null || o.page != page) {
                    return const SizedBox.shrink();
                  }
                  const box = 44.0;
                  var left = o.at.dx * size.width - box / 2;
                  var top = o.at.dy * size.height - box - 16;
                  if (constraints.maxWidth.isFinite) {
                    left = left.clamp(0.0, constraints.maxWidth - box);
                  }
                  if (top < 0) top = o.at.dy * size.height + 16;
                  return Positioned(
                    left: left,
                    top: top,
                    child: _EraserOfferButton(
                      onClaim: controller.claimPointer,
                      onAccept: controller.acceptEraserOffer,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<InkSuggestion?>(
                valueListenable: controller.suggestion,
                builder: (context, s, _) {
                  if (s == null || s.page != page) {
                    return const SizedBox.shrink();
                  }
                  const box = 36.0;
                  var left = s.anchor.dx * size.width + 2;
                  var top = s.anchor.dy * size.height + 2;
                  if (constraints.maxWidth.isFinite) {
                    left = left.clamp(0.0, constraints.maxWidth - box);
                  }
                  if (constraints.maxHeight.isFinite) {
                    top = top.clamp(0.0, constraints.maxHeight - box);
                  }
                  return Positioned(
                    left: left,
                    top: top,
                    child: InkFixMarker(
                      suggestion: s,
                      onClaim: controller.claimPointer,
                      onApply: () => _applyWithConsent(context, s),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paintStack(BuildContext context, Size size) {
    final paintSize = uniform ? size : Size.infinite;
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: CommittedInkPainter(controller, page),
            size: paintSize,
          ),
        ),
        CustomPaint(
          painter: ActiveInkPainter(
            controller,
            page,
            Theme.of(context).colorScheme.primary,
          ),
          size: paintSize,
        ),
      ],
    );
    return uniform
        ? OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: stack,
          )
        // Kare kutudan taşan çizgi de boyanır (kırpılmaz). OverflowBox:
        // Align'la tuval katmanın boyuna sıkışıyordu — kalem kipi kapanınca
        // (sayfa altı boşluğu gidince) çizim dikeyde basılıp yukarı
        // kayıyordu (tablet bulgusu 2026-11-07).
        : stack;
  }

  /// Tik/çarpı ilk kez: "otomatik düzeltme açılsın mı" (varsayılan kapalı).
  Future<void> _applyWithConsent(BuildContext context, InkSuggestion s) async {
    if (!s.needsConsent) {
      controller.applySuggestion();
      return;
    }
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inkMarkFixAskTitle),
        content: Text(l10n.inkMarkFixAskBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.inkMarkFixAskNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.inkMarkFixAskYes),
          ),
        ],
      ),
    );
    if (yes == null) return;
    InkToolMemory.saveMarkFix(yes);
    if (yes && identical(controller.suggestion.value, s)) {
      controller.applySuggestion();
    } else {
      controller.dismissSuggestion();
    }
  }
}

/// Basılı tutulan çizginin üstünde beliren silgi düğmesi (bkz.
/// [InkController.eraserOffer]). İnişte kabul eder — düzeltme işaretçisiyle
/// aynı neden (kalem/parmak inişi çizim katmanına kaçmasın).
class _EraserOfferButton extends StatelessWidget {
  const _EraserOfferButton({required this.onClaim, required this.onAccept});

  final ValueChanged<int> onClaim;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.inkEraserOffer;
    return Semantics(
      button: true,
      label: label,
      onTap: onAccept,
      child: Tooltip(
        message: label,
        child: Material(
          key: const ValueKey('ink-eraser-offer'),
          color: scheme.tertiaryContainer,
          shape: const CircleBorder(),
          elevation: 4,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              onClaim(e.pointer);
              onAccept();
            },
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.auto_fix_normal_outlined,
                size: 22,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Çizginin sağ altındaki küçük düzeltme düğmesi: önerilen şeklin simgesi.
class InkFixMarker extends StatelessWidget {
  const InkFixMarker({
    super.key,
    required this.suggestion,
    required this.onApply,
    this.onClaim,
  });

  final InkSuggestion suggestion;
  final VoidCallback onApply;
  final ValueChanged<int>? onClaim;

  static IconData iconOf(InkFixKind kind) => switch (kind) {
    InkFixKind.line => Icons.horizontal_rule_rounded,
    InkFixKind.arrow => Icons.north_east_rounded,
    InkFixKind.rectangle => Icons.crop_square_rounded,
    InkFixKind.ellipse => Icons.circle_outlined,
    InkFixKind.triangle => Icons.change_history_rounded,
    InkFixKind.quad => Icons.crop_din_rounded,
    InkFixKind.polygon => Icons.pentagon_outlined,
    InkFixKind.tick => Icons.check_rounded,
    InkFixKind.cross => Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.inkFixApply,
      onTap: onApply,
      child: Tooltip(
        message: context.l10n.inkFixApply,
        child: Material(
          key: const ValueKey('ink-fix-marker'),
          color: scheme.primaryContainer,
          shape: const CircleBorder(),
          elevation: 3,
          // Ham işaretçi (Listener): kalemle basış InkWell'in jest
          // yarışmasında üst katmanlara (kaydırma/çizim) kaybediliyordu —
          // kalem modunda tik/onay düğmesi "basmayı algılamıyordu"
          // (kullanıcı bildirimi 2026-11-08). Parmak, kalem, fare aynı yol.
          child: Listener(
            behavior: HitTestBehavior.opaque,
            // İNİŞTE uygula: işaretçi en derinde, olayı çizim katmanından
            // ÖNCE alır; [onClaim] o dokunuşun çizgi başlatmasını engeller.
            onPointerDown: (e) {
              onClaim?.call(e.pointer);
              onApply();
            },
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: SizedBox.square(
                dimension: 36,
                child: Icon(
                  iconOf(suggestion.kind),
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitmiş çizgiler (F62.1): yalnız [InkController.committedRev] artınca
/// boyanır — kalem ilerlerken sayfadaki çizgiler yeniden çizilmez.
class CommittedInkPainter extends CustomPainter {
  CommittedInkPainter(this.controller, this.page)
    : super(repaint: controller.committedRev);

  final InkController controller;
  final int page;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in controller.strokesOf(page)) {
      paintInkStroke(canvas, size, s);
    }
  }

  @override
  bool shouldRepaint(CommittedInkPainter old) =>
      !identical(old.controller, controller) || old.page != page;
}

/// Etkin çizgi + kement çizgisi, seçimin çerçevesi ve kalemin havadaki
/// ucunun önizlemesi. Her bildirimde boyanır; işi sayfadaki çizgi
/// sayısından bağımsız (F62.1).
class ActiveInkPainter extends CustomPainter {
  ActiveInkPainter(this.controller, this.page, this.accent)
    : super(repaint: Listenable.merge([controller, controller.hover]));

  final InkController controller;
  final int page;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final active = controller.activeStroke;
    if (active != null && active.page == page) {
      paintInkStroke(canvas, size, active, cache: false);
    }
    final path = controller.lassoPathOn(page);
    final selection = controller.selectionPage == page
        ? controller.selectionBounds
        : null;
    _paintOverlay(canvas, size, path, selection);
  }

  void _paintOverlay(
    Canvas canvas,
    Size size,
    List<double>? path,
    Rect? selection,
  ) {

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
        )
        // Döndürme tutamağı (üst orta, 2026-11-09).
        ..drawLine(
          rect.topCenter,
          rect.topCenter.translate(0, -InkController.rotateHandleGap + 7),
          Paint()
            ..strokeWidth = 1.5
            ..color = accent,
        )
        ..drawCircle(
          rect.topCenter.translate(0, -InkController.rotateHandleGap),
          7,
          Paint()..color = accent,
        )
        ..drawCircle(
          rect.topCenter.translate(0, -InkController.rotateHandleGap),
          4,
          Paint()..color = const Color(0xFFFFFFFF),
        )
        // Boyut tutamağı (sağ alt).
        ..drawCircle(rect.bottomRight, 7, Paint()..color = accent)
        ..drawCircle(
          rect.bottomRight,
          4,
          Paint()..color = const Color(0xFFFFFFFF),
        );
    }
    final h = controller.hover.value;
    final at = h != null && h.$1 == page ? h.$2 : null;
    if (at != null) {
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
  bool shouldRepaint(ActiveInkPainter old) =>
      !identical(old.controller, controller) ||
      old.page != page ||
      old.accent != accent;
}

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
    final fixed = pen.fixedOpacity;
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
                fontWeight: AppWeight.strong,
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
                    // Fosforlu / dolma kalemin saydamlığı sabit (türü
                    // ondan okunuyor).
                    value: fixed ?? controller.opacity,
                    min: 0.1,
                    divisions: 9,
                    label: '%${((fixed ?? controller.opacity) * 100).round()}',
                    onChanged: fixed != null ? null : controller.setOpacity,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '%${((fixed ?? controller.opacity) * 100).round()}',
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
              key: const ValueKey('ink-shape-suggest'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.auto_fix_high_rounded),
              title: Text(l10n.inkShapeSuggestTitle),
              subtitle: Text(l10n.inkShapeSuggestInfo),
              value: controller.shapeSuggest,
              onChanged: controller.setShapeSuggest,
            ),
            StatefulBuilder(
              builder: (context, setLocal) => SwitchListTile(
                key: const ValueKey('ink-mark-fix'),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.rule_rounded),
                title: Text(l10n.inkMarkFixTitle),
                subtitle: Text(l10n.inkMarkFixInfo),
                value: InkToolMemory.markFix ?? false,
                onChanged: (v) => setLocal(() => InkToolMemory.saveMarkFix(v)),
              ),
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
      widget.controller.isPalm(e.kind);

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
      paintInkStroke(canvas, size, s);
    }
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
      onChanged: (value) => setState(() => InkToolMemory.saveAutoStylus(value)),
    );
  }
}
