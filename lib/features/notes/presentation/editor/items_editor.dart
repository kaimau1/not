import '../../../../app/window_class.dart';
import '../../../../core/widgets/back_closes.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/haptics.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart' show PointerDeviceKind, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderFlex, RenderParagraph;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../core/a11y/motion.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/tips.dart';
import '../../../../core/widgets/frame_loop.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/utils/link_text.dart' show findLinks;
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../domain/note_item.dart';
import '../../domain/note_share_text.dart';
import '../item_divider_style.dart';
import 'format_menu.dart';
import 'note_package.dart';
import 'selection_toolbar.dart';
import 'auto_spell.dart';
import 'spell_underline.dart';
import 'tag_chips.dart';
import 'tag_tap.dart';
import 'text_wrap.dart';
import 'notebook_paper.dart' show RuledAnchor;
import 'stylus_toggle.dart' show StylusGutter;
import 'windowed_body.dart' show kWindowedCaretMargin, selectWordAt, windowedFieldStyle;

part 'items_editor_lazy.dart';
part 'items_editor_row.dart';
part 'items_editor_actions.dart';
part 'items_editor_widgets.dart';
part 'items_editor_helpers.dart';
part 'items_editor_build.dart';

/// Yanlışlıkla işaretlenen öğenin "hemen geri alındı" sayıldığı süre.
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
    this.columns = 1,
    this.expandItems = true,
    this.header,
    this.footer,
    this.floats = const [],
    this.floatsListenable,
    this.pageBox,
    this.shrinkWrap = false,
    this.contentInsertion,
    this.richTheme,
    this.textStyle,
    this.onFieldFocused,
    this.wholeNoteText,
    this.onFieldDisposed,
    this.attachmentNames = const [],
    this.tagLooks = const {},
    this.onAttachmentTag,
    this.selectionMenu,
    this.videoTimestamps = false,
    this.onVideoTimestamp,
    this.onEmbedVideo,
    this.addRowTrailing,
    this.paperLines = false,
    this.onMoveToPage,
    this.onMakeTask,
    this.onLineReminder,
    this.lineTrailing,
    this.onItemChecked,
  });

  /// DEFTER (çizgili kâğıt) görünümü: satırlar defter çizgilerine oturacak
  /// şekilde dizilir — dikey dolgu yok (madde satırı = satır sayısı × satır
  /// aralığı) ve kutucuk tek satırın bandına sığar (bkz. `RuledLines`).
  final bool paperLines;

  /// Madde menüsündeki "Başka sayfaya taşı" (notun birden çok sayfası
  /// varken). null = seçenek yok.
  final ValueChanged<NoteItem>? onMoveToPage;

  /// Madde menüsündeki "Görev yap" (TAKVIM F50.3); null = seçenek yok.
  final ValueChanged<NoteItem>? onMakeTask;

  /// Madde menüsündeki "Hatırlat": satıra bağlı hatırlatıcı (2026-11-08).
  final ValueChanged<NoteItem>? onLineReminder;

  /// Satırın sonunda (yıldızın solunda) bağlı görev/hatırlatıcı çipi.
  final Widget Function(NoteItem item)? lineTrailing;

  /// Kullanıcı maddeyi işaretledi/kaldırdı (bağlı görev eşlemesi).
  final void Function(NoteItem item, bool checked)? onItemChecked;

  /// "+ Yeni öğe" satırının SAĞ ucundaki ek düğme (editörde: notta hem metin
  /// hem liste varken "bölümler" menüsü — listeyi ya da metni kaldır).
  final Widget? addRowTrailing;

  /// Notta video var mı: varsa madde metnindeki "1:23" damgaları bağlantı
  /// gibi çizilir ve dokununca [onVideoTimestamp] çağrılır.
  final bool videoTimestamps;
  final ValueChanged<int>? onVideoTimestamp;

  /// Madde metnindeki YouTube bağlantısına dokunulunca "Nota göm" seçeneği
  /// (bkz. `handleLinkTap`); null = yalnız açılır.
  final ValueChanged<String>? onEmbedVideo;

  final List<NoteItem> items;
  final ValueChanged<List<NoteItem>> onChanged;
  final bool showCheckboxes;

  /// Maddelerin kaç SÜTUNDA dizileceği: 1 (varsayılan) ya da 2
  /// (kullanıcı isteği 2026-08-16: "liste modunda 2 kolon modu").
  ///
  /// İki sütunda SÜRÜKLEYEREK SIRALAMA KAPALIDIR. `ReorderableListView` tek
  /// eksende çalışıyor; iki sütunlu bir ızgarada "araya bırak" hedefi
  /// belirsiz (sağ sütunun üçüncü satırı, sıradaki hangi indeks?) ve yanlış
  /// hesaplanan tek bir indeks bütün listeyi karıştırırdı. Sıralama gerekince
  /// tek sütuna dönülür; menüdeki "Maddeleri sırala" iki sütunda da çalışır.
  final int columns;

  /// Sayfadaki görsellerin kapladığı bantlar (sayfa uzayı): madde metni
  /// bunların etrafından akar. Boşsa satırlar sıradan davranır.
  final List<FloatBox> floats;

  /// Bantların CANLI kaynağı (editör, 2026-11-24): verilince [floats] yok
  /// sayılır; bant değişince liste ve satırlar KURULMAZ — yalnız ölçen
  /// katmanlar (`_FloatRow`, `WrapFieldMeasure`) yeniden ölçer. KÖK NEDEN
  /// (kullanıcı bulgusu "notlar açılıp kapanırken, klavye açılıp kapanırken
  /// kasma/donma"): yüzen tablo olan 380 maddelik notta her bant değişimi
  /// editörün kökünü + bütün satırları baştan kuruyordu.
  final ValueListenable<List<FloatBox>>? floatsListenable;

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

  /// Metne gömülü EK ETİKETLERİNİN adları (bkz. attachment_tag.dart).
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu 2026-09-01: "ek bağlama … ataç işareti
  /// geliyor ama tamamen işlevsiz, altı çizilmiyor, basınca bir şey
  /// olmuyor").** Etiketi kırmızı + altı çizili çizen ve dokunuşu eke
  /// bağlayan yol yalnız GÖVDE alanında kuruluydu: editör listeyi
  /// `_bodyController.attachmentNames` ile besliyor, madde satırlarının
  /// denetleyicilerine hiçbir şey vermiyordu. Liste notunda ("Buraya bağla"
  /// bir MADDE metnine uygulandığında) etiket düz yazı olarak kalıyor,
  /// tıklanacak bir şey de olmuyordu — kullanıcının gördüğü tam olarak buydu.
  final List<String> attachmentNames;

  /// Gömülü yazıların ÇİP görünümü (gövdeyle aynı — bkz.
  /// `AttachmentTagChips`). Boşsa eski kırmızı görünüm.
  final Map<String, TagLook> tagLooks;

  /// [tagLooks]'tan satır denetleyicilerinin istediği renk haritası.
  Map<String, Color> get _tagChipColors => {
    for (final e in tagLooks.entries) e.key: e.value.color,
  };

  /// Bir madde satırındaki ek etiketine dokunuldu: [fileName] etiketin
  /// taşıdığı ad (bağ etiketi ya da dosya adı). Eki açmak editörün işi —
  /// görüntüleyiciler ve düzenleme geri çağrıları orada.
  final void Function(String fileName)? onAttachmentTag;

  /// Madde satırının seçim menüsünü EDİTÖR kurar — gövdeyle AYNI seçenekler
  /// ve AYNI sıra (ek göm, etiket önizle/düzenle/kaldır, bağlantıyı aç,
  /// biçim; bkz. `arrangeSelectionMenu`). [own] madde editörünün kendi
  /// seçenekleri (Tüm notu kopyala), menünün sonuna eklenir. [commit] alanın
  /// metnini nota işler. null ise yalnız madde editörünün kendi menüsü.
  final Widget Function(
    EditableTextState state,
    WrapTextController controller,
    VoidCallback commit,
    List<ContextMenuButtonItem> own,
  )?
  selectionMenu;

  @override
  State<ItemsEditor> createState() => ItemsEditorState();
}

class ItemsEditorState extends State<ItemsEditor>
    with SingleTickerProviderStateMixin {
  /// Konu dosyalarındaki uzantılar (`items_editor_*.dart`) için `setState`:
  /// korumalı üye uzantıdan doğrudan çağrılamaz (editördeki `_update`).
  void _update(VoidCallback fn) => setState(fn);

  /// Notun vurgusu (kartla AYNI kural, bkz. [NoteAccent]): kutucuk, "Yeni
  /// madde" ve ayırıcı bundan çizilir. build'de en yakın [NoteAccent]'ten
  /// okunur; yoksa (başka ekran, test) temanın vurgusu.
  NoteAccent? _accent;

  static const _uuid = Uuid();

  /// Madde metninin bir satır boyu (sarma katmanlarının ortak eşiği).
  static double itemLineHeight(BuildContext context, TextStyle style) =>
      MediaQuery.textScalerOf(context).scale(style.fontSize ?? 16) *
      (style.height ?? 1.3);

  /// Tek satır kipinde satır başına son taşma ölçümü (metin + genişlik +
  /// punto ile birlikte).
  final _overflowCache =
      <String, ({String text, double width, double fontSize, bool value})>{};

  /// Bant içinde ölçen satırlar (bkz. [_remeasureRows]).
  final Set<_FloatRowState> _floatRowStates = {};

  /// Son yeniden ölçümdeki liste geometrisi (yükseklik + madde sırası).
  Object? _layoutSig;
  bool _layoutCheckQueued = false;

  final Map<String, (Object, Widget)> _rowCache = {};
  Object? _rowCacheEnv;
  bool _rowCacheInline = false;
  final Map<String, _RowSlot> _slotCache = {};

  /// Liste düzeyi bir girdi değiştiyse önbelleği tümden düşürür; silinen
  /// maddelerin bayat girdilerini de ayıklar.
  void _syncRowCache(ThemeData theme, AppLocalizations l10n) {
    // WEB VE TABLETTE sürükleme tutamağı HEP görünür (kullanıcı isteği
    // 2026-11-08: "solda boşluk var yeterince"); telefonda yalnız Seç'te.
    _pinHandles = !WindowClass.of(context).compactDevice;
    final env = (
      _pinHandles,
      theme.colorScheme,
      // Notun vurgusu (rengi değişince kutucuklar yeniden çizilsin).
      _accent?.accent,
      _accent?.background,
      widget.textStyle,
      widget.richTheme,
      widget.showCheckboxes,
      widget.expandItems,
      // Defter görünümü dolguyu ve kutu boyunu değiştiriyor.
      widget.paperLines,
      _selectionMode,
      l10n.localeName,
      widget.contentInsertion,
      // Çip görünümü İÇERİKLE anahtarlanır: harita her kurulumda yeni nesne
      // (kimlikle karşılaştırılsa önbellek her karede boşalırdı).
      Object.hashAll([
        for (final e in widget.tagLooks.entries) Object.hash(e.key, e.value),
      ]),
    );
    // Bantların KONUMU önbelleği düşürmez (satırlar bildiriciyle ölçer);
    // yalnız metne sarılan kutunun var/yok geçişi (gerçek alan ↔ düz çizim).
    if (env != _rowCacheEnv || _rowCacheInline != _inlineFloats) {
      _rowCache.clear();
      _rowCacheEnv = env;
      _rowCacheInline = _inlineFloats;
      return;
    }
    if (_rowCache.length > _items.length) {
      final live = {for (final i in _items) i.id};
      _rowCache.removeWhere((id, _) => !live.contains(id));
      _slotCache.removeWhere((id, _) => !live.contains(id));
    }
  }

  late List<NoteItem> _items;
  final _controllers = <String, WrapTextController>{};
  final _focusNodes = <String, _LazyFocusNode>{};

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

  /// Geniş ekranda (web, tablet) tutamak seçim kipi dışında da görünür.
  bool _pinHandles = false;

  /// Satırda sürükleme tutamağı yuvası var mı.
  bool get _showHandles => _selectionMode || _pinHandles;

  /// Seçim çubuğunu ekranın DİBİNE demirleyen katman denetleyicisi.
  ///
  /// Çubuk eskiden listenin header'ındaydı ve listeyle birlikte kayıyordu:
  /// uzun bir listede aşağıdaki maddeleri seçtikten sonra kopyalamak için
  /// başa dönmek gerekiyordu. Overlay'e taşınınca çubuk sayfa neresinde
  /// olursa olsun görünür kalır.
  ///
  /// Katmanda YALNIZ seçim çubuğu var. Bir ara "Yeni öğe" ve "Seç" de yüzen
  /// düğmeler olarak buraya alınmıştı; ekranın dibindeki alt paneli (ek şeridi
  /// + alt çubuk) örttüğü için geri alındı (kullanıcı isteği 2026-08-09: "seç
  /// burada olsun, yeni öğe eski yerinde"). Artık "Seç" alt çubuğun bir
  /// segmenti (bkz. note_editor_screen `_selectToolButton` → [startSelection]),
  /// "Yeni öğe" ise yine listenin footer'ında.
  final _barController = OverlayPortalController();

  /// Çubuk yalnız seçim kipinde görünür.
  void _syncBar() {
    if (_selectionMode) {
      if (!_barController.isShowing) _barController.show();
    } else if (_barController.isShowing) {
      _barController.hide();
    }
  }

  /// Alt çubuktaki "Seç" segmentinin girişi (bkz. note_editor_screen).
  /// Liste boşken seçilecek bir şey yok, kip açılmaz.
  /// NOT İÇİ ARAMANIN taradığı madde alanları, EKRANDAKİ sırayla
  /// (işaretsizler önce — bkz. [_items] düzeni). Satırı henüz KURULMAMIŞ
  /// madde de dahil (2026-11-09 düzeltme: uzun listede ekran dışındaki
  /// maddeler aranmıyordu, sayaç eksik çıkıyordu): denetleyici şimdi
  /// oluşturulur, satır kurulunca aynısını kullanır (vurgu üstünde hazır);
  /// eşleşmeye gidiş [revealFocus] ile satırı kurdurur.
  List<({String id, WrapTextController controller, FocusNode focus})>
  searchFields() => [
    for (final item in _items)
      (id: item.id, controller: _controllerFor(item), focus: _focusFor(item)),
  ];

  void startSelection() {
    if (_items.isEmpty || _selectionMode) return;
    // Yazılan satırın odağı bırakılır: klavye kapanır, alttaki seçim
    // çubuğu klavyenin üstünde asılı kalmaz ve dokunuşlar düzenlemeye değil
    // seçime gider.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectMode = true);
    _syncBar();
    TipOnce.showDeferred(
      context,
      TipOnce.itemHoldSelect,
      () => context.l10n.tipItemHoldSelect,
      icon: Icons.checklist_rounded,
    );
  }

  /// Madde alanlarına yapılan son dokunuşun konumu (bkz. [_tapAttachmentTag]).
  final _tapPoint = TapPointTracker();

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
    _floatsL.addListener(_onFloats);
    _inlineFloats = _hasInlineFloats(_floatsL.value);
    _adoptedFrom = widget.items;
    _items = _adopt(widget.items);
    if (_items.length > _kFirstRows) {
      _rowBudget = _kFirstRows;
      _budgetTimer = Timer(_kGrowAfter, _growBudget);
    }
  }

  /// **UZUN LİSTEDE KADEMELİ KURULUM.** Dış sayfa kaydırıcısının içinde liste
  /// tembel değil. Satır düz çizim olsa da (bkz. [_LazyItemField]) 100 satır
  /// geçişin ilk karesinde 100+ ms (telefonda ölçüldü, 2026-11-04) → ilk karede
  /// ekranı dolduran kadarı, geçiş (460 ms) bitince kalanı kare başına birkaç.
  ///
  /// **Kare başına 2 değil, büyüyen adım (2026-11-11, F60.S5 yan bulgusu).**
  /// Her adım `setState` → sürüklenebilir listenin BÜTÜN satır sarmalayıcıları
  /// (`_ReorderableItem`, `KeepAlive`, `KeyedSubtree` — satır başına ≈ 7)
  /// yeniden kurulur; maliyet satır sayısıyla büyür. 120 maddede 2'şerlik
  /// adım 52 kare × 367→1039 kurulum (≈ 35 bin) sürüyordu ve erken dokunuşta
  /// klavye açılışına denk geliyordu. Adım = mevcut bütçenin yarısı,
  /// [_kRowsPerFrame]–[_kMaxRowsPerFrame] arası: 120 maddede 11 kare, kare
  /// başı 833 → 1393, toplam ≈ 12 bin (`test/items_grow_budget_test.dart`).
  /// Klavye hareket ederken ([KeyboardInset.moving]) adım atılmaz, bekler.
  static const _kFirstRows = 16;
  static const _kRowsPerFrame = 4;
  static const _kMaxRowsPerFrame = 8;
  static const _kGrowAfter = Duration(milliseconds: 500);
  static const _kGrowRetry = Duration(milliseconds: 120);

  /// Kurulacak en çok madde (işaretsizler önce, sonra işaretliler); null = hepsi.
  int? _rowBudget;
  Timer? _budgetTimer;

  void _growBudget() {
    _budgetTimer = null;
    final budget = _rowBudget;
    if (!mounted || budget == null) return;
    if (KeyboardInset.moving.value) {
      // Klavye açılıp kapanırken kare bütçesi klavyenin: sonra devam.
      _budgetTimer = Timer(_kGrowRetry, _growBudget);
      return;
    }
    setState(() {
      final next = budget + (budget ~/ 2).clamp(_kRowsPerFrame, _kMaxRowsPerFrame);
      _rowBudget = next >= _items.length ? null : next;
    });
    if (_rowBudget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _growBudget());
    }
  }

  /// **İŞARETLİLER 10'AR** (kullanıcı isteği 2026-11-03: "çok işaretli
  /// maddesi olan notlar kasıyor; belli sayının üzerindeki işaretliler
  /// gizlensin, 'işaretlileri göster' ile her basışta 10 tanesi yüklensin,
  /// not kapanınca da kapansın"). İşaretli blokta ilk [_kCheckedStep] madde
  /// kurulur; kalanı ağaçta HİÇ yok (kurulum, ölçüm, sarma maliyeti yok).
  /// Durum yalnız bu açılışa ait — not yeniden açılınca yine 10.
  static const _kCheckedStep = 10;
  int _checkedShown = _kCheckedStep;
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
  /// Kenar kaydırma döngüsü — ilk sürüklemede kurulur (dispose'ta tembel
  /// kurulum bağlam araması yapardı).
  FrameLoop? _autoScroll;

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
    (_autoScroll ??= FrameLoop(_autoScrollTick, vsync: this)).start();
  }

  /// Kenar kaydırmasının bir karesi (F2.2: vsync'e bağlı; adım 60 Hz
  /// karesine göre ölçeklenir, 120 Hz'de de aynı hız).
  void _autoScrollTick(double scale) {
    final position = _outerScroll?.position;
    if (position == null || !position.hasContentDimensions) {
      _stopAutoScroll();
      return;
    }
    final target = (position.pixels + _autoScrollStep * scale).clamp(
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
    _autoScroll?.stop();
    _autoScrollStep = 0;
  }

  @override
  void didUpdateWidget(covariant ItemsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floatsListenable != widget.floatsListenable) {
      (oldWidget.floatsListenable ?? _ownFloats)?.removeListener(_onFloats);
      _floatsL.addListener(_onFloats);
    }
    final own = _ownFloats;
    if (widget.floatsListenable == null &&
        own != null &&
        !sameFloatList(own.value, widget.floats)) {
      own.value = List.of(widget.floats);
    }
    _onFloats();
    _adoptIncomingItems();
  }

  /// Dış kaynak yoksa [ItemsEditor.floats]'tan beslenen yerel kaynak.
  ValueNotifier<List<FloatBox>>? _ownFloats;

  ValueListenable<List<FloatBox>> get _floatsL =>
      widget.floatsListenable ??
      (_ownFloats ??= ValueNotifier(List.of(widget.floats)));

  /// Metnin İÇİNE sarılan (blok olmayan) kutu var mı: yalnız o zaman madde
  /// gerçek alan olarak kurulur (sarma çapaları). Tam genişlik tablo/görsel
  /// satırı bütünüyle iter (`_FloatRow`) — hafif çizim yeter.
  bool _inlineFloats = false;

  static bool _hasInlineFloats(List<FloatBox> floats) =>
      floats.any((f) => !f.block);

  void _onFloats() {
    final next = _hasInlineFloats(_floatsL.value);
    if (next == _inlineFloats || !mounted) return;
    // Yalnız GEÇİŞTE (yok ↔ var) satırlar yeniden kurulur; konum değişimi
    // ölçen katmanlarda kalır.
    setState(() => _inlineFloats = next);
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
          a[i].checked != b[i].checked ||
          a[i].divider != b[i].divider ||
          a[i].header != b[i].header ||
          a[i].align != b[i].align ||
          a[i].package != b[i].package ||
          !sameNoteItemExtras(a[i].extras, b[i].extras)) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _floatsL.removeListener(_onFloats);
    _ownFloats?.dispose();
    _budgetTimer?.cancel();
    _autoScroll?.dispose();
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
    // Ek etiketleri gövdeyle AYNI yoldan çizilsin (bkz.
    // [ItemsEditor.attachmentNames]); setter aynı listede hiçbir şey yapmaz.
    controller.attachmentNames = widget.attachmentNames;
    controller.tagChipColors = widget._tagChipColors;
    controller.videoTimestamps = widget.videoTimestamps;
    return controller;
  }

  _LazyFocusNode _focusFor(NoteItem item) => _focusNodes.putIfAbsent(item.id, () {
    final node = _LazyFocusNode();
    // MADDE BAŞINDA GERİ SİL = ÜSTTEKİYLE BİRLEŞ (kullanıcı isteği
    // 2026-10-28: "Enter madde ekliyorsa diğer maddenin en başından geri
    // silme üst maddeyle birleştirsin"). Silinecek harf yokken klavye
    // (Gboard, donanım klavyesi) Backspace'i TUŞ olayı olarak yollar.
    final id = item.id;
    node.onKeyEvent = (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      // OK TUŞLARI (kullanıcı isteği 2026-11-08): satırın ilk/son satırında
      // ↑/↓ bir önceki/sonraki maddeye geçer.
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        return moveFocusVertically(id, up: key == LogicalKeyboardKey.arrowUp)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      }
      if (key != LogicalKeyboardKey.backspace) {
        return KeyEventResult.ignored;
      }
      return mergeIntoPrevious(id)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    };
    // Odak değişince (a) "dokununca aç" modunda satır yüksekliği, (b)
    // silme "x" düğmesinin görünürlüğü değişir; ikisi de YALNIZ o satırı
    // ilgilendirir — bu yüzden listenin tamamı değil, satırın kendi bayrağı
    // güncellenir (bkz. [_focusFlags]).
    node.addListener(() {
      if (!mounted) return;
      final controller = _controllerFor(item);
      if (node.hasFocus) {
        _lastFocusedItemId = item.id;
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

  /// Satırların son ölçülen kaydırma değerleri (id → sol/sağ dolgu). Yeni
  /// eklenen satır KOMŞUSUNUN değeriyle doğsun diye tutulur: aksi hâlde satır
  /// bir kare kaymadan çizilip sonraki karede yerine atlıyor ve madde
  /// eklerken titreme görünüyordu.
  final _pads = <String, ({double start, double end, double top})>{};

  /// Satır başındaki sürükleme tutamacının kapladığı genişlik (yalnız seçim
  /// modunda vardır).
  static const double _kHandleWidth = 22;

  /// Tutamaç simgesinin kutusu (kare): hizası bu yükseklikten hesaplanıyor
  /// (bkz. [_itemRow] → `handleTop`).
  static const double _kHandleIcon = 20;

  /// Kutucuk / seçim dairesi / sıra numarasının kapladığı genişlik.
  static const double _kLeadingWidth = 48;

  /// Sil düğmesinin (odaksızken boş kutunun) genişliği.
  static const double _kTrailingWidth = 28;

  /// Satırın iki yanındaki yatay dolgunun TOPLAMI (sol 12 + sağ 2).
  static const double _kRowPadding = 14;

  /// "Yeni öğe / Seç" ve "İşaretlileri sil" düğme satırlarının sığdığı en az
  /// genişlik. Bu satırların metni sarılamaz (düğme daralmaz); dar kalırlarsa
  /// taşarlar — o yüzden görselin yanına sıkışmak yerine ALTINA inerler.
  static const double _kButtonRowWidth = 280;

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
    // Boş maddeye tek satır "☐ süt" yapıştırıldı: paylaşım işareti metne
    // girmesin (bkz. [_lineMarker]).
    if (_items[index].text.isEmpty && RegExp(r'^\s*[☐☑☒]').hasMatch(text)) {
      text = text.substring(_lineMarker.firstMatch(text)!.end);
    }
    final wasBlank = _items[index].text.trim().isEmpty;
    _items[index] = _items[index].copyWith(text: text);
    // Boş ↔ dolu: satırın kutusu etkinleşir/pasifleşir (bkz. `_itemRow`).
    // Eskiden bunu kökün yeniden kurulumu getiriyordu; kök artık madde
    // değişikliğinde kurulmuyor (bkz. NoteEditorScreen._mutate itemsShown).
    if (wasBlank != text.trim().isEmpty) setState(() {});
    _commit();
  }

  /// `- [x]`, `-`, `•`, `3.`, `☐`/`☑` gibi liste öneklerini soyar;
  /// checklist'te işaret durumunu da okur. ☐/☑ paylaşım biçimidir (bkz.
  /// noteShareText): nottan Telegram'a kopyalayıp geri yapıştırınca işaret
  /// metinde kalıyor, bir sonraki kopyada "☐ ☐" oluyordu (2026-11-09) —
  /// art arda gelen işaretlerin HEPSİ soyulur.
  static final _lineMarker = RegExp(
    // `**` kalın işareti madde imi değil.
    r'^\s*(?:(?:[-•]|\*(?!\*))\s*)?(?:(?:\[([ xX])\]|([☐☑☒]))\s*)*(?:\d+[.)]\s+)?',
  );

  static bool _markerChecked(RegExpMatch? m) =>
      m != null &&
      ((m.group(1) ?? '').toLowerCase() == 'x' ||
          (m.group(2) != null && m.group(2) != '☐'));

  void _splitMultiline(NoteItem target, int index, String text) {
    // Donanım Enter'ı: var olan metne tek satır sonu girdi. Biçim işareti
    // ortadan kesilmesin (`**ek` / `mek**`): iki parça da kendi biçimiyle.
    final previous = _items[index].text;
    final enter = text.indexOf('\n');
    final List<String> lines;
    if (text.replaceRange(enter, enter + 1, '') == previous) {
      final (:before, :after) = splitRichText(previous, enter, enter);
      lines = [before, after];
    } else {
      lines = text.split('\n');
    }
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
      final checked = widget.showCheckboxes && _markerChecked(match);
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
        if (!mounted) return;
        _focusFor(focusTarget).requestFocus();
        // Tek Enter (donanım klavyesi) maddeyi ortadan böldü: imleç yeni
        // maddenin BAŞINA (bkz. [_enterAt]).
        if (lines.length == 2 && !wasEmpty) {
          _controllerFor(focusTarget).selection = const TextSelection.collapsed(
            offset: 0,
          );
        }
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

  /// 220 → 420 ms (kullanıcı isteği 2026-09-22: "liste maddeleri tıklanma
  /// geçiş animasyonu"): önce kutu zıplar ve çizgi akar, ardından satır
  /// yerinde katlanır; yeni yerinde açılarak belirir. Eski süre yalnız
  /// solmaya yetiyordu, satır sonra bir anda ışınlanıyordu.
  static const _settleDuration = AppMotion.long;

  /// Yeni yerine YENİ varmış öğeler: orada açılarak belirirler
  /// (bkz. [_CheckMove]). Açılma bitince listeden düşerler.
  final _arriving = <String>{};

  /// Öğe hangi blokta çizilsin: yerleşiyorsa eski durumu, değilse gerçeği.
  bool _placedAsChecked(NoteItem item) => _settling[item.id] ?? item.checked;

  /// İşaretlenen öğenin işaretlenmeden ÖNCEKİ sırası ve işaretlenme anı —
  /// [kUncheckRestoreWindow] içinde geri alınırsa öğe oraya döner.
  final _checkedFrom = <String, ({int index, DateTime at})>{};

  void addItemWithText(String text, {TextEditingController? after}) {
    NoteItem? anchor;
    if (after != null) {
      for (final entry in _controllers.entries) {
        if (!identical(entry.value, after)) continue;
        anchor = _items.where((i) => i.id == entry.key).firstOrNull;
        break;
      }
    }
    NoteItem target;
    if (anchor != null && anchor.text.trim().isEmpty) {
      target = anchor;
    } else if (anchor != null) {
      final index = _items.indexWhere((i) => i.id == anchor!.id);
      target = NoteItem(id: _uuid.v4(), text: '');
      final at = (widget.showCheckboxes && anchor.checked)
          ? _uncheckedInsertIndex(_uncheckedCount)
          : index + 1;
      setState(() => _items.insert(at, target));
    } else {
      final open = [
        for (final i in _items)
          if (!i.checked) i,
      ];
      if (open.isNotEmpty && open.last.text.trim().isEmpty) {
        target = open.last;
      } else {
        target = NoteItem(id: _uuid.v4(), text: '');
        setState(
          () => _items.insert(_uncheckedInsertIndex(_uncheckedCount), target),
        );
      }
    }
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    setState(() => _items[index] = _items[index].copyWith(text: text));
    _controllers[target.id]?.setLogical(text, text.length);
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _controllerFor(_items.firstWhere(
        (i) => i.id == target.id,
        orElse: () => target,
      ));
      _focusFor(target).requestFocus();
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  /// Odaktaki maddenin kimliği (madde odakta değilse null).
  String? get focusedItemId {
    for (final entry in _focusNodes.entries) {
      if (entry.value.hasFocus) return entry.key;
    }
    return null;
  }

  /// Çoklu seçim kipinde mi (jestler kapalı — satırlar seçer/sürüklenir).
  bool get isSelecting => _selectionMode;

  /// [controller] hangi maddenin alanı (biçim paneli hedefi → madde).
  void _addItem() {
    final open = [
      for (final i in _items)
        if (!i.checked) i,
    ];
    final trailing = trailingEmptyCount(open);
    if (trailing >= kMaxTrailingEmptyItems) {
      _focusFor(open[open.length - trailing]).requestFocus();
      return;
    }
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(_uncheckedInsertIndex(_uncheckedCount), item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  /// Boş bir ARA BAŞLIK açar ve odaklar (bkz. [NoteItem.header]).
  ///
  /// KONUM (kullanıcı isteği 2026-11-05: "ara başlığı en alta ekliyor,
  /// imlecin olduğu satırın altına yerleştirmeli"): odaktaki — düğmeye
  /// basılınca odak kaybolduysa EN SON odaklanan — işaretsiz maddenin
  /// hemen ALTINA girer; hiç odak olmadıysa işaretsizlerin sonuna. Hedef
  /// konumda zaten boş bir başlık varsa yenisi açılmaz.
  @visibleForTesting
  void addHeader() {
    final anchorId = focusedItemId ?? _lastFocusedItemId;
    var anchor = anchorId == null
        ? -1
        : _items.indexWhere((i) => i.id == anchorId && !i.checked);
    final int insertAt;
    if (anchor >= 0) {
      insertAt = anchor + 1;
    } else {
      insertAt = _uncheckedInsertIndex(_uncheckedCount);
      anchor = insertAt - 1;
    }
    // Komşu boş başlık (düğmeye iki kez basma) → ona odaklan.
    for (final i in [anchor, insertAt]) {
      if (i < 0 || i >= _items.length) continue;
      final near = _items[i];
      if (near.header && !near.checked && near.text.trim().isEmpty) {
        _focusFor(near).requestFocus();
        return;
      }
    }
    final item = NoteItem(id: _uuid.v4(), text: '', header: true);
    setState(() => _items.insert(insertAt, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  /// En son odaklanan maddenin kimliği ([addHeader] hedefi; düğmeye basmak
  /// odağı alabilir).
  String? _lastFocusedItemId;

  /// Ara başlığın hizasını değiştirir (bkz. [NoteItem.align]).
  void _setHeaderAlign(NoteItem target, String align) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0 || _items[index].align == align) return;
    _update(() => _items[index] = _items[index].copyWith(align: align));
    _commit();
  }

  /// Maddeyi ara başlığa çevirir ya da geri alır. Başlık işaretlenmez:
  /// işaretli madde başlık olunca işareti kalkar ve işaretsizlerin sonuna
  /// gelir.
  void _toggleHeader(NoteItem target) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    final current = _items[index];
    final header = !current.header;
    _update(() {
      if (header && current.checked) {
        _items.removeAt(index);
        _items.insert(
          _uncheckedInsertIndex(_uncheckedCount),
          current.copyWith(header: true, checked: false),
        );
      } else {
        _items[index] = current.copyWith(header: header);
      }
    });
    _commit();
  }

  /// İmleç maddenin EN BAŞINDAYKEN (seçim yok) maddeyi üstteki maddeye
  /// ekler: metin üstün sonuna yapışır, imleç birleşme noktasında kalır —
  /// Enter'ın [_enterAt] ile böldüğü maddeyi geri birleştirmenin yolu.
  /// İlk maddede ya da işaretli/işaretsiz sınırında hiçbir şey yapmaz
  /// (false döner; tuş klavyenin kendisine kalır).
  /// ↑ ilk satırdaysa önceki maddenin sonuna, ↓ son satırdaysa sonrakinin
  /// başına geçer. ponytail: yalnız mantıksal satıra (`\n`) bakılır; sarılmış
  /// uzun maddede görsel satırlar atlanır — gerekirse TextPainter ile ölç.
  bool moveFocusVertically(String id, {required bool up}) {
    final index = _items.indexWhere((i) => i.id == id);
    final target = index + (up ? -1 : 1);
    if (index < 0 || target < 0 || target >= _items.length) return false;
    final c = _controllers[id];
    if (c == null || !c.selection.isValid) return false;
    final caret = c.selection.extentOffset;
    final text = c.text;
    final onEdge = up
        ? !text.substring(0, caret.clamp(0, text.length)).contains('\n')
        : !text.substring(caret.clamp(0, text.length)).contains('\n');
    if (!onEdge) return false;
    final next = _items[target];
    _focusFor(next).requestFocus();
    final nc = _controllerFor(next);
    nc.selection = TextSelection.collapsed(
      offset: up ? nc.text.length : 0,
    );
    return true;
  }

  /// Şu an AÇIK not paketi (bkz. [NoteItem.package]); null = hepsi kapalı.
  String? _openPackage;

  /// Seçili maddeler (seçim modunda) ya da odaktaki madde paket olur;
  /// dağınık seçim ilk seçilenin yerinde toplanır. Zaten paketse çözülür.
  /// false = paketlenecek madde yok.
  bool togglePackage() {
    final ids = _selected.isNotEmpty
        ? {..._selected}
        : {?_lastFocusedItemId};
    final group = [
      for (final i in _items)
        if (ids.contains(i.id) && !i.header) i,
    ];
    if (group.isEmpty) return false;
    final unpack = group.every((i) => i.package.isNotEmpty);
    final pkg = unpack ? '' : const Uuid().v4().substring(0, 8);
    final changed = {
      for (final i in group) i.id: i.copyWith(package: unpack ? '' : pkg),
    };
    setState(() {
      if (unpack) {
        for (var k = 0; k < _items.length; k++) {
          final c = changed[_items[k].id];
          if (c != null) _items[k] = c;
        }
      } else {
        // Ardışık olsun: hepsi ilk maddenin yerine.
        final at = _items.indexWhere((i) => i.id == group.first.id);
        _items.removeWhere((i) => changed.containsKey(i.id));
        _items.insertAll(at, [for (final i in group) changed[i.id]!]);
      }
      _selected.clear();
      _selectMode = false;
      _openPackage = null;
      // Önbellek TEMİZLENMEZ (F60.2): satır anahtarı `item.package`'ı ve
      // sırayı içerir, değişen üyeler kendiliğinden yenilenir; temizlemek
      // görünen bütün satırları sıfırdan kuruyordu (30 maddede 20 satır).
    });
    _commit();
    return true;
  }

  @visibleForTesting
  List<NoteItem> get debugItems => List.unmodifiable(_items);

  /// Paketi çözer: maddeler yerinde kalır, paket işareti kalkar (×,
  /// kullanıcı isteği 2026-11-09: "paketten çıkarmak çok zor").
  @visibleForTesting
  void unpackGroup(String pkg) {
    if (pkg.isEmpty) return;
    setState(() {
      for (var k = 0; k < _items.length; k++) {
        if (_items[k].package == pkg) {
          _items[k] = _items[k].copyWith(package: '');
        }
      }
      if (_openPackage == pkg) _openPackage = null;
    });
    unawaited(AppHaptics.tick());
    _commit();
  }

  void _setOpenPackage(String? pkg) {
    if (_openPackage == pkg || !mounted) return;
    setState(() => _openPackage = pkg);
  }

  /// Sürüklenebilir listede [index]teki satır: paketsiz madde AYNEN; kapalı
  /// paketin ilk maddesi çerçeveli özet, kalanları sıfır yükseklik (dizinler
  /// sürüklemeyle örtüşsün diye satır yerinde kalır); açık paketin
  /// maddeleri ince kenarlı ve dışarı dokununca paket daralır.
  void _removeItem(NoteItem target) {
    setState(() => _items.removeWhere((i) => i.id == target.id));
    _disposeRowFor(target.id);
    _checkedFrom.remove(target.id);
    _commit();
  }

  /// Satırın denetleyici/odak kaynaklarını bırakır; önce biçim çubuğuna
  /// haber verir (bkz. [ItemsEditor.onFieldDisposed]).
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
  @override
  Widget build(BuildContext context) => _buildItemsEditor(context);
}
