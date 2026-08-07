import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../viewers/ink_layer.dart';
import '../viewers/slide_canvas.dart';
import '../viewers/slide_viewer_screen.dart';
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
  });

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
  /// Çizimler panoda GÖRÜNÜR ama burada düzenlenmez (PDF sürümüyle aynı
  /// gerekçe: küçük bölmede tek parmak çizim, slayt geçişini imkânsız kılar).
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(ink: strokes)),
  );

  List<SlideVM>? _slides;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SlideNotePane old) {
    super.didUpdateWidget(old);
    if (!identical(old.attachment.ink, widget.attachment.ink)) {
      _ink.replace(widget.attachment.ink);
    }
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
    _ink.dispose();
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
    viewerBuilder: (context, host) => _SlidePaneViewer(
      slides: _slides,
      error: _error,
      ink: _ink,
      host: host,
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
    required this.host,
  });

  final List<SlideVM>? slides;
  final Object? error;
  final InkController ink;
  final PageNoteHost host;

  @override
  State<_SlidePaneViewer> createState() => _SlidePaneViewerState();
}

class _SlidePaneViewerState extends State<_SlidePaneViewer> {
  PageController? _pages;

  @override
  void didUpdateWidget(_SlidePaneViewer old) {
    super.didUpdateWidget(old);
    if (old.slides == null && widget.slides != null) {
      widget.host.onPageCount(widget.slides!.length);
    }
    // Pano başka bir slayda geçti (düğme ya da toplu görünüm): görüntüleyici
    // oraya kayar. `hasClients` şart — sunum henüz çizilmemiş olabilir.
    final controller = _pages;
    if (old.host.page != widget.host.page &&
        controller != null &&
        controller.hasClients) {
      controller.jumpToPage(widget.host.page - 1);
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

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
    final index = (widget.host.page - 1).clamp(0, slides.length - 1);
    _pages ??= PageController(initialPage: index);
    return ColoredBox(
      color: Colors.black,
      child: PageView.builder(
        controller: _pages,
        itemCount: slides.length,
        onPageChanged: (i) => widget.host.onPageChanged(i + 1),
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            // Slaydın kendi en-boy oranıyla çizilir; çizim katmanı da aynı
            // kutuyu kaplar → oranlar hizalı kalır.
            child: AspectRatio(
              aspectRatio: slides[i].heightPt == 0
                  ? 16 / 9
                  : slides[i].widthPt / slides[i].heightPt,
              child: Stack(
                children: [
                  Positioned.fill(child: SlideCanvas(slide: slides[i])),
                  Positioned.fill(
                    child: InkPageLayer(controller: widget.ink, page: i + 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
