import '../../../../core/widgets/back_closes.dart';

import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/fixed_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/color_palette.dart';
import '../viewers/ink_layer.dart';
import 'pen_icons.dart';
import '../viewers/ink_pen.dart';
import '../viewers/ink_tools.dart';
import '../../../../core/a11y/chip_roles.dart';

/// Tepsideki araçlar (soldan sağa).
enum PenTrayTool { lasso, shapes, eraser, pen, marker, highlighter }

/// **KALEM TEPSİSİ** (kullanıcı isteği 2026-10-28: "örnek çizim ekranı daha
/// görsel olarak bütün ve menüsü güzel"). Araçlar simge değil, tepside
/// duran KALEMLER: cetvel (şekiller), silgi, tükenmez, keçeli, fosforlu.
/// Seçili araç tepsiden yukarı kalkar ve ucu çizilen renktedir — hangi
/// kalemin hangi renkte olduğu bir bakışta görülür. Seçili araca (ya da
/// sağdaki renk düğmesine) yeniden dokunmak ayar panelini açar: renkler,
/// kalınlık (canlı önizlemeli), şekil seçimi, silgide "temizle".
///
/// **TEK KALEM ARAYÜZÜ (F13.3, 2026-10-31):** PDF, sunum ve görsel üstünde
/// çizim de bu tepsiyle yapılır (eski `InkToolbar` kalktı) — iki ayrı kalem
/// arayüzü vardı, biri güncellenince öbürü geride kalıyordu. Belge üstünde
/// üst çubuk olmadığı için [controls] tepsinin üstüne ince bir satır koyar:
/// ipucu · geri al · yinele · yalnız kalem · ayarlar.
/// Kalem ayarları: tablette açılır pencere (kullanıcı isteği 2026-11-02),
/// telefonda alt levha.
void showInkSettings(BuildContext context, InkController ink) {
  if (PenTray.useRail(context)) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: InkSettingsSheet(controller: ink),
          ),
        ),
      ),
    );
    return;
  }
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => InkSettingsSheet(controller: ink),
    ),
  );
}

class PenTray extends StatefulWidget {
  const PenTray({
    super.key,
    required this.controller,
    this.controls = false,
    this.hint,
    this.trayHeight = 92,
    this.rail = false,
    this.dock = false,
    this.followActive = false,
    this.actions = const [],
  });

  /// **ETKİN YÜZEY** (OTURTMA F63.2, KALEM K4): geri al / yinele son
  /// dokunulan yüzeye ([InkController.active]: sayfa, sabit ya da gömülü ek)
  /// gider. Yalnız birden çok yüzeyi olan editörde açık; araç seçimi zaten
  /// ortak (`InkToolMemory`).
  final bool followActive;

  /// **ÇEKMECE KİPİ** (kullanıcı isteği 2026-11-02: "kalem modunda kalem
  /// paneli altta olsun, daha kibar olsun; kullanılmıyorken çekmece gibi
  /// içeri girsin, oraya tıklanınca birazcık yukarı gelsin"). Not sayfasının
  /// ÜSTÜNDE, altta yüzen yuvarlak bir tepsi: çizim başlayınca (ya da bir
  /// süre dokunulmayınca) aşağı kayar, yalnız kalemlerin uçları görünür;
  /// dokununca ya da yukarı çekince geri çıkar. Sayfa yerleşimi hiç
  /// değişmez (yer kaplamaz, üstte durur).
  final bool dock;

  /// Tablet penceresi mi (ray + ana-detayda da pencerenin kendisi ölçülür):
  /// orada kalemler sayfanın SOLUNDA sütun olur (kullanıcı isteği 2026-11-02:
  /// "üst ve alt kısımlar tamamen not sayfası olsun").
  static bool useRail(BuildContext context) =>
      MediaQueryData.fromView(View.of(context)).size.width >= 600;

  /// Dikey sütun: araçlar, renk, geri al/yinele, ayarlar ve [actions].
  final bool rail;

  /// Denetimlerin sonuna eklenen düğmeler (tam ekran, kalemi kapat).
  final List<Widget> actions;

  final InkController controller;

  /// Tepsinin üstünde geri al / yinele / yalnız kalem / ayarlar satırı
  /// (çizim ekranında bunlar uygulama çubuğunda, burada kapalı).
  final bool controls;

  /// Denetim satırındaki tek satırlık ipucu (iki parmak jesti); kement ya
  /// da "yalnız kalem" açıkken onların ipucu yazılır.
  final String? hint;

  /// Kalemlerin durduğu şeridin yüksekliği: bölmede (belgenin altında) daha
  /// alçak tutulur, belge görünür kalsın.
  final double trayHeight;

  @override
  State<PenTray> createState() => _PenTrayState();
}

class _PenTrayState extends State<PenTray> {
  bool _panel = false;

  /// Çekmece kipinde tepsi aşağıda mı (bkz. [PenTray.dock]).
  bool _tucked = false;
  Timer? _idle;
  int _strokes = 0;

  /// Bu kadar dokunulmazsa çekmece kendiliğinden iner.
  static const _idleDelay = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _strokes = _ink.ink.length;
    if (widget.dock) {
      _ink.addListener(_onInk);
      _armIdle();
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    if (widget.dock) _ink.removeListener(_onInk);
    super.dispose();
  }

  /// Çizim değişti (yeni çizgi, silme): kullanıcı sayfayla meşgul — açık
  /// renk paneli kapanır, tepsi yol vermek için iner (kullanıcı bulgusu
  /// 2026-11-02: "kalem seçildikten sonra yazmaya başlayınca otomatik
  /// kapanmıyor" — panel açıkken iniş engelleniyordu).
  void _onInk() {
    final count = _ink.ink.length;
    final changed = count != _strokes;
    _strokes = count;
    if (!_ink.drawing && !changed) return;
    if (_panel) setState(() => _panel = false);
    _setTucked(true);
  }

  void _armIdle() {
    _idle?.cancel();
    if (!widget.dock) return;
    _idle = Timer(_idleDelay, () {
      if (mounted && !_panel) _setTucked(true);
    });
  }

  void _setTucked(bool value) {
    if (!widget.dock || value == _tucked || !mounted) return;
    setState(() => _tucked = value);
    if (!value) _armIdle();
  }

  /// Tepsiye her dokunuş: açık tut, zamanlayıcıyı yeniden kur.
  void _touched() {
    if (_tucked) _setTucked(false);
    _armIdle();
  }

  InkController get _ink => widget.controller;

  /// Geri al / yinelenin hedefi (bkz. [PenTray.followActive]).
  InkController get _hist =>
      widget.followActive ? (InkController.active ?? _ink) : _ink;

  static PenTrayTool _penToolOf(InkPen p) => switch (p) {
    InkPen.pen => PenTrayTool.pen,
    InkPen.marker => PenTrayTool.marker,
    InkPen.highlighter => PenTrayTool.highlighter,
  };

  PenTrayTool get _current {
    if (_ink.lasso) return PenTrayTool.lasso;
    if (_ink.eraser) return PenTrayTool.eraser;
    if (_ink.arrow || _ink.shape != null) return PenTrayTool.shapes;
    return _penToolOf(_ink.pen);
  }

  void _tap(PenTrayTool tool) {
    HapticFeedback.selectionClick();
    _touched();
    if (tool == _current) {
      _togglePanel();
      return;
    }
    switch (tool) {
      case PenTrayTool.lasso:
        _ink.setLasso(true);
      case PenTrayTool.shapes:
        // Son şekil hatırlanmıyor: ok en sık kullanılanı ("şuraya bak").
        _ink.setArrow(true);
      case PenTrayTool.eraser:
        _ink.setEraser(true);
      case PenTrayTool.pen:
        _ink.setPen(InkPen.pen);
      case PenTrayTool.marker:
        _ink.setPen(InkPen.marker);
      case PenTrayTool.highlighter:
        _ink.setPen(InkPen.highlighter);
    }
  }

  /// Renk/kalınlık paneli: şeritte yerinde açılır, sütunda açılır pencere.
  void _togglePanel() {
    _touched();
    if (!widget.rail) {
      setState(() => _panel = !_panel);
      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListenableBuilder(
              listenable: _ink,
              builder: (_, _) => SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader(title: _labels(context.l10n)[_current]!),
                    _Options(controller: _ink, tool: _current),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Geri sırası: ayar kartı → açık kapsül (hapa iner) → kalem kipi
    // (dıştaki BackCloses).
    return BackCloses(
      open: _panel || (widget.dock && !_tucked),
      onClose: () {
        if (_panel) {
          setState(() => _panel = false);
        } else {
          _idle?.cancel();
          _setTucked(true);
        }
      },
      // Renk/kalınlık kartı tepsinin DIŞINA dokununca kapanır (kullanıcı
      // isteği 2026-11-09: "ekranda bir yere tıklayınca kapanmalı, şu an x'e
      // basana kadar açık kalıyor"). Tepsinin kendi düğmeleri içeride sayılır.
      child: TapRegion(
        onTapOutside: (_) {
          if (_panel) setState(() => _panel = false);
        },
        // Etkin yüzey değişince (toolRev) onun çizgileri de dinlenir: geri
        // al düğmesi o yüzeyin geçmişine göre açılır.
        child: ValueListenableBuilder(
          valueListenable: InkToolMemory.toolRev,
          builder: (context, _, _) => ListenableBuilder(
            listenable: identical(_hist, _ink)
                ? _ink
                : Listenable.merge([_ink, _hist]),
            builder: (context, _) => widget.rail
                ? _buildRail(context)
                : widget.dock
                ? _buildDock(context)
                : _build(context),
          ),
        ),
      ),
    );
  }

  /// Sayfanın solundaki sütun: kalemler ucu sayfaya bakacak şekilde yatık.
  Widget _buildRail(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final current = _current;
    final labels = _labels(l10n);
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 64,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final tool in PenTrayTool.values)
                  SizedBox(
                    width: 64,
                    height: 48,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: _TrayTool(
                        key: ValueKey('pen-tray-${tool.name}'),
                        tool: tool,
                        label: labels[tool]!,
                        selected: tool == current,
                        ink: _ink.color,
                        onTap: () => _tap(tool),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _colorDot(scheme, l10n),
                if (InkToolMemory.presets.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _presetRow(Axis.vertical),
                ],
                const Divider(height: 18, indent: 12, endIndent: 12),
                ..._controlButtons(l10n),
                ...widget.actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Çekmece tepsisi — TEK SATIR (kullanıcı bulgusu 2026-11-02: "çok
  /// yükseliyor ve dar"): ince tutamak, altında kalemler · renk · geri al ·
  /// (geniş ekranda) yinele/yalnız kalem/ayarlar · [actions]. Dar ekranda
  /// seyrek düğmeler "⋯" menüsünde. Renk/kalınlık paneli tepsiyi
  /// yükseltmez, üstünde ayrı kart olarak açılır. Aşağıdayken yalnız
  /// tutamak + seçili rengin noktası görünür.
  /// **KALEM KAPSÜLÜ** (sıfırdan tasarım 2026-11-07, kullanıcı isteği:
  /// "alt kalem menüsünü baştan yaz; ekranda daha az yer, görsel premium
  /// olsun"). Yazarken sayfanın dibinde yalnız küçük bir HAP kalır (seçili
  /// kalem + renk) — eski çekmecenin yarım görünen 80 dp'lik şeridi yerine
  /// 44 dp. Dokununca ya da yukarı çekince ortada yüzen tek satırlık KAPSÜL
  /// açılır: kalemler · hızlı renkler · geri al · ⋯ · eylemler. Seçili
  /// kaleme ya da palet düğmesine dokunmak ayar kartını kapsülün üstünde
  /// açar. Çizim başlayınca / 6 sn dokunulmayınca yine hapa döner.
  Widget _buildDock(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final current = _current;
    final labels = _labels(l10n);
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final bottom = MediaQuery.paddingOf(context).bottom + _kDockGap;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final open = !_tucked || _panel;
    final inkDot = _ink.eraser ? scheme.primary : _ink.color;

    final shape = StadiumBorder(
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        width: 0.8,
      ),
    );
    Widget surface(Widget child, {ShapeBorder? border}) => DecoratedBox(
      decoration: ShapeDecoration(
        shape: border ?? shape,
        // İki katlı yumuşak gölge: yakın (keskin) + uzak (dağınık).
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: border ?? shape,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );

    final mini = Semantics(
      button: true,
      label: l10n.penTrayShow,
      child: GestureDetector(
        key: const ValueKey('pen-dock-peek'),
        behavior: HitTestBehavior.opaque,
        onTap: _touched,
        child: surface(
          // AZICIK GENİŞ (kullanıcı isteği 2026-11-08: "basınca karışıyor
          // bazen"): 48 dp boy, kalem/renk bölümü ile silgi arasında ayraç
          // ve 48 dp silgi hedefi — hap açma ile hızlı silgi karışmasın.
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seçili kalem çapraz yatık, ucu rengiyle.
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: FittedBox(
                        child: SizedBox(
                          width: 44,
                          height: 96,
                          child: CustomPaint(
                            painter: PenToolPainter(
                              tool: current,
                              ink: _ink.color,
                              dark: scheme.brightness == Brightness.dark,
                              lifted: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Swatch(color: inkDot, size: 16, selected: false),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  // HIZLI SİLGİ (kullanıcı isteği 2026-11-08): küçük panelde
                  // hep silgi; silgi seçiliyken yerinde SON kalem — tek
                  // dokunuşla gidip gelinir. `_ink.pen` silgide de korunur.
                  Tooltip(
                    message: _ink.eraser ? labels[_penToolOf(_ink.pen)]! : l10n.eraser,
                    child: InkResponse(
                      key: const ValueKey('pen-dock-quick-eraser'),
                      radius: 20,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _ink.eraser ? _ink.setPen(_ink.pen) : _ink.setEraser(true);
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          _ink.eraser
                              ? Icons.edit_outlined
                              : Icons.auto_fix_normal_outlined,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final divider = Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    );
    Widget tool(PenTrayTool t) => _DockTool(
      key: ValueKey('pen-tray-${t.name}'),
      tool: t,
      label: labels[t]!,
      selected: t == current,
      ink: _ink.color,
      onTap: () => _tap(t),
    );
    final colors = wide
        ? [
            for (final c in _quickColors())
              _Swatch(
                color: c,
                size: 26,
                selected: !_ink.eraser && c.toARGB32() == _ink.color.toARGB32(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _touched();
                  if (c.toARGB32() == _ink.color.toARGB32()) {
                    _togglePanel();
                  } else {
                    _ink.setColor(c);
                  }
                },
              ),
            // Tüm renkler + kalınlık: uygulamanın "özel renk" gökkuşağı
            // halkası (simge sözlüğünde palet = görünüm).
            Tooltip(
              message: l10n.inkColor,
              child: InkResponse(
                key: const ValueKey('pen-tray-color'),
                radius: 22,
                onTap: _togglePanel,
                child: SizedBox(
                  width: 40,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: FixedColors.rainbowSweep,
                        boxShadow: _panel
                            ? [
                                BoxShadow(
                                  color: scheme.primary,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]
        : [
            _Swatch(
              key: const ValueKey('pen-tray-color'),
              color: inkDot,
              size: 26,
              selected: _panel,
              tooltip: l10n.inkColor,
              onTap: _togglePanel,
            ),
          ];
    final capsule = surface(
      SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
            children: [
              for (final t in PenTrayTool.values)
                wide ? tool(t) : Expanded(child: tool(t)),
              divider,
              ...colors,
              divider,
              IconButton(
                key: const ValueKey('pen-tray-undo'),
                tooltip: l10n.undo,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.undo_rounded),
                onPressed: _hist.canUndo ? () => _hist.undo() : null,
              ),
              if (wide)
                IconButton(
                  tooltip: l10n.redo,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: _hist.canRedo ? () => _hist.redo() : null,
                ),
              _moreMenu(l10n, redo: !wide),
              ...widget.actions,
            ],
          ),
        ),
      ),
    );
    final panel = surface(
      _Options(controller: _ink, tool: current),
      border: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
    );
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 150) _setTucked(true);
          if (v < -150) _touched();
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, bottom),
          child: Listener(
            onPointerDown: (_) => _armIdle(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: _panel
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: panel,
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ),
                if (open && InkToolMemory.presets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: surface(
                      SizedBox(
                        height: 44,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _presetRow(Axis.horizontal),
                        ),
                      ),
                    ),
                  ),
                // Hap ↔ kapsül: alttan büyüyerek/küçülerek yer değiştirir.
                AnimatedSwitcher(
                  duration: duration,
                  reverseDuration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      alignment: Alignment.bottomCenter,
                      scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [...previous, ?current],
                  ),
                  child: open
                      ? KeyedSubtree(
                          key: const ValueKey('pen-dock-open'),
                          child: capsule,
                        )
                      : KeyedSubtree(
                          key: const ValueKey('pen-dock-closed'),
                          child: mini,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kapsüldeki hızlı renkler: sabit sıra (dokununca yer değiştirmesin);
  /// seçili renk listede yoksa son yuvaya o gelir.
  List<Color> _quickColors() {
    // Siyah, mavi, kırmızı, yeşil (ortak kalem paleti).
    final base = [
      for (final i in const [0, 5, 2, 4]) kInkPalette[i],
    ];
    final current = _ink.color.toARGB32();
    if (base.any((c) => c.toARGB32() == current)) return base;
    return [...base.take(3), Color(current)];
  }

  /// Dar ekranda seyrek kullanılan denetimler: yinele, yalnız kalem, ayarlar.
  Widget _moreMenu(AppLocalizations l10n, {bool redo = true}) =>
      PopupMenuButton<int>(
        key: const ValueKey('pen-tray-more'),
        tooltip: l10n.more,
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (v) => switch (v) {
          0 => _hist.redo(),
          1 => _ink.setPenOnly(!_ink.penOnly),
          3 => _pinCurrent(),
          _ => showInkSettings(context, _ink),
        },
        itemBuilder: (_) => [
          if (redo)
            PopupMenuItem(
              value: 0,
              enabled: _hist.canRedo,
              child: ListTile(
                leading: const Icon(Icons.redo_rounded),
                title: Text(l10n.redo),
              ),
            ),
          CheckedPopupMenuItem(
            value: 1,
            checked: _ink.penOnly,
            child: Text(_ink.penOnly ? l10n.inkPenOnlyOn : l10n.inkPenOnlyOff),
          ),
          if (!_ink.eraser && !_ink.lasso)
            PopupMenuItem(
              key: const ValueKey('pen-tray-pin'),
              value: 3,
              child: ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(l10n.inkPinPen),
              ),
            ),
          PopupMenuItem(
            value: 2,
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(l10n.inkSettings),
            ),
          ),
        ],
      );

  /// Seçili kalemi (tür + renk + kalınlık) kapsüle sabitler; doluysa en
  /// eskisi düşer (kullanıcı isteği 2026-11-08).
  void _pinCurrent() {
    final p = _ink.currentPreset;
    final list = [...InkToolMemory.presets.where((x) => x != p), p];
    InkToolMemory.savePresets(
      list.length > InkToolMemory.maxPresets
          ? list.sublist(list.length - InkToolMemory.maxPresets)
          : list,
    );
    HapticFeedback.selectionClick();
    _touched();
    setState(() {});
  }

  /// Sabitlenmiş kalemler: dokun = seç, basılı tut = kaldır.
  Widget _presetRow(Axis axis) {
    final current = _ink.eraser || _ink.lasso ? null : _ink.currentPreset;
    final l10n = context.l10n;
    return Flex(
      direction: axis,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in InkToolMemory.presets)
          _PresetChip(
            key: ValueKey('pen-preset-${p.encode()}'),
            preset: p,
            selected: p == current,
            label: l10n.inkPinnedPen,
            onTap: () {
              HapticFeedback.selectionClick();
              _touched();
              _ink.applyPreset(p);
            },
            onRemove: () {
              HapticFeedback.mediumImpact();
              InkToolMemory.savePresets([
                for (final x in InkToolMemory.presets)
                  if (x != p) x,
              ]);
              setState(() {});
            },
          ),
      ],
    );
  }

  Map<PenTrayTool, String> _labels(AppLocalizations l10n) => {
    PenTrayTool.lasso: l10n.inkLasso,
    PenTrayTool.shapes: l10n.inkShapes,
    PenTrayTool.eraser: l10n.eraser,
    PenTrayTool.pen: l10n.penBallpoint,
    PenTrayTool.marker: l10n.penMarker,
    PenTrayTool.highlighter: l10n.penHighlighter,
  };

  /// RENK düğmesi: seçili renk; dokununca panel.
  Widget _colorDot(ColorScheme scheme, AppLocalizations l10n) => Tooltip(
    message: l10n.inkColor,
    child: InkResponse(
      key: const ValueKey('pen-tray-color'),
      radius: 26,
      onTap: _togglePanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _ink.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _panel ? scheme.primary : scheme.outlineVariant,
            width: _panel ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _controlButtons(AppLocalizations l10n) => [
    IconButton(
      key: const ValueKey('pen-tray-undo'),
      tooltip: l10n.undo,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.undo_rounded),
      onPressed: _hist.canUndo ? () => _hist.undo() : null,
    ),
    IconButton(
      tooltip: l10n.redo,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.redo_rounded),
      onPressed: _hist.canRedo ? () => _hist.redo() : null,
    ),
    // YALNIZ KALEM: açıkken parmak kaydırır/yakınlaştırır.
    IconButton(
      tooltip: _ink.penOnly ? l10n.inkPenOnlyOn : l10n.inkPenOnlyOff,
      isSelected: _ink.penOnly,
      visualDensity: VisualDensity.compact,
      icon: Icon(_ink.penOnly ? Icons.draw_rounded : Icons.touch_app_outlined),
      onPressed: () => _ink.setPenOnly(!_ink.penOnly),
    ),
    IconButton(
      key: const ValueKey('pen-tray-settings'),
      tooltip: l10n.inkSettings,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.tune_rounded),
      onPressed: () => showInkSettings(context, _ink),
    ),
  ];

  /// [PenTray.controls] satırı: solda ipucu, sağda geçmiş ve ayarlar.
  Widget _controlRow(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hint = _ink.lasso
        ? l10n.inkLassoHint
        : _ink.penOnly
        ? l10n.inkPenOnlyHint
        : widget.hint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: hint == null
                ? const SizedBox.shrink()
                : Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
          ),
          ..._controlButtons(l10n),
          ...widget.actions,
        ],
      ),
    );
  }

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final current = _current;
    final labels = _labels(l10n);
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            if (widget.controls) _controlRow(context),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: _panel
                  ? _Options(controller: _ink, tool: current)
                  : const SizedBox(width: double.infinity),
            ),
            SizedBox(
              height: widget.trayHeight,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  for (final tool in PenTrayTool.values)
                    Expanded(
                      child: _TrayTool(
                        key: ValueKey('pen-tray-${tool.name}'),
                        tool: tool,
                        label: labels[tool]!,
                        selected: tool == current,
                        ink: _ink.color,
                        onTap: () => _tap(tool),
                      ),
                    ),
                  // RENK düğmesi: seçili renk; dokununca panel.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _colorDot(scheme, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kapsül/hap ile ekranın alt kenarı (gezinme çubuğunun üstü) arası.
const double _kDockGap = 10;

/// Kapsüldeki tek kalem: dik durur, yalnız üst kısmı görünür; seçili kalem
/// yaylı biçimde yukarı kalkar, ucu çizilen renktedir.
class _DockTool extends StatelessWidget {
  const _DockTool({
    super.key,
    required this.tool,
    required this.label,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final PenTrayTool tool;
  final String label;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 52,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
                    top: selected ? 3 : 15,
                    child: SizedBox(
                      width: 31,
                      height: 68,
                      child: FittedBox(
                        child: SizedBox(
                          width: 44,
                          height: 96,
                          child: CustomPaint(
                            painter: PenToolPainter(
                              tool: tool,
                              ink: ink,
                              dark: dark,
                              lifted: selected,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renk yuvarlağı: seçiliyse arada boşluk bırakan ince halka (renk
/// kenarına yapışık kalın çerçeve yerine).
class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.size,
    required this.selected,
    this.onTap,
    this.tooltip,
  });

  final Color color;
  final double size;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size + 8,
      height: size + 8,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
      ),
    );
    if (onTap == null) return dot;
    final button = InkResponse(
      radius: size,
      onTap: onTap,
      child: SizedBox(
        width: math.max(size + 14, 40),
        height: 48,
        child: Center(child: dot),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Tepsideki tek araç: seçiliyse yukarı kalkar (yaylı), altında küçük renk
/// noktası belirir.
class _TrayTool extends StatelessWidget {
  const _TrayTool({
    super.key,
    required this.tool,
    required this.label,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  final PenTrayTool tool;
  final String label;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 320),
                  curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
                  offset: Offset(0, selected ? 0.02 : 0.24),
                  child: SizedBox(
                    width: 44,
                    height: 96,
                    child: CustomPaint(
                      painter: PenToolPainter(
                        tool: tool,
                        ink: ink,
                        dark: dark,
                        lifted: selected,
                      ),
                    ),
                  ),
                ),
                // Seçili aracın altındaki çizgi (örnekteki gibi).
                Positioned(
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: 22,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: tool == PenTrayTool.eraser
                            ? scheme.primary
                            : ink,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.6),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tepsinin üstünde açılan ayar paneli: renkler, kalınlık/önizleme, araca
/// göre şekiller ya da temizle.
class _Options extends StatelessWidget {
  const _Options({required this.controller, required this.tool});

  final InkController controller;
  final PenTrayTool tool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final pen = controller.pen;
    final recent = [
      for (final c in InkToolMemory.recentColors.take(4))
        if (!kInkPalette.any((p) => p.toARGB32() == c)) Color(c),
    ];
    Widget dot(Color color) {
      final selected =
          !controller.eraser && controller.color.toARGB32() == color.toARGB32();
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 10),
        child: InkResponse(
          radius: 20,
          onTap: () {
            HapticFeedback.selectionClick();
            controller.setColor(color);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 32 : 28,
            height: selected ? 32 : 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );
    }

    String shapeLabel(InkShape s) => switch (s) {
      InkShape.line => l10n.inkShapeLine,
      InkShape.rectangle => l10n.inkShapeRectangle,
      InkShape.ellipse => l10n.inkShapeEllipse,
      InkShape.triangle => l10n.inkShapeTriangle,
      InkShape.table => l10n.inkShapeTable,
    };
    IconData shapeIcon(InkShape s) => switch (s) {
      InkShape.line => Icons.horizontal_rule_rounded,
      InkShape.rectangle => Icons.crop_square_rounded,
      InkShape.ellipse => Icons.circle_outlined,
      InkShape.triangle => Icons.change_history_rounded,
      InkShape.table => Icons.table_chart_outlined,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tool == PenTrayTool.shapes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.north_east_rounded, size: 18),
                    label: Text(l10n.inkArrow),
                    selected: controller.arrow,
                    onSelected: (_) => controller.setArrow(true),
                  ),
                  for (final s in InkShape.values)
                    radioChip(
                      ChoiceChip(
                        avatar: Icon(shapeIcon(s), size: 18),
                        label: Text(shapeLabel(s)),
                        selected: controller.shape == s,
                        onSelected: (_) => controller.setShape(s),
                      ),
                    ),
                ],
              ),
            ),
          if (tool == PenTrayTool.lasso)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: controller.hasSelection
                  ? Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.inkDeleteSelection),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.error,
                          ),
                          onPressed: controller.deleteSelection,
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.deselect),
                          label: Text(l10n.inkClearSelection),
                          onPressed: controller.clearSelection,
                        ),
                      ],
                    )
                  : Text(
                      l10n.inkLassoHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
            ),
          if (tool == PenTrayTool.eraser) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.clearInk),
                onPressed: controller.ink.isEmpty ? null : controller.clear,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.inkPartialEraserTitle),
              subtitle: Text(l10n.inkPartialEraserInfo),
              value: controller.partialEraser,
              onChanged: controller.setPartialEraser,
            ),
          ] else if (tool == PenTrayTool.lasso && !controller.hasSelection)
            const SizedBox.shrink()
          else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final color in kInkPalette) dot(color),
                  for (final color in recent) dot(color),
                  PaletteButton(
                    title: l10n.paletteMore,
                    size: 28,
                    current: kInkPalette.contains(controller.color)
                        ? null
                        : controller.color,
                    onPicked: controller.setColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Kalınlığın CANLI önizlemesi: gerçek çizgi kalınlığında nokta.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: controller.widthPx.clamp(2.0, 46.0),
                      height: controller.widthPx.clamp(2.0, 46.0),
                      decoration: BoxDecoration(
                        color: controller.penColor,
                        shape: pen == InkPen.highlighter
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: pen.clampWidth(controller.widthPx),
                    min: pen.minWidth,
                    max: pen.maxWidth,
                    onChanged: controller.setWidth,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    controller.widthPx.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            // Şeffaflık da tepsinin kendi panelinde (kullanıcı isteği
            // 2026-11-08): ayrı ayar sayfasına gitmeden. Fosforlu sabit %40.
            Row(
              key: const ValueKey('pen-tray-opacity'),
              children: [
                SizedBox(
                  width: 48,
                  height: 40,
                  child: Tooltip(
                    message: l10n.inkOpacity,
                    child: Icon(
                      Icons.opacity_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: pen == InkPen.highlighter ? 0.4 : controller.opacity,
                    min: 0.1,
                    divisions: 9,
                    label:
                        '%${((pen == InkPen.highlighter ? 0.4 : controller.opacity) * 100).round()}',
                    onChanged: pen == InkPen.highlighter
                        ? null
                        : controller.setOpacity,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '%${((pen == InkPen.highlighter ? 0.4 : controller.opacity) * 100).round()}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Sabitlenmiş kalem düğmesi: renkli nokta, boyu kalınlığı, biçimi kalem
/// türünü gösterir (fosforlu yarı saydam kare, keçeli dolu, tükenmez ince).
class _PresetChip extends StatelessWidget {
  const _PresetChip({
    super.key,
    required this.preset,
    required this.selected,
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final InkPreset preset;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pen = preset.pen < InkPen.values.length
        ? InkPen.values[preset.pen]
        : InkPen.pen;
    final color = Color(preset.color);
    final t = ((preset.width - pen.minWidth) / (pen.maxWidth - pen.minWidth))
        .clamp(0.0, 1.0);
    final dot = 8 + 12 * t;
    final highlighter = pen == InkPen.highlighter;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onRemove,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.8),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Container(
                  width: highlighter ? 16 : dot,
                  height: highlighter ? dot * 0.7 + 4 : dot,
                  decoration: BoxDecoration(
                    color: highlighter ? color.withAlpha(0x99) : color,
                    shape: highlighter ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: highlighter ? BorderRadius.circular(3) : null,
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.25),
                      width: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
