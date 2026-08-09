import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../domain/note_item.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

/// Yanlışlıkla işaretlenen öğenin "hemen geri alındı" sayıldığı süre.
const kUncheckRestoreWindow = Duration(seconds: 30);

/// İşareti KALKAN öğenin listeye geri gireceği konum.
///
/// İki farklı niyet aynı hareketle yapılıyor: (a) yanlışlıkla işaretleyip
/// hemen geri alma — öğe eski sırasında kalmalı, (b) gerçekten tamamlanmış bir
/// işi sonradan yeniden açma — öğe sıranın sonuna girmeli. Aradaki tek fark
/// GEÇEN SÜREdir; [kUncheckRestoreWindow] içinde geri alınan öğe eski
/// konumuna döner, sonrası işaretsizlerin sonuna eklenir (eski davranış).
///
/// [uncheckedCount] öğe listeden çıkarıldıktan SONRAKİ işaretsiz sayısıdır:
/// hem sonuna ekleme hem de hatırlanan konumun üst sınırı odur (arada başka
/// öğeler silinmiş olabilir).
int uncheckRestoreIndex({
  required int uncheckedCount,
  int? rememberedIndex,
  Duration? sinceChecked,
}) {
  if (rememberedIndex == null ||
      sinceChecked == null ||
      sinceChecked > kUncheckRestoreWindow) {
    return uncheckedCount;
  }
  return rememberedIndex.clamp(0, uncheckedCount);
}

/// Madde listesini "işaretsizler önce, işaretliler sonra" düzenine getirir;
/// iki blok da kendi içindeki sırayı KORUR (kararlı bölme).
///
/// KÖK NEDEN (kullanıcı: "madde sıralamasını değiştiremiyorum iptal oluyor",
/// "yeni öğe alta eklenmiyor / yanlış yere gidiyor"): editörün bütün konum
/// hesabı "işaretsizler listenin başında" DEĞİŞMEZİNE dayanıyordu ama bu
/// değişmez hiçbir yerde ZORLANMIYORDU — yalnızca umuluyordu. Bozulması da
/// kolay: bir madde işaretlendiğinde görünüm animasyonu bitene kadar (220 ms)
/// öğe listede YERİNDE kalır ve o hâliyle bir kez kaydedilir; kullanıcı o
/// aralıkta editörden çıkarsa nota "işaretli madde ortada" diye yazılır.
/// Aynı şey başka cihazdan/eski sürümden gelen ya da yapay zekânın kurduğu
/// listelerde de olabiliyor.
///
/// Değişmez bozulunca iki şey birden kırılıyordu:
/// - "Yeni öğe" `_checkedStart`e giriyordu; o da artık ilk işaretlinin (yani
///   listenin ORTASININ) konumuydu → madde yanlış yere düşüyordu.
/// - Sürükle-sırala, ekrandaki satır sırasını `_items` sırasıyla BİREBİR
///   eşleşiyor sayıyordu → sürüklenen satır yerine başka bir madde taşınıyor,
///   kullanıcıya sıralama "tutmuyor / geri alınıyor" gibi görünüyordu.
///
/// Artık liste dışarıdan her benimsendiğinde buradan geçiyor (bozuk kayıt
/// açılışta onarılır) ve konum hesapları da düzene GÜVENMİYOR (bkz.
/// `_ItemsEditorState._uncheckedInsertIndex`, `_reorder`).
List<NoteItem> normalizeItems(List<NoteItem> items) {
  var seenChecked = false;
  var ordered = true;
  for (final item in items) {
    if (item.checked) {
      seenChecked = true;
    } else if (seenChecked) {
      ordered = false;
      break;
    }
  }
  if (ordered) return List.of(items);
  return [
    for (final i in items)
      if (!i.checked) i,
    for (final i in items)
      if (i.checked) i,
  ];
}

/// Sürükleyerek sıralarken parmağın konumuna göre kare başına kaç piksel
/// kaydırılacağı. Negatif = yukarı, pozitif = aşağı, 0 = kaydırma yok.
///
/// [top] ve [bottom] görünür sayfa kutusunun ekran koordinatlarıdır. Parmak
/// [band] kadarlık kenar şeridine girdikçe kaydırma hızlanır; şeridin dışında
/// kaydırma durur. Ayrı bir işlev: kenar mantığı widget kurmadan sınanabilsin.
double reorderAutoScrollStep({
  required double pointerY,
  required double top,
  required double bottom,
  double band = 88,
  double maxStep = 14,
}) {
  // Kutu banttan darsa (çok kısa liste) bant kutunun yarısına iner; yoksa üst
  // ve alt bantlar örtüşür ve parmak nerede olursa olsun kaydırma tetiklenir.
  final effective = math.min(band, (bottom - top) / 2);
  if (effective <= 0) return 0;
  if (pointerY < top + effective) {
    return -maxStep *
        ((top + effective - pointerY) / effective).clamp(0.0, 1.0);
  }
  if (pointerY > bottom - effective) {
    return maxStep *
        ((pointerY - (bottom - effective)) / effective).clamp(0.0, 1.0);
  }
  return 0;
}

/// Checklist ve sıralı liste düzenleyicisi. Öğeler "Seç" modundaki tutamaçtan
/// sürüklenerek sıralanır, Enter yeni öğe ekler. Silme "x" düğmesi yalnızca
/// satır odaklıyken görünür (kaydırma/yazma sırasında yanlışlıkla basılmasın).
/// Checklist modunda işaretlenen öğeler otomatik listenin en altına düşer ve
/// "İşaretlileri sil" ile toplu silinebilir.
class ItemsEditor extends StatefulWidget {
  const ItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    required this.showCheckboxes,
    this.expandItems = true,
    this.header,
    this.footer,
    this.floats = const [],
    this.pageBox,
    this.shrinkWrap = false,
    this.contentInsertion,
    this.richTheme,
    this.textStyle,
    this.onFieldFocused,
    this.wholeNoteText,
    this.onFieldDisposed,
  });

  final List<NoteItem> items;
  final ValueChanged<List<NoteItem>> onChanged;
  final bool showCheckboxes;

  /// Sayfadaki görsellerin kapladığı bantlar (sayfa uzayı): madde metni
  /// bunların etrafından akar. Boşsa satırlar sıradan davranır.
  final List<FloatBox> floats;

  /// Sayfa içeriğinin kök kutusu — satırların konumu buna göre ölçülür.
  /// null ise sarma tümüyle kapalıdır.
  final RenderBox? Function()? pageBox;

  /// true: liste kendi kaydırmasını yapmaz, dıştaki sayfa kaydırır (serbest
  /// görsel tuvalinin içindeyken şart — iç içe iki kaydırıcı olamaz).
  /// Bu kipte sürükleyerek sıralarken kenar kaydırmasını editör kendi
  /// yürütür (bkz. [_ItemsEditorState._autoScrollTo]): ReorderableListView'ın
  /// yerleşik otomatik kaydırıcısı KENDİ görünüm kutusunu kaydırır, o da bu
  /// kipte kaydırılamaz olduğu için hiçbir şey yapmıyordu.
  final bool shrinkWrap;

  /// true: uzun satırlar tamamen sarılıp görünür. false: satır tek satırda
  /// kalır, yalnızca odaklanınca (dokununca) açılır.
  final bool expandItems;

  final Widget? header;
  final Widget? footer;

  /// Klavyeden gelen görselin nereye gideceği (Gboard pano çubuğu /
  /// "Yapıştır"). Ekleri not editörü yönettiğinden yapılandırma dışarıdan
  /// verilir; null ise klavye görseli hiç göndermez.
  final ContentInsertionConfiguration? contentInsertion;

  /// Satır içi biçimlendirmenin (kalın/italik/renk) çizim ayarları; null ise
  /// madde metni biçimlendirilmeden çizilir.
  final RichTextTheme? richTheme;

  /// Madde metninin temel stili (notun yazı tipi/boyutu). null ise temanın
  /// `bodyLarge`'ı kullanılır.
  final TextStyle? textStyle;

  /// Bir madde alanı odağı aldığında çağrılır: biçim çubuğu hangi alana
  /// yazacağını buradan öğrenir (denetleyici + metni nota işleyen geri çağrı).
  final void Function(
    WrapTextController controller,
    FocusNode focusNode,
    VoidCallback commit,
  )?
  onFieldFocused;

  /// "Tüm notu kopyala" için notun TAM düz metni (başlık + gövde + maddeler).
  /// null ise yalnız maddeler kopyalanır (bağımsız kullanım).
  final String Function()? wholeNoteText;

  /// Bir madde satırı silinip denetleyicisi dispose edilmeden ÖNCE çağrılır:
  /// biçim çubuğunun hedefi bu alansa hedefi bıraksın — yoksa çubuk dispose
  /// edilmiş denetleyiciye yazmaya çalışıyordu.
  final void Function(WrapTextController controller)? onFieldDisposed;

  @override
  State<ItemsEditor> createState() => ItemsEditorState();
}

class ItemsEditorState extends State<ItemsEditor> {
  static const _uuid = Uuid();

  late List<NoteItem> _items;
  final _controllers = <String, WrapTextController>{};
  final _focusNodes = <String, FocusNode>{};

  /// Satır başına "odaklı mı" bayrağı.
  ///
  /// KÖK NEDEN (kasma): odak dinleyicisi eskiden `setState(() {})` çağırıyordu
  /// ve odak SATIRDAN SATIRA her dokunuşta iki kez değiştiği için (biri
  /// bırakan, biri alan satır) listenin TAMAMI — her satırın TextField'ı,
  /// taşma ölçümü, sarma kutusu — iki kez yeniden kuruluyordu. Odağın
  /// değiştirdiği tek şey o satırın kendi görünümü (imleç, "×" düğmesi, tek
  /// satır kipinde yükseklik); artık yalnız o satır yeniden çiziliyor.
  final _focusFlags = <String, ValueNotifier<bool>>{};

  /// Bayrak, düğümün O ANKİ hâliyle doğar: satır ilk kez çizilmeden önce
  /// odaklanmış olabilir (başlıktaki "İleri" tuşu → [focusFirstItem]).
  /// Değer build SIRASINDA yazılmaz — yazılsaydı dinleyici çizim ortasında
  /// tetiklenirdi.
  ValueNotifier<bool> _focusFlagFor(String id) => _focusFlags.putIfAbsent(
    id,
    () => ValueNotifier(_focusNodes[id]?.hasFocus ?? false),
  );

  /// En son benimsenen DIŞ liste (nesne kimliğiyle). Gelen liste düzensizse
  /// [normalizeItems]'tan geçmiş hâli benimseniyor; bu alan olmasa aynı bozuk
  /// liste her üst build'de yeniden "farklı" görünür ve boşuna setState
  /// çağrılırdı.
  List<NoteItem>? _adoptedFrom;

  /// Toplu işlem için seçilen öğeler.
  /// Metin alanları ayrı TextField olduğundan sistemin metin seçimi
  /// satırlar arasına geçemez; toplu kopyalama/silme bu modla yapılır.
  final _selected = <String>{};

  /// "Seç" düğmesiyle açılan mod. Seçim satırın sol kenarına uzun basışla da
  /// açılıyordu ama o bölge dar ve görünmez — hiçbir yerde yazmadığı için
  /// bulunamıyordu; düğme aynı modu görünür kılar (henüz hiçbir öğe
  /// seçilmemişken de açık kalması gerektiğinden ayrı bayrak şart).
  bool _selectMode = false;

  bool get _selectionMode => _selectMode || _selected.isNotEmpty;

  /// Alt çubuğu ekranın DİBİNE demirleyen katman denetleyicisi.
  ///
  /// Çubuk eskiden listenin header'ındaydı ve listeyle birlikte kayıyordu:
  /// uzun bir listede aşağıdaki maddeleri seçtikten sonra kopyalamak için
  /// başa dönmek gerekiyordu. Overlay'e taşınınca çubuk sayfa neresinde
  /// olursa olsun görünür kalır.
  ///
  /// **Artık "Yeni öğe" ve "Seç" de burada** (kullanıcı isteği 2026-08-09:
  /// "seç ve yeni öğe hep görülmeli, sayfanın neresinde olursak olalım").
  /// İkisi listenin FOOTER'ındaydı, yani en altında: elli maddelik bir notta
  /// madde eklemek ya da toplu seçime girmek için önce dibe kadar kaydırmak
  /// gerekiyordu. Katman tek: seçim kipinde seçim çubuğu, dışında ekleme
  /// çubuğu çizilir — ikisi aynı yerde, hiç üst üste binmeden.
  final _barController = OverlayPortalController();

  /// Çubuk liste düzenleyici ekrandayken HER ZAMAN durur; içeriği kipe göre
  /// değişir (seçim çubuğu ↔ ekleme çubuğu).
  void _syncBar() {
    if (!_barController.isShowing) _barController.show();
  }

  void _exitSelection() {
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    _syncBar();
  }

  @override
  void initState() {
    super.initState();
    _adoptedFrom = widget.items;
    _items = _adopt(widget.items);
    // Katman ilk kareden SONRA gösterilir: OverlayPortal henüz ağaca
    // bağlanmadan `show()` çağırmak denetleyiciyi boşa harcar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncBar();
    });
  }

  /// Dışarıdan gelen listeyi yerel duruma alır: checklist'te "işaretsizler
  /// önce" düzenine getirilir (bkz. [normalizeItems] — bozuk kayıt burada
  /// onarılır). Sıralı listede işaret kavramı yok, sıra olduğu gibi kalır.
  ///
  /// Onarım nota HEMEN yazılmaz (yalnız yerel): açılışta kaydetmek her eski
  /// notun `updatedAt`ini boşuna tazeler ve ana ekranın sıralamasını
  /// karıştırırdı. Kullanıcı ilk düzenlemesini yaptığı anda düzeltilmiş sıra
  /// zaten kaydedilir.
  List<NoteItem> _adopt(List<NoteItem> incoming) =>
      widget.showCheckboxes ? normalizeItems(incoming) : List.of(incoming);

  /// Dıştaki sayfa kaydırıcısı ([ItemsEditor.shrinkWrap] kipinde liste kendi
  /// kaydırmasını yapmaz). Sürükleyerek sıralarken kenar kaydırması bunun
  /// üzerinden yürür.
  ScrollableState? _outerScroll;

  /// Sürükleme sürüyor mu ve o an kare başına kaç piksel kaydırılacak.
  bool _reordering = false;
  double _autoScrollStep = 0;
  Timer? _autoScrollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _outerScroll = widget.shrinkWrap ? Scrollable.maybeOf(context) : null;
  }

  /// Sürükleme sırasında parmağın konumuna göre kenar kaydırmasını ayarlar.
  /// Parmak bandın dışındaysa kaydırma durur.
  void _autoScrollTo(Offset globalPosition) {
    final scrollable = _outerScroll;
    if (!_reordering || scrollable == null) return;
    final box = scrollable.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final step = reorderAutoScrollStep(
      pointerY: globalPosition.dy,
      top: top,
      bottom: top + box.size.height,
    );
    _autoScrollStep = step;
    if (step == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollTick(),
    );
  }

  void _autoScrollTick() {
    final position = _outerScroll?.position;
    if (position == null || !position.hasContentDimensions) {
      _stopAutoScroll();
      return;
    }
    final target = (position.pixels + _autoScrollStep).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    // Uca gelindiyse zamanlayıcıyı boşuna döndürme.
    if (target == position.pixels) {
      _stopAutoScroll();
      return;
    }
    position.jumpTo(target);
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollStep = 0;
  }

  @override
  void didUpdateWidget(covariant ItemsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _adoptIncomingItems();
  }

  /// Sürükleme SÜRERKEN gelen listeyi benimseme, bırakılınca benimse.
  ///
  /// KÖK NEDEN (kullanıcı: "sıralamayı değiştiremiyorum iptal oluyor"):
  /// `SliverReorderableList` öğe SAYISI değişir değişmez sürüklemeyi iptal
  /// eder (`didUpdateWidget` → `cancelReorder`). Editör bu sırada arka planda
  /// kaydediyor; Firestore'dan (ya da başka bir cihazdan) dönen anlık görüntü
  /// tam sürükleme ortasında listeyi tazelerse hareket sessizce düşüyordu —
  /// parmak hâlâ ekrandayken satır eski yerine geri atlıyor.
  bool _adoptDeferred = false;

  void _adoptIncomingItems() {
    if (_reordering) {
      _adoptDeferred = true;
      return;
    }
    // Gelen liste yerelden farklıysa benimse. ESKİDEN yalnızca kimliklerin
    // TAMAMEN değiştiği durumda yenileniyordu; dikte/hesap makinesi/AI bir
    // öğe eklediğinde eski kimlikler durduğundan koşul tutmuyor ve eklenen
    // öğe ekranda HİÇ görünmüyordu (editörden çıkıp girince beliriyordu).
    //
    // Yerel yazımda döngü riski yok: onChanged çağıran taraf durumu aynı
    // karede günceller, dönen liste yerelle birebir aynı olur ve buradaki
    // karşılaştırma false kalır.
    // `identical` süzgeci: gelen liste düzensizse yerel kopya ONARILMIŞ hâli
    // tutar, yani `_sameItems` bir daha asla tutmaz. O listeyi bir kez
    // benimsedikten sonra her üst build'de yeniden benimsemek boşuna
    // setState demek olurdu.
    if (!identical(widget.items, _adoptedFrom) &&
        !_sameItems(_items, widget.items)) {
      _adoptedFrom = widget.items;
      setState(() => _items = _adopt(widget.items));
      // Denetleyici metinleri de SENKRONLANMALI: controller yalnız ilk
      // kurulumda maddenin metnini alıyor. Metin dışarıdan değişince (Geri
      // al, AI "Değiştir"in kimlik koruyan yolu) alan eski metni göstermeye
      // devam ediyor ve o satıra yazılan ilk harf BAYAT metni nota geri
      // yazıyordu — geri alma sessizce iptal oluyordu.
      for (final item in _items) {
        final controller = _controllers[item.id];
        if (controller == null || controller.logicalText == item.text) {
          continue;
        }
        final node = _focusNodes[item.id];
        final selection = controller.selection;
        final caret = (node != null && node.hasFocus && selection.isValid)
            ? selection.baseOffset.clamp(0, item.text.length)
            : item.text.length;
        controller.setLogical(item.text, caret);
      }
    }
  }

  /// İki liste görünür olarak aynı mı (sıra + kimlik + metin + işaret).
  static bool _sameItems(List<NoteItem> a, List<NoteItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].checked != b[i].checked) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    for (final f in _focusFlags.values) {
      f.dispose();
    }
    super.dispose();
  }

  WrapTextController _controllerFor(NoteItem item) {
    final controller = _controllers.putIfAbsent(item.id, () {
      final created = WrapTextController(text: item.text);
      // Gövde metniyle aynı davranış: uzun basış kelimeyi değil cümleyi seçer.
      attachSentenceSelection(created);
      return created;
    });
    // Tema (renk paleti) değişebilir; setter aynı değerde hiçbir şey yapmaz.
    controller.richTheme = widget.richTheme;
    return controller;
  }

  FocusNode _focusFor(NoteItem item) => _focusNodes.putIfAbsent(item.id, () {
    final node = FocusNode();
    // Odak değişince (a) "dokununca aç" modunda satır yüksekliği, (b)
    // silme "x" düğmesinin görünürlüğü değişir; ikisi de YALNIZ o satırı
    // ilgilendirir — bu yüzden listenin tamamı değil, satırın kendi bayrağı
    // güncellenir (bkz. [_focusFlags]).
    node.addListener(() {
      if (!mounted) return;
      final controller = _controllerFor(item);
      if (node.hasFocus) {
        widget.onFieldFocused?.call(
          controller,
          node,
          () => _updateText(item, controller.logicalText),
        );
      } else if (controller.hasPendingFormat) {
        // Satır odaktan çıkıyor: bekleyen biçim metne YAZILIR. Yoksa "kalın"a
        // basıp tek kelime yazan ve başka yere dokunan kullanıcı biçmi
        // sessizce kaybederdi (sarma normalde kelime sınırında yapılıyor —
        // bkz. WrapTextController._wrapPending).
        controller.flushPendingFormat();
        _updateText(item, controller.logicalText);
      }
      _focusFlagFor(item.id).value = node.hasFocus;
    });
    return node;
  });

  void _commit() {
    // Silinen satırların taşma ölçümü sonsuza dek yaşamasın (bkz.
    // [_overflowsLine]); ölçüm satır sayısından çoksa bayatlar ayıklanır.
    if (_overflowCache.length > _items.length) {
      final live = {for (final i in _items) i.id};
      _overflowCache.removeWhere((id, _) => !live.contains(id));
    }
    widget.onChanged(List.of(_items));
  }

  /// Tek satır kipinde satır başına son taşma ölçümü (metin + genişlik +
  /// punto ile birlikte). Ölçüm `TextPainter.layout` demek; önbelleksiz
  /// hâlinde EKRANDAKİ HER SATIR, her yeniden çizimde yeniden ölçülüyordu —
  /// bir maddeye yazarken editörün tamamı yeniden kurulduğu için bu, tuş
  /// başına satır sayısı kadar metin yerleşimi ediyordu (kasmanın
  /// kaynaklarından biri). Metin/genişlik/punto değişmedikçe ölçüm tekrar
  /// edilmez.
  final _overflowCache =
      <String, ({String text, double width, double fontSize, bool value})>{};

  bool _overflowsLine(
    BuildContext context,
    String id,
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final fontSize = style.fontSize ?? 0;
    final cached = _overflowCache[id];
    if (cached != null &&
        cached.text == text &&
        cached.width == maxWidth &&
        cached.fontSize == fontSize) {
      return cached.value;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final value = painter.width > maxWidth - 14;
    painter.dispose();
    _overflowCache[id] = (
      text: text,
      width: maxWidth,
      fontSize: fontSize,
      value: value,
    );
    return value;
  }

  /// Satırların son ölçülen kaydırma değerleri (id → sol/sağ dolgu). Yeni
  /// eklenen satır KOMŞUSUNUN değeriyle doğsun diye tutulur: aksi hâlde satır
  /// bir kare kaymadan çizilip sonraki karede yerine atlıyor ve madde
  /// eklerken titreme görünüyordu.
  final _pads = <String, ({double start, double end, double top})>{};

  /// Satır başındaki sürükleme tutamacının kapladığı genişlik (yalnız seçim
  /// modunda vardır).
  static const double _kHandleWidth = 22;

  /// Kutucuk / seçim dairesi / sıra numarasının kapladığı genişlik.
  static const double _kLeadingWidth = 48;

  /// Sil düğmesinin (odaksızken boş kutunun) genişliği.
  static const double _kTrailingWidth = 48;

  /// Satırın iki yanındaki yatay dolgu.
  static const double _kRowPadding = 24;

  /// "Yeni öğe / Seç" ve "İşaretlileri sil" düğme satırlarının sığdığı en az
  /// genişlik. Bu satırların metni sarılamaz (düğme daralmaz); dar kalırlarsa
  /// taşarlar — o yüzden görselin yanına sıkışmak yerine ALTINA inerler.
  static const double _kButtonRowWidth = 280;

  /// Satırın TAMAMINI (tutamaç + kutucuk + metin + sil düğmesi) görselin
  /// yanına kaydırır. Yalnız metni sarmak yetmiyordu: kutucuk ve tutamaç
  /// satırın sol başında durduğundan görselin ALTINDA kalıyordu.
  ///
  /// [reserved] satırın metne ayrılamayan payıdır; sarma kararı bu pay
  /// düşülerek verilir (bkz. [_FloatRow.reserved]).
  ///
  /// KÖK NEDEN (kullanıcı: "yeni öğe görselin yanına ilk defa eklendiğinde
  /// yanıp sönen imleç çıkmıyor") — sarmalayıcı eskiden `floats.isEmpty`
  /// olduğunda HİÇ kurulmuyordu. Bantlar çalışma anında doluyor (tuval
  /// görsellerin yerini ilk çizimden SONRA ölçüp bildiriyor, görsel eklenip
  /// silinince de değişiyor): o anda satırın ağacına araya bir katman girip
  /// çıkıyor, TextField başka bir konuma düşüyor ve state'i (içindeki
  /// EditableText ile birlikte) SIFIRDAN kuruluyordu. Yeni state odağı zaten
  /// almış bir düğümle açıldığı için "odak değişti" olayı gelmiyor, imlecin
  /// yanıp sönme zamanlayıcısı hiç başlamıyordu — imleç ancak ilk harfte
  /// beliriyordu. (Aynı kök neden 2026-08-06'da odak için bulunmuştu; kural
  /// odakla sınırlı değil: ağacın ŞEKLİ çalışma anında hiç değişmemeli.)
  ///
  /// Bant yokken bedel sıfır: [_FloatRow] boş bant listesinde ölçüm bile
  /// planlamaz, yalnız 0 dolgulu bir [Padding] çizer.
  Widget _floatRow(Widget child, {String? id, double reserved = 0}) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return child;
    return _FloatRow(
      floats: widget.floats,
      pageBox: pageBox,
      reserved: reserved,
      initial: id == null ? null : (_pads[id] ?? _padOfNeighbour(id)),
      onMeasured: id == null ? null : (pad) => _pads[id] = pad,
      child: child,
    );
  }

  /// Yeni satırın başlangıç tahmini: bir üstündeki maddenin kaydırması
  /// (aynı görselin bandındaysa birebir doğrudur).
  ({double start, double end, double top})? _padOfNeighbour(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index <= 0) return null;
    return _pads[_items[index - 1].id];
  }

  /// Madde alanını sarma denetleyicisinin ölçümüne bağlar.
  ///
  /// Bantlar BİLEREK BOŞ geçilir: liste satırını görselin yanına [_FloatRow]
  /// satırın TAMAMINI kaydırarak taşıyor. Alan içi sarma çapaları da aynı
  /// bantlara göre girinti basınca ikisi üst üste biniyor ve görselin
  /// yanındaki maddelerin metni kutucuktan kopuk, "kaymış" görünüyordu
  /// (ekran görüntüsüyle bildirilen hata). Boş bant listesi ayrıca daha
  /// önce eklenmiş çapaları da temizler.
  Widget _wrapped(
    WrapTextController controller,
    TextStyle style,
    Widget field,
  ) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: const [],
      pageBox: pageBox,
      child: field,
    );
  }

  void _updateText(NoteItem target, String text) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    // Metinde satır sonu: ya çok satırlı bir YAPIŞTIRMA ya da donanım
    // klavyesinin Enter'ı (çok satırlı alanda Enter onEditingComplete'e
    // düşmez, alana `\n` girer). İki durumda da satırlar ayrı maddelere
    // bölünür — "ekmek\nsüt\nyumurta" tek şişkin madde olmaz.
    if (text.contains('\n')) {
      _splitMultiline(target, index, text);
      return;
    }
    _items[index] = _items[index].copyWith(text: text);
    _commit();
  }

  /// `- [x]`, `-`, `•`, `3.` gibi liste öneklerini soyar; checklist'te
  /// işaret durumunu da okur.
  static final _lineMarker = RegExp(
    r'^\s*(?:[-*•]\s*)?(?:\[([ xX])\]\s*)?(?:\d+[.)]\s+)?',
  );

  void _splitMultiline(NoteItem target, int index, String text) {
    final lines = text.split('\n');
    // Hedef madde yapıştırmadan önce BOŞSA ilk satırın liste öneki de
    // soyulur (sonraki satırlarla tutarlı); doluysa ilk satır kullanıcının
    // yazmakta olduğu metnin devamıdır, dokunulmaz.
    final wasEmpty = _items[index].text.trim().isEmpty;
    var first = lines.first;
    if (wasEmpty) {
      // İşaret durumu ([x]) hedefe UYGULANMAZ: hedef yerinde kalır, yerinde
      // işaretlenmesi "işaretsizler başta" değişmezini bozardı.
      first = first.substring(_lineMarker.firstMatch(first)?.end ?? 0);
    }
    // İşaretsiz ve işaretli satırlar AYRI toplanır: "işaretsizler _items'ın
    // başında" değişmezi (sürükle-sırala buna dayanıyor) karışık yapıştırmada
    // da korunmalı — hepsi tek konuma basılsaydı işaretli satır işaretsiz
    // bloğun ortasına girerdi.
    final unchecked = <NoteItem>[];
    final checkedRest = <NoteItem>[];
    for (var i = 1; i < lines.length; i++) {
      final match = _lineMarker.firstMatch(lines[i]);
      final body = lines[i].substring(match?.end ?? 0);
      if (body.trim().isEmpty) continue;
      final checked =
          widget.showCheckboxes &&
          match?.group(1) != null &&
          match!.group(1)!.toLowerCase() == 'x';
      (checked ? checkedRest : unchecked).add(
        NoteItem(id: _uuid.v4(), text: body, checked: checked),
      );
    }
    setState(() {
      _items[index] = _items[index].copyWith(text: first);
      if (unchecked.isNotEmpty) {
        final at = (widget.showCheckboxes && _items[index].checked)
            ? _uncheckedInsertIndex(_uncheckedCount)
            : index + 1;
        _items.insertAll(at, unchecked);
      }
      if (checkedRest.isNotEmpty) {
        // İşaretliler işaretli bloğun başına girer (işaretsizlerin sonu).
        _items.insertAll(_checkedStart, checkedRest);
      }
    });
    // Alanın kendisi hâlâ çok satırlı metni gösteriyor; ilk satıra indirilir.
    final controller = _controllers[target.id];
    if (controller != null && controller.logicalText != first) {
      controller.setLogical(first, first.length);
    }
    _commit();
    // Donanım Enter'ı (kalan satırlar boş): yeni boş madde aç — yazılım
    // klavyesindeki "İleri" ile aynı davranış.
    if (unchecked.isEmpty && checkedRest.isEmpty && lines.length > 1) {
      _insertAfter(target);
      return;
    }
    final focusTarget = unchecked.isNotEmpty
        ? unchecked.last
        : (checkedRest.isNotEmpty ? checkedRest.last : null);
    if (focusTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFor(focusTarget).requestFocus();
      });
    }
  }

  /// İşaretli bloğun EN ÜSTÜ (= ilk işaretlinin konumu). İşaretlenen öğe
  /// buraya girer; en son işaretlenen en üstte durur.
  int get _checkedStart {
    final first = _items.indexWhere((i) => i.checked);
    return first < 0 ? _items.length : first;
  }

  /// Listedeki işaretsiz öğe sayısı.
  int get _uncheckedCount {
    if (!widget.showCheckboxes) return _items.length;
    var count = 0;
    for (final i in _items) {
      if (!i.checked) count++;
    }
    return count;
  }

  /// İŞARETSİZ bloğun [position]'ıncı sırasına denk gelen [_items] ekleme
  /// konumu. [position] blok uzunluğuna eşitse öğe bloğun sonuna girer.
  ///
  /// Sayarak bulunur, "işaretsizler başta" düzenine GÜVENİLMEZ: liste
  /// dışarıdan bozuk sırayla gelmiş olabilir (bkz. [normalizeItems]). Düzen
  /// bozukken bile ekranda görülen sıra işaretsizlerin KENDİ aralarındaki
  /// sırasıdır; ekleme de o sıraya göre yapılmalı.
  int _uncheckedInsertIndex(int position) {
    if (!widget.showCheckboxes) {
      return position.clamp(0, _items.length);
    }
    var seen = 0;
    var afterLast = 0;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].checked) continue;
      if (seen == position) return i;
      seen++;
      afterLast = i + 1;
    }
    return afterLast;
  }

  /// İşareti yeni değişmiş öğeler: id → YERLEŞİMDE kullanılacak eski durum.
  ///
  /// İşaretli öğeler listenin footer'ında ayrı bir blokta durduğundan, işaret
  /// anında değişirse satır bir widget ağacından diğerine taşınır; taşınan
  /// widget'ın State'i yeniden yaratıldığı için hiçbir geçiş animasyonu
  /// oynayamaz. Çözüm: görünüm hemen değişsin (solma oynar), YERLEŞİM kısa
  /// bir süre eski blokta kalsın, animasyon bitince gerçek yerine taşınsın.
  final _settling = <String, bool>{};

  static const _settleDuration = Duration(milliseconds: 220);

  /// Öğe hangi blokta çizilsin: yerleşiyorsa eski durumu, değilse gerçeği.
  bool _placedAsChecked(NoteItem item) => _settling[item.id] ?? item.checked;

  /// İşaretlenen öğenin işaretlenmeden ÖNCEKİ sırası ve işaretlenme anı —
  /// [kUncheckRestoreWindow] içinde geri alınırsa öğe oraya döner.
  final _checkedFrom = <String, ({int index, DateTime at})>{};

  void _toggleItem(NoteItem target, bool? value) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    final wasChecked = _items[index].checked;
    final nowChecked = value ?? false;
    // Metni BOŞ öğe işaretlenemez: yeni açılan "Yeni öğe" satırının kutusuna
    // yanlışlıkla dokunmak, içi boş bir maddeyi işaretlilerin arasına
    // indiriyordu — ne silinebilir bir iş, ne okunur bir satır. İşareti geri
    // almak da gerekmesin diye kutucuk hiç tepki vermez.
    if (nowChecked && _items[index].text.trim().isEmpty) return;
    if (nowChecked && !wasChecked) {
      // Eski sıra ŞİMDİ saklanmalı: işaret anında öğe listede yer değiştirir.
      _checkedFrom[target.id] = (index: index, at: DateTime.now());
    }
    setState(() {
      _items[index] = _items[index].copyWith(checked: nowChecked);
      _settling[target.id] = wasChecked;
    });
    _commit();
    Future<void>.delayed(_settleDuration, () {
      if (!mounted) return;
      setState(() {
        _settling.remove(target.id);
        final current = _items.indexWhere((i) => i.id == target.id);
        if (current < 0) return;
        final item = _items.removeAt(current);
        if (item.checked) {
          _items.insert(_checkedStart, item);
          return;
        }
        final memory = _checkedFrom.remove(item.id);
        _items.insert(
          _uncheckedInsertIndex(
            uncheckRestoreIndex(
              uncheckedCount: _uncheckedCount,
              rememberedIndex: memory?.index,
              sinceChecked: memory == null
                  ? null
                  : DateTime.now().difference(memory.at),
            ),
          ),
          item,
        );
      });
      _commit();
    });
  }

  void _insertAfter(NoteItem after) {
    final index = _items.indexWhere((i) => i.id == after.id);
    if (index < 0) return;
    final item = NoteItem(id: _uuid.v4(), text: '');
    // İşaretli maddeden (footer bloğu) Enter: yeni İŞARETSİZ öğe işaretli
    // bloğun ortasına giremez — "işaretsizler _items'ın başında" değişmezi
    // bozulur ve sürükle-sırala görünenden BAŞKA öğeyi taşırdı. Yeni öğe
    // işaretsizlerin sonuna girer.
    final at = (widget.showCheckboxes && after.checked)
        ? _uncheckedInsertIndex(_uncheckedCount)
        : index + 1;
    setState(() => _items.insert(at, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  /// Başlıktaki klavye "İleri" tuşu buraya düşer (liste notunda gövde alanı
  /// yok): ilk işaretsiz maddeye odaklanır, hiç madde yoksa yeni açar.
  void focusFirstItem() {
    for (final item in _items) {
      if (!item.checked) {
        _focusFor(item).requestFocus();
        return;
      }
    }
    _addItem();
  }

  /// "Yeni öğe" düğmesiyle öğe ekler; işaretsizlerin SONUNA girer — düğme
  /// zaten işaretsiz bloğun hemen altında durur.
  void _addItem() {
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(_uncheckedInsertIndex(_uncheckedCount), item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  void _removeItem(NoteItem target) {
    setState(() => _items.removeWhere((i) => i.id == target.id));
    _disposeRowFor(target.id);
    _checkedFrom.remove(target.id);
    _commit();
  }

  /// Satırın denetleyici/odak kaynaklarını bırakır; önce biçim çubuğuna
  /// haber verir (bkz. [ItemsEditor.onFieldDisposed]).
  void _disposeRowFor(String id) {
    final controller = _controllers.remove(id);
    if (controller != null) {
      widget.onFieldDisposed?.call(controller);
      controller.dispose();
    }
    _focusNodes.remove(id)?.dispose();
    _focusFlags.remove(id)?.dispose();
  }

  /// İşaretli tüm öğeleri tek seferde siler (madde 18 — Keep'teki gibi
  /// tek tek silmeye gerek kalmaz).
  void _deleteChecked() {
    final removed = [
      for (final i in _items)
        if (i.checked) i,
    ];
    if (removed.isEmpty) return;
    setState(
      () => _items = [
        for (final i in _items)
          if (!i.checked) i,
      ],
    );
    for (final item in removed) {
      _disposeRowFor(item.id);
      _checkedFrom.remove(item.id);
    }
    _commit();
  }

  void _toggleSelection(NoteItem item) {
    setState(() {
      if (!_selected.remove(item.id)) _selected.add(item.id);
    });
    _syncBar();
  }

  /// Tümünü seç / seçimi bırak. Çubuk artık altta sabit olduğundan uzun
  /// listede tek dokunuşla hepsini kopyalamak mümkün.
  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((i) => i.id));
      }
    });
    _syncBar();
  }

  /// Seçili maddeleri liste sırasıyla panoya kopyalar. Metinler
  /// [stripRichMarkers]'tan geçer: biçimli madde panoya `**süt al**` diye
  /// işaretli gitmesin (Note.toPlainText ile aynı kural).
  Future<void> _copySelected() async {
    final buffer = StringBuffer();
    var order = 1;
    for (final item in _items) {
      if (!_selected.contains(item.id)) continue;
      final text = stripRichMarkers(item.text);
      if (widget.showCheckboxes) {
        buffer.writeln('${item.checked ? '[x]' : '[ ]'} $text');
      } else {
        buffer.writeln('${order++}. $text');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  void _deleteSelected() {
    final removed = [
      for (final i in _items)
        if (_selected.contains(i.id)) i,
    ];
    if (removed.isEmpty) return;
    setState(() {
      _items = [
        for (final i in _items)
          if (!_selected.contains(i.id)) i,
      ];
      _selected.clear();
      _selectMode = false;
    });
    _syncBar();
    for (final item in removed) {
      _disposeRowFor(item.id);
    }
    _commit();
  }

  /// Sürükle-bırak sonucu. Gelen indeksler EKRANDAKİ (sürüklenebilir) listeye
  /// aittir; [_items] ise işaretli ve "yerleşmekte olan" öğeleri de taşır.
  ///
  /// KÖK NEDEN (kullanıcı: "sıralamayı değiştiremiyorum iptal oluyor"):
  /// eskiden bu iki indeks BİREBİR aynı sayılıyordu ("işaretsizler _items'ın
  /// başında" değişmezine dayanarak). Değişmez bozulduğu anda (bkz.
  /// [normalizeItems]) sürüklenen satır yerine listedeki BAŞKA bir madde
  /// taşınıyordu: ekranda sürüklenen satır eski yerine geri dönüyor, hareket
  /// "iptal oldu" gibi görünüyordu. Artık eşleme öğenin kendisi üzerinden
  /// yapılır ve görünmeyen öğeler kendi konumlarında kalır.
  void _reorder(int oldIndex, int newIndex) {
    final visible = _visibleItems();
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex.clamp(0, visible.length), moved);
    setState(() {
      var next = 0;
      _items = [
        for (final item in _items)
          if (_isVisibleRow(item)) visible[next++] else item,
      ];
    });
    _commit();
  }

  /// Satır sürüklenebilir listede mi çiziliyor (işaretliler footer'da ayrı
  /// blokta durur, sıraları sabittir).
  bool _isVisibleRow(NoteItem item) =>
      !widget.showCheckboxes || !_placedAsChecked(item);

  /// Sürüklenebilir listenin gösterdiği öğeler — `itemBuilder` ile AYNI sıra.
  List<NoteItem> _visibleItems() => [
    for (final i in _items)
      if (_isVisibleRow(i)) i,
  ];

  /// Tüm not içeriğini panoya kopyalar ("Tümünü seç" seçeneği — ayrı
  /// TextField'lar arası gerçek seçim mümkün olmadığından pratik karşılığı).
  ///
  /// [ItemsEditor.wholeNoteText] verildiyse o kullanılır: "Tüm notu kopyala"
  /// başlığı ve serbest gövde metnini de içermeli — eskiden yalnız maddeler
  /// kopyalanıyor, karışık notta üstteki paragraf sessizce düşüyordu.
  Future<void> _copyAll() async {
    String text;
    final whole = widget.wholeNoteText?.call();
    if (whole != null && whole.trim().isNotEmpty) {
      text = whole.trim();
    } else {
      final buffer = StringBuffer();
      for (var i = 0; i < _items.length; i++) {
        final line = stripRichMarkers(_items[i].text);
        if (widget.showCheckboxes) {
          buffer.writeln('${_items[i].checked ? '[x]' : '[ ]'} $line');
        } else {
          buffer.writeln('${i + 1}. $line');
        }
      }
      text = buffer.toString().trim();
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.allCopied)));
    }
  }

  /// Öğe metni seçim araç çubuğu. Varsayılan araçlar (kes/kopyala/yapıştır ve
  /// "Tümünü seç") olduğu gibi korunur — böylece bir satırın metninin TAMAMI
  /// seçilebilir (madde 8; eskiden "Tümünü seç" seçim yerine panoya kopyalıyor,
  /// gerçek seçim ise kaldırılmıştı). Ayrıca ayrı bir "Tüm notu kopyala"
  /// seçeneği eklenir (alanlar arası gerçek seçim mümkün olmadığından tüm
  /// notu panoya almak için pratik karşılık).
  Widget _contextMenu(
    BuildContext context,
    EditableTextState editableState,
    NoteItem item,
  ) {
    final l10n = context.l10n;
    final buttonItems = <ContextMenuButtonItem>[
      // Kes/Kopyala temiz-metin sürümü: varsayılanlar biçim işaretlerini ve
      // sarma çapalarını panoya HAM yazıyordu (gövdeyle aynı gerekçe).
      ...cleanClipboardMenuItems(editableState),
      // Biçim (kalın/italik/altı çizili/renk) — gövde metniyle aynı yol.
      if (!editableState.textEditingValue.selection.isCollapsed)
        ContextMenuButtonItem(
          label: l10n.formatMenu,
          onPressed: () {
            editableState.hideToolbar();
            final controller = _controllerFor(item);
            showFormatSheet(
              context,
              controller: controller,
              onApplied: () => _updateText(item, controller.logicalText),
            );
          },
        ),
      ContextMenuButtonItem(
        label: l10n.copyWholeNote,
        onPressed: () {
          editableState.hideToolbar();
          _copyAll();
        },
      ),
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  /// Tek öğe satırı. [reorderIndex] verilirse satır sürüklenebilir;
  /// footer'daki işaretli öğelerde tutamak yoktur (sıraları zaten sabit).
  /// [orderNumber] sıralı listede gösterilen numaradır.
  /// Satır widget'larının önbelleği: madde kimliği → (anahtar, widget).
  ///
  /// KÖK NEDEN (kasma — "kasma birikip artıyor"): liste `shrinkWrap: true` ile
  /// bir `SingleChildScrollView`'ın içinde. `ShrinkWrappingViewport` kendi
  /// boyunu bulmak için BÜTÜN çocukları kurmak zorunda, yani 60 maddelik bir
  /// notta ekranda 8 satır görünse bile 60 `TextField` + 60 `EditableText`
  /// **her build'de** yeniden kuruluyor ve yeniden yerleşiyordu. Editörün her
  /// yeniden kurulumunun bedeli madde sayısıyla doğru orantılıydı.
  ///
  /// Çözüm önbellek: girdileri değişmemiş satır için AYNI widget örneği
  /// döndürülür. Flutter `updateChild`te birebir aynı widget'ı görünce alt
  /// ağacı hiç kurmaz — ve kurulmayan bir `RenderObject` "kirli"
  /// işaretlenmediği için `layout()` da erken döner. Yani hem yeniden kurulum
  /// hem yerleşim kalkar.
  ///
  /// Yan etki (bilerek): `_FloatRow.build` içindeki kare-sonu ölçüm planlaması
  /// da yalnız satır GERÇEKTEN değiştiğinde kuruluyor; eskiden her build'de
  /// satır sayısı kadar geri çağrı sıraya giriyordu.
  ///
  /// TUZAK: önbellekteki widget ESKİ `NoteItem` örneğini kapanışlarında
  /// tutuyor. Güvenli, çünkü satır geri çağrılarının hepsi (`_updateText`,
  /// `_toggleItem`, `_removeItem`, `_insertAfter`, `_toggleSelection`) öğeyi
  /// KİMLİĞİYLE arıyor, nesne kimliğiyle değil.
  final Map<String, (Object, Widget)> _rowCache = {};

  /// Önbelleği tümden geçersiz kılan LİSTE DÜZEYİ girdiler.
  Object? _rowCacheEnv;
  List<FloatBox> _rowCacheFloats = const [];

  /// Satır düzeyi girdiler değişmediyse önbellekten döndürür.
  Widget _cachedItemRow(
    NoteItem item, {
    int? reorderIndex,
    int? orderNumber,
  }) {
    // Kayıt (record) yapısal eşitlik kullanır — hash çakışması yok, yani
    // bayat satır dönme riski de yok.
    final key = (
      item.text,
      item.checked,
      reorderIndex,
      orderNumber,
      _selected.contains(item.id),
    );
    final hit = _rowCache[item.id];
    if (hit != null && hit.$1 == key) return hit.$2;
    final row = _itemRow(
      item,
      reorderIndex: reorderIndex,
      orderNumber: orderNumber,
    );
    _rowCache[item.id] = (key, row);
    return row;
  }

  /// Liste düzeyi bir girdi değiştiyse önbelleği tümden düşürür; silinen
  /// maddelerin bayat girdilerini de ayıklar.
  void _syncRowCache(ThemeData theme, AppLocalizations l10n) {
    final env = (
      theme.colorScheme,
      widget.textStyle,
      widget.richTheme,
      widget.showCheckboxes,
      widget.expandItems,
      _selectionMode,
      l10n.localeName,
      widget.contentInsertion,
    );
    if (env != _rowCacheEnv || !sameFloatList(_rowCacheFloats, widget.floats)) {
      _rowCache.clear();
      _rowCacheEnv = env;
      // Bantlar YERİNDE değişebiliyor (görsel sürüklenirken aynı liste
      // güncelleniyor); kopyası saklanır, yoksa karşılaştırma hep eşit çıkar.
      _rowCacheFloats = List.of(widget.floats);
      return;
    }
    if (_rowCache.length > _items.length) {
      final live = {for (final i in _items) i.id};
      _rowCache.removeWhere((id, _) => !live.contains(id));
    }
  }

  Widget _itemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final baseStyle =
        widget.textStyle ?? theme.textTheme.bodyLarge ?? const TextStyle();
    final checked = widget.showCheckboxes && item.checked;
    final selected = _selected.contains(item.id);
    // Odak durumu SATIRIN KENDİ dinleyicisinden gelir (bkz. [_focusFlags]).
    _focusFor(item);
    final focusFlag = _focusFlagFor(item.id);

    // Sürükleme tutamacı YALNIZ "Seç" modunda görünür.
    //
    // Normalde her satırın başında duran 6 nokta yer kaplıyor, metni içeri
    // itiyor ve ne işe yaradığı görünmüyordu (sürüklemek için ayrıca uzun
    // basmak gerekiyordu). Seç modu zaten "satırlarla toplu iş yap" kipi;
    // sıralama da oraya taşındı. Orada uzun basış SEÇİM demek olduğundan
    // tutamaç gecikmesiz sürükler (ReorderableDragStartListener) ve seçim
    // jestlerinin DIŞINDA durur — üstüne dokunmak öğeyi seçmez.
    final dragHandle = (reorderIndex != null && _selectionMode)
        ? ReorderableDragStartListener(
            index: reorderIndex,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 2),
              child: Icon(
                Icons.drag_indicator,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          )
        : null;

    // Sol bölge (kutucuk/numara). Uzun basış seçim modunu açar: metin alanına
    // uzun basmak Android'in kendi metin seçimini açtığı için madde seçimi
    // buraya bağlandı, ikisi çakışmaz.
    final leading = GestureDetector(
      onLongPress: () => _toggleSelection(item),
      onTap: _selectionMode ? () => _toggleSelection(item) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            )
          else if (widget.showCheckboxes)
            Checkbox(
              value: item.checked,
              // Boş satırın kutusu PASİF: dokunulunca hiçbir şey olmadığını
              // görmek, işaretlenip alta düşen boş bir maddeyi geri almaktan
              // iyidir (bkz. _toggleItem). Zaten işaretliyse etkin kalır ki
              // eski notlardaki boş işaretli satır geri alınabilsin.
              onChanged: (item.text.trim().isEmpty && !item.checked)
                  ? null
                  : (value) => _toggleItem(item, value),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${orderNumber ?? 0}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );

    Widget rowBody(bool focused) => Container(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // İşaretleme geçişi: satır sertçe sönmek yerine yumuşak solar.
      // Kutucuğun kendi tik animasyonu Material'dan geliyor; buradaki solma
      // ona eşlik eder. Üstü çizili hâl anında gelir — çizgi kısmi çizilemez,
      // yarım çizgi animasyonu için satırı yeniden çizmek gerekirdi.
      child: AnimatedOpacity(
        opacity: checked ? 0.55 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Row(
          children: [
            ?dragHandle,
            leading,
            Expanded(
              // Seçim modunda metne dokunmak düzenlemeye değil seçime gider.
              child: GestureDetector(
                onTap: _selectionMode ? () => _toggleSelection(item) : null,
                child: AbsorbPointer(
                  absorbing: _selectionMode,
                  child: _wrapped(
                    controller,
                    baseStyle,
                    Builder(
                      builder: (context) {
                        // Solma AnimatedOpacity'e bırakıldı (aşağıya bak);
                        // burada alfa verilirse iki kez soluyor.
                        final fieldStyle = checked
                            ? baseStyle.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant,
                              )
                            : baseStyle;
                        final field = TextField(
                          controller: controller,
                          focusNode: _focusFor(item),
                          onChanged: (_) =>
                              _updateText(item, controller.logicalText),
                          contextMenuBuilder: (context, editableState) =>
                              _contextMenu(context, editableState, item),
                          contentInsertionConfiguration:
                              widget.contentInsertion,
                          // Varsayılan "next" davranışı odağı metin dışı bir
                          // öğeye taşıyıp klavyeyi kapatıp açıyordu;
                          // onEditingComplete onu bastırır, odak doğrudan
                          // yeni öğeye geçer.
                          onEditingComplete: () => _insertAfter(item),
                          textInputAction: TextInputAction.next,
                          // Tam göster modunda satır sarılıp büyür; "dokununca
                          // aç" modunda odaklanınca açılır, aksi hâlde tek satır.
                          maxLines: widget.expandItems || focused ? null : 1,
                          // Sarma planı bu stille hesaplanır; TextField'ın örtük
                          // varsayılanına bırakılırsa ölçüm ile çizim ayrışır ve
                          // satırlar yanlış kırılır (M3 varsayılanı bodyLarge).
                          style: fieldStyle,
                          decoration: InputDecoration(
                            hintText: l10n.newItemHint,
                            filled: false,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        );
                        // Tek satır kipinde taşan metnin "devamı var"
                        // göstergesi: TextField kırpar ama üç nokta koyamaz
                        // (kaydırılabilir alan), kullanıcı metnin bittiğini
                        // sanıyordu. Taşma ölçülür, taşıyorsa alanın hemen
                        // sağına "…" konur; odaklanınca satır zaten açılır.
                        //
                        // KÖK NEDEN (imleç görünmüyordu) — ağacın ŞEKLİ
                        // odakla DEĞİŞMEMELİ: eskiden odaksızken
                        // `LayoutBuilder > Row > Expanded > TextField`,
                        // odaklanınca çıplak `TextField` dönüyordu. Dokunuş
                        // odağı verir, gelen yeniden çizimde alanın öğesi
                        // BAŞKA bir konuma düştüğü için TextField'ın state'i
                        // (ve içindeki EditableText) sıfırdan kuruluyordu;
                        // yeni state odağı ZATEN almış bir düğümle açıldığı
                        // için "odak değişti" olayı hiç gelmiyor ve imlecin
                        // yanıp sönme zamanlayıcısı başlamıyordu — imleç
                        // ancak ilk harfte beliriyordu. Yalnız "tam göster"
                        // (odaktan bağımsız) sarmalayıcıyı belirler; odak
                        // artık yalnız "…"in görünürlüğünü değiştirir.
                        if (widget.expandItems) return field;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final overflowing =
                                !focused &&
                                constraints.maxWidth.isFinite &&
                                _overflowsLine(
                                  context,
                                  item.id,
                                  controller.text,
                                  fieldStyle,
                                  constraints.maxWidth,
                                );
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(child: field),
                                if (overflowing)
                                  Text(
                                    '…',
                                    style: fieldStyle.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Silme "x" yalnızca satır odaklıyken görünür: kaydırırken ya
            // da yazarken yanlışlıkla basılmaz (madde 11-12). Odaksızken
            // yerini boş bir kutu tutar ki satırlar yatayda zıplamasın.
            if (focused && !_selectionMode)
              IconButton(
                tooltip: l10n.removeItem,
                icon: const Icon(Icons.close, size: 18),
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                onPressed: () => _removeItem(item),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: _floatRow(
        id: item.id,
        // Satırın metne AYRILAMAYAN payı: yatay dolgu + tutamaç + kutucuk/
        // numara + sil düğmesinin yeri. Sarma kararı bu pay düşülerek
        // verilmeli (bkz. _FloatRow.reserved).
        reserved:
            _kRowPadding +
            (dragHandle == null ? 0 : _kHandleWidth) +
            _kLeadingWidth +
            _kTrailingWidth,
        // Odak DEĞİŞİMİ yalnız bu satırı yeniden çizer (bkz. [_focusFlags]).
        // Sarmalayıcı KOŞULSUZ duruyor: ağacın şekli odakla değişemez —
        // değişirse TextField'ın state'i sıfırdan kurulur ve imleç ilk harfe
        // kadar yanıp sönmez (aşağıdaki kök neden notu).
        ValueListenableBuilder<bool>(
          valueListenable: focusFlag,
          builder: (context, focused, _) => rowBody(focused),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final showChecks = widget.showCheckboxes;
    // Satır önbelleğinin liste düzeyi girdileri (bkz. [_rowCache]).
    _syncRowCache(theme, l10n);

    // Checklist'te işaretli öğeler sürüklenebilir listenin DIŞINDA, footer'da
    // ayrı bir blok olarak durur (Keep'in "tamamlananlar" bölümü gibi).
    // Böylece "Yeni öğe" düğmesi tam istenen yere — işaretsizlerin altına,
    // işaretlilerin üstüne — doğal olarak düşer.
    // Blok seçimi _placedAsChecked ile yapılır: işareti yeni değişen öğe,
    // solma animasyonu bitene kadar eski bloğunda kalır (bkz. _settling).
    final checkedItems = showChecks
        ? [
            for (final i in _items)
              if (_placedAsChecked(i)) i,
          ]
        : const <NoteItem>[];
    // Sürüklenebilir liste ile [_reorder]'ın eşlemesi AYNI süzgeçten geçmeli.
    final listItems = _visibleItems();

    // "Yeni öğe" ve "Seç" BURADA DEĞİL, ekranın dibine demirlenmiş çubukta
    // (bkz. [_addBar]) — kullanıcı isteği 2026-08-09: "seç ve yeni öğe hep
    // görülmeli, sayfanın neresinde olursak olalım". Footer'da oldukları
    // sürece elli maddelik bir notta madde eklemek için önce dibe kadar
    // kaydırmak gerekiyordu.
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in checkedItems) _itemRow(item),
        if (checkedItems.isNotEmpty)
          _floatRow(
            reserved: _kButtonRowWidth,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: TextButton.icon(
                onPressed: _deleteChecked,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(l10n.deleteChecked(checkedItems.length)),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    final list = ReorderableListView.builder(
      // Alt dolgu, altta sabit duran seçim çubuğunun son maddeyi örtmemesi
      // için seçim modunda büyür.
      padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      header: widget.header,
      footer: footer,
      itemCount: listItems.length,
      // İşaretsizler _items'ın başında tutulduğundan (bkz. _checkedStart)
      // buradaki index'ler _items index'leriyle birebir örtüşür.
      onReorderItem: _reorder,
      onReorderStart: (_) => _reordering = true,
      onReorderEnd: (_) {
        _reordering = false;
        _stopAutoScroll();
        // Sürükleme sırasında ertelenen dış güncelleme varsa şimdi uygulanır
        // (bkz. [_adoptIncomingItems]). `_reorder` bu çağrıdan ÖNCE koştuğu
        // için kullanıcının taşıması kaybolmaz: yeni sıra zaten kaydedildi,
        // gelen liste ondan farklıysa gerçekten dışarıdan bir değişiklik var
        // demektir.
        if (_adoptDeferred) {
          _adoptDeferred = false;
          _adoptIncomingItems();
        }
      },
      itemBuilder: (context, index) => _cachedItemRow(
        listItems[index],
        reorderIndex: index,
        orderNumber: index + 1,
      ),
    );

    // Kenar kaydırması yalnız shrinkWrap kipinde elle yürütülür; normal kipte
    // ReorderableListView'ın kendi otomatik kaydırıcısı zaten çalışıyor.
    final scrollableList = widget.shrinkWrap
        ? Listener(
            onPointerMove: (event) => _autoScrollTo(event.position),
            onPointerUp: (_) => _stopAutoScroll(),
            onPointerCancel: (_) => _stopAutoScroll(),
            child: list,
          )
        : list;

    // Seçim çubuğu ekranın dibinde, kaydırmadan bağımsız bir katmanda durur:
    // liste nerede olursa olsun "Kopyala" hep parmağın altındadır.
    //
    // Geri tuşu seçim kipini KAPATIR, notu değil: kullanıcı yanlışlıkla seçim
    // moduna girince telefonun geri tuşu editörden atıyordu. Aynı kural ana
    // ekranda da geçerli (bkz. dashboard_screen).
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: OverlayPortal(
        controller: _barController,
        overlayChildBuilder: (context) =>
            _selectionMode ? _selectionBar(context) : _addBar(context),
        child: scrollableList,
      ),
    );
  }

  /// Ekranın dibine demirlenmiş **"Yeni öğe" / "Seç"** çubuğu.
  ///
  /// Seçim çubuğuyla AYNI konumda ve aynı katmanda; ikisi birbirini dışlar
  /// (bkz. [_barController]). Odak İSTEMEZ: düğmeye dokunmak yazılan
  /// maddenin odağını düşürseydi klavye kapanır, hemen ardından yeni madde
  /// odağı isteyince tekrar açılır ve ekran zıplardı.
  Widget _addBar(BuildContext context) {
    final l10n = context.l10n;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8 + keyboard + systemBar,
      child: TextFieldTapRegion(
        child: Focus(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          // ŞERİT YOK (kullanıcı isteği 2026-08-09: "yeni öğe ve seç bir
          // satır kaplamamalı, sadece butonlar olacak, şeriti olmasın"):
          // önce tam genişlikte bir kart vardı ve altındaki maddeyi örten
          // kalın bir bant gibi duruyordu. Artık yalnız iki küçük düğme;
          // aralarındaki alan boş ve DOKUNUŞ GEÇİRİR (`IgnorePointer` değil,
          // Row'un kendisi saydam) — arkadaki maddeye dokunulabilir.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _floatingAction(
                context,
                icon: Icons.add,
                label: l10n.newItemHint,
                onTap: _addItem,
              ),
              // Toplu kopyalama/silme girişi. Uzun basış hâlâ çalışıyor ama
              // görünmez olduğundan bulunamıyordu.
              if (_items.isNotEmpty)
                _floatingAction(
                  context,
                  icon: Icons.checklist,
                  label: l10n.select,
                  onTap: () {
                    setState(() => _selectMode = true);
                    _syncBar();
                  },
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  /// Sayfanın üstünde yüzen tek düğme: kendi küçük zemini var (metnin
  /// üzerinde okunur kalsın diye) ama satır kaplamaz.
  ///
  /// `TextButton.icon` KALIYOR (elle çizilmiş bir InkWell değil): görünüm
  /// düğmenin `style`ıyla veriliyor, böylece dokunma hedefi ve erişilebilirlik
  /// anlamı Material'ın kendisinden geliyor.
  Widget _floatingAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
        foregroundColor: scheme.onSurface,
        iconColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Ekranın dibine demirlenmiş seçim çubuğu (Overlay çocuğu). Klavye
  /// açıkken onun üstüne çıkar; sistem gezinme çubuğunun altında kalmaz.
  Widget _selectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // `MediaQuery.of` DEĞİL: o, MediaQuery'nin HERHANGİ bir alanı değişince
    // (yönelim, metin ölçeği, erişilebilirlik…) çubuğu yeniden kurar. Çubuğun
    // ihtiyacı yalnız iki ölçü.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;
    final hasSelection = _selected.isNotEmpty;
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8 + keyboard + systemBar,
      child: Material(
        color: scheme.primaryContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                icon: const Icon(Icons.close, size: 20),
                onPressed: _exitSelection,
              ),
              Expanded(
                child: Text(
                  l10n.itemsSelected(_selected.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.selectAllItems,
                icon: Icon(
                  allSelected ? Icons.deselect : Icons.select_all,
                  size: 20,
                ),
                onPressed: _items.isEmpty ? null : _toggleSelectAll,
              ),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: hasSelection ? _copySelected : null,
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: scheme.error,
                onPressed: hasSelection ? _deleteSelected : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayfadaki görsellerin bandına denk gelen liste satırını görselin yanına
/// kaydırır (soldaki görsel → sağa iter, sağdaki görsel → sola daraltır).
/// Konum yerleşimden SONRA ölçülür; dolgu satırın DIŞINDAN uygulandığı için
/// ölçüm kendi kendini beslemez (ölçülen kutu her zaman tam genişliktir).
///
/// Satırın METNİNE okunur bir genişlik kalmıyorsa yana kaydırma bırakılır ve
/// satır görselin ALTINA itilir — gövde metnindeki "satırı boşalt"
/// davranışının liste karşılığı.
class _FloatRow extends StatefulWidget {
  const _FloatRow({
    required this.floats,
    required this.pageBox,
    required this.child,
    this.reserved = 0,
    this.initial,
    this.onMeasured,
  });

  final List<FloatBox> floats;
  final RenderBox? Function() pageBox;

  /// Satırın metne AYRILAMAYAN payı (tutamaç + kutucuk + sil düğmesi +
  /// dolgu). Kalan yer ölçülürken düşülür.
  ///
  /// KÖK NEDEN (madde: "bir görsel yazıları sıkıştırdığında tek harf tek
  /// satıra kadar daralıyor"): eskiden "yer kaldı mı" kararı satırın TAMAMI
  /// üzerinden veriliyordu. Liste satırının ~140 dp'si sabit kontrollere
  /// gidiyor; görsel satırın üçte ikisini kaplayınca satırın kendisi eşiği
  /// geçiyor ama METNE bir-iki karakterlik yer kalıyordu — metin dikey bir
  /// harf sütununa dönüşüp satırı ekran boyu uzatıyordu.
  final double reserved;

  /// Ölçüm gelene kadarki başlangıç kaydırması (komşu satırın değeri).
  final ({double start, double end, double top})? initial;

  /// Ölçüm sonucu — çağıran, sonraki satırlara tahmin olarak verir.
  final ValueChanged<({double start, double end, double top})>? onMeasured;

  final Widget child;

  @override
  State<_FloatRow> createState() => _FloatRowState();
}

/// Bir madde satırının metnine bırakılacak en az genişlik (dp) — yaklaşık
/// 8-10 karakter. Bundan darına sıkışan metin harf harf kırılır.
const double _kMinRowTextWidth = 72;

class _FloatRowState extends State<_FloatRow> {
  late double _start = widget.initial?.start ?? 0;
  late double _end = widget.initial?.end ?? 0;
  late double _top = widget.initial?.top ?? 0;

  /// Bu kare için ölçüm zaten sıraya girdi mi. Satır bir karede birden çok
  /// kez kurulabiliyor (odak, seçim, tema); her kuruluşta ayrı bir kare-sonu
  /// geri çağrısı biriktirmenin anlamı yok — hepsi aynı sonucu ölçer.
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    // Bant yoksa ve dolgular zaten sıfırsa ölçülecek bir şey de yok: madde
    // listelerinin ezici çoğunluğu (görselsiz notlar) buradan bedelsiz geçer.
    final idle = widget.floats.isEmpty && _start == 0 && _end == 0 && _top == 0;
    if (!_scheduled && !idle) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    return Padding(
      // BİLEREK FİZİKSEL (Directional DEĞİL): bu boşluklar sayfaya konmuş
      // yüzen görsellerin ÖLÇÜLEN x koordinatlarından hesaplanıyor
      // (bkz. text_wrap.dart). Yönlü karşılığına çevrilirse RTL'de metin
      // görselin bulunmadığı tarafa kaçar — sarma tam ters yerde olur.
      padding: EdgeInsets.only(left: _start, right: _end, top: _top),
      child: widget.child,
    );
  }

  void _measure() {
    _scheduled = false;
    if (!mounted) return;
    // Son görsel silindi: dolguları sıfırla, ölçüme hiç girme.
    if (widget.floats.isEmpty) {
      if (_start != 0 || _end != 0 || _top != 0) {
        widget.onMeasured?.call((start: 0, end: 0, top: 0));
        setState(() {
          _start = 0;
          _end = 0;
          _top = 0;
        });
      }
      return;
    }
    final box = context.findRenderObject();
    final page = widget.pageBox();
    if (box is! RenderBox || !box.hasSize || page == null || !page.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: page);
    final width = box.size.width;
    // Kesişme HER ZAMAN satırın itilmemiş bandıyla ölçülür: kutu kendi üst
    // dolgusunu da içerdiğinden `box.size.height` kullanmak, itildikçe bandı
    // büyütür, büyüyen bant daha çok görsele değer ve satır sonsuza dek
    // aşağı kaçardı. `_top` çıkarılınca ölçüm itmeden bağımsız ve kararlı.
    final bottom = origin.dy + box.size.height - _top;
    var start = 0.0;
    var end = 0.0;
    for (final f in widget.floats) {
      if (f.bottom <= origin.dy || f.top >= bottom) continue;
      final left = f.left - origin.dx;
      final right = f.right - origin.dx;
      if (right <= 0 || left >= width) continue;
      // Satır görselin GENİŞ tarafına geçer (metin sarmasıyla aynı kural).
      if (width - right >= left) {
        if (right > start) start = right;
      } else {
        final pad = width - left;
        if (pad > end) end = pad;
      }
    }
    var top = 0.0;
    // Metne kalan yer: satırın sabit kontrolleri (tutamaç/kutucuk/sil) düşülür.
    // Eşik, gövde metnindeki kuralın (sütunun dörtte biri) metin payına
    // uygulanmış hâli; çok dar sütunlarda da okunur bir taban bırakılır.
    final textWidth = width - start - end - widget.reserved;
    final minTextWidth = math.max(
      _kMinRowTextWidth,
      (width - widget.reserved) * 0.25,
    );
    if (textWidth < minTextWidth) {
      // Yana kaçacak yer yok. Gövde metninde bu durumda satır boşaltılır ve
      // metin görselin ALTINA iner (text_wrap.dart `_kMinUsableFraction`);
      // liste maddesinde karşılığı satırı aşağı itmektir. Eskiden satır pes
      // edip görselin altında kalıyordu.
      start = 0;
      end = 0;
      for (final f in widget.floats) {
        if (f.bottom <= origin.dy || f.top >= bottom) continue;
        if (f.right - origin.dx <= 0 || f.left - origin.dx >= width) continue;
        final push = f.bottom - origin.dy;
        if (push > top) top = push;
      }
    }
    widget.onMeasured?.call((start: start, end: end, top: top));
    if ((start - _start).abs() > 0.5 ||
        (end - _end).abs() > 0.5 ||
        (top - _top).abs() > 0.5) {
      setState(() {
        _start = start;
        _end = end;
        _top = top;
      });
    }
  }
}
