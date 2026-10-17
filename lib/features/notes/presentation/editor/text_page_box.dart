import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// Sayfaya gömülen METİN kutusunun ekte saklanan oranı (genişlik × yükseklik;
/// birimsiz). Görseldeki `width`/`height` alanlarıyla aynı yerde durur ki
/// tuvalin bütün oran hesapları (sarma, yerleşim, boyutlandırma) değişmeden
/// çalışsın. 1:1,3 — okunaklı bir kâğıt sayfası, A4'ten biraz geniş.
const int kTextBoxWidth = 1000;
const int kTextBoxHeight = 1300;

/// Kutunun İÇİ bu sabit "referans" ölçüde dizilir ve kutuya ölçeklenir
/// (`FittedBox`). Neden: sayfalama kutunun dp boyuna bağlı olsaydı her
/// boyutlandırmada sayfalar yeniden bölünür, kaydedilen "kaldığın sayfa"
/// başka bir metne denk gelirdi. Böylece kutu PDF sayfası gibi davranır:
/// büyüyünce yazı büyür, sayfa aynı kalır.
const double _kRefWidth = 260;
const double _kPadH = 16;
const double _kPadTop = 14;
const double _kBarHeight = 24;
const Color _kBarInk = Color(0xFF5B544A);

/// Referans sayfanın metin stili (kutunun ve sayfalamanın ORTAK kaynağı —
/// ikisi ayrı stil kullanırsa sayfa sonları kayar).
TextStyle _pageStyle(BuildContext context) =>
    DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        fontSize: 11,
        height: 1.45,
        color: Color(0xFF2D2A26),
        letterSpacing: 0,
        decoration: TextDecoration.none,
      ),
    );

/// **SAYFAYA GÖMÜLÜ METİN** (kullanıcı isteği 2026-10-17: "txt dosyaları da
/// ekrana gömme, yukarı sabitleme ve balonlu mod geçişi").
///
/// PDF kutusunun ([PdfPageBox]) metin karşılığı: notun sayfasında yüzen bir
/// kâğıt; görsel gibi taşınır, boyutlanır, yazı etrafından akar. Uzun metin
/// SAYFALARA bölünür — yatay kaydırma ya da ‹ › ile çevrilir, "3 / 12"
/// göstergesi kaldığın yeri söyler (sayfa ekte `pdfPage` alanında saklanır,
/// PDF'teki gibi senkronlanır). ⤢ tam okuma ekranını açar.
class TextPageBox extends StatefulWidget {
  const TextPageBox({
    super.key,
    required this.attachment,
    required this.onChanged,
    this.onOpen,
    this.swipeToTurn = true,
    this.controls = true,
  });

  final Attachment attachment;

  /// Sayfa değişince nota yazılır (gecikmeli — parmak her sayfada kaydı
  /// tetiklemesin).
  final ValueChanged<Attachment> onChanged;

  /// Tam okuma ekranı (transkript ekranı). null ise düğme yok.
  final VoidCallback? onOpen;

  /// Kutu üzerinde yatay kaydırma sayfa çevirsin mi (bkz. PdfPageBox).
  final bool swipeToTurn;

  /// false ise alt çubuk çizilmez (salt görüntü: kart, küçük önizleme).
  final bool controls;

  @override
  State<TextPageBox> createState() => _TextPageBoxState();
}

class _TextPageBoxState extends State<TextPageBox> {
  TextPagination? _pages;
  PageController? _pager;
  late int _page = widget.attachment.pdfPage.clamp(1, 1 << 20);
  Timer? _save;

  double get _aspect {
    final w = (widget.attachment.width ?? 0).toDouble();
    final h = (widget.attachment.height ?? 0).toDouble();
    return w > 0 && h > 0 ? w / h : kTextBoxWidth / kTextBoxHeight;
  }

  Size get _refSize => Size(_kRefWidth, _kRefWidth / _aspect);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindPages();
  }

  @override
  void didUpdateWidget(TextPageBox old) {
    super.didUpdateWidget(old);
    if (old.attachment.text != widget.attachment.text ||
        old.attachment.width != widget.attachment.width ||
        old.attachment.height != widget.attachment.height) {
      _bindPages();
    }
  }

  void _bindPages() {
    final next = TextPagination.of(
      text: widget.attachment.text,
      title: _titleOf(widget.attachment),
      style: _pageStyle(context),
      page: _refSize,
      padding: const EdgeInsets.fromLTRB(
        _kPadH,
        _kPadTop,
        _kPadH,
        _kBarHeight + 6,
      ),
    );
    if (identical(next, _pages)) return;
    _pages?.removeListener(_onPagesGrew);
    _pages = next..addListener(_onPagesGrew);
  }

  void _onPagesGrew() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pages?.removeListener(_onPagesGrew);
    _pager?.dispose();
    _save?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    if (page == _page) return;
    setState(() => _page = page);
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || widget.attachment.pdfPage == _page) return;
      widget.onChanged(widget.attachment.copyWith(pdfPage: _page));
    });
  }

  void _turn(int delta) {
    final pager = _pager;
    final pages = _pages;
    if (pager == null || pages == null || !pager.hasClients) return;
    final target = (_page - 1 + delta).clamp(0, pages.count - 1);
    HapticFeedback.selectionClick();
    pager.animateToPage(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages!;
    final count = pages.count;
    if (_page > count && pages.complete) _page = count.clamp(1, 1 << 20);
    final pager = _pager ??= PageController(initialPage: _page - 1);
    final style = _pageStyle(context);
    final ref = _refSize;
    // `contain`: kutunun oranı sayfanınkinden saparsa (eski kayıt) yazı
    // ÇARPILMAZ, kenarlar kâğıt rengiyle dolar.
    return ColoredBox(
      color: const Color(0xFFFFFDF8),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: ref.width,
          height: ref.height,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFFFFDF8)),
            child: Stack(
              children: [
                PageView.builder(
                  controller: pager,
                  physics: widget.swipeToTurn
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  allowImplicitScrolling: true,
                  itemCount: count,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, i) =>
                      _PageText(pages: pages, index: i, style: style),
                ),
                if (widget.controls)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _kBarHeight,
                    child: _bar(context, pages),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, TextPagination pages) {
    final l10n = context.l10n;
    final total = pages.complete ? '${pages.count}' : '${pages.count}+';
    return Material(
      type: MaterialType.transparency,
      child: _barBody(context, pages, l10n, total),
    );
  }

  Widget _barBody(
    BuildContext context,
    TextPagination pages,
    AppLocalizations l10n,
    String total,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF3EEE3),
        border: Border(top: BorderSide(color: Color(0xFFE4DCCB), width: 0.6)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const Icon(Icons.notes_rounded, size: 12, color: Color(0xFF8D6E63)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: _kBarInk,
              ),
            ),
          ),
          if (pages.count > 1) ...[
            _BarIcon(
              icon: Icons.chevron_left_rounded,
              tooltip: l10n.pdfPreviousPage,
              onTap: _page > 1 ? () => _turn(-1) : null,
            ),
            Flexible(
              child: Text(
                '$_page / $total',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: _kBarInk,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _BarIcon(
              icon: Icons.chevron_right_rounded,
              tooltip: l10n.pdfNextPage,
              onTap: _page < pages.count ? () => _turn(1) : null,
            ),
          ],
          if (widget.onOpen != null)
            _BarIcon(
              icon: Icons.open_in_full_rounded,
              tooltip: l10n.fullscreen,
              onTap: widget.onOpen,
              size: 11,
            ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

String _titleOf(Attachment a) {
  final dot = a.fileName.lastIndexOf('.');
  return dot > 0 ? a.fileName.substring(0, dot) : a.fileName;
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 14,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onTap,
      radius: 14,
      child: SizedBox(
        width: 22,
        height: _kBarHeight,
        child: Icon(
          icon,
          size: size,
          color: onTap == null
              ? const Color(0x405B544A)
              : const Color(0xFF5B544A),
        ),
      ),
    ),
  );
}

class _PageText extends StatelessWidget {
  const _PageText({
    required this.pages,
    required this.index,
    required this.style,
  });

  final TextPagination pages;
  final int index;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final body = pages.pageText(index);
    return Padding(
      padding: pages.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index == 0 && pages.title.isNotEmpty)
            Text(
              pages.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: pages.titleStyle,
            ),
          Text(body, textScaler: TextScaler.noScaling, style: style),
        ],
      ),
    );
  }
}

/// Metnin sabit bir sayfa ölçüsünde SAYFALARA bölünmüş hâli.
///
/// Her sayfa, metnin bir SATIR BAŞINDAN başlayan dilimidir: dilim aynı
/// genişlikte yeniden dizilince satırlar aynı yerden kırılır (açgözlü satır
/// kırma, satır başından başlayınca kararlıdır), yani sayfada görülen metin
/// ölçülen metnin aynısıdır.
///
/// MALİYET: 120 bin karakterlik bir transkript (~130 sayfa) tek seferde
/// bölünseydi kutunun ilk karesi onlarca ms takılırdı. İlk birkaç sayfa
/// hemen, kalanı kısa aralıklarla parça parça bölünür; sayaç o sırada
/// "3 / 12+" der. Sonuç aynı metin + ölçü için ÖNBELLEKTE (kutu yeniden
/// kurulunca, sabit bölmeden sayfaya inince yeniden bölünmez).
class TextPagination extends ChangeNotifier {
  TextPagination._({
    required this.text,
    required this.title,
    required this.style,
    required this.page,
    required this.padding,
  }) : titleStyle = style.merge(
         const TextStyle(
           fontSize: 13.5,
           height: 1.3,
           fontWeight: FontWeight.w700,
         ),
       ) {
    _layoutTitle();
    _advance(3);
    if (!complete) _schedule();
  }

  /// Önbellekli kurucu: aynı metin/başlık/stil/ölçü için AYNI nesne.
  factory TextPagination.of({
    required String text,
    required String title,
    required TextStyle style,
    required Size page,
    required EdgeInsets padding,
  }) {
    final key = Object.hash(
      text.length,
      text.hashCode,
      title,
      style,
      page,
      padding,
    );
    final cached = _cache.remove(key);
    if (cached != null && cached.text == text) {
      _cache[key] = cached;
      return cached;
    }
    final made = TextPagination._(
      text: text,
      title: title,
      style: style,
      page: page,
      padding: padding,
    );
    _cache[key] = made;
    while (_cache.length > 12) {
      _cache.remove(_cache.keys.first);
    }
    return made;
  }

  static final _cache = <int, TextPagination>{};

  final String text;
  final String title;
  final TextStyle style;
  final TextStyle titleStyle;
  final Size page;
  final EdgeInsets padding;

  /// Sayfa başlangıçları (karakter konumu). Son öğe bir sonraki sayfanın
  /// başı ya da (bittiyse) metnin sonu.
  final _starts = <int>[0];
  bool _complete = false;
  double _titleHeight = 0;

  bool get complete => _complete;

  /// Bilinen sayfa sayısı (bölme sürerken artar; boş metinde 1).
  int get count => (_starts.length - 1).clamp(1, 1 << 20);

  double get _width => page.width - padding.horizontal;
  double get _height => page.height - padding.vertical;

  /// [index]. sayfanın metni (sondaki satır sonu kırpılır — boş satır
  /// çizilmesin).
  String pageText(int index) {
    if (index + 1 >= _starts.length) return '';
    var end = _starts[index + 1];
    final start = _starts[index];
    while (end > start && text.codeUnitAt(end - 1) == 0x0A) {
      end--;
    }
    return text.substring(start, end);
  }

  void _layoutTitle() {
    if (title.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: _width);
    _titleHeight = painter.height;
    painter.dispose();
  }

  Timer? _tick;

  /// Kalan sayfaları kısa aralıklarla, parça parça böler.
  ///
  /// TUZAK — `SchedulerBinding.scheduleTask(Priority.idle)` KULLANILMADI:
  /// bir animasyon sürerken (sayfa çevirme, levha açılışı) boşta öncelikli
  /// görev ertelenir ama zamanlayıcı her olay döngüsünde SIFIR gecikmeyle
  /// yeniden kurulur — cihazda animasyon boyunca boşa dönen bir döngü
  /// (pil), testte sonsuz döngü. Küçük gecikmeli bir zamanlayıcı her
  /// adımda ~1–2 ms iş yapar ve kareyi hiç bekletmez.
  void _schedule() {
    if (_tick != null || _complete) return;
    _tick = Timer(const Duration(milliseconds: 24), () {
      _tick = null;
      _advance(6);
      notifyListeners();
      if (!_complete) _schedule();
    });
  }

  /// En çok [pages] sayfa daha böler.
  void _advance(int pages) {
    for (var i = 0; i < pages && !_complete; i++) {
      final start = _starts.last;
      if (start >= text.length) {
        if (_starts.length == 1) _starts.add(text.length);
        _complete = true;
        return;
      }
      final room = _starts.length == 1 ? _height - _titleHeight : _height;
      final end = _pageEnd(start, room);
      _starts.add(end);
      if (end >= text.length) _complete = true;
    }
  }

  /// [start]'tan başlayan sayfanın sonu: [room] yüksekliğe sığan son TAM
  /// satırın sonu. Metnin tamamı yerine bir PENCERE dizilir (sayfaya sığan
  /// metnin birkaç katı); pencere yetmezse büyütülür.
  int _pageEnd(int start, double room) {
    var window = 2400;
    while (true) {
      final end = (start + window).clamp(0, text.length);
      final slice = text.substring(start, end);
      final painter = TextPainter(
        text: TextSpan(text: slice, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: _width);
      final lines = painter.computeLineMetrics();
      var used = 0.0;
      var fit = 0;
      for (final line in lines) {
        if (used + line.height > room + 0.5) break;
        used += line.height;
        fit++;
      }
      // Pencere bitti ama sayfa dolmadı: metin bittiyse sayfa da biter,
      // bitmediyse pencere küçük kaldı — büyüt.
      if (fit >= lines.length) {
        painter.dispose();
        if (end >= text.length) return text.length;
        window *= 2;
        continue;
      }
      if (fit == 0) fit = 1; // tek satır bile sığmıyorsa yine de ilerle
      final y = lines[fit - 1].baseline + lines[fit - 1].descent;
      final next = painter.getPositionForOffset(Offset(0, y + 0.5)).offset;
      painter.dispose();
      // Güvence: ilerleme yoksa (çok uzun tek kelime) bir satır ileri.
      return next <= 0 ? (start + 1).clamp(0, text.length) : start + next;
    }
  }
}

/// **SABİT BÖLMEDE METİN** — notun tepesinde okunan kâğıt: kaydırılır,
/// seçilir (seçim menüsünden kopyalanır), not altında yazılır.
///
/// Uzun metin PARAGRAF paragraf tembel kurulur (120 bin karakterlik bir
/// transkript tek `Text` olsaydı her kaydırma karesinde dev bir yerleşim
/// taşınırdı).
class TextReaderView extends StatelessWidget {
  const TextReaderView({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final paragraphs = attachment.text.split('\n');
    final style = DefaultTextStyle.of(context).style.merge(
      const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF2D2A26)),
    );
    return ColoredBox(
      color: const Color(0xFFFFFDF8),
      child: SelectionArea(
        child: Scrollbar(
          child: ListView.builder(
            key: PageStorageKey('pinned-text-${attachment.id}'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            itemCount: paragraphs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _titleOf(attachment),
                    style: style.merge(
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }
              final p = paragraphs[i - 1];
              return Text(p.isEmpty ? ' ' : p, style: style);
            },
          ),
        ),
      ),
    );
  }
}
