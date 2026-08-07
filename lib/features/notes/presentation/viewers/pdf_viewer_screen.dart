import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/local_file.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/pdf_copy_text.dart';
import '../../data/pdf/edge_auto_scroll.dart';
import '../../domain/attachment.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'pdf_select_layer.dart';

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
///
/// Sayfanın üzerinde ÜÇ katman yaşar; üçü de PDF dosyasına dokunmaz, ekin
/// kendi alanlarında saklanır ve not ile birlikte senkronlanır:
/// * **Metin seçimi** ([PdfSelectLayer]) — daima açık. Uzun basış kelimeyi
///   seçer, sürükleme büyütür, tutamaçlar ince ayar yapar; seçilen metin
///   panoya kopyalanır. Taranmış sayfada cihaz-içi OCR devreye girer.
/// * **Not balonları** ([BubblePageLayer]) — sayfanın istenen noktasına
///   bırakılan, açılıp kapanan metin balonları.
/// * **El yazısı** ([InkPageLayer]) — yalnız [onChanged] verilirse ve kalem
///   düğmesiyle açılınca.
///
/// Üçü aynı anda dokunuş beklemez: çizim ya da balon bırakma açıkken metin
/// seçimi kapanır (aksi hâlde iki katman aynı parmağı paylaşırdı).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.attachment, this.onChanged});

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim ve balon
  /// düzenleme kapalı, metin seçimi yine açık.
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

  late final BubbleController _bubbles = BubbleController(
    initial: widget.attachment.bubbles,
    onChanged: (list) =>
        widget.onChanged?.call(widget.attachment.copyWith(bubbles: list)),
  );

  final _pdf = PdfViewerController();

  /// Çizim modu ekran durumu. Görüntüleyici YALNIZ bu değişince yeniden kurulur
  /// (pdfrx `panEnabled` değişimi belgeyi yeniden yüklemez ama katman ağacı
  /// değişir); çizgiler `InkPageLayer` içinde bağımsız tazelendiğinden çizim
  /// sırasında PDF yeniden kurulmaz, iki parmak jesti bozulmaz.
  bool _editing = false;

  // ── Metin seçimi durumu ───────────────────────────────────────────────────
  String _selection = '';
  int _selectionPage = 0;

  /// Sürükleyerek seçim ŞU AN sürüyor mu? True iken pdfrx'in pan'ı kilitlenir
  /// ki sürükleme sayfayı kaydırmasın; işaretçi kalkar kalkmaz katman false
  /// bildirir ve kilit açılır (kalıcı bir "seçim modu" YOK).
  bool _selecting = false;

  /// Kenar oto-kaydırması: seçim sürüklenirken işaretçinin son EKRAN konumu
  /// (katman bildirir; null = sürükleme yok) ve 60 Hz itme zamanlayıcısı.
  Offset? _dragPos;
  Timer? _edgeTimer;

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _ink.dispose();
    _bubbles.dispose();
    super.dispose();
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

  Future<void> _copySelection() async {
    // Ham seçim değil TEMİZ metin kopyalanır: pdfium'un satır sonları ve
    // görünmez karakterleri panoya taşınmasın, satırlara bölünmüş "Fizik /
    // Muayene" tek satır "Fizik Muayene" olsun.
    final text = cleanPdfCopyText(_selection);
    if (text.isEmpty) return;
    final message = context.l10n.pdfSelectCopied(text.length);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Seçim sürüklemesinin ekran konumu değişti (null = bitti). Kenara
  /// yaklaşınca 60 Hz'lik zamanlayıcı görüntüyü o yöne iter; sürükleme bitince
  /// zamanlayıcı ölür. Zamanlayıcı işaretçi olaylarından AYRI koşar ki parmak
  /// kenarda hiç kımıldamadan dursa da akış sürsün.
  void _onSelectDragAt(Offset? global) {
    _dragPos = global;
    if (global == null) {
      _edgeTimer?.cancel();
      _edgeTimer = null;
      return;
    }
    _edgeTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final pos = _dragPos;
      if (pos == null || !mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final delta = edgeAutoScrollDelta(box.globalToLocal(pos), box.size);
      if (delta == Offset.zero) return;
      try {
        // Görüntü matrisi işaretçinin TERS yönüne itilir (alt kenar → içerik
        // yukarı). Ayarlayıcı güvenli aralığa kıstırır.
        _pdf.value = _pdf.value.clone()
          ..leftTranslateByDouble(-delta.dx, -delta.dy, 0, 1);
      } catch (_) {
        // Görüntüleyici henüz hazır değilse (yarış) itme sessizce atlanır.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = widget.attachment;
    final editable = widget.onChanged != null;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        localFileExists(attachment.localPath);

    final params = PdfViewerParams(
      // Sürükleyerek seçim sürerken pan kapalı: parmak/fare seçimi büyütür,
      // sayfa kaymaz. InteractiveViewer bu bayrağı HER olayda okuduğu için
      // jest ortasında kapatmak da işler; belge yeniden YÜKLENMEZ.
      //
      // Çizimde görüntüleyicinin KENDİ jestleri tamamen kapalı: tek parmak
      // çizer, iki parmak yakınlaştırma+kaydırmayı InkNavLayer matrise uygular
      // (görüntüleyicinin tanıyıcısı iki parmağın birlikte hareketini "pan"
      // sayıp panEnabled:false'ta yutuyordu).
      panEnabled: !_editing && !_selecting,
      scaleEnabled: !_editing,
      pageOverlaysBuilder: (context, pageRect, page) => [
        // Metin seçimi EN ALTTA: çizim/balon açıkken hiç kurulmaz, kapalıyken
        // parmağı yutmadan dinler (bkz. PdfSelectLayer sınıf açıklaması).
        if (!_editing && !_bubbles.adding)
          PdfSelectLayer(
            page: page,
            pageSize: pageRect.size,
            activeSelectionPage: _selection.isEmpty ? 0 : _selectionPage,
            onSelected: (text, rects, pageNo, fromOcr) {
              if (!mounted) return;
              setState(() {
                _selection = text;
                _selectionPage = text.isEmpty ? 0 : pageNo;
              });
            },
            onSelectingChanged: (value) {
              if (mounted && _selecting != value) {
                setState(() => _selecting = value);
              }
            },
            onDragAt: _onSelectDragAt,
          ),
        Positioned.fill(
          child: InkPageLayer(controller: _ink, page: page.pageNumber),
        ),
        Positioned.fill(
          child: BubblePageLayer(
            controller: _bubbles,
            page: page.pageNumber,
            readOnly: !editable,
          ),
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
      onPopInvokedWithResult: (_, _) {
        _ink.save();
        // Yazılmadan bırakılan balon sayfada anlamsız bir nokta olarak kalmasın.
        _bubbles.dropEmpty();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            if (editable)
              IconButton(
                tooltip: _bubbles.adding
                    ? l10n.bubbleAddDone
                    : l10n.bubbleAdd,
                isSelected: _bubbles.adding,
                icon: Icon(
                  _bubbles.adding
                      ? Icons.chat_bubble
                      : Icons.add_comment_outlined,
                ),
                onPressed: _toggleBubbleAdding,
              ),
            if (editable)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: _toggleEditing,
              ),
          ],
        ),
        // Ctrl/Cmd+C: seçili metni panoya kopyalar (masaüstü alışkanlığı —
        // Chrome'un PDF görüntüleyicisiyle aynı).
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyC, control: true):
                _copySelection,
            const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                _copySelection,
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(child: viewer),
                if (_selection.trim().isNotEmpty)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 16,
                    child: Center(child: _selectionBar()),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : (_bubbles.adding ? BubbleToolbar(controller: _bubbles) : null),
      ),
    );
  }

  /// Seçim çubuğu: yalnız seçim varken görünür. Seçilen metnin başı okunur
  /// (hangi metnin kopyalanacağı belli olsun) ve tek dokunuşla panoya gider.
  Widget _selectionBar() {
    final text = _selection.replaceAll('\n', ' ').trim();
    final preview = text.length <= 28 ? text : '${text.substring(0, 28)}…';
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '“$preview”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: _copySelection,
              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
              label: Text(
                context.l10n.copy,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
