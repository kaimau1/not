import 'package:flutter/material.dart';

import '../../../../core/utils/local_file.dart';
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
  final _pdf = PdfViewerController();

  /// Çizim modu ekran durumu. Görüntüleyici YALNIZ bu değişince yeniden kurulur
  /// (pdfrx `panEnabled`/`enableTextSelection` değişimi belgeyi yeniden yüklüyor);
  /// çizgiler `InkPageLayer` içinde bağımsız tazelendiğinden çizim sırasında
  /// PDF yeniden kurulmaz, iki parmak jesti bozulmaz.
  bool _editing = false;

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _editing = !_editing;
      _ink.setEditing(_editing);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        localFileExists(attachment.localPath);

    final params = PdfViewerParams(
      // Çizim modunda metin seçimi kapalı (seçim katmanı parmağı kapıyor).
      enableTextSelection: !_editing,
      // Çizimde görüntüleyicinin KENDİ jestleri tamamen kapalı: tek parmak
      // çizer, iki parmak yakınlaştırma+kaydırmayı InkNavLayer matrise uygular
      // (görüntüleyicinin tanıyıcısı iki parmağın birlikte hareketini "pan"
      // sayıp panEnabled:false'ta yutuyordu). Normalde tam kaydırma+yakınlaştırma.
      panEnabled: !_editing,
      scaleEnabled: !_editing,
      pageOverlaysBuilder: (context, pageRect, page) => [
        Positioned.fill(
          child: InkPageLayer(controller: _ink, page: page.pageNumber),
        ),
      ],
    );

    Widget viewer;
    if (hasLocal) {
      viewer = PdfViewer.file(
        attachment.localPath,
        controller: _pdf,
        params: params,
      );
    } else if (attachment.isUploaded) {
      viewer = PdfViewer.uri(
        Uri.parse(attachment.downloadUrl),
        controller: _pdf,
        params: params,
      );
    } else {
      viewer = const Center(
        child: Icon(Icons.picture_as_pdf_outlined, size: 64),
      );
    }
    viewer = InkNavLayer(
      enabled: _editing,
      controller: _ink,
      getMatrix: () => _pdf.isReady ? _pdf.value : null,
      // pdfrx value setter'ı matrisi kendisi normalleştirir (konum + min ölçek);
      // üst sınırı InkNavLayer maxScale ile tutar.
      setMatrix: (m) => _pdf.value = m,
      minScale: 0.1,
      maxScale: 8,
      child: viewer,
    );

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
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        body: viewer,
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : null,
      ),
    );
  }
}
