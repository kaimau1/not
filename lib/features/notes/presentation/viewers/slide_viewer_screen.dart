import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import '../editor/bubbles_overview.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'slide_canvas.dart';
import 'slide_scroll.dart';
import 'zoom_box.dart';

/// Sunum (.pptx) ekini gerçek tasarımıyla slayt slayt gösterir. PDF'teki gibi
/// üzerine elle yazılabilir: çizim slayt oranlı vektör olarak ekin `ink`
/// alanında saklanır (dosyaya gömülmez, senkron ve düzenlenebilir).
///
/// İki parmakla yakınlaştırılır; grafik/SmartArt gibi çizilemeyen öğeler boş
/// görünür — "dosya okuyucu" motorunun mevcut sınırı (tablo çizilir).
class SlideViewerScreen extends ConsumerStatefulWidget {
  const SlideViewerScreen({
    super.key,
    required this.attachment,
    this.onChanged,
  });

  final Attachment attachment;

  /// null ise salt görüntüleme: çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  @override
  ConsumerState<SlideViewerScreen> createState() => _SlideViewerScreenState();
}

class _SlideViewerScreenState extends ConsumerState<SlideViewerScreen> {
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onChanged?.call(widget.attachment.copyWith(ink: strokes)),
  );
  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) =>
        widget.onChanged?.call(widget.attachment.copyWith(bubbles: list)),
  );
  /// Slaytlar PDF gibi ALT ALTA, boşluksuz kayar (kullanıcı isteği
  /// 2026-08-08). Yatay `PageView` bırakıldı — bkz. [SlideStripMetrics].
  final _scroll = ScrollController();
  SlideStripMetrics? _metrics;
  double _viewport = 0;
  Timer? _centerTimer;

  /// Görünen slayt yakınlaştırılmış mı? Yakınken liste kilitlenir.
  bool _zoomed = false;

  /// Çizim modu ekran durumu (görüntüleyiciyi çizgi başına yeniden kurmamak
  /// için; çizgiler InkPageLayer içinde bağımsız tazelenir).
  bool _editing = false;

  List<SlideVM>? _slides;
  Object? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _bubbles.onOpened = _centerOn;
    _load();
  }

  void _onScroll() {
    final metrics = _metrics;
    if (metrics == null || !_scroll.hasClients) return;
    final page = metrics.pageAt(_scroll.offset, _viewport);
    if (page - 1 != _index) setState(() => _index = page - 1);
  }

  void _goToPage(int page) {
    final metrics = _metrics;
    if (metrics == null || !_scroll.hasClients) return;
    _scroll.jumpTo(
      metrics.startOf(page).clamp(0.0, _scroll.position.maxScrollExtent),
    );
  }

  /// Açılan balonu, yazma kartının üstünde kalan alanın ortasına getirir
  /// ("tıklanan balon klavye ile ekranın üstü arasında ortalanmalı").
  void _centerOn(PageBubble bubble) {
    _centerTimer?.cancel();
    _centerTimer = Timer(const Duration(milliseconds: 340), () {
      final metrics = _metrics;
      if (!mounted || metrics == null || !_scroll.hasClients) return;
      final free = (_viewport - _bubbles.dockHeight.value - 24).clamp(
        80.0,
        _viewport <= 0 ? 80.0 : _viewport,
      );
      _scroll.animateTo(
        metrics.centerOffset(
          page: bubble.page,
          y: bubble.y,
          free: free,
          maxScroll: _scroll.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
      // Çizim açılırken balon ekleme kipi kapanır: iki kip aynı parmağı ister.
      if (_editing) _bubbles.setAdding(false);
    });
  }

  /// Toplu balon listesi: "balona git" seçilirse o slayda gidip balonu açar.
  Future<void> _openBubbles() async {
    final target = await showBubblesOverview(context, _bubbles);
    if (target == null || !mounted) return;
    _goToPage(target.page);
    setState(() => _index = target.page - 1);
    _bubbles.openOnly(target.id);
  }

  void _toggleBubbleAdding() {
    setState(() {
      final next = !_bubbles.adding;
      _bubbles.setAdding(next);
      if (next && _editing) {
        _editing = false;
        _ink.setEditing(false);
      }
    });
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
    _centerTimer?.cancel();
    _ink.dispose();
    _bubbles.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        _ink.save();
        // Yazılmadan bırakılan balon slaytta anlamsız bir nokta kalmasın.
        _bubbles.dropEmpty();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.attachment.fileName,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
              tooltip: l10n.bubblesOverviewTitle,
              icon: const Icon(Icons.forum_outlined),
              onPressed: _openBubbles,
            ),
            if (widget.onChanged != null && (_slides?.isNotEmpty ?? false))
              IconButton(
                tooltip: _bubbles.adding ? l10n.bubbleAddDone : l10n.bubbleAdd,
                isSelected: _bubbles.adding,
                icon: Icon(
                  _bubbles.adding
                      ? Icons.chat_bubble
                      : Icons.add_comment_outlined,
                ),
                onPressed: _toggleBubbleAdding,
              ),
            if (widget.onChanged != null && (_slides?.isNotEmpty ?? false))
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _body(l10n)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BubbleDock(
                controller: _bubbles,
                readOnly: widget.onChanged == null,
                bottomPadding: MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : (_bubbles.adding ? BubbleToolbar(controller: _bubbles) : null),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_error != null) {
      return Center(
        child: Text(
          l10n.slideOpenFailed,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final slides = _slides;
    if (slides == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (slides.isEmpty) {
      return Center(
        child: Text(
          l10n.slideOpenFailed,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    // Liste kilitli: çizerken (o parmak çiziyor) ya da slayt yakınken.
    final locked = _editing || _zoomed || _bubbles.dragging != null;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = SlideStripMetrics.forWidth(
                [for (final s in slides) slideAspect(s)],
                constraints.maxWidth,
              );
              _metrics = metrics;
              _viewport = constraints.maxHeight;
              return ListView.builder(
                controller: _scroll,
                physics: locked
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                itemCount: slides.length,
                itemExtentBuilder: (index, _) => metrics.heightOf(index + 1),
                itemBuilder: (context, i) => RepaintBoundary(
                  child: ZoomBox(
                    // Çizimde jestler kapalı ama ölçek KORUNUR: tek parmak
                    // çizer, önceden yapılmış yakınlaştırma kaybolmaz.
                    enabled: !_editing,
                    onZoomChanged: (value) {
                      if (mounted && _zoomed != value) {
                        setState(() => _zoomed = value);
                      }
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(child: SlideCanvas(slide: slides[i])),
                        Positioned.fill(
                          child: InkPageLayer(controller: _ink, page: i + 1),
                        ),
                        Positioned.fill(
                          child: BubblePageLayer(
                            controller: _bubbles,
                            page: i + 1,
                            readOnly: widget.onChanged == null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            '${_index + 1} / ${slides.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
