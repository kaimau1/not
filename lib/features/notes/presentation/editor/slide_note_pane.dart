import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../viewers/bubble_layer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/slide_canvas.dart';
import '../viewers/slide_scroll.dart';
import '../viewers/slide_viewer_screen.dart';
import '../viewers/zoom_box.dart';
import 'bubbles_overview.dart';
import 'page_note_pane.dart';
import 'text_wrap.dart';

/// "Sunum ekle not al" notunun gövdesi: ÜSTTE slayt, ALTTA o slaydın notu.
///
/// PDF sürümünün birebir eşi; tek fark üst bölmedeki görüntüleyici. Not
/// tarafının tamamı (sayfa çubuğu, bölme tutamağı, alan, toplu görünüm) ortak
/// [PageNotePane]'dedir — "slayt notu" ile "sayfa notu" aynı veri modelini
/// (`Note.pageNotes`) ve aynı kimlik düzenini kullanır, yani toplu görünüm de
/// olduğu gibi çalışır.
class SlideNotePane extends ConsumerStatefulWidget {
  const SlideNotePane({
    super.key,
    required this.noteOf,
    required this.attachment,
    required this.onPageNoteChanged,
    required this.onAttachmentChanged,
    this.textStyle,
    this.richTheme,
    this.onFieldFocused,
    this.onFieldDisposed,
    this.onImmersiveChanged,
    this.penMode = false,
    this.onPenModeChanged,
  });

  /// Slaydın ÜZERİNE yazma kipi (editörün alt çubuğundaki kalem düğmesi).
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "slayt modunda alttaki düzenleme
  /// üzerine çizme kalemi çalışmıyor"): kalem düğmesi editörde tek bir
  /// `_penMode` bayrağını çeviriyor ama o bayrak yalnızca [PdfNotePane]'e
  /// bağlanmıştı — slayt panosu parametreyi hiç almıyordu, dolayısıyla düğme
  /// slaytta hiçbir şey yapmıyordu. Artık iki pano da AYNI sözleşmeyi taşıyor:
  /// açıkken tek parmak çizer, iki parmak gezinir ve panonun dibinde kalem
  /// çubuğu (renk, kalınlık, ok, **silgi**, geri al, temizle) belirir.
  final bool penMode;
  final ValueChanged<bool>? onPenModeChanged;

  /// Balona yazılırken true (PDF panosuyla aynı sözleşme).
  final ValueChanged<bool>? onImmersiveChanged;

  final Note Function() noteOf;
  final Attachment attachment;
  final void Function(int page, String text) onPageNoteChanged;
  final ValueChanged<Attachment> onAttachmentChanged;

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
  ConsumerState<SlideNotePane> createState() => _SlideNotePaneState();
}

class _SlideNotePaneState extends ConsumerState<SlideNotePane> {
  /// Çizimler bölmede de DÜZENLENİR (kalem kipi açıkken) — PDF panosundaki
  /// kurulumun aynısı. Kip kapalıyken katman dokunuşa hiç karışmaz, yani slayt
  /// listesi eskisi gibi tek parmakla kayar.
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(ink: strokes)),
  );

  /// Not balonları burada da düzenlenir (çizimden farkı: balon metindir,
  /// küçük bölmede de tıklanıp yazılabilir).
  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(bubbles: list)),
    hidden: widget.attachment.bubblesHidden,
    onHiddenChanged: (hidden) => widget.onAttachmentChanged(
      widget.attachment.copyWith(bubblesHidden: hidden),
    ),
  );

  /// Balon yazılırken alt not alanı gizlenir (PDF panosuyla aynı gerekçe:
  /// iki bölme + klavye sığmıyor).
  final _bubbleEditing = ValueNotifier<bool>(false);

  List<SlideVM>? _slides;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.penMode) _ink.setEditing(true);
    _bubbles.onEditingChanged = (editing) {
      _bubbleEditing.value = editing;
      widget.onImmersiveChanged?.call(editing);
    };
    _bubbles.addingListenable.addListener(_onAddingChanged);
    _load();
  }

  /// Balon bırakma açılınca kalem kapanır (PDF panosuyla aynı kural).
  void _onAddingChanged() {
    if (_bubbles.adding && widget.penMode) {
      widget.onPenModeChanged?.call(false);
    }
  }

  /// Balon listesi; seçilen balonun slaydına gidilir ve balon açılır.
  Future<void> _openBubbles(ValueChanged<int> goToPage) async {
    final target = await showBubblesOverview(context, _bubbles);
    if (target == null || !mounted) return;
    goToPage(target.page);
    _bubbles.openOnly(target.id);
  }

  @override
  void didUpdateWidget(SlideNotePane old) {
    super.didUpdateWidget(old);
    if (old.penMode != widget.penMode) {
      // Kalem açılırken balon bırakma kipi kapanır: iki kip aynı parmağı ister
      // (tam ekran görüntüleyicideki ve PDF panosundaki kuralın aynısı).
      _ink.setEditing(widget.penMode);
      if (widget.penMode) _bubbles.setAdding(false);
    }
    // Kimlik değil İÇERİK karşılaştırması denetleyicinin içinde yapılıyor
    // (her anlık görüntü yeni liste kuruyor — bkz. InkController.replace).
    _ink.replace(widget.attachment.ink);
    _bubbles
      ..replace(widget.attachment.bubbles)
      ..syncHidden(widget.attachment.bubblesHidden);
    // Dosya bu arada senkronlandıysa (başka cihazda eklenmiş sunum indi)
    // yeniden denenir; yoksa pano sonsuza dek "açılamadı" derdi.
    if (_slides == null &&
        _error != null &&
        old.attachment.downloadUrl != widget.attachment.downloadUrl) {
      _error = null;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final bytes = await ref
          .read(attachmentRepositoryProvider)
          ?.readBytes(widget.attachment);
      if (bytes == null) {
        if (mounted) setState(() => _error = 'no-bytes');
        return;
      }
      final slides = await SlideDeck.fromBytes(bytes);
      if (mounted) setState(() => _slides = slides);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    // Yazma kartı açıkken bölme kalkarsa (klasik görünüme geçildi) editör
    // sade "yazma kipinde" kalmasın: kare sonunda geri alınır (editörün
    // geri çağrısı kendi `mounted`ını denetler).
    if (_bubbleEditing.value) {
      final onImmersive = widget.onImmersiveChanged;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onImmersive?.call(false),
      );
    }
    _bubbles.addingListenable.removeListener(_onAddingChanged);
    _ink.dispose();
    _bubbles.dispose();
    _bubbleEditing.dispose();
    super.dispose();
  }

  Future<void> _openFullScreen() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SlideViewerScreen(
        attachment: widget.attachment,
        onChanged: widget.onAttachmentChanged,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PageNotePane(
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
    viewerBuilder: (context, host) => _SlidePaneViewer(
      slides: _slides,
      error: _error,
      ink: _ink,
      bubbles: _bubbles,
      host: host,
      penMode: widget.penMode,
    ),
  );
}

/// Panonun üst bölmesindeki slayt görüntüleyicisi.
///
/// Tam ekran sürümündeki yakınlaştırma/çizim jestleri BURADA yok: bölme küçük
/// ve alt tarafta bir yazı alanı var; iki parmak jestleri klavye açılıp
/// kapanırken kazara tetikleniyordu. Yakınlaştırma ve çizim tam ekranda.
class _SlidePaneViewer extends StatefulWidget {
  const _SlidePaneViewer({
    required this.slides,
    required this.error,
    required this.ink,
    required this.bubbles,
    required this.host,
    required this.penMode,
  });

  final List<SlideVM>? slides;
  final Object? error;
  final InkController ink;
  final BubbleController bubbles;
  final PageNoteHost host;
  final bool penMode;

  @override
  State<_SlidePaneViewer> createState() => _SlidePaneViewerState();
}

class _SlidePaneViewerState extends State<_SlidePaneViewer> {
  /// Görünen slayt YAKINLAŞTIRILMIŞ mı? Yakınken liste kilitlenir — tek parmak
  /// büyütülmüş slaytta gezinmektir, kaydırmak değil.
  bool _zoomed = false;

  /// Slaytlar PDF gibi ALT ALTA kayar (bkz. [SlideStripMetrics]); yatay
  /// `PageView` bırakıldı.
  final _scroll = ScrollController();

  /// Son çizimdeki ölçüler ve görünür yükseklik — kaydırma konumundan slayt
  /// numarası (ve tersi) bunlarla hesaplanır.
  SlideStripMetrics? _metrics;
  double _viewport = 0;

  /// Kaydırmayla varılan slayt. Panodan gelen istek bununla karşılaştırılır:
  /// aksi hâlde "kaydır → panoyu haberdar et → pano geri sıçrat" döngüsü olur.
  int _page = 1;

  bool _positioned = false;

  /// Açılan balonu görünür kılan yardımcı (bkz. [BubbleReveal]).
  late final _reveal = BubbleReveal(widget.bubbles);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.bubbles.onOpened = _centerOn;
  }

  @override
  void didUpdateWidget(_SlidePaneViewer old) {
    super.didUpdateWidget(old);
    final slides = widget.slides;
    if (slides != null && old.slides?.length != slides.length) {
      widget.host.onPageCount(slides.length);
    }
    // Pano başka bir slayda geçti (düğme ya da toplu görünüm): liste oraya
    // kayar. Kaydırmanın KENDİ bildirdiği sayfa için sıçratma yapılmaz.
    if (widget.host.page != _page) _goToPage(widget.host.page);
  }

  @override
  void dispose() {
    _reveal.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final metrics = _metrics;
    if (metrics == null || !_scroll.hasClients) return;
    final page = metrics.pageAt(_scroll.offset, _viewport);
    if (page == _page) return;
    _page = page;
    widget.host.onPageChanged(page);
  }

  void _goToPage(int page) {
    final metrics = _metrics;
    if (metrics == null || !_scroll.hasClients) return;
    _page = page;
    _scroll.jumpTo(
      metrics.startOf(page).clamp(0.0, _scroll.position.maxScrollExtent),
    );
  }

  /// Açılan balonu gerekirse (yalnız görünmüyorsa) yazma kartının üstünde
  /// kalan alanın ortasına getirir — yerleşim oturduktan sonra, tek kez
  /// (bkz. [BubbleReveal]).
  void _centerOn(PageBubble bubble) => _reveal.request(
    bubble,
    viewport: context,
    scrollBy: (dy) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      _scroll.animateTo(
        (position.pixels + dy).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    },
    centerUnbuilt: (top, height) {
      final metrics = _metrics;
      if (!mounted || metrics == null || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      final target =
          metrics.centerOffset(
            page: bubble.page,
            y: bubble.y,
            free: height,
            maxScroll: max,
          ) -
          top;
      _scroll.animateTo(
        target.clamp(0.0, math.max(0.0, max)),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.slideOpenFailed,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    final slides = widget.slides;
    if (slides == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (slides.isEmpty) {
      return Center(
        child: Text(
          l10n.slideOpenFailed,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return _withOverlays(_listFor(slides));
  }

  /// Slayt listesi — KURULDUĞU GİBİ SAKLANIR (PDF panosundaki
  /// `_viewerFor` ile aynı kök neden: pano her sayfa değişiminde bu bölmeyi
  /// yeniden kuruyor, görünen bütün slaytlar baştan çiziliyordu). Liste
  /// yalnız slaytlar, kalem kipi ya da yakınlaştırma değişince kurulur.
  ///
  /// Eskiden liste balon denetleyicisinin HER bildirimini de dinliyordu
  /// (yalnız "balon taşınıyor mu" bilgisi için): balon açmak, renk seçmek
  /// görünen her slaydı yeniden çizdiriyordu. Artık yalnız
  /// [BubbleController.draggingListenable] dinlenir.
  Widget _listFor(List<SlideVM> slides) {
    final cached = _list;
    if (cached != null &&
        identical(_listSlides, slides) &&
        _listPen == widget.penMode &&
        _listZoomed == _zoomed) {
      return cached;
    }
    _listSlides = slides;
    _listPen = widget.penMode;
    _listZoomed = _zoomed;
    return _list = ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = SlideStripMetrics.forWidth([
            for (final s in slides) slideAspect(s),
          ], constraints.maxWidth);
          _metrics = metrics;
          _viewport = constraints.maxHeight;
          if (!_positioned && widget.host.page > 1) {
            _positioned = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _goToPage(widget.host.page),
            );
          }
          return ValueListenableBuilder<bool>(
            valueListenable: widget.bubbles.draggingListenable,
            builder: (context, dragging, _) => ListView.builder(
              controller: _scroll,
              // Balon taşınırken, KALEM AÇIKKEN ya da slayt
              // yakınlaştırılmışken kaydırma KİLİTLİ: parmak balonu
              // sürüklerken (ya da çizerken) listenin de kayması işi
              // imkânsız kılıyordu.
              physics: (dragging || _zoomed || widget.penMode)
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              itemCount: slides.length,
              // Yükseklikler önceden biliniyor: liste ölçmeden kurulur,
              // "balona git" tam yere gider.
              itemExtentBuilder: (index, _) => metrics.heightOf(index + 1),
              itemBuilder: (context, i) => RepaintBoundary(
                child: ZoomBox(
                  // Çizimde jestler kapalı ama ölçek KORUNUR: tek parmak
                  // çizer, önceden yapılmış yakınlaştırma kaybolmaz (tam
                  // ekran görüntüleyicideki kurulumun aynısı).
                  enabled: !widget.penMode,
                  onZoomChanged: (value) {
                    if (mounted && _zoomed != value) {
                      setState(() => _zoomed = value);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(child: SlideCanvas(slide: slides[i])),
                      Positioned.fill(
                        child: InkPageLayer(
                          controller: widget.ink,
                          page: i + 1,
                        ),
                      ),
                      Positioned.fill(
                        child: BubblePageLayer(
                          controller: widget.bubbles,
                          page: i + 1,
                          longPressAdd: !widget.penMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _list;
  List<SlideVM>? _listSlides;
  bool? _listPen;
  bool? _listZoomed;

  /// Görüntüleyicinin üstündeki katmanlar: yazma kartı, balon araç kartı ve
  /// kalem çubuğu (PDF panosuyla aynı). Balon düğmeleri artık panonun alt
  /// çubuğunda (bkz. [BubbleBarActions]).
  Widget _withOverlays(Widget viewer) => Stack(
    children: [
      Positioned.fill(child: viewer),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: BubbleDock(controller: widget.bubbles),
      ),
      // **BALON ARAÇ ÇUBUĞU BURADA DA VAR** (kullanıcı bulgusu 2026-08-18:
      // "bu balon PDF ekle not al modunda yok, sadece metin içi PDF
      // eklendiğinde çıkıyor"). Aynı çubuk, aynı denetleyici.
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
      // Kalem çubuğu bölmenin DİBİNDE: renk, kalınlık, ok, silgi, geri al,
      // temizle (PDF panosuyla aynı yer ve aynı çubuk).
      if (widget.penMode)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: InkToolbar(controller: widget.ink),
        ),
    ],
  );
}
