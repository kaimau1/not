import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../app/theme/app_tokens.dart';
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
import 'page_ink_layer.dart' show InkClaim;
import '../viewers/pdf_page_image.dart';
import '../viewers/pdf_select_layer.dart';
import '../viewers/pdf_selection_bar.dart' show PdfSelectionState;
import '../viewers/pdf_viewer_screen.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';
import 'bubbles_overview.dart';
import 'media_loading_cover.dart';
import 'pdf_page_column.dart';
import '../../../../core/haptics.dart';

part 'pdf_page_box_parts.dart';

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
    this.onInsertToNote,
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

  /// Alan işlemlerindeki yapay zekâ yanıtını doğrudan nota eklemek için.
  final ValueChanged<String>? onInsertToNote;

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
    } else if (widget.attachment.pdfTurns != old.attachment.pdfTurns) {
      // Döndürünce sayfa boyları değişir: dikey sütun aynı sayfada kalsın.
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
    _pillDim?.cancel();
    _pageShown.dispose();
    _pillLit.dispose();
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
    AppHaptics.tick();
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
      if (!mounted) return;
      _pageShown.value = _page;
      _columnKey.currentState?.showPage(_page);
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
    _pageShown.value = next;
    _columnKey.currentState?.showPage(
      next,
      animate: (next - previous).abs() == 1,
    );
    final pager = _pager;
    if (pager != null && pager.hasClients) {
      if ((next - previous).abs() == 1) {
        pager.animateToPage(
          next - 1,
          duration: const Duration(milliseconds: 240),
          curve: AppMotion.emphasized,
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

  // ── SÜREKLİ DİKEY KAYDIRMA (F65.8; yalnız [PdfPageBox.fitWidth]) ──────
  /// Sabit bölmede sayfalar alt alta ([PdfPageColumn]); eski "dipte çekince
  /// sonraki sayfa" geçişi (KALEM K1) ve yana çevirme bununla kalktı.
  /// Kaydırırken kök `setState` YOK: ortadaki sayfa [_pageShown]'a (hap)
  /// yazılır, nota kaydırma DURUNCA ([_onColumnSettled]).
  final _columnKey = GlobalKey<PdfPageColumnState>();
  late final _pageShown = ValueNotifier<int>(_page);
  final _pillLit = ValueNotifier<bool>(true);
  Timer? _pillDim;
  bool _pillTimed = false;

  void _dimPillSoon() {
    _pillDim?.cancel();
    _pillDim = Timer(const Duration(seconds: 2), () => _pillLit.value = false);
  }

  void _onColumnPage(int page) {
    _page = page;
    _pageShown.value = page;
    _pillLit.value = true;
  }

  void _onColumnSettled(int page) {
    _dimPillSoon();
    if (page == widget.attachment.pdfPage) return;
    widget.onChanged(widget.attachment.copyWith(pdfPage: page));
    // Çubuğun yer imi düğmesi yeni sayfayı göstersin (kutu kurulmadan).
    widget.externalBar?._update(_barSignature());
  }

  /// Sayfanın yükseklik/genişlik oranı; ölçüsü henüz gelmemiş sayfa ilk
  /// sayfanın oranıyla yer tutar.
  double _ratioOf(PdfDocument document, int index) {
    final pages = document.pages;
    if (pages.isEmpty) return 1.41;
    var p = pages[index];
    if (!p.isLoaded || p.width <= 0 || p.height <= 0) p = pages.first;
    if (p.width <= 0 || p.height <= 0) return 1.41;
    return widget.attachment.pdfTurns.isOdd
        ? p.width / p.height
        : p.height / p.width;
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
          await file.delete();
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
    await showAreaActions(
      context,
      png,
      onInsertToNote: widget.onInsertToNote,
    );
  }

  Future<void> _captureActivePage() async {
    final document = _doc?.document;
    if (document == null) return;
    await _capturePage(document);
  }

  /// Sayfaya atlama levhası: kaydırıcı, ilk/son sayfa, yer imleri ve bütün
  /// sayfaların küçük resimleri.
  Future<void> _openJumpSheet(PdfDocument document) async {
    final target = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
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
    widget.externalBar?._update(_barSignature());
    if (listenable == null) return _placeholder(context);
    return _document(context, listenable.document);
  }

  Object _barSignature() {
    final a = widget.attachment;
    return (
      _doc != null,
      _page,
      _count,
      a.pdfMarks.contains(_page),
      a.bubbles.length,
      a.bubblesHidden,
      _busy,
      _autoPlay != null,
    );
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
      // Belge açılırken gri kutu değil küçük resim + gecikmeli halka (F78.3b).
      return MediaLoadingCover(attachment: widget.attachment);
    }
    if (_count != document.pages.length) {
      _count = document.pages.length;
      _page = _clamp(_page);
    }
    _reportSize(document);
    final a = widget.attachment;
    final swipe = widget.controls && widget.swipeToTurn;
    // Yazılabilir bölmede denetleyici HEP kurulur (kip dışında da balon
    // taşınır, düzenlenir).
    final bubbles =
        widget.showBubbles &&
            (a.bubbles.isNotEmpty || _bubbleEdit || _bubblesWritable)
        ? _bubbleController()
        : null;
    final locked = _selecting || _zoomed;
    // Kendi çizicimiz: pdfrx'in PdfPageView'ı aynı boydaki sayfalarda
    // görüntüyü yenilemiyordu (bkz. PdfPageImage). Mürekkep, seçim ve balon
    // katmanları sayfa başına ([_pageOverlay]) — iki kipte de aynı kutu.
    Widget pageAt(int i) => RotatedBox(
      quarterTurns: a.pdfTurns,
      child: PdfPageImage(
        document: document,
        pageNumber: i + 1,
        overlay: _pageOverlay(document, i + 1, bubbles),
      ),
    );
    final Widget pages;
    if (widget.fitWidth) {
      // SÜREKLİ DİKEY (F65.8): sayfalar alt alta, tembel; seçim sürerken /
      // yakınken kaydırma kilitli. Her sayfa liste öğesi olarak kendi
      // RepaintBoundary'sinde (ListView varsayılanı).
      if (!_pillTimed) {
        _pillTimed = true;
        _dimPillSoon();
      }
      pages = NotificationListener<ScrollStartNotification>(
        onNotification: (n) {
          if (n.depth == 0) {
            _pillDim?.cancel();
            _pillLit.value = true;
          }
          return false;
        },
        child: PdfPageColumn(
          key: _columnKey,
          count: _count,
          initialPage: _page,
          ratioOf: (i) => _ratioOf(document, i),
          physics: locked
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          onPageChanged: _onColumnPage,
          onPageSettled: _onColumnSettled,
          itemBuilder: (context, i) => pageAt(i),
        ),
      );
    } else {
      pages = ColoredBox(
        color: Colors.white,
        child: PageView.builder(
          controller: _pager ??= PageController(initialPage: _page - 1),
          // Seçim sürerken / yakınken sayfa çevrilmez.
          physics: swipe && !locked
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          allowImplicitScrolling: true,
          itemCount: _count,
          onPageChanged: _onPagerChanged,
          itemBuilder: (context, i) => pageAt(i),
        ),
      );
    }
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
        // SAYFA HAPI (F65.8): bölme çubuğundaki ‹ n/N › yerine sağ altta
        // "12 / 240"; dokununca sayfaya atlama levhası.
        if (widget.fitWidth && _count > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: PdfPagePill(
              page: _pageShown,
              count: _count,
              lit: _pillLit,
              onTap: () => _openJumpSheet(document),
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
}
