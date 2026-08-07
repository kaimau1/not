import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_viewer_screen.dart';
import 'page_note_pane.dart';
import 'text_wrap.dart';

/// "PDF ekle not al" notunun gövdesi: ÜSTTE PDF sayfası, ALTTA o sayfanın
/// notu.
///
/// Not tarafının tamamı [PageNotePane]'dedir (slayt sürümüyle ortak); burada
/// yalnız pdfrx görüntüleyicisi ve çizim katmanı yaşar.
class PdfNotePane extends StatefulWidget {
  const PdfNotePane({
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

  /// Tam ekran görüntüleyicide yapılan çizim ekle birlikte geri gelir.
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

  @override
  void didUpdateWidget(PdfNotePane old) {
    super.didUpdateWidget(old);
    // Tam ekranda çizim yapılıp dönüldüyse pano da tazelenir.
    if (!identical(old.attachment.ink, widget.attachment.ink)) {
      _ink.replace(widget.attachment.ink);
    }
  }

  @override
  void dispose() {
    _ink.dispose();
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
    noteOf: widget.noteOf,
    attachment: widget.attachment,
    onPageNoteChanged: widget.onPageNoteChanged,
    textStyle: widget.textStyle,
    richTheme: widget.richTheme,
    onFieldFocused: widget.onFieldFocused,
    onFieldDisposed: widget.onFieldDisposed,
    onFullScreen: _openFullScreen,
    viewerBuilder: (context, host) => _PdfPaneViewer(
      attachment: widget.attachment,
      ink: _ink,
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
    required this.host,
  });

  final Attachment attachment;
  final InkController ink;
  final PageNoteHost host;

  @override
  State<_PdfPaneViewer> createState() => _PdfPaneViewerState();
}

class _PdfPaneViewerState extends State<_PdfPaneViewer> {
  final _pdf = PdfViewerController();

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
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync();
    final params = PdfViewerParams(
      onPageChanged: (page) {
        if (page != null) widget.host.onPageChanged(page);
      },
      onViewerReady: (document, controller) {
        widget.host.onPageCount(document.pages.length);
        // Pano başka bir sayfadaysa (toplu görünümden gelindi) belge açılır
        // açılmaz oraya gidilir.
        if (widget.host.page > 1) {
          controller.goToPage(pageNumber: widget.host.page);
        }
      },
      // Çizimler görünür ama düzenlenmez (bkz. [_PdfNotePaneState._ink]).
      pageOverlaysBuilder: (context, pageRect, page) => [
        Positioned.fill(
          child: InkPageLayer(controller: widget.ink, page: page.pageNumber),
        ),
      ],
    );
    if (hasLocal) {
      return PdfViewer.file(
        attachment.localPath,
        controller: _pdf,
        params: params,
      );
    }
    if (attachment.isUploaded) {
      return PdfViewer.uri(
        Uri.parse(attachment.downloadUrl),
        controller: _pdf,
        params: params,
      );
    }
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
}
