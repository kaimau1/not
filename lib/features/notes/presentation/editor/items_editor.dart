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
    return -maxStep * ((top + effective - pointerY) / effective).clamp(0.0, 1.0);
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

  /// Seçim çubuğunu ekranın DİBİNE demirleyen katman denetleyicisi.
  /// Çubuk eskiden listenin header'ındaydı ve listeyle birlikte kayıyordu:
  /// uzun bir listede aşağıdaki maddeleri seçtikten sonra kopyalamak için
  /// başa dönmek gerekiyordu. Overlay'e taşınınca çubuk sayfa neresinde
  /// olursa olsun görünür kalır (madde 1).
  final _barController = OverlayPortalController();

  void _syncBar() {
    if (_selectionMode) {
      if (!_barController.isShowing) _barController.show();
    } else if (_barController.isShowing) {
      _barController.hide();
    }
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
    _items = List.of(widget.items);
  }

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
    // Gelen liste yerelden farklıysa benimse. ESKİDEN yalnızca kimliklerin
    // TAMAMEN değiştiği durumda yenileniyordu; dikte/hesap makinesi/AI bir
    // öğe eklediğinde eski kimlikler durduğundan koşul tutmuyor ve eklenen
    // öğe ekranda HİÇ görünmüyordu (editörden çıkıp girince beliriyordu).
    //
    // Yerel yazımda döngü riski yok: onChanged çağıran taraf durumu aynı
    // karede günceller, dönen liste yerelle birebir aynı olur ve buradaki
    // karşılaştırma false kalır.
    if (!_sameItems(_items, widget.items)) {
      setState(() => _items = List.of(widget.items));
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
    // silme "x" düğmesinin görünürlüğü değişir; her iki durumda çiz.
    node.addListener(() {
      if (!mounted) return;
      if (node.hasFocus) {
        final controller = _controllerFor(item);
        widget.onFieldFocused?.call(
          controller,
          node,
          () => _updateText(item, controller.logicalText),
        );
      }
      setState(() {});
    });
    return node;
  });

  void _commit() => widget.onChanged(List.of(_items));

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
  Widget _floatRow(Widget child, {String? id, double reserved = 0}) {
    final pageBox = widget.pageBox;
    if (pageBox == null || widget.floats.isEmpty) return child;
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
            ? _checkedStart
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

  /// İşaretsizlerin bittiği (= ilk işaretlinin başladığı) konum. Hem yeni
  /// öğe hem de işareti değişen öğe buraya girer:
  /// - işaretlenen öğe → işaretli bloğun EN ÜSTÜne (en son işaretlenen üstte)
  /// - işareti kalkan öğe → işaretsizlerin sonuna
  int get _checkedStart {
    final first = _items.indexWhere((i) => i.checked);
    return first < 0 ? _items.length : first;
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
          uncheckRestoreIndex(
            uncheckedCount: _checkedStart,
            rememberedIndex: memory?.index,
            sinceChecked: memory == null
                ? null
                : DateTime.now().difference(memory.at),
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
        ? _checkedStart
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

  /// "Yeni öğe" düğmesiyle öğe ekler; işaretsizlerin sonuna girer.
  void _addItem() {
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(_checkedStart, item));
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

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _commit();
  }

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
  Widget _itemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final baseStyle =
        widget.textStyle ?? theme.textTheme.bodyLarge ?? const TextStyle();
    final checked = widget.showCheckboxes && item.checked;
    final focused = _focusFor(item).hasFocus;
    final selected = _selected.contains(item.id);

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

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: _floatRow(
        id: item.id,
        // Satırın metne AYRILAMAYAN payı: yatay dolgu + tutamaç + kutucuk/
        // numara + sil düğmesinin yeri. Sarma kararı bu pay düşülerek
        // verilmeli (bkz. _FloatRow.reserved).
        reserved: _kRowPadding + (dragHandle == null ? 0 : _kHandleWidth) +
            _kLeadingWidth + _kTrailingWidth,
        Container(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : null,
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
                            if (widget.expandItems || focused) return field;
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                if (!constraints.maxWidth.isFinite) {
                                  return field;
                                }
                                final painter = TextPainter(
                                  text: TextSpan(
                                    text: controller.text,
                                    style: fieldStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: Directionality.of(context),
                                  textScaler: MediaQuery.textScalerOf(context),
                                )..layout();
                                final overflowing =
                                    painter.width > constraints.maxWidth - 14;
                                painter.dispose();
                                if (!overflowing) return field;
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Expanded(child: field),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final showChecks = widget.showCheckboxes;

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
    final listItems = showChecks
        ? [
            for (final i in _items)
              if (!_placedAsChecked(i)) i,
          ]
        : _items;

    final addButton = _floatRow(
      reserved: _kButtonRowWidth,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.newItemHint),
            ),
            const Spacer(),
            // Toplu kopyalama/silme girişi. Uzun basış hâlâ çalışıyor ama
            // görünmez olduğundan bulunamıyordu.
            if (!_selectionMode && _items.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectMode = true);
                  _syncBar();
                },
                icon: const Icon(Icons.checklist, size: 20),
                label: Text(l10n.select),
              ),
          ],
        ),
      ),
    );

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addButton,
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
      },
      itemBuilder: (context, index) => _itemRow(
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
        overlayChildBuilder: _selectionBar,
        child: scrollableList,
      ),
    );
  }

  /// Ekranın dibine demirlenmiş seçim çubuğu (Overlay çocuğu). Klavye
  /// açıkken onun üstüne çıkar; sistem gezinme çubuğunun altında kalmaz.
  Widget _selectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;
    final hasSelection = _selected.isNotEmpty;
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8 + media.viewInsets.bottom + media.viewPadding.bottom,
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
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
    if (!mounted) return;
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
