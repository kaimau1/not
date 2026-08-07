import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import 'pdf_notes_overview.dart';
import 'text_wrap.dart';

/// Üst bölmeyi kuran kapanış.
///
/// Sayfa durumu PANODA tutulur, görüntüleyicide değil: alt bölmenin hangi
/// sayfanın notunu göstereceği tek bir yerden belirlenir ve PDF ile slayt
/// sürümleri aynı davranışı paylaşır.
typedef PageViewerBuilder =
    Widget Function(BuildContext context, PageNoteHost host);

/// Görüntüleyicinin panoyla konuştuğu arayüz.
@immutable
class PageNoteHost {
  const PageNoteHost({
    required this.page,
    required this.onPageChanged,
    required this.onPageCount,
  });

  /// GÖSTERİLMESİ İSTENEN sayfa (1 tabanlı). Görüntüleyici bu değer değişince
  /// oraya kaymalıdır (sayfa düğmeleri ve toplu görünüm buradan çalışır).
  final int page;

  /// Görüntüleyici KENDİ hareketiyle sayfa değiştirdi (kaydırma, kaydırıcı).
  final ValueChanged<int> onPageChanged;

  /// Belge açıldı: toplam sayfa/slayt sayısı.
  final ValueChanged<int> onPageCount;
}

/// "Belge ekle not al" notlarının ortak gövdesi: ÜSTTE belgenin sayfası,
/// ALTTA O SAYFANIN notu.
///
/// Alt bölmenin YERİ sabittir, İÇERİĞİ değil (kullanıcı kararı, 2026-08-07):
/// üstte 3. sayfa varken altta 3. sayfanın notu durur, sayfa çevrilince not da
/// değişir. Sayfa notları [Note.pageNotes] haritasında sayfa KİMLİĞİYLE
/// tutulur (bkz. `domain/page_notes.dart`), yani sayfa silme/sıralama gelince
/// notlar kaymaz.
///
/// PDF ve SLAYT sürümleri yalnız üst bölmede ayrışır; not tarafının tamamı
/// (sayfa çubuğu, bölme tutamağı, alan, toplu görünüm, bekleyen biçim) burada
/// tek kopyadır.
class PageNotePane extends StatefulWidget {
  const PageNotePane({
    super.key,
    required this.noteOf,
    required this.attachment,
    required this.onPageNoteChanged,
    required this.viewerBuilder,
    this.onFullScreen,
    this.textStyle,
    this.richTheme,
    this.onFieldFocused,
    this.onFieldDisposed,
  });

  /// Notun O ANKİ hâlini veren okuyucu.
  ///
  /// Neden anlık görüntü (`Note`) DEĞİL: sayfa notuna yazmak editörde "saf
  /// yazım" sayılır ve ekran geneli `setState` bilerek ATLANIR (bkz.
  /// note_editor_screen `_sameVisual` — kasma kök nedeni). Yani pano bir
  /// `Note` alanı taşısaydı, kullanıcı yazdıktan sonra o alan BAYAT kalır ve
  /// toplu görünümden dönüşte alan eski metinle doldurulurdu.
  final Note Function() noteOf;

  /// Notun birincil belgesi (PDF ya da sunum eki).
  final Attachment attachment;

  /// Sayfa notu değişti: (1 tabanlı sayfa, metin).
  final void Function(int page, String text) onPageNoteChanged;

  final PageViewerBuilder viewerBuilder;

  /// Tam ekran görüntüleyiciyi açar (çizim orada yapılır). null = düğme yok.
  final Future<void> Function()? onFullScreen;

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
  State<PageNotePane> createState() => _PageNotePaneState();
}

class _PageNotePaneState extends State<PageNotePane> {
  /// Sayfa notu alanı, gövde/madde alanlarıyla AYNI denetleyiciyi kullanır:
  /// satır içi biçimlendirme (kalın, renk, boyut) burada da çalışsın diye.
  /// Sarma çapası yok — bölmede yüzen görsel olmaz.
  final _controller = WrapTextController();
  final _focus = FocusNode();

  /// Görünen sayfa (1 tabanlı) ve belgenin sayfa sayısı (0 = henüz açılmadı).
  int _page = 1;
  int _pageCount = 0;

  /// Üst bölmenin yükseklik payı (0–1). Ekranda tutulur, kayda YAZILMAZ —
  /// notun içeriği değil, o anki okuma tercihidir.
  double _split = 0.55;
  static const _minSplit = 0.2;
  static const _maxSplit = 0.85;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.noteOf().pageNote(widget.attachment, _page);
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Bekleyen biçim koşusu odak kaybında metne yazılır (gövde/başlık ve
        // liste satırlarıyla aynı kural — bkz. WrapTextController._wrapRun).
        if (_controller.hasPendingFormat) {
          _controller.flushPendingFormat();
          _commit();
        }
        return;
      }
      widget.onFieldFocused?.call(_controller, _focus, _commit);
    });
  }

  @override
  void didUpdateWidget(PageNotePane old) {
    super.didUpdateWidget(old);
    // UZAKTAN gelen sayfa notu: ikinci cihaz aynı sayfaya yazdıysa alan
    // güncellenir. Alan ODAKTAYKEN dokunulmaz — kullanıcının yazdığı metni
    // altından çekmek imlecin yerini kaybettirir ve IME'yi bozar (gövde
    // alanında da aynı kural: bkz. note_editor_screen "pristine").
    if (_focus.hasFocus) return;
    final incoming = widget.noteOf().pageNote(widget.attachment, _page);
    if (incoming != _controller.logicalText) _controller.text = incoming;
  }

  @override
  void dispose() {
    widget.onFieldDisposed?.call(_controller);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Alandaki metni notun O ANKİ sayfasına yazar.
  void _commit() => widget.onPageNoteChanged(_page, _controller.logicalText);

  /// Sayfa değişti.
  ///
  /// KÖK NEDEN olacak sıra: önce YAZILMAKTA olan sayfanın notu kesinleştirilir,
  /// sonra sayfa numarası değişir. Ters sırada, kullanıcı 3. sayfaya yazarken
  /// kaydırıp 4. sayfaya geçince son tuş vuruşları 4. sayfaya yapışırdı.
  void _setPage(int next) {
    if (next == _page || next < 1) return;
    // Bekleyen biçim koşusu sayfa değişimiyle biter: işaretler ESKİ sayfanın
    // notuna yazılmalı, yenisine değil.
    if (_controller.hasPendingFormat) _controller.flushPendingFormat();
    _commit();
    setState(() => _page = next);
    _controller.text = widget.noteOf().pageNote(widget.attachment, next);
  }

  void _goTo(int page) {
    if (page < 1 || (_pageCount > 0 && page > _pageCount)) return;
    _setPage(page);
  }

  void _onPageCount(int count) {
    if (count == _pageCount || !mounted) return;
    setState(() {
      _pageCount = count;
      // Belge küçüldüyse (başka cihazda sayfa silinmiş) görünen sayfa dışarıda
      // kalmasın.
      if (_pageCount > 0 && _page > _pageCount) _page = _pageCount;
    });
  }

  /// Toplu görünüm: bütün sayfa notları tek akışta. Başlığa dokunulup bir
  /// sayfa dönerse pano oraya gider.
  Future<void> _openOverview() async {
    // Alandaki son hâl önce kesinleşir: toplu görünüm notu EKRAN AÇILIRKEN
    // dondurup kendi denetleyicilerine kopyalıyor, bekleyen tuş vuruşları
    // orada eksik görünmesin.
    if (_controller.hasPendingFormat) _controller.flushPendingFormat();
    _commit();
    final page = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => PdfNotesOverviewScreen(
          note: widget.noteOf(),
          attachment: widget.attachment,
          onPageNoteChanged: widget.onPageNoteChanged,
          textStyle: widget.textStyle,
          richTheme: widget.richTheme,
        ),
      ),
    );
    if (!mounted) return;
    // Toplu görünümde düzenlenen notlar panoya da yansımalı: dönülen sayfa
    // aynı sayfa olsa bile alan tazelenir.
    if (page != null && page != _page) {
      _goTo(page);
    } else {
      _controller.text = widget.noteOf().pageNote(widget.attachment, _page);
    }
  }

  Future<void> _openFullScreen() async {
    final open = widget.onFullScreen;
    if (open == null) return;
    // Bölmedeki alanın son hâli önce kaydedilir: tam ekranda çizim yapıp geri
    // dönen kullanıcı yazdığını kaybetmesin.
    if (_controller.hasPendingFormat) _controller.flushPendingFormat();
    _commit();
    await open();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _controller.richTheme = widget.richTheme;
    final host = PageNoteHost(
      page: _page,
      onPageChanged: _setPage,
      onPageCount: _onPageCount,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Column(
          children: [
            Expanded(
              flex: (_split * 1000).round(),
              child: widget.viewerBuilder(context, host),
            ),
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
            tooltip: l10n.pdfAllPageNotes,
            visualDensity: VisualDensity.compact,
            onPressed: _openOverview,
            icon: const Icon(Icons.subject),
          ),
          if (widget.onFullScreen != null)
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
