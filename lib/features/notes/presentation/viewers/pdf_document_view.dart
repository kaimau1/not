import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../domain/attachment.dart';
import 'ink_layer.dart';

/// **TEK BELGE GÖRÜNTÜLEYİCİ ÇEKİRDEĞİ** (F3.4): tam ekran görüntüleyici
/// ([PdfViewerScreen]) ve not ekranındaki PDF bölmesi (`PdfNotePane`) aynı
/// bileşeni farklı kaplarda kullanır. Katmanlar (seçim, kalem, balon)
/// `pdfLayerParams`tan gelir; kaynak seçimi (cihazdaki dosya / bulut adresi)
/// ve kalem açıkken iki parmakla gezinme burada tek kopyadır.
///
/// Defter sayfasındaki tek PDF sayfası (`PdfPageBox`) ve kart kapakları aynı
/// çizimi sayfa görüntüsüyle (`PdfPageImage`) yapar.
class PdfDocumentView extends StatelessWidget {
  const PdfDocumentView({
    super.key,
    required this.attachment,
    required this.hasLocal,
    required this.controller,
    required this.params,
    required this.ink,
    required this.penMode,
  });

  final Attachment attachment;

  /// Dosya cihazda mı (yoksa bulut adresinden açılır).
  final bool hasLocal;
  final PdfViewerController controller;
  final PdfViewerParams params;
  final InkController ink;

  /// Kalem açık: tek parmak çizer, İKİ PARMAK gezinir.
  final bool penMode;

  @override
  Widget build(BuildContext context) {
    final Widget viewer;
    if (hasLocal) {
      viewer = PdfViewer.file(
        attachment.localPath,
        controller: controller,
        params: params,
      );
    } else if (attachment.isUploaded) {
      viewer = PdfViewer.uri(
        Uri.parse(attachment.downloadUrl),
        controller: controller,
        params: params,
      );
    } else {
      return const Center(child: Icon(Icons.picture_as_pdf_outlined, size: 64));
    }
    return InkNavLayer(
      enabled: penMode,
      controller: ink,
      getMatrix: () => controller.isReady ? controller.value : null,
      setMatrix: (m) => controller.value = m,
      minScale: 0.1,
      maxScale: 8,
      child: viewer,
    );
  }
}
