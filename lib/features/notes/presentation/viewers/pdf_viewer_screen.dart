import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'ink_layer.dart';

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
///
/// [onChanged] verilirse sayfaların üzerine elle yazma/çizme açılır: çizimler
/// PDF dosyasına gömülmez, ekin `ink` alanında sayfa oranlı vektör olarak
/// saklanır (not ile birlikte Firestore'a gider) — bu yüzden her açılışta
/// yeniden düzenlenebilir, silinebilir.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.attachment, this.onChanged});

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onChanged?.call(widget.attachment.copyWith(ink: strokes)),
  );

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync();

    return ListenableBuilder(
      listenable: _ink,
      builder: (context, _) {
        final params = PdfViewerParams(
          // Metin seçimi açık: kullanıcı PDF içindeki yazıyı seçip
          // kopyalayabilsin. Çizim modunda kapalı: seçim katmanı parmağı kapıyor.
          enableTextSelection: !_ink.editing,
          // Tek parmak çizerken kaydırma kapalı; ikinci parmak inince açılır.
          panEnabled: !_ink.lockPan,
          pageOverlaysBuilder: (context, pageRect, page) => [
            Positioned.fill(
              child: InkPageLayer(controller: _ink, page: page.pageNumber),
            ),
          ],
        );

        Widget viewer;
        if (hasLocal) {
          viewer = PdfViewer.file(attachment.localPath, params: params);
        } else if (attachment.isUploaded) {
          viewer = PdfViewer.uri(
            Uri.parse(attachment.downloadUrl),
            params: params,
          );
        } else {
          viewer = const Center(
            child: Icon(Icons.picture_as_pdf_outlined, size: 64),
          );
        }

        return PopScope(
          onPopInvokedWithResult: (_, _) => _ink.save(),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                attachment.fileName,
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                if (widget.onChanged != null)
                  IconButton(
                    tooltip: _ink.editing ? l10n.annotateDone : l10n.annotate,
                    isSelected: _ink.editing,
                    icon: Icon(_ink.editing ? Icons.check : Icons.edit_outlined),
                    onPressed: _ink.toggleEditing,
                  ),
              ],
            ),
            body: viewer,
            bottomNavigationBar: _ink.editing
                ? InkToolbar(controller: _ink)
                : null,
          ),
        );
      },
    );
  }
}
