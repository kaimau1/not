import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/local_file.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/pdf_copy_text.dart';
import '../../data/pdf/edge_auto_scroll.dart';
import '../../domain/attachment.dart';
import '../editor/bubbles_overview.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'pdf_select_layer.dart';
import 'pdf_selection_bar.dart';

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
///
/// Sayfanın üzerinde ÜÇ katman yaşar; üçü de PDF dosyasına dokunmaz, ekin
/// kendi alanlarında saklanır ve not ile birlikte senkronlanır:
/// * **Metin seçimi** ([PdfSelectLayer]) — daima açık. Uzun basış kelimeyi
///   seçer, sürükleme büyütür; seçim çubuğundan metin vurgulanır, nota
///   çevrilir ya da panoya kopyalanır. Taranmış sayfada cihaz-içi OCR devreye
///   girer.
/// * **Not balonları ve vurgular** ([BubblePageLayer]) — belgenin üzerinde
///   çalışmanın ANA aracı.
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
  final _selection = PdfSelectionState();

  /// Çizim modu ekran durumu.
  bool _editing = false;

  /// Kenar oto-kaydırması: seçim sürüklenirken işaretçinin son EKRAN konumu
  /// (katman bildirir; null = sürükleme yok) ve 60 Hz itme zamanlayıcısı.
  Offset? _dragPos;
  Timer? _edgeTimer;

  @override
  void initState() {
    super.initState();
    // Balon taşımasında pan KİLİTLENMEZ: kilit `PdfViewerParams`ı değiştirip
    // jestin ortasında görüntüleyiciyi yeniden kuruyor ve başlamış uzun
    // basışı iptal ediyordu ("hâlâ çok zor sürükleniyor"). Uzun basış jest
    // arenasını zaten kazanıyor, sayfa altta kaymıyor.
    _bubbles.ensureVisible = _ensureBubbleVisible;
  }

  /// Klavye açılınca balon kartı ekranın altında kalıyorsa belgeyi yukarı
  /// iter. Kart görünür alanın içine girecek kadar — fazlası okunan yeri
  /// gereksiz kaydırır.
  void _ensureBubbleVisible(Rect globalRect) {
    if (!mounted || !_pdf.isReady) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final viewportBottom = box.localToGlobal(Offset.zero).dy + box.size.height;
    final overflow = globalRect.bottom + 12 - viewportBottom;
    if (overflow <= 0) return;
    try {
      _pdf.value = _pdf.value.clone()
        ..leftTranslateByDouble(0, -overflow, 0, 1);
    } catch (_) {
      // Görüntüleyici hazır değilse sessizce atlanır.
    }
  }

  @override
  void dispose() {
    _edgeTimer?.cancel();
    _ink.dispose();
    _bubbles.dispose();
    _selection.dispose();
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

  Future<void> _copySelection() async {
    final text = cleanPdfCopyText(_selection.text.value);
    if (text.isEmpty) return;
    final message = context.l10n.pdfSelectCopied(text.length);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Toplu balon listesini açar; "balona git" seçilirse o sayfaya gidip balonu
  /// tek başına açar.
  Future<void> _openBubbles() async {
    final target = await showBubblesOverview(context, _bubbles);
    if (target == null || !mounted) return;
    if (_pdf.isReady) _pdf.goToPage(pageNumber: target.page);
    _bubbles.openOnly(target.id);
  }

  /// Seçim sürüklemesinin ekran konumu değişti (null = bitti). Kenara
  /// yaklaşınca 60 Hz'lik zamanlayıcı görüntüyü o yöne iter.
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

    // Yalnız pan kilidi değişince yeniden kurulur (hareket başına iki kez).
    Widget viewer = ValueListenableBuilder<bool>(
      valueListenable: _selection.selecting,
      builder: (context, dragging, _) {
        final params = pdfLayerParams(
          selection: _selection,
          bubbles: _bubbles,
          inkLayer: (page) => InkPageLayer(controller: _ink, page: page),
          inkEditing: _editing,
          dragging: dragging,
          editable: editable,
          onSelectDragAt: _onSelectDragAt,
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
        return const Center(
          child: Icon(Icons.picture_as_pdf_outlined, size: 64),
        );
      },
    );
    viewer = InkNavLayer(
      enabled: _editing,
      controller: _ink,
      getMatrix: () => _pdf.isReady ? _pdf.value : null,
      setMatrix: (m) => _pdf.value = m,
      minScale: 0.1,
      maxScale: 8,
      child: viewer,
    );

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        _ink.save();
        // Yazılmadan bırakılan serbest balon anlamsız bir nokta olarak kalmasın
        // (vurgular korunur — kendi başlarına anlamlılar).
        _bubbles.dropEmpty();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
              tooltip: l10n.bubblesOverviewTitle,
              icon: const Icon(Icons.forum_outlined),
              onPressed: _openBubbles,
            ),
            if (editable)
              AnimatedBuilder(
                animation: _bubbles,
                builder: (context, _) => IconButton(
                  tooltip: _bubbles.adding ? l10n.bubbleAddDone : l10n.bubbleAdd,
                  isSelected: _bubbles.adding,
                  icon: Icon(
                    _bubbles.adding
                        ? Icons.chat_bubble
                        : Icons.add_comment_outlined,
                  ),
                  onPressed: () {
                    if (!_bubbles.adding && _editing) _toggleEditing();
                    _bubbles.setAdding(!_bubbles.adding);
                  },
                ),
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
        // Ctrl/Cmd+C: seçili metni panoya kopyalar (masaüstü alışkanlığı).
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
                // Alt gezinme çubuğunun (telefon tuşları) ALTINDA kalmasın:
                // Scaffold gövdesi bottomNavigationBar yokken sistem payını
                // eklemiyor, çubuk tuşların üstüne biniyordu.
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
                  child: PdfSelectionBar(
                    selection: _selection,
                    bubbles: _bubbles,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _editing
            ? InkToolbar(controller: _ink, hint: context.l10n.inkTwoFingerHint)
            : AnimatedBuilder(
                animation: _bubbles,
                builder: (context, _) => _bubbles.adding
                    ? BubbleToolbar(controller: _bubbles)
                    : const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Seçim + balon + (varsa) çizim katmanlarını taşıyan `PdfViewerParams`.
///
/// Tam ekran görüntüleyici ile not panosunun bölmesi AYNI katman düzenini
/// paylaşsın diye burada, tek kopya (kullanıcı isteği: "PDF üzerinde metin
/// seçme, üzerine yazı yazma tam ekran yapmadan da çalışmalı").
///
/// **Performans:** parametre nesnesi seçim değiştikçe YENİDEN KURULMAZ —
/// katmanların içi `ValueListenableBuilder`/`AnimatedBuilder` ile kendi
/// başına tazelenir. Eskiden her seçim olayı ekranın `setState`ini çağırıyor,
/// o da tüm sayfa katmanlarını yeniden kuruyordu (kasmanın kök nedeni).
PdfViewerParams pdfLayerParams({
  required PdfSelectionState selection,
  required BubbleController bubbles,
  required bool editable,
  Widget Function(int page)? inkLayer,
  bool inkEditing = false,
  bool dragging = false,
  ValueChanged<Offset?>? onSelectDragAt,
  void Function(PdfDocument document, PdfViewerController controller)?
  onViewerReady,
  ValueChanged<int?>? onPageChanged,
}) => PdfViewerParams(
  // Sürükleyerek seçim ya da balon taşıma sürerken pan kapalı: parmak seçimi
  // büyütür / balonu taşır, sayfa kaymaz. Bu bayrak jest BAŞINDA ve SONUNDA
  // (saniyede iki kez değil, hareket başına iki kez) değişir; params o anda
  // yeniden kurulur ama belge YÜKLENMEZ — pdfrx yalnız documentRef
  // değişiminde yükler.
  panEnabled: !inkEditing && !dragging,
  scaleEnabled: !inkEditing,
  onViewerReady: onViewerReady,
  onPageChanged: onPageChanged,
  pageOverlaysBuilder: (context, pageRect, page) => [
    // Katmanların TAMAMI tek bir dinleyicinin altında: seçim/balon durumu
    // değişince yalnız burası tazelenir, görüntüleyici kurulmaz.
    //
    // `selection.page` de dinlenir ki seçim başka bir sayfaya geçince bu
    // sayfanın katmanı kendi vurgusunu bıraksın (tek etkin seçim).
    Positioned.fill(
      child: ValueListenableBuilder<int>(
        valueListenable: selection.page,
        builder: (context, activePage, _) => AnimatedBuilder(
        animation: bubbles,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            if (!inkEditing && !bubbles.adding)
              PdfSelectLayer(
                page: page,
                pageSize: pageRect.size,
                activeSelectionPage: activePage,
                onSelected: (text, rects, pageNo, fromOcr) => selection.set(
                  value: text,
                  pageNumber: pageNo,
                  pdfRects: rects,
                  source: page,
                ),
                onSelectingChanged: (value) =>
                    selection.selecting.value = value,
                onDragAt: onSelectDragAt,
              ),
            if (inkLayer != null)
              Positioned.fill(child: inkLayer(page.pageNumber)),
            Positioned.fill(
              child: BubblePageLayer(
                controller: bubbles,
                page: page.pageNumber,
                readOnly: !editable,
              ),
            ),
          ],
        ),
        ),
      ),
    ),
  ],
);
