import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'slide_canvas.dart';

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
  final _pages = PageController();

  /// Geçerli slaydın yakınlaştırma dönüşümü. Yalnız görünen slayda bağlanır;
  /// yakınken (ölçek > 1) slayt geçişi kilitlenir, slayt değişince sıfırlanır.
  final _zoom = TransformationController();
  bool _zoomed = false;

  /// Çizim modu ekran durumu (görüntüleyiciyi çizgi başına yeniden kurmamak
  /// için; çizgiler InkPageLayer içinde bağımsız tazelenir).
  bool _editing = false;

  /// Ekrandaki parmak sayısı (üst düzey Listener sayar). İki parmak inince
  /// PageView kilitlenir → pinch sırasında slayt sağa/sola KAYMAZ (bildirilen
  /// hata buydu). Yalnız çizim kapalıyken güncellenir; çizimde zaten kilitli.
  int _touch = 0;

  List<SlideVM>? _slides;
  Object? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoomChanged);
    _load();
  }

  void _onZoomChanged() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
      // Çizim açılırken balon ekleme kipi kapanır: iki kip aynı parmağı ister.
      if (_editing) _bubbles.setAdding(false);
    });
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
    _ink.dispose();
    _bubbles.dispose();
    _pages.dispose();
    _zoom.dispose();
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
        body: _body(l10n),
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
    // Slayt geçişi kilitli: çizerken (o parmak çiziyor), yakınken ya da iki
    // parmak inince (pinch) — böylece yakınlaştırırken slayt sağa/sola KAYMAZ.
    final lockPage = _editing || _zoomed || _touch >= 2;
    return Listener(
      // Üst düzey, hep aktif parmak sayacı: pinch'i (2 parmak) yakalayıp
      // PageView'ı kilitler. Çizimde güncelleme gereksiz (zaten kilitli) —
      // çizgi başına yeniden kurmayı önlemek için yalnız çizim kapalıyken
      // setState edilir.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _touch++;
        if (!_editing) setState(() {});
      },
      onPointerUp: (_) {
        _touch = _touch > 0 ? _touch - 1 : 0;
        if (!_editing) setState(() {});
      },
      onPointerCancel: (_) {
        _touch = _touch > 0 ? _touch - 1 : 0;
        if (!_editing) setState(() {});
      },
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              physics: lockPage
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: slides.length,
              onPageChanged: (i) => setState(() {
                _index = i;
                _zoom.value = Matrix4.identity(); // yeni slayt tam ekrandan
              }),
              itemBuilder: (context, i) {
                final isCurrent = i == _index;
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    // Slaytın kendi en-boy oranıyla çizilir; çizim katmanı da
                    // aynı kutuyu kaplar → oranlar zoom'da bile hizalı kalır
                    // (katman InteractiveViewer'ın İÇİNDE, birlikte ölçeklenir).
                    child: AspectRatio(
                      aspectRatio: slides[i].heightPt == 0
                          ? 16 / 9
                          : slides[i].widthPt / slides[i].heightPt,
                      // Çizimde IV'nin kendi jestleri tamamen kapalı: tek
                      // parmak çizer, iki parmak yakınlaştırma+kaydırmayı
                      // InkNavLayer _zoom matrisine uygular (IV iki parmağın
                      // birlikte hareketini "pan" sayıp panEnabled:false'ta
                      // yutuyordu). Normalde yakınken kaydır.
                      child: InkNavLayer(
                        enabled: _editing && isCurrent,
                        controller: _ink,
                        getMatrix: () => _zoom.value,
                        setMatrix: (m) => _zoom.value = m,
                        minScale: 1,
                        maxScale: 5,
                        clampToBounds: true,
                        child: InteractiveViewer(
                          transformationController: isCurrent ? _zoom : null,
                          minScale: 1,
                          maxScale: 5,
                          panEnabled: !_editing && isCurrent && _zoomed,
                          scaleEnabled: !_editing,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SlideCanvas(slide: slides[i]),
                              ),
                              Positioned.fill(
                                child: InkPageLayer(
                                  controller: _ink,
                                  page: i + 1,
                                ),
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
      ),
    );
  }
}
