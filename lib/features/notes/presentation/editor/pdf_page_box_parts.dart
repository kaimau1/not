part of 'pdf_page_box.dart';

/// **SAYFAYA GÖMÜLÜ PDF** (kullanıcı isteği 2026-09-06: "PDF'yi sayfaya
/// entegre etme, aynı görsel gibi sayfaya yerleşir ancak sayfa
/// değiştirilebilir ve ek özellikler istiyorum").
///
/// PDF artık ek şeridinde bekleyen bir dosya değil, notun sayfasında duran
/// bir kutu: görselle birebir aynı şekilde taşınır, boyutlandırılır ve metin
/// etrafından akar ([Attachment.floatsOnPage]). Görselden tek farkı, kutunun
/// TEK bir kare değil bir BELGE göstermesi — bu yüzden kutunun kendi
/// gezinme çubuğu var.
///
/// Kutunun yaptıkları (hepsi tam ekrana geçmeden):
///  1. **Sayfa çevirme** — ‹ › düğmeleri ve kutunun üzerinde yatay kaydırma
///     (sayfalar parmağı izleyerek kayar; bkz. [_PdfPageBoxState._pager]).
///  2. **Sayfa göstergesi** — "3 / 24"; dokununca sayfaya atlama levhası.
///  3. **Küçük resimle atlama** — levhada bütün sayfaların ızgarası.
///  4. **Kaldığın sayfa kalıcı** — sayfa numarası nota yazılır, senkronlanır.
///  5. **Yer imleri** — sayfaya yer imi koy, listeden atla (uzun belgede
///     "kaldığım yerler").
///  6. **Görünümü döndürme** — yatay taranmış belgeler için; dosyaya
///     dokunmaz, yalnız kutuyu döndürür.
///  7. **Tam ekran** — aynı sayfadan açılır, dönüşte sayfa korunur.
///  8. **Sayfa metnini kopyalama** — o sayfanın metin katmanı panoya.
///  9. **Sayfayı yakalama** — sayfa görüntüsü yapay zekâya sorulur ya da
///     panoya alınır (alan seçimindeki levhanın aynısı).
/// 10. **Otomatik geçiş** — belgeyi slayt gibi ilerletir (sunum/okuma).
/// 11. **Sayfa notu göstergesi** — o sayfadaki balon/vurgu sayısı rozet
///     olarak, el yazısı katmanı da kutunun üstünde çizilir.
/// 12. **Sayfa oranına oturma** — kutunun en-boyu belgenin ilk sayfasından
///     alınır ve ekte saklanır (kare varsayımıyla ezilmiş PDF yok).
/// 13. **İlk/son sayfaya atlama**.
/// 14. **Şeride geri alma** — kutu menüsünden, görseldeki gibi.
/// **DIŞ ÇUBUK KÖPRÜSÜ** (kullanıcı isteği 2026-11-07: sabit bölmede
/// belgenin üstündeki gri sayfa şeridi "kaldır, özellikleri bir alt
/// satırla birleştir"). Verilirse [PdfPageBox] kendi yüzen şeridini
/// ÇİZMEZ; sayfa gezinme · yer imi · balon göster/gizle · belge menüsü
/// [buildControls] ile sabit bölmenin çubuğunda çizilir. Kutu durumu
/// değişince (sayfa, sayfa sayısı, yer imi…) dinleyiciler uyarılır —
/// yalnız çubuk yeniden kurulur, belge değil.
class PdfBoxBar extends ChangeNotifier {
  _PdfPageBoxState? _box;
  Object? _signature;

  /// Belge açıldı mı (çubukta denetim var mı)?
  bool get ready => _box?._doc != null;

  /// Geçerli sayfa ve toplam sayfa sayısı (levha başlığı için).
  int get page => _box?._page ?? 0;
  int get pageCount => _box?._count ?? 0;

  /// Sabit bölme çubuğuna konan denetimler ([width] çubuğun genişliği).
  List<Widget> buildControls(BuildContext context, double width) =>
      _box?._externalControls(context, width) ?? const [];

  /// Belge menüsünün maddeleri — sabit bölmenin TEK ⋮ levhasında çizilir
  /// (P49: "⋮ ile sayfalara göz at menüleri tek ⋮ menüde"). Belge
  /// açılmadıysa boş. Tam ekran bölme çubuğunun kendi düğmesi: burada yok.
  List<PdfMenuAction> menuActions(BuildContext context) {
    final box = _box;
    final document = box?._doc?.document;
    if (box == null || document == null) return const [];
    return box._menuActions(context, document, fullScreen: false);
  }

  /// Etkin PDF sayfasının alan işlemleri levhasını açar.
  Future<void> openAreaActions() async => _box?._captureActivePage();

  void _attach(_PdfPageBoxState box) {
    _box = box;
    _signature = null;
  }

  void _detach(_PdfPageBoxState box) {
    if (identical(_box, box)) _box = null;
  }

  bool _disposed = false;

  void _update(Object signature) {
    if (signature == _signature) return;
    _signature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Belge menüsünün bir maddesi (bkz. [PdfBoxBar.menuActions]).
typedef PdfMenuAction = ({
  String id,
  IconData icon,
  String label,
  VoidCallback run,
});


extension _PdfPageBoxUi on _PdfPageBoxState {
  /// Sayfanın üst katmanları: balonlar, (genişliğe oturan kipte) el yazısı
  /// ve seçim katmanı. Hiçbiri yoksa null.
  Widget? _pageOverlay(
    PdfDocument document,
    int pageNumber,
    BubbleController? bubbles,
  ) {
    final a = widget.attachment;
    final pen = widget.ink;
    // Gömülü (kapak) kutuda da kalem verilince yazılır (2026-11-09).
    final inkHere = pen != null || (widget.fitWidth && a.ink.isNotEmpty);
    if (bubbles == null && !inkHere && !_selectable) return null;
    // KÖK NEDEN (kullanıcı bulgusu 2026-11-08: "sabit moddayken PDF üzerine
    // kalemle yazamıyorum, yalnız tam ekranda yazılıyor"): kalem katmanı
    // seçim ve balon katmanlarının ALTINDAYDI — kalemin dokunuşunu üstteki
    // seçim katmanı (basılı tut = seç) alıyordu. Kalem açıkken mürekkep EN
    // ÜSTTE ve seçim katmanı yok (yazarken seçim gerekmez).
    // Balon bırakma kipinde kalem yazmaz (kullanıcı bulgusu 2026-11-22):
    // dokunuş balonu/metni bırakır, çizgiler yalnız boyanır.
    final penOn = inkHere && pen != null && !_bubbleEdit;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          if (inkHere && !penOn)
            IgnorePointer(
              child: CustomPaint(
                painter: InkPainter(pen?.ink ?? a.ink, pageNumber),
              ),
            ),
          if (_selectable && !penOn)
            ValueListenableBuilder<int>(
              valueListenable: _selection.page,
              builder: (context, active, _) => Stack(
                fit: StackFit.expand,
                children: [
                  PdfSelectLayer(
                    page: document.pages[pageNumber - 1],
                    pageSize: box.biggest,
                    activeSelectionPage: active,
                    // Basılı tut = seçim; genişliğe oturan (yakınlaşan)
                    // kipte çift dokunuş yakınlaştırmanın.
                    doubleTapSelects: !widget.fitWidth,
                    onSelected: (text, rects, page, fromOcr) =>
                        _onSelected(document, text, rects, page, fromOcr),
                    onSelectingChanged: _setSelecting,
                  ),
                ],
              ),
            ),
          if (bubbles != null)
            BubblePageLayer(
              controller: bubbles,
              page: pageNumber,
              readOnly: penOn || !(_bubbleEdit || _bubblesWritable),
            ),
          // Avuç ve kalem burada yakalanır: kalem yazarken değen avuç sayfayı
          // kaydırmaz/çevirmez; parmak (izinsiz) kaydırmaya devam eder.
          // Parmak çiziyorsa (kalemsiz cihazda kalem düğmesi) sarılmaz: iki
          // parmak yakınlaştırma yutulmasın.
          if (penOn)
            pen.accepts(PointerDeviceKind.touch)
                ? InkPageLayer(controller: pen, page: pageNumber)
                : InkClaim(
                    ink: pen,
                    child: InkPageLayer(controller: pen, page: pageNumber),
                  ),
        ],
      ),
    );
  }

  /// Seçim varken kutunun TEPESİNDE beliren çubuk: **Not al** (birincil,
  /// yazılı) · Kopyala · Vurgula · Kapat. Tepede: alttaki sayfa çubuğunu ve
  /// seçimin tutamaçlarını örtmesin.
  Widget _selectionBar(BuildContext context, PdfDocument document) {
    final l10n = context.l10n;
    Widget icon(IconData icon, String tooltip, VoidCallback onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: AppIconSize.m),
          visualDensity: VisualDensity.compact,
        );
    return Material(
      key: const ValueKey('pdf-box-selection-bar'),
      color: Colors.black.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              key: const ValueKey('pdf-box-note-from-selection'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => _noteFromSelection(document),
              icon: const Icon(Icons.edit_note, size: AppIconSize.m),
              label: Text(l10n.pdfNoteFromSelection),
            ),
            icon(Icons.copy, l10n.copy, _copySelection),
            icon(Icons.border_color, l10n.pdfHighlight, _highlightSelection),
            icon(Icons.close, l10n.close, _clearSelection),
          ],
        ),
      ),
    );
  }

  /// Kutunun dibindeki gezinme çubuğu: ‹ · sayfa · › · yer imi · menü.
  ///
  /// **DAR KUTUYA SIĞMALI**: kutu sayfanın istenen genişliğinde olabiliyor
  /// (en az %15). Beş denetim 130 dp'lik bir kutuda taşardı; çubuk kutunun
  /// genişliğine göre inceliyor — önce yer imi düğmesi (menüde de var),
  /// sonra oklar düşüyor. Menü her boyda kalıyor: bütün işlemler orada.
  ///
  /// SAYAÇ KESİLMEMELİ (kullanıcı ekran görüntüsü 2026-09-29: "5 /…"):
  /// menü düğmesi Material'in 48 dp'lik asgari dokunma kutusunu alıyor ve
  /// 170 dp'lik kutuda sayaca yer bırakmıyordu. Menü artık çubuğun
  /// düğmeleriyle aynı boyda; geniş kutuda düğmeler büyür (parmakla
  /// isabet kolaylaşsın).
  Widget _bar(BuildContext context, PdfDocument document) => LayoutBuilder(
    builder: (context, constraints) =>
        _barRow(context, document, constraints.maxWidth),
  );

  Widget _barRow(BuildContext context, PdfDocument document, double width) {
    final l10n = context.l10n;
    final a = widget.attachment;
    final marked = a.pdfMarks.contains(_page);
    final notes = a.bubbles.where((b) => b.page == _page).length;
    final showMark = width >= 210;
    // Balonlar çiziliyorsa sayfa rozeti yerine GÖSTER/GİZLE düğmesi.
    final bubbleToggle = widget.showBubbles && a.bubbles.isNotEmpty;
    final showArrows = width >= 110;
    final big = width >= 150;
    return Material(
      color: Colors.black.withValues(alpha: widget.fitWidth ? 0.38 : 0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showArrows)
              _barButton(
                icon: Icons.chevron_left,
                tooltip: l10n.pdfPreviousPage,
                big: big,
                onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
              ),
            Flexible(
              child: InkWell(
                onTap: _count > 0 ? () => _openJumpSheet(document) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (marked)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.bookmark,
                            size: 12,
                            color: Colors.amber,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          '$_page / ${_count == 0 ? '…' : _count}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: big ? 12 : 11,
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                      ),
                      // Sayfa notu rozeti: bu sayfada balon/vurgu var mı?
                      if (notes > 0 && showMark && !bubbleToggle)
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble,
                                size: 10,
                                color: Colors.white70,
                              ),
                              Text(
                                ' $notes',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (showArrows)
              _barButton(
                icon: Icons.chevron_right,
                tooltip: l10n.pdfNextPage,
                big: big,
                onPressed: _count > 0 && _page < _count
                    ? () => _goTo(_page + 1)
                    : null,
              ),
            if (bubbleToggle)
              _barButton(
                key: const ValueKey('pdf-box-bubbles'),
                icon: a.bubblesHidden
                    ? Icons.speaker_notes_off_outlined
                    : Icons.chat_bubble_outline,
                tooltip: a.bubblesHidden ? l10n.bubblesShow : l10n.bubblesHide,
                color: a.bubblesHidden ? Colors.white54 : Colors.white,
                big: big,
                onPressed: () => widget.onChanged(
                  a.copyWith(bubblesHidden: !a.bubblesHidden),
                ),
              ),
            // BALON EKLE (sabit bölme): kipi aç/kapa.
            if (widget.fitWidth && widget.showBubbles && showMark)
              _barButton(
                key: const ValueKey('pdf-box-add-bubble'),
                icon: _bubbleEdit ? Icons.check : Icons.add_comment_outlined,
                tooltip: _bubbleEdit ? l10n.bubbleAddDone : l10n.bubbleAdd,
                color: _bubbleEdit ? Colors.amber : Colors.white,
                big: big,
                onPressed: _toggleBubbleEdit,
              ),
            if (showMark)
              _barButton(
                icon: marked ? Icons.bookmark : Icons.bookmark_border,
                tooltip: marked ? l10n.pdfBookmarkRemove : l10n.pdfBookmarkAdd,
                color: marked ? Colors.amber : Colors.white,
                big: big,
                onPressed: _toggleMark,
              ),
            _menu(context, document, big: big),
          ],
        ),
      ),
    );
  }

  /// Sabit bölme çubuğundaki denetimler ([PdfBoxBar]): yalnız GENİŞ çubukta
  /// (≥ 600 dp) yer imi. Belge menüsü ayrı düğme DEĞİL (P49, K-O6): maddeler
  /// bölmenin tek ⋮ levhasında ([PdfBoxBar.menuActions]); balon göster/gizle
  /// balon menüsünde.
  List<Widget> _externalControls(BuildContext context, double width) {
    if (_doc?.document == null || width < 600) return const [];
    final l10n = context.l10n;
    final marked = widget.attachment.pdfMarks.contains(_page);
    // Sayfa gezinme (‹ n/N ›) çubukta YOK (F65.8): sayfalar dikey kayar,
    // numara bölmenin sağ altındaki hapta ([PdfPagePill]).
    return [
      IconButton(
        key: const ValueKey('pinned-pdf-mark'),
        tooltip: marked ? l10n.pdfBookmarkRemove : l10n.pdfBookmarkAdd,
        visualDensity: VisualDensity.compact,
        iconSize: AppIconSize.m,
        color: marked ? Theme.of(context).colorScheme.primary : null,
        icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border),
        onPressed: _busy ? null : _toggleMark,
      ),
    ];
  }

  /// Belge menüsünün maddeleri — kutunun kendi ⋮'ı ve sabit bölmenin levhası
  /// AYNI listeyi çizer (tek yer).
  List<PdfMenuAction> _menuActions(
    BuildContext context,
    PdfDocument document, {
    bool fullScreen = true,
  }) {
    final l10n = context.l10n;
    final playing = _autoPlay != null;
    final marked = widget.attachment.pdfMarks.contains(_page);
    void guarded(VoidCallback run) {
      if (mounted && !_busy) run();
    }

    return [
      (
        id: 'pages',
        icon: Icons.grid_view_outlined,
        label: l10n.pdfThumbnails,
        run: () => guarded(() => _openJumpSheet(document)),
      ),
      (
        id: 'mark',
        icon: marked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined,
        label: marked ? l10n.pdfBookmarkRemove : l10n.pdfBookmarkAdd,
        run: () => guarded(_toggleMark),
      ),
      (
        id: 'marks',
        icon: Icons.bookmarks_outlined,
        label: l10n.pdfBookmarks,
        run: () => guarded(_openMarks),
      ),
      // BALONLARIN TOPLU LİSTESİ (kullanıcı bulgusu 2026-11-14: "balonları
      // toplu gördüğümüz yer kaybolmuş"): sabit bölmede liste düğmesi
      // yoktu; ⋮ levhasının PDF bölümünde.
      if (widget.attachment.bubbles.isNotEmpty)
        (
          id: 'bubbles',
          icon: Icons.forum_outlined,
          label: l10n.bubblesListAll,
          run: () => guarded(_openBubbleList),
        ),
      (
        id: 'rotate',
        icon: Icons.rotate_90_degrees_ccw,
        label: l10n.pdfRotateView,
        run: () => guarded(_rotate),
      ),
      (
        id: 'play',
        icon: playing
            ? Icons.pause_circle_outline
            : Icons.play_circle_outline,
        label: playing ? l10n.pdfSlideshowStop : l10n.pdfSlideshow,
        run: () => guarded(_toggleAutoPlay),
      ),
      (
        id: 'text',
        icon: Icons.text_snippet_outlined,
        label: l10n.pdfCopyPageText,
        run: () => guarded(_copyPageText),
      ),
      (
        id: 'capture',
        icon: Icons.auto_awesome,
        label: l10n.pdfCapturePage,
        run: () => guarded(() => _capturePage(document)),
      ),
      if (fullScreen)
        (
          id: 'full',
          icon: Icons.fullscreen,
          label: l10n.pdfFullScreen,
          run: () => guarded(_openFullScreen),
        ),
    ];
  }

  Widget _barButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color color = Colors.white,
    bool big = false,
    Key? key,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    iconSize: big ? 20 : 16,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints(
      minWidth: big ? 34 : 26,
      minHeight: big ? 32 : 26,
    ),
    visualDensity: VisualDensity.compact,
    color: color,
    disabledColor: Colors.white30,
    icon: Icon(icon),
    onPressed: _busy ? null : onPressed,
  );

  Widget _menu(BuildContext context, PdfDocument document, {bool big = false}) {
    return SizedBox(
      width: big ? 32 : 26,
      height: big ? 32 : 26,
      child: PopupMenuButton<String>(
        tooltip: context.l10n.more,
        iconSize: big ? 20 : 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 200),
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (id) => _menuActions(
          context,
          document,
        ).firstWhere((a) => a.id == id).run(),
        itemBuilder: (context) => [
          for (final a in _menuActions(context, document))
            _menuItem(a.id, a.icon, a.label),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem<String>(
        value: value,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
        ),
      );

  /// Yer imi listesi: konan sayfalara tek dokunuşla atlanır.
  /// Belgedeki bütün balonlar (arama, yıldız, düzenle, sil, kopyala);
  /// seçilen balonun sayfasına gidilir ve balon açılır.
  Future<void> _openBubbleList() async {
    final bubbles = _bubbleController();
    final target = await showBubblesOverview(context, bubbles);
    if (target == null || !mounted) return;
    _goTo(target.page);
    bubbles.openOnly(target.id);
  }

  Future<void> _openMarks() async {
    final marks = widget.attachment.pdfMarks;
    final l10n = context.l10n;
    final target = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: marks.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(l10n.pdfNoBookmarks),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final page in marks)
                    ListTile(
                      leading: const Icon(Icons.bookmark, color: Colors.amber),
                      title: Text(l10n.pdfPage(page)),
                      onTap: () => Navigator.of(context).pop(page),
                    ),
                ],
              ),
      ),
    );
    if (target != null && mounted) _goTo(target);
}
}


/// Sayfaya atlama levhası: kaydırıcı + ilk/son + küçük resim ızgarası.
class _PdfJumpSheet extends StatefulWidget {
  const _PdfJumpSheet({
    required this.document,
    required this.page,
    required this.marks,
  });

  final PdfDocument document;
  final int page;
  final List<int> marks;

  @override
  State<_PdfJumpSheet> createState() => _PdfJumpSheetState();
}

class _PdfJumpSheetState extends State<_PdfJumpSheet> {
  late int _page = widget.page;

  int get _count => widget.document.pages.length;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.pdfPageOf(_page, _count),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.pdfFirstPage,
                  icon: const Icon(Icons.first_page),
                  onPressed: () => setState(() => _page = 1),
                ),
                Expanded(
                  child: Slider(
                    value: _page.toDouble().clamp(1, _count.toDouble()),
                    min: 1,
                    max: _count.toDouble(),
                    divisions: _count > 1 ? _count - 1 : null,
                    label: '$_page',
                    onChanged: (v) => setState(() => _page = v.round()),
                  ),
                ),
                IconButton(
                  tooltip: l10n.pdfLastPage,
                  icon: const Icon(Icons.last_page),
                  onPressed: () => setState(() => _page = _count),
                ),
              ],
            ),
            // Küçük resimler: sayfayı görerek seçmek numara yazmaktan hızlı.
            SizedBox(
              height: 260,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _count,
                itemBuilder: (context, i) {
                  final number = i + 1;
                  final selected = number == _page;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(number),
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: PdfPageImage(
                              document: widget.document,
                              pageNumber: number,
                              maximumDpi: 72,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.marks.contains(number))
                              const Icon(
                                Icons.bookmark,
                                size: 11,
                                color: Colors.amber,
                              ),
                            Text(
                              '$number',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_page),
              child: Text(l10n.pdfGoToPage),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SAF MANTIK (ölçülebilir; pdfium gerektirmez) ────────────────────────────

/// Sayfa numarasını belgenin sınırlarına oturtur. Belge henüz açılmadıysa
/// ([count] = 0) numara olduğu gibi kalır — açılınca yeniden kırpılır.
int clampPdfPage(int page, int count) {
  if (count <= 0) return page < 1 ? 1 : page;
  if (page < 1) return 1;
  if (page > count) return count;
  return page;
}

/// Otomatik geçişte sıradaki sayfa: sonuncudan sonra BAŞA döner.
int autoPlayNext(int page, int count) {
  if (count <= 0) return page;
  return page >= count ? 1 : page + 1;
}

/// Yer imini ekler ya da kaldırır; liste her zaman sıralı ve tekrarsız.
List<int> togglePdfMark(List<int> marks, int page) {
  final out = [...marks];
  if (out.remove(page)) return out..sort();
  return out
    ..add(page)
    ..sort();
}

/// Döndürülmüş kutunun en-boy oranı: 90°/270°'de sayfa yan yatar.
double pdfBoxAspect(double width, double height, int turns) {
  if (width <= 0 || height <= 0) return 1;
  return turns.isEven ? width / height : height / width;
}
