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
  });

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
  /// Çizimler pano üzerinde de görünür ama BURADA düzenlenmez: küçük bölmede
  /// tek parmakla çizim, sayfayı kaydırmayı imkânsız kılıyordu. Düzenleme tam
  /// ekran görüntüleyicide (kalem düğmesi) yapılır.
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
    viewerBuilder: (context, host) => _PdfPaneViewer(
      attachment: widget.attachment,
      ink: _ink,
      bubbles: _bubbles,
      host: host,
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
  });

  final Attachment attachment;
  final InkController ink;
  final BubbleController bubbles;
  final PageNoteHost host;

  @override
  State<_PdfPaneViewer> createState() => _PdfPaneViewerState();
}

class _PdfPaneViewerState extends State<_PdfPaneViewer> {
  final _pdf = PdfViewerController();
  final _selection = PdfSelectionState();

  @override
  void initState() {
    super.initState();
    // Balon taşımasında pan kilidi YOK (bkz. BubbleController açıklaması);
    // klavye açılınca kart görünür alanın altında kalırsa belge yukarı itilir.
    widget.bubbles.ensureVisible = _ensureBubbleVisible;
  }

  void _ensureBubbleVisible(Rect globalRect) {
    if (!mounted || !_pdf.isReady) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final viewportBottom = box.localToGlobal(Offset.zero).dy + box.size.height;
    final overflow = globalRect.bottom + 8 - viewportBottom;
    if (overflow <= 0) return;
    try {
      _pdf.value = _pdf.value.clone()
        ..leftTranslateByDouble(0, -overflow, 0, 1);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(_PdfPaneViewer old) {
    super.didUpdateWidget(old);
    // Pano başka bir sayfaya geçti: belge oraya kayar. Görüntüleyici hazır
    // değilse (dosya hâlâ iniyor) atlanır — pano zaten kendi sayfasını
    // gösteriyor, kullanıcı notunu beklemeden yazabilir.
    if (old.host.page != widget.host.page && _pdf.isReady) {
      _pdf.goToPage(pageNumber: widget.host.page);
    }
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  Future<void> _openBubbles() async {
    final target = await showBubblesOverview(context, widget.bubbles);
    if (target == null || !mounted) return;
    widget.host.onPageChanged(target.page);
    if (_pdf.isReady) _pdf.goToPage(pageNumber: target.page);
    widget.bubbles.openOnly(target.id);
  }

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

    // Katmanların tamamı (seçim, çizim, balon) tam ekran görüntüleyiciyle
    // AYNI kurulumdan gelir: "tam ekran yapmadan da çalışsın" isteğinin tek
    // kopyalı karşılığı (bkz. pdfLayerParams).
    final viewer = ValueListenableBuilder<bool>(
      valueListenable: _selection.selecting,
      builder: (context, dragging, _) {
        final params = pdfLayerParams(
          selection: _selection,
          bubbles: widget.bubbles,
          editable: true,
          dragging: dragging,
          // Çizimler görünür ama panoda DÜZENLENMEZ (bkz. _PdfNotePaneState).
          inkLayer: (page) => InkPageLayer(controller: widget.ink, page: page),
          onPageChanged: (page) {
            if (page != null) widget.host.onPageChanged(page);
          },
          onViewerReady: (document, controller) {
            widget.host.onPageCount(document.pages.length);
            // Pano başka bir sayfadaysa (toplu görünümden gelindi) belge
            // açılır açılmaz oraya gidilir.
            if (widget.host.page > 1) {
              controller.goToPage(pageNumber: widget.host.page);
            }
          },
        );
        return hasLocal
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
      },
    );

    return Stack(
      children: [
        Positioned.fill(child: viewer),
        Positioned(
          top: 4,
          right: 4,
          child: Column(children: [_bubbleButton(), _overviewButton()]),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: PdfSelectionBar(
            selection: _selection,
            bubbles: widget.bubbles,
            compact: true,
          ),
        ),
      ],
    );
  }

  /// "Balon bırak" düğmesi. Pano bölmesi küçük olduğu için düğme küçük ve
  /// köşede: sayfayı kapatmaz ama planlamaya tam ekrana geçmeden başlanır.
  Widget _bubbleButton() => AnimatedBuilder(
    animation: widget.bubbles,
    builder: (context, _) {
      final adding = widget.bubbles.adding;
      final scheme = Theme.of(context).colorScheme;
      return Material(
        color: adding ? scheme.primary : scheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          tooltip: adding ? context.l10n.bubbleAddDone : context.l10n.bubbleAdd,
          visualDensity: VisualDensity.compact,
          onPressed: () => widget.bubbles.setAdding(!adding),
          icon: Icon(
            adding ? Icons.chat_bubble : Icons.add_comment_outlined,
            size: 18,
            color: adding ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      );
    },
  );

  Widget _overviewButton() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(
          tooltip: context.l10n.bubblesOverviewTitle,
          visualDensity: VisualDensity.compact,
          onPressed: _openBubbles,
          icon: Icon(
            Icons.forum_outlined,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
