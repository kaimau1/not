import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/page_notes.dart';
import 'pdf_notes_overview.dart';
import 'text_wrap.dart';

/// Üst bölmeyi kuran kapanış.
///
/// Sayfa durumu PANODA tutulur, görüntüleyicide değil: alt bölmenin hangi
/// sayfanın notunu göstereceği tek bir yerden belirlenir ve PDF ile slayt
/// sürümleri aynı davranışı paylaşır.
typedef PageViewerBuilder =
    Widget Function(BuildContext context, PageNoteHost host);

/// Sayfa çubuğuna görüntüleyiciye özgü düğmeler koyan kapanış (balonlu
/// panolarda "Balon" ve balon listesi). [goToPage] panonun sayfasını
/// değiştirir — görüntüleyici oraya kendisi kayar; [compact] dar ekranda
/// yazıların düşmesi içindir.
typedef PageBarActionsBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<int> goToPage,
      bool compact,
    );

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
    this.onEditPages,
    this.textStyle,
    this.richTheme,
    this.onFieldFocused,
    this.onFieldDisposed,
    this.suppressNotes,
    this.barActions,
  });

  /// Sayfa çubuğunun sağındaki görüntüleyiciye özgü düğmeler (bkz.
  /// [PageBarActionsBuilder]). null = yok.
  final PageBarActionsBuilder? barActions;

  /// true olduğunda alt not alanı GEÇİCİ olarak gizlenir — kullanıcı bir
  /// balonun içine yazarken. Kök neden (2026-08-08 bulgusu: "balona not
  /// yazarken klavye, sayfa hepsi kayıyor"): klavye açılınca ekranın altı
  /// yarıya iner, iki bölme + klavye aynı anda sığmaz ve balon kartı bölmenin
  /// dışında kalır. Balon yazarken belge tam alanı kullanır.
  final ValueListenable<bool>? suppressNotes;

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

  /// Sayfa yöneticisini açar (yalnız PDF'te var; sunumda sayfa düzenleme yok).
  /// Sayfa sayısı panonun bildiği tek yer olduğu için parametre olarak geçer.
  final Future<void> Function(int pageCount)? onEditPages;

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

/// [PageNotePane.suppressNotes] verilmediğinde kullanılan sabit "hiç
/// bastırma" kaynağı — builder'ın null denetimiyle dolmaması için.
final ValueNotifier<bool> _neverSuppressed = ValueNotifier<bool>(false);

class _PageNotePaneState extends State<PageNotePane> {
  /// Sayfa notu alanı, gövde/madde alanlarıyla AYNI denetleyiciyi kullanır:
  /// satır içi biçimlendirme (kalın, renk, boyut) burada da çalışsın diye.
  /// Sarma çapası yok — bölmede yüzen görsel olmaz.
  final _controller = WrapTextController();
  final _focus = FocusNode();

  /// Görünen sayfa (1 tabanlı) ve belgenin sayfa sayısı (0 = henüz açılmadı).
  int _page = 1;
  int _pageCount = 0;

  /// Alt NOT alanı açık mı? **Varsayılan KAPALI** (kullanıcı kararı
  /// 2026-08-08: "alttaki not sayfası alanı gizli başlasın ve göster gizlesi
  /// olsun"). Artık asıl çalışma aracı sayfanın üzerindeki balonlar; sayfa
  /// notu alanı ekranın yarısını kaplamak yerine istendiğinde açılıyor.
  /// Ekranda tutulur, kayda yazılmaz — o anki okuma tercihidir.
  bool _notesOpen = false;

  /// Üst bölmenin yükseklik payı (0–1). Ekranda tutulur, kayda YAZILMAZ —
  /// notun içeriği değil, o anki okuma tercihidir.
  double _split = 0.55;
  static const _minSplit = 0.2;
  static const _maxSplit = 0.85;

  /// **KLAVYE AÇILINCA BELGE KÜÇÜLMEZ** (kullanıcı bulgusu 2026-10-20:
  /// "balonlu kipte klavye açılınca görsel boyut değiştiriyor, odak
  /// kayıyor"). KÖK NEDEN: iki bölme esnek paylarla (flex) dizilmişti; gövde
  /// klavye oturunca tek seferde kısalıyor, belge de payıyla birlikte
  /// küçülüp yeniden ölçekleniyordu — sayfa bir karede zıplıyordu. Artık
  /// belge klavyesiz boyunda yerleşir ve yeniden ölçülmez; yer gerekiyorsa
  /// yalnız görünür penceresi klavyeyle birlikte yumuşakça daralır (bkz.
  /// [KeyboardClipWindow]).
  KeyboardPhase _keyboard = (open: false, estimate: 0);

  /// Klavye evresi değişti: pencere bu süre boyunca kayarak daralır/açılır.
  /// Not alanını açıp kapamak ya da ayracı sürüklemek ANINDA uygulanır.
  bool _windowAnimating = false;

  /// Klavyesiz yükseklik (bkz. pinned_media_pane `_stable`).
  double _stableWidth = -1;
  double _stableHeight = 0;

  /// Sayfa çubuğunun ölçülen yüksekliği (düğme yoğunluğu, yazı ölçeği).
  final _barKey = GlobalKey();
  double _barHeight = 56;
  static const _handleHeight = 12.0;

  /// Klavye açıkken sayfa notuna kalan en az yer.
  static const _noteMinHeight = 96.0;

  double _stable(BoxConstraints c) {
    if (c.maxWidth != _stableWidth) {
      _stableWidth = c.maxWidth;
      _stableHeight = 0;
    }
    if (!_keyboard.open || c.maxHeight > _stableHeight) {
      _stableHeight = c.maxHeight;
    }
    return _stableHeight;
  }

  void _measureBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final h = _barKey.currentContext?.size?.height;
      if (h != null && (h - _barHeight).abs() > 0.5) {
        setState(() => _barHeight = h);
      }
    });
  }

  void _onKeyboard(KeyboardPhase phase) {
    if (!mounted) return;
    setState(() {
      _keyboard = phase;
      _windowAnimating = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _windowAnimating = false;
    });
  }

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
    // Bekleyen biçim koşusu burada da kapatılır: geri tuşuyla çıkışta
    // `FocusNode.dispose`ın odak kaybı dinleyicisini tetikleyeceğine
    // GÜVENİLEMEZ (sıra Flutter'da garanti değil) ve "kalın" yazılan satır düz
    // kaydedilirdi.
    if (_controller.hasPendingFormat) {
      _controller.flushPendingFormat();
      _commit();
    }
    widget.onFieldDisposed?.call(_controller);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Alandaki metni notun O ANKİ sayfasına yazar.
  ///
  /// BOŞ metin, o sayfanın kaydı HİÇ YOKSA yazılmaz: sayfa düğmeleriyle
  /// gezinen kullanıcı yoksa her sayfa için boş bir anahtar oluşur ve doküman
  /// boş yere şişerdi. (Var olan bir notu silmek başka: o BOŞ DİZGİ olarak
  /// yazılmalı — bkz. `Note.pageNotes` merge tuzağı.)
  void _commit() {
    final text = _controller.logicalText;
    if (text.isEmpty) {
      final note = widget.noteOf();
      if (!note.pageNotes.containsKey(pageNoteKey(widget.attachment, _page))) {
        return;
      }
    }
    widget.onPageNoteChanged(_page, text);
  }

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
    // Belge küçüldüyse (sayfa silinmiş ya da kullanıcı sayım gelmeden ileri
    // sarmış) görünen sayfa dışarıda kalmasın.
    //
    // KÖK NEDEN (veri kaybı): sayfa kısılırken alan TAZELENMEZSE, ekranda
    // eski sayfanın metni durur ve bir sonraki tuş vuruşu onu YENİ sayfanın
    // üstüne yazar. Bu yüzden önce yazılmakta olan sayfa kesinleşir, sonra
    // numara değişir, sonra alan yeniden doldurulur — `_setPage`'in aynısı.
    final clamped = (count > 0 && _page > count) ? count : _page;
    if (clamped != _page) {
      if (_controller.hasPendingFormat) _controller.flushPendingFormat();
      _commit();
    }
    setState(() {
      _pageCount = count;
      _page = clamped;
    });
    if (clamped != _page || true) {
      _controller.text = widget.noteOf().pageNote(widget.attachment, clamped);
    }
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
    // KÖK NEDEN (veri kaybı): alan ÖNCE tazelenir, sayfa SONRA değişir.
    // Ters sırada `_setPage` panonun elindeki BAYAT metni (toplu görünümde
    // düzeltilmeden önceki hâli) eski sayfaya geri yazıyor ve kullanıcının az
    // önce yaptığı düzeltme sessizce siliniyordu.
    _controller.text = widget.noteOf().pageNote(widget.attachment, _page);
    if (page != null && page != _page) _goTo(page);
  }

  /// Sayfa yöneticisi. Belge değişeceği için alandaki son hâl önce
  /// kesinleşir; dönüşte pano kendi sayfasını sınırlar içine çeker (sayfa
  /// silinmiş olabilir).
  Future<void> _openPageEditor(int pageCount) async {
    final open = widget.onEditPages;
    if (open == null) return;
    if (_controller.hasPendingFormat) _controller.flushPendingFormat();
    _commit();
    await open(pageCount);
    if (!mounted) return;
    setState(() {
      if (_pageCount > 0 && _page > _pageCount) _page = _pageCount;
    });
    _controller.text = widget.noteOf().pageNote(widget.attachment, _page);
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
    // Balon yazılırken not alanı zorla kapanır; kullanıcının açtığı alan
    // kaybolmasın diye kip bitince eski hâline döner (bkz. suppressNotes).
    return KeyboardPhaseListener(
      onChanged: _onKeyboard,
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.suppressNotes ?? _neverSuppressed,
        builder: (context, suppressed, _) {
          final notesOpen = _notesOpen && !suppressed;
          return LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final stable = _stable(constraints);
              if (!suppressed) _measureBar();
              final fixed =
                  (notesOpen ? _handleHeight : 0.0) +
                  (suppressed ? 0.0 : _barHeight);
              // Belgenin YERLEŞİM boyu klavyesiz yükseklikten; görünen
              // penceresi klavye açıkken notun satırına yer bırakacak kadar.
              final share = notesOpen ? _split : 1.0;
              final full = math.max(0.0, (stable - fixed) * share);
              var visible = full;
              if (_keyboard.open) {
                final settled = stable - height > 40;
                final room = settled ? height : height - _keyboard.estimate;
                final fit = notesOpen
                    ? room - fixed - _noteMinHeight
                    : room - fixed;
                visible = math.min(full, math.max(56.0, fit));
              }
              // Gerçek yere sığmayan pencere olmasın (ölçüm kayması).
              visible = math.min(visible, math.max(0.0, height - fixed));
              return Column(
                children: [
                  KeyboardClipWindow(
                    full: full,
                    visible: visible,
                    animate: _windowAnimating,
                    child: widget.viewerBuilder(context, host),
                  ),
                  if (notesOpen)
                    _SplitHandle(
                      onDrag: (dy) {
                        final base = stable - fixed;
                        if (base <= 0) return;
                        setState(
                          () => _split = (_split + dy / base).clamp(
                            _minSplit,
                            _maxSplit,
                          ),
                        );
                      },
                    ),
                  // Balona yazılırken sayfa çubuğu da gizlenir: klavye
                  // ekranın yarısını alıyor, "Sayfa 1 / 4" satırı o anda
                  // hiçbir işe yaramıyor (kullanıcı isteği 2026-08-08).
                  if (!suppressed)
                    KeyedSubtree(
                      key: _barKey,
                      child: _pageBar(context, l10n, notesOpen),
                    ),
                  if (notesOpen)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          style: widget.textStyle,
                          onChanged: (_) => _commit(),
                          // Bölmenin tamamını kaplar: alt bölme SABİT bir
                          // yazı alanı, içeriğe göre büyüyüp küçülen bir
                          // satır değil.
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          // Kes/Kopyala TEMİZ metin verir: gövde, başlık ve
                          // madde alanlarıyla aynı kural. Bu alanda eksikti
                          // — panoya `**kalın**` işaretleri ham gidiyordu.
                          contextMenuBuilder: (menuContext, state) =>
                              AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: state.contextMenuAnchors,
                                buttonItems: cleanClipboardMenuItems(state),
                              ),
                          decoration: InputDecoration(
                            hintText: l10n.pdfPageNoteHint,
                            filled: false,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    )
                  else
                    // Ölçüm yuvarlamasını yutar: belge dibe kadar uzansın.
                    const Expanded(child: SizedBox.shrink()),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Alt not alanını açıp kapatır. Kapatırken alandaki son hâl kesinleşir ve
  /// klavye düşer: gizlenen bir alanın odakta kalması klavyeyi ayakta tutar.
  void _toggleNotes() {
    if (_notesOpen) {
      if (_controller.hasPendingFormat) _controller.flushPendingFormat();
      _commit();
      _focus.unfocus();
    }
    setState(() => _notesOpen = !_notesOpen);
  }

  /// Belgenin altındaki çubuk: solda sayfa gezinme HAPI, sağda balon
  /// düğmeleri ve sayfa notu işleri.
  ///
  /// **2026-10-15 yenilemesi** (kullanıcı isteği: "balonlu mod genel hatlar
  /// tamamen yenilenmeli"): eskiden yedi eşit simgelik düz bir satırdı ve
  /// balon bırakma/listeleme belgenin SAĞ ÜST köşesine binen iki küçük
  /// yuvarlak simgedeydi. Şimdi en çok kullanılan iş (balon) yazılı ve
  /// belirgin; dar telefonda seyrek işler (sayfa notu, toplu görünüm, sayfa
  /// düzenleme, tam ekran) tek bir "⋮" menüsünde. Geniş ekranda hepsi
  /// görünür kalır.
  Widget _pageBar(BuildContext context, AppLocalizations l10n, bool notesOpen) {
    final scheme = Theme.of(context).colorScheme;
    final label = _pageCount > 0
        ? l10n.pdfPageOf(_page, _pageCount)
        : l10n.pdfPage(_page);
    final actions = widget.barActions;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
            width: 0.7,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final compact = constraints.maxWidth < 340;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.75,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.pdfPreviousPage,
                          visualDensity: VisualDensity.compact,
                          onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
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
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actions != null) ...[
                      const SizedBox(width: 6),
                      actions(context, _goTo, compact),
                    ],
                    if (wide) ..._wideActions(l10n, notesOpen) else
                      _moreMenu(l10n, notesOpen),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Geniş ekranda (tablet, masaüstü) seyrek işler de simge olarak görünür.
  List<Widget> _wideActions(AppLocalizations l10n, bool notesOpen) => [
    IconButton(
      tooltip: notesOpen ? l10n.pageNotesHide : l10n.pageNotesShow,
      visualDensity: VisualDensity.compact,
      isSelected: notesOpen,
      onPressed: _toggleNotes,
      icon: Icon(notesOpen ? Icons.edit_note : Icons.edit_note_outlined),
    ),
    IconButton(
      tooltip: l10n.pdfAllPageNotes,
      visualDensity: VisualDensity.compact,
      onPressed: _openOverview,
      icon: const Icon(Icons.subject),
    ),
    if (widget.onEditPages != null)
      IconButton(
        tooltip: l10n.pdfEditPages,
        visualDensity: VisualDensity.compact,
        // Sayfa sayısı bilinmeden düzenleme açılmaz: yönetici sayfa
        // ızgarasını ona göre kuruyor.
        onPressed: _pageCount > 0 ? () => _openPageEditor(_pageCount) : null,
        icon: const Icon(Icons.auto_awesome_motion_outlined),
      ),
    if (widget.onFullScreen != null)
      IconButton(
        tooltip: l10n.pdfFullScreen,
        visualDensity: VisualDensity.compact,
        onPressed: _openFullScreen,
        icon: const Icon(Icons.open_in_full),
      ),
  ];

  /// Dar ekranda seyrek işler tek menüde (simgeleri geniş ekrandakilerle
  /// aynı — kullanıcı ikisinde de aynı işareti arar).
  Widget _moreMenu(AppLocalizations l10n, bool notesOpen) {
    PopupMenuItem<VoidCallback> item(
      IconData icon,
      String label,
      VoidCallback action, {
      bool enabled = true,
    }) => PopupMenuItem<VoidCallback>(
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(label)),
        ],
      ),
    );
    return PopupMenuButton<VoidCallback>(
      key: const ValueKey('page-bar-more'),
      tooltip: l10n.pageBarMore,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        item(
          notesOpen ? Icons.edit_note : Icons.edit_note_outlined,
          notesOpen ? l10n.pageNotesHide : l10n.pageNotesShow,
          _toggleNotes,
        ),
        item(Icons.subject, l10n.pdfAllPageNotes, _openOverview),
        if (widget.onEditPages != null)
          item(
            Icons.auto_awesome_motion_outlined,
            l10n.pdfEditPages,
            () => _openPageEditor(_pageCount),
            enabled: _pageCount > 0,
          ),
        if (widget.onFullScreen != null)
          item(Icons.open_in_full, l10n.pdfFullScreen, _openFullScreen),
      ],
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
