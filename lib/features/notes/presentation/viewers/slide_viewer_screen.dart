import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import 'ink_layer.dart';
import 'slide_canvas.dart';

/// Sunum (.pptx) ekini gerçek tasarımıyla slayt slayt gösterir. PDF'teki gibi
/// üzerine elle yazılabilir: çizim slayt oranlı vektör olarak ekin `ink`
/// alanında saklanır (dosyaya gömülmez, senkron ve düzenlenebilir).
///
/// Slaytlar ekrana sığdırılır (yakınlaştırma yok); tablo/grafik/SmartArt gibi
/// çizilemeyen öğeler boş görünür — "dosya okuyucu" motorunun mevcut sınırı.
class SlideViewerScreen extends ConsumerStatefulWidget {
  const SlideViewerScreen({super.key, required this.attachment, this.onChanged});

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
  final _pages = PageController();

  List<SlideVM>? _slides;
  Object? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
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
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _ink,
      builder: (context, _) {
        return PopScope(
          onPopInvokedWithResult: (_, _) => _ink.save(),
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
                    tooltip: _ink.editing ? l10n.annotateDone : l10n.annotate,
                    isSelected: _ink.editing,
                    icon: Icon(_ink.editing ? Icons.check : Icons.edit_outlined),
                    onPressed: _ink.toggleEditing,
                  ),
              ],
            ),
            body: _body(l10n),
            bottomNavigationBar: _ink.editing
                ? InkToolbar(controller: _ink)
                : null,
          ),
        );
      },
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
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            // Çizim + tek parmak varken slayt geçişi kilitli (o parmak çiziyor).
            physics: _ink.lockPan
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                // Slaytın kendi en-boy oranıyla çizilmesi için AspectRatio;
                // çizim katmanı da aynı kutuyu kaplar → oranlar hizalı kalır.
                child: AspectRatio(
                  aspectRatio: slides[i].heightPt == 0
                      ? 16 / 9
                      : slides[i].widthPt / slides[i].heightPt,
                  child: Stack(
                    children: [
                      Positioned.fill(child: SlideCanvas(slide: slides[i])),
                      Positioned.fill(
                        child: InkPageLayer(controller: _ink, page: i + 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
