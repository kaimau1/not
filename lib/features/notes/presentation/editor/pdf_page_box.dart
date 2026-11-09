import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/pdf_copy_text.dart';
import '../../../../core/utils/pdf_ref.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../../core/widgets/wheel_scroll_viewer.dart';
import '../../data/pdf/pdf_page_ocr.dart';
import '../../data/pdf_text.dart';
import '../../domain/attachment.dart';
import '../viewers/area_actions.dart';
import '../viewers/bubble_layer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_page_image.dart';
import '../viewers/pdf_select_layer.dart';
import '../viewers/pdf_selection_bar.dart' show PdfSelectionState;
import '../viewers/pdf_viewer_screen.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';

/// **SAYFAYA GÖMÜLÜ PDF** (kullanıcı isteği 2026-09-06: "PDF'yi sayfaya
/// entegre etme, aynı görsel gibi sayfaya yerleşir ancak sayfa
/// değiştirilebilir ve ek özellikler istiyorum").
///
/// PDF artık ek şeridinde bekleyen bir dosya değil, notun sayfasında duran
/// bir kutu: görselle birebir aynı şekilde taşınır, boyutlandırılır ve metin
/// etrafından akar ([Attachment.floatsOnPage]). Görselden tek farkı, kutunun
/// TEK bir kare değil bir BELGE göstermesi — bu yüzden kutunun kendi
/// gezinme çubuğu var.
///
/// Kutunun yaptıkları (hepsi tam ekrana geçmeden):
///  1. **Sayfa çevirme** — ‹ › düğmeleri ve kutunun üzerinde yatay kaydırma
///     (sayfalar parmağı izleyerek kayar; bkz. [_PdfPageBoxState._pager]).
///  2. **Sayfa göstergesi** — "3 / 24"; dokununca sayfaya atlama levhası.
///  3. **Küçük resimle atlama** — levhada bütün sayfaların ızgarası.
///  4. **Kaldığın sayfa kalıcı** — sayfa numarası nota yazılır, senkronlanır.
///  5. **Yer imleri** — sayfaya yer imi koy, listeden atla (uzun belgede
///     "kaldığım yerler").
///  6. **Görünümü döndürme** — yatay taranmış belgeler için; dosyaya
///     dokunmaz, yalnız kutuyu döndürür.
///  7. **Tam ekran** — aynı sayfadan açılır, dönüşte sayfa korunur.
///  8. **Sayfa metnini kopyalama** — o sayfanın metin katmanı panoya.
///  9. **Sayfayı yakalama** — sayfa görüntüsü yapay zekâya sorulur ya da
///     panoya alınır (alan seçimindeki levhanın aynısı).
/// 10. **Otomatik geçiş** — belgeyi slayt gibi ilerletir (sunum/okuma).
/// 11. **Sayfa notu göstergesi** — o sayfadaki balon/vurgu sayısı rozet
///     olarak, el yazısı katmanı da kutunun üstünde çizilir.
/// 12. **Sayfa oranına oturma** — kutunun en-boyu belgenin ilk sayfasından
///     alınır ve ekte saklanır (kare varsayımıyla ezilmiş PDF yok).
/// 13. **İlk/son sayfaya atlama**.
/// 14. **Şeride geri alma** — kutu menüsünden, görseldeki gibi.
/// **DIŞ ÇUBUK KÖPRÜSÜ** (kullanıcı isteği 2026-11-07: sabit bölmede
/// belgenin üstündeki gri sayfa şeridi "kaldır, özellikleri bir alt
/// satırla birleştir"). Verilirse [PdfPageBox] kendi yüzen şeridini
/// ÇİZMEZ; sayfa gezinme · yer imi · balon göster/gizle · belge menüsü
/// [buildControls] ile sabit bölmenin çubuğunda çizilir. Kutu durumu
/// değişince (sayfa, sayfa sayısı, yer imi…) dinleyiciler uyarılır —
/// yalnız çubuk yeniden kurulur, belge değil.
class PdfBoxBar extends ChangeNotifier {
  _PdfPageBoxState? _box;
  Object? _signature;

  /// Belge açıldı mı (çubukta denetim var mı)?
  bool get ready => _box?._doc != null;

  /// Sabit bölme çubuğuna konan denetimler ([width] çubuğun genişliği).
  List<Widget> buildControls(BuildContext context, double width) =>
      _box?._externalControls(context, width) ?? const [];

  void _attach(_PdfPageBoxState box) {
    _box = box;
    _signature = null;
  }

  void _detach(_PdfPageBoxState box) {
    if (identical(_box, box)) _box = null;
  }

  bool _disposed = false;

  void _update(Object signature) {
    if (signature == _signature) return;
    _signature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class PdfPageBox extends StatefulWidget {
  const PdfPageBox({
    this.externalBar,
    super.key,
    required this.attachment,
    required this.onChanged,
    this.controls = true,
    this.swipeToTurn = true,
    this.showBubbles = false,
    this.editBubbles = false,
    this.addingBubbles,
    this.addingPlain,
    this.onBubbleWriting,
    this.onNoteFromSelection,
    this.fitWidth = false,
    this.ink,
  });

  /// Verilirse sayfanın üstüne KALEMLE YAZILIR (sabit bölme, 2026-11-08):
  /// çizim katmanı etkileşimli; yoksa var olan çizim yalnız gösterilir.
  final InkController? ink;

  /// **OKUMA NOTU** (kullanıcı isteği 2026-11-03): verilirse sayfadaki yazı
  /// BASILI TUTARAK seçilir (Chrome'daki gibi kelime kelime büyür) ve
  /// kutunun tepesinde "Not al · Kopyala · Vurgula" çubuğu çıkar. "Not al"
  /// sayfa numarasını, seçimin sayfadaki SATIRINI ve alıntıyı verir —
  /// YouTube'da dakikaya not almak gibi (bkz. `pdf_ref.dart`). Yalnız sabit
  /// bölmede: sayfadaki yüzen kutuda basılı tutmak kutuyu taşır.
  final void Function(int page, int? line, String quote)? onNoteFromSelection;

  /// Sayfa kutunun GENİŞLİĞİNİ doldurur, boyu taşarsa sayfa dikeyde kayar
  /// (okuma kipi: dar bölmede A4 sayfanın yanlarında boşluk kalmaz, yazı
  /// büyük okunur). Kapalıyken sayfa kutuya bütünüyle sığar.
  final bool fitWidth;

  /// Belgenin BALONLARI sayfanın üstünde çizilsin mi (salt okunur: dokununca
  /// okuma kartı açılır). Kullanıcı isteği 2026-10-16: "balonludan üste
  /// sabitlemeye alınca da balonlar görülsün ama göster/gizlesi olsun" —
  /// sabit bölme açar; çubukta göster/gizle düğmesi çıkar
  /// ([Attachment.bubblesHidden]). Sayfadaki yüzen kutuda kapalı (orada
  /// dokunuş kutuyu seçer/taşır).
  final bool showBubbles;

  /// **SABİT BÖLMEDE BALONLAR HEP DÜZENLENEBİLİR** (kullanıcı bulgusu
  /// 2026-11-05: "balonlar taşınamıyor, düzenlenemiyor, silinemiyor; uzun
  /// basış metin tanıma yapıyor"). Balonlar eskiden yalnız şeritteki
  /// "Balon ekle" kipi açıkken yazılabiliyordu — şerit 2,5 sn'de söndüğü
  /// için kip görünmüyor, balon salt okunur kalıyordu. Artık ([showBubbles]
  /// ile birlikte) tutamaç basılı tutulup taşınır, okuma kartında Düzenle
  /// çıkar.
  ///
  /// JESTLER (kullanıcı kararı 2026-11-05, aynı günün "basılı tut = balon"
  /// sürümünün yerine): basılı tutmak METNİ SEÇER, çift dokunuş
  /// YAKINLAŞTIRIR, yeni balon YALNIZ "Balon ekle" düğmesiyle açılan
  /// bırakma kipinde dokunarak eklenir.
  final bool editBubbles;

  /// Dışarıdaki "Balon ekle" düğmesiyle (sabit bölmenin çubuğu) paylaşılan
  /// bırakma kipi: true → dokunarak balon bırakma açık. İki yönlü: araç
  /// kartındaki "Bitti" değeri false'a çeker.
  final ValueNotifier<bool>? addingBubbles;

  /// Bırakma kipinde AÇIK METİN mi (Paint'teki yazı aracı gibi — bkz.
  /// [PageBubble.plain])? Bölme çubuğundaki "Balon ekle" menüsünden seçilir.
  final ValueNotifier<bool>? addingPlain;

  /// Balon yazma kartı açıldı/kapandı: sabit bölme alttaki notu gizleyip
  /// belgeyi klavyeye kadar uzatır (kullanıcı bulgusu 2026-11-05: "balon
  /// yazarken sayfa aşırı daralıyor").
  final ValueChanged<bool>? onBubbleWriting;

  final Attachment attachment;

  /// Sayfa numarası, yer imi, döndürme ve ölçü değişiklikleri buradan
  /// nota yazılır (ve senkronlanır).
  final ValueChanged<Attachment> onChanged;

  /// false ise gezinme çubuğu çizilmez (salt görüntü).
  final bool controls;

  /// Kutu üzerinde yatay kaydırma sayfa çevirsin mi? Büyük önizlemede
  /// KAPALI: oradaki yatay kaydırma nottaki DİĞER EKE geçiyor, iki jest
  /// aynı parmağı paylaşamaz (çubuğun okları orada da çalışıyor).
  final bool swipeToTurn;

  /// Verilirse kutunun kendi şeridi çizilmez (bkz. [PdfBoxBar]).
  final PdfBoxBar? externalBar;

  @override
  State<PdfPageBox> createState() => _PdfPageBoxState();
}

class _PdfPageBoxState extends State<PdfPageBox> {
  /// Kutunun GÖSTERDİĞİ sayfa. Ekten okunur ama ekle aynı anda ilerlemez:
  /// yazma gecikmeli, sayfa ise parmakla anında değişmeli.
  late int _page = widget.attachment.pdfPage;

  /// Belgenin sayfa sayısı (0 = henüz açılmadı).
  int _count = 0;

  /// **SAYFALAR PARMAĞI İZLEYEREK KAYAR** (kullanıcı bulgusu 2026-09-29:
  /// "sayfalarını değiştirmek zor"). Eskiden kutu yalnız HIZLI bir yatay
  /// fiskeyi (80 px/sn üstü) sayıyordu: yavaş sürükleme hiçbir şey
  /// yapmıyor, parmak sayfayı hareket ettirmiyor, kullanıcı çevirip
  /// çevirmediğini anlamıyordu. Artık kutunun içi bir sayfa çevirici:
  /// sayfa parmakla birlikte kayar, yarıyı geçince yerine oturur; komşu
  /// sayfalar önceden çizilir (allowImplicitScrolling).
  ///
  /// Belge açılınca kurulur (başlangıç sayfası ancak o zaman kırpılabilir).
  PageController? _pager;

  /// Otomatik geçiş zamanlayıcısı (null = kapalı).
  Timer? _autoPlay;

  /// Metin/görüntü işlemi sürerken düğmeler kilitlenir.
  bool _busy = false;

  /// **BELGE BURADA TUTULUYOR — `PdfDocumentViewBuilder` İLE DEĞİL.**
  ///
  /// KÖK NEDEN: o kabuk `didUpdateWidget`te dinleyicisini önce kaldırıp sonra
  /// yeniden ekliyor. Kaldırma anında dinleyici sayısı sıfıra düşerse pdfrx
  /// belgeyi KAPATIYOR (`autoDispose`) ve hemen ardından yeniden açıyor —
  /// yani not sayfası her yeniden kurulduğunda (yazarken de) PDF baştan
  /// yükleniyordu. Dinleyici doğrudan bu State'te durunca sayı hiç sıfıra
  /// düşmez; belge bir kez açılır, kutu kapanınca kapanır.
  PdfDocumentListenable? _doc;
  StreamSubscription<PdfDocumentEvent>? _events;

  @override
  void initState() {
    super.initState();
    _attachDocument();
    _zoom.addListener(_onZoom);
    widget.addingBubbles?.addListener(_onExternalAdding);
    widget.addingPlain?.addListener(_onExternalPlain);
    widget.externalBar?._attach(this);
    if (widget.fitWidth && widget.externalBar == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _flashBar());
    }
  }

  /// Ekin kaynağı (yerel kopya → indirme adresi) için belge dinleyicisi.
  /// pdfrx dinleyicileri kaynak yoluna göre paylaşıyor: aynı PDF birden çok
  /// yerde açıksa (kutu + tam ekran) tek belge yüklenir.
  void _attachDocument() {
    final a = widget.attachment;
    final hasLocal = a.localPath.isNotEmpty && localFileExists(a.localPath);
    if (!hasLocal && !a.isUploaded) return;
    final ref = hasLocal
        ? PdfDocumentRefFile(a.localPath)
        : PdfDocumentRefUri(Uri.parse(a.downloadUrl));
    final listenable = ref.resolveListenable()..addListener(_onDocument);
    _doc = listenable;
    listenable.load();
    // Belge BAŞKA bir yerde zaten açıksa (paylaşılan dinleyici) dinleyici
    // hiç tetiklenmez; olaylara burada bağlanılır. `setState` YOK — bu yol
    // `initState`ten de geçiyor.
    _bindEvents();
  }

  void _detachDocument() {
    _events?.cancel();
    _events = null;
    _bound = null;
    _doc?.removeListener(_onDocument);
    _doc = null;
  }

  /// Olaylarına bağlanılmış belge (aynı belgeye iki kez abone olunmasın).
  PdfDocument? _bound;

  void _bindEvents() {
    final document = _doc?.document;
    if (document == null || identical(document, _bound)) return;
    _events?.cancel();
    _bound = document;
    // İlerlemeli yükleme: sayfa ölçüleri geldikçe kutu tazelenir.
    _events = document.events.listen((event) {
      if (event.type == PdfDocumentEventType.pageStatusChanged) {
        _refreshSoon();
      }
    });
    document.loadPagesProgressively();
  }

  /// İlerlemeli yüklemenin sayfa olaylarını TEK yeniden kuruluşta toplar
  /// (kullanıcı bulgusu 2026-11-05: "PDF'lerde kaydırırken kasma"): her
  /// sayfanın ölçüsü geldikçe bütün kutu — sayfa görünümü ve her sayfanın
  /// katmanları — yeniden kuruluyordu; uzun belgede açılıştan sonraki ilk
  /// saniyelerde kaydırma, saniyede onlarca tam kuruluşla yarışıyordu.
  /// Artık en çok 150 ms'de bir.
  Timer? _refreshTimer;

  void _refreshSoon() {
    if (_refreshTimer != null) return;
    _refreshTimer = Timer(const Duration(milliseconds: 150), () {
      _refreshTimer = null;
      if (mounted) setState(() {});
    });
  }

  /// Belge yüklendi (ya da yeniden yüklendi).
  void _onDocument() {
    if (!mounted) return;
    _bindEvents();
    setState(() {});
  }

  @override
  void didUpdateWidget(PdfPageBox old) {
    super.didUpdateWidget(old);
    if (!identical(old.externalBar, widget.externalBar)) {
      old.externalBar?._detach(this);
      widget.externalBar?._attach(this);
    }
    if (!identical(old.addingBubbles, widget.addingBubbles)) {
      old.addingBubbles?.removeListener(_onExternalAdding);
      widget.addingBubbles?.addListener(_onExternalAdding);
    }
    if (!identical(old.addingPlain, widget.addingPlain)) {
      old.addingPlain?.removeListener(_onExternalPlain);
      widget.addingPlain?.addListener(_onExternalPlain);
    }
    // DIŞARIDAN gelen sayfa değişimi (tam ekrandan dönüş, başka cihaz):
    // kutu oraya gider. Kendi yazdığımız değer geri geldiğinde hiçbir şey
    // olmaz — yoksa parmakla çevirirken sayfa geri sıçrardı (aynı tuzak
    // PDF panosunda da vardı, bkz. pdf_note_pane.dart).
    final incoming = widget.attachment.pdfPage;
    if (incoming != old.attachment.pdfPage && incoming != _page) {
      _page = _clamp(incoming);
      _syncPagerSoon();
    }
    // Tam ekranda/balonlu görünümde değişen balonlar ve gizlilik.
    _bubbles
      ?..replace(widget.attachment.bubbles)
      ..syncHidden(widget.attachment.bubblesHidden);
    // Dosya yolu/adresi değiştiyse (yükleme bitti, dosya yeniden yazıldı)
    // belge yeniden bağlanır.
    if (widget.attachment.localPath != old.attachment.localPath ||
        widget.attachment.downloadUrl != old.attachment.downloadUrl) {
      _detachDocument();
      _attachDocument();
      _syncPagerSoon();
    }
  }

  @override
  void dispose() {
    widget.externalBar?._detach(this);
    _autoPlay?.cancel();
    _refreshTimer?.cancel();
    _detachDocument();
    _pager?.dispose();
    widget.addingBubbles?.removeListener(_onExternalAdding);
    widget.addingPlain?.removeListener(_onExternalPlain);
    _bubbles?.addingListenable.removeListener(_onAddingChanged);
    _bubbles?.save();
    _bubbles?.dispose();
    _selection.dispose();
    _zoom.dispose();
    _barHide?.cancel();
    super.dispose();
  }

  // ── OKUMA NOTU: seçim ────────────────────────────────────────────────
  /// Seçili yazı ve sayfası (tam ekran görüntüleyiciyle aynı denetleyici).
  final _selection = PdfSelectionState();

  /// Seçimin PDF-koordinat satır dikdörtgenleri (satır numarası için).
  List<PdfRect> _selectionPdfRects = const [];

  /// Sürükleyerek seçim sürüyor mu — sürerken sayfa çevrilmez/kaymaz.
  bool _selecting = false;

  /// Seçimin hangi kaynaktan geldiği (taranmış sayfada OCR).
  bool _selectionFromOcr = false;

  bool get _selectable => widget.onNoteFromSelection != null;

  // ── OKUMA KİPİ: yakınlaştırma, şerit, balon (2026-11-03) ──────────────
  /// İki parmakla / çift dokunuşla yakınlaştırma (yalnız [fitWidth]).
  final _zoom = TransformationController();
  bool _zoomed = false;
  Offset? _doubleTapAt;

  void _onZoom() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed && mounted) setState(() => _zoomed = zoomed);
  }

  void _resetZoom() {
    if (_zoom.value.getMaxScaleOnAxis() != 1) _zoom.value = Matrix4.identity();
  }

  /// Çift dokunuş: yakınsa sıfırlar, değilse dokunulan yere 2,5×.
  void _toggleZoomAt(Offset? at) {
    if (_zoomed) {
      _resetZoom();
      return;
    }
    final p = at ?? Offset.zero;
    const scale = 2.5;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Sayfa şeridi görünür mü (yalnız [fitWidth]: sayfa değişince ya da
  /// sayfaya dokununca belirir, 2,5 sn sonra söner).
  bool _barShown = true;
  Timer? _barHide;

  void _flashBar() {
    if (!widget.fitWidth || widget.externalBar != null) return;
    _barHide?.cancel();
    if (!_barShown && mounted) setState(() => _barShown = true);
    _barHide = Timer(const Duration(milliseconds: 2500), () {
      // Balon yazılırken / menü işlerken şerit kalır.
      if (mounted && !_bubbleEdit) setState(() => _barShown = false);
    });
  }

  void _toggleBar() {
    if (!widget.fitWidth || widget.externalBar != null) return;
    if (_barShown) {
      _barHide?.cancel();
      setState(() => _barShown = false);
    } else {
      _flashBar();
    }
  }

  /// Sabit bölmede BALON EKLEME kipi (kullanıcı isteği 2026-11-03:
  /// "sabitleme ekranında da balon ekleme olsun, bir buton yardımı ile").
  /// Açıkken balon katmanı düzenlenebilir, sayfaya dokunmak balon bırakır;
  /// yazma kartı kutunun dibinde.
  ///
  /// Kip denetleyicinin `adding` değerinden okunur: araç kartındaki "Bitti"
  /// de kipi kapatır (ayrı bayrak tutulunca düğme "açık" kalıyordu).
  bool get _bubbleEdit => _bubbles?.adding ?? false;

  bool get _bubblesWritable => widget.showBubbles && widget.editBubbles;

  void _toggleBubbleEdit() {
    final controller = _bubbleController();
    controller.setAdding(!controller.adding);
    _flashBar();
  }

  void _onExternalAdding() {
    final want = widget.addingBubbles?.value ?? false;
    if (want == _bubbleEdit || !mounted) return;
    final controller = _bubbleController();
    if (want) controller.setPlainMode(widget.addingPlain?.value ?? false);
    controller.setAdding(want);
  }

  void _onExternalPlain() {
    if (!mounted) return;
    _bubbleController().setPlainMode(widget.addingPlain?.value ?? false);
  }

  void _onAddingChanged() {
    if (!mounted) return;
    widget.addingBubbles?.value = _bubbleEdit;
    if (!_bubbleEdit) _bubbles?.save();
    setState(() {});
    _flashBar();
  }

  void _onSelected(
    PdfDocument document,
    String text,
    List<PdfRect> rects,
    int pageNumber,
    bool fromOcr,
  ) {
    if (pageNumber < 1 || pageNumber > document.pages.length) return;
    _selectionPdfRects = rects;
    _selectionFromOcr = fromOcr;
    _selection.set(
      value: text,
      pageNumber: pageNumber,
      pdfRects: rects,
      source: document.pages[pageNumber - 1],
    );
  }

  void _setSelecting(bool value) {
    if (!mounted || value == _selecting) return;
    setState(() => _selecting = value);
  }

  void _clearSelection() {
    _selectionPdfRects = const [];
    _selection.clear();
  }

  /// Seçimin İLK satırının sayfadaki sırası (1 tabanlı); bilinmiyorsa null.
  Future<int?> _selectionLine(PdfDocument document, int pageNumber) async {
    final rects = _selectionPdfRects;
    if (rects.isEmpty) return null;
    try {
      final page = document.pages[pageNumber - 1];
      final PdfPageText? text = _selectionFromOcr
          ? await PdfPageOcr.forPage(page)
          : await page.loadStructuredText();
      if (text == null) return null;
      final first = rects.first;
      return pdfLineNumber(
        [
          for (final f in text.fragments)
            (
              left: f.bounds.left,
              top: f.bounds.top,
              right: f.bounds.right,
              bottom: f.bounds.bottom,
            ),
        ],
        (
          left: first.left,
          top: first.top,
          right: first.right,
          bottom: first.bottom,
        ),
      );
    } catch (_) {
      // Satır bulunamazsa not yalnız sayfayla alınır.
      return null;
    }
  }

  Future<void> _noteFromSelection(PdfDocument document) async {
    final callback = widget.onNoteFromSelection;
    final page = _selection.page.value;
    final quote = cleanPdfCopyText(_selection.text.value);
    if (callback == null || page == 0) return;
    final line = await _selectionLine(document, page);
    if (!mounted) return;
    _clearSelection();
    callback(page, line, quote);
  }

  Future<void> _copySelection() async {
    final text = cleanPdfCopyText(_selection.text.value);
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.pdfSelectCopied(text.length);
    await Clipboard.setData(ClipboardData(text: text));
    _clearSelection();
    messenger.showMessage(message);
  }

  void _highlightSelection() {
    final page = _selection.page.value;
    final rects = _selection.rects;
    if (page == 0 || rects.isEmpty) return;
    HapticFeedback.selectionClick();
    _bubbleController().addHighlight(page: page, rects: rects, open: false);
    _clearSelection();
  }

  /// Balon katmanının denetleyicisi — yalnız [PdfPageBox.showBubbles] açık
  /// ve belgede balon varken kurulur. Okuma kartının aç/kapa durumu da bu
  /// yoldan nota yazılır (balonlu görünümle aynı veri).
  BubbleController? _bubbles;

  /// Kurulum build'de (bildirim yok); dışarıdan gelen değişiklik
  /// `didUpdateWidget`te benimsenir.
  BubbleController _bubbleController() {
    final a = widget.attachment;
    return _bubbles ??=
        BubbleController(
            initial: a.bubbles,
            hidden: a.bubblesHidden,
            // İki yazım da İKİ alanın canlı değerini taşır: aynı karede gelen
            // "göster" + "yeni balon" yazımı birbirini bayat ekle ezmesin (bkz.
            // PdfNotePane._live).
            onChanged: (list) => widget.onChanged(
              widget.attachment.copyWith(
                bubbles: list,
                bubblesHidden:
                    _bubbles?.hidden ?? widget.attachment.bubblesHidden,
              ),
            ),
            onHiddenChanged: (hidden) => widget.onChanged(
              widget.attachment.copyWith(
                bubblesHidden: hidden,
                bubbles: _bubbles?.bubbles ?? widget.attachment.bubbles,
              ),
            ),
          )
          ..addingListenable.addListener(_onAddingChanged)
          ..onEditingChanged = (writing) =>
              widget.onBubbleWriting?.call(writing);
  }

  /// Çevirici, kutunun gösterdiği sayfadan ayrı düştüyse (dışarıdan gelen
  /// sayfa, tam ekrandan dönüş, belge yeniden bağlandı) oraya ATLAR —
  /// kaydırma animasyonu yok, aradaki sayfalar çizilmesin.
  void _syncPagerSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pager = _pager;
      if (!mounted || pager == null || !pager.hasClients) return;
      final target = _page - 1;
      if ((pager.page ?? target.toDouble()).round() != target) {
        pager.jumpToPage(target);
      }
    });
  }

  int _clamp(int page) => clampPdfPage(page, _count);

  /// Sayfayı değiştirir ve nota yazar (kaldığı yer korunsun).
  ///
  /// Komşu sayfaya KAYARAK gidilir (‹ › düğmeleri parmakla çevirmeyle aynı
  /// görünsün); uzak sayfaya (atlama levhası, yer imi, başa dönüş) ATLANIR:
  /// kaydırılsaydı aradaki her sayfa çizilir ve `onPageChanged` her birinde
  /// nota yazardı.
  void _goTo(int page, {bool save = true}) {
    final next = _clamp(page);
    if (next == _page) return;
    final previous = _page;
    setState(() => _page = next);
    _resetZoom();
    _flashBar();
    final pager = _pager;
    if (pager != null && pager.hasClients) {
      if ((next - previous).abs() == 1) {
        pager.animateToPage(
          next - 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        pager.jumpToPage(next - 1);
      }
    }
    if (save) widget.onChanged(widget.attachment.copyWith(pdfPage: next));
  }

  /// Parmakla çevrilen sayfa yerine oturdu. Düğmeyle başlatılan geçişin
  /// kendi bildirimi ([_goTo] `_page`'i önceden yazdığı için) yok sayılır.
  void _onPagerChanged(int index) {
    final next = _clamp(index + 1);
    if (next == _page) return;
    if (_selection.page.value != 0) _clearSelection();
    _resetZoom();
    _flashBar();
    setState(() => _page = next);
    widget.onChanged(widget.attachment.copyWith(pdfPage: next));
  }

  void _toggleAutoPlay() {
    setState(() {
      if (_autoPlay != null) {
        _autoPlay!.cancel();
        _autoPlay = null;
        return;
      }
      _autoPlay = Timer.periodic(
        const Duration(seconds: 5),
        // Sonuncudan sonra başa döner: sunum gibi dönsün, sessizce durmasın.
        (_) => _goTo(autoPlayNext(_page, _count), save: false),
      );
    });
  }

  void _toggleMark() {
    final marks = togglePdfMark(widget.attachment.pdfMarks, _page);
    widget.onChanged(widget.attachment.copyWith(pdfMarks: marks));
  }

  void _rotate() {
    final turns = (widget.attachment.pdfTurns + 1) % 4;
    widget.onChanged(widget.attachment.copyWith(pdfTurns: turns));
  }

  /// Belgenin ölçüsü ekte yoksa İLK açılışta yazılır: kutunun en-boyu
  /// (bkz. `NotePageCanvas`) buradan geliyor, yoksa PDF kare kutuya ezilir.
  void _reportSize(PdfDocument document) {
    final a = widget.attachment;
    if (a.width != null && a.height != null) return;
    if (document.pages.isEmpty) return;
    final page = document.pages.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged(
        a.copyWith(width: page.width.round(), height: page.height.round()),
      );
    });
  }

  Future<void> _openFullScreen() async {
    final page = _page;
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => PdfViewerScreen(
          attachment: widget.attachment,
          initialPage: page,
          // Tam ekranda çevrilen sayfa kutuya geri döner: kullanıcı belgeyi
          // bıraktığı yerde bulur.
          onPageChanged: (p) {
            if (!mounted) return;
            _page = _clamp(p);
            widget.onChanged(widget.attachment.copyWith(pdfPage: _page));
          },
          onChanged: widget.onChanged,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    _syncPagerSoon();
  }

  /// Bu sayfanın metin katmanını panoya alır. Taranmış sayfada metin yoktur;
  /// o zaman kullanıcıya söylenir (OCR yolu tam ekran görüntüleyicide).
  Future<void> _copyPageText() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final path = widget.attachment.localPath;
    if (path.isEmpty || !localFileExists(path)) {
      messenger.showMessage(l10n.attachmentNotSynced);
      return;
    }
    setState(() => _busy = true);
    try {
      final text = await PdfText.pageText(path, _page);
      if (!mounted) return;
      if (text.isEmpty) {
        messenger.showMessage(l10n.pdfSelectOcrNone);
        return;
      }
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      messenger.showMessage(l10n.pdfSelectCopied(text.length));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sayfayı görüntü olarak yakalar ve alan işlemleri levhasını açar
  /// (yapay zekâya sor / panoya kopyala) — alan seçimiyle AYNI levha.
  Future<void> _capturePage(PdfDocument document) async {
    if (_page < 1 || _page > document.pages.length) return;
    setState(() => _busy = true);
    Uint8List? png;
    try {
      final rendered = await PdfPageOcr.renderPageToPng(
        document.pages[_page - 1],
      );
      if (rendered != null) {
        final file = File(rendered.path);
        png = await file.readAsBytes();
        try {
          file.deleteSync();
        } catch (_) {
          // Geçici dosya silinemezse sorun değil; sistem temizler.
        }
      }
    } catch (_) {
      // Çizim başarısızsa levha hiç açılmaz (aşağıdaki null denetimi).
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (png == null) {
      ScaffoldMessenger.of(context).showMessage(context.l10n.areaCaptureFailed);
      return;
    }
    await showAreaActions(context, png);
  }

  /// Sayfaya atlama levhası: kaydırıcı, ilk/son sayfa, yer imleri ve bütün
  /// sayfaların küçük resimleri.
  Future<void> _openJumpSheet(PdfDocument document) async {
    final target = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PdfJumpSheet(
        document: document,
        page: _page,
        marks: widget.attachment.pdfMarks,
      ),
    );
    if (target != null && mounted) _goTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final listenable = _doc;
    final a = widget.attachment;
    widget.externalBar?._update((
      listenable != null,
      _page,
      _count,
      a.pdfMarks.contains(_page),
      a.bubbles.length,
      a.bubblesHidden,
      _busy,
      _autoPlay != null,
    ));
    if (listenable == null) return _placeholder(context);
    return _document(context, listenable.document);
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: scheme.error),
            const SizedBox(height: 4),
            Text(
              context.l10n.attachmentNotSynced,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _document(BuildContext context, PdfDocument? document) {
    if (document == null) {
      return const ColoredBox(
        color: Color(0xFFF2F2F2),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_count != document.pages.length) {
      _count = document.pages.length;
      _page = _clamp(_page);
    }
    _reportSize(document);
    final a = widget.attachment;
    final pager = _pager ??= PageController(initialPage: _page - 1);
    final swipe = widget.controls && widget.swipeToTurn;
    // Yazılabilir bölmede denetleyici HEP kurulur (kip dışında da balon
    // taşınır, düzenlenir).
    final bubbles =
        widget.showBubbles &&
            (a.bubbles.isNotEmpty || _bubbleEdit || _bubblesWritable)
        ? _bubbleController()
        : null;
    final locked = _selecting || _zoomed;
    final pages = ColoredBox(
      color: Colors.white,
      child: PageView.builder(
        controller: pager,
        // Seçim sürerken / yakınken sayfa çevrilmez.
        physics: swipe && !locked
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        allowImplicitScrolling: true,
        itemCount: _count,
        onPageChanged: _onPagerChanged,
        itemBuilder: (context, i) {
          final page = RotatedBox(
            quarterTurns: a.pdfTurns,
            // Kendi çizicimiz: pdfrx'in PdfPageView'ı aynı boydaki
            // sayfalarda görüntüyü yenilemiyordu (bkz. PdfPageImage).
            child: PdfPageImage(
              document: document,
              pageNumber: i + 1,
              overlay: _pageOverlay(document, i + 1, bubbles),
            ),
          );
          if (!widget.fitWidth) return page;
          // GENİŞLİĞE OTURAN sayfa: boyu taşarsa dikeyde kayar. Şerit
          // kendiliğinden söndüğü için küçük bir dip payı yeter.
          final p = document.pages[i];
          final aspect = p.height <= 0 || p.width <= 0
              ? 1 / 1.41
              : (a.pdfTurns.isOdd ? p.height / p.width : p.width / p.height);
          // `RepaintBoundary`: kaydırırken sayfa görüntüsü ve katmanları
          // (balon, mürekkep, seçim) her karede YENİDEN ÇİZİLMESİN —
          // kaydırıcı yalnız hazır katmanı kaydırır (SingleChildScrollView
          // listelerin aksine çocuğuna kendiliğinden sınır koymuyor).
          return SingleChildScrollView(
            physics: locked
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: RepaintBoundary(
              child: AspectRatio(aspectRatio: aspect, child: page),
            ),
          );
        },
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        // Yatay kaydırma sayfa çevirir: kutunun küçük düğmelerine nişan
        // almadan da gezilebilsin. Dikey kaydırma NOTUN kendi kaydırması
        // olarak kalır (çevirici yalnız yatay sürüklemeyi alır); uzun basıp
        // kutuyu taşımak da bozulmaz (taşıma hareketsiz basılı tutmayla
        // başlar, çevirici ise ancak parmak yana kayınca devreye girer).
        if (!widget.fitWidth)
          pages
        else
          // YAKINLAŞTIRMA (kullanıcı isteği 2026-11-03): iki parmak ya da çift
          // dokunuş; yakınken tek parmak sayfayı gezdirir, sayfa çevirme ve
          // dikey kaydırma kilitli. Tek dokunuş sayfa şeridini aç/kapa.
          GestureDetector(
            onTap: _toggleBar,
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            // Çift dokunuş HEP yakınlaştırır (kullanıcı kararı 2026-11-05);
            // seçim basılı tutmakla (bkz. PdfSelectLayer.doubleTapSelects).
            onDoubleTap: () => _toggleZoomAt(_doubleTapAt),
            // Fare tekerleği sayfayı kaydırır, zoom Ctrl+tekerlekle.
            child: WheelScrollViewer(
              controller: _zoom,
              panEnabled: _zoomed,
              child: pages,
            ),
          ),
        // El yazısı katmanı: PDF'in üzerine yapılan çizim kutuda da görünür
        // (tam ekranda çizip nota dönünce sayfa boş görünmesin). Genişliğe
        // oturan kipte sayfanın kendi katmanında (sayfayla birlikte kayar).
        if (a.ink.isNotEmpty && !widget.fitWidth)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: InkPainter(a.ink, _page)),
            ),
          ),
        if (widget.controls && !widget.fitWidth)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bar(context, document),
          ),
        // OKUMA KİPİNDE ŞERİT (kullanıcı isteği 2026-11-03: "sayfa sayısının
        // yazdığı koyu gri şerit çok kötü görünüyor; şeffaf olsun, açılıp
        // kapansın, sayfa değiştikçe görülsün"): yüzen saydam hap, sayfa
        // değişince ya da sayfaya dokununca belirir, sonra söner.
        if (widget.controls && widget.fitWidth && widget.externalBar == null)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: IgnorePointer(
              ignoring: !_barShown,
              child: AnimatedOpacity(
                opacity: _barShown ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _bar(context, document),
                ),
              ),
            ),
          ),
        // Yazma kartı kendini yalnız bir balon düzenlenirken çizer; balon
        // kip dışında da (okuma kartında "Düzenle") düzenlenebilsin diye
        // yazılabilir bölmede hep ağaçta.
        if (bubbles != null && (_bubbleEdit || _bubblesWritable)) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BubbleDock(controller: bubbles),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: bubbles.addingListenable,
              builder: (context, adding, _) => adding
                  ? BubbleToolbar(controller: bubbles)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
        if (_selectable)
          Positioned(
            left: 6,
            right: 6,
            top: 6,
            child: ValueListenableBuilder<String>(
              valueListenable: _selection.text,
              builder: (context, text, _) => text.trim().isEmpty
                  ? const SizedBox.shrink()
                  : Center(child: _selectionBar(context, document)),
            ),
          ),
      ],
    );
  }

  /// Sayfanın üst katmanları: balonlar, (genişliğe oturan kipte) el yazısı
  /// ve seçim katmanı. Hiçbiri yoksa null.
  Widget? _pageOverlay(
    PdfDocument document,
    int pageNumber,
    BubbleController? bubbles,
  ) {
    final a = widget.attachment;
    final pen = widget.ink;
    // Gömülü (kapak) kutuda da kalem verilince yazılır (2026-11-09).
    final inkHere = pen != null || (widget.fitWidth && a.ink.isNotEmpty);
    if (bubbles == null && !inkHere && !_selectable) return null;
    // KÖK NEDEN (kullanıcı bulgusu 2026-11-08: "sabit moddayken PDF üzerine
    // kalemle yazamıyorum, yalnız tam ekranda yazılıyor"): kalem katmanı
    // seçim ve balon katmanlarının ALTINDAYDI — kalemin dokunuşunu üstteki
    // seçim katmanı (basılı tut = seç) alıyordu. Kalem açıkken mürekkep EN
    // ÜSTTE ve seçim katmanı yok (yazarken seçim gerekmez).
    final penOn = inkHere && pen != null;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          if (inkHere && !penOn)
            IgnorePointer(
              child: CustomPaint(painter: InkPainter(a.ink, pageNumber)),
            ),
          if (_selectable && !penOn)
            ValueListenableBuilder<int>(
              valueListenable: _selection.page,
              builder: (context, active, _) => Stack(
                fit: StackFit.expand,
                children: [
                  PdfSelectLayer(
                    page: document.pages[pageNumber - 1],
                    pageSize: box.biggest,
                    activeSelectionPage: active,
                    // Basılı tut = seçim; genişliğe oturan (yakınlaşan)
                    // kipte çift dokunuş yakınlaştırmanın.
                    doubleTapSelects: !widget.fitWidth,
                    onSelected: (text, rects, page, fromOcr) =>
                        _onSelected(document, text, rects, page, fromOcr),
                    onSelectingChanged: _setSelecting,
                  ),
                ],
              ),
            ),
          if (bubbles != null)
            BubblePageLayer(
              controller: bubbles,
              page: pageNumber,
              readOnly: penOn || !(_bubbleEdit || _bubblesWritable),
            ),
          if (penOn) InkPageLayer(controller: pen, page: pageNumber),
        ],
      ),
    );
  }

  /// Seçim varken kutunun TEPESİNDE beliren çubuk: **Not al** (birincil,
  /// yazılı) · Kopyala · Vurgula · Kapat. Tepede: alttaki sayfa çubuğunu ve
  /// seçimin tutamaçlarını örtmesin.
  Widget _selectionBar(BuildContext context, PdfDocument document) {
    final l10n = context.l10n;
    Widget icon(IconData icon, String tooltip, VoidCallback onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          visualDensity: VisualDensity.compact,
        );
    return Material(
      key: const ValueKey('pdf-box-selection-bar'),
      color: Colors.black.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              key: const ValueKey('pdf-box-note-from-selection'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => _noteFromSelection(document),
              icon: const Icon(Icons.edit_note, size: 20),
              label: Text(l10n.pdfNoteFromSelection),
            ),
            icon(Icons.copy, l10n.copy, _copySelection),
            icon(Icons.border_color, l10n.pdfHighlight, _highlightSelection),
            icon(Icons.close, l10n.close, _clearSelection),
          ],
        ),
      ),
    );
  }

  /// Kutunun dibindeki gezinme çubuğu: ‹ · sayfa · › · yer imi · menü.
  ///
  /// **DAR KUTUYA SIĞMALI**: kutu sayfanın istenen genişliğinde olabiliyor
  /// (en az %15). Beş denetim 130 dp'lik bir kutuda taşardı; çubuk kutunun
  /// genişliğine göre inceliyor — önce yer imi düğmesi (menüde de var),
  /// sonra oklar düşüyor. Menü her boyda kalıyor: bütün işlemler orada.
  ///
  /// SAYAÇ KESİLMEMELİ (kullanıcı ekran görüntüsü 2026-09-29: "5 /…"):
  /// menü düğmesi Material'in 48 dp'lik asgari dokunma kutusunu alıyor ve
  /// 170 dp'lik kutuda sayaca yer bırakmıyordu. Menü artık çubuğun
  /// düğmeleriyle aynı boyda; geniş kutuda düğmeler büyür (parmakla
  /// isabet kolaylaşsın).
  Widget _bar(BuildContext context, PdfDocument document) => LayoutBuilder(
    builder: (context, constraints) =>
        _barRow(context, document, constraints.maxWidth),
  );

  Widget _barRow(BuildContext context, PdfDocument document, double width) {
    final l10n = context.l10n;
    final a = widget.attachment;
    final marked = a.pdfMarks.contains(_page);
    final notes = a.bubbles.where((b) => b.page == _page).length;
    final showMark = width >= 210;
    // Balonlar çiziliyorsa sayfa rozeti yerine GÖSTER/GİZLE düğmesi.
    final bubbleToggle = widget.showBubbles && a.bubbles.isNotEmpty;
    final showArrows = width >= 110;
    final big = width >= 150;
    return Material(
      color: Colors.black.withValues(alpha: widget.fitWidth ? 0.38 : 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showArrows)
              _barButton(
                icon: Icons.chevron_left,
                tooltip: l10n.pdfPreviousPage,
                big: big,
                onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
              ),
            Flexible(
              child: InkWell(
                onTap: _count > 0 ? () => _openJumpSheet(document) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (marked)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.bookmark,
                            size: 12,
                            color: Colors.amber,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          '$_page / ${_count == 0 ? '…' : _count}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: big ? 12 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Sayfa notu rozeti: bu sayfada balon/vurgu var mı?
                      if (notes > 0 && showMark && !bubbleToggle)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble,
                                size: 10,
                                color: Colors.white70,
                              ),
                              Text(
                                ' $notes',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showArrows)
              _barButton(
                icon: Icons.chevron_right,
                tooltip: l10n.pdfNextPage,
                big: big,
                onPressed: _count > 0 && _page < _count
                    ? () => _goTo(_page + 1)
                    : null,
              ),
            if (bubbleToggle)
              _barButton(
                key: const ValueKey('pdf-box-bubbles'),
                icon: a.bubblesHidden
                    ? Icons.speaker_notes_off_outlined
                    : Icons.chat_bubble_outline,
                tooltip: a.bubblesHidden ? l10n.bubblesShow : l10n.bubblesHide,
                color: a.bubblesHidden ? Colors.white54 : Colors.white,
                big: big,
                onPressed: () => widget.onChanged(
                  a.copyWith(bubblesHidden: !a.bubblesHidden),
                ),
              ),
            // BALON EKLE (sabit bölme): kipi aç/kapa.
            if (widget.fitWidth && widget.showBubbles && showMark)
              _barButton(
                key: const ValueKey('pdf-box-add-bubble'),
                icon: _bubbleEdit ? Icons.check : Icons.add_comment_outlined,
                tooltip: _bubbleEdit ? l10n.bubbleAddDone : l10n.bubbleAdd,
                color: _bubbleEdit ? Colors.amber : Colors.white,
                big: big,
                onPressed: _toggleBubbleEdit,
              ),
            if (showMark)
              _barButton(
                icon: marked ? Icons.bookmark : Icons.bookmark_border,
                tooltip: marked ? l10n.pdfBookmarkRemove : l10n.pdfBookmarkAdd,
                color: marked ? Colors.amber : Colors.white,
                big: big,
                onPressed: _toggleMark,
              ),
            _menu(context, document, big: big),
          ],
        ),
      ),
    );
  }

  /// Sabit bölme çubuğundaki denetimler ([PdfBoxBar]): ‹ n/N › (çok
  /// sayfada) · balon göster/gizle (balon varsa) · yer imi (yer varsa) ·
  /// belge menüsü. Balon EKLE bölme çubuğunda zaten var (yinelenmez).
  List<Widget> _externalControls(BuildContext context, double width) {
    final document = _doc?.document;
    if (document == null) return const [];
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final a = widget.attachment;
    final marked = a.pdfMarks.contains(_page);
    final multi = _count > 1;
    Widget button({
      required Key key,
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      bool selected = false,
    }) => IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 40),
      color: selected ? scheme.primary : null,
      icon: Icon(icon),
      onPressed: _busy ? null : onPressed,
    );
    return [
      if (multi) ...[
        if (width >= 340)
          button(
            key: const ValueKey('pinned-pdf-prev'),
            icon: Icons.chevron_left,
            tooltip: l10n.pdfPreviousPage,
            onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
          ),
        InkWell(
          key: const ValueKey('pinned-pdf-page'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openJumpSheet(document),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  '$_page/$_count',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: marked ? scheme.primary : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (width >= 340)
          button(
            key: const ValueKey('pinned-pdf-next'),
            icon: Icons.chevron_right,
            tooltip: l10n.pdfNextPage,
            onPressed: _page < _count ? () => _goTo(_page + 1) : null,
          ),
      ],
      if (widget.showBubbles && a.bubbles.isNotEmpty)
        button(
          key: const ValueKey('pinned-pdf-bubbles'),
          icon: a.bubblesHidden
              ? Icons.speaker_notes_off_outlined
              : Icons.chat_bubble_outline,
          tooltip: a.bubblesHidden ? l10n.bubblesShow : l10n.bubblesHide,
          selected: a.bubblesHidden,
          onPressed: () =>
              widget.onChanged(a.copyWith(bubblesHidden: !a.bubblesHidden)),
        ),
      if (width >= 400)
        button(
          key: const ValueKey('pinned-pdf-mark'),
          icon: marked ? Icons.bookmark : Icons.bookmark_border,
          tooltip: marked ? l10n.pdfBookmarkRemove : l10n.pdfBookmarkAdd,
          selected: marked,
          onPressed: _toggleMark,
        ),
      // Belge menüsü (küçük resimler, yer imleri, döndür, slayt gösterisi,
      // sayfa metni, AI yakala, tam ekran) — eski şeridin ⋮'ı.
      _menu(
        context,
        document,
        big: true,
        size: 40,
        key: const ValueKey('pinned-pdf-menu'),
        icon: Icon(Icons.auto_stories_outlined, color: scheme.onSurfaceVariant),
      ),
    ];
  }

  Widget _barButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color color = Colors.white,
    bool big = false,
    Key? key,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    iconSize: big ? 20 : 16,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints(
      minWidth: big ? 34 : 26,
      minHeight: big ? 32 : 26,
    ),
    visualDensity: VisualDensity.compact,
    color: color,
    disabledColor: Colors.white30,
    icon: Icon(icon),
    onPressed: _busy ? null : onPressed,
  );

  Widget _menu(
    BuildContext context,
    PdfDocument document, {
    bool big = false,
    Widget? icon,
    double? size,
    Key? key,
  }) {
    final l10n = context.l10n;
    final playing = _autoPlay != null;
    return SizedBox(
      key: key,
      width: size ?? (big ? 32 : 26),
      height: size ?? (big ? 32 : 26),
      child: PopupMenuButton<String>(
        tooltip: icon == null ? l10n.more : l10n.pdfThumbnails,
        iconSize: big ? 20 : 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 200),
        icon: icon ?? const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (action) {
          switch (action) {
            case 'pages':
              _openJumpSheet(document);
            case 'mark':
              _toggleMark();
            case 'marks':
              _openMarks();
            case 'rotate':
              _rotate();
            case 'full':
              _openFullScreen();
            case 'text':
              _copyPageText();
            case 'capture':
              _capturePage(document);
            case 'play':
              _toggleAutoPlay();
          }
        },
        itemBuilder: (context) => [
          _menuItem('pages', Icons.grid_view_outlined, l10n.pdfThumbnails),
          _menuItem(
            'mark',
            widget.attachment.pdfMarks.contains(_page)
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_add_outlined,
            widget.attachment.pdfMarks.contains(_page)
                ? l10n.pdfBookmarkRemove
                : l10n.pdfBookmarkAdd,
          ),
          _menuItem('marks', Icons.bookmarks_outlined, l10n.pdfBookmarks),
          _menuItem('rotate', Icons.rotate_90_degrees_ccw, l10n.pdfRotateView),
          _menuItem(
            'play',
            playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
            playing ? l10n.pdfSlideshowStop : l10n.pdfSlideshow,
          ),
          _menuItem('text', Icons.text_snippet_outlined, l10n.pdfCopyPageText),
          _menuItem('capture', Icons.auto_awesome, l10n.pdfCapturePage),
          _menuItem('full', Icons.fullscreen, l10n.pdfFullScreen),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem<String>(
        value: value,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
        ),
      );

  /// Yer imi listesi: konan sayfalara tek dokunuşla atlanır.
  Future<void> _openMarks() async {
    final marks = widget.attachment.pdfMarks;
    final l10n = context.l10n;
    final target = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: marks.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(l10n.pdfNoBookmarks),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final page in marks)
                    ListTile(
                      leading: const Icon(Icons.bookmark, color: Colors.amber),
                      title: Text(l10n.pdfPage(page)),
                      onTap: () => Navigator.of(context).pop(page),
                    ),
                ],
              ),
      ),
    );
    if (target != null && mounted) _goTo(target);
  }
}

/// Sayfaya atlama levhası: kaydırıcı + ilk/son + küçük resim ızgarası.
class _PdfJumpSheet extends StatefulWidget {
  const _PdfJumpSheet({
    required this.document,
    required this.page,
    required this.marks,
  });

  final PdfDocument document;
  final int page;
  final List<int> marks;

  @override
  State<_PdfJumpSheet> createState() => _PdfJumpSheetState();
}

class _PdfJumpSheetState extends State<_PdfJumpSheet> {
  late int _page = widget.page;

  int get _count => widget.document.pages.length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.pdfPageOf(_page, _count),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.pdfFirstPage,
                  icon: const Icon(Icons.first_page),
                  onPressed: () => setState(() => _page = 1),
                ),
                Expanded(
                  child: Slider(
                    value: _page.toDouble().clamp(1, _count.toDouble()),
                    min: 1,
                    max: _count.toDouble(),
                    divisions: _count > 1 ? _count - 1 : null,
                    label: '$_page',
                    onChanged: (v) => setState(() => _page = v.round()),
                  ),
                ),
                IconButton(
                  tooltip: l10n.pdfLastPage,
                  icon: const Icon(Icons.last_page),
                  onPressed: () => setState(() => _page = _count),
                ),
              ],
            ),
            // Küçük resimler: sayfayı görerek seçmek numara yazmaktan hızlı.
            SizedBox(
              height: 260,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _count,
                itemBuilder: (context, i) {
                  final number = i + 1;
                  final selected = number == _page;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(number),
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: PdfPageImage(
                              document: widget.document,
                              pageNumber: number,
                              maximumDpi: 72,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.marks.contains(number))
                              const Icon(
                                Icons.bookmark,
                                size: 11,
                                color: Colors.amber,
                              ),
                            Text(
                              '$number',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_page),
              child: Text(l10n.pdfGoToPage),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SAF MANTIK (ölçülebilir; pdfium gerektirmez) ────────────────────────────

/// Sayfa numarasını belgenin sınırlarına oturtur. Belge henüz açılmadıysa
/// ([count] = 0) numara olduğu gibi kalır — açılınca yeniden kırpılır.
int clampPdfPage(int page, int count) {
  if (count <= 0) return page < 1 ? 1 : page;
  if (page < 1) return 1;
  if (page > count) return count;
  return page;
}

/// Otomatik geçişte sıradaki sayfa: sonuncudan sonra BAŞA döner.
int autoPlayNext(int page, int count) {
  if (count <= 0) return page;
  return page >= count ? 1 : page + 1;
}

/// Yer imini ekler ya da kaldırır; liste her zaman sıralı ve tekrarsız.
List<int> togglePdfMark(List<int> marks, int page) {
  final out = [...marks];
  if (out.remove(page)) return out..sort();
  return out
    ..add(page)
    ..sort();
}

/// Döndürülmüş kutunun en-boy oranı: 90°/270°'de sayfa yan yatar.
double pdfBoxAspect(double width, double height, int turns) {
  if (width <= 0 || height <= 0) return 1;
  return turns.isEven ? width / height : height / width;
}
