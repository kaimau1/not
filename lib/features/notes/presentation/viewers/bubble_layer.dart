import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show LongPressGestureRecognizer, TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/arrow.dart';
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

  /// Açık balon DÜZENLENİYOR mu?
  ///
  /// İki ayrı durum var (kullanıcı isteği 2026-08-08): yazılmış bir balonun
  /// tutamacına dokunulunca **yalnız notu okunur** — sayfanın üzerinde, yerinde
  /// duran küçük bir balonda, klavye açılmadan. Yazmak için "Düzenle" denir;
  /// ancak o zaman klavye açılır ve içerik klavyenin üstündeki karta
  /// ([BubbleDock]) taşınır. Yeni bırakılan boş balon doğrudan düzenlemede
  /// doğar — orada okunacak bir şey yok.
  bool editMode = false;

  /// Yazarken CANLI tazeleme sayacı. Yalnız AÇIK balonun tutamacı dinler:
  /// başlık yazılırken sayfadaki etiket harf harf güncellensin ("başlık kısmı
  /// canlı olarak ekranda değişsin") ama sayfanın bütün balon katmanı her tuş
  /// vuruşunda yeniden kurulmasın (kasmanın kök nedeni buydu).
  final revision = ValueNotifier<int>(0);

  /// Klavyenin üstündeki kartın yüksekliği — belgeyi kaydırıp açık balonu
  /// kartın ÜSTÜNDE ortalayan görüntüleyiciler bunu kullanır.
  final dockHeight = ValueNotifier<double>(0);

  /// ŞU AN taşınan balonun jest başından beri biriken kayması (piksel).
  ///
  /// Balonu vurguladığı metne bağlayan ok bunu dinler: taşırken ok parmakla
  /// birlikte uzar/kısalır ve yönelir. Ayrı bir `ValueNotifier` olması şart —
  /// denetleyiciyi her karede uyandırmak sayfanın bütün balon katmanını
  /// yeniden kurardı (kasmanın kök nedeni, bkz. `_BubblePinState._drag`).
  final dragDelta = ValueNotifier<Offset>(Offset.zero);

  /// Bir balon açıldığında (ya da düzenlemeye geçildiğinde) çağrılır:
  /// görüntüleyici belgeyi kaydırıp balonu görünür alanın ortasına alır.
  ValueChanged<PageBubble>? onOpened;

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

  /// Okuma balonundan DÜZENLEMEYE geçer ("Düzenle" düğmesi).
  void beginEdit() {
    final open = openBubble;
    if (open == null || editMode) return;
    editMode = true;
    justAdded = open.id;
    notifyListeners();
    onOpened?.call(open);
  }

  void _insert(PageBubble bubble, {bool focus = true}) {
    _bubbles = [..._bubbles, bubble];
    justAdded = focus ? bubble.id : null;
    // Yeni balonda okunacak bir şey yok: doğrudan yazmaya açılır.
    editMode = focus;
    if (focus) onOpened?.call(bubble);
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
    _bubbles = [..._bubbles]
      ..[index] = _bubbles[index].copyWith(title: clipped);
    _dirty = true;
    revision.value++;
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
    revision.value++;
  }

  @override
  void dispose() {
    revision.dispose();
    dockHeight.dispose();
    dragDelta.dispose();
    super.dispose();
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
    if (value) editMode = false;
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

  /// Balonu vurguladığı metne bağlayan OKU açar/kapatır (kullanıcı isteği
  /// 2026-08-09: "ok işaretini kaldırma seçeneği olmalı").
  void toggleArrow(String id) {
    final bubble = byId(id);
    if (bubble == null) return;
    update(bubble.copyWith(arrow: !bubble.arrow));
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
    editMode = false;
    _dirty = true;
    notifyListeners();
    save();
    return true;
  }

  /// Bir balonu tek başına açar, diğerlerini kapatır (toplu listeden "balona
  /// git" ve vurguya dokunma bu yoldan geçer — iki kart yan yana açık kalmaz).
  ///
  /// Yazılmış balon OKUMA kipinde açılır: klavye gelmez, not yerinde görünür.
  /// Henüz boş olanda okunacak bir şey yok, doğrudan yazmaya açılır.
  void openOnly(String id, {bool edit = false}) {
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
    final target = byId(id);
    editMode = edit || (target != null && target.text.trim().isEmpty);
    if (changed) {
      _dirty = true;
      save();
    }
    notifyListeners();
    if (target != null) onOpened?.call(target);
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
        final open = controller.openBubble;
        final anyOpen = open != null;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Vurgu boyası EN ALTTA ve dokunuşa kapalı: rengi metnin üstüne
            // serer, parmağı almaz (dokunuşu aşağıdaki görünmez alan alır).
            // `RepaintBoundary`: sayfa kaydırılırken ya da bir tutamaç
            // kıpırdadığında bu boya yeniden ÇİZİLMESİN.
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _HighlightPainter(bubbles: bubbles),
                ),
              ),
            ),
            // Balonu vurguladığı metne bağlayan OK. Balon sürüklendikçe ok
            // uzar/kısalır ve yönünü değiştirir (kullanıcı isteği 2026-08-08):
            // yalnız bu katman tazelenir, sürükleme kare başına tam bir
            // yeniden kurulum yapmaz.
            IgnorePointer(
              child: RepaintBoundary(
                child: ValueListenableBuilder<Offset>(
                  valueListenable: controller.dragDelta,
                  builder: (context, drag, _) => CustomPaint(
                    size: size,
                    painter: _LeaderPainter(
                      bubbles: bubbles,
                      draggingId: controller.dragging,
                      drag: drag,
                    ),
                  ),
                ),
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
            // OKUMA balonu: yazılmış bir nota dokunulunca not YERİNDE, klavye
            // açılmadan görünür. Yazmak için "Düzenle" denir — o zaman içerik
            // klavyenin üstündeki karta geçer (bkz. BubbleController.editMode).
            if (open != null && open.page == page && !controller.editMode)
              _BubbleReadCard(
                controller: controller,
                bubble: open,
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
///
/// **Görünüm yeniden yazıldı** (kullanıcı bulgusu 2026-08-08: "fosforlu kalem
/// görüntüsü çok çok kötü, ortası kalın kenarlar sönük, yazıyı okunmaz hâle
/// getiriyor"). Eskiden iki katman vardı: satırın tamamını kaplayan soluk bir
/// zemin + ortasından geçen KOYU kalın bir bant. İki katman üst üste binince
/// satırın ortası (yani harflerin gövdesi) en koyu yer oluyordu — tam da
/// okunması gereken kısım. Şimdi TEK ve DÜZGÜN bir dolgu var: satır boyunca
/// aynı yoğunlukta, hafif yuvarlatılmış ve harflerin okunmasına izin verecek
/// kadar saydam. Metnin üstü işaretli görünür ama metin hep okunur.
class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.bubbles});

  final List<PageBubble> bubbles;

  /// Vurgunun yoğunluğu. 0.28 gözle görünür ama altındaki 12 punto metni
  /// kapatmıyor; 0.42'lik eski bant koyu renklerde yazıyı yutuyordu.
  static const _alpha = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      if (bubble.rects.isEmpty) continue;
      final color = Color(bubble.color);
      final path = Path();
      for (final r in bubble.rects) {
        final rect = Rect.fromLTRB(
          r.left * size.width,
          r.top * size.height,
          r.right * size.width,
          r.bottom * size.height,
        );
        if (rect.width <= 0 || rect.height <= 0) continue;
        // Satırın tamamı: kalem izi gibi hafifçe taşar (üstte/altta 1 px),
        // böylece harflerin çıkıntıları da işaretin içinde kalır.
        path.addRRect(
          RRect.fromRectAndRadius(
            rect.inflate(0.5),
            const Radius.circular(2.5),
          ),
        );
      }
      // TEK yol, TEK boya: `Path` üst üste binen satırları birleştirdiği için
      // kesişimlerde renk koyulaşmaz.
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: _alpha));
    }
  }

  /// **Dokunuşu YUTMAZ.** `painter:` verilmiş bir `CustomPaint`, `hitTest`
  /// geçersiz kılınmazsa (`hitTestSelf` içinde `?? true`) kapladığı alandaki
  /// HER dokunuşu yutar — bu boyayıcı sayfanın tamamını kapladığı için sayfa
  /// kaydırma ve yakınlaştırma ölürdü. Aynı tuzak `PdfSelectLayer`'da da var.
  @override
  bool hitTest(Offset position) => false;

  /// Aynı vurgular için YENİDEN ÇİZMEZ. Eskiden hep `true` idi; sayfa
  /// katmanı her tazelendiğinde (tutamaç kıpırdadı, balon açıldı) bütün vurgu
  /// yolları baştan çiziliyordu — kaydırmadaki takılmanın paylarından biri.
  @override
  bool shouldRepaint(_HighlightPainter old) {
    if (old.bubbles.length != bubbles.length) return true;
    for (var i = 0; i < bubbles.length; i++) {
      final a = old.bubbles[i];
      final b = bubbles[i];
      if (a.color != b.color || a.rects.length != b.rects.length) return true;
      for (var j = 0; j < b.rects.length; j++) {
        if (a.rects[j].left != b.rects[j].left ||
            a.rects[j].top != b.rects[j].top ||
            a.rects[j].right != b.rects[j].right ||
            a.rects[j].bottom != b.rects[j].bottom) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Balonu, vurguladığı METNE bağlayan ince ok.
///
/// Kullanıcı isteği (2026-08-08): "metin seçip balon koyunca ... yazının
/// merkezine bağlı ok işareti olsun, balonun hareketiyle o da otomatik
/// uzasın, kısalsın, yönelsin." Vurgu sayfanın bir yerinde, balon başka bir
/// yerinde durabiliyor; hangi balonun hangi satırı işaret ettiği ancak bu
/// bağla anlaşılıyor.
///
/// Taşınan balonda ok CANLI: [drag] o balonun jest başından beri biriken
/// kaymasıdır (bkz. [BubbleController.dragDelta]) ve yalnız bu katman
/// yeniden çizilir.
class _LeaderPainter extends CustomPainter {
  _LeaderPainter({
    required this.bubbles,
    required this.draggingId,
    required this.drag,
  });

  final List<PageBubble> bubbles;
  final String? draggingId;
  final Offset drag;

  /// Balon zaten metnin üstündeyse ok çizilmez: kısa bir çizgi hem çirkin
  /// hem de yönü okunmaz olurdu.
  static const _minLength = 26.0;

  /// Okun opaklığı — kullanıcı isteği 2026-08-09: "yüzde 65 opaklıkta olmalı".
  static const _alpha = 0.65;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      if (bubble.rects.isEmpty) continue;
      // Balon başına kapatılabilir (bkz. [PageBubble.arrow]).
      if (!bubble.arrow) continue;
      final target = _center(bubble, size);
      if (target == null) continue;
      var tail = Offset(bubble.x * size.width, bubble.y * size.height);
      if (bubble.id == draggingId) tail += drag;
      final delta = target - tail;
      if (delta.distance < _minLength) continue;
      final color = Color(bubble.color);
      // Ok metnin ORTASINA değil, kenarına kadar gider: ucu harflerin üstünü
      // kapatmasın.
      final head = target - delta / delta.distance * 6;
      final geo = arrowGeometry(tail, head, 2);
      // **YAZININ ARKASINA GEÇER** (kullanıcı bulgusu 2026-08-09: "ok işareti
      // PDF veya diğer belgelerde yazının arkasına geçmeli, şu an yazının
      // üzerine gelip kapatıyor").
      //
      // KÖK NEDEN ve neden böyle çözülüyor: belge sayfası RASTERİZE bir
      // görüntüdür (pdfrx sayfayı tek katman olarak çizer) — okun boyasını
      // "harflerin altına" koymanın gerçek bir yolu yok, ayrı bir metin
      // katmanı bulunmuyor. `BlendMode.multiply` aynı sonucu verir: sonuç
      // renk altındaki pikselle ÇARPILDIĞI için koyu harfler okun üzerinden
      // olduğu gibi geçer, ok yalnız açık zeminde görünür. Fosforlu kalemin
      // kâğıt üzerindeki davranışının aynısı.
      final paint = Paint()
        ..color = color.withValues(alpha: _alpha)
        ..blendMode = BlendMode.multiply
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas
        ..drawLine(tail, geo.lineEnd, paint)
        ..drawPath(
          Path()
            ..moveTo(head.dx, head.dy)
            ..lineTo(geo.left.dx, geo.left.dy)
            ..lineTo(geo.right.dx, geo.right.dy)
            ..close(),
          Paint()
            ..color = color.withValues(alpha: _alpha)
            ..blendMode = BlendMode.multiply,
        );
    }
  }

  /// Vurgunun (bütün satırlarının) ortası — okun işaret ettiği nokta.
  Offset? _center(PageBubble bubble, Size size) {
    var left = double.infinity;
    var top = double.infinity;
    var right = -double.infinity;
    var bottom = -double.infinity;
    for (final r in bubble.rects) {
      left = math.min(left, r.left);
      top = math.min(top, r.top);
      right = math.max(right, r.right);
      bottom = math.max(bottom, r.bottom);
    }
    if (left > right || top > bottom) return null;
    return Offset(
      (left + right) / 2 * size.width,
      (top + bottom) / 2 * size.height,
    );
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_LeaderPainter old) =>
      old.drag != drag ||
      old.draggingId != draggingId ||
      old.bubbles.length != bubbles.length ||
      _moved(old.bubbles, bubbles);

  static bool _moved(List<PageBubble> a, List<PageBubble> b) {
    for (var i = 0; i < b.length && i < a.length; i++) {
      if (a[i].x != b[i].x ||
          a[i].y != b[i].y ||
          a[i].color != b[i].color ||
          a[i].arrow != b[i].arrow ||
          a[i].rects.length != b[i].rects.length) {
        return true;
      }
    }
    return false;
  }
}

/// Yazılmış bir balonun SALT OKUNUR hâli — sayfanın üzerinde, tutamacın
/// yanında.
///
/// Kullanıcı isteği (2026-08-08): "not yazıldıktan sonra küçük simgesine
/// tıklandığında sadece not orada balon olarak görülsün, düzenleme için
/// Düzenle butonu olsun." Okumak için klavye açmak (ve içeriği ekranın öbür
/// ucundaki karta taşımak) gereksizdi.
///
/// **Görünüm yenilendi** (kullanıcı bulgusu 2026-08-08, ekran görüntüsüyle:
/// "balonun görüntüsü yenilenmeli"): kart baştan sona balon rengiyle dolu,
/// sayfanın %86'sı genişliğinde ve içinde koca bir "Balonu düzenle" düğmesi
/// taşıyan bir bloktu — altındaki belgeyi tümüyle kapatıyordu. Şimdi yazma
/// kartıyla ([BubbleDock]) AYNI dili konuşuyor: zemin belgenin rengi (yüzey),
/// balonun rengi solda 5 px'lik şerit, başlık ve eylemler tek satırda simge
/// olarak. Dar, kısa ve okunan yeri kapatmıyor.
class _BubbleReadCard extends StatelessWidget {
  const _BubbleReadCard({
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
  Widget build(BuildContext context) {
    // Dar tutulur: kart okunan satırın yanında durmalı, sayfayı örtmemeli.
    final width = math.min(pageSize.width * 0.66, 260.0);
    final anchor = Offset(
      bubble.x * pageSize.width,
      bubble.y * pageSize.height,
    );
    final left = (anchor.dx - width / 2)
        .clamp(0.0, math.max(0.0, pageSize.width - width))
        .toDouble();
    // Sayfanın alt yarısındaki balonun kartı YUKARI açılır: aşağı açılsa
    // sayfanın dışına taşardı.
    final below = anchor.dy < pageSize.height * 0.55;
    final card = _card(context);
    return Positioned(
      left: left,
      width: width,
      top: below ? anchor.dy + 22 : null,
      bottom: below ? null : math.max(0.0, pageSize.height - anchor.dy) + 22,
      child: card,
    );
  }

  Widget _card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(bubble.color);
    final title = bubble.title.trim();
    final text = bubble.text.trim();
    return Material(
      color: scheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        padding: const EdgeInsets.fromLTRB(9, 4, 2, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve eylemler TEK satırda: eskiden düğmeler ayrı bir satır
            // alıyor, kart iki kat uzuyordu.
            SizedBox(
              height: 28,
              child: Row(
                children: [
                  Expanded(
                    child: title.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  if (bubble.urgent)
                    Icon(
                      Icons.priority_high,
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  if (bubble.starred)
                    Icon(Icons.star, size: 15, color: scheme.onSurfaceVariant),
                  // Ok yalnız VURGULU balonda var: serbest balonun bağlanacağı
                  // bir metin yok, düğme de anlamsız olurdu.
                  if (!readOnly && bubble.isHighlight)
                    _action(
                      context,
                      icon: bubble.arrow ? Icons.north_east : Icons.block,
                      tooltip: bubble.arrow
                          ? context.l10n.bubbleArrowHide
                          : context.l10n.bubbleArrowShow,
                      onPressed: () => controller.toggleArrow(bubble.id),
                    ),
                  if (!readOnly)
                    _action(
                      context,
                      icon: Icons.edit_outlined,
                      tooltip: context.l10n.bubbleEdit,
                      onPressed: controller.beginEdit,
                    ),
                  _action(
                    context,
                    icon: Icons.close,
                    tooltip: context.l10n.bubbleCollapse,
                    onPressed: controller.collapseAll,
                  ),
                ],
              ),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  text,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
    icon: Icon(
      icon,
      size: 17,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
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

  /// Taşıma sırasında biriken kayma — YALNIZ burada durur ve tek bir
  /// `Transform.translate`i besler.
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "sürükleme çalışıyor ama
  /// parmağımdan geride kalıyor, yavaş geliyor"): her hareket
  /// `controller.update` çağırıyordu; o da `notifyListeners` ile sayfanın
  /// BÜTÜN balon katmanını — vurgu boyaması, vurgu dokunma alanları, öbür
  /// tutamaçlar — yeniden kuruyordu. Kare başına bir tam yeniden kurulum,
  /// parmağın gerisinde kalmak demek. Artık model taşıma BİTİNCE bir kez
  /// yazılır; hareket sırasında yalnız bu değer değişir ve tek bir widget
  /// tazelenir.
  final _drag = ValueNotifier<Offset>(Offset.zero);

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
    _drag.dispose();
    super.dispose();
  }

  void _syncBlink() {
    final wanted = widget.bubble.urgent;
    if (wanted && _blink == null) {
      _blink = AnimationController(
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
    _drag.value += delta;
    // Vurguya giden ok da parmakla birlikte uzasın/yönelsin: yalnız ok
    // katmanı dinliyor, denetleyici uyandırılmıyor (bkz. dragDelta).
    widget.controller.dragDelta.value = _drag.value;
  }

  void _dragEnd() {
    if (!_lifted) return;
    final moved = _drag.value;
    _drag.value = Offset.zero;
    widget.controller.dragDelta.value = Offset.zero;
    setState(() => _lifted = false);
    final b = widget.bubble;
    widget.controller
      ..update(
        b.copyWith(
          x: (b.x + moved.dx / widget.pageSize.width).clamp(0.0, 1.0),
          y: (b.y + moved.dy / widget.pageSize.height).clamp(0.0, 1.0),
        ),
      )
      ..setDragging(null)
      ..save();
  }

  /// Kapalı balon `widget.bubble`den okunur. AÇIK balon [BubbleController]'dan
  /// canlı okunur: başlık/metin yazılırken denetleyici dinleyicileri
  /// uyandırmaz (kasma), yalnız `revision` sayacını artırır — böylece sayfadaki
  /// etiket harf harf güncellenirken öbür balonlar hiç tazelenmez.
  @override
  Widget build(BuildContext context) => widget.bubble.collapsed
      ? _pin(context, widget.bubble)
      : ValueListenableBuilder<int>(
          valueListenable: widget.controller.revision,
          builder: (context, _, _) => _pin(
            context,
            widget.controller.byId(widget.bubble.id) ?? widget.bubble,
          ),
        );

  Widget _pin(BuildContext context, PageBubble bubble) {
    // Tutamaç YARI SAYDAM: sayfanın üstünde duruyor ve altındaki yazının
    // okunmasını engellememeli (kullanıcı isteği 2026-08-08 — "yarı saydam,
    // yazının arkasında kalan balon"). Taşınırken ve açıkken tam opak olur:
    // o an ilgilenilen balon net görünmeli.
    final opaque = _lifted || !bubble.collapsed;
    final color = Color(bubble.color).withValues(alpha: opaque ? 1 : 0.72);
    final hasTitle = bubble.title.trim().isNotEmpty;
    final child = hasTitle ? _titleChip(bubble, color) : _dot(bubble, color);
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
    // Taşıma sırasında YALNIZ bu dönüşüm tazelenir: `child` bir kez kurulur ve
    // parmak boyunca aynı kalır (bkz. [_drag]).
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _drag,
        builder: (context, offset, child) =>
            Transform.translate(offset: offset, child: child),
        child: AnimatedScale(
          scale: _lifted ? 1.25 : 1,
          duration: const Duration(milliseconds: 120),
          child: BubbleDragArea(
            enabled: !widget.readOnly,
            onTap: () => widget.controller.openOnly(bubble.id),
            onDragStart: _dragStart,
            onDragDelta: _dragMove,
            onDragEnd: _dragEnd,
            // `Tooltip` YOK: kendi uzun basış tanıyıcısını arenaya sokup
            // taşımayla yarışıyordu ("çok zor sürükleniyor"). Notun tamamı
            // zaten dokununca açılan okuma balonunda görünüyor.
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

  /// Açık balonun tutamacı koyu halkayla işaretlenir: düzenlenen notun sayfada
  /// NEREYE ait olduğu görünsün.
  BoxBorder _borderOf(PageBubble bubble) => Border.all(
    color: bubble.collapsed ? Colors.white : Colors.black87,
    width: bubble.collapsed ? 2 : 2.5,
  );

  Widget _dot(PageBubble bubble, Color color) => Container(
    width: _pinSize,
    height: _pinSize,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: _borderOf(bubble),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _lifted ? 0.45 : 0.25),
          blurRadius: _lifted ? 10 : 4,
        ),
      ],
    ),
    child: Icon(
      bubble.urgent
          ? Icons.priority_high
          : (bubble.starred
                ? Icons.star
                : (bubble.text.trim().isEmpty
                      ? Icons.format_color_text
                      : Icons.chat_bubble_outline)),
      size: 15,
      color: Colors.black87,
    ),
  );

  Widget _titleChip(PageBubble bubble, Color color) => Container(
    constraints: const BoxConstraints(maxWidth: 170),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(9),
      border: _borderOf(bubble),
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

/// YAZMA kartı: açık balonun içeriği, KLAVYENİN hemen üstünde.
///
/// Yalnız düzenleme kipinde görünür ([BubbleController.editMode]); okumak için
/// sayfanın üzerindeki balon yeter (bkz. `_BubbleReadCard`).
///
/// Neden sayfada değil (kullanıcı isteği 2026-08-08, kendi önerisi): kart sayfa
/// koordinatındayken klavye açılınca görünür alan yarıya iniyor ve sayfanın alt
/// yarısındaki kart klavyenin ALTINDA kalıyordu. Kart görüntüleyicinin ALT
/// kenarına demirlendi: `Scaffold` klavye kadar daraldığı için kart her zaman
/// klavyenin hemen üstünde, yazının aktığı yerde duruyor — parmağın ve gözün
/// gittiği yer orası ("2.ss'teki alana al"). Üstte durduğu sürümde göz sayfanın
/// bir ucundan öbürüne gidip geliyordu.
///
/// Başlık alanı şeridin İÇİNDE ve GENİŞ: eski kompakt şeritte beş simgeyle
/// yan yanaydı ve dar sayfada birkaç piksele iniyordu ("başlık kısmı hiç
/// görülmüyor"). Şimdi şeritte yalnız kapat + taşma düğmesi var; yıldız,
/// ünlem, renk ve silme kartın İÇİNDE açılan bir satırda.
///
/// **Eylemler neden menü/levha DEĞİL** (kullanıcı bulgusu 2026-08-08:
/// "balondaki yazıyı düzenlerken 3 noktaya basınca klavye kapanıyor,
/// kullanımı bozuyor"): `PopupMenuButton` bir ROTA iter; itilen rota kendi
/// odak kapsamını alır, `TextField` odağı düşer, klavye kapanır ve menü
/// kapanınca geri gelmez — üstelik odak düşünce `editing` false olduğu için
/// gizlenen çubuklar geri gelip ekran zıplıyordu. Renk seçici de aynı sebeple
/// (modal levha) kartın içine alındı. Satır `TextFieldTapRegion` +
/// `ExcludeFocus` içinde: hiçbir düğme odağı istemez, yazı alanı odakta kalır.
class BubbleDock extends StatefulWidget {
  const BubbleDock({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.bottomPadding = 0,
  });

  final BubbleController controller;
  final bool readOnly;

  /// Kartın altına eklenecek sistem payı (tam ekran görüntüleyicide telefon
  /// gezinme çubuğu). Pano bölmesinde 0'dır — orası ekranın dibi değil.
  final double bottomPadding;

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

  /// Eylem satırı (yıldız/acil/renk/sil) açık mı? Kartın İÇİNDE açılır —
  /// menü rotası klavyeyi kapatıyordu (bkz. sınıf açıklaması).
  bool _actions = false;

  /// Renk şeridi açık mı? (Eylem satırındaki palet düğmesi açar.)
  bool _colors = false;

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
    // Başka bir balona geçildi: açık kalan eylem satırı yeni balona ait
    // sanılmasın.
    _actions = false;
    _colors = false;
    // Düzenlemeye açıldıysa klavye hazır gelir. Okuma kipinde bu kart zaten
    // görünmüyor — orada sayfanın üzerindeki balon var.
    if (widget.controller.editMode && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textFocus.requestFocus();
      });
    }
  }

  /// Kartın yüksekliğini denetleyiciye bildirir: görüntüleyici belgeyi
  /// kaydırıp açık balonu kartın ÜSTÜNDE kalan alanın ortasına alıyor
  /// ("tıklanan balon klavye ile ekranın üstü arasında ortalanmalı").
  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _cardKey.currentContext?.size?.height ?? 0;
      if ((widget.controller.dockHeight.value - height).abs() > 1) {
        widget.controller.dockHeight.value = height;
      }
    });
  }

  final _cardKey = GlobalKey();

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
      if (bubble == null || !widget.controller.editMode) {
        if (widget.controller.dockHeight.value != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.controller.dockHeight.value = 0;
          });
        }
        return const SizedBox.shrink();
      }
      _reportHeight();
      final color = Color(bubble.color);
      final scheme = Theme.of(context).colorScheme;
      // Kâğıda iliştirilmiş bir fiş gibi: zemin BELGENİN rengi (beyaz), balonun
      // rengi solda ince bir şerit. Eski sürümde kart baştan sona balon
      // rengiyle doluydu ve sayfanın üstünde koca bir sarı bant gibi
      // duruyordu ("güzel değil, sayfa yapısına uygun bir tasarımda olsun").
      return Padding(
        padding: EdgeInsets.fromLTRB(10, 6, 10, 8 + widget.bottomPadding),
        child: Material(
          key: _cardKey,
          color: scheme.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 5)),
            ),
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
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                onChanged: (value) => widget.controller
                                    .updateTitle(bubble.id, value),
                              ),
                      ),
                      if (bubble.urgent)
                        Icon(
                          Icons.priority_high,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      if (bubble.starred)
                        Icon(
                          Icons.star,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      _barButton(
                        context,
                        icon: Icons.close_fullscreen,
                        tooltip: context.l10n.bubbleCollapse,
                        onPressed: _close,
                      ),
                      if (!widget.readOnly)
                        _barButton(
                          context,
                          icon: Icons.more_vert,
                          tooltip: '',
                          selected: _actions,
                          onPressed: () => setState(() {
                            _actions = !_actions;
                            if (!_actions) _colors = false;
                          }),
                        ),
                    ],
                  ),
                ),
                if (widget.readOnly)
                  Text(bubble.text, style: _bodyStyle)
                else
                  TextField(
                    controller: _text,
                    focusNode: _textFocus,
                    maxLines: 4,
                    minLines: 1,
                    style: _bodyStyle,
                    cursorColor: scheme.onSurface,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 2),
                      border: InputBorder.none,
                      hintText: context.l10n.bubbleHint,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    onChanged: (value) =>
                        widget.controller.updateText(bubble.id, value),
                  ),
                if (_actions && !widget.readOnly) _actionRow(context, bubble),
                if (_actions && _colors && !widget.readOnly)
                  _colorStrip(bubble),
              ],
            ),
          ),
        ),
      );
    },
  );

  static const _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const _bodyStyle = TextStyle(fontSize: 14);

  /// Şerit düğmesi: küçük, odak İSTEMEYEN simge düğmesi.
  ///
  /// `ExcludeFocus` + `TextFieldTapRegion`: dokunuş yazı alanının odağını
  /// düşürmez — klavye açık kalır (bkz. sınıf açıklaması).
  Widget _barButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: IconButton(
          tooltip: tooltip.isEmpty ? null : tooltip,
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          icon: Icon(
            icon,
            size: 17,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Yıldız, acil, renk ve silme — kartın İÇİNDE, klavyeyi kapatmadan.
  Widget _actionRow(BuildContext context, PageBubble bubble) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 2),
      child: Row(
        children: [
          _barButton(
            context,
            icon: bubble.starred ? Icons.star : Icons.star_border,
            tooltip: l10n.bubbleStar,
            selected: bubble.starred,
            onPressed: () => widget.controller.toggleStar(bubble.id),
          ),
          _barButton(
            context,
            icon: Icons.priority_high,
            tooltip: l10n.bubbleUrgent,
            selected: bubble.urgent,
            onPressed: () => widget.controller.toggleUrgent(bubble.id),
          ),
          _barButton(
            context,
            icon: Icons.palette_outlined,
            tooltip: l10n.color,
            selected: _colors,
            onPressed: () => setState(() => _colors = !_colors),
          ),
          const Spacer(),
          TextFieldTapRegion(
            child: ExcludeFocus(
              child: IconButton(
                tooltip: l10n.delete,
                onPressed: () {
                  _titleFocus.unfocus();
                  _textFocus.unfocus();
                  widget.controller.remove(bubble.id);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: Icon(Icons.delete_outline, size: 17, color: scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renk şeridi: modal levha yerine kartın içinde yatay bir sıra (levha da
  /// rota iterek klavyeyi kapatıyordu).
  Widget _colorStrip(PageBubble bubble) => TextFieldTapRegion(
    child: ExcludeFocus(
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          children: [
            for (final argb in BubbleController.palette)
              GestureDetector(
                key: ValueKey('bubble-color-$argb'),
                onTap: () => widget.controller
                  ..update(bubble.copyWith(color: argb))
                  ..save(),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Color(argb),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bubble.color == argb
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black26,
                      width: bubble.color == argb ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

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
