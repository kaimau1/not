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
    this.registry,
  });

  /// Liste geometrisi değişince satırları yeniden ölçtürmek için kayıt
  /// (bkz. `ItemsEditorState._remeasureRows`).
  final Set<_FloatRowState>? registry;

  /// Satırın tepesinden bu kadar (dp) AŞAĞIDA başlayan görsel satırı
  /// kaydırmaz — alanın kendi sarması işler (bkz. `_wrapped`). `null`:
  /// her görsel satırı kaydırır.
  final double? inlineBelow;

  /// true ise satır görselin YANINA hiç geçmez, bandına değdiği her görselin
  /// ALTINA iner. Küçülemeyen satırlar ("Yeni öğe", "İşaretlileri sil") böyle:
  /// yana kaydırma kararı metne kalan yere bakıyor, onlarınsa metni yok.
  final bool pushOnly;

  /// Bantların canlı kaynağı: değişince satır KURULMAZ, yalnız yeniden
  /// ölçülür (ölçüm dolguyu değiştirirse bu katman kendini çizer).
  final ValueListenable<List<FloatBox>> floats;
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

/// **AYNI KAREDEKİ KAYMALAR** (kullanıcı bulgusu 2026-11-23: "satır eklerken
/// maddeler yukarı çıkarken titreme"). KÖK NEDEN: satırlar aynı kare sonunda
/// sırayla ölçülüyor; üstteki satır kendini aşağı ittiğinde alttaki henüz
/// ESKİ yerinden ölçüyor, o da bandın içinde sanıp kendini itiyordu — bir
/// sonraki karede fazla itme geri alınıyor, maddeler aşağı-yukarı
/// sekiyordu. Kare içinde verilen her dikey kayma burada birikir; alttaki
/// satır kendi yerine onu ekleyerek ölçer.
abstract final class _FrameShifts {
  static Duration? _frame;
  static final List<(double, double)> _shifts = [];

  static void _sync() {
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_frame != now) {
      _frame = now;
      _shifts.clear();
    }
  }

  /// [y]'nin üstünde bu karede verilmiş kaymaların toplamı.
  static double above(double y) {
    _sync();
    var sum = 0.0;
    for (final (at, d) in _shifts) {
      if (at < y) sum += d;
    }
    return sum;
  }

  static void add(double y, double delta) {
    _sync();
    if (delta.abs() > 0.5) _shifts.add((y, delta));
  }
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
  void initState() {
    super.initState();
    widget.floats.addListener(_schedule);
    widget.registry?.add(this);
  }

  @override
  void didUpdateWidget(_FloatRow old) {
    super.didUpdateWidget(old);
    if (old.registry != widget.registry) {
      old.registry?.remove(this);
      widget.registry?.add(this);
    }
    if (old.floats != widget.floats) {
      old.floats.removeListener(_schedule);
      widget.floats.addListener(_schedule);
    }
  }

  @override
  void dispose() {
    widget.floats.removeListener(_schedule);
    widget.registry?.remove(this);
    super.dispose();
  }

  void _schedule() {
    final idle =
        widget.floats.value.isEmpty && _start == 0 && _end == 0 && _top == 0;
    if (_scheduled || idle) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    // Bant değişti ama hiçbir şey kurulmuyorsa kare de gelmeyebilir.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    // Bant yoksa ve dolgular zaten sıfırsa ölçülecek bir şey de yok: madde
    // listelerinin ezici çoğunluğu (görselsiz notlar) buradan bedelsiz geçer.
    _schedule();
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
    final all = widget.floats.value;
    // Son görsel silindi: dolguları sıfırla, ölçüme hiç girme.
    if (all.isEmpty) {
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
    final measured = box.localToGlobal(Offset.zero, ancestor: page);
    // Üstteki satırların bu karede verdiği (henüz çizilmemiş) kaymalar.
    final origin = measured.translate(0, _FrameShifts.above(measured.dy));
    final width = box.size.width;
    // Kesişme HER ZAMAN satırın itilmemiş bandıyla ölçülür: kutu kendi üst
    // dolgusunu da içerdiğinden `box.size.height` kullanmak, itildikçe bandı
    // büyütür, büyüyen bant daha çok görsele değer ve satır sonsuza dek
    // aşağı kaçardı. `_top` çıkarılınca ölçüm itmeden bağımsız ve kararlı.
    final bottom = origin.dy + box.size.height - _top;
    // Satırın İÇİNDE başlayan görsel alanın işi (bkz. [_FloatRow.inlineBelow]).
    final inline = widget.pushOnly ? null : widget.inlineBelow;
    final floats = inline == null
        ? all
        : [
            for (final f in all)
              // BLOK kutu satırın içinde başlasa da satırı bütünüyle iter
              // (madde bölünmez; alan planı onu almaz — `WrapFieldMeasure`).
              if (f.block || f.top < origin.dy + _top + inline) f,
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
    final blocked = floats.any(
      (f) =>
          f.block &&
          f.bottom > origin.dy &&
          f.top < bottom &&
          f.right - origin.dx > 0 &&
          f.left - origin.dx < width,
    );
    if (widget.pushOnly || blocked || textWidth < minTextWidth) {
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
    _FrameShifts.add(measured.dy, top - _top);
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
  copyItem,
  moveUp,
  moveDown,
  header,
  select,
  delete,
  moveToPage,
  task,
  reminder,
  alignStart,
  alignCenter,
  alignEnd,
}

/// Madde menüsünün Bento ızgara paneli (alt çizgi biçim panelinde).
class _ItemMenuPanel extends PopupMenuEntry<_ItemAction> {
  const _ItemMenuPanel({
    required this.starred,
    required this.canMove,
    this.canMoveUp = true,
    this.canMoveDown = true,
    this.canTask = false,
    this.canRemind = false,
    this.header = false,
    this.align = '',
  });

  final bool starred;
  final bool canMoveUp;
  final bool canMoveDown;

  /// Ara başlığın şimdiki hizası (bkz. [NoteItem.align]).
  final String align;
  final bool canMove;

  /// "Görev yap" (TAKVIM F50.3).
  final bool canTask;

  /// "Hatırlat" (satıra hatırlatıcı).
  final bool canRemind;

  /// Satır ara başlık mı (düğme "Maddeye çevir" der).
  final bool header;

  @override
  double get height => header ? 196 : 148;

  @override
  bool represents(_ItemAction? value) => false;

  @override
  State<_ItemMenuPanel> createState() => _ItemMenuPanelState();
}

class _ItemMenuPanelState extends State<_ItemMenuPanel> {
  void _pick(_ItemAction action) => Navigator.pop(context, action);

  Widget _tile(
    _ItemAction action,
    IconData icon,
    String label, {
    bool active = false,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final danger = action == _ItemAction.delete;
    final fg = !enabled
        ? scheme.onSurface.withValues(alpha: AppAlpha.disabled)
        : danger
        ? scheme.error
        : active
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final bg = danger
        ? scheme.errorContainer.withValues(alpha: AppAlpha.soft)
        : active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: AppAlpha.muted);

    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.m),
          onTap: enabled ? () => _pick(action) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xs,
              vertical: AppSpace.s,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppIconSize.m, color: fg),
                const SizedBox(height: AppSpace.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.meta.copyWith(
                    color: fg,
                    fontWeight: AppWeight.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row2 = <Widget>[
      _tile(
        _ItemAction.moveUp,
        Icons.arrow_upward_rounded,
        l10n.itemMoveUp,
        enabled: widget.canMoveUp,
      ),
      _tile(
        _ItemAction.moveDown,
        Icons.arrow_downward_rounded,
        l10n.itemMoveDown,
        enabled: widget.canMoveDown,
      ),
      if (widget.canRemind)
        _tile(
          _ItemAction.reminder,
          Icons.alarm_add_outlined,
          l10n.itemMenuRemind,
        ),
      if (widget.canTask)
        _tile(
          _ItemAction.task,
          Icons.add_task_rounded,
          l10n.itemMenuTask,
        ),
      if (widget.canMove)
        _tile(
          _ItemAction.moveToPage,
          AppIcons.moveToFolder,
          l10n.itemMenuMove,
        ),
      _tile(
        _ItemAction.delete,
        Icons.delete_outline_rounded,
        l10n.itemMenuDelete,
      ),
    ];

    List<Widget> spaced(List<Widget> items) => [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpace.xs + AppSpace.xxs),
        items[i],
      ],
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 272, maxWidth: 376),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: spaced([
                _tile(
                  _ItemAction.select,
                  Icons.checklist_rounded,
                  l10n.select,
                ),
                _tile(
                  _ItemAction.copyItem,
                  AppIcons.copy,
                  l10n.copy,
                ),
                _tile(
                  _ItemAction.star,
                  widget.starred ? Icons.star_rounded : Icons.star_outline_rounded,
                  widget.starred ? l10n.itemMenuUnstar : l10n.star,
                  active: widget.starred,
                ),
                _tile(
                  _ItemAction.header,
                  widget.header
                      ? Icons.format_list_bulleted_rounded
                      : Icons.title_rounded,
                  widget.header ? l10n.itemMenuToItem : l10n.itemMenuToHeader,
                  active: widget.header,
                ),
              ]),
            ),
            const SizedBox(height: AppSpace.xs + AppSpace.xxs),
            Row(children: spaced(row2)),
            // ARA BAŞLIK HİZASI (kullanıcı isteği 2026-11-05): basılı tutunca
            // sola · ortaya · sağa.
            if (widget.header)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s),
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
                      icon: const Icon(
                        Icons.format_align_left,
                        size: AppIconSize.m,
                      ),
                      tooltip: l10n.itemAlignStart,
                    ),
                    ButtonSegment(
                      value: _ItemAction.alignCenter,
                      icon: const Icon(
                        Icons.format_align_center,
                        size: AppIconSize.m,
                      ),
                      tooltip: l10n.itemAlignCenter,
                    ),
                    ButtonSegment(
                      value: _ItemAction.alignEnd,
                      icon: const Icon(
                        Icons.format_align_right,
                        size: AppIconSize.m,
                      ),
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
  _ItemDividerPainter(
    this.raw,
    this.color, {
    this.reveal,
    this.curve,
    this.rtl = false,
  }) : style = ItemDivider.parse(raw) ?? const ItemDivider(''),
       super(repaint: reveal);

  final String raw;
  final ItemDivider style;
  final Color color;

  /// Beliriş ilerlemesi ([_DividerReveal]); null = tam çizgi. Denetleyiciyi
  /// `repaint:` ile dinler — satır KURULMAZ, yalnız bu katman boyanır.
  final Animation<double>? reveal;
  final Curve? curve;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final r = reveal;
    final t = r == null ? 1.0 : (curve?.transform(r.value) ?? r.value);
    if (t <= 0) return;
    final clip = t < 1;
    if (clip) {
      // Kırpma (katman/opaklık YOK — satırı katmanla sarmak kasma kök
      // nedeniydi, items_editor_row.dart); sağdan-sola dilde sağdan başlar.
      canvas
        ..save()
        ..clipRect(
          rtl
              ? Rect.fromLTRB(size.width * (1 - t), 0, size.width, size.height)
              : Rect.fromLTRB(0, 0, size.width * t, size.height),
        );
    }
    paintItemDivider(
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
    if (clip) canvas.restore();
  }

  @override
  bool shouldRepaint(_ItemDividerPainter old) =>
      old.raw != raw ||
      old.color != color ||
      old.reveal != reveal ||
      old.rtl != rtl;
}

/// **ÇİZGİNİN BELİRİŞİ** (P63 PB6, plan_tasarim_B §5.2): çizgisiz maddeye
/// çizgi eklenince çizgi soldan sağa çizilir — YALNIZ BOYAMA.
///
/// KOŞULSUZ sarmalayıcı: çizgisiz satırda da aynı ağaç (painter null), ağaç
/// şekli koşula bağlı değişmez. Tetik YALNIZ boş → dolu geçişinde
/// ([didUpdateWidget]); not açılışı, kaydırmayla gelen satır ve "Tüm
/// çizgilere" oynatmaz; tür/renk/kalınlık değişimi ve kaldırma tek karede.
/// Denetleyici tembel (ilk tetikte); hareketi azalt → doğrudan tam çizgi.
/// Satır önbelleği anahtarına beliriş durumu GİRMEZ (durum burada).
class _DividerReveal extends StatefulWidget {
  const _DividerReveal({
    required this.raw,
    required this.color,
    required this.child,
  });

  final String raw;
  final Color color;
  final Widget child;

  @override
  State<_DividerReveal> createState() => _DividerRevealState();
}

class _DividerRevealState extends State<_DividerReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didUpdateWidget(_DividerReveal old) {
    super.didUpdateWidget(old);
    if (old.raw.isEmpty && widget.raw.isNotEmpty && motionOf(context)) {
      final c = _controller ??= AnimationController(vsync: this);
      c
        ..duration = AppMotion.of(context, AppMotion.short)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: widget.raw.isEmpty
        ? null
        : _ItemDividerPainter(
            widget.raw,
            widget.color,
            reveal: _controller,
            curve: AppMotion.curveOf(context, AppMotion.enter),
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
    child: widget.child,
  );
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

/// **BASILI TUTMAYA DEVAM → MADDE SEÇİMİ (F60.S6, kullanıcı isteği
/// 2026-11-11).** Maddeye uzun basış (≈500 ms) metin alanının kendi jestiyle
/// yazıyı seçer; parmak kalkmadan ve kaymadan [_kHoldSelectDelay] dolarsa
/// [_HoldToSelect.onHold] çağrılır (madde seçim kipine geçiş).
///
/// Ham [Listener]: jest arenasına KATILMAZ, metin alanının uzun basışını ve
/// seçim tutamacı sürüklemesini yarıştırıp bozmaz. Yalnız dokunmatik parmak —
/// kalem ve fare kendi seçim davranışında kalır. Zamanlayıcı bu küçük öğenin
/// durumunda: editörün kök `setState`'ine dokunmaz (kasma listesi 3), ağaç
/// şekli sabit (4).
///
/// **İKİ AŞAMA GÖRÜNÜR (F60.S11, 2026-11-12).** Basılan yerde halka dolar:
/// 1. tur [_kHoldTextStage]'de biter → [_HoldToSelect.onText] (hafif titreşim
/// + maddenin tüm yazısı seçili); 2. tur [_kHoldSelectDelay]'de → `onHold`.
/// Halka yalnız BOYAMADA (AnimationController → CustomPaint repaint,
/// RepaintBoundary): editör de bu öğe de yeniden kurulmaz (kasma listesi 3/6).
/// 1. aşama metin alanının kendi uzun basışından (500 ms) ve tembel alanın
/// iki kare sonraki sözcük seçiminden SONRA gelsin diye 650 ms.
const _kHoldTextStage = Duration(milliseconds: 650);
const _kHoldSelectDelay = Duration(milliseconds: 1250);

/// Kısa dokunuşta halka yanıp sönmesin: bu kadar basılı kalmadan çizilmez.
const _kHoldRingShow = Duration(milliseconds: 150);

class _HoldToSelect extends StatefulWidget {
  const _HoldToSelect({
    required this.enabled,
    required this.onText,
    required this.onHold,
    required this.child,
  });

  /// Madde seçim kipinde kapalı (dokunuş zaten maddeyi seçiyor).
  final bool enabled;
  final VoidCallback onText;
  final VoidCallback onHold;
  final Widget child;

  @override
  State<_HoldToSelect> createState() => _HoldToSelectState();
}

class _HoldToSelectState extends State<_HoldToSelect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: _kHoldSelectDelay,
  );
  Timer? _textTimer;
  Timer? _timer;
  int? _pointer;
  Offset _origin = Offset.zero;

  /// Halkanın merkezi (yerel); boyayıcı okur, yeniden kurulum yok.
  Offset _center = Offset.zero;

  void _cancel() {
    _textTimer?.cancel();
    _textTimer = null;
    _timer?.cancel();
    _timer = null;
    _pointer = null;
    _ring.reset();
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null) {
      // İkinci parmak (yakınlaştırma vb.): basılı tutma sayılmaz.
      _cancel();
      return;
    }
    if (!widget.enabled || e.kind != PointerDeviceKind.touch) return;
    _pointer = e.pointer;
    _origin = e.position;
    _center = e.localPosition;
    _ring.forward(from: 0);
    _textTimer = Timer(_kHoldTextStage, () {
      _textTimer = null;
      if (mounted) widget.onText();
    });
    _timer = Timer(_kHoldSelectDelay, () {
      _cancel();
      if (mounted) widget.onHold();
    });
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    if ((e.position - _origin).distance > kTouchSlop) _cancel();
  }

  void _end(PointerEvent e) {
    if (e.pointer == _pointer) _cancel();
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _timer?.cancel();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _end,
    onPointerCancel: _end,
    // Ağaç şekli sabit: halka hep kurulu, boştayken hiçbir şey çizmez.
    child: Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('item-hold-ring'),
                painter: _HoldRingPainter(
                  this,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// İki turlu dolum halkası: 1. tur soluk iz + yay, 2. tur tam renk + ince
/// dolgu (1. turun izi altta kalır — kullanıcı iki aşamayı ayırt etsin).
class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter(this.state, this.color) : super(repaint: state._ring);

  final _HoldToSelectState state;
  final Color color;

  static const _radius = 22.0;
  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final ms = state._ring.value * _kHoldSelectDelay.inMilliseconds;
    final show = _kHoldRingShow.inMilliseconds;
    if (ms <= show) return;
    final stage1 = _kHoldTextStage.inMilliseconds;
    final rect = Rect.fromCircle(center: state._center, radius: _radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    const start = -math.pi / 2;
    if (ms < stage1) {
      paint.color = color.withValues(alpha: AppAlpha.hairline);
      canvas.drawCircle(state._center, _radius, paint);
      paint.color = color.withValues(alpha: AppAlpha.muted);
      canvas.drawArc(
        rect,
        start,
        2 * math.pi * (ms - show) / (stage1 - show),
        false,
        paint,
      );
      return;
    }
    canvas.drawCircle(
      state._center,
      _radius - 2,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: AppAlpha.pressed),
    );
    paint.color = color.withValues(alpha: AppAlpha.soft);
    canvas.drawCircle(state._center, _radius, paint);
    paint.color = color;
    canvas.drawArc(
      rect,
      start,
      2 * math.pi * (ms - stage1) / (_kHoldSelectDelay.inMilliseconds - stage1),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) =>
      old.state != state || old.color != color;
}

/// Ekranın dibine demirlenmiş Bento madde seçim çubuğu.
class _ItemSelectionBar extends StatefulWidget {
  const _ItemSelectionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.showCheckboxes,
    required this.allSelected,
    required this.allChecked,
    required this.allPackaged,
    required this.canRangeSelect,
    required this.onExit,
    required this.onSelectAll,
    required this.onRangeSelect,
    required this.onInvert,
    required this.onCheck,
    required this.onCopy,
    required this.onCopyAndCheck,
    required this.onBatchFormat,
    required this.onBatchHeader,
    required this.onBatchDivider,
    required this.onPackage,
    required this.onDelete,
  });

  final int selectedCount;
  final int totalCount;
  final bool showCheckboxes;
  final bool allSelected;
  final bool allChecked;
  final bool allPackaged;
  final bool canRangeSelect;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;
  final VoidCallback onRangeSelect;
  final VoidCallback onInvert;
  final VoidCallback onCheck;
  final VoidCallback onCopy;
  final VoidCallback onCopyAndCheck;
  final void Function(RichFormat format, {int? colorIndex}) onBatchFormat;
  final VoidCallback onBatchHeader;
  final VoidCallback onBatchDivider;
  final VoidCallback onPackage;
  final VoidCallback onDelete;

  @override
  State<_ItemSelectionBar> createState() => _ItemSelectionBarState();
}

class _ItemSelectionBarState extends State<_ItemSelectionBar> {
  bool _formatOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final keyboard = KeyboardInset.liveOf(context);
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    final hasSelection = widget.selectedCount > 0;

    return Positioned(
      left: AppSpace.s,
      right: AppSpace.s,
      bottom: AppSpace.s + (keyboard > systemBar ? keyboard : systemBar),
      child: Material(
        key: const ValueKey('items-selection-bar'),
        color: scheme.surfaceContainerHigh,
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: AppAlpha.scrim),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
          side: BorderSide(color: tokens.accentBorder ?? tokens.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_formatOpen && hasSelection) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s,
                  AppSpace.xs + AppSpace.xxs,
                  AppSpace.s,
                  AppSpace.xs,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _BatchChip(
                        key: const ValueKey('items-batch-bold'),
                        icon: Icons.format_bold_rounded,
                        label: l10n.formatBold,
                        onTap: () => widget.onBatchFormat(RichFormat.bold),
                        scheme: scheme,
                        text: text,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _BatchChip(
                        key: const ValueKey('items-batch-highlight'),
                        icon: Icons.border_color_rounded,
                        label: l10n.formatHighlight,
                        onTap: () => widget.onBatchFormat(
                          RichFormat.highlight,
                          colorIndex: 1,
                        ),
                        scheme: scheme,
                        text: text,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _BatchChip(
                        key: const ValueKey('items-batch-header'),
                        icon: Icons.title_rounded,
                        label: l10n.formatHeading,
                        onTap: widget.onBatchHeader,
                        scheme: scheme,
                        text: text,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _BatchChip(
                        key: const ValueKey('items-batch-divider'),
                        icon: Icons.horizontal_rule_rounded,
                        label: l10n.itemDivider,
                        onTap: widget.onBatchDivider,
                        scheme: scheme,
                        text: text,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
              ),
            ],
            Container(
              color: scheme.primaryContainer.withValues(alpha: AppAlpha.muted),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs,
                vertical: AppSpace.xxs,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.cancel,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: AppIconSize.m),
                    onPressed: widget.onExit,
                  ),
                  Expanded(
                    child: Text(
                      l10n.itemsSelected(widget.selectedCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.label.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                  ),
                  if (widget.canRangeSelect)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpace.xs,
                      ),
                      child: _BatchChip(
                        key: const ValueKey('items-range-select'),
                        icon: Icons.linear_scale_rounded,
                        label: l10n.itemRangeSelect,
                        onTap: widget.onRangeSelect,
                        scheme: scheme,
                        text: text,
                      ),
                    ),
                  IconButton(
                    key: const ValueKey('items-invert-select'),
                    tooltip: l10n.itemInvertSelection,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.published_with_changes_rounded,
                      size: AppIconSize.m,
                    ),
                    onPressed: widget.totalCount > 0 ? widget.onInvert : null,
                  ),
                  IconButton(
                    tooltip: l10n.selectAllItems,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      widget.allSelected ? Icons.deselect : Icons.select_all,
                      size: AppIconSize.m,
                    ),
                    onPressed: widget.totalCount > 0 ? widget.onSelectAll : null,
                  ),
                ],
              ),
            ),
            IconButtonTheme(
              data: IconButtonThemeData(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.showCheckboxes)
                      IconButton(
                        tooltip: widget.allChecked
                            ? l10n.uncheckSelectedItems
                            : l10n.checkSelectedItems,
                        icon: Icon(
                          widget.allChecked
                              ? Icons.remove_done
                              : Icons.done_all,
                          size: AppIconSize.m,
                        ),
                        onPressed: hasSelection ? widget.onCheck : null,
                      ),
                    IconButton(
                      tooltip: l10n.copy,
                      icon: const Icon(AppIcons.copy, size: AppIconSize.m),
                      onPressed: hasSelection ? widget.onCopy : null,
                    ),
                    if (widget.showCheckboxes)
                      IconButton(
                        key: const ValueKey('items-copy-check'),
                        tooltip: l10n.copyAndCheckSelectedItems,
                        icon: const Icon(
                          Icons.library_add_check_outlined,
                          size: AppIconSize.m,
                        ),
                        onPressed: hasSelection ? widget.onCopyAndCheck : null,
                      ),
                    IconButton(
                      key: const ValueKey('items-batch-format'),
                      tooltip: l10n.itemsBatchFormat,
                      icon: Icon(
                        Icons.text_format_rounded,
                        size: AppIconSize.m,
                        color: _formatOpen ? scheme.primary : null,
                      ),
                      onPressed: hasSelection
                          ? () => setState(() => _formatOpen = !_formatOpen)
                          : null,
                    ),
                    IconButton(
                      key: const ValueKey('items-package'),
                      tooltip: widget.allPackaged
                          ? l10n.notePackageUnpack
                          : l10n.quickRowPackage,
                      icon: const Icon(
                        AppIcons.notePackage,
                        size: AppIconSize.m,
                      ),
                      onPressed: hasSelection ? widget.onPackage : null,
                    ),
                    IconButton(
                      tooltip: l10n.delete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: AppIconSize.m,
                      ),
                      color: scheme.error,
                      onPressed: hasSelection ? widget.onDelete : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchChip extends StatelessWidget {
  const _BatchChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scheme,
    required this.text,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final AppText text;

  @override
  Widget build(BuildContext context) => Material(
    color: scheme.surfaceContainerHighest.withValues(alpha: AppAlpha.muted),
    borderRadius: BorderRadius.circular(AppRadius.s),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.s),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.xs, color: scheme.primary),
            const SizedBox(width: AppSpace.xs),
            Text(
              label,
              style: text.meta.copyWith(
                color: scheme.onSurface,
                fontWeight: AppWeight.medium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Satırın listedeki yeri: önbellekli satırın DIŞINDAN verilir (P20 M1).
/// Yer değişince yalnız okuyan küçük parçalar (tutamaç, numara) kurulur.
class _RowSlot extends InheritedWidget {
  const _RowSlot({
    super.key,
    this.reorderIndex,
    this.orderNumber,
    required super.child,
  });

  final int? reorderIndex;
  final int? orderNumber;

  static _RowSlot? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RowSlot>();

  @override
  bool updateShouldNotify(_RowSlot old) =>
      old.reorderIndex != reorderIndex || old.orderNumber != orderNumber;
}
