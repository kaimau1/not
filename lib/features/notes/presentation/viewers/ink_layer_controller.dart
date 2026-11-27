part of 'ink_layer.dart';

List<Offset> _inkPixels(InkStroke s, Size size) => [
  for (var i = 0; i + 1 < s.points.length; i += 2)
    Offset(s.points[i] * size.width, s.points[i + 1] * size.height),
];

bool _sameInkStrokes(List<InkStroke> a, List<InkStroke> b) {
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
double? _inkPageShift(InkStroke s, int page) {
  final d = s.page - page;
  if (d == 0) return 0;
  if (d.abs() != 1) return null;
  return d.toDouble();
}

  /// Silgi için çizginin örnek noktaları: ardışık iki nokta arası silgi
  /// yarıçapından uzaksa ara noktalar eklenir (ok, düz çizgi, dikdörtgen).
List<double> _inkSampled(InkStroke s) {
  final p = s.points;
  if (p.length < 4) return p;
  var sparse = false;
  for (var i = 2; i + 1 < p.length; i += 2) {
    if ((p[i] - p[i - 2]).abs() > InkController._eraseRadius ||
        (p[i + 1] - p[i - 1]).abs() > InkController._eraseRadius) {
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
      (math.max(dx.abs(), dy.abs()) / InkController._eraseRadius).ceil(),
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

extension InkControllerOps on InkController {
  void _showHold(
    int page,
    double x,
    double y, {
    required bool eraser,
    Duration duration = kInkHoldDuration,
  }) {
    holdProgress.value = InkHoldProgress(
      page: page,
      at: Offset(x, y),
      eraser: eraser,
      serial: ++_holdSerial,
      duration: duration,
    );
  }

  void _clearHold() {
    _holdPreTimer?.cancel();
    _holdPreTimer = null;
    if (holdProgress.value != null) holdProgress.value = null;
  }

  /// Silgi önerisini kabul et: silgi seçilir, öneri kalkar.
  void acceptEraserOffer() {
    eraserOffer.value = null;
    setEraser(true);
  }

  /// **SİLGİDE BASILI TUT = KALEM** (P59, kullanıcı 2026-11-14: "silgiden


  void _hideQuickSwap() {
    final q = quickSwap.value;
    if (q != null && q.shown) quickSwap.value = q.hidden();
  }

  void _showQuickSwap(int page, Rect box, Size size) {
    final prev = quickSwap.value;
    // Aynı sayfa ve boyda önceki yer aday olarak verilir: yazı yakınında
    // kaldıkça düğme kıpırdamaz (kullanıcı bulgusu 2026-11-19: "bir sağda,
    // bir aşağıda, bir yukarıda; çok unstable").
    final keep = prev != null && prev.page == page && prev.size == size
        ? prev.at
        : null;
    quickSwap.value = InkQuickSwap(
      page: page,
      box: box,
      size: size,
      serial: ++_swapSerial,
      at: inkQuickSwapPlace(box, size, previous: keep),
    );
  }

  /// Hızlı düğmeye dokunuldu: kalem ↔ silgi; düğme yerinde kalır (solma
  /// saati düğmenin kendisinde — denetleyicide zamanlayıcı yok).
  void toggleQuickSwap() {
    if (eraser) {
      setPen(pen);
    } else {
      setEraser(true);
    }
    AppHaptics.tick();
  }

  /// Silgi + kalem önerisi birlikte (katmanda tek dinleyici).


  void acceptPenOffer() {
    penOffer.value = null;
    setPen(pen);
  }

  void _offerPen(int page) {
    _clearHold();
    final at = _eraserHoldAt;
    _eraserHold = null;
    if (at == null || _pointers != 1 || !eraser || _tempEraser) return;
    final base = _gestureBase;
    if (base != null && !identical(base, _ink)) {
      _ink = base;
      _dirty = true;
    }
    // Parmak kalkana dek silme sürmez (bkz. pointerMove: _snapped).
    _snapped = true;
    _showOffer(penOffer, page, at);
  }

  /// Basılı tutma önerisini (silgi / kalem) gösterir: tek titreşim yolu.
  void _showOffer(
    ValueNotifier<({int page, Offset at})?> offer,
    int page,
    Offset at,
  ) {
    offer.value = (page: page, at: at);
    AppHaptics.tick();
    _notify();
  }

  bool _inkNear(int page, double x, double y) {
    const r = InkController._eraseRadius * 1.5;
    for (final s in _ink) {
      if (s.page != page) continue;
      final samples = _inkSampled(s);
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
    _showOffer(eraserOffer, page, at);
  }

  /// Katmanın üstündeki bir düğme (düzeltme işaretçisi) bu dokunuşu aldı:



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
      _inkPixels(stroke, size),
      previous: prev == null ? null : _inkPixels(prev, size),
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
    AppHaptics.tick();
    _notify();
  }

  /// Çizim değişince güncel çizgi listesiyle çağrılır (kaydetme).


  bool _onHandle(Offset local, Size size) {
    final b = selectionBounds;
    if (b == null) return false;
    final corner = Offset(b.right * size.width + 8, b.bottom * size.height + 8);
    return (local - corner).distance <= InkController._handleRadius;
  }

  /// **DÖNDÜRME** (kullanıcı isteği 2026-11-09: "şekilleri tanıdıktan sonra
  /// döndüremiyorum"): seçim kutusunun üst ortasındaki tutamak. Dönüş PİKSEL
  /// uzayında yapılır (oranlı uzayda en/boy farklı, şekil bozulurdu).
  bool _onRotateHandle(Offset local, Size size) {
    final b = selectionBounds;
    if (b == null) return false;
    final at = Offset(
      b.center.dx * size.width,
      b.top * size.height - 8 - InkController.rotateHandleGap,
    );
    return (local - at).distance <= InkController._handleRadius;
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

  InkStroke? _strokeNear(int page, double x, double y) {
    const r = InkController._eraseRadius * 1.5;
    for (final s in _ink.reversed) {
      if (s.page != page) continue;
      final samples = _inkSampled(s);
      for (var i = 0; i + 1 < samples.length; i += 2) {
        if ((samples[i] - x).abs() < r && (samples[i + 1] - y).abs() < r) {
          return s;
        }
      }
    }
    return null;
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

  void setEditing(bool value) {
    if (editing == value) return;
    editing = value;
    if (!editing) save();
    _notify();
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
    _notify();
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
    _notify();
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

  /// Parmağın işi (K34): Kaydırır / Çizer / Siler. Hep kullanıcı seçimi.
  void setFingerTool(FingerTool tool) {
    InkToolMemory.saveFingerTool(tool);
    _toolChanged();
  }

  /// Parmak-silgi jesti yakınlaştırma niyetine döndü (ikinci parmak): sildiği
  /// her şey geri gelir — yakınlaştırırken çizgi kaybolmasın.
  void _undoFingerErase() {
    if (!_fingerErase) return;
    final base = _gestureBase;
    if (base != null) _ink = base;
    _fingerErase = false;
    _tempEraser = false;
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
    if (_history.length > InkController._historyMax) _history.removeAt(0);
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
    _notify();
  }

  void redo() {
    dismissSuggestion();
    _selected = const [];
    if (_future.isEmpty) return;
    _history.add(_ink);
    _ink = _future.removeLast();
    _dirty = true;
    save();
    _notify();
  }

  void clear() {
    dismissSuggestion();
    if (_ink.isEmpty) return;
    _pushHistory(_ink);
    _dirty = true;
    _ink = [];
    save();
    _notify();
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
    if (_sameInkStrokes(_ink, strokes)) return;
    dismissSuggestion();
    _dirty = false;
    _ink = [...strokes];
    _selected = const [];
    _lassoPath = null;
    // Dışarıdan gelen liste geçmişi geçersiz kılar (geri al eski listeye
    // dönüp başka cihazın çizimini silmesin).
    _history.clear();
    _future.clear();
    _notify();
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
      final shift = _inkPageShift(s, page);
      if (shift != null) {
        // OK yalnız İKİ nokta taşır; gövdesine dokunmak da silmeli, yoksa
        // yalnız uçlarından yakalanan bir çizgi olurdu. Düz çizgi ve
        // dikdörtgenin kenarları da seyrek noktalı — aynı örnekleme.
        final samples = _inkSampled(s);
        for (var i = 0; i < samples.length; i += 2) {
          if ((samples[i] - x).abs() < InkController._eraseRadius &&
              (samples[i + 1] + shift - y).abs() < InkController._eraseRadius) {
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
    const r = InkController._eraseRadius;
    var changed = false;
    final out = <InkStroke>[];
    for (final s in _ink) {
      final shift = _inkPageShift(s, page);
      if (shift == null) {
        out.add(s);
        continue;
      }
      final ey = y - shift;
      bool near(double px, double py) =>
          (px - x).abs() < r && (py - ey).abs() < r;
      final sampled = _inkSampled(s);
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


}
