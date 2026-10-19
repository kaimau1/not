import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/local_file.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/frame_loop.dart';
import '../../../../core/utils/pdf_copy_text.dart';
import '../../data/pdf/edge_auto_scroll.dart';
import '../../domain/attachment.dart';
import '../editor/bubbles_overview.dart';
import 'area_actions.dart';
import 'area_select.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'pdf_document_view.dart';
import 'pdf_select_layer.dart';
import 'pdf_selection_bar.dart';

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
///
/// Sayfanın üzerinde ÜÇ katman yaşar; üçü de PDF dosyasına dokunmaz, ekin
/// kendi alanlarında saklanır ve not ile birlikte senkronlanır:
/// * **Metin seçimi** ([PdfSelectLayer]) — daima açık. Uzun basış kelimeyi
///   seçer, sürükleme büyütür; seçim çubuğundan metin vurgulanır, nota
///   çevrilir ya da panoya kopyalanır. Taranmış sayfada cihaz-içi OCR devreye
///   girer.
/// * **Not balonları ve vurgular** ([BubblePageLayer]) — belgenin üzerinde
///   çalışmanın ANA aracı.
/// * **El yazısı** ([InkPageLayer]) — yalnız [onChanged] verilirse ve kalem
///   düğmesiyle açılınca.
///
/// Üçü aynı anda dokunuş beklemez: çizim ya da balon bırakma açıkken metin
/// seçimi kapanır (aksi hâlde iki katman aynı parmağı paylaşırdı).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.attachment,
    this.onChanged,
    this.initialPage = 1,
    this.onPageChanged,
  });

  final Attachment attachment;

  /// Açılışta gidilecek sayfa (1 tabanlı). Sayfaya gömülü PDF kutusu
  /// buradan kaldığı sayfayı geçirir — tam ekran belgenin başına dönmez.
  final int initialPage;

  /// Sayfa değişince bildirir; kutu bunu ekin `pdfPage` alanına yazar, yani
  /// tam ekranda çevrilen sayfa nota dönünce de açık kalır.
  final ValueChanged<int>? onPageChanged;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim ve balon
  /// düzenleme kapalı, metin seçimi yine açık.
  final ValueChanged<Attachment>? onChanged;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  /// Ekin GÜNCEL hâli. KÖK NEDEN: değişiklikler eskiden hep AÇILIŞTAKİ
  /// `widget.attachment` üstüne kuruluyordu (rota yeniden kurulmaz) — önce
  /// çizip sonra balon bırakınca balon yazımı çizimi açılıştaki hâline
  /// geri döndürüyordu. Her değişiklik bu kopyaya işlenir.
  late Attachment _current = widget.attachment;

  void _emit(Attachment next) {
    _current = next;
    widget.onChanged?.call(next);
  }

  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) => _emit(_current.copyWith(ink: strokes)),
  );

  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) => _emit(_current.copyWith(bubbles: list)),
    hidden: widget.attachment.bubblesHidden,
    onHiddenChanged: (hidden) =>
        _emit(_current.copyWith(bubblesHidden: hidden)),
  );

  final _pdf = PdfViewerController();
  final _selection = PdfSelectionState();

  /// Görüntüleyicinin KENDİ sayfası: `onPageChanged` her kaydırmada gelir,
  /// aynı sayfa iki kez bildirilmesin.
  late int _page = widget.initialPage;

  /// Çizim modu ekran durumu.
  bool _editing = false;

  /// **ALAN SEÇİMİ** kipi (bkz. [AreaSelectLayer]): açıkken sayfanın üstünde
  /// dikdörtgen çizilir, kapalıyken katman hiç kurulmaz.
  bool _areaMode = false;

  /// Alan seçiminin yakalayacağı katman: belge + üzerine konmuş vurgu, balon
  /// ve el yazısı. Seçim çerçevesi bu sınırın DIŞINDA duruyor (bkz.
  /// [captureBoundaryArea]).
  final _areaBoundary = GlobalKey();

  /// Kenar oto-kaydırması: seçim sürüklenirken işaretçinin son EKRAN konumu
  /// (katman bildirir; null = sürükleme yok) ve kareye bağlı itme döngüsü.
  Offset? _dragPos;
  FrameLoop? _edgeLoop;

  @override
  void initState() {
    super.initState();
    // Balon taşımasında pan KİLİTLENMEZ: kilit `PdfViewerParams`ı değiştirip
    // jestin ortasında görüntüleyiciyi yeniden kuruyor ve başlamış uzun
    // basışı iptal ediyordu ("hâlâ çok zor sürükleniyor"). Uzun basış jest
    // arenasını zaten kazanıyor, sayfa altta kaymıyor.
    _bubbles.onOpened = (bubble) => revealPdfBubble(
      reveal: _reveal,
      controller: _pdf,
      bubble: bubble,
      viewport: _viewportKey.currentContext ?? context,
    );
  }

  /// Açılan balonu görünür kılan (yerleşim oturunca, gerekirse) yardımcı.
  late final _reveal = BubbleReveal(_bubbles);

  /// Görüntüleyici + yazma kartının kutusu (görünür alan buradan ölçülür).
  final _viewportKey = GlobalKey();

  @override
  void dispose() {
    _reveal.cancel();
    _edgeLoop?.dispose();
    _ink.dispose();
    _bubbles.dispose();
    _selection.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
      // Çizim açılırken balon ekleme kipi kapanır: iki kip aynı parmağı ister.
      if (_editing) _bubbles.setAdding(false);
      if (_editing) _areaMode = false;
    });
  }

  /// Alan seçimini açar/kapatır. Diğer iki kip (çizim, balon bırakma) kapanır:
  /// üçü de aynı parmağı bekliyor.
  void _toggleAreaMode() {
    setState(() {
      _areaMode = !_areaMode;
      if (!_areaMode) return;
      if (_editing) {
        _editing = false;
        _ink.setEditing(false);
      }
      _bubbles.setAdding(false);
    });
  }

  Future<void> _copySelection() async {
    final text = cleanPdfCopyText(_selection.text.value);
    if (text.isEmpty) return;
    final message = context.l10n.pdfSelectCopied(text.length);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Toplu balon listesini açar; "balona git" seçilirse o sayfaya gidip balonu
  /// tek başına açar.
  Future<void> _openBubbles() async {
    final target = await showBubblesOverview(context, _bubbles);
    if (target == null || !mounted) return;
    if (_pdf.isReady) _pdf.goToPage(pageNumber: target.page);
    _bubbles.openOnly(target.id);
  }

  /// Seçim sürüklemesinin ekran konumu değişti (null = bitti). Kenara
  /// yaklaşınca kare döngüsü görüntüyü o yöne iter.
  void _onSelectDragAt(Offset? global) {
    _dragPos = global;
    if (global == null) {
      _edgeLoop?.stop();
      return;
    }
    (_edgeLoop ??= FrameLoop(_edgeStep, vsync: this)).start();
  }

  /// Kenar itmesinin bir karesi (F2.2: vsync'e bağlı, 120 Hz'de de aynı hız).
  void _edgeStep(double scale) {
    final pos = _dragPos;
    if (pos == null || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final delta = edgeAutoScrollDelta(box.globalToLocal(pos), box.size) * scale;
    if (delta == Offset.zero) return;
    try {
      _pdf.value = _pdf.value.clone()
        ..leftTranslateByDouble(-delta.dx, -delta.dy, 0, 1);
    } catch (_) {
      // Görüntüleyici henüz hazır değilse (yarış) itme sessizce atlanır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = widget.attachment;
    final editable = widget.onChanged != null;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        localFileExists(attachment.localPath);

    // Yalnız pan kilidi değişince yeniden kurulur (hareket başına iki kez).
    Widget viewer = ValueListenableBuilder<bool>(
      valueListenable: _selection.selecting,
      builder: (context, dragging, _) {
        final params = pdfLayerParams(
          selection: _selection,
          bubbles: _bubbles,
          inkLayer: (page) => InkPageLayer(controller: _ink, page: page),
          inkEditing: _editing,
          dragging: dragging,
          editable: editable,
          onSelectDragAt: _onSelectDragAt,
          onPageChanged: (page) {
            if (page == null || page == _page) return;
            _page = page;
            widget.onPageChanged?.call(page);
          },
          // Belge açılır açılmaz kaldığı sayfaya gider.
          onViewerReady: (document, controller) {
            if (widget.initialPage > 1 &&
                widget.initialPage <= document.pages.length) {
              controller.goToPage(pageNumber: widget.initialPage);
            }
          },
        );
        return PdfDocumentView(
          attachment: attachment,
          hasLocal: hasLocal,
          controller: _pdf,
          params: params,
          ink: _ink,
          penMode: _editing,
        );
      },
    );

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        _ink.save();
        // Yazılmadan bırakılan serbest balon anlamsız bir nokta olarak kalmasın
        // (vurgular korunur — kendi başlarına anlamlılar).
        _bubbles.dropEmpty();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
              tooltip: _areaMode ? l10n.areaSelectOff : l10n.areaSelect,
              isSelected: _areaMode,
              icon: const Icon(Icons.crop_free),
              onPressed: _toggleAreaMode,
            ),
            IconButton(
              tooltip: l10n.bubblesOverviewTitle,
              icon: const Icon(Icons.forum_outlined),
              onPressed: _openBubbles,
            ),
            if (editable)
              AnimatedBuilder(
                animation: _bubbles,
                builder: (context, _) => IconButton(
                  tooltip: _bubbles.adding
                      ? l10n.bubbleAddDone
                      : l10n.bubbleAdd,
                  isSelected: _bubbles.adding,
                  icon: Icon(
                    _bubbles.adding
                        ? Icons.chat_bubble
                        : Icons.add_comment_outlined,
                  ),
                  onPressed: () {
                    if (!_bubbles.adding && _editing) _toggleEditing();
                    _bubbles.setAdding(!_bubbles.adding);
                  },
                ),
              ),
            if (editable)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        // Ctrl/Cmd+C: seçili metni panoya kopyalar (masaüstü alışkanlığı).
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                _copySelection,
            const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                _copySelection,
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              key: _viewportKey,
              children: [
                // Klavye açılıp kapanırken görüntüleyicinin boyu SABİT:
                // pdfrx boy değişiminde sayfa başına sıçrıyordu (bkz.
                // StableViewport).
                Positioned.fill(
                  child: StableViewport(
                    child: RepaintBoundary(key: _areaBoundary, child: viewer),
                  ),
                ),
                // Yazma kartı KLAVYENİN üstünde: Scaffold klavye kadar
                // daraldığı için "alt kenar" = klavyenin üstü (bkz. BubbleDock).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BubbleDock(
                    controller: _bubbles,
                    readOnly: !editable,
                    bottomPadding: MediaQuery.paddingOf(context).bottom,
                  ),
                ),
                // Alt gezinme çubuğunun (telefon tuşları) ALTINDA kalmasın:
                // Scaffold gövdesi bottomNavigationBar yokken sistem payını
                // eklemiyor, çubuk tuşların üstüne biniyordu.
                // Yazma kartı açıkken çubuk onun ÜSTÜNE çıkar: ikisi de alt
                // kenarda duruyor, üst üste binmesinler.
                ValueListenableBuilder<double>(
                  valueListenable: _bubbles.dockHeight,
                  builder: (context, dock, child) => Positioned(
                    left: 8,
                    right: 8,
                    bottom:
                        16 + MediaQuery.viewPaddingOf(context).bottom + dock,
                    child: child!,
                  ),
                  child: PdfSelectionBar(
                    selection: _selection,
                    bubbles: _bubbles,
                  ),
                ),
                // Alan seçimi EN ÜSTTE ve yakalanan sınırın DIŞINDA: karartma
                // ile seçim çerçevesi görüntüye karışmaz, yönerge şeridi de
                // seçim çubuğunun altında kalmaz.
                if (_areaMode)
                  Positioned.fill(
                    child: AreaSelectLayer(
                      boundaryKey: _areaBoundary,
                      onCancel: _toggleAreaMode,
                      onCaptured: (png) => showAreaActions(context, png),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : ValueListenableBuilder<bool>(
                valueListenable: _bubbles.addingListenable,
                builder: (context, adding, _) => adding
                    ? BubbleToolbar(controller: _bubbles)
                    : const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Açılan balonu PDF'te görünür kılar (bkz. [BubbleReveal] — ne zaman ve ne
/// kadar kaydırılacağına o karar verir; burada yalnız PDF'in kaydırma dili).
///
/// Tam ekran görüntüleyici ile pano bölmesi aynı kodu kullansın diye burada.
void revealPdfBubble({
  required BubbleReveal reveal,
  required PdfViewerController controller,
  required PageBubble bubble,
  required BuildContext viewport,
}) {
  reveal.request(
    bubble,
    viewport: StableViewport.contextOf(viewport),
    scrollBy: (dy) {
      if (!controller.isReady) return;
      // Ekran pikseliyle kaydırma = dönüşümün ÖNÜNE öteleme.
      final next = Matrix4.translationValues(0, -dy, 0)
        ..multiply(controller.value);
      controller.goTo(next, duration: const Duration(milliseconds: 260));
    },
    centerUnbuilt: (top, height) {
      if (!controller.isReady) return;
      try {
        // pdfrx 1.3.x'te sayfa ölçüsüne tek erişim bu; `useDocument` eşleniği
        // 2.x ile geliyor ve o sürüm bu projede kullanılamıyor.
        // ignore: deprecated_member_use
        final page = controller.pages[bubble.page - 1];
        // Balonun sayfa oranlı konumu → PDF puntosu (sol-ALT orijin).
        final x = bubble.x * page.width;
        final y = (1 - bubble.y) * page.height;
        final at = controller
            .calcRectForRectInsidePage(
              pageNumber: bubble.page,
              rect: PdfRect(x - 1, y + 1, x + 1, y - 1),
            )
            .center;
        final view = controller.viewSize;
        final matrix = controller.calcMatrixFor(
          at,
          viewSize: Size(view.width, height),
        );
        controller.goTo(
          Matrix4.translationValues(0, top, 0)..multiply(matrix),
          duration: const Duration(milliseconds: 260),
        );
      } catch (_) {
        // Belge henüz hazır değilse (yarış) ortalama sessizce atlanır.
      }
    },
  );
}

/// Seçim + balon + (varsa) çizim katmanlarını taşıyan `PdfViewerParams`.
///
/// Tam ekran görüntüleyici ile not panosunun bölmesi AYNI katman düzenini
/// paylaşsın diye burada, tek kopya (kullanıcı isteği: "PDF üzerinde metin
/// seçme, üzerine yazı yazma tam ekran yapmadan da çalışmalı").
///
/// **Performans:** parametre nesnesi seçim değiştikçe YENİDEN KURULMAZ —
/// katmanların içi `ValueListenableBuilder`/`AnimatedBuilder` ile kendi
/// başına tazelenir. Eskiden her seçim olayı ekranın `setState`ini çağırıyor,
/// o da tüm sayfa katmanlarını yeniden kuruyordu (kasmanın kök nedeni).
PdfViewerParams pdfLayerParams({
  required PdfSelectionState selection,
  required BubbleController bubbles,
  required bool editable,
  Widget Function(int page)? inkLayer,
  bool inkEditing = false,
  bool dragging = false,
  ValueChanged<Offset?>? onSelectDragAt,
  void Function(PdfDocument document, PdfViewerController controller)?
  onViewerReady,
  ValueChanged<int?>? onPageChanged,
}) => PdfViewerParams(
  // Sürükleyerek seçim ya da balon taşıma sürerken pan kapalı: parmak seçimi
  // büyütür / balonu taşır, sayfa kaymaz. Bu bayrak jest BAŞINDA ve SONUNDA
  // (saniyede iki kez değil, hareket başına iki kez) değişir; params o anda
  // yeniden kurulur ama belge YÜKLENMEZ — pdfrx yalnız documentRef
  // değişiminde yükler.
  panEnabled: !inkEditing && !dragging,
  scaleEnabled: !inkEditing,
  onViewerReady: onViewerReady,
  onPageChanged: onPageChanged,
  pageOverlaysBuilder: (context, pageRect, page) => [
    // Katmanların TAMAMI tek bir dinleyicinin altında: seçim/balon durumu
    // değişince yalnız burası tazelenir, görüntüleyici kurulmaz.
    //
    // `selection.page` de dinlenir ki seçim başka bir sayfaya geçince bu
    // sayfanın katmanı kendi vurgusunu bıraksın (tek etkin seçim).
    // `RepaintBoundary`: sayfa kaydırılırken katmanların çizimi belgenin
    // kendi katmanına karışmasın — kaydırmadaki takılmanın paylarından biri.
    Positioned.fill(
      child: RepaintBoundary(
        child: ValueListenableBuilder<int>(
          valueListenable: selection.page,
          // YALNIZ "balon bırak" kipi dinlenir (seçim katmanını kapatıp açan
          // tek şey o). Balon katmanı kendi dinleyicisiyle, yalnız KENDİ
          // sayfası değişince tazelenir (bkz. BubblePageLayer).
          builder: (context, activePage, _) => ValueListenableBuilder<bool>(
            valueListenable: bubbles.addingListenable,
            builder: (context, adding, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                if (!inkEditing && !adding)
                  PdfSelectLayer(
                    page: page,
                    pageSize: pageRect.size,
                    activeSelectionPage: activePage,
                    // Düzenlenebilir görünümde basılı tutmak balon bırakır;
                    // seçim çift dokunuşla (bkz. longPressSelects).
                    longPressSelects: !editable,
                    onSelected: (text, rects, pageNo, fromOcr) => selection.set(
                      value: text,
                      pageNumber: pageNo,
                      pdfRects: rects,
                      source: page,
                    ),
                    onSelectingChanged: (value) =>
                        selection.selecting.value = value,
                    onDragAt: onSelectDragAt,
                  ),
                if (inkLayer != null)
                  Positioned.fill(child: inkLayer(page.pageNumber)),
                Positioned.fill(
                  child: BubblePageLayer(
                    controller: bubbles,
                    page: page.pageNumber,
                    readOnly: !editable,
                    longPressAdd: !inkEditing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
