import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_design.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/group_card.dart';
import '../../../../core/widgets/hold_progress_ring.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../domain/attachment.dart';
import '../../domain/ink_pack.dart';
import '../editor/eraser_glyph.dart';
import '../editor/pen_stroke_preview.dart';
import 'ink_pen.dart';
import 'ink_recognize.dart';
import 'ink_stroke_paint.dart';
import 'ink_tools.dart';

part 'ink_layer_canvas.dart';
part 'ink_layer_sheets.dart';
part 'ink_layer_controller.dart';

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

/// Hızlı kalem ↔ silgi düğmesi kullanılmazsa bu kadar sonra solar.
const kInkQuickSwapIdle = Duration(seconds: 3);

/// Bundan kısa çizgide (dp, kutunun uzun kenarı) hızlı düğme çıkmaz — tık
/// ya da nokta.
const double kInkQuickSwapMinStroke = 8;

/// Hızlı düğmenin konum bilgisi: [box] bitmiş çizginin katman pikselindeki
/// kutusu, [size] o anki katman boyu. [shown] false = solarak gizli.
@immutable
class InkQuickSwap {
  const InkQuickSwap({
    required this.page,
    required this.box,
    required this.size,
    required this.serial,
    this.at,
    this.shown = true,
  });

  final int page;
  final Rect box;
  final Size size;

  /// Düğmenin katman pikselindeki sol üst köşesi ([inkQuickSwapPlace]);
  /// ardışık çizgilerde YAPIŞKAN — yalnız yazı uzaklaşınca ya da düğmenin
  /// üstüne gelince yer değiştirir.
  final Offset? at;

  /// Her yeni çizgide artar: düğmenin solma saati baştan başlar.
  final int serial;
  final bool shown;

  InkQuickSwap hidden() => InkQuickSwap(
    page: page,
    box: box,
    size: size,
    serial: serial,
    at: at,
    shown: false,
  );
}

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
  void _notify() => notifyListeners();

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
  Timer? _holdPreTimer;

  /// tekrar kaleme geçmek zor"): silgi seçiliyken kıpırdamadan 550 ms
  /// basılı tutunca o noktada kalem düğmesi belirir; dokununca son kalem
  /// geri gelir. Basılı tutuşun sildiği çizgiler geri konur.
  final penOffer = ValueNotifier<({int page, Offset at})?>(null);

  /// **KALEM ↔ SİLGİ HIZLI DÜĞMESİ** (kullanıcı isteği 2026-11-19: "çizim
  /// yaparken yazılan noktaya yakın, rahatsız etmeyen saydam küçük silgi
  /// düğmesi; silgideyken kaleme döndürsün"). Çizgi BİTİNCE çizginin kutusu
  /// (katman pikseli) yayınlanır; yeni çizgi başlayınca ([pointerDown]) ve
  /// [kInkQuickSwapIdle] hareketsizlikte `shown: false` olur (düğme solar,
  /// dokunuş geçirir). Hareket karesinde bildirim YOK: kutu dört sayı
  /// olarak birikir, yalnız inişte ve kalkışta yazılır.
  final quickSwap = ValueNotifier<InkQuickSwap?>(null);
  int _swapSerial = 0;
  int? _swapPage;
  double _sx0 = 0, _sy0 = 0, _sx1 = 0, _sy1 = 0;
  Size _swapSize = Size.zero;

  late final Listenable offers = Listenable.merge([
    eraserOffer,
    penOffer,
    quickSwap,
  ]);

  /// çizim ona hiç başlamaz. KÖK NEDEN (kullanıcı bildirimi 2026-11-08,
  /// "kalemle oto düzelt onayına basılamıyor"): kalemin inişi önce çizimi
  /// başlatıp öneriyi siliyordu, işaretçi kalkışı hiç görmüyordu.
  void claimPointer(int pointer) => _claimed.add(pointer);
  final Set<int> _claimed = {};

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
  Offset _rotCenterPx = Offset.zero;
  double _rotLast = 0;
  Size _rotSize = Size.zero;

  /// Dönme tutamağından seçim döndürülüyor.
  bool _rotating = false;
  double _moveX = 0, _moveY = 0;

  /// Döndürme tutamağının kutunun üstünden uzaklığı (piksel).
  static const rotateHandleGap = 30.0;

  /// Çift dokunuşla yeniden seçimin bekleyen dokunuşu.
  ({DateTime at, int page, double x, double y, List<InkStroke> before})?
  _lastTap;

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

  /// Bu jestin geçici silgisi PARMAK aracından mı (K34: parmak "Siler").
  bool _fingerErase = false;

  /// Bu yarıçaptan (dp, `PointerEvent.radiusMajor`) geniş parmak teması
  /// avuçtur: parmak-silgi SİLMEZ. 0 = cihaz bildirmiyor → süzülmez.
  /// ponytail: tahminî eşik — tablette parmak ucu/avuç ölçülüp ayarlanacak.
  static const kFingerEraserPalmRadius = 22.0;

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
    _undoFingerErase();
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
    double? touchRadius,
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
      // Parmak-silgide geniş temas avuçtur (K34): hiç üstlenilmez.
      if (kind == PointerDeviceKind.touch &&
          InkToolMemory.fingerErases &&
          (touchRadius ?? 0) > kFingerEraserPalmRadius) {
        return;
      }
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
      _undoFingerErase();
      _swapPage = null;
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
    if (penOffer.value != null) penOffer.value = null;
    _hideQuickSwap();
    _swapPage = page;
    _swapSize = size;
    _sx0 = _sx1 = local.dx;
    _sy0 = _sy1 = local.dy;
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
    // Parmak "Siler" (K34): parmak dokunuşu yan düğme silgisiyle aynı yol;
    // seçimi (tutamak ya da kement içi) yine taşır, kalemin aracı kalemde
    // kalır.
    final selBounds = selectionBounds;
    _fingerErase =
        kind == PointerDeviceKind.touch &&
        InkToolMemory.fingerErases &&
        !penOnly &&
        !_tempEraser &&
        !(lasso &&
            selBounds != null &&
            selectionPage == page &&
            selBounds
                .inflate(0.03)
                .contains(Offset(local.dx / size.width, local.dy / size.height)));
    if (_fingerErase) _tempEraser = true;
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
      _eraserHold?.cancel();
      _eraserHold = null;
      _snapped = false;
      if (eraser && !_tempEraser) {
        final x = local.dx / size.width;
        final y = local.dy / size.height;
        _eraserHoldAt = Offset(x, y);
        _eraserHold = Timer(kInkHoldDuration, () => _offerPen(page));
        _showHold(page, x, y, eraser: false);
      }
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
    AppHaptics.tick();
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
    penOffer.dispose();
    quickSwap.dispose();
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
    if (_swapPage != null) {
      final x = local.dx, y = local.dy;
      if (x < _sx0) _sx0 = x;
      if (x > _sx1) _sx1 = x;
      if (y < _sy0) _sy0 = y;
      if (y > _sy1) _sy1 = y;
    }
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
      if (_snapped) return; // kalem önerisi çıktı: parmak kalkana dek silme yok
      final holdAt = _eraserHoldAt;
      if (_eraserHold != null &&
          holdAt != null &&
          math.max(
                (local.dx / size.width - holdAt.dx).abs(),
                (local.dy / size.height - holdAt.dy).abs(),
              ) >
              0.01) {
        _eraserHold?.cancel();
        _eraserHold = null;
        _clearHold();
      }
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
    // uç gerçekten yol alınca yeniden kurulur. Halka yalnızca kalem gerçekten
    // 140 ms durunca kurulur: hızlı çizimde 2,4 dp'de bir widget fırtınası yok.
    if (shapeSnap && math.max((x - _holdX).abs(), (y - _holdY).abs()) > 0.006) {
      _holdX = x;
      _holdY = y;
      _holdTimer?.cancel();
      _clearHold();
      _holdTimer = Timer(kInkHoldDuration, _snapActive);
      final quietWait = kInkHoldDuration ~/ 4;
      final activePage = active.page;
      _holdPreTimer = Timer(quietWait, () {
        if (!identical(_active, active)) return;
        _showHold(
          activePage,
          _holdX,
          _holdY,
          eraser: false,
          duration: kInkHoldDuration - quietWait,
        );
      });
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
      final samples = _inkSampled(s);
      var inside = 0;
      final n = samples.length ~/ 2;
      for (var i = 0; i + 1 < samples.length; i += 2) {
        if (inkPointInPolygon(samples[i], samples[i + 1], path)) inside++;
      }
      if (n > 0 && inside * 2 > n) picked.add(s);
    }
    _selected = picked;
    if (picked.isNotEmpty) AppHaptics.tick();
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
    final wasTemp = _tempEraser;
    final swapPage = _swapPage;
    _swapPage = null;
    _snapLineFrom = null;
    _tempEraser = false;
    _fingerErase = false;
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
          AppHaptics.tick();
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
    // Çizgi (ya da silgi geçişi) bitti: hızlı düğme yanında belirir. Tık,
    // kement, geçici silgi (yan düğme / parmak Siler) ve taşıma hariç.
    final box = Rect.fromLTRB(_sx0, _sy0, _sx1, _sy1);
    if (InkToolMemory.quickSwap &&
        swapPage != null &&
        !lasso &&
        !wasTemp &&
        (wasErasing || (done != null && !wasSnapped)) &&
        box.longestSide >= kInkQuickSwapMinStroke) {
      _showQuickSwap(swapPage, box, _swapSize);
    }
    notifyListeners();
  }

}

/// Basılı tutulan çizginin üstünde beliren silgi düğmesi (bkz.
/// [InkController.eraserOffer]). İnişte kabul eder — düzeltme işaretçisiyle
/// aynı neden (kalem/parmak inişi çizim katmanına kaçmasın).
class _EraserOfferButton extends StatelessWidget {
  const _EraserOfferButton({
    required this.onClaim,
    required this.onAccept,
    this.toPen = false,
  });

  final ValueChanged<int> onClaim;
  final VoidCallback onAccept;

  /// true = silgiden kaleme dönüş düğmesi (P59).
  final bool toPen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = toPen ? context.l10n.inkPenOffer : context.l10n.inkEraserOffer;
    return Semantics(
      button: true,
      label: label,
      onTap: onAccept,
      child: Tooltip(
        message: label,
        child: Material(
          key: ValueKey(toPen ? 'ink-pen-offer' : 'ink-eraser-offer'),
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
                toPen ? Icons.edit_outlined : Icons.auto_fix_normal_outlined,
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

/// Hızlı düğmenin çapı ve çizgi kutusuna uzaklığı (dp).
const double kInkQuickSwapSize = 40;
const double kInkQuickSwapGap = 20;

/// Önceki yer, yeni çizgi düğmeden en çok bu kadar uzaktaysa korunur (dp).
const double kInkQuickSwapReach = 180;

