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
    _view = _PageView.of(widget.controller, widget.page);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
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

/// Tutamacın kare boyu (yazısız balon).
const _pinSize = 28.0;

/// Başlıklı tutamacın en geniş hâli — 12 karakterlik başlık sığar.
const _pinChipMaxWidth = 150.0;

/// Tutamacın noktaya göre yerleşimi: [below] gövde noktanın ALTINA mı
/// açılıyor, [left] noktanın SOLUNA mı.
typedef _PinPlace = ({bool below, bool left});

/// Tutamaç bir KONUŞMA BALONUDUR: sivri köşesi balonun noktasında durur,
/// gövdesi o köşeden açılır (kullanıcı isteği 2026-10-15: "balon görüntüsü
/// baştan yenilenmeli"). Eski yuvarlak tutamaç noktanın TAM ÜSTÜNE
/// ortalanıyordu; işaret ettiği kelimeyi kapatıyor, hangi noktayı
/// gösterdiği de belli olmuyordu.
///
/// Serbest balonun gövdesi noktanın ÜSTÜNDE (harita iğnesi gibi); vurgunun
/// gövdesi ise vurgulanan satırın ALTINDA — yoksa işaretlenen yazının
/// üstünü kapatırdı. Sayfanın kenarına yakın tutamaç ters yöne döner.
_PinPlace _pinPlacement(PageBubble bubble, Size page, [double scale = 1]) {
  final x = bubble.x * page.width;
  final y = bubble.y * page.height;
  final title = bubble.title.trim();
  final width =
      (title.isEmpty
          ? _pinSize
          : math.min(_pinChipMaxWidth, 34 + title.characters.length * 7.2)) *
      scale;
  final room = (_pinSize + 8) * scale;
  return (
    below: bubble.isHighlight ? y <= page.height - room : y < room,
    left: x + width > page.width - 2 && x >= width,
  );
}

/// Tutamacın ekrandaki boy çarpanı: genel tercih ([BubbleLook.scale]) ×
/// balonun kendi boyu ([PageBubble.size]). Açık metinde 1 — orada boy
/// yazının puntosudur, tutamaç yok.
double _pinScaleOf(PageBubble bubble, double scale) =>
    bubble.plain ? 1 : (scale * bubble.size).clamp(0.5, 4.0).toDouble();

/// Balon renginin üstünde okunan yazı/simge rengi. Sabit siyah, koyu
/// renklerde (indigo, kahve, mor) okunmuyordu.
Color _inkOn(Color color) =>
    color.computeLuminance() > 0.36 ? Colors.black87 : Colors.white;

/// Yazılmış bir balonun SALT OKUNUR hâli — sayfanın üzerinde, tutamacın
/// yanında.
///
/// Kullanıcı isteği (2026-08-08): "not yazıldıktan sonra küçük simgesine
/// tıklandığında sadece not orada balon olarak görülsün, düzenleme için
/// Düzenle butonu olsun." Okumak için klavye açmak (ve içeriği ekranın öbür
/// ucundaki karta taşımak) gereksizdi.
///
/// **Görünüm yeniden yazıldı (2026-10-15).** Kart artık tutamacın ÜSTÜNE
/// binmez (tutamaç noktanın hangi yanına açıldıysa kart öbür yanında
/// başlar); balonun rengi üstte ince bir şerit, başlık kalın, yazı rahat
/// satır aralığıyla; eylemler altta YAZILI düğmeler — "Düzenle" bir simgenin
/// arkasına saklanmıyor.
class _BubbleReadCard extends StatelessWidget {
  const _BubbleReadCard({
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
    this.scale = 1,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;

  /// Genel balon boyu ([BubbleLook.scale]): kartın genişliği ve yazısı da
  /// onunla büyür (büyük balon tercih eden okumayı da büyük ister).
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Dar tutulur: kart okunan satırın yanında durmalı, sayfayı örtmemeli.
    final width = math.min(pageSize.width * 0.74, 280.0 * scale);
    final pinScale = _pinScaleOf(bubble, scale);
    final anchor = Offset(
      bubble.x * pageSize.width,
      bubble.y * pageSize.height,
    );
    final left = (anchor.dx - 16)
        .clamp(0.0, math.max(0.0, pageSize.width - width))
        .toDouble();
    // Sayfanın alt yarısındaki balonun kartı YUKARI açılır: aşağı açılsa
    // sayfanın dışına taşardı.
    final below = anchor.dy < pageSize.height * 0.55;
    // Tutamaç noktanın hangi yanında duruyor? Kart onun üstüne binmesin.
    final pinBelow =
        !bubble.plain && _pinPlacement(bubble, pageSize, pinScale).below;
    const gap = 6.0;
    final pin = _pinSize * pinScale + gap + 2;
    final card = _card(context);
    return Positioned(
      left: left,
      width: width,
      top: below ? anchor.dy + (pinBelow ? pin : gap) : null,
      bottom: below
          ? null
          : math.max(0.0, pageSize.height - anchor.dy) + (pinBelow ? gap : pin),
      child: scale == 1
          ? card
          : MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1) * scale,
                ),
              ),
              child: card,
            ),
    );
  }

  Widget _card(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = Color(bubble.color);
    final title = bubble.title.trim();
    final text = bubble.text.trim();
    final muted = scheme.onSurfaceVariant;
    return Material(
      color: scheme.surface,
      elevation: 5,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: color),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, title.isEmpty ? 8 : 3, 12, 0),
              child: Text(
                text,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 2, 2),
            child: Row(
              children: [
                if (bubble.urgent)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.priority_high_rounded,
                      size: 16,
                      color: scheme.error,
                    ),
                  ),
                if (bubble.starred)
                  Icon(Icons.star_rounded, size: 17, color: Colors.amber[700]),
                const Spacer(),
                // Ok yalnız VURGULU balonda var: serbest balonun bağlanacağı
                // bir metin yok, düğme de anlamsız olurdu.
                if (!readOnly && bubble.isHighlight)
                  _action(
                    icon: bubble.arrow ? Icons.north_east : Icons.block,
                    tooltip: bubble.arrow
                        ? l10n.bubbleArrowHide
                        : l10n.bubbleArrowShow,
                    color: muted,
                    onPressed: () => controller.toggleArrow(bubble.id),
                  ),
                if (!readOnly)
                  TextButton.icon(
                    key: const ValueKey('bubble-read-edit'),
                    onPressed: controller.beginEdit,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(l10n.bubbleEditShort),
                  ),
                _action(
                  icon: Icons.close,
                  tooltip: l10n.bubbleCollapse,
                  color: muted,
                  onPressed: controller.collapseAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    icon: Icon(icon, size: 17, color: color),
  );
}

/// Balon tutamaçlarının GENEL boy tercihi (cihaz başına, bütün belgelerde).
///
/// Kullanıcı isteği 2026-10-16: "balonların boyutu ayarlanabilir olsun".
/// Telefonda 28 dp'lik tutamaç kimine küçük (bulunmuyor), kimine büyük
/// (yazıyı örtüyor). Tek balonun boyu yazma kartındaki −/+ ile
/// ([PageBubble.size]), hepsininki balon bırakma kartındaki −/+ ile
/// buradan ayarlanır; ikisi çarpılır.
class BubbleLook {
  BubbleLook._();

  static const double min = 0.7;
  static const double max = 2.0;
  static const double step = 0.15;

  static final scale = ValueNotifier<double>(1);

  static SharedPreferences? _prefs;
  static const _key = 'bubble_pin_scale';

  /// Uygulama açılışında (main) bir kez: kayıtlı tercih okunur.
  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    scale.value = (prefs.getDouble(_key) ?? 1).clamp(min, max).toDouble();
  }

  static void setScale(double value) {
    final next = value.clamp(min, max).toDouble();
    if ((next - scale.value).abs() < 0.001) return;
    scale.value = next;
    _prefs?.setDouble(_key, next);
  }
}

/// "Basılı tut → balon bırak" dinleyicisi (bkz. [BubblePageLayer.longPressAdd]).
///
/// **Jest tanıyıcısı DEĞİL, `Listener`**: sayfanın tamamını kaplayan bir uzun
/// basış tanıyıcısı HER dokunuşta arenaya girer ve süresi dolunca kazanıp
/// belgenin kaydırma/yakınlaştırma tanıyıcılarını elerdi (PdfSelectLayer'daki
/// gerekçenin aynısı). Dinleyici arenaya girmez: süre zamanlayıcıyla ölçülür,
/// parmak kayarsa ya da ikinci parmak inerse iptal olur. Fare dinlenmez —
/// masaüstünde basılı tutup sürüklemek metin seçimidir.
class _LongPressDrop extends StatefulWidget {
  const _LongPressDrop({required this.onDrop});

  final ValueChanged<Offset> onDrop;

  static const delay = Duration(milliseconds: 450);
  static const slop = 18.0;

  @override
  State<_LongPressDrop> createState() => _LongPressDropState();
}

class _LongPressDropState extends State<_LongPressDrop> {
  final _pointers = <int>{};
  Timer? _timer;
  int? _pointer;
  Offset _start = Offset.zero;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _pointer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _up(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (e.pointer == _pointer) _cancel();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      if (e.kind == PointerDeviceKind.mouse) return;
      _pointers.add(e.pointer);
      if (_pointers.length > 1) {
        _cancel();
        return;
      }
      _pointer = e.pointer;
      _start = e.localPosition;
      _timer?.cancel();
      _timer = Timer(_LongPressDrop.delay, () {
        final at = _start;
        _cancel();
        if (mounted) widget.onDrop(at);
      });
    },
    onPointerMove: (e) {
      if (e.pointer == _pointer &&
          (e.localPosition - _start).distance > _LongPressDrop.slop) {
        _cancel();
      }
    },
    onPointerUp: _up,
    onPointerCancel: _up,
    child: const SizedBox.expand(),
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
    this.scale = 1,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;

  /// Genel balon boyu ([BubbleLook.scale]).
  final double scale;

  @override
  State<_BubblePin> createState() => _BubblePinState();
}

class _BubblePinState extends State<_BubblePin>
    with SingleTickerProviderStateMixin {
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
    final page = widget.pageSize;
    // BOY (kullanıcı isteği 2026-10-16): tutamaç sivri köşesinin ETRAFINDA
    // ölçeklenir — işaret ettiği nokta yerinde kalır. Ölçek bir dönüşüm:
    // yerleşim ve dokunma alanı (RenderTransform isabeti dönüşümle
    // hesaplar) birlikte büyür, gövdenin ölçüsünü bilmek gerekmez.
    final pinScale = _pinScaleOf(bubble, widget.scale);
    final point = Offset(bubble.x * page.width, bubble.y * page.height);
    // AÇIK METİN ALANI: tutamaç yerine yazının kendisi çizilir.
    // Boyutlanırken model henüz yazılmadı: geçici çarpan burada uygulanır.
    final Widget child;
    double? left;
    double? top;
    double? right;
    double? bottom;
    var origin = Alignment.center;
    if (bubble.plain) {
      final shown = _resizeSize == null
          ? bubble
          : bubble.copyWith(size: _resizeSize);
      child = _plainText(context, shown, Color(bubble.color));
      left = point.dx.clamp(0.0, (page.width - 60).clamp(0.0, double.infinity));
      top = point.dy.clamp(0.0, (page.height - 20).clamp(0.0, double.infinity));
      origin = Alignment.topLeft;
    } else {
      // Sivri köşe NOKTADA: gövde oradan sağa/sola, yukarı/aşağı açılır.
      // Sağ/alt kenardan yerleştirmek gövdenin genişliğini bilmeyi
      // gerektirmez (etiket uzunluğu başlığa göre değişiyor).
      final place = _pinPlacement(bubble, page, pinScale);
      child = _marker(bubble, place, opaque);
      if (place.left) {
        right = page.width - point.dx;
      } else {
        left = point.dx;
      }
      if (place.below) {
        top = point.dy;
      } else {
        bottom = page.height - point.dy;
      }
      origin = Alignment(place.left ? 1 : -1, place.below ? -1 : 1);
    }
    final blink = _blink;
    // Taşıma sırasında YALNIZ bu dönüşüm tazelenir: `child` bir kez kurulur ve
    // parmak boyunca aynı kalır (bkz. [_drag]).
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _drag,
        builder: (context, offset, child) =>
            Transform.translate(offset: offset, child: child),
        child: AnimatedScale(
          scale: (_lifted ? 1.2 : 1) * pinScale,
          alignment: origin,
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

  /// Konuşma balonu biçimli tutamaç (bkz. [_pinPlacement]).
  ///
  /// Gölge BULANIKSIZ (yalnız 1.5 px aşağı kaydırılmış koyu bir kopya):
  /// sayfadaki her tutamaç için bulanıklık maskesi çizmek, çok balonlu
  /// sayfalarda kaydırmanın takılmasının paylarından biriydi. Bulanık gölge
  /// yalnız TAŞINAN tek balonda var — "kaldırdım" hissi için.
  Widget _marker(PageBubble bubble, _PinPlace place, bool opaque) {
    final base = Color(bubble.color);
    final ink = _inkOn(base);
    final title = bubble.title.trim();
    final open = !bubble.collapsed;
    const round = Radius.circular(12);
    const tip = Radius.circular(2.5);
    final radius = BorderRadius.only(
      topLeft: place.below && !place.left ? tip : round,
      topRight: place.below && place.left ? tip : round,
      bottomLeft: !place.below && !place.left ? tip : round,
      bottomRight: !place.below && place.left ? tip : round,
    );
    final empty = bubble.text.trim().isEmpty;
    // Yazısız VURGU: işaret metnin kendisinde, tutamaç küçük ve sessiz.
    final quiet = bubble.isHighlight && empty && title.isEmpty;
    final decoration = BoxDecoration(
      color: base.withValues(alpha: opaque ? 1 : 0.82),
      borderRadius: radius,
      border: Border.all(
        color: open ? Colors.black87 : Colors.white,
        width: open ? 2.2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _lifted ? 0.35 : 0.22),
          offset: Offset(0, _lifted ? 3 : 1.5),
          blurRadius: _lifted ? 6 : 0,
        ),
      ],
    );
    final icon = bubble.urgent
        ? Icons.priority_high_rounded
        : bubble.starred
        ? Icons.star_rounded
        : empty
        ? (bubble.isHighlight ? Icons.format_color_text : Icons.edit_rounded)
        : Icons.notes_rounded;
    if (title.isEmpty) {
      final size = quiet ? 20.0 : _pinSize;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: decoration,
        child: Icon(icon, size: quiet ? 12 : 16, color: ink),
      );
    }
    return Container(
      constraints: const BoxConstraints(
        maxWidth: _pinChipMaxWidth,
        minHeight: 26,
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bubble.urgent || bubble.starred)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(
                bubble.urgent
                    ? Icons.priority_high_rounded
                    : Icons.star_rounded,
                size: 14,
                color: ink,
              ),
            ),
          Flexible(
            child: Text(
              bubble.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Paint tarzı AÇIK METİN: balonun yazısı sayfanın üstünde doğrudan
  /// görünür — kutu yok, tutamaç yok.
  ///
  /// Sayfa fotoğraf da olabildiği için yazı **çift çizilir**: önce koyu bir
  /// dış hat (stroke), üstüne balonun kendi rengi. Tek renkli düz yazı açık
  /// bir zeminde (beyaz kâğıt, parlak gökyüzü) okunmuyordu; dış hat her
  /// zeminde okunur kılar ve gölgenin aksine yazıyı bulanıklaştırmaz.
  ///
  /// Boş metin, üzerine dokunulabilecek bir hedef bırakmak için yer tutucu
  /// gösterir; yoksa yeni bırakılan boş bir metin alanı görünmez olur ve
  /// kullanıcı onu bir daha açamazdı.
  Widget _plainText(BuildContext context, PageBubble bubble, Color color) {
    final text = bubble.text.trim();
    final empty = text.isEmpty;
    final fontSize = bubble.fontSize;
    // **VARSAYILAN YAZI BİÇİMİ** (kullanıcı isteği 2026-08-18: "yazı formatı
    // varsayılan yazı formatı olmalı"): kendi kalınlığını (w600) dayatmak
    // yerine temanın gövde biçimi devralınır — uygulamanın/notun seçili yazı
    // tipi neyse açık metin de onunla yazılır.
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final style = base.copyWith(
      fontSize: fontSize,
      height: 1.2,
      // KALIN/İTALİK (kullanıcı isteği: "metin kutusunu geliştirme"): biçim
      // balonun kendi alanlarından geliyor, varsayılan hâli eski davranışın
      // aynısı (bkz. [PageBubble.bold]).
      fontWeight: bubble.bold ? FontWeight.w700 : FontWeight.normal,
      fontStyle: bubble.italic ? FontStyle.italic : FontStyle.normal,
      color: color,
    );
    final align = switch (bubble.align) {
      1 => TextAlign.center,
      2 => TextAlign.right,
      _ => TextAlign.left,
    };
    // DOLGU: fotoğrafın/taranmış sayfanın karışık zemininde dış hat bile
    // yetmiyordu; dolgu yazının arkasına düz bir zemin koyar.
    final fill = bubble.fill == 0 ? null : Color(bubble.fill);
    // Dış hat yazının ZIDDI: siyah yazının çevresi beyaz, beyaz yazının
    // çevresi siyah. Sabit koyu dış hat, siyah varsayılanla birlikte yazıyı
    // kendi gölgesinde kaybediyordu.
    final outline = color.computeLuminance() < 0.5
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.7);
    final framed = empty || _lifted || _resizing;
    final body = Container(
      constraints: BoxConstraints(maxWidth: math.max(120, fontSize * 16)),
      padding: fill == null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.symmetric(horizontal: fontSize * 0.35, vertical: 4),
      decoration: (framed || fill != null)
          ? BoxDecoration(
              color: fill,
              // Boşken (taşınırken, boyutlanırken) ince bir çerçeve: alanın
              // nerede olduğu ve nereye kadar uzandığı görünsün.
              border: framed
                  ? Border.all(color: color.withValues(alpha: 0.8))
                  : null,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: empty
          ? Text(
              context.l10n.bubblePlainHint,
              textAlign: align,
              style: style.copyWith(
                color: color.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            )
          // Dolgu varken DIŞ HAT çizilmez: zemin zaten okunurluğu sağlıyor,
          // dış hat dolgunun üstünde gereksiz bir kalınlık bırakıyordu.
          : fill != null
          ? Text(text, textAlign: align, style: style)
          : Stack(
              children: [
                Text(
                  text,
                  textAlign: align,
                  style: style.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = math.max(2, fontSize / 6)
                      ..color = outline,
                  ),
                ),
                Text(text, textAlign: align, style: style),
              ],
            ),
    );
    if (widget.readOnly) return body;
    // **BOYUT TUTAMACI (Paint'teki gibi)**: yazının sağ alt köşesinde küçük
    // bir kulp; sürüklendikçe yazı büyür/küçülür. Yalnız AÇIK (seçili) metin
    // alanında çizilir — sayfadaki her yazının yanında sürekli duran bir kulp
    // belgeyi okunmaz hâle getirirdi.
    if (bubble.collapsed && !_resizing) return body;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          right: -9,
          bottom: -9,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Boş `onTap`/`onLongPress` bilerek burada: üstteki
            // [BubbleDragArea] aynı iki jesti dinliyor ve kulba 220 ms basılı
            // tutmak balonu TAŞIMAYA başlatırdı. Arenaya çocuk olarak giren
            // tanıyıcı önce eklendiği için kazanır; kulp yalnız boyutlandırır.
            onTap: () {},
            onLongPress: () {},
            onPanStart: (_) => setState(() => _resizing = true),
            onPanUpdate: (d) => _resizeBy(bubble, d.delta),
            onPanEnd: (_) => _resizeEnd(),
            onPanCancel: _resizeEnd,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: outline, width: 1.5),
              ),
              child: const Icon(
                Icons.open_in_full,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Boyut tutamacı şu an sürükleniyor mu (çerçeve bu sırada görünür kalır).
  bool _resizing = false;

  /// Sürükleme sırasında biriken çarpan; parmak bırakılınca bir kez yazılır.
  ///
  /// Taşımadaki kök nedenin aynısı (bkz. [_drag]): her karede `update` çağırmak
  /// sayfadaki bütün balon katmanını yeniden kurar ve kulp parmağın gerisinde
  /// kalır. Model YALNIZ bitişte yazılır.
  double? _resizeSize;

  void _resizeBy(PageBubble bubble, Offset delta) {
    final current = _resizeSize ?? bubble.size;
    // Çapraz hareketin ikisi de büyütür: sağa VE aşağı çekmek Paint'te
    // kutuyu büyütür. 90 px sürükleme ≈ bir kat büyüme.
    final next = (current + (delta.dx + delta.dy) / 90)
        .clamp(PageBubble.minSize, PageBubble.maxSize)
        .toDouble();
    if (next == current) return;
    setState(() => _resizeSize = next);
  }

  void _resizeEnd() {
    final next = _resizeSize;
    setState(() {
      _resizing = false;
      _resizeSize = null;
    });
    if (next == null) return;
    widget.controller
      ..update(widget.bubble.copyWith(size: next))
      ..save();
  }
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
/// görülmüyor"). Başlığın yanında yalnız YAZILI "Bitti" var; renk, yıldız,
/// ünlem ve silme altta HEP GÖRÜNEN bir araç satırında (2026-10-15'e kadar
/// "⋮" düğmesinin arkasındaydı ve bulunmuyordu).
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

  /// Renk şeridi açık mı? (Araç satırındaki renk dairesi açar.)
  bool _colors = false;

  /// Açık metin alanının DOLGU şeridi açık mı (bkz. [PageBubble.fill]).
  bool _fills = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    for (final focus in [_titleFocus, _textFocus]) {
      focus.addListener(() {
        final focused = _titleFocus.hasFocus || _textFocus.hasFocus;
        if (!focused) widget.controller.save();
      });
    }
    _sync();
  }

  /// Yazma kartı AÇIK mı (balon açık + düzenleme kipi) — bölmeyi sadeleştiren
  /// "yazma kipi" ([BubbleController.setEditing]) buna bağlıdır.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "balona yazarken odak sorunu,
  /// klavye kayması"): kip eskiden yazı alanının ODAĞINA bağlıydı. Odak her
  /// gidip geldiğinde (sayfaya dokunmak, renk şeridi, başlıktan metne geçiş
  /// sırasında bir kare) editörün başlığı, alt çubuğu ve sayfa çubuğu
  /// gizlenip geri geliyor, bütün bölme yeniden yerleşip kayıyordu. Artık kip
  /// kartın görünürlüğüne bağlı: kart açılınca BİR KEZ sadeleşir, "Bitti"
  /// ile BİR KEZ geri gelir; arada odak ne yaparsa yapsın yerleşim sabit.
  bool _dockOpen = false;

  void _setDockOpen(bool open) {
    if (_dockOpen == open) return;
    _dockOpen = open;
    // Denetleyici bildirimi sırasında (ya da initState'te) üst ekranın
    // setState'i çağrılmasın: kare sonuna ertelenir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setEditing(_dockOpen);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Odağın en son İSTENDİĞİ balon. Okuma kartından "Düzenle"ye geçişte
  /// alanlar zaten aynı balonla dolu olduğundan ([_loadedId]) eski kod erken
  /// dönüyor ve ODAK HİÇ İSTENMİYORDU — kart açılıyor ama klavye gelmiyor,
  /// kullanıcı alana ayrıca dokunmak zorunda kalıyordu.
  String? _focusedFor;

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
    final editMode = widget.controller.editMode;
    _setDockOpen(open != null && editMode && !widget.readOnly);
    if (open == null) {
      _focusedFor = null;
      if (_loadedId != null) {
        _loadedId = null;
        _titleFocus.unfocus();
        _textFocus.unfocus();
      }
      return;
    }
    if (open.id != _loadedId) {
      _loadedId = open.id;
      _title.text = open.title;
      _text.text = open.text;
      // Başka bir balona geçildi: açık kalan eylem satırı yeni balona ait
      // sanılmasın.
      _colors = false;
      _fills = false;
      _focusedFor = null;
    }
    if (!editMode) {
      _focusedFor = null;
      return;
    }
    // Düzenlemeye açıldı (yeni balon, okuma kartından "Düzenle", listeden
    // düzenle): klavye hazır gelir, imleç metnin SONUNDA. Her balon için
    // BİR KEZ — sonraki bildirimler (yazdıkça) odağı yerinden oynatmaz.
    if (widget.readOnly || _focusedFor == open.id) return;
    _focusedFor = open.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _titleFocus.hasFocus || _textFocus.hasFocus) return;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
      _textFocus.requestFocus();
    });
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
      final l10n = context.l10n;
      final hintStyle = TextStyle(
        fontSize: 14,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      );
      // **YAZMA ALANI YENİLENDİ** (kullanıcı isteği 2026-10-16: "yazma
      // düzenleme alanı tamamen görsel yenilensin"): başlık satırı balonun
      // rengine boyalı bir şerit (renkli rozet + başlık + Bitti), yazı alanı
      // yumuşak dolgulu bir kutu (sohbet yazma kutusu gibi; kutunun boş
      // yerine dokunmak da alana odaklanır), araçlar altta. Kart klavyenin
      // hemen üstünde ve klavyeyle KARE KARE birlikte kayar
      // ([_KeyboardFollow]) — eskiden klavye animasyonu boyunca klavyenin
      // ARKASINDA kalıp, klavye durunca yukarı sıçrıyordu.
      final onColor =
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black87;
      return _KeyboardFollow(
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 6, 6, 6 + widget.bottomPadding),
          child: Material(
            key: _cardKey,
            color: scheme.surface,
            elevation: 10,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.16),
                    scheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            bubble.plain
                                ? Icons.text_fields_rounded
                                : bubble.isHighlight
                                ? Icons.border_color_rounded
                                : Icons.chat_bubble_rounded,
                            size: 15,
                            color: onColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: widget.readOnly
                              ? Text(
                                  bubble.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _titleStyle,
                                )
                              : TextField(
                                  key: const ValueKey('bubble-dock-title'),
                                  controller: _title,
                                  focusNode: _titleFocus,
                                  maxLines: 1,
                                  maxLength: PageBubble.maxTitle,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  // Başlıkta Enter metne geçer — klavye
                                  // kapanıp açılmaz.
                                  onSubmitted: (_) => _textFocus.requestFocus(),
                                  style: _titleStyle,
                                  cursorColor: scheme.onSurface,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: false,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    border: InputBorder.none,
                                    hintText: l10n.bubbleTitleHint,
                                    hintStyle: hintStyle,
                                  ),
                                  onChanged: (value) => widget.controller
                                      .updateTitle(bubble.id, value),
                                ),
                        ),
                        // "Bitti" YAZILI ve hep görünür: eski kapat simgesi
                        // (⤡) neyin kapandığını anlatmıyordu.
                        TextFieldTapRegion(
                          child: ExcludeFocus(
                            child: FilledButton.icon(
                              key: const ValueKey('bubble-dock-done'),
                              onPressed: _close,
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(0, 34),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(l10n.bubbleDone),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                  child: widget.readOnly
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(bubble.text, style: _bodyStyle),
                        )
                      : GestureDetector(
                          // Kutunun boş yerine dokunmak da yazmaya başlatır:
                          // tek satırlık alanın dışına (kutunun dolgusuna)
                          // dokunan parmak eskiden boşa gidiyordu.
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (!_textFocus.hasFocus) {
                              _textFocus.requestFocus();
                            }
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                              child: TextField(
                                key: const ValueKey('bubble-dock-text'),
                                controller: _text,
                                focusNode: _textFocus,
                                maxLines: 6,
                                minLines: 2,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                style: _bodyStyle,
                                cursorColor: scheme.onSurface,
                                // İmleç alanın içinde kaydırılırken kartın
                                // üstünde boşluk bırakılmaz.
                                scrollPadding: EdgeInsets.zero,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: l10n.bubbleHint,
                                  hintStyle: hintStyle,
                                ),
                                onChanged: (value) => widget.controller
                                    .updateText(bubble.id, value),
                              ),
                            ),
                          ),
                        ),
                ),
                if (!widget.readOnly) _toolRow(context, bubble),
                if (_colors && !widget.readOnly) _colorStrip(bubble),
                if (_fills && bubble.plain && !widget.readOnly)
                  _fillStrip(bubble),
                if (widget.readOnly) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );

  static const _titleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const _bodyStyle = TextStyle(fontSize: 14, height: 1.35);

  /// Araç düğmesi: küçük, odak İSTEMEYEN simge düğmesi.
  ///
  /// `ExcludeFocus` + `TextFieldTapRegion`: dokunuş yazı alanının odağını
  /// düşürmez — klavye açık kalır (bkz. sınıf açıklaması).
  Widget _barButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool selected = false,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: IconButton(
          tooltip: tooltip.isEmpty ? null : tooltip,
          onPressed: onPressed,
          isSelected: selected,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: selected
              ? IconButton.styleFrom(backgroundColor: scheme.secondaryContainer)
              : null,
          icon: Icon(
            icon,
            size: 19,
            color:
                color ??
                (selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  /// Renk, yıldız, acil, (vurguda) ok, (açık metinde) biçim ve silme.
  ///
  /// **HEP GÖRÜNÜR** (2026-10-15 yenilemesi): eskiden "⋮" düğmesinin
  /// arkasındaydı ve çoğu kullanıcı yıldızın, rengin, silmenin nerede
  /// olduğunu bulamıyordu. Satır kartın İÇİNDE, odak istemeyen düğmelerden
  /// oluşur — menü/levha rotası klavyeyi kapatıyordu (bkz. sınıf açıklaması).
  Widget _toolRow(BuildContext context, PageBubble bubble) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Düğmeler YATAY KAYAR, Sil sabit sağda: açık metin alanında biçim
    // düğmeleri ve boy düğmeleriyle satır dar telefona sığmıyordu.
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _tools(context, bubble, l10n, scheme)),
            ),
          ),
          _barButton(
            context,
            icon: Icons.delete_outline,
            tooltip: l10n.delete,
            color: scheme.error,
            onPressed: () {
              _titleFocus.unfocus();
              _textFocus.unfocus();
              widget.controller.remove(bubble.id);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _tools(
    BuildContext context,
    PageBubble bubble,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) => [
    // Renk: balonun kendi rengiyle dolu bir daire — şeridi açar.
    TextFieldTapRegion(
      child: ExcludeFocus(
        child: IconButton(
          key: const ValueKey('bubble-color-toggle'),
          tooltip: l10n.color,
          onPressed: () => setState(() {
            _colors = !_colors;
            if (_colors) _fills = false;
          }),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(bubble.color),
              shape: BoxShape.circle,
              border: Border.all(
                color: _colors ? scheme.primary : scheme.outlineVariant,
                width: _colors ? 2.5 : 1.5,
              ),
            ),
          ),
        ),
      ),
    ),
    _barButton(
      context,
      icon: bubble.starred ? Icons.star_rounded : Icons.star_border_rounded,
      tooltip: l10n.bubbleStar,
      selected: bubble.starred,
      color: bubble.starred ? Colors.amber[800] : null,
      onPressed: () => widget.controller.toggleStar(bubble.id),
    ),
    _barButton(
      context,
      icon: Icons.priority_high_rounded,
      tooltip: l10n.bubbleUrgent,
      selected: bubble.urgent,
      color: bubble.urgent ? scheme.error : null,
      onPressed: () => widget.controller.toggleUrgent(bubble.id),
    ),
    // Ok yalnız VURGULU balonda: serbest balonun bağlanacağı metin yok.
    if (bubble.isHighlight)
      _barButton(
        context,
        icon: bubble.arrow ? Icons.north_east : Icons.block,
        tooltip: bubble.arrow ? l10n.bubbleArrowHide : l10n.bubbleArrowShow,
        onPressed: () => widget.controller.toggleArrow(bubble.id),
      ),
    // **METİN KUTUSU BİÇİMİ** — yalnız AÇIK METİN alanında (normal
    // balonun yazısı kartın içinde duruyor, sayfada değil; orada
    // kalın/hiza/dolgu bir şey ifade etmez).
    if (bubble.plain) ...[
      _barButton(
        context,
        icon: Icons.format_bold,
        tooltip: l10n.formatBold,
        selected: bubble.bold,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(bold: !bubble.bold))
          ..save(),
      ),
      _barButton(
        context,
        icon: Icons.format_italic,
        tooltip: l10n.formatItalic,
        selected: bubble.italic,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(italic: !bubble.italic))
          ..save(),
      ),
      // Hiza tek düğmeyle DÖNER (sol → orta → sağ): kartta üç ayrı
      // düğmeye yer yok, simge de o an hangi hizada olduğunu gösterir.
      _barButton(
        context,
        icon: switch (bubble.align) {
          1 => Icons.format_align_center,
          2 => Icons.format_align_right,
          _ => Icons.format_align_left,
        },
        tooltip: switch (bubble.align) {
          1 => l10n.bubbleTextAlignCenter,
          2 => l10n.bubbleTextAlignRight,
          _ => l10n.bubbleTextAlignLeft,
        },
        selected: bubble.align != 0,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(align: (bubble.align + 1) % 3))
          ..save(),
      ),
      _barButton(
        context,
        icon: Icons.format_color_fill,
        tooltip: l10n.bubbleTextFill,
        selected: _fills,
        onPressed: () => setState(() {
          _fills = !_fills;
          if (_fills) _colors = false;
        }),
      ),
    ],
    // BOY (kullanıcı isteği 2026-10-16: "balonların boyutu
    // ayarlanabilir olsun"): normal balonda tutamaç, açık metinde yazı
    // büyür/küçülür. Değer nota yazılır, her cihazda aynı.
    _barButton(
      context,
      icon: Icons.zoom_out_rounded,
      tooltip: l10n.bubbleSmaller,
      onPressed: () => widget.controller.stepSize(bubble.id, -1),
    ),
    SizedBox(
      width: 34,
      child: Text(
        '${(bubble.size * 100).round()}%',
        key: const ValueKey('bubble-size-label'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    ),
    _barButton(
      context,
      icon: Icons.zoom_in_rounded,
      tooltip: l10n.bubbleLarger,
      onPressed: () => widget.controller.stepSize(bubble.id, 1),
    ),
  ];

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
            // Açık metin alanı kendi paletini kullanır (siyah/beyaz dahil) —
            // tutamaç renkleri bir YAZI için doğru seçenekler değil.
            for (final argb
                in bubble.plain
                    ? BubbleController.plainPalette
                    : BubbleController.palette)
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

  /// Açık metin alanının DOLGU şeridi: yazının arkasına konan zemin rengi.
  /// İlk seçenek "dolgu yok" (eski, dış hatlı çizim).
  Widget _fillStrip(PageBubble bubble) => TextFieldTapRegion(
    child: ExcludeFocus(
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          children: [
            for (final argb in BubbleController.fillPalette)
              GestureDetector(
                key: ValueKey('bubble-fill-$argb'),
                onTap: () => widget.controller
                  ..update(bubble.copyWith(fill: argb))
                  ..save(),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: argb == 0 ? null : Color(argb),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bubble.fill == argb
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black26,
                      width: bubble.fill == argb ? 3 : 1,
                    ),
                  ),
                  child: argb == 0
                      ? Tooltip(
                          message: context.l10n.bubbleTextFillNone,
                          child: const Icon(
                            Icons.format_color_reset,
                            size: 14,
                            color: Colors.black45,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// "Balon bırak" kipinin araç kartı: kip (balon / açık metin), renk, ipucu ve
/// YAZILI bir "Bitti". Yalnız ekleme kipinde görünür.
///
/// **2026-10-15 yenilemesi:** tek satırlık eski çubukta kip düğmeleri,
/// palet ve ipucu yan yana sıkışıyordu; dar telefonda ipucu iki harfe
/// iniyor, kipten nasıl çıkılacağı da görünmüyordu (çıkış yalnız sağ üstteki
/// küçük simgedeydi). Şimdi iki satır: üstte ne yapılacağı + Bitti, altta
/// kip ve renkler.
class BubbleToolbar extends StatelessWidget {
  const BubbleToolbar({super.key, required this.controller});

  final BubbleController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final plain = controller.plainMode;
        final selected = plain ? controller.plainColor : controller.color;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Material(
              color: scheme.surface,
              elevation: 6,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plain
                                ? l10n.bubblePlainTapToPlace
                                : l10n.bubbleTapToPlace,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('bubble-toolbar-done'),
                          onPressed: () => controller.setAdding(false),
                          child: Text(l10n.bubbleDone),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // KİP SEÇİMİ EN BAŞTA VE ETİKETLİ (kullanıcı bulgusu
                        // 2026-08-16: "paint tarzı metin balonu eklemeyi
                        // bulamadım").
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                              ),
                              label: Text(l10n.bubbleModeBubble),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.text_fields, size: 16),
                              label: Text(l10n.bubblePlainModeShort),
                            ),
                          ],
                          selected: {plain},
                          onSelectionChanged: (selection) =>
                              controller.setPlainMode(selection.first),
                        ),
                        // Palet KİPE GÖRE değişir: balon tutamacının renkleri
                        // ile açık metnin renkleri ayrı listeler (açık metnin
                        // başı siyah — bkz. [BubbleController.plainPalette]).
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 6),
                              children: [
                                for (final argb
                                    in plain
                                        ? BubbleController.plainPalette
                                        : BubbleController.palette)
                                  GestureDetector(
                                    onTap: () => plain
                                        ? controller.setPlainColor(argb)
                                        : controller.setColor(argb),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(argb),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected == argb
                                              ? scheme.onSurface
                                              // Beyaz renk beyaz zeminde
                                              // kaybolmasın.
                                              : scheme.outlineVariant,
                                          width: selected == argb ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // BÜTÜN balonların boyu (cihaz tercihi — bkz.
                        // [BubbleLook]). Tek balonunki yazma kartında.
                        if (!plain) const _GlobalSizeButtons(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Balon bırakma kartındaki genel boy düğmeleri: − 100% +.
class _GlobalSizeButtons extends StatelessWidget {
  const _GlobalSizeButtons();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double>(
      valueListenable: BubbleLook.scale,
      builder: (context, scale, _) {
        Widget button(IconData icon, String tooltip, double delta, Key key) =>
            IconButton(
              key: key,
              tooltip: tooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
              iconSize: 18,
              onPressed:
                  (delta < 0
                      ? scale <= BubbleLook.min
                      : scale >= BubbleLook.max)
                  ? null
                  : () => BubbleLook.setScale(scale + delta),
              icon: Icon(icon),
            );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Icons.zoom_out_rounded,
              l10n.bubbleAllSmaller,
              -BubbleLook.step,
              const ValueKey('bubble-global-smaller'),
            ),
            Text(
              '${(scale * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            button(
              Icons.zoom_in_rounded,
              l10n.bubbleAllLarger,
              BubbleLook.step,
              const ValueKey('bubble-global-larger'),
            ),
          ],
        );
      },
    );
  }
}

/// Balonlu panonun alt çubuğundaki balon düğmeleri: belirgin "Balon"
/// (bırakma kipini açar; açıkken "Bitti" olur) ve sayılı balon listesi.
///
/// Eskiden ikisi de görüntüleyicinin SAĞ ÜST köşesinde, belgenin üstüne
/// binen iki küçük yuvarlak simgeydi (2026-10-15: "genel hatlar tamamen
/// yenilenmeli"); ne işe yaradıkları anlaşılmıyor, belgeyi de kapatıyordu.
/// Yalnız bu küçük satır denetleyiciyi dinler — belge yeniden kurulmaz.
class BubbleBarActions extends StatelessWidget {
  const BubbleBarActions({
    super.key,
    required this.controller,
    required this.onOpenList,
    this.compact = false,
  });

  final BubbleController controller;
  final VoidCallback onOpenList;

  /// Dar ekranda "Balon" yazısı düşer, yalnız simge kalır.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final adding = controller.adding;
        final count = controller.bubbles.length;
        // Göster/gizle düğmesi de çubuktayken (balon varken) telefonda
        // "Balon" yazısı düşer — sayfa sayacı kesilmesin.
        final compact =
            this.compact ||
            (count > 0 && MediaQuery.sizeOf(context).width < 400);
        final style = FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          minimumSize: const Size(0, 36),
        );
        final icon = Icon(
          adding ? Icons.check : Icons.add_comment_outlined,
          size: 18,
        );
        void toggle() => controller.setAdding(!adding);
        final Widget add = compact
            ? (adding
                  ? FilledButton(onPressed: toggle, style: style, child: icon)
                  : FilledButton.tonal(
                      onPressed: toggle,
                      style: style,
                      child: icon,
                    ))
            : (adding
                  ? FilledButton.icon(
                      onPressed: toggle,
                      style: style,
                      icon: icon,
                      label: Text(l10n.bubbleDone),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: toggle,
                      style: style,
                      icon: icon,
                      label: Text(l10n.bubbleModeBubble),
                    ));
        final hidden = controller.hidden;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              key: const ValueKey('bubble-add'),
              message: adding ? l10n.bubbleAddDone : l10n.bubbleAdd,
              child: add,
            ),
            // GÖSTER / GİZLE (kullanıcı isteği 2026-10-16). Balon yoksa
            // gizlenecek bir şey de yok — düğme çizilmez.
            if (count > 0)
              IconButton(
                key: const ValueKey('bubble-visibility'),
                tooltip: hidden ? l10n.bubblesShow : l10n.bubblesHide,
                visualDensity: VisualDensity.compact,
                isSelected: hidden,
                onPressed: () => controller.setHidden(!hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            IconButton(
              tooltip: l10n.bubblesOverviewTitle,
              visualDensity: VisualDensity.compact,
              onPressed: onOpenList,
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.forum_outlined),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Çocuğunu KLAVYENİN ÜSTÜNDE tutar: çocuğun alt kenarı klavyenin arkasına
/// düşüyorsa (ekranın gövdesi henüz kısalmadıysa) aradaki fark kadar yukarı
/// KAYDIRARAK çizer. Yalnız boyama ve isabet testi kayar — yerleşim yok.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "balona yazarken klavye
/// kayması"): not editörü klavye açılırken gövdeyi bilerek animasyon
/// boyunca tam boyda tutar ve klavye DURUNCA tek seferde kısaltır (bkz.
/// `KeyboardSnap` — kasma çözümü). Gövdenin dibindeki yazma kartı bu yüzden
/// klavye açılırken ~400 ms klavyenin arkasında kalıyor, sonra birden
/// yukarı sıçrıyordu; yazılan ilk harfler görünmüyordu. Kart artık
/// klavyeyle kare kare birlikte yükselir; gövde oturunca fark sıfırlanır,
/// görünür hiçbir sıçrama olmaz. Klavyeyi zaten gövdeden düşen tam ekran
/// görüntüleyicilerde fark hep sıfırdır (etkisiz).
class _KeyboardFollow extends StatelessWidget {
  const _KeyboardFollow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Bağımlılık YALNIZ bu küçük sarmalayıcıda: klavye karelerinde kartın
    // kendisi yeniden kurulmaz, yalnız çizim kayması güncellenir.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final view = View.of(context);
    final height = view.physicalSize.height / view.devicePixelRatio;
    final keyboard = math.max(
      inset,
      view.viewInsets.bottom / view.devicePixelRatio,
    );
    return _KeyboardFollowBox(keyboardTop: height - keyboard, child: child);
  }
}

class _KeyboardFollowBox extends SingleChildRenderObjectWidget {
  const _KeyboardFollowBox({required this.keyboardTop, super.child});

  /// Klavyenin üst kenarı (pencerenin tepesinden, mantıksal piksel).
  final double keyboardTop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKeyboardFollow(keyboardTop);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderKeyboardFollow renderObject,
  ) => renderObject.keyboardTop = keyboardTop;
}

class _RenderKeyboardFollow extends RenderProxyBox {
  _RenderKeyboardFollow(this._keyboardTop);

  double _keyboardTop;
  set keyboardTop(double value) {
    if (value == _keyboardTop) return;
    _keyboardTop = value;
    markNeedsPaint();
  }

  /// Son çizimdeki yukarı kayma (dp).
  double _shift = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final bottom = localToGlobal(Offset(0, size.height)).dy;
    _shift = math.max(0.0, bottom - _keyboardTop);
    context.paintChild(child, offset.translate(0, -_shift));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (!size.contains(position.translate(0, _shift))) return false;
    final hit = result.addWithPaintOffset(
      offset: Offset(0, -_shift),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_shift, 0, 1);
  }
}

/// Bölmenin alt kenarının klavyenin ARKASINDA kalan kısmı (dp). Görüntüleyici
/// açık balonu ortalarken klavyenin altında kalan yeri "görünür" saymasın
/// (bkz. `centerPdfOnBubble`) — editör gövdesi klavye durana dek kısalmaz.
double keyboardOverlapOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return 0;
  final view = View.maybeOf(context);
  if (view == null) return 0;
  final height = view.physicalSize.height / view.devicePixelRatio;
  final keyboard = view.viewInsets.bottom / view.devicePixelRatio;
  if (keyboard <= 0) return 0;
  final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
  return math.max(0.0, bottom - (height - keyboard));
}
