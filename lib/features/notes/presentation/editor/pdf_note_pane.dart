import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_viewer_screen.dart';
import 'text_wrap.dart';

/// "PDF ekle not al" notunun gövdesi: ÜSTTE belgenin sayfası, ALTTA O
/// SAYFANIN notu.
///
/// Alt bölmenin YERİ sabittir, İÇERİĞİ değil (kullanıcı kararı): üstte 3.
/// sayfa varken altta 3. sayfanın notu durur, sayfa çevrilince not da değişir.
/// Sayfa notları [Note.pageNotes] haritasında sayfa KİMLİĞİYLE tutulur (bkz.
/// `domain/page_notes.dart`), yani ileride sayfa silme/sıralama gelince notlar
/// kaymaz.
///
/// Bölme oranı sürüklenerek değiştirilir; ekranda tutulur, kayda YAZILMAZ —
/// notun içeriği değil, o anki okuma tercihidir.
class PdfNotePane extends StatefulWidget {
  const PdfNotePane({
    super.key,
    required this.note,
    required this.attachment,
    required this.onPageNoteChanged,
    required this.onAttachmentChanged,
    this.textStyle,
    this.richTheme,
    this.onFieldFocused,
    this.onFieldDisposed,
  });

  final Note note;

  /// Notun birincil PDF eki (ilk PDF).
  final Attachment attachment;

  /// Sayfa notu değişti: (1 tabanlı sayfa, metin).
  final void Function(int page, String text) onPageNoteChanged;

  /// Tam ekran görüntüleyicide yapılan çizim ekle birlikte geri gelir.
  final ValueChanged<Attachment> onAttachmentChanged;

  final TextStyle? textStyle;
  final RichTextTheme? richTheme;

  /// Biçim çubuğunun hedefi: alan odaklanınca bildirilir (gövde/madde
  /// alanlarıyla aynı sözleşme).
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
  /// Sayfa notu alanı, gövde/madde alanlarıyla AYNI denetleyiciyi kullanır:
  /// satır içi biçimlendirme (kalın, renk, boyut) burada da çalışsın diye.
  /// Sarma çapası yok — bölmede yüzen görsel olmaz.
  final _controller = WrapTextController();
  final _focus = FocusNode();
  final _pdf = PdfViewerController();

  /// Görünen sayfa (1 tabanlı) ve belgenin sayfa sayısı (0 = henüz açılmadı).
  int _page = 1;
  int _pageCount = 0;

  /// Üst bölmenin yükseklik payı (0–1).
  double _split = 0.55;
  static const _minSplit = 0.2;
  static const _maxSplit = 0.85;

  /// Çizimler pano üzerinde de görünür ama BURADA düzenlenmez: küçük bölmede
  /// tek parmakla çizim, sayfayı kaydırmayı imkânsız kılıyordu. Düzenleme tam
  /// ekran görüntüleyicide (kalem düğmesi) yapılır.
  late final InkController _ink = InkController(
    initial: widget.attachment.ink,
    onChanged: (strokes) =>
        widget.onAttachmentChanged(widget.attachment.copyWith(ink: strokes)),
  );

  @override
  void initState() {
    super.initState();
    _controller.text = widget.note.pageNote(widget.attachment, _page);
    _focus.addListener(() {
      if (!_focus.hasFocus) return;
      widget.onFieldFocused?.call(_controller, _focus, _commit);
    });
  }

  @override
  void didUpdateWidget(PdfNotePane old) {
    super.didUpdateWidget(old);
    // Ek değiştiyse (belge silinip yenisi kondu) çizim katmanı tazelenir.
    if (!identical(old.attachment.ink, widget.attachment.ink)) {
      _ink.replace(widget.attachment.ink);
    }
    // UZAKTAN gelen sayfa notu: ikinci cihaz aynı sayfaya yazdıysa alan
    // güncellenir. Alan ODAKTAYKEN dokunulmaz — kullanıcının yazdığı metni
    // altından çekmek imlecin yerini kaybettirir ve IME'yi bozar (gövde
    // alanında da aynı kural: bkz. note_editor_screen "pristine").
    if (_focus.hasFocus) return;
    final incoming = widget.note.pageNote(widget.attachment, _page);
    if (incoming != _controller.logicalText) _controller.text = incoming;
  }

  @override
  void dispose() {
    widget.onFieldDisposed?.call(_controller);
    _ink.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Alandaki metni notun O ANKİ sayfasına yazar.
  void _commit() => widget.onPageNoteChanged(_page, _controller.logicalText);

  /// Görüntüleyici başka bir sayfaya geçti.
  ///
  /// KÖK NEDEN olacak sıra: önce YAZILMAKTA olan sayfanın notu kesinleştirilir,
  /// sonra sayfa numarası değişir. Ters sırada, son tuş vuruşları yeni sayfanın
  /// notu olarak kaydedilirdi — kullanıcı 3. sayfaya yazarken kaydırıp 4.
  /// sayfaya geçince yazdığı satır 4. sayfaya yapışırdı.
  void _onPageChanged(int? page) => _setPage(page ?? 1);

  void _setPage(int next) {
    if (next == _page || next < 1) return;
    _commit();
    setState(() => _page = next);
    _controller.text = widget.note.pageNote(widget.attachment, next);
  }

  /// Sayfa düğmeleri: alt bölme ÖNCE geçer, görüntüleyici ardından kaydırılır.
  ///
  /// Ters sıra (yalnız görüntüleyiciye söyleyip [_onPageChanged]'i beklemek)
  /// belge henüz açılmamışken — dosya buluttan inerken ya da hiç
  /// senkronlanmamışken — düğmeyi ÖLÜ bırakırdı: kullanıcı notunu yazamadan
  /// beklemek zorunda kalırdı. Görüntüleyici hazır olduğunda kendi geri
  /// çağrısı zaten aynı sayfayı doğrular ([_setPage] aynı numarada hiçbir şey
  /// yapmaz), yani iki yol çakışmaz.
  void _goTo(int page) {
    if (page < 1 || (_pageCount > 0 && page > _pageCount)) return;
    _setPage(page);
    if (_pdf.isReady) _pdf.goToPage(pageNumber: page);
  }

  Future<void> _openFullScreen() async {
    // Bölmedeki alanın son hâli önce kaydedilir: tam ekranda çizim yapıp geri
    // dönen kullanıcı yazdığını kaybetmesin.
    _commit();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(
          attachment: widget.attachment,
          onChanged: widget.onAttachmentChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _controller.richTheme = widget.richTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Column(
          children: [
            Expanded(flex: (_split * 1000).round(), child: _viewer(context)),
            _SplitHandle(
              onDrag: (dy) {
                if (height <= 0) return;
                setState(
                  () => _split = (_split + dy / height).clamp(
                    _minSplit,
                    _maxSplit,
                  ),
                );
              },
            ),
            _pageBar(context, l10n),
            Expanded(
              flex: ((1 - _split) * 1000).round(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  style: widget.textStyle,
                  onChanged: (_) => _commit(),
                  // Bölmenin tamamını kaplar: alt bölme SABİT bir yazı alanı,
                  // içeriğe göre büyüyüp küçülen bir satır değil.
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: l10n.pdfPageNoteHint,
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _viewer(BuildContext context) {
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync();
    final params = PdfViewerParams(
      onPageChanged: _onPageChanged,
      onViewerReady: (document, controller) {
        final count = document.pages.length;
        if (count != _pageCount && mounted) setState(() => _pageCount = count);
      },
      // Çizimler görünür ama düzenlenmez (bkz. [_ink]).
      pageOverlaysBuilder: (context, pageRect, page) => [
        Positioned.fill(
          child: InkPageLayer(controller: _ink, page: page.pageNumber),
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
    // senkronlanmamış olabilir. Notlar yine yazılabilsin diye ekran kilitlenmez.
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

  Widget _pageBar(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final label = _pageCount > 0
        ? l10n.pdfPageOf(_page, _pageCount)
        : l10n.pdfPage(_page);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.pdfPreviousPage,
            visualDensity: VisualDensity.compact,
            onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.pdfNextPage,
            visualDensity: VisualDensity.compact,
            onPressed: (_pageCount == 0 || _page < _pageCount)
                ? () => _goTo(_page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: l10n.pdfFullScreen,
            visualDensity: VisualDensity.compact,
            onPressed: _openFullScreen,
            icon: const Icon(Icons.open_in_full),
          ),
        ],
      ),
    );
  }
}

/// Bölmeyi ayıran sürüklenebilir tutamak. Dokunma hedefi çizginin kendisinden
/// kalın (12 dp): 1 px'lik bir çizgiyi parmakla yakalamak imkânsızdı.
class _SplitHandle extends StatelessWidget {
  const _SplitHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        child: SizedBox(
          height: 12,
          child: Center(
            child: Container(
              width: math.min(48, MediaQuery.sizeOf(context).width * 0.2),
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
