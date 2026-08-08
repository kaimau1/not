import 'package:flutter/gestures.dart'
    show LongPressGestureRecognizer, TapGestureRecognizer;
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
/// parmakla birebir gider.
///
/// **İKİNCİ tur düzeltmesi (2026-08-08, "hâlâ çok zor").** İki şey kalmıştı:
/// (a) Basılı tutma süresi Flutter'ın 500 ms varsayılanıydı; artık 220 ms
/// (bkz. [BubbleDragArea]) — "tut ve taşı" tek akışta hissediliyor.
/// (b) Taşıma başlarken görüntüleyicinin pan'ı kilitleniyordu; o kilit
/// `PdfViewerParams`ı değiştirip **jestin ortasında `PdfViewer`'ı yeniden
/// kuruyor** ve başlamış uzun basışı iptal ediyordu. Kilide GEREK YOK: uzun
/// basış arenayı kazandığı an pdfrx'in kaydırma/ölçek tanıyıcıları zaten
/// eleniyor. (Metin seçiminde kilit ŞART kalır — o katman arenaya hiç
/// girmeyen bir `Listener` kullanıyor.)
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

  /// **Vurgunun** rengi — balon renginden AYRI. Varsayılan fosforlu kırmızı:
  /// kullanıcı isteği "seçilen metnin üzeri kırmızı fosforlu kalemle
  /// çizilmiş gibi olsun". Balon rengi konu ayırmak için (sarı not, mavi
  /// soru...), vurgu ise metnin üstünde göze çarpmak için var.
  int highlightColor = highlightPalette.first;

  /// Vurgu için fosforlu tonlar (metnin üstünde okunurluğu bozmayan,
  /// doygunluğu yüksek renkler).
  static const highlightPalette = <int>[
    0xFFFF1744, // fosforlu kırmızı (varsayılan)
    0xFFFFEA00, // fosforlu sarı
    0xFF00E676, // fosforlu yeşil
    0xFF00B0FF, // fosforlu mavi
    0xFFFF9100, // fosforlu turuncu
    0xFFD500F9, // fosforlu mor
  ];

  void setHighlightColor(int value) {
    highlightColor = value;
    notifyListeners();
  }

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

  /// Taşıma başlayıp bitince çağrılır (yalnız bilgi amaçlı: pan kilidi
  /// ARTIK KURULMUYOR — bkz. sınıf açıklamasındaki ikinci tur düzeltmesi).
  ValueChanged<bool>? onDragChanged;

  /// ŞU AN açık olan balon (yoksa null). Açık balonun içeriği sayfada değil,
  /// görüntüleyicinin ÜSTÜNDEKİ sabit kartta ([BubbleDock]) düzenlenir.
  ///
  /// KÖK NEDEN (2026-08-08: "yazı yazmaya başlayınca balon yine altta
  /// kalıyor"): kart sayfa koordinatındaydı; klavye açılınca görünür alan
  /// yarıya iniyor ve sayfanın alt yarısındaki kart klavyenin altında
  /// kalıyordu. Belgeyi kaydırarak telafi etmek de okunan yeri kaçırıyordu.
  /// Artık sayfada YALNIZ tutamaç/vurgu var; içerik hep en üstte, klavyenin
  /// üstünde. (Kullanıcının kendi önerisi; PDF yorum araçlarının da yolu.)
  PageBubble? get openBubble {
    for (final b in _bubbles) {
      if (!b.collapsed) return b;
    }
    return null;
  }

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
        color: highlightColor,
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
  void updateTitle(String id, String title) {
    final index = _bubbles.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final clipped = title.characters.length > PageBubble.maxTitle
        ? title.characters.take(PageBubble.maxTitle).toString()
        : title;
    _bubbles = [..._bubbles]..[index] = _bubbles[index].copyWith(
      title: clipped,
    );
    _dirty = true;
  }

  void toggleUrgent(String id) {
    final bubble = byId(id);
    if (bubble == null) return;
    update(bubble.copyWith(urgent: !bubble.urgent));
    save();
  }

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
        final anyOpen = controller.openBubble != null;
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
              if (bubble.isHighlight)
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
            // Sayfada YALNIZ tutamaç/etiket durur; açık balonun içeriği
            // görüntüleyicinin üstündeki sabit kartta ([BubbleDock]).
            for (final bubble in bubbles)
              _BubblePin(
                key: ValueKey(bubble.id),
                controller: controller,
                bubble: bubble,
                pageSize: size,
                readOnly: readOnly,
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
      // FOSFORLU KALEM izi: satırın tamamını kaplayan soluk bir zemin +
      // ortasından geçen daha koyu, uçları yuvarlak KALIN bir iz. İkisi
      // birlikte "üzeri kalemle çizilmiş" görüntüsü verir; tek düz
      // dikdörtgen düz bir seçim vurgusu gibi duruyordu (kullanıcı isteği
      // 2026-08-08).
      final color = Color(bubble.color);
      final wash = Path();
      final stroke = Path();
      for (final r in bubble.rects) {
        final rect = Rect.fromLTRB(
          r.left * size.width,
          r.top * size.height,
          r.right * size.width,
          r.bottom * size.height,
        );
        if (rect.width <= 0 || rect.height <= 0) continue;
        wash.addRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        );
        // İz satır yüksekliğinin %58'i, dikeyde ortalanmış.
        final band = rect.height * 0.58;
        final center = rect.center.dy;
        stroke.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              rect.left,
              center - band / 2,
              rect.right,
              center + band / 2,
            ),
            Radius.circular(band / 2),
          ),
        );
      }
      canvas
        ..drawPath(wash, Paint()..color = color.withValues(alpha: 0.20))
        ..drawPath(stroke, Paint()..color = color.withValues(alpha: 0.42));
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


/// Balonu (kart ya da tutamaç) **basılı tutup sürüklenebilir** yapan sarmalayıcı.
///
/// Neden `GestureDetector` değil `RawGestureDetector`: `GestureDetector` uzun
/// basış SÜRESİNİ dışarı açmıyor ve Flutter'ın varsayılanı 500 ms — kullanıcı
/// "hâlâ çok zor sürükleniyor" derken tarif ettiği şey buydu. Burada süre
/// 220 ms; yarım saniye beklemek yerine "tut ve taşı" tek akışta oluyor.
///
/// Uzun basış arenayı kazandığı an pdfrx'in kaydırma/ölçek tanıyıcıları
/// elenir, yani sayfa altta kaymaz — ayrıca bir pan kilidine gerek yoktur.
class BubbleDragArea extends StatefulWidget {
  const BubbleDragArea({
    super.key,
    required this.child,
    required this.onDragStart,
    required this.onDragDelta,
    required this.onDragEnd,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onDragEnd;
  final VoidCallback? onTap;
  final bool enabled;

  static const _pressDuration = Duration(milliseconds: 220);

  @override
  State<BubbleDragArea> createState() => _BubbleDragAreaState();
}

class _BubbleDragAreaState extends State<BubbleDragArea> {
  /// Son bildirilen TOPLAM kayma. **STATE'te durmak zorunda.**
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "sürüklemeye başladığım anda
  /// kenarlara fırlıyor, kontrolsüz hareket ediyor"): bu değer `build()`
  /// içinde YEREL bir değişkendi. Taşıma sırasında her hareket denetleyiciyi
  /// güncelliyor, o da katmanı yeniden kuruyor ve `build()` yeniden koştuğu
  /// için değişken SIFIRLANIYORDU. Bir sonraki olayda fark, kare farkı yerine
  /// jestin BAŞINDAN itibaren toplam kayma olarak uygulanıyor ve balon
  /// parmaktan kat kat hızlı fırlıyordu.
  Offset _last = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.onTap == null
          ? widget.child
          : GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        if (widget.onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (instance) => instance.onTap = widget.onTap,
              ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: BubbleDragArea._pressDuration,
              ),
              (instance) => instance
                ..onLongPressStart = (_) {
                  _last = Offset.zero;
                  widget.onDragStart();
                }
                ..onLongPressMoveUpdate = (d) {
                  widget.onDragDelta(d.offsetFromOrigin - _last);
                  _last = d.offsetFromOrigin;
                }
                ..onLongPressEnd = (_) {
                  _last = Offset.zero;
                  widget.onDragEnd();
                }
                ..onLongPressCancel = () {
                  _last = Offset.zero;
                  widget.onDragEnd();
                },
            ),
      },
      child: widget.child,
    );
  }
}

/// Sayfadaki TUTAMAÇ: kapalıysa nokta ya da başlık etiketi, açıksa aynı
/// tutamacın vurgulanmış hâli. İçerik burada DEĞİL — [BubbleDock]'ta.
class _BubblePin extends StatefulWidget {
  const _BubblePin({
    super.key,
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;

  @override
  State<_BubblePin> createState() => _BubblePinState();
}

class _BubblePinState extends State<_BubblePin>
    with SingleTickerProviderStateMixin {
  static const _pinSize = 30.0;

  /// Sürüklerken parmağın balonu "kaldırdığı" hissi.
  bool _lifted = false;

  /// ACİL balonun yanıp sönmesi. Denetleyici YALNIZ gerektiğinde koşar:
  /// sayfadaki her balon için sürekli dönen bir animasyon, kare kare yeniden
  /// boyama demek olurdu (kasma).
  AnimationController? _blink;

  @override
  void initState() {
    super.initState();
    _syncBlink();
  }

  @override
  void didUpdateWidget(_BubblePin old) {
    super.didUpdateWidget(old);
    _syncBlink();
  }

  @override
  void dispose() {
    _blink?.dispose();
    super.dispose();
  }

  void _syncBlink() {
    final wanted = widget.bubble.urgent;
    if (wanted && _blink == null) {
      _blink =
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
          )..repeat(reverse: true);
    } else if (!wanted && _blink != null) {
      _blink!.dispose();
      _blink = null;
    }
  }

  void _dragStart() {
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
    final hasTitle = bubble.title.trim().isNotEmpty;
    final child = hasTitle ? _titleChip(color) : _dot(color);
    final point = Offset(
      bubble.x * widget.pageSize.width,
      bubble.y * widget.pageSize.height,
    );
    // Etiket genişliği bilinmiyor; sol kenarı noktadan 20 px sola alıp sayfaya
    // kıstırmak yeterli — etiket kısa (en çok 12 karakter).
    final at = hasTitle
        ? Offset(
            (point.dx - 20).clamp(
              0.0,
              (widget.pageSize.width - 40).clamp(0.0, double.infinity),
            ),
            point.dy - _pinSize / 2,
          )
        : point - const Offset(_pinSize / 2, _pinSize / 2);
    final blink = _blink;
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: AnimatedScale(
        scale: _lifted ? 1.25 : 1,
        duration: const Duration(milliseconds: 120),
        child: BubbleDragArea(
          enabled: !widget.readOnly,
          onTap: () => widget.controller.openOnly(bubble.id),
          onDragStart: _dragStart,
          onDragDelta: _dragMove,
          onDragEnd: _dragEnd,
          child: Tooltip(
            message: bubble.text.trim().isEmpty ? bubble.title : bubble.text,
            child: blink == null
                ? child
                : FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0.35).animate(blink),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }

  /// Açık balonun tutamacı beyaz halkayla işaretlenir: üstteki karttaki notun
  /// sayfada NEREYE ait olduğu görünsün.
  BoxBorder get _border => Border.all(
    color: widget.bubble.collapsed ? Colors.white : Colors.black87,
    width: widget.bubble.collapsed ? 2 : 2.5,
  );

  Widget _dot(Color color) => Container(
    width: _pinSize,
    height: _pinSize,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: _border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _lifted ? 0.45 : 0.25),
          blurRadius: _lifted ? 10 : 4,
        ),
      ],
    ),
    child: Icon(
      widget.bubble.urgent
          ? Icons.priority_high
          : (widget.bubble.starred
                ? Icons.star
                : (widget.bubble.text.trim().isEmpty
                      ? Icons.format_color_text
                      : Icons.chat_bubble_outline)),
      size: 15,
      color: Colors.black87,
    ),
  );

  Widget _titleChip(Color color) {
    final bubble = widget.bubble;
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: _border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _lifted ? 0.45 : 0.25),
            blurRadius: _lifted ? 10 : 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bubble.urgent)
            const Icon(Icons.priority_high, size: 13, color: Colors.black87),
          if (bubble.starred)
            const Icon(Icons.star, size: 13, color: Colors.black87),
          Flexible(
            child: Text(
              bubble.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Açık balonun İÇERİĞİ — görüntüleyicinin ÜST kenarına demirlenmiş kart.
///
/// Neden sayfada değil (kullanıcı isteği 2026-08-08, kendi önerisi): balon
/// sayfa koordinatındayken klavye açılınca görünür alan yarıya iniyor ve
/// sayfanın alt yarısındaki kart klavyenin ALTINDA kalıyordu. Belgeyi
/// kaydırarak telafi etmek okunan yeri kaçırıyor. Sayfada yalnız tutamaç ve
/// vurgu kalıyor, içerik hep en üstte — klavye ne kadar yer alırsa alsın kart
/// görünür. (PDF yorum araçlarının da yolu budur.)
///
/// Başlık alanı şeridin İÇİNDE ve GENİŞ: eski kompakt şeritte beş simgeyle
/// yan yanaydı ve dar sayfada birkaç piksele iniyordu ("başlık kısmı hiç
/// görülmüyor"). Şimdi şeritte yalnız kapat + taşma menüsü var; yıldız,
/// ünlem, renk ve silme menüde.
class BubbleDock extends StatefulWidget {
  const BubbleDock({super.key, required this.controller, this.readOnly = false});

  final BubbleController controller;
  final bool readOnly;

  @override
  State<BubbleDock> createState() => _BubbleDockState();
}

class _BubbleDockState extends State<BubbleDock> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _titleFocus = FocusNode();
  final _textFocus = FocusNode();

  /// Alanları hangi balon için doldurduk? Balon değişince (başka bir
  /// tutamaca dokunuldu) alanlar yeniden yüklenir.
  String? _loadedId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    for (final focus in [_titleFocus, _textFocus]) {
      focus.addListener(() {
        final editing = _titleFocus.hasFocus || _textFocus.hasFocus;
        if (!editing) widget.controller.save();
        widget.controller.setEditing(editing);
      });
    }
    _sync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _title.dispose();
    _text.dispose();
    _titleFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _sync() {
    final open = widget.controller.openBubble;
    if (open == null) {
      if (_loadedId != null) {
        _loadedId = null;
        _titleFocus.unfocus();
        _textFocus.unfocus();
      }
      return;
    }
    if (open.id == _loadedId) return;
    _loadedId = open.id;
    _title.text = open.title;
    _text.text = open.text;
    // Yeni bırakılan balonda klavye hazır gelsin; var olana dokunulduğunda
    // gelmesin (kullanıcı önce okumak isteyebilir).
    if (widget.controller.justAdded == open.id && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textFocus.requestFocus();
      });
    }
  }

  void _close() {
    final open = widget.controller.openBubble;
    _titleFocus.unfocus();
    _textFocus.unfocus();
    if (open != null) widget.controller.setCollapsed(open.id, true);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final bubble = widget.controller.openBubble;
      if (bubble == null) return const SizedBox.shrink();
      final color = Color(bubble.color);
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Material(
          color: color.withValues(alpha: 0.97),
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 2, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Expanded(
                        child: widget.readOnly
                            ? Text(
                                bubble.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle,
                              )
                            : TextField(
                                controller: _title,
                                focusNode: _titleFocus,
                                maxLines: 1,
                                maxLength: PageBubble.maxTitle,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: _titleStyle,
                                cursorColor: scheme.onSurface,
                                decoration: InputDecoration(
                                  isDense: true,
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: context.l10n.bubbleTitleHint,
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black26,
                                  ),
                                ),
                                onChanged: (value) => widget.controller
                                    .updateTitle(bubble.id, value),
                              ),
                      ),
                      if (bubble.urgent)
                        const Icon(
                          Icons.priority_high,
                          size: 16,
                          color: Colors.black54,
                        ),
                      if (bubble.starred)
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.black54,
                        ),
                      IconButton(
                        tooltip: context.l10n.bubbleCollapse,
                        onPressed: _close,
                        icon: const Icon(
                          Icons.close_fullscreen,
                          size: 17,
                          color: Colors.black54,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                      ),
                      if (!widget.readOnly) _menu(context, bubble),
                    ],
                  ),
                ),
                if (widget.readOnly)
                  Text(bubble.text, style: _bodyStyle)
                else
                  TextField(
                    controller: _text,
                    focusNode: _textFocus,
                    maxLines: 6,
                    minLines: 1,
                    style: _bodyStyle,
                    cursorColor: scheme.onSurface,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 2),
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
      );
    },
  );

  static const _titleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );
  static const _bodyStyle = TextStyle(fontSize: 13, color: Colors.black87);

  /// Yıldız, ünlem, renk ve silme TAŞMA MENÜSÜNDE: şeritte yan yana
  /// dizildiklerinde başlık alanına yer kalmıyordu.
  Widget _menu(BuildContext context, PageBubble bubble) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: '',
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.black54),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      onSelected: (value) async {
        switch (value) {
          case 'star':
            widget.controller.toggleStar(bubble.id);
          case 'urgent':
            widget.controller.toggleUrgent(bubble.id);
          case 'color':
            final picked = await showBubbleColorSheet(context, bubble.color);
            if (picked == null) return;
            widget.controller
              ..update(bubble.copyWith(color: picked))
              ..save();
          case 'delete':
            _titleFocus.unfocus();
            _textFocus.unfocus();
            widget.controller.remove(bubble.id);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'star',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(bubble.starred ? Icons.star : Icons.star_border),
            title: Text(l10n.bubbleStar),
          ),
        ),
        PopupMenuItem(
          value: 'urgent',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.priority_high),
            title: Text(l10n.bubbleUrgent),
          ),
        ),
        PopupMenuItem(
          value: 'color',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.color),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.delete),
          ),
        ),
      ],
    );
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
