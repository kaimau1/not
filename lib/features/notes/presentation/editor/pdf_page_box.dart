import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/pdf/pdf_page_ocr.dart';
import '../../data/pdf_text.dart';
import '../../domain/attachment.dart';
import '../viewers/area_actions.dart';
import '../viewers/bubble_layer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_page_image.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';

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
class PdfPageBox extends StatefulWidget {
  const PdfPageBox({
    super.key,
    required this.attachment,
    required this.onChanged,
    this.controls = true,
    this.swipeToTurn = true,
    this.onDetach,
    this.showBubbles = false,
  });

  /// Belgenin BALONLARI sayfanın üstünde çizilsin mi (salt okunur: dokununca
  /// okuma kartı açılır). Kullanıcı isteği 2026-10-16: "balonludan üste
  /// sabitlemeye alınca da balonlar görülsün ama göster/gizlesi olsun" —
  /// sabit bölme açar; çubukta göster/gizle düğmesi çıkar
  /// ([Attachment.bubblesHidden]). Sayfadaki yüzen kutuda kapalı (orada
  /// dokunuş kutuyu seçer/taşır).
  final bool showBubbles;

  final Attachment attachment;

  /// Sayfa numarası, yer imi, döndürme ve ölçü değişiklikleri buradan
  /// nota yazılır (ve senkronlanır).
  final ValueChanged<Attachment> onChanged;

  /// false ise gezinme çubuğu çizilmez (salt görüntü).
  final bool controls;

  /// Kutu üzerinde yatay kaydırma sayfa çevirsin mi? Büyük önizlemede
  /// KAPALI: oradaki yatay kaydırma nottaki DİĞER EKE geçiyor, iki jest
  /// aynı parmağı paylaşamaz (çubuğun okları orada da çalışıyor).
  final bool swipeToTurn;

  /// Kutuyu sayfadan alıp ek şeridine taşır; null ise menüde görünmez.
  final VoidCallback? onDetach;

  @override
  State<PdfPageBox> createState() => _PdfPageBoxState();
}

class _PdfPageBoxState extends State<PdfPageBox> {
  /// Kutunun GÖSTERDİĞİ sayfa. Ekten okunur ama ekle aynı anda ilerlemez:
  /// yazma gecikmeli, sayfa ise parmakla anında değişmeli.
  late int _page = widget.attachment.pdfPage;

  /// Belgenin sayfa sayısı (0 = henüz açılmadı).
  int _count = 0;

  /// **SAYFALAR PARMAĞI İZLEYEREK KAYAR** (kullanıcı bulgusu 2026-09-29:
  /// "sayfalarını değiştirmek zor"). Eskiden kutu yalnız HIZLI bir yatay
  /// fiskeyi (80 px/sn üstü) sayıyordu: yavaş sürükleme hiçbir şey
  /// yapmıyor, parmak sayfayı hareket ettirmiyor, kullanıcı çevirip
  /// çevirmediğini anlamıyordu. Artık kutunun içi bir sayfa çevirici:
  /// sayfa parmakla birlikte kayar, yarıyı geçince yerine oturur; komşu
  /// sayfalar önceden çizilir (allowImplicitScrolling).
  ///
  /// Belge açılınca kurulur (başlangıç sayfası ancak o zaman kırpılabilir).
  PageController? _pager;

  /// Otomatik geçiş zamanlayıcısı (null = kapalı).
  Timer? _autoPlay;

  /// Metin/görüntü işlemi sürerken düğmeler kilitlenir.
  bool _busy = false;

  /// **BELGE BURADA TUTULUYOR — `PdfDocumentViewBuilder` İLE DEĞİL.**
  ///
  /// KÖK NEDEN: o kabuk `didUpdateWidget`te dinleyicisini önce kaldırıp sonra
  /// yeniden ekliyor. Kaldırma anında dinleyici sayısı sıfıra düşerse pdfrx
  /// belgeyi KAPATIYOR (`autoDispose`) ve hemen ardından yeniden açıyor —
  /// yani not sayfası her yeniden kurulduğunda (yazarken de) PDF baştan
  /// yükleniyordu. Dinleyici doğrudan bu State'te durunca sayı hiç sıfıra
  /// düşmez; belge bir kez açılır, kutu kapanınca kapanır.
  PdfDocumentListenable? _doc;
  StreamSubscription<PdfDocumentEvent>? _events;

  @override
  void initState() {
    super.initState();
    _attachDocument();
  }

  /// Ekin kaynağı (yerel kopya → indirme adresi) için belge dinleyicisi.
  /// pdfrx dinleyicileri kaynak yoluna göre paylaşıyor: aynı PDF birden çok
  /// yerde açıksa (kutu + tam ekran) tek belge yüklenir.
  void _attachDocument() {
    final a = widget.attachment;
    final hasLocal = a.localPath.isNotEmpty && localFileExists(a.localPath);
    if (!hasLocal && !a.isUploaded) return;
    final ref = hasLocal
        ? PdfDocumentRefFile(a.localPath)
        : PdfDocumentRefUri(Uri.parse(a.downloadUrl));
    final listenable = ref.resolveListenable()..addListener(_onDocument);
    _doc = listenable;
    listenable.load();
    // Belge BAŞKA bir yerde zaten açıksa (paylaşılan dinleyici) dinleyici
    // hiç tetiklenmez; olaylara burada bağlanılır. `setState` YOK — bu yol
    // `initState`ten de geçiyor.
    _bindEvents();
  }

  void _detachDocument() {
    _events?.cancel();
    _events = null;
    _bound = null;
    _doc?.removeListener(_onDocument);
    _doc = null;
  }

  /// Olaylarına bağlanılmış belge (aynı belgeye iki kez abone olunmasın).
  PdfDocument? _bound;

  void _bindEvents() {
    final document = _doc?.document;
    if (document == null || identical(document, _bound)) return;
    _events?.cancel();
    _bound = document;
    // İlerlemeli yükleme: sayfa ölçüleri geldikçe kutu tazelenir.
    _events = document.events.listen((event) {
      if (mounted && event.type == PdfDocumentEventType.pageStatusChanged) {
        setState(() {});
      }
    });
    document.loadPagesProgressively();
  }

  /// Belge yüklendi (ya da yeniden yüklendi).
  void _onDocument() {
    if (!mounted) return;
    _bindEvents();
    setState(() {});
  }

  @override
  void didUpdateWidget(PdfPageBox old) {
    super.didUpdateWidget(old);
    // DIŞARIDAN gelen sayfa değişimi (tam ekrandan dönüş, başka cihaz):
    // kutu oraya gider. Kendi yazdığımız değer geri geldiğinde hiçbir şey
    // olmaz — yoksa parmakla çevirirken sayfa geri sıçrardı (aynı tuzak
    // PDF panosunda da vardı, bkz. pdf_note_pane.dart).
    final incoming = widget.attachment.pdfPage;
    if (incoming != old.attachment.pdfPage && incoming != _page) {
      _page = _clamp(incoming);
      _syncPagerSoon();
    }
    // Tam ekranda/balonlu görünümde değişen balonlar ve gizlilik.
    _bubbles
      ?..replace(widget.attachment.bubbles)
      ..syncHidden(widget.attachment.bubblesHidden);
    // Dosya yolu/adresi değiştiyse (yükleme bitti, dosya yeniden yazıldı)
    // belge yeniden bağlanır.
    if (widget.attachment.localPath != old.attachment.localPath ||
        widget.attachment.downloadUrl != old.attachment.downloadUrl) {
      _detachDocument();
      _attachDocument();
      _syncPagerSoon();
    }
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _detachDocument();
    _pager?.dispose();
    _bubbles?.dispose();
    super.dispose();
  }

  /// Balon katmanının denetleyicisi — yalnız [PdfPageBox.showBubbles] açık
  /// ve belgede balon varken kurulur. Okuma kartının aç/kapa durumu da bu
  /// yoldan nota yazılır (balonlu görünümle aynı veri).
  BubbleController? _bubbles;

  /// Kurulum build'de (bildirim yok); dışarıdan gelen değişiklik
  /// `didUpdateWidget`te benimsenir.
  BubbleController _bubbleController() {
    final a = widget.attachment;
    return _bubbles ??= BubbleController(
      initial: a.bubbles,
      hidden: a.bubblesHidden,
      // İki yazım da İKİ alanın canlı değerini taşır: aynı karede gelen
      // "göster" + "yeni balon" yazımı birbirini bayat ekle ezmesin (bkz.
      // PdfNotePane._live).
      onChanged: (list) => widget.onChanged(
        widget.attachment.copyWith(
          bubbles: list,
          bubblesHidden: _bubbles?.hidden ?? widget.attachment.bubblesHidden,
        ),
      ),
      onHiddenChanged: (hidden) => widget.onChanged(
        widget.attachment.copyWith(
          bubblesHidden: hidden,
          bubbles: _bubbles?.bubbles ?? widget.attachment.bubbles,
        ),
      ),
    );
  }

  /// Çevirici, kutunun gösterdiği sayfadan ayrı düştüyse (dışarıdan gelen
  /// sayfa, tam ekrandan dönüş, belge yeniden bağlandı) oraya ATLAR —
  /// kaydırma animasyonu yok, aradaki sayfalar çizilmesin.
  void _syncPagerSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pager = _pager;
      if (!mounted || pager == null || !pager.hasClients) return;
      final target = _page - 1;
      if ((pager.page ?? target.toDouble()).round() != target) {
        pager.jumpToPage(target);
      }
    });
  }

  int _clamp(int page) => clampPdfPage(page, _count);

  /// Sayfayı değiştirir ve nota yazar (kaldığı yer korunsun).
  ///
  /// Komşu sayfaya KAYARAK gidilir (‹ › düğmeleri parmakla çevirmeyle aynı
  /// görünsün); uzak sayfaya (atlama levhası, yer imi, başa dönüş) ATLANIR:
  /// kaydırılsaydı aradaki her sayfa çizilir ve `onPageChanged` her birinde
  /// nota yazardı.
  void _goTo(int page, {bool save = true}) {
    final next = _clamp(page);
    if (next == _page) return;
    final previous = _page;
    setState(() => _page = next);
    final pager = _pager;
    if (pager != null && pager.hasClients) {
      if ((next - previous).abs() == 1) {
        pager.animateToPage(
          next - 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        pager.jumpToPage(next - 1);
      }
    }
    if (save) widget.onChanged(widget.attachment.copyWith(pdfPage: next));
  }

  /// Parmakla çevrilen sayfa yerine oturdu. Düğmeyle başlatılan geçişin
  /// kendi bildirimi ([_goTo] `_page`'i önceden yazdığı için) yok sayılır.
  void _onPagerChanged(int index) {
    final next = _clamp(index + 1);
    if (next == _page) return;
    setState(() => _page = next);
    widget.onChanged(widget.attachment.copyWith(pdfPage: next));
  }

  void _toggleAutoPlay() {
    setState(() {
      if (_autoPlay != null) {
        _autoPlay!.cancel();
        _autoPlay = null;
        return;
      }
      _autoPlay = Timer.periodic(
        const Duration(seconds: 5),
        // Sonuncudan sonra başa döner: sunum gibi dönsün, sessizce durmasın.
        (_) => _goTo(autoPlayNext(_page, _count), save: false),
      );
    });
  }

  void _toggleMark() {
    final marks = togglePdfMark(widget.attachment.pdfMarks, _page);
    widget.onChanged(widget.attachment.copyWith(pdfMarks: marks));
  }

  void _rotate() {
    final turns = (widget.attachment.pdfTurns + 1) % 4;
    widget.onChanged(widget.attachment.copyWith(pdfTurns: turns));
  }

  /// Belgenin ölçüsü ekte yoksa İLK açılışta yazılır: kutunun en-boyu
  /// (bkz. `NotePageCanvas`) buradan geliyor, yoksa PDF kare kutuya ezilir.
  void _reportSize(PdfDocument document) {
    final a = widget.attachment;
    if (a.width != null && a.height != null) return;
    if (document.pages.isEmpty) return;
    final page = document.pages.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged(
        a.copyWith(width: page.width.round(), height: page.height.round()),
      );
    });
  }

  Future<void> _openFullScreen() async {
    final page = _page;
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => PdfViewerScreen(
          attachment: widget.attachment,
          initialPage: page,
          // Tam ekranda çevrilen sayfa kutuya geri döner: kullanıcı belgeyi
          // bıraktığı yerde bulur.
          onPageChanged: (p) {
            if (!mounted) return;
            _page = _clamp(p);
            widget.onChanged(widget.attachment.copyWith(pdfPage: _page));
          },
          onChanged: widget.onChanged,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
    _syncPagerSoon();
  }

  /// Bu sayfanın metin katmanını panoya alır. Taranmış sayfada metin yoktur;
  /// o zaman kullanıcıya söylenir (OCR yolu tam ekran görüntüleyicide).
  Future<void> _copyPageText() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final path = widget.attachment.localPath;
    if (path.isEmpty || !localFileExists(path)) {
      messenger.showMessage(l10n.attachmentNotSynced);
      return;
    }
    setState(() => _busy = true);
    try {
      final text = await PdfText.pageText(path, _page);
      if (!mounted) return;
      if (text.isEmpty) {
        messenger.showMessage(l10n.pdfSelectOcrNone);
        return;
      }
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      messenger.showMessage(l10n.pdfSelectCopied(text.length));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sayfayı görüntü olarak yakalar ve alan işlemleri levhasını açar
  /// (yapay zekâya sor / panoya kopyala) — alan seçimiyle AYNI levha.
  Future<void> _capturePage(PdfDocument document) async {
    if (_page < 1 || _page > document.pages.length) return;
    setState(() => _busy = true);
    Uint8List? png;
    try {
      final rendered = await PdfPageOcr.renderPageToPng(
        document.pages[_page - 1],
      );
      if (rendered != null) {
        final file = File(rendered.path);
        png = await file.readAsBytes();
        try {
          file.deleteSync();
        } catch (_) {
          // Geçici dosya silinemezse sorun değil; sistem temizler.
        }
      }
    } catch (_) {
      // Çizim başarısızsa levha hiç açılmaz (aşağıdaki null denetimi).
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (png == null) {
      ScaffoldMessenger.of(
        context,
      ).showMessage(context.l10n.areaCaptureFailed);
      return;
    }
    await showAreaActions(context, png);
  }

  /// Sayfaya atlama levhası: kaydırıcı, ilk/son sayfa, yer imleri ve bütün
  /// sayfaların küçük resimleri.
  Future<void> _openJumpSheet(PdfDocument document) async {
    final target = await showAppSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PdfJumpSheet(
        document: document,
        page: _page,
        marks: widget.attachment.pdfMarks,
      ),
    );
    if (target != null && mounted) _goTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final listenable = _doc;
    if (listenable == null) return _placeholder(context);
    return _document(context, listenable.document);
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: scheme.error),
            const SizedBox(height: 4),
            Text(
              context.l10n.attachmentNotSynced,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _document(BuildContext context, PdfDocument? document) {
    if (document == null) {
      return const ColoredBox(
        color: Color(0xFFF2F2F2),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_count != document.pages.length) {
      _count = document.pages.length;
      _page = _clamp(_page);
    }
    _reportSize(document);
    final a = widget.attachment;
    final pager = _pager ??= PageController(initialPage: _page - 1);
    final swipe = widget.controls && widget.swipeToTurn;
    final bubbles = widget.showBubbles && a.bubbles.isNotEmpty
        ? _bubbleController()
        : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Yatay kaydırma sayfa çevirir: kutunun küçük düğmelerine nişan
        // almadan da gezilebilsin. Dikey kaydırma NOTUN kendi kaydırması
        // olarak kalır (çevirici yalnız yatay sürüklemeyi alır); uzun basıp
        // kutuyu taşımak da bozulmaz (taşıma hareketsiz basılı tutmayla
        // başlar, çevirici ise ancak parmak yana kayınca devreye girer).
        ColoredBox(
          color: Colors.white,
          child: PageView.builder(
            controller: pager,
            physics: swipe
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            allowImplicitScrolling: true,
            itemCount: _count,
            onPageChanged: _onPagerChanged,
            itemBuilder: (context, i) => RotatedBox(
              quarterTurns: a.pdfTurns,
              // Kendi çizicimiz: pdfrx'in PdfPageView'ı aynı boydaki
              // sayfalarda görüntüyü yenilemiyordu (bkz. PdfPageImage).
              child: PdfPageImage(
                document: document,
                pageNumber: i + 1,
                overlay: bubbles == null
                    ? null
                    : BubblePageLayer(
                        controller: bubbles,
                        page: i + 1,
                        readOnly: true,
                        longPressAdd: false,
                      ),
              ),
            ),
          ),
        ),
        // El yazısı katmanı: PDF'in üzerine yapılan çizim kutuda da görünür
        // (tam ekranda çizip nota dönünce sayfa boş görünmesin).
        if (a.ink.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: InkPainter(a.ink, _page)),
            ),
          ),
        if (widget.controls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bar(context, document),
          ),
      ],
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
      color: Colors.black.withValues(alpha: 0.55),
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
                            fontWeight: FontWeight.w600,
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
    final l10n = context.l10n;
    final playing = _autoPlay != null;
    return SizedBox(
      width: big ? 32 : 26,
      height: big ? 32 : 26,
      child: PopupMenuButton<String>(
        tooltip: l10n.more,
        iconSize: big ? 20 : 16,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 200),
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (action) {
          switch (action) {
            case 'pages':
              _openJumpSheet(document);
            case 'mark':
              _toggleMark();
            case 'marks':
              _openMarks();
            case 'rotate':
              _rotate();
            case 'full':
              _openFullScreen();
            case 'text':
              _copyPageText();
            case 'capture':
              _capturePage(document);
            case 'play':
              _toggleAutoPlay();
            case 'detach':
              widget.onDetach?.call();
          }
        },
        itemBuilder: (context) => [
          _menuItem('pages', Icons.grid_view_outlined, l10n.pdfThumbnails),
          _menuItem(
            'mark',
            widget.attachment.pdfMarks.contains(_page)
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_add_outlined,
            widget.attachment.pdfMarks.contains(_page)
                ? l10n.pdfBookmarkRemove
                : l10n.pdfBookmarkAdd,
          ),
          _menuItem('marks', Icons.bookmarks_outlined, l10n.pdfBookmarks),
          _menuItem('rotate', Icons.rotate_90_degrees_ccw, l10n.pdfRotateView),
          _menuItem(
            'play',
            playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
            playing ? l10n.pdfSlideshowStop : l10n.pdfSlideshow,
          ),
          _menuItem('text', Icons.text_snippet_outlined, l10n.pdfCopyPageText),
          _menuItem('capture', Icons.auto_awesome, l10n.pdfCapturePage),
          _menuItem('full', Icons.fullscreen, l10n.pdfFullScreen),
          if (widget.onDetach != null)
            _menuItem(
              'detach',
              Icons.attachment_outlined,
              l10n.moveImageToAttachments,
            ),
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
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
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
                            Text('$number', style: const TextStyle(fontSize: 11)),
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
