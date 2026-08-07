import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// PDF ve slayt görüntüleyicilerinin ortak **not balonu** katmanı — uygulamanın
/// belge üzerinde çalışma biçiminin ANA aracı.
///
/// Kullanıcı belgenin istediği noktasına balon bırakır ve içine yazar; ya da
/// bir metni seçip **vurgular** — vurgu da bir balondur, dikdörtgenleri
/// [PageBubble.rects] içinde durur ve dokununca aynı kart açılır. Balonlar
/// açılıp kapanır, basılı tutup sürüklenerek taşınır, yıldızlanır ve toplu
/// listeden aranır.
///
/// PDF dosyasına GÖMÜLMEZ: sayfa oranlı (0–1) konumla [PageBubble] listesinde
/// durur ve [onChanged] ile üst katmana (ek → not → Firestore) verilir —
/// çizim katmanıyla (`InkController`) birebir aynı yol.
///
/// **Sürüklemenin kök nedeni (2026-08-08 kullanıcı bulgusu: "çok zor
/// sürükleniyor").** Eski sürüm `onPanUpdate` kullanıyordu; sürükleme jesti
/// pdfrx'in `InteractiveViewer`'ıyla AYNI arenada yarışır ve kaydırma
/// tanıyıcısı çoğu zaman önce kazanır — parmak balonu değil sayfayı çekerdi.
/// Şimdi taşıma UZUN BASIŞLA başlıyor (`onLongPressStart`): uzun basış
/// arenayı kesin kazanır, titreşimle "aldım" der ve `onLongPressMoveUpdate`
/// parmakla birebir gider. Ek olarak taşıma sürerken üst katman
/// [onDragChanged] ile görüntüleyicinin pan'ını kilitler.
class BubbleController extends ChangeNotifier {
  BubbleController({required List<PageBubble> initial, required this.onChanged})
    : _bubbles = [...initial];

  /// Balonlar değişince güncel listeyle çağrılır (kaydetme).
  final ValueChanged<List<PageBubble>> onChanged;

  static const _uuid = Uuid();

  /// Seçilebilecek renkler. Konu ayırmak için: kullanıcı isteğiyle genişletildi
  /// (2026-08-08) — beş renk "konu başına bir renk" için yetmiyordu.
  static const palette = <int>[
    0xFFFFC107, // amber
    0xFFEF5350, // kırmızı
    0xFF66BB6A, // yeşil
    0xFF42A5F5, // mavi
    0xFFAB47BC, // mor
    0xFFFF7043, // turuncu
    0xFF26C6DA, // turkuaz
    0xFFEC407A, // pembe
    0xFF8D6E63, // kahve
    0xFF9CCC65, // fıstık
    0xFF5C6BC0, // indigo
    0xFF78909C, // gri-mavi
  ];

  List<PageBubble> _bubbles;
  List<PageBubble> get bubbles => _bubbles;

  /// "Balon bırak" kipi açık mı? Açıkken sayfaya dokunmak o noktaya balon
  /// bırakır; kapalıyken sayfa normal okunur/kaydırılır ve yalnız var olan
  /// balonlar dokunuşa yanıt verir.
  bool adding = false;

  /// Yeni bırakılacak balonun rengi.
  int color = palette.first;

  /// Az önce eklenen balon: katman onu açık ve klavyesi odaklanmış getirir.
  String? justAdded;

  /// ŞU AN taşınan balon (uzun basışla tutuldu). Üst katman bu doluyken
  /// görüntüleyicinin pan'ını kilitler.
  String? dragging;

  /// Bir balon açık ve kullanıcı İÇİNE YAZIYOR. Pano bölmesi bunu görünce alt
  /// not alanını gizler (kullanıcı bulgusu: "balona not yazarken klavye, sayfa
  /// hepsi kayıyor").
  bool editing = false;

  /// [editing] her değiştiğinde çağrılır — bölmeyi daraltan üst katman için.
  ValueChanged<bool>? onEditingChanged;

  /// Taşıma başlayıp bitince çağrılır (pan kilidi).
  ValueChanged<bool>? onDragChanged;

  bool _dirty = false;

  void setAdding(bool value) {
    if (adding == value) return;
    adding = value;
    notifyListeners();
  }

  void setColor(int value) {
    color = value;
    notifyListeners();
  }

  void setDragging(String? id) {
    if (dragging == id) return;
    final was = dragging != null;
    dragging = id;
    if (was != (id != null)) onDragChanged?.call(id != null);
    notifyListeners();
  }

  void setEditing(bool value) {
    if (editing == value) return;
    editing = value;
    onEditingChanged?.call(value);
    notifyListeners();
  }

  /// Dışarıdan gelen listeyi benimser (tam ekranda balon eklenip panoya
  /// dönüldüğünde). İÇERİK karşılaştırılır: her anlık görüntü yeni bir liste
  /// nesnesi kurduğu için kimlik karşılaştırması sonsuz tazelemeye yol açar.
  void replace(List<PageBubble> next) {
    if (_sameContent(_bubbles, next)) return;
    _bubbles = [...next];
    notifyListeners();
  }

  static bool _sameContent(List<PageBubble> a, List<PageBubble> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].page != b[i].page ||
          a[i].x != b[i].x ||
          a[i].y != b[i].y ||
          a[i].text != b[i].text ||
          a[i].color != b[i].color ||
          a[i].collapsed != b[i].collapsed ||
          a[i].starred != b[i].starred ||
          a[i].rects.length != b[i].rects.length) {
        return false;
      }
    }
    return true;
  }

  /// [page] sayfasının balonları (çizim gibi sayfa başına süzülür).
  List<PageBubble> forPage(int page) => [
    for (final b in _bubbles)
      if (b.page == page) b,
  ];

  PageBubble? byId(String id) {
    for (final b in _bubbles) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Sayfanın boş bir noktasına serbest balon bırakır.
  void add(int page, double x, double y) => _insert(
    PageBubble(
      id: _uuid.v4(),
      page: page,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      color: color,
    ),
  );

  /// Seçili metni VURGULAR: dikdörtgenleri taşıyan bir balon kurar.
  ///
  /// [open] false ise balon kapalı doğar — kullanıcı yalnız "vurgula" dedi,
  /// klavye açılmasın; true ise kart açılır ve yazmaya hazır gelir.
  void addHighlight({
    required int page,
    required List<PageBubbleRect> rects,
    required bool open,
  }) {
    if (rects.isEmpty) return;
    // Uç noktası vurgunun SON satırının sağ ucu: kart metnin altına açılır,
    // vurgulanan yazının üstünü kapatmaz.
    final last = rects.last;
    _insert(
      PageBubble(
        id: _uuid.v4(),
        page: page,
        x: ((last.left + last.right) / 2).clamp(0.0, 1.0),
        y: last.bottom.clamp(0.0, 1.0),
        color: color,
        collapsed: !open,
        rects: rects,
      ),
      focus: open,
    );
  }

  void _insert(PageBubble bubble, {bool focus = true}) {
    _bubbles = [..._bubbles, bubble];
    justAdded = focus ? bubble.id : null;
    // Tek balon bırakıp arka arkaya on tane daha bırakmak isteyen azdır:
    // ekleme kipi bırakıldıktan sonra kapanır, kullanıcı yazısına odaklanır.
    adding = false;
    _dirty = true;
    notifyListeners();
    save();
  }

  void update(PageBubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index < 0) return;
    _bubbles = [..._bubbles]..[index] = bubble;
    _dirty = true;
    notifyListeners();
  }

  /// Balonun METNİNİ dinleyicileri UYANDIRMADAN günceller.
  ///
  /// Kök neden (kasma): metin `update` ile yazılınca her tuş vuruşu
  /// `notifyListeners` çağırıyor, o da sayfadaki BÜTÜN balon katmanını (ve
  /// vurgu boyamasını) yeniden kuruyordu. Yazılan metni zaten `TextField`
  /// kendi gösteriyor; dışarıya haber vermenin tek gerekli anı kaydetmedir.
  void updateText(String id, String text) {
    final index = _bubbles.indexWhere((b) => b.id == id);
    if (index < 0) return;
    _bubbles = [..._bubbles]..[index] = _bubbles[index].copyWith(text: text);
    _dirty = true;
  }

  /// Metin yazımı gibi sık değişimlerde [update] yalnız belleği tazeler;
  /// kaydetme (Firestore yazımı) balon kapanınca/odak düşünce buradan olur.
  void save() {
    if (!_dirty) return;
    _dirty = false;
    onChanged(_bubbles);
  }

  void remove(String id) {
    _bubbles = [
      for (final b in _bubbles)
        if (b.id != id) b,
    ];
    _dirty = true;
    if (justAdded == id) justAdded = null;
    notifyListeners();
    save();
  }

  void setCollapsed(String id, bool value) {
    final index = _bubbles.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final bubble = _bubbles[index];
    if (bubble.collapsed == value) return;
    _bubbles = [..._bubbles]..[index] = bubble.copyWith(collapsed: value);
    if (justAdded == id && value) justAdded = null;
    _dirty = true;
    notifyListeners();
    save();
  }

  void toggleCollapsed(String id) {
    final bubble = byId(id);
    if (bubble != null) setCollapsed(id, !bubble.collapsed);
  }

  void toggleStar(String id) {
    final bubble = byId(id);
    if (bubble == null) return;
    update(bubble.copyWith(starred: !bubble.starred));
    save();
  }

  /// Sayfadaki AÇIK balonları kapatır — sayfanın boş bir yerine dokununca.
  /// Kapanan oldu mu döner (dokunuş "tüketildi" mi).
  bool collapseAll() {
    var changed = false;
    final next = <PageBubble>[];
    for (final b in _bubbles) {
      if (b.collapsed) {
        next.add(b);
      } else {
        next.add(b.copyWith(collapsed: true));
        changed = true;
      }
    }
    if (!changed) return false;
    _bubbles = next;
    justAdded = null;
    _dirty = true;
    notifyListeners();
    save();
    return true;
  }

  /// Bir balonu tek başına açar, diğerlerini kapatır (toplu listeden "balona
  /// git" ve vurguya dokunma bu yoldan geçer — iki kart yan yana açık kalmaz).
  void openOnly(String id) {
    var changed = false;
    final next = <PageBubble>[];
    for (final b in _bubbles) {
      final wanted = b.id == id ? false : true; // yalnız hedef açık kalır
      if (b.collapsed == wanted) {
        next.add(b);
      } else {
        next.add(b.copyWith(collapsed: wanted));
        changed = true;
      }
    }
    _bubbles = next;
    justAdded = id;
    if (changed) {
      _dirty = true;
      save();
    }
    notifyListeners();
  }

  /// Boş kalmış SERBEST balonları atar — kullanıcı balon bırakıp hiçbir şey
  /// yazmadan çıkarsa sayfada anlamsız bir nokta kalmasın. Vurgular korunur:
  /// onların kendi başına bir anlamı var (metni işaretlemek).
  void dropEmpty() {
    final kept = [
      for (final b in _bubbles)
        if (b.text.trim().isNotEmpty || b.isHighlight) b,
    ];
    if (kept.length != _bubbles.length) {
      _bubbles = kept;
      _dirty = true;
      notifyListeners();
    }
    save();
  }
}

/// Tek bir sayfanın üzerindeki balonlar ve vurgular. Sayfa katmanı olarak
/// (`pageOverlaysBuilder` / `Positioned.fill`) kurulur.
///
/// **Dokunuşu YUTMAZ:** ekleme kipi kapalıyken katmanın kendisi saydamdır,
/// yalnız balonların/vurguların kendisi dokunuş alır — sayfa kaydırma ve
/// yakınlaştırma bozulmaz. Vurgu boyaması `IgnorePointer` altında; dokunuşu
/// vurgunun kendi görünmez dokunma alanı alır.
class BubblePageLayer extends StatelessWidget {
  const BubblePageLayer({
    super.key,
    required this.controller,
    required this.page,
    this.readOnly = false,
  });

  final BubbleController controller;
  final int page;

  /// Salt görüntüleme: balonlar görünür ve açılıp kapanır ama düzenlenmez.
  final bool readOnly;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final bubbles = controller.forPage(page);
        final anyOpen = bubbles.any((b) => !b.collapsed);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Vurgu boyası EN ALTTA ve dokunuşa kapalı: rengi metnin üstüne
            // serer, parmağı almaz (dokunuşu aşağıdaki görünmez alan alır).
            IgnorePointer(
              child: CustomPaint(
                size: size,
                painter: _HighlightPainter(bubbles: bubbles),
              ),
            ),
            // Vurguya dokunmak balonu AÇAR (kullanıcı isteği). Görünmez
            // dokunma alanları yalnız vurgunun satırlarını kaplar.
            for (final bubble in bubbles)
              if (bubble.collapsed && bubble.isHighlight)
                for (final rect in bubble.rects)
                  Positioned(
                    left: rect.left * size.width,
                    top: rect.top * size.height,
                    width: (rect.right - rect.left) * size.width,
                    height: (rect.bottom - rect.top) * size.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => controller.openOnly(bubble.id),
                      child: const SizedBox.expand(),
                    ),
                  ),
            if (controller.adding && !readOnly)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    HapticFeedback.selectionClick();
                    controller.add(
                      page,
                      d.localPosition.dx / size.width,
                      d.localPosition.dy / size.height,
                    );
                  },
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
            // Açık balon varken sayfanın boşluğuna dokunmak onu KAPATIR
            // (kullanıcı isteği: "balonu kapatmak için sayfanın bir yerine
            // tıklamak yeterli olmalı"). Yalnız TAP dinlenir — kaydırma ve
            // yakınlaştırma jestleri alta geçmeye devam eder.
            if (anyOpen && !controller.adding)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: controller.collapseAll,
                  child: const SizedBox.expand(),
                ),
              ),
            for (final bubble in bubbles)
              _Bubble(
                key: ValueKey(bubble.id),
                controller: controller,
                bubble: bubble,
                pageSize: size,
                readOnly: readOnly,
                autofocus: controller.justAdded == bubble.id,
              ),
          ],
        );
      },
    ),
  );
}

/// Vurgu dikdörtgenlerini balonun rengiyle boyar. Yarı saydam ve TEK yol:
/// üst üste binen satırlarda renk koyulaşmasın.
class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.bubbles});

  final List<PageBubble> bubbles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      if (bubble.rects.isEmpty) continue;
      final path = Path();
      for (final r in bubble.rects) {
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              r.left * size.width,
              r.top * size.height,
              r.right * size.width,
              r.bottom * size.height,
            ),
            const Radius.circular(2),
          ),
        );
      }
      canvas.drawPath(
        path,
        Paint()..color = Color(bubble.color).withValues(alpha: 0.34),
      );
    }
  }

  /// **Dokunuşu YUTMAZ.** `painter:` verilmiş bir `CustomPaint`, `hitTest`
  /// geçersiz kılınmazsa (`hitTestSelf` içinde `?? true`) kapladığı alandaki
  /// HER dokunuşu yutar — bu boyayıcı sayfanın tamamını kapladığı için sayfa
  /// kaydırma ve yakınlaştırma ölürdü. Aynı tuzak `PdfSelectLayer`'da da var.
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    super.key,
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
    required this.autofocus,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;
  final bool autofocus;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  late final TextEditingController _text = TextEditingController(
    text: widget.bubble.text,
  );
  final _focus = FocusNode();

  /// Açık balonun en büyük genişliği.
  static const _maxWidth = 260.0;
  static const _pinSize = 30.0;

  /// Sürüklerken parmağın balonu "kaldırdığı" hissi: kart büyür ve gölgesi
  /// derinleşir (Material'ın sürükleme dili).
  bool _lifted = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Odak düşünce yazılan metin kalıcılaşır (her tuşta Firestore'a
      // yazmamak için: `update` belleği, `save` diski tazeler).
      if (!_focus.hasFocus) widget.controller.save();
      widget.controller.setEditing(_focus.hasFocus);
    });
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.readOnly) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_Bubble old) {
    super.didUpdateWidget(old);
    // Dışarıdan (senkron ya da toplu listeden düzenleme) değişen metni
    // benimse — kullanıcı o an yazmıyorsa.
    if (widget.bubble.text != _text.text && !_focus.hasFocus) {
      _text.text = widget.bubble.text;
    }
    // Toplu listeden "balona git" ile açıldıysa klavye hazır gelsin.
    if (old.autofocus != widget.autofocus &&
        widget.autofocus &&
        !widget.bubble.collapsed &&
        !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (_focus.hasFocus) widget.controller.setEditing(false);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  double get _width =>
      (widget.pageSize.width * 0.62).clamp(140.0, _maxWidth).toDouble();

  /// Balonun sol-üst köşesinin sayfadaki piksel konumu. Uç noktası (x,y)
  /// sayfanın sağ/alt kenarına yakınsa kart içeri alınır ki taşmasın.
  Offset _topLeft(double width, {required bool collapsed}) {
    final point = Offset(
      widget.bubble.x * widget.pageSize.width,
      widget.bubble.y * widget.pageSize.height,
    );
    if (collapsed) {
      return point - const Offset(_pinSize / 2, _pinSize / 2);
    }
    final maxLeft = widget.pageSize.width - width;
    final left = maxLeft <= 0 ? 0.0 : (point.dx - width / 2).clamp(0.0, maxLeft);
    return Offset(left, point.dy + _pinSize / 2);
  }

  // ── Taşıma: UZUN BASIŞ + sürükle ─────────────────────────────────────────
  //
  // Uzun basış jest arenasını KESİN kazanır (pan/scale tanıyıcıları elenir),
  // bu yüzden parmak balonu değil sayfayı çekme sorunu ortadan kalkar. Başlama
  // anında titreşim var: kullanıcı "tuttum" hissini duyar.
  void _dragStart(Offset _) {
    if (widget.readOnly) return;
    HapticFeedback.mediumImpact();
    setState(() => _lifted = true);
    widget.controller.setDragging(widget.bubble.id);
  }

  void _dragMove(Offset delta) {
    if (widget.readOnly || !_lifted) return;
    final b = widget.bubble;
    widget.controller.update(
      b.copyWith(
        x: (b.x + delta.dx / widget.pageSize.width).clamp(0.0, 1.0),
        y: (b.y + delta.dy / widget.pageSize.height).clamp(0.0, 1.0),
      ),
    );
  }

  void _dragEnd() {
    if (!_lifted) return;
    setState(() => _lifted = false);
    widget.controller
      ..setDragging(null)
      ..save();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.bubble;
    final color = Color(bubble.color);
    if (bubble.collapsed) return _pin(color);

    final width = _width;
    final at = _topLeft(width, collapsed: false);
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: width,
      child: AnimatedScale(
        scale: _lifted ? 1.06 : 1,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          // Kartın TAMAMI taşıma tutamacıdır: uzun basıp sürükle. Kısa
          // dokunuş yazı alanına gider (uzun basış onu iptal etmez).
          onLongPressStart: (d) => _dragStart(d.localPosition),
          onLongPressMoveUpdate: (d) {
            _dragMove(d.offsetFromOrigin - _last);
            _last = d.offsetFromOrigin;
          },
          onLongPressEnd: (_) {
            _last = Offset.zero;
            _dragEnd();
          },
          onLongPressCancel: () {
            _last = Offset.zero;
            _dragEnd();
          },
          child: Material(
            color: color.withValues(alpha: 0.97),
            elevation: _lifted ? 10 : 3,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 4, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: Colors.black45,
                      ),
                      const Spacer(),
                      if (!widget.readOnly)
                        _iconButton(
                          icon: bubble.starred ? Icons.star : Icons.star_border,
                          tooltip: context.l10n.bubbleStar,
                          onPressed: () =>
                              widget.controller.toggleStar(bubble.id),
                        ),
                      if (!widget.readOnly)
                        _iconButton(
                          icon: Icons.palette_outlined,
                          tooltip: context.l10n.color,
                          onPressed: () => _pickColor(context),
                        ),
                      _iconButton(
                        icon: Icons.close_fullscreen,
                        tooltip: context.l10n.bubbleCollapse,
                        onPressed: () {
                          _focus.unfocus();
                          widget.controller.setCollapsed(bubble.id, true);
                        },
                      ),
                      if (!widget.readOnly)
                        _iconButton(
                          icon: Icons.delete_outline,
                          tooltip: context.l10n.delete,
                          onPressed: () => widget.controller.remove(bubble.id),
                        ),
                    ],
                  ),
                  if (widget.readOnly)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
                      child: Text(
                        bubble.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: _text,
                      focusNode: _focus,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      cursorColor: scheme.onSurface,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: context.l10n.bubbleHint,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                        ),
                      ),
                      onChanged: (value) =>
                          widget.controller.updateText(bubble.id, value),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Uzun basış sürüklemesi TOPLAM kaymayı verir; iki olay arasındaki FARKI
  /// bulmak için son değer saklanır.
  Offset _last = Offset.zero;

  Widget _pin(Color color) {
    final bubble = widget.bubble;
    final at = _topLeft(_pinSize, collapsed: true);
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: AnimatedScale(
        scale: _lifted ? 1.25 : 1,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          onTap: () => widget.controller.openOnly(bubble.id),
          onLongPressStart: (d) => _dragStart(d.localPosition),
          onLongPressMoveUpdate: (d) {
            _dragMove(d.offsetFromOrigin - _last);
            _last = d.offsetFromOrigin;
          },
          onLongPressEnd: (_) {
            _last = Offset.zero;
            _dragEnd();
          },
          onLongPressCancel: () {
            _last = Offset.zero;
            _dragEnd();
          },
          child: Tooltip(
            message: bubble.text,
            child: Container(
              width: _pinSize,
              height: _pinSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _lifted ? 0.45 : 0.25),
                    blurRadius: _lifted ? 10 : 4,
                  ),
                ],
              ),
              child: Icon(
                bubble.starred
                    ? Icons.star
                    : (bubble.text.trim().isEmpty
                          ? Icons.format_color_text
                          : Icons.chat_bubble_outline),
                size: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 16, color: Colors.black54),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
  );

  Future<void> _pickColor(BuildContext context) async {
    final picked = await showBubbleColorSheet(context, widget.bubble.color);
    if (picked == null) return;
    widget.controller
      ..update(widget.bubble.copyWith(color: picked))
      ..save();
  }
}

/// Renk seçici levha — balon kartı ve araç çubuğu aynı listeyi kullansın.
Future<int?> showBubbleColorSheet(BuildContext context, int selected) =>
    showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final argb in BubbleController.palette)
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, argb),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(argb),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == argb
                            ? Theme.of(sheetContext).colorScheme.onSurface
                            : Colors.black26,
                        width: selected == argb ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

/// Görüntüleyicinin alt çubuğuna konan balon araç çubuğu: renk seçimi ve
/// "nereye dokunacaksın" ipucu. Yalnız ekleme kipinde görünür.
class BubbleToolbar extends StatelessWidget {
  const BubbleToolbar({super.key, required this.controller});

  final BubbleController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final argb in BubbleController.palette)
                      GestureDetector(
                        onTap: () => controller.setColor(argb),
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Color(argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: controller.color == argb
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  context.l10n.bubbleTapToPlace,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
