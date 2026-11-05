part of 'items_editor.dart';

// F18.23: ItemsEditor'ın yardımcı widget'ları items_editor.dart'tan taşındı (davranış aynı).

/// Sayfadaki görsellerin bandına denk gelen liste satırını görselin yanına
/// kaydırır (soldaki görsel → sağa iter, sağdaki görsel → sola daraltır).
/// Konum yerleşimden SONRA ölçülür; dolgu satırın DIŞINDAN uygulandığı için
/// ölçüm kendi kendini beslemez (ölçülen kutu her zaman tam genişliktir).
///
/// Satırın METNİNE okunur bir genişlik kalmıyorsa yana kaydırma bırakılır ve
/// satır görselin ALTINA itilir — gövde metnindeki "satırı boşalt"
/// davranışının liste karşılığı.
class _FloatRow extends StatefulWidget {
  const _FloatRow({
    required this.floats,
    required this.pageBox,
    required this.child,
    this.reserved = 0,
    this.pushOnly = false,
    this.inlineBelow,
    this.initial,
    this.onMeasured,
  });

  /// Satırın tepesinden bu kadar (dp) AŞAĞIDA başlayan görsel satırı
  /// kaydırmaz — alanın kendi sarması işler (bkz. `_wrapped`). `null`:
  /// her görsel satırı kaydırır.
  final double? inlineBelow;

  /// true ise satır görselin YANINA hiç geçmez, bandına değdiği her görselin
  /// ALTINA iner. Küçülemeyen satırlar ("Yeni öğe", "İşaretlileri sil") böyle:
  /// yana kaydırma kararı metne kalan yere bakıyor, onlarınsa metni yok.
  final bool pushOnly;

  final List<FloatBox> floats;
  final RenderBox? Function() pageBox;

  /// Satırın metne AYRILAMAYAN payı (tutamaç + kutucuk + sil düğmesi +
  /// dolgu). Kalan yer ölçülürken düşülür.
  ///
  /// KÖK NEDEN (madde: "bir görsel yazıları sıkıştırdığında tek harf tek
  /// satıra kadar daralıyor"): eskiden "yer kaldı mı" kararı satırın TAMAMI
  /// üzerinden veriliyordu. Liste satırının ~140 dp'si sabit kontrollere
  /// gidiyor; görsel satırın üçte ikisini kaplayınca satırın kendisi eşiği
  /// geçiyor ama METNE bir-iki karakterlik yer kalıyordu — metin dikey bir
  /// harf sütununa dönüşüp satırı ekran boyu uzatıyordu.
  final double reserved;

  /// Ölçüm gelene kadarki başlangıç kaydırması (komşu satırın değeri).
  final ({double start, double end, double top})? initial;

  /// Ölçüm sonucu — çağıran, sonraki satırlara tahmin olarak verir.
  final ValueChanged<({double start, double end, double top})>? onMeasured;

  final Widget child;

  @override
  State<_FloatRow> createState() => _FloatRowState();
}

/// Bir madde satırının metnine bırakılacak en az genişlik (dp) — yaklaşık
/// 8-10 karakter. Bundan darına sıkışan metin harf harf kırılır.
const double _kMinRowTextWidth = 72;

class _FloatRowState extends State<_FloatRow> {
  late double _start = widget.initial?.start ?? 0;
  late double _end = widget.initial?.end ?? 0;
  late double _top = widget.initial?.top ?? 0;

  /// Bu kare için ölçüm zaten sıraya girdi mi. Satır bir karede birden çok
  /// kez kurulabiliyor (odak, seçim, tema); her kuruluşta ayrı bir kare-sonu
  /// geri çağrısı biriktirmenin anlamı yok — hepsi aynı sonucu ölçer.
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    // Bant yoksa ve dolgular zaten sıfırsa ölçülecek bir şey de yok: madde
    // listelerinin ezici çoğunluğu (görselsiz notlar) buradan bedelsiz geçer.
    final idle = widget.floats.isEmpty && _start == 0 && _end == 0 && _top == 0;
    if (!_scheduled && !idle) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    return Padding(
      // BİLEREK FİZİKSEL (Directional DEĞİL): bu boşluklar sayfaya konmuş
      // yüzen görsellerin ÖLÇÜLEN x koordinatlarından hesaplanıyor
      // (bkz. text_wrap.dart). Yönlü karşılığına çevrilirse RTL'de metin
      // görselin bulunmadığı tarafa kaçar — sarma tam ters yerde olur.
      padding: EdgeInsets.only(left: _start, right: _end, top: _top),
      child: widget.child,
    );
  }

  void _measure() {
    _scheduled = false;
    if (!mounted) return;
    // Son görsel silindi: dolguları sıfırla, ölçüme hiç girme.
    if (widget.floats.isEmpty) {
      if (_start != 0 || _end != 0 || _top != 0) {
        widget.onMeasured?.call((start: 0, end: 0, top: 0));
        setState(() {
          _start = 0;
          _end = 0;
          _top = 0;
        });
      }
      return;
    }
    final box = context.findRenderObject();
    final page = widget.pageBox();
    if (box is! RenderBox || !box.hasSize || page == null || !page.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: page);
    final width = box.size.width;
    // Kesişme HER ZAMAN satırın itilmemiş bandıyla ölçülür: kutu kendi üst
    // dolgusunu da içerdiğinden `box.size.height` kullanmak, itildikçe bandı
    // büyütür, büyüyen bant daha çok görsele değer ve satır sonsuza dek
    // aşağı kaçardı. `_top` çıkarılınca ölçüm itmeden bağımsız ve kararlı.
    final bottom = origin.dy + box.size.height - _top;
    // Satırın İÇİNDE başlayan görsel alanın işi (bkz. [_FloatRow.inlineBelow]).
    final inline = widget.pushOnly ? null : widget.inlineBelow;
    final floats = inline == null
        ? widget.floats
        : [
            for (final f in widget.floats)
              if (f.top < origin.dy + _top + inline) f,
          ];
    var start = 0.0;
    var end = 0.0;
    if (!widget.pushOnly) {
      for (final f in floats) {
        if (f.bottom <= origin.dy || f.top >= bottom) continue;
        final left = f.left - origin.dx;
        final right = f.right - origin.dx;
        if (right <= 0 || left >= width) continue;
        // Satır görselin GENİŞ tarafına geçer (metin sarmasıyla aynı kural).
        if (width - right >= left) {
          if (right > start) start = right;
        } else {
          final pad = width - left;
          if (pad > end) end = pad;
        }
      }
    }
    var top = 0.0;
    // Metne kalan yer: satırın sabit kontrolleri (tutamaç/kutucuk/sil) düşülür.
    // Eşik, gövde metnindeki kuralın (sütunun dörtte biri) metin payına
    // uygulanmış hâli; çok dar sütunlarda da okunur bir taban bırakılır.
    final textWidth = width - start - end - widget.reserved;
    final minTextWidth = math.max(
      _kMinRowTextWidth,
      (width - widget.reserved) * 0.25,
    );
    if (widget.pushOnly || textWidth < minTextWidth) {
      // Yana kaçacak yer yok. Gövde metninde bu durumda satır boşaltılır ve
      // metin görselin ALTINA iner (text_wrap.dart `_kMinUsableFraction`);
      // liste maddesinde karşılığı satırı aşağı itmektir. Eskiden satır pes
      // edip görselin altında kalıyordu.
      start = 0;
      end = 0;
      for (final f in floats) {
        if (f.bottom <= origin.dy || f.top >= bottom) continue;
        if (f.right - origin.dx <= 0 || f.left - origin.dx >= width) continue;
        final push = f.bottom - origin.dy;
        if (push > top) top = push;
      }
    }
    widget.onMeasured?.call((start: start, end: end, top: top));
    if ((start - _start).abs() > 0.5 ||
        (end - _end).abs() > 0.5 ||
        (top - _top).abs() > 0.5) {
      setState(() {
        _start = start;
        _end = end;
        _top = top;
      });
    }
  }
}

/// Satır menüsünün ([ItemsEditorState._showItemMenu]) seçenekleri.
enum _ItemAction {
  star,
  header,
  select,
  delete,
  moveToPage,
  alignStart,
  alignCenter,
  alignEnd,
}

/// Madde menüsünün tek parçalık gövdesi: iş düğmeleri (alt çizgi
/// 2026-10-30'dan beri biçim panelinde — bkz. [ItemsEditorState._showItemMenu]).
class _ItemMenuPanel extends PopupMenuEntry<_ItemAction> {
  const _ItemMenuPanel({
    required this.starred,
    required this.canMove,
    this.header = false,
    this.align = '',
  });

  final bool starred;

  /// Ara başlığın şimdiki hizası (bkz. [NoteItem.align]).
  final String align;
  final bool canMove;

  /// Satır ara başlık mı (düğme "Maddeye çevir" der).
  final bool header;

  @override
  double get height => header ? 132 : 84;

  @override
  bool represents(_ItemAction? value) => false;

  @override
  State<_ItemMenuPanel> createState() => _ItemMenuPanelState();
}

class _ItemMenuPanelState extends State<_ItemMenuPanel> {
  void _pick(_ItemAction action) => Navigator.pop(context, action);

  Widget _action(_ItemAction action, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final danger = action == _ItemAction.delete;
    final color = danger ? scheme.error : scheme.onSurface;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 248, maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _action(
                  _ItemAction.star,
                  widget.starred ? Icons.star : Icons.star_outline,
                  widget.starred ? l10n.itemMenuUnstar : l10n.star,
                ),
                _action(
                  _ItemAction.header,
                  widget.header ? Icons.format_list_bulleted : Icons.title,
                  widget.header ? l10n.itemMenuToItem : l10n.itemMenuToHeader,
                ),
                _action(_ItemAction.select, Icons.checklist, l10n.select),
                if (widget.canMove)
                  _action(
                    _ItemAction.moveToPage,
                    Icons.drive_file_move_outline,
                    l10n.itemMenuMove,
                  ),
                _action(
                  _ItemAction.delete,
                  Icons.delete_outline,
                  l10n.itemMenuDelete,
                ),
              ],
            ),
            // ARA BAŞLIK HİZASI (kullanıcı isteği 2026-11-05): basılı tutunca
            // sola · ortaya · sağa.
            if (widget.header)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: SegmentedButton<_ItemAction>(
                  key: const ValueKey('item-menu-align'),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  segments: [
                    ButtonSegment(
                      value: _ItemAction.alignStart,
                      icon: const Icon(Icons.format_align_left, size: 20),
                      tooltip: l10n.itemAlignStart,
                    ),
                    ButtonSegment(
                      value: _ItemAction.alignCenter,
                      icon: const Icon(Icons.format_align_center, size: 20),
                      tooltip: l10n.itemAlignCenter,
                    ),
                    ButtonSegment(
                      value: _ItemAction.alignEnd,
                      icon: const Icon(Icons.format_align_right, size: 20),
                      tooltip: l10n.itemAlignEnd,
                    ),
                  ],
                  selected: {
                    switch (widget.align) {
                      NoteItem.alignCenter => _ItemAction.alignCenter,
                      NoteItem.alignEnd => _ItemAction.alignEnd,
                      _ => _ItemAction.alignStart,
                    },
                  },
                  onSelectionChanged: (v) => _pick(v.first),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Madde altı ayırıcı çizgi (bkz. [NoteItem.divider], [ItemDivider]).
class _ItemDividerPainter extends CustomPainter {
  _ItemDividerPainter(this.raw, this.color)
    : style = ItemDivider.parse(raw) ?? const ItemDivider('');

  final String raw;
  final ItemDivider style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: style,
    fallbackColor: color,
    left: 8,
    right: size.width - 8,
    // Defterde satır çizgisiyle AYNI yere düşer: ince kalırsa kesik/nokta
    // altındaki düz çizgide kaybolup "düz çizgi" gibi görünüyordu.
    y: size.height - 1,
    baseWidth: 2.2,
  );

  @override
  bool shouldRepaint(_ItemDividerPainter old) =>
      old.raw != raw || old.color != color;
}

enum _MovePhase { idle, leaving, arriving }

/// İşaretlenen maddenin YER DEĞİŞTİRME geçişi.
///
/// İşaretli maddeler ayrı bir blokta (footer) durduğundan satır bir ağaçtan
/// ötekine taşınır ve arada hiçbir şey canlandırılamıyordu — madde bir anda
/// ışınlanıyordu. Geçiş iki yarıya bölündü:
/// * **leaving**: eski yerinde, işaret/çizgi animasyonuna bir süre izin
///   verildikten sonra satır dikeyde katlanır ve solar; altındakiler yukarı
///   kayar.
/// * **arriving**: yeni yerinde sıfır yükseklikten açılır, hafifçe yukarı
///   süzülerek belirir.
/// Katlanma bitince öğe gerçek yerine taşınır (bkz. `_toggleItem`), yani
/// iki yarı birbirini kesintisiz izler.
class _CheckMove extends StatefulWidget {
  const _CheckMove({required this.phase, required this.child});

  final _MovePhase phase;
  final Widget child;

  static const arriveDuration = Duration(milliseconds: 280);

  @override
  State<_CheckMove> createState() => _CheckMoveState();
}

class _CheckMoveState extends State<_CheckMove>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.phase == _MovePhase.arriving ? 0 : 1,
  );
  late Animation<double> _size = _controller;

  @override
  void initState() {
    super.initState();
    if (widget.phase == _MovePhase.arriving) _arrive();
  }

  @override
  void didUpdateWidget(_CheckMove old) {
    super.didUpdateWidget(old);
    if (old.phase == widget.phase) return;
    switch (widget.phase) {
      case _MovePhase.leaving:
        // İlk %40 satır yerinde durur: kutunun zıplaması ve çizginin akışı
        // görülsün, sonra katlanma başlasın.
        _size = CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
          reverseCurve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
        );
        // Katlanma [_settleDuration] içinde bitmeli ki öğe taşındığında
        // eski yerinde boşluk kalmasın.
        _controller.reverseDuration = ItemsEditorState._settleDuration;
        _controller.reverse(from: 1);
      case _MovePhase.arriving:
        _arrive();
      case _MovePhase.idle:
        _controller.value = 1;
    }
  }

  void _arrive() {
    _size = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.duration = _CheckMove.arriveDuration;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _size,
        child: widget.phase == _MovePhase.arriving
            ? SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(_size),
                child: widget.child,
              )
            : widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// İşaret kutusunun "zıplaması": değer DEĞİŞİNCE kutu kısa süre büyüyüp
/// yerine oturur. İlk kurulumda oynamaz.
class _CheckPop extends StatefulWidget {
  const _CheckPop({required this.value, required this.child});

  final bool value;
  final Widget child;

  @override
  State<_CheckPop> createState() => _CheckPopState();
}

class _CheckPopState extends State<_CheckPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.22,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.22,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(_CheckPop old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
