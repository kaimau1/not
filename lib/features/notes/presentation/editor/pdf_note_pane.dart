import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/local_file.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../viewers/bubble_layer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_selection_bar.dart';
import '../viewers/pdf_viewer_screen.dart';
import 'bubbles_overview.dart';
import 'page_note_pane.dart';
import 'text_wrap.dart';

/// "PDF ekle not al" notunun gövdesi: ÜSTTE PDF sayfası, ALTTA (istenirse) o
/// sayfanın notu.
///
/// Asıl çalışma aracı sayfanın ÜZERİdir: metin seçilir, vurgulanır, balon
/// bırakılır — hepsi tam ekrana geçmeden, bu bölmede. Alt not alanı varsayılan
/// olarak kapalıdır (bkz. [PageNotePane]).
class PdfNotePane extends StatefulWidget {
  const PdfNotePane({
    super.key,
    required this.noteOf,
    required this.attachment,
    required this.onPageNoteChanged,
    required this.onAttachmentChanged,
    this.onEditPages,
    this.textStyle,
    this.richTheme,
    this.onFieldFocused,
    this.onFieldDisposed,
    this.onImmersiveChanged,
    this.penMode = false,
    this.onPenModeChanged,
  });

  /// Sayfanın ÜZERİNE yazma kipi (editörün alt çubuğundaki kalem düğmesi).
  /// Açıkken bölmede tek parmak çizer, iki parmak gezinir ve bölmenin altında
  /// kalem çubuğu belirir — tam ekrana geçmeye gerek kalmaz (kullanıcı isteği
  /// 2026-08-08: "pdf üzerine yazma kalemini gösterdiğim alana al").
  final bool penMode;
  final ValueChanged<bool>? onPenModeChanged;

  /// Balona yazılırken true: editör kendi alt çubuğunu (Biçim/Ekle/AI) ve ek
  /// şeridini gizler. Klavye + iki bölme + iki çubuk aynı anda sığmıyor.
  final ValueChanged<bool>? onImmersiveChanged;

  final Note Function() noteOf;
  final Attachment attachment;
  final void Function(int page, String text) onPageNoteChanged;

  /// Tam ekran görüntüleyicide yapılan çizim/balon ekle birlikte geri gelir.
  final ValueChanged<Attachment> onAttachmentChanged;

  /// Sayfa yöneticisini açar (sil/döndür/sırala + çizimi belgeye gömme).
  /// null = düzenleme kapalı.
  final Future<void> Function(int pageCount)? onEditPages;

  final TextStyle? textStyle;
  final RichTextTheme? richTheme;
  final void Function(
    WrapTextController controller,
    FocusNode focusNode,
    VoidCallback commit,
  )?
  onFieldFocused;
  final ValueChanged<WrapTextController>? onFieldDisposed;

  @override
  State<PdfNotePane> createState() => _PdfNotePaneState();
}

class _PdfNotePaneState extends State<PdfNotePane> {
  /// Çizimler bölmede de DÜZENLENİR (kalem kipi açıkken). Eskiden yalnız tam
  /// ekranda düzenlenebiliyordu; gerekçe "küçük bölmede tek parmakla çizim
  /// sayfayı kaydırmayı imkânsız kılıyor" idi. Artık çizim açık bir KİPTİR:
  /// açıkken tek parmak çizer, iki parmak gezinir; kapalıyken sayfa eskisi
  /// gibi kayar. Kullanıcı kalemi kendisi açtığı için sürpriz yok.
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(ink: strokes)),
  );

  /// Balonlar BURADA da düzenlenir (çizimden farkı bu): balon metin alanıdır,
  /// küçük bölmede de tıklanıp yazılabilir ve kullanıcı belgenin üzerinde
  /// planını tam ekrana geçmeden kurar.
  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(bubbles: list)),
  );

  /// Balon yazılırken alt not alanı gizlenir — iki bölme + klavye aynı anda
  /// sığmıyor ve balon kartı bölmenin dışında kalıyordu.
  final _bubbleEditing = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _bubbles.onEditingChanged = (editing) {
      _bubbleEditing.value = editing;
      widget.onImmersiveChanged?.call(editing);
    };
    _bubbles.addingListenable.addListener(_onAddingChanged);
  }

  /// Balon bırakma açılınca kalem kapanır: iki kip aynı parmağı ister. Ters
  /// yön (kalem açılınca balon kipi kapanır) görüntüleyicide.
  void _onAddingChanged() {
    if (_bubbles.adding && widget.penMode) {
      widget.onPenModeChanged?.call(false);
    }
  }

  /// Balon listesi; seçilen balonun sayfasına gidilir ve balon açılır.
  Future<void> _openBubbles(ValueChanged<int> goToPage) async {
    final target = await showBubblesOverview(context, _bubbles);
    if (target == null || !mounted) return;
    goToPage(target.page);
    _bubbles.openOnly(target.id);
  }

  @override
  void didUpdateWidget(PdfNotePane old) {
    super.didUpdateWidget(old);
    // Tam ekranda çizim/balon eklenip dönüldüyse pano da tazelenir.
    // Kimlik değil İÇERİK karşılaştırması denetleyicinin içinde yapılıyor
    // (her anlık görüntü yeni liste kuruyor — bkz. InkController.replace).
    _ink.replace(widget.attachment.ink);
    _bubbles.replace(widget.attachment.bubbles);
  }

  @override
  void dispose() {
    _bubbles.addingListenable.removeListener(_onAddingChanged);
    _ink.dispose();
    _bubbles.dispose();
    _bubbleEditing.dispose();
    super.dispose();
  }

  Future<void> _openFullScreen() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PdfViewerScreen(
        attachment: widget.attachment,
        onChanged: widget.onAttachmentChanged,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PageNotePane(
    onEditPages: widget.onEditPages,
    noteOf: widget.noteOf,
    attachment: widget.attachment,
    onPageNoteChanged: widget.onPageNoteChanged,
    textStyle: widget.textStyle,
    richTheme: widget.richTheme,
    onFieldFocused: widget.onFieldFocused,
    onFieldDisposed: widget.onFieldDisposed,
    onFullScreen: _openFullScreen,
    suppressNotes: _bubbleEditing,
    barActions: (context, goToPage, compact) => BubbleBarActions(
      controller: _bubbles,
      compact: compact,
      onOpenList: () => _openBubbles(goToPage),
    ),
    viewerBuilder: (context, host) => _PdfPaneViewer(
      attachment: widget.attachment,
      ink: _ink,
      bubbles: _bubbles,
      host: host,
      penMode: widget.penMode,
    ),
  );
}

/// Panonun üst bölmesindeki pdfrx görüntüleyicisi.
///
/// Sayfa durumu PANODA: [PageNoteHost.page] dışarıdan değişince (sayfa
/// düğmeleri, toplu görünüm) belge oraya kaydırılır; kullanıcı belgeyi elle
/// kaydırırsa [PageNoteHost.onPageChanged] ile pano haberdar edilir.
class _PdfPaneViewer extends StatefulWidget {
  const _PdfPaneViewer({
    required this.attachment,
    required this.ink,
    required this.bubbles,
    required this.host,
    required this.penMode,
  });

  final Attachment attachment;
  final InkController ink;
  final BubbleController bubbles;
  final PageNoteHost host;
  final bool penMode;

  @override
  State<_PdfPaneViewer> createState() => _PdfPaneViewerState();
}

class _PdfPaneViewerState extends State<_PdfPaneViewer> {
  final _pdf = PdfViewerController();
  final _selection = PdfSelectionState();

  Timer? _centerTimer;

  /// Görüntüleyicinin KENDİ gösterdiği sayfa (1 tabanlı).
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-08: "PDF sayfa geçişleri düzgün
  /// değil, zıplamalar oluyor"): kullanıcı parmağıyla kaydırdığında pdfrx
  /// `onPageChanged` ile panoya haber veriyor, pano `setState` ile yeni bir
  /// [PageNoteHost] kuruyor ve buradaki `didUpdateWidget` "pano sayfa
  /// değiştirmiş" sanıp `goToPage` çağırıyordu — yani kaydırmanın ORTASINDA
  /// belge sayfa başına sıçratılıyordu. Pano sayfası bizim bildirdiğimizle
  /// aynıysa sıçratma YAPILMAZ; sıçratma yalnız DIŞARIDAN gelen sayfa
  /// değişimlerinde (sayfa okları, toplu görünüm, balona git) çalışır.
  /// Aynı tuzak ve aynı çözüm slayt bölmesinde de var (bkz. slide_note_pane).
  int _page = 1;

  @override
  void initState() {
    super.initState();
    if (widget.penMode) widget.ink.setEditing(true);
    // Balon taşımasında pan kilidi YOK (bkz. BubbleController açıklaması).
    // Açılan balon, yazma kartının üstünde kalan alanın ortasına getirilir.
    widget.bubbles.onOpened = (bubble) => centerPdfOnBubble(
      controller: _pdf,
      bubble: bubble,
      timer: (t) => _centerTimer = t,
      previous: _centerTimer,
      freeBelow: () => widget.bubbles.dockHeight.value,
      alive: () => mounted,
    );
  }

  @override
  void didUpdateWidget(_PdfPaneViewer old) {
    super.didUpdateWidget(old);
    if (old.penMode != widget.penMode) {
      // Kalem açılırken balon bırakma kipi kapanır: iki kip aynı parmağı
      // ister (tam ekran görüntüleyicideki kuralın aynısı).
      widget.ink.setEditing(widget.penMode);
      if (widget.penMode) widget.bubbles.setAdding(false);
    }
    // Pano başka bir sayfaya geçti: belge oraya kayar. Görüntüleyici hazır
    // değilse (dosya hâlâ iniyor) atlanır — pano zaten kendi sayfasını
    // gösteriyor, kullanıcı notunu beklemeden yazabilir.
    //
    // Panonun sayfası ZATEN bizim bildirdiğimizse dokunulmaz: yoksa
    // kullanıcının kendi kaydırması geri sıçratılır (bkz. [_page]).
    if (widget.host.page != _page && _pdf.isReady) {
      _page = widget.host.page;
      _pdf.goToPage(pageNumber: widget.host.page);
    }
  }

  @override
  void dispose() {
    _centerTimer?.cancel();
    _selection.dispose();
    super.dispose();
  }

  /// Belge görüntüleyicisi — KURULDUĞU GİBİ SAKLANIR.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-15: "balonlu modda kasma"): pano
  /// her `setState`inde (kullanıcı kaydırıp sayfa sınırını geçince, bölme
  /// tutamağı sürüklenirken, alt not açılıp kapanınca) bu bölmeyi yeniden
  /// kuruyordu; o da her seferinde yeni bir `PdfViewerParams` ve yeni bir
  /// `PdfViewer` demekti — görünen bütün sayfaların seçim, kalem ve balon
  /// katmanları baştan kuruluyordu. Aynı widget örneği verilince Flutter alt
  /// ağacı hiç gezmez. Görüntüleyici yalnız KAYNAĞI (dosya/adres) ya da kalem
  /// kipi değişince yeniden kurulur; geri çağırmalar `widget`ı çağrı anında
  /// okuduğu için güncel pano bilgisiyle çalışır.
  Widget _viewerFor(Attachment attachment, bool hasLocal) {
    final source = hasLocal
        ? 'f:${attachment.localPath}'
        : 'u:${attachment.downloadUrl}';
    final cached = _viewer;
    if (cached != null &&
        _viewerSource == source &&
        _viewerPen == widget.penMode) {
      return cached;
    }
    _viewerSource = source;
    _viewerPen = widget.penMode;
    // Katmanların tamamı (seçim, çizim, balon) tam ekran görüntüleyiciyle
    // AYNI kurulumdan gelir: "tam ekran yapmadan da çalışsın" isteğinin tek
    // kopyalı karşılığı (bkz. pdfLayerParams).
    return _viewer = ValueListenableBuilder<bool>(
      valueListenable: _selection.selecting,
      builder: (context, dragging, _) {
        final params = pdfLayerParams(
          selection: _selection,
          bubbles: widget.bubbles,
          editable: true,
          dragging: dragging,
          inkEditing: widget.penMode,
          inkLayer: (page) => InkPageLayer(controller: widget.ink, page: page),
          onPageChanged: (page) {
            if (page == null || page == _page) return;
            // Önce KENDİ sayfamız işaretlenir: pano bu haberi işleyip geri
            // geldiğinde `didUpdateWidget` sıçratmasın (bkz. [_page]).
            _page = page;
            widget.host.onPageChanged(page);
          },
          onViewerReady: (document, controller) {
            widget.host.onPageCount(document.pages.length);
            // Pano başka bir sayfadaysa (toplu görünümden gelindi) belge
            // açılır açılmaz oraya gidilir.
            if (widget.host.page > 1) {
              _page = widget.host.page;
              controller.goToPage(pageNumber: widget.host.page);
            }
          },
        );
        final viewer = hasLocal
            ? PdfViewer.file(
                attachment.localPath,
                controller: _pdf,
                params: params,
              )
            : PdfViewer.uri(
                Uri.parse(attachment.downloadUrl),
                controller: _pdf,
                params: params,
              );
        // Kalem açıkken İKİ PARMAK gezinir: çizim katmanı tek parmağı aldığı
        // için yakınlaştırma/kaydırma bu katmandan yapılır (tam ekran
        // görüntüleyicideki kurulumun aynısı).
        return InkNavLayer(
          enabled: widget.penMode,
          controller: widget.ink,
          getMatrix: () => _pdf.isReady ? _pdf.value : null,
          setMatrix: (m) => _pdf.value = m,
          minScale: 0.1,
          maxScale: 8,
          child: viewer,
        );
      },
    );
  }

  Widget? _viewer;
  String? _viewerSource;
  bool? _viewerPen;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        localFileExists(attachment.localPath);
    if (!hasLocal && !attachment.isUploaded) {
      // Dosya ne cihazda ne bulutta: başka bir cihazda eklenmiş ve henüz
      // senkronlanmamış olabilir. Notlar yine yazılabilsin diye ekran
      // kilitlenmez.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.attachmentNotSynced,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final viewer = _viewerFor(attachment, hasLocal);
    return Stack(
      children: [
        Positioned.fill(child: viewer),
        // Yazma kartı bölmenin ALT kenarında — klavye açıkken tam onun üstü.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BubbleDock(controller: widget.bubbles),
        ),
        // **BALON ARAÇ ÇUBUĞU BURADA DA VAR** (kullanıcı bulgusu 2026-08-18:
        // "bu balon PDF ekle not al modunda yok, sadece metin içi PDF
        // eklendiğinde çıkıyor"). Çubuk yalnız tam ekran görüntüleyicilere
        // konmuştu; balonlu kipin KENDİ ekranında — yani "PDF/sunum ekle not
        // al" ile açılan iki bölmeli ekranda — kip seçimi (balon / açık metin)
        // ve renk paleti hiç görünmüyordu. Aynı çubuk, aynı denetleyici.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.bubbles.addingListenable,
            builder: (context, adding, _) => adding
                ? BubbleToolbar(controller: widget.bubbles)
                : const SizedBox.shrink(),
          ),
        ),
        // Kalem çubuğu bölmenin DİBİNDE: renk, kalınlık, silgi, ok, geri al.
        if (widget.penMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: InkToolbar(controller: widget.ink),
          ),
        // Yazma kartı açıkken çubuk onun üstüne çıkar (üst üste binmesin).
        ValueListenableBuilder<double>(
          valueListenable: widget.bubbles.dockHeight,
          builder: (context, dock, child) => Positioned(
            left: 8,
            right: 8,
            bottom: 8 + dock,
            child: child!,
          ),
          child: PdfSelectionBar(
            selection: _selection,
            bubbles: widget.bubbles,
            compact: true,
          ),
        ),
      ],
    );
  }
}
