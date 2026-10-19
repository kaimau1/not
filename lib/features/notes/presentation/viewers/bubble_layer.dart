import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show LongPressGestureRecognizer, PointerDeviceKind, TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/frame_loop.dart';
import '../../domain/arrow.dart';
import '../../domain/attachment.dart';

part 'bubble_pin.dart';
part 'bubble_dock.dart';
part 'bubble_reveal.dart';

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
  BubbleController({
    required List<PageBubble> initial,
    required this.onChanged,
    bool hidden = false,
    this.onHiddenChanged,
  }) : _bubbles = [...initial],
       hiddenListenable = ValueNotifier<bool>(hidden);

  /// **BALONLAR GİZLİ Mİ** (kullanıcı isteği 2026-10-16: "balonları
  /// göster/gizle olsun"). Gizliyken sayfada ne tutamaç ne vurgu çizilir;
  /// balonlar silinmez (toplu liste, paylaşım, senkron aynen). Balon
  /// bırakmaya geçmek, listeden bir balona gitmek ya da basılı tutup yeni
  /// balon bırakmak balonları kendiliğinden GÖSTERİR — gizli bir şeyin
  /// üstüne çalışılmaz. Değer ekte saklanır ([Attachment.bubblesHidden]).
  final ValueNotifier<bool> hiddenListenable;
  bool get hidden => hiddenListenable.value;

  /// Kullanıcı gizle/göster deyince (kaydetmek için).
  ValueChanged<bool>? onHiddenChanged;

  void setHidden(bool value) {
    if (hidden == value) return;
    hiddenListenable.value = value;
    if (value) {
      // Açık kart/yazma kartı da gider. Bellekte kapatılır, AYRICA
      // kaydedilmez: aynı karede iki ayrı ek yazımı birbirini ezerdi.
      final next = <PageBubble>[];
      for (final b in _bubbles) {
        next.add(b.collapsed ? b : b.copyWith(collapsed: true));
        if (!b.collapsed) _dirty = true;
      }
      _bubbles = next;
      justAdded = null;
      editMode = false;
      adding = false;
    }
    notifyListeners();
    onHiddenChanged?.call(value);
  }

  /// Dışarıdan gelen değeri benimser (tam ekrandan dönüş) — kaydetmez.
  void syncHidden(bool value) {
    if (hidden == value) return;
    hiddenListenable.value = value;
    notifyListeners();
  }

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
  bool get adding => addingListenable.value;
  set adding(bool value) => addingListenable.value = value;

  /// [adding]'in dinlenebilir hâli. Sayfa katmanının SEÇİM/ÇİZİM kısmı
  /// yalnız buna bakar (bkz. `pdfLayerParams`): eskiden balon denetleyicisinin
  /// HER bildirimi (balon açıldı, renk değişti, odak) görünen bütün sayfaların
  /// metin seçim ve kalem katmanlarını da yeniden kuruyordu.
  final addingListenable = ValueNotifier<bool>(false);

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

  /// **Açık metin alanının** renkleri — balon renginden AYRI ve başı SİYAH.
  ///
  /// Kullanıcı isteği 2026-08-18: "açık metin balonunun varsayılanı siyah
  /// olmalı". Balon rengi bir TUTAMACIN rengidir (sarı not, mavi soru); açık
  /// metin ise sayfanın üstüne YAZI yazmaktır ve yazının varsayılanı her
  /// yerde siyahtır. Amber bir yazı beyaz kâğıtta zaten okunmuyordu.
  static const plainPalette = <int>[
    0xFF000000, // siyah (varsayılan)
    0xFFFFFFFF, // beyaz (koyu sayfa/fotoğraf için)
    0xFFD32F2F, // kırmızı
    0xFF1976D2, // mavi
    0xFF388E3C, // yeşil
    0xFFF57C00, // turuncu
    0xFF7B1FA2, // mor
    0xFF00838F, // petrol
  ];

  /// Açık metin alanının DOLGU (yazı zemini) seçenekleri; 0 = dolgu yok.
  ///
  /// Yarı saydam siyah/beyaz en başta: fotoğrafın üstüne yazı yazarken en çok
  /// istenen şey, altındakini tümüyle örtmeden yazıyı okunur kılmak. Ardından
  /// düz renkler geliyor (etiket, uyarı).
  static const fillPalette = <int>[
    0, // dolgu yok
    0x99000000, // yarı saydam siyah
    0x99FFFFFF, // yarı saydam beyaz
    0xFFFFFFFF, // beyaz
    0xFF000000, // siyah
    0xFFFFF59D, // sarı fosforlu
    0xFFC8E6C9, // yeşil
    0xFFBBDEFB, // mavi
    0xFFFFCDD2, // kırmızı
  ];

  /// Yeni bırakılacak AÇIK METİN alanının rengi (varsayılan siyah).
  int plainColor = plainPalette.first;

  void setPlainColor(int value) {
    plainColor = value;
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

  /// Ekranda KURULU sayfa katmanlarının bağlamları (sayfa → bağlam). Açılan
  /// balonun ekrandaki gerçek yeri buradan ölçülür (bkz. [BubbleReveal]):
  /// yakınlaştırma, kaydırma ve klavye ne yapmış olursa olsun.
  final Map<int, BuildContext> _pageContexts = {};

  void _attachPage(int page, BuildContext context) =>
      _pageContexts[page] = context;

  void _detachPage(int page, BuildContext context) {
    if (identical(_pageContexts[page], context)) _pageContexts.remove(page);
  }

  /// Balonun işaret ettiği noktanın EKRAN konumu; sayfası kurulu değilse
  /// (ekran dışında, liste onu henüz kurmamış) null.
  Offset? globalPointOf(PageBubble bubble) {
    final context = _pageContexts[bubble.page];
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(
      Offset(bubble.x * box.size.width, bubble.y * box.size.height),
    );
  }

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
    // Gizli balonların üstüne yenisi bırakılmaz: önce görünürler.
    if (value && hidden) setHidden(false);
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
    draggingListenable.value = id != null;
    if (was != (id != null)) onDragChanged?.call(id != null);
    notifyListeners();
  }

  /// Bir balon taşınıyor mu — [dragging]'in dinlenebilir hâli. Slayt
  /// listesi kaydırmayı yalnız buna bakarak kilitler; eskiden bütün liste
  /// (görünen her slaydın çizimiyle) denetleyicinin HER bildiriminde yeniden
  /// kuruluyordu.
  final draggingListenable = ValueNotifier<bool>(false);

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
          a[i].plain != b[i].plain ||
          a[i].size != b[i].size ||
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

  /// Yeni bırakılacak balon AÇIK METİN ALANI mı olsun (Paint'teki metin
  /// aracı gibi — bkz. [PageBubble.plain])? Araç çubuğundan seçilir ve
  /// seçim yeni balonlara taşınır; var olan balonlar etkilenmez.
  bool plainMode = false;

  void setPlainMode(bool value) {
    if (plainMode == value) return;
    plainMode = value;
    notifyListeners();
  }

  /// Sayfanın boş bir noktasına serbest balon bırakır.
  void add(int page, double x, double y) => _insert(
    PageBubble(
      id: _uuid.v4(),
      page: page,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      // Açık metin alanı kendi paletinden doğar (varsayılan siyah).
      color: plainMode ? plainColor : color,
      plain: plainMode,
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
    if (hidden) setHidden(false);
    // Yeni balon AÇIK doğar; açık kalmış eskiler kapanır — yoksa "açık
    // balon" ilk açık olan sayılır ve yazma kartı yanlış balona açılırdı
    // (basılı tutup balon bırakırken bir okuma kartı açık olabilir).
    _bubbles = [
      for (final b in _bubbles)
        if (focus && !b.collapsed) b.copyWith(collapsed: true) else b,
      bubble,
    ];
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

  /// Balonun BOYUTUNU bir adım değiştirir ([PageBubble.sizeSteps]):
  /// tutamaçta tutamacın kendisi, açık metinde yazının puntosu büyür.
  void stepSize(String id, int direction) {
    final bubble = byId(id);
    if (bubble == null) return;
    final next = PageBubble.stepSize(
      bubble.size,
      direction,
      plain: bubble.plain,
    );
    if (next == bubble.size) return;
    update(bubble.copyWith(size: next));
    save();
  }

  @override
  void dispose() {
    revision.dispose();
    dockHeight.dispose();
    dragDelta.dispose();
    addingListenable.dispose();
    draggingListenable.dispose();
    hiddenListenable.dispose();
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
    if (hidden) setHidden(false);
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
///
/// **Yalnız KENDİ sayfası değişince yeniden kurulur** (kullanıcı bulgusu
/// 2026-10-15: "balonlu mod kasıyor, performansı yenilenmeli"). Eskiden
/// katman denetleyicinin her bildirimini dinliyordu: başka sayfada bir balon
/// açılınca, renk seçilince, taşıma başlayıp bitince GÖRÜNEN BÜTÜN
/// sayfaların balonları, vurgu boyaları ve dokunma alanları baştan
/// kuruluyordu. Şimdi her bildirimde sayfanın küçük bir özeti ([_PageView])
/// çıkarılır ve yalnız o özet değiştiyse sayfa tazelenir.
class BubblePageLayer extends StatefulWidget {
  const BubblePageLayer({
    super.key,
    required this.controller,
    required this.page,
    this.readOnly = false,
    this.longPressAdd = true,
  });

  final BubbleController controller;
  final int page;

  /// Salt görüntüleme: balonlar görünür ve açılıp kapanır ama düzenlenmez.
  final bool readOnly;

  /// **BASILI TUTUNCA BALON** (kullanıcı isteği 2026-10-16: "basılı tutarak
  /// balon ekleme olsun; şu an metin tanıma yapıyor"). Sayfanın boş ya da
  /// yazılı herhangi bir yerine parmağı ~0,45 sn kıpırdatmadan tutmak oraya
  /// balon bırakır ve yazma kartını açar — "Balon" kipine geçmeden. Kalem
  /// kipinde kapalı (o parmak çizer). Metin seçimi PDF'te ÇİFT DOKUNUŞA
  /// geçti (bkz. `PdfSelectLayer.longPressSelects`).
  final bool longPressAdd;

  @override
  State<BubblePageLayer> createState() => _BubblePageLayerState();
}

/// Bir sayfanın balon katmanının bağlı olduğu her şey.
///
/// Balonlar KİMLİKLE karşılaştırılır: denetleyici değişmeyen balonun
/// nesnesini yeni listeye olduğu gibi taşır, yalnız değişeni yeniden kurar.
@immutable
class _PageView {
  const _PageView({
    required this.bubbles,
    required this.anyOpen,
    required this.open,
    required this.editMode,
    required this.adding,
    required this.dragging,
    required this.hidden,
  });

  factory _PageView.of(BubbleController c, int page) {
    final open = c.openBubble;
    final dragging = c.dragging;
    final bubbles = c.forPage(page);
    return _PageView(
      bubbles: bubbles,
      anyOpen: open != null,
      open: open != null && open.page == page ? open : null,
      editMode: c.editMode,
      adding: c.adding,
      dragging: dragging != null && bubbles.any((b) => b.id == dragging)
          ? dragging
          : null,
      hidden: c.hidden,
    );
  }

  final List<PageBubble> bubbles;
  final bool anyOpen;
  final PageBubble? open;
  final bool editMode;
  final bool adding;
  final String? dragging;
  final bool hidden;

  bool sameAs(_PageView other) {
    if (anyOpen != other.anyOpen ||
        hidden != other.hidden ||
        !identical(open, other.open) ||
        adding != other.adding ||
        dragging != other.dragging ||
        // Düzenleme kipi yalnız açık balon BU sayfadaysa bir şey değiştirir
        // (okuma kartı ↔ yazma kartı).
        (open != null && editMode != other.editMode) ||
        bubbles.length != other.bubbles.length) {
      return false;
    }
    for (var i = 0; i < bubbles.length; i++) {
      if (!identical(bubbles[i], other.bubbles[i])) return false;
    }
    return true;
  }
}

class _BubblePageLayerState extends State<BubblePageLayer> {
  late _PageView _view = _PageView.of(widget.controller, widget.page);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller._attachPage(widget.page, context);
    BubbleLook.scale.addListener(_onScale);
  }

  /// Genel balon boyu değişti (araç kartındaki −/+): tutamaçlar yeniden
  /// ölçülür. Seyrek bir olay — sayfanın tamamı tazelenir.
  void _onScale() {
    if (mounted) setState(() {});
  }

  /// Basılı tutulan noktaya balon bırakır (bkz. [BubblePageLayer.longPressAdd]).
  void _dropAt(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    HapticFeedback.mediumImpact();
    widget.controller.add(
      widget.page,
      local.dx / size.width,
      local.dy / size.height,
    );
  }

  @override
  void didUpdateWidget(BubblePageLayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    if (!identical(old.controller, widget.controller) ||
        old.page != widget.page) {
      old.controller._detachPage(old.page, context);
      widget.controller._attachPage(widget.page, context);
    }
    _view = _PageView.of(widget.controller, widget.page);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.controller._detachPage(widget.page, context);
    BubbleLook.scale.removeListener(_onScale);
    super.dispose();
  }

  void _onChanged() {
    final next = _PageView.of(widget.controller, widget.page);
    if (next.sameAs(_view)) return;
    setState(() => _view = next);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final view = _view;
    final page = widget.page;
    final readOnly = widget.readOnly;
    final scale = BubbleLook.scale.value;
    final drop = widget.longPressAdd && !readOnly && !view.adding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // GİZLİ: yalnız "basılı tut → balon" dinleyicisi kalır (bırakılan
        // balon gizliliği kaldırır).
        if (view.hidden && !view.adding) {
          return drop
              ? _LongPressDrop(onDrop: (at) => _dropAt(at, size))
              : const SizedBox.shrink();
        }
        final bubbles = view.bubbles;
        final open = view.open;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Basılı tut → balon: EN ALTTA ve arenaya girmeyen bir dinleyici
            // (tutamaçlar ve vurgular dokunuşu önce alır; sayfa kaydırma,
            // yakınlaştırma ve metin seçimi bozulmaz).
            if (drop)
              Positioned.fill(
                child: _LongPressDrop(onDrop: (at) => _dropAt(at, size)),
              ),
            // Vurgu boyası EN ALTTA ve dokunuşa kapalı: rengi metnin üstüne
            // serer, parmağı almaz (dokunuşu aşağıdaki görünmez alan alır).
            // `RepaintBoundary`: sayfa kaydırılırken ya da bir tutamaç
            // kıpırdadığında bu boya yeniden ÇİZİLMESİN.
            if (bubbles.any((b) => b.isHighlight))
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
            if (bubbles.any((b) => b.isHighlight && b.arrow))
              IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<Offset>(
                    valueListenable: controller.dragDelta,
                    builder: (context, drag, _) => CustomPaint(
                      size: size,
                      painter: _LeaderPainter(
                        bubbles: bubbles,
                        draggingId: view.dragging,
                        drag: view.dragging == null ? Offset.zero : drag,
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
            if (view.adding && !readOnly)
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
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.06),
                  ),
                ),
              ),
            // Açık balon varken sayfanın boşluğuna dokunmak onu KAPATIR
            // (kullanıcı isteği: "balonu kapatmak için sayfanın bir yerine
            // tıklamak yeterli olmalı"). Yalnız TAP dinlenir — kaydırma ve
            // yakınlaştırma jestleri alta geçmeye devam eder.
            if (view.anyOpen && !view.adding)
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
                scale: scale,
              ),
            // OKUMA balonu: yazılmış bir nota dokunulunca not YERİNDE, klavye
            // açılmadan görünür. Yazmak için "Düzenle" denir — o zaman içerik
            // klavyenin üstündeki karta geçer (bkz. BubbleController.editMode).
            if (open != null && !view.editMode)
              _BubbleReadCard(
                controller: controller,
                bubble: open,
                pageSize: size,
                readOnly: readOnly,
                scale: scale,
              ),
          ],
        );
      },
    );
  }
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
