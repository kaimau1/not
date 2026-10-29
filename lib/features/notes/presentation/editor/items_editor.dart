import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/frame_loop.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../domain/note_item.dart';
import '../../domain/note_share_text.dart';
import '../item_divider_style.dart';
import 'format_menu.dart';
import 'tag_chips.dart';
import 'tag_tap.dart';
import 'text_wrap.dart';

part 'items_editor_row.dart';
part 'items_editor_actions.dart';

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
    this.columns = 1,
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
  });

  /// DEFTER (çizgili kâğıt) görünümü: satırlar defter çizgilerine oturacak
  /// şekilde dizilir — dikey dolgu yok (madde satırı = satır sayısı × satır
  /// aralığı) ve kutucuk tek satırın bandına sığar (bkz. `RuledLines`).
  final bool paperLines;

  /// Madde menüsündeki "Başka sayfaya taşı" (notun birden çok sayfası
  /// varken). null = seçenek yok.
  final ValueChanged<NoteItem>? onMoveToPage;

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
  /// (işaretsizler önce — bkz. [_items] düzeni). Satırı henüz kurulmamış
  /// (denetleyicisi olmayan) madde atlanır: ekranda değil, vurgulanamaz.
  List<({String id, WrapTextController controller, FocusNode focus})>
  searchFields() => [
    for (final item in _items)
      if (_controllers[item.id] case final controller?)
        (id: item.id, controller: controller, focus: _focusFor(item)),
  ];

  void startSelection() {
    if (_items.isEmpty || _selectionMode) return;
    // Yazılan satırın odağı bırakılır: klavye kapanır, alttaki seçim
    // çubuğu klavyenin üstünde asılı kalmaz ve dokunuşlar düzenlemeye değil
    // seçime gider.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectMode = true);
    _syncBar();
  }

  /// [target] bu editörün satırlarından biriyse metni O SATIRA, imlecin
  /// yerine ekler ve nota işler; değilse false döner (çağıran gövdeye yazar).
  ///
  /// Sesli yakalama gibi akışlar odağı düşürdüğü için hedefi çağıran taşır
  /// (editör en son odaklanan alanı zaten biliyor — `_formatTarget`).
  bool insertTextAtCaret(TextEditingController target, String text) {
    for (final entry in _controllers.entries) {
      if (!identical(entry.value, target)) continue;
      final index = _items.indexWhere((i) => i.id == entry.key);
      if (index < 0) return false;
      final controller = entry.value;
      final logical = controller.logicalText;
      final selection = controller.selection;
      final caret = selection.isValid
          ? wrapToLogicalOffset(controller.text, selection.baseOffset)
          : logical.length;
      final result = insertAtCaret(logical, caret, text);
      if (result.text == logical) return true;
      controller.setLogical(result.text, result.caret);
      _updateText(_items[index], result.text);
      return true;
    }
    return false;
  }

  /// İmleç bir EK ETİKETİNİN üstüne düştüyse çağıranı haberdar eder.
  /// Konum önce mantıksal metne çevrilir: alanın metni sarma çapaları
  /// taşıyabiliyor ve çapalar sayılırsa etiketin sınırları kayardı.
  void _tapAttachmentTag(
    WrapTextController controller,
    BuildContext fieldContext,
  ) {
    final selection = controller.selection;
    if (!selection.isValid) return;
    // VİDEO ZAMAN DAMGASI (bkz. video_time.dart): notta video varken
    // "1:23"e dokunmak videoyu oraya sarar — gövdeyle aynı kural.
    final onTime = widget.onVideoTimestamp;
    if (onTime != null && widget.videoTimestamps) {
      final seconds = tappedVideoTimestamp(
        displayText: controller.text,
        selection: selection,
        editable: editableTextBelow(fieldContext),
        tapGlobal: _tapPoint.last,
      );
      if (seconds != null) {
        onTime(seconds);
        return;
      }
    }
    // BAĞLANTIYA DOKUNUŞ (2026-10-28): gövdeyle aynı kural — okurken açar,
    // yazarken önerir.
    final link = tappedLink(
      displayText: controller.text,
      editable: editableTextBelow(fieldContext),
      tapGlobal: _tapPoint.last,
    );
    if (link != null) {
      editableTextBelow(fieldContext)?.hideToolbar();
      handleLinkTap(
        context,
        link,
        editing: _tapPoint.wasFocused,
        onEmbedVideo: widget.onEmbedVideo,
      );
      return;
    }
    final onTag = widget.onAttachmentTag;
    if (onTag == null || widget.attachmentNames.isEmpty) return;
    // Etiketin İÇİNE dokunuş; sınırdaysa dokunuşun KONUMU etiketin
    // kutusunda mı ona bakılır (bkz. tappedAttachmentTag — son harfe
    // dokunmak imleci sınıra koyuyor, önizleme açılmıyordu).
    final editable = editableTextBelow(fieldContext);
    final tag = tappedAttachmentTag(
      logicalText: controller.logicalText,
      logicalCaret: wrapToLogicalOffset(controller.text, selection.baseOffset),
      displayText: controller.text,
      selection: selection,
      names: widget.attachmentNames,
      editable: editable,
      tapGlobal: _tapPoint.last,
    );
    if (tag == null) return;
    // Önizleme açılırken dokunuşun açtığı Yapıştır menüsü kalmasın.
    editable?.hideToolbar();
    onTag(tag.fileName);
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
    _adoptedFrom = widget.items;
    _items = _adopt(widget.items);
    if (_items.length > _kFirstRows) {
      _rowBudget = _kFirstRows;
      _budgetTimer = Timer(const Duration(milliseconds: 380), _growBudget);
    }
  }

  /// **UZUN LİSTEDE KADEMELİ İLK KURULUM** (kullanıcı bulgusu 2026-10-20:
  /// "not ilk açılırken kasma oluyor"). Editörde liste `shrinkWrap` — dış
  /// sayfa kaydırıcısının içinde olduğu için tembel değil, BÜTÜN maddeleri
  /// ilk karede kurar. 97 maddelik notta bu, rota geçişinin ilk karesinde
  /// 97 zengin metin alanı (RenderEditable + sarma ölçümü) demekti; sayfa
  /// kayarken takılıyordu. Artık ilk karede yalnız ekranı dolduran ilk
  /// [_kFirstRows] madde kurulur; geçiş bitince (≈380 ms) kalanlar kare
  /// başına [_kRowsPerFrame] madde eklenerek tamamlanır. Kurulmamış
  /// maddeler zaten ekranın altında — kullanıcı farkı görmez.
  static const _kFirstRows = 18;
  static const _kRowsPerFrame = 14;

  /// Kurulacak en çok madde sayısı (işaretsizler önce, sonra işaretliler);
  /// null = hepsi.
  int? _rowBudget;
  Timer? _budgetTimer;

  void _growBudget() {
    _budgetTimer = null;
    final budget = _rowBudget;
    if (!mounted || budget == null) return;
    setState(() {
      final next = budget + _kRowsPerFrame;
      _rowBudget = next >= _items.length ? null : next;
    });
    if (_rowBudget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _growBudget());
    }
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
          a[i].checked != b[i].checked ||
          a[i].divider != b[i].divider) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
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

  FocusNode _focusFor(NoteItem item) => _focusNodes.putIfAbsent(item.id, () {
    final node = FocusNode();
    // MADDE BAŞINDA GERİ SİL = ÜSTTEKİYLE BİRLEŞ (kullanıcı isteği
    // 2026-10-28: "Enter madde ekliyorsa diğer maddenin en başından geri
    // silme üst maddeyle birleştirsin"). Silinecek harf yokken klavye
    // (Gboard, donanım klavyesi) Backspace'i TUŞ olayı olarak yollar.
    final id = item.id;
    node.onKeyEvent = (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey != LogicalKeyboardKey.backspace) {
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

  /// Tutamaç simgesinin kutusu (kare): hizası bu yükseklikten hesaplanıyor
  /// (bkz. [_itemRow] → `handleTop`).
  static const double _kHandleIcon = 20;

  /// Kutucuk / seçim dairesi / sıra numarasının kapladığı genişlik.
  static const double _kLeadingWidth = 48;

  /// Sil düğmesinin (odaksızken boş kutunun) genişliği.
  static const double _kTrailingWidth = 40;

  /// Satırın iki yanındaki yatay dolgunun TOPLAMI (sol 12 + sağ 2).
  static const double _kRowPadding = 14;

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
  Widget _floatRow(
    Widget child, {
    String? id,
    double reserved = 0,
    bool pushOnly = false,
  }) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return child;
    return _FloatRow(
      floats: widget.floats,
      pageBox: pageBox,
      reserved: reserved,
      pushOnly: pushOnly,
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
  static const _settleDuration = Duration(milliseconds: 420);

  /// Yeni yerine YENİ varmış öğeler: orada açılarak belirirler
  /// (bkz. [_CheckMove]). Açılma bitince listeden düşerler.
  final _arriving = <String>{};

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
        _arriving.add(target.id);
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
      Future<void>.delayed(_CheckMove.arriveDuration, () {
        if (!mounted || !_arriving.remove(target.id)) return;
        setState(() {});
      });
    });
  }

  /// Klavyenin Enter/"İleri" tuşu: imleç maddenin SONUNDAYSA altına boş
  /// madde açar; ORTASINDAYSA maddeyi imleçten böler — sağdaki kısım yeni
  /// maddeye geçer ve imleç onun başına konur (kullanıcı isteği 2026-10-28:
  /// "cümlenin arasında enter yapılınca oradan itibaren bölüp yeni madde
  /// yapmalı"). İmleç başta ve madde doluysa üstüne boş madde açılır.
  void _enterAt(NoteItem target) {
    final index = _items.indexWhere((i) => i.id == target.id);
    final controller = _controllers[target.id];
    if (index < 0 || controller == null || !controller.selection.isValid) {
      _insertAfter(target);
      return;
    }
    final logical = controller.logicalText;
    final start = wrapToLogicalOffset(
      controller.text,
      controller.selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      controller.text,
      controller.selection.end,
    ).clamp(start, logical.length);
    final before = logical.substring(0, start);
    final after = logical.substring(end);
    if (after.isEmpty) {
      if (end != start) {
        // Sona kadar seçili metin Enter'la silinir (yazılan Enter gibi).
        controller.setLogical(before, before.length);
        _updateText(target, before);
      }
      _insertAfter(target);
      return;
    }
    if (before.trim().isEmpty) {
      // Baştan Enter: madde aşağı kayar, üstüne boş madde açılır; imleç
      // yerinde kalır (Keep ve kelime işlemcilerdeki gibi).
      final blank = NoteItem(id: _uuid.v4(), text: '');
      setState(() => _items.insert(index, blank));
      _commit();
      return;
    }
    final current = _items[index];
    final next = NoteItem(id: _uuid.v4(), text: after.trimLeft());
    setState(() {
      _items[index] = current.copyWith(text: before.trimRight());
      // İşaretli maddeden bölünen parça işaretsizlerin sonuna girer
      // ("işaretsizler başta" değişmezi, bkz. [_insertAfter]).
      final at = (widget.showCheckboxes && current.checked)
          ? _uncheckedInsertIndex(_uncheckedCount)
          : index + 1;
      _items.insert(at, next);
    });
    controller.setLogical(before.trimRight(), before.trimRight().length);
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextController = _controllerFor(next);
      _focusFor(next).requestFocus();
      nextController.selection = const TextSelection.collapsed(offset: 0);
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

  /// [text] ile başlayan bir madde açar ve imleci sonuna koyar (videonun
  /// "Bu ana not al" düğmesi — damga + boşluk).
  ///
  /// [after] bu editörün bir satırıysa: o satır BOŞSA damga oraya yazılır,
  /// doluysa hemen altına yeni madde açılır. Verilmezse işaretsizlerin
  /// sonundaki boş madde kullanılır, yoksa sona yeni madde eklenir — art
  /// arda basılan düğme boş satır biriktirmez.
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

  /// Maddeye odaklanır ve imleci sonuna koyar (dışarıdan eklenen madde —
  /// ör. alt çubuğun ☑ düğmesi gövde satırını maddeye çevirdiğinde).
  void focusItem(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    final controller = _controllerFor(item);
    _focusFor(item).requestFocus();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  /// **ONAY KUTUSUNU KALDIR**: maddeyi listeden çıkarır ve metnini döner
  /// (çağıran gövdeye yazar). Madde yoksa null.
  String? takeItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return null;
    final text = _items[index].text;
    _focusNodes[id]?.unfocus();
    _removeItem(_items[index]);
    return text;
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
  ///
  /// KÖK NEDEN (kullanıcı ekran görüntüsü 2026-09-23: listenin sonunda boş
  /// bir "Yeni öğe" satırı ve hemen altında "+ Yeni öğe" düğmesi): düğme her
  /// dokunuşta YENİ bir boş öğe açıyordu. Boş öğeye yazmadan başka yere
  /// dokunan ya da düğmeye iki kez basan kullanıcıda boş satırlar birikiyor,
  /// kayda da boş öğe olarak gidiyordu.
  ///
  /// SINIR 1 DEĞİL 3 (kullanıcı isteği 2026-09-26: "1'den fazla yeni boş öğe
  /// eklenebilmeli, max 3 tane"): tek boş öğe sınırı, önceden birkaç satır
  /// açıp sonra sırayla doldurmak isteyeni engelliyordu. İşaretsizlerin
  /// sonunda üst üste [kMaxTrailingEmptyItems] boş öğe varsa YENİSİ açılmaz,
  /// ilk boş olana odaklanılır — birikme yine sınırlı.
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

  /// İmleç maddenin EN BAŞINDAYKEN (seçim yok) maddeyi üstteki maddeye
  /// ekler: metin üstün sonuna yapışır, imleç birleşme noktasında kalır —
  /// Enter'ın [_enterAt] ile böldüğü maddeyi geri birleştirmenin yolu.
  /// İlk maddede ya da işaretli/işaretsiz sınırında hiçbir şey yapmaz
  /// (false döner; tuş klavyenin kendisine kalır).
  @visibleForTesting
  bool mergeIntoPrevious(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index <= 0) return false;
    final controller = _controllers[id];
    if (controller == null) return false;
    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return false;
    if (wrapToLogicalOffset(controller.text, selection.baseOffset) != 0) {
      return false;
    }
    final current = _items[index];
    final previous = _items[index - 1];
    if (widget.showCheckboxes && previous.checked != current.checked) {
      return false;
    }
    final caret = previous.text.length;
    final joined = previous.text + current.text;
    unawaited(HapticFeedback.selectionClick());
    // Odak ÖNCE üst maddeye geçer: silinen satırla birlikte odak (ve
    // klavye) bir kare için kaybolmasın.
    _focusFor(previous).requestFocus();
    _items[index - 1] = previous.copyWith(text: joined);
    _controllerFor(_items[index - 1]).setLogical(joined, caret);
    _removeItem(current);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final merged = _items.where((i) => i.id == previous.id).firstOrNull;
      if (merged == null) return;
      final c = _controllerFor(merged);
      if (c.logicalText == joined) c.setLogical(joined, caret);
    });
    return true;
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
  Widget _cachedItemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    // Kayıt (record) yapısal eşitlik kullanır — hash çakışması yok, yani
    // bayat satır dönme riski de yok.
    final key = (
      item.text,
      item.checked,
      item.starred,
      // KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "alta çizgi çek çalışmıyor,
      // defterde kararsız"): ayırıcı anahtarda yoktu — satır önbellekten
      // ESKİ hâliyle dönüyordu, çizgi ancak başka bir şey satırı yeniden
      // kurunca beliriyordu.
      item.divider,
      reorderIndex,
      orderNumber,
      _selected.contains(item.id),
      _movePhase(item.id),
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

  /// Satırın yer değiştirme evresi (bkz. [_CheckMove]).
  _MovePhase _movePhase(String id) {
    if (_settling.containsKey(id)) return _MovePhase.leaving;
    if (_arriving.contains(id)) return _MovePhase.arriving;
    return _MovePhase.idle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final showChecks = widget.showCheckboxes;
    // Satır önbelleğinin liste düzeyi girdileri (bkz. [_rowCache]).
    _syncRowCache(theme, l10n);
    // Ek listesi değişince (ek silindi/eklendi) etiketin kırmızı çizilip
    // çizilmeyeceği değişir. Satır ÖNBELLEKTEN gelebildiği için besleme
    // `_controllerFor`a bırakılamaz: denetleyici zaten var olan satırlarda o
    // işlev hiç çağrılmaz. Setter aynı listede hiçbir şey yapmaz.
    final chipColors = widget._tagChipColors;
    for (final controller in _controllers.values) {
      controller.attachmentNames = widget.attachmentNames;
      controller.tagChipColors = chipColors;
      controller.videoTimestamps = widget.videoTimestamps;
    }

    // Checklist'te işaretli öğeler sürüklenebilir listenin DIŞINDA, footer'da
    // ayrı bir blok olarak durur (Keep'in "tamamlananlar" bölümü gibi).
    // Böylece "Yeni öğe" düğmesi tam istenen yere — işaretsizlerin altına,
    // işaretlilerin üstüne — doğal olarak düşer.
    // Blok seçimi _placedAsChecked ile yapılır: işareti yeni değişen öğe,
    // solma animasyonu bitene kadar eski bloğunda kalır (bkz. _settling).
    var checkedItems = showChecks
        ? [
            for (final i in _items)
              if (_placedAsChecked(i)) i,
          ]
        : const <NoteItem>[];
    // Sürüklenebilir liste ile [_reorder]'ın eşlemesi AYNI süzgeçten geçmeli.
    var listItems = _visibleItems();
    // Kademeli ilk kurulum (bkz. [_rowBudget]): yalnız ÖNEK kurulur, yani
    // sürükleme dizinleri [_reorder]'ın eşlemesiyle yine örtüşür.
    final checkedCount = checkedItems.length;
    final budget = _rowBudget;
    if (budget != null) {
      if (listItems.length > budget) listItems = listItems.sublist(0, budget);
      final left = budget - listItems.length;
      if (checkedItems.length > left) {
        checkedItems = checkedItems.sublist(0, left);
      }
    }

    // "Yeni öğe" LİSTENİN İÇİNDE, işaretsizlerin hemen altında (eski yeri).
    // Bir tur ekranın dibinde yüzen bir düğmeye alınmıştı; oradaki alt paneli
    // (ek şeridi + alt çubuk) örttüğü için geri kondu — kullanıcı isteği
    // 2026-08-09: "seç burada olsun, yeni öğe eski yerinde". "Seç" ise alt
    // çubuğun segmenti oldu (bkz. [startSelection]); footer'da tekrarlanmaz.
    final addButton = _floatRow(
      reserved: _kButtonRowWidth,
      // DÜĞME SATIRI YANA GEÇMEZ, ALTA İNER (kullanıcı bulgusu 2026-08-10:
      // "yeni öğe + yazısı resimlerin altında kalıyor, görsel çok büyüyünce
      // oluyor"): yana kaydırma kararı metne kalan yere bakıyordu ve düğme
      // satırının metni yok — küçülemeyen 280 dp'lik sabit bir blok. Görselin
      // bandına değen her durumda satır görselin ALTINA iner; böylece düğme
      // görselin altında kalamaz, ölçüm bir piksel şaşsa bile.
      pushOnly: true,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.newItemHint),
            ),
            if (widget.addRowTrailing != null) ...[
              const Spacer(),
              widget.addRowTrailing!,
            ],
          ],
        ),
      ),
    );

    // STRETCH, start DEĞİL: `_FloatRow` kesişmeyi KENDİ genişliğinden ölçüyor
    // (bkz. [_FloatRowState._measure]). `start` hizalamada düğme satırı yalnız
    // düğme kadar genişti, yani sayfanın sağ yarısındaki bir görselle hiç
    // kesişmiyor görünüyor ve satır olduğu yerde kalıyordu. Tam genişlikte
    // ölçülünce satırın gerçekten hangi görselin bandında olduğu doğru çıkar.
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        addButton,
        // ÖNBELLEKTEN (kullanıcı bulgusu 2026-10-28: "maddeleri okundu
        // işaretleyince donma kasma"): işaretli blok `_itemRow` ile her
        // kurulumda BAŞTAN kuruluyordu — çok işaretli maddeli notta her tuş,
        // her işaret ve görsel eklenince bütün üstü çizili satırlar (metin
        // alanı, taşma ölçümü, sarma ölçümü) yeniden kuruluyordu.
        for (final item in checkedItems) _cachedItemRow(item),
        if (checkedItems.isNotEmpty)
          _floatRow(
            reserved: _kButtonRowWidth,
            pushOnly: true,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: TextButton.icon(
                onPressed: _deleteChecked,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(l10n.deleteChecked(checkedCount)),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    // İKİ SÜTUN: sürüklenebilir liste yerine iki paralel sütun. Maddeler
    // yarı yarıya bölünür (soldaki ilk yarı, sağdaki ikinci yarı) — soldan
    // sağa dizilseydi göz her maddede satır atlamak zorunda kalır, "1 2 / 3 4"
    // düzeni basılı bir listeye hiç benzemezdi.
    //
    // Satırların KENDİSİ aynı `_itemRow`: onay kutusu, yıldız, biçimli metin,
    // uzun basma menüsü ve seçim kipi tek sütundakiyle birebir aynı çalışır.
    // Yalnız sürükleme tutamağı yok (bkz. [ItemsEditor.columns]).
    if (widget.columns == 2) {
      final half = (listItems.length + 1) ~/ 2;
      final columns = <Widget>[
        for (final range in [
          (start: 0, end: half),
          (start: half, end: listItems.length),
        ])
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = range.start; i < range.end; i++)
                  _cachedItemRow(listItems[i], orderNumber: i + 1),
              ],
            ),
          ),
      ];
      final grid = ListView(
        padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : null,
        children: [
          if (widget.header != null) widget.header!,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
          footer,
        ],
      );
      return PopScope(
        canPop: !_selectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitSelection();
        },
        child: OverlayPortal(
          controller: _barController,
          overlayChildBuilder: _selectionBar,
          child: grid,
        ),
      );
    }

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
        overlayChildBuilder: _selectionBar,
        child: scrollableList,
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
    this.pushOnly = false,
    this.initial,
    this.onMeasured,
  });

  /// true ise satır görselin YANINA hiç geçmez, bandına değdiği her görselin
  /// ALTINA iner. Küçülemeyen satırlar ("Yeni öğe", "İşaretlileri sil") böyle:
  /// yana kaydırma kararı metne kalan yere bakıyor, onlarınsa metni yok.
  final bool pushOnly;

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
    if (!widget.pushOnly) {
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
    if (widget.pushOnly || textWidth < minTextWidth) {
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

/// Satır menüsünün ([ItemsEditorState._showItemMenu]) seçenekleri.
enum _ItemAction {
  star,
  select,
  delete,
  dividerSolid,
  dividerDashed,
  dividerDotted,
  dividerStyle,
  moveToPage,
}

/// Madde menüsünün tek parçalık gövdesi: üstte iş düğmeleri, altta çizgi
/// türleri (bkz. [ItemsEditorState._showItemMenu]).
class _ItemMenuPanel extends PopupMenuEntry<_ItemAction> {
  const _ItemMenuPanel({
    required this.starred,
    required this.divider,
    required this.canMove,
  });

  final bool starred;

  /// Maddenin şimdiki çizgi türü ('' = yok).
  final String divider;
  final bool canMove;

  @override
  double get height => 148;

  @override
  bool represents(_ItemAction? value) => false;

  @override
  State<_ItemMenuPanel> createState() => _ItemMenuPanelState();
}

class _ItemMenuPanelState extends State<_ItemMenuPanel> {
  void _pick(_ItemAction action) => Navigator.pop(context, action);

  Widget _action(_ItemAction action, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final danger = action == _ItemAction.delete;
    final color = danger ? scheme.error : scheme.onSurface;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(_ItemAction action, String kind, String tooltip) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.divider == kind;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _pick(action),
        child: Container(
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? scheme.secondaryContainer : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomPaint(
            painter: _LineSwatchPainter(
              kind,
              selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 248, maxWidth: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _action(
                  _ItemAction.star,
                  widget.starred ? Icons.star : Icons.star_outline,
                  widget.starred ? l10n.itemMenuUnstar : l10n.star,
                ),
                _action(_ItemAction.select, Icons.checklist, l10n.select),
                if (widget.canMove)
                  _action(
                    _ItemAction.moveToPage,
                    Icons.drive_file_move_outline,
                    l10n.itemMenuMove,
                  ),
                _action(
                  _ItemAction.delete,
                  Icons.delete_outline,
                  l10n.itemMenuDelete,
                ),
              ],
            ),
            Divider(height: 12, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 0, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.itemMenuLine,
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _line(
                    _ItemAction.dividerSolid,
                    NoteItem.dividerSolid,
                    l10n.itemDividerSolid,
                  ),
                  _line(
                    _ItemAction.dividerDashed,
                    NoteItem.dividerDashed,
                    l10n.itemDividerDashed,
                  ),
                  _line(
                    _ItemAction.dividerDotted,
                    NoteItem.dividerDotted,
                    l10n.itemDividerDotted,
                  ),
                  IconButton(
                    tooltip: l10n.dividerSettings,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tune, size: 20),
                    onPressed: () => _pick(_ItemAction.dividerStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menüdeki çizgi türü örneği (ortadan, ince).
class _LineSwatchPainter extends CustomPainter {
  _LineSwatchPainter(this.kind, this.color);

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: ItemDivider(kind),
    fallbackColor: color,
    left: 8,
    right: size.width - 8,
    y: size.height / 2,
    baseWidth: 1.8,
  );

  @override
  bool shouldRepaint(_LineSwatchPainter old) =>
      old.kind != kind || old.color != color;
}

/// Madde altı ayırıcı çizgi (bkz. [NoteItem.divider], [ItemDivider]).
class _ItemDividerPainter extends CustomPainter {
  _ItemDividerPainter(this.raw, this.color)
    : style = ItemDivider.parse(raw) ?? const ItemDivider('');

  final String raw;
  final ItemDivider style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: style,
    fallbackColor: color,
    left: 8,
    right: size.width - 8,
    // Defterde satır çizgisiyle AYNI yere düşer: ince kalırsa kesik/nokta
    // altındaki düz çizgide kaybolup "düz çizgi" gibi görünüyordu.
    y: size.height - 1,
    baseWidth: 2.2,
  );

  @override
  bool shouldRepaint(_ItemDividerPainter old) =>
      old.raw != raw || old.color != color;
}

/// Üstü çizili geçişin süresi (bkz. `_itemRow`).
const _kStrikeDuration = Duration(milliseconds: 260);

enum _MovePhase { idle, leaving, arriving }

/// İşaretlenen maddenin YER DEĞİŞTİRME geçişi.
///
/// İşaretli maddeler ayrı bir blokta (footer) durduğundan satır bir ağaçtan
/// ötekine taşınır ve arada hiçbir şey canlandırılamıyordu — madde bir anda
/// ışınlanıyordu. Geçiş iki yarıya bölündü:
/// * **leaving**: eski yerinde, işaret/çizgi animasyonuna bir süre izin
///   verildikten sonra satır dikeyde katlanır ve solar; altındakiler yukarı
///   kayar.
/// * **arriving**: yeni yerinde sıfır yükseklikten açılır, hafifçe yukarı
///   süzülerek belirir.
/// Katlanma bitince öğe gerçek yerine taşınır (bkz. `_toggleItem`), yani
/// iki yarı birbirini kesintisiz izler.
class _CheckMove extends StatefulWidget {
  const _CheckMove({required this.phase, required this.child});

  final _MovePhase phase;
  final Widget child;

  static const arriveDuration = Duration(milliseconds: 280);

  @override
  State<_CheckMove> createState() => _CheckMoveState();
}

class _CheckMoveState extends State<_CheckMove>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.phase == _MovePhase.arriving ? 0 : 1,
  );
  late Animation<double> _size = _controller;

  @override
  void initState() {
    super.initState();
    if (widget.phase == _MovePhase.arriving) _arrive();
  }

  @override
  void didUpdateWidget(_CheckMove old) {
    super.didUpdateWidget(old);
    if (old.phase == widget.phase) return;
    switch (widget.phase) {
      case _MovePhase.leaving:
        // İlk %40 satır yerinde durur: kutunun zıplaması ve çizginin akışı
        // görülsün, sonra katlanma başlasın.
        _size = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
          reverseCurve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
        );
        // Katlanma [_settleDuration] içinde bitmeli ki öğe taşındığında
        // eski yerinde boşluk kalmasın.
        _controller.reverseDuration = ItemsEditorState._settleDuration;
        _controller.reverse(from: 1);
      case _MovePhase.arriving:
        _arrive();
      case _MovePhase.idle:
        _controller.value = 1;
    }
  }

  void _arrive() {
    _size = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.duration = _CheckMove.arriveDuration;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _size,
        child: widget.phase == _MovePhase.arriving
            ? SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(_size),
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// İşaret kutusunun "zıplaması": değer DEĞİŞİNCE kutu kısa süre büyüyüp
/// yerine oturur. İlk kurulumda oynamaz.
class _CheckPop extends StatefulWidget {
  const _CheckPop({required this.value, required this.child});

  final bool value;
  final Widget child;

  @override
  State<_CheckPop> createState() => _CheckPopState();
}

class _CheckPopState extends State<_CheckPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.22,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.22,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(_CheckPop old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


/// "+ Yeni öğe" ile üst üste açılabilecek en çok boş öğe (bkz.
/// [ItemsEditorState._addItem]).
const int kMaxTrailingEmptyItems = 3;

/// [items]in SONUNDA üst üste duran boş (yalnız boşluk içeren) öğe sayısı.
int trailingEmptyCount(List<NoteItem> items) {
  var count = 0;
  for (var i = items.length - 1; i >= 0; i--) {
    if (items[i].text.trim().isNotEmpty) break;
    count++;
  }
  return count;
}
