import '../../../../app/window_class.dart';
import '../../../../core/widgets/back_closes.dart';

import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_design.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/fixed_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../../core/widgets/color_palette.dart';
import '../viewers/ink_layer.dart';
import 'pen_icons.dart';
import 'pen_stroke_preview.dart';
import '../viewers/ink_pen.dart';
import '../viewers/ink_tools.dart';
import '../../../../core/a11y/chip_roles.dart';
import '../../../../core/haptics.dart';

/// Tepsideki araçlar (soldan sağa).
enum PenTrayTool { lasso, shapes, eraser, pen, fountain, marker, highlighter }

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
  // Ortak levha (P63 PB3): tutamak + üst güvenli alan düzeltmesi buraya da.
  unawaited(
    showAppSheet<void>(
      context: context,
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
    this.showUndo = true,
  });

  /// Kapsülde geri al / yinele (yalnız [dock]). Editör üst çubuğunda zaten
  /// geri al varken kapalı (kullanıcı isteği 2026-11-15: "geri butonuna gerek
  /// yok, üstte zaten var"); üst çubuğun kalktığı kalem + tam ekranda açık.
  final bool showUndo;

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
  /// Telefon yatayda (851×393) sütun sığmaz: altta dok kalır (F66.7).
  static bool useRail(BuildContext context) {
    final win = WindowClass.fromSize(
      MediaQueryData.fromView(View.of(context)).size,
      web: kIsWeb,
    );
    return win.atLeast(WindowWidth.medium) && !win.compactDevice;
  }

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

class _PenTrayState extends State<PenTray>
    with SingleTickerProviderStateMixin {
  bool _panel = false;

  /// Ayar panelinin girişi/çıkışı (P63 PB3): yuva TEK ADIMDA açılır, içerik
  /// yalnız boyamada (solma + kayma) belirir; kapanışta çıkış bitince yuva
  /// tek adımda kalkar. boy animasyonu YOK — şerit belgeyle aynı sütunda
  /// olduğu ekranlarda belge her karede yeniden diziliyordu.
  late final AnimationController _panelAnim = AnimationController(vsync: this)
    ..addStatusListener((s) {
      final shown = s != AnimationStatus.dismissed;
      if (!shown) _panelLeaving = null;
      _panelShown.value = shown;
    });
  CurvedAnimation? _panelCurve;

  /// Yuvayı yalnız kendi küçük kurucusu boşaltır (çıkış bitince tepsinin
  /// tamamı yeniden kurulmaz).
  final _panelShown = ValueNotifier(false);

  /// Çıkan panelin son hâli: çıkış süresince AYNI örnek (çizgi olayları onu
  /// yeniden kurmaz).
  Widget? _panelLeaving;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _panelAnim
      ..duration = AppMotion.of(context, AppMotion.short)
      ..reverseDuration = AppMotion.of(
        context,
        AppMotion.exitOf(AppMotion.short),
      );
    _panelCurve?.dispose();
    _panelCurve = CurvedAnimation(
      parent: _panelAnim,
      curve: AppMotion.curveOf(context, AppMotion.enter),
      reverseCurve: AppMotion.curveOf(context, AppMotion.exit),
    );
  }

  @override
  void dispose() {
    _idle?.cancel();
    if (widget.dock) _ink.removeListener(_onInk);
    _panelCurve?.dispose();
    _panelAnim.dispose();
    _panelShown.dispose();
    super.dispose();
  }

  /// Paneli aç/kapa: durum + giriş/çıkış hareketi tek yerde.
  void _setPanel(bool value) {
    if (value == _panel) return;
    setState(() => _panel = value);
    value ? _panelAnim.forward(from: 0) : _panelAnim.reverse();
  }

  /// Panel yuvası: KOŞULSUZ kurulu (ağaç şekli sabit), kapalıyken boş.
  Widget _panelSlot(Widget Function() panel) {
    final Widget? content;
    if (_panel) {
      content = _panelLeaving = panel();
    } else {
      content = _panelAnim.isDismissed ? null : _panelLeaving;
    }
    final a = _panelCurve!;
    return ValueListenableBuilder<bool>(
      valueListenable: _panelShown,
      builder: (_, shown, child) =>
          shown && child != null ? child : const SizedBox.shrink(),
      child: content == null
          ? null
          : FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: a.drive(
                  Tween(begin: const Offset(0, _kPanelRise), end: Offset.zero),
                ),
                child: content,
              ),
            ),
    );
  }

  /// Tepside duran araçlar (P63 PB3, plan §3.2.1): kullanıcının gizledikleri
  /// çıkar; tükenmez ve silgi gizlenemez, o an seçili araç hep çizilir.
  List<PenTrayTool> get _tools {
    final prefs = Personalize.current;
    final current = _current;
    return [
      for (final t in PenTrayTool.values)
        if (t == current ||
            t == PenTrayTool.pen ||
            t == PenTrayTool.eraser ||
            prefs.shows(UiItem.penTool(t.name)))
          t,
    ];
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
    _setPanel(false);
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
    InkPen.fountain => PenTrayTool.fountain,
  };

  PenTrayTool get _current {
    if (_ink.lasso) return PenTrayTool.lasso;
    if (_ink.eraser) return PenTrayTool.eraser;
    if (_ink.arrow || _ink.shape != null) return PenTrayTool.shapes;
    return _penToolOf(_ink.pen);
  }

  void _tap(PenTrayTool tool) {
    AppHaptics.tick();
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
      case PenTrayTool.fountain:
        _ink.setPen(InkPen.fountain);
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
      _setPanel(!_panel);
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
                padding: const EdgeInsets.only(
                  top: AppSpace.m,
                  bottom: AppSpace.s,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeader(title: _labels(context.l10n)[_current]!),
                    _options(),
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
          _setPanel(false);
        } else {
          _idle?.cancel();
          _setTucked(true);
        }
      },
      // Renk/kalınlık kartı tepsinin DIŞINA dokununca kapanır (kullanıcı
      // isteği 2026-11-09: "ekranda bir yere tıklayınca kapanmalı, şu an x'e
      // basana kadar açık kalıyor"). Tepsinin kendi düğmeleri içeride sayılır.
      child: TapRegion(
        onTapOutside: (_) => _setPanel(false),
        // Etkin yüzey değişince (toolRev) onun çizgileri de dinlenir: geri
        // al düğmesi o yüzeyin geçmişine göre açılır.
        child: ValueListenableBuilder(
          valueListenable: InkToolMemory.toolRev,
          builder: (context, _, _) => ListenableBuilder(
            // Personalize: gizlenen kalemler (kök setState yok).
            listenable: Listenable.merge([
              _ink,
              if (!identical(_hist, _ink)) _hist,
              Personalize.listenable,
            ]),
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
    final theme = Theme.of(context);
    // Sütun: zeminden bir ton, sayfa tarafında ince çizgi; gölgesiz.
    return Material(
      color: scheme.surfaceContainerLow,
      shape: Border(
        right: BorderSide(color: AppTokens.fromTheme(theme).hairline),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 64,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
            child: Column(
              children: [
                for (final tool in _tools)
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
                const SizedBox(height: AppSpace.s),
                _colorButton(l10n),
                if (InkToolMemory.presets.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s),
                  _presetRow(Axis.vertical),
                ],
                const Divider(
                  height: AppSpace.l,
                  indent: AppSpace.m,
                  endIndent: AppSpace.m,
                ),
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
  /// açılır: kalemler · hızlı renkler · silgi · ⋯ · eylemler (2026-11-15:
  /// geri al üst çubukta, onay düğmeleri yok — seçim anında uygulanır). Seçili
  /// kaleme ya da palet düğmesine dokunmak ayar kartını kapsülün üstünde
  /// açar. Çizim başlayınca / 6 sn dokunulmayınca yine hapa döner.
  Widget _buildDock(BuildContext context) => LayoutBuilder(
    // Geniş kapsül BÖLMENİN enine göre (pencere değil): bölünmüş görünümde
    // pencere geniş ama bölme dar olabilir — tek satır taşıyordu (G4 turu).
    builder: (context, c) => _dock(
      context,
      wide:
          c.maxWidth >=
          _kWideDockFixed + _kDockSlot * (_tools.length + widget.actions.length),
    ),
  );

  Widget _dock(BuildContext context, {required bool wide}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final current = _current;
    final labels = _labels(l10n);
    final bottom = MediaQuery.paddingOf(context).bottom + _kDockGap;
    final open = !_tucked || _panel;
    final inkDot = _ink.eraser ? scheme.primary : _ink.color;
    // Silgi kalem sırasında değil, sağda kendi düğmesinde (kullanıcı isteği
    // 2026-11-15: "kalem yazısı varken silgi her zaman kolay erişilebilir").
    final tools = [
      for (final t in _tools)
        if (t != PenTrayTool.eraser) t,
    ];
    final undo = widget.showUndo;

    // Yüzen yüzey (P63 PB3): ortak `AppSurface.floating` — ince çizgi +
    // bulanıksız alt kenar; bulanık gölge ve sabit siyah yok.
    Widget surface(Widget child, {double radius = AppRadius.pill}) =>
        DecoratedBox(
          decoration: AppSurface.floating(theme, radius: radius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        );

    final rule = Container(
      width: 1,
      height: AppSpace.xxl,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      color: scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
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
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.l,
                end: AppSpace.s,
              ),
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
                  const SizedBox(width: AppSpace.s),
                  _Swatch(color: inkDot, size: 16, selected: false),
                  const SizedBox(width: AppSpace.xs),
                  rule,
                  // HIZLI SİLGİ (kullanıcı isteği 2026-11-08): küçük panelde
                  // hep silgi; silgi seçiliyken yerinde SON kalem — tek
                  // dokunuşla gidip gelinir. `_ink.pen` silgide de korunur.
                  Tooltip(
                    message: _ink.eraser
                        ? labels[_penToolOf(_ink.pen)]!
                        : l10n.eraser,
                    child: InkResponse(
                      key: const ValueKey('pen-dock-quick-eraser'),
                      radius: AppSpace.xl,
                      onTap: () {
                        AppHaptics.tick();
                        _ink.eraser
                            ? _ink.setPen(_ink.pen)
                            : _ink.setEraser(true);
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          _ink.eraser
                              ? Icons.edit_outlined
                              : Icons.auto_fix_normal_outlined,
                          size: AppIconSize.m,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: AppIconSize.m,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                  AppHaptics.tick();
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
                radius: AppSpace.xl,
                onTap: _togglePanel,
                child: SizedBox(
                  width: 40,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      padding: const EdgeInsets.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: FixedColors.rainbowSweep,
                        // Seçili halka: bulanıksız, yalnız yayılma.
                        boxShadow: _panel
                            ? [
                                BoxShadow(
                                  color: scheme.primary,
                                  spreadRadius: AppSpace.xxs,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
          child: Row(
            mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
            children: [
              for (final t in tools) wide ? tool(t) : Expanded(child: tool(t)),
              rule,
              ...colors,
              _eraserButton(l10n, scheme),
              rule,
              if (undo)
                IconButton(
                  key: const ValueKey('pen-tray-undo'),
                  tooltip: l10n.undo,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: _hist.canUndo ? () => _hist.undo() : null,
                ),
              if (wide && undo)
                IconButton(
                  tooltip: l10n.redo,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: _hist.canRedo ? () => _hist.redo() : null,
                ),
              _moreMenu(l10n, redo: !(wide && undo)),
              ...widget.actions,
            ],
          ),
        ),
      ),
    );
    // Hap ↔ kapsül ve sabit kalem hapı: aynı geçiş — alttan hafif büyüyerek
    // solar (taşmayan eğri; çıkış girişin 2/3'ü).
    final enter = AppMotion.of(context, AppMotion.short);
    final exit = AppMotion.of(context, AppMotion.exitOf(AppMotion.short));
    Widget swap(Widget child) => AnimatedSwitcher(
      duration: enter,
      reverseDuration: exit,
      switchInCurve: AppMotion.curveOf(context, AppMotion.emphasized),
      switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: Tween(begin: _kSwapScale, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.bottomCenter,
        children: [...previous, ?current],
      ),
      child: child,
    );
    final presets = open && InkToolMemory.presets.isNotEmpty;
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
          padding: EdgeInsets.fromLTRB(
            AppSpace.s,
            0,
            AppSpace.s,
            bottom,
          ),
          child: Listener(
            onPointerDown: (_) => _armIdle(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panelSlot(
                  () => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: surface(_options(), radius: AppRadius.xl),
                    ),
                  ),
                ),
                swap(
                  presets
                      ? Padding(
                          key: const ValueKey('pen-dock-presets'),
                          padding: const EdgeInsets.only(bottom: AppSpace.s),
                          child: surface(
                            SizedBox(
                              height: 44,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.xs,
                                ),
                                child: _presetRow(Axis.horizontal),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Hap ↔ kapsül: alttan büyüyerek/küçülerek yer değiştirir.
                swap(
                  open
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
          3 => _togglePin(),
          4 => _clearAll(),
          _ => showInkSettings(context, _ink),
        },
        itemBuilder: (_) => [
          if (widget.dock)
            PopupMenuItem(
              key: const ValueKey('pen-tray-clear'),
              value: 4,
              enabled: _hasInk,
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(l10n.clearInk),
              ),
            ),
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
            child: Text(_fingerLabel(l10n)),
          ),
          if (!_ink.eraser && !_ink.lasso)
            PopupMenuItem(
              key: const ValueKey('pen-tray-pin'),
              value: 3,
              child: ListTile(
                leading: Icon(
                  _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(_pinned ? l10n.unpin : l10n.inkPinPen),
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

  /// Sayfada (ya da etkin yüzeyde) mürekkep var mı.
  bool get _hasInk => _ink.ink.isNotEmpty || _hist.ink.isNotEmpty;

  /// TÜM YAZILARI KALDIR (kullanıcı isteği 2026-11-15): etkin yüzeyin bütün
  /// mürekkebi gider; [InkController.clear] geçmişe yazar, "Geri al"
  /// bildirimi ve üstteki geri al geri getirir (veri kaybı yok).
  void _clearAll() {
    final target = _hist.ink.isNotEmpty ? _hist : _ink;
    if (target.ink.isEmpty) return;
    final l10n = context.l10n;
    AppHaptics.heavy();
    target.clear();
    showUndoSnackBar(
      context,
      message: l10n.inkCleared,
      undoLabel: l10n.undo,
      // Arada yeni çizgi geldiyse onu değil, yalnız temizliği geri al.
      onUndo: () {
        if (target.ink.isEmpty) target.undo();
      },
    );
  }

  /// Kapsülün SİLGİSİ: tek dokunuş = silgi (seçiliyken ayarları), basılı
  /// tut = tüm yazıları kaldır. Mürekkep yokken soluk (yeri sabit kalır).
  Widget _eraserButton(AppLocalizations l10n, ColorScheme scheme) {
    final on = _ink.eraser;
    return Tooltip(
      message: l10n.inkEraserTooltip,
      child: Semantics(
        button: true,
        selected: on,
        child: InkResponse(
          key: const ValueKey('pen-tray-eraser'),
          radius: AppSpace.xl,
          onTap: () => _tap(PenTrayTool.eraser),
          onLongPress: _clearAll,
          child: SizedBox(
            width: _kDockSlot,
            height: _kDockSlot,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? scheme.primaryContainer : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s),
                  child: Icon(
                    Icons.auto_fix_normal_outlined,
                    size: AppIconSize.m,
                    color: on
                        ? scheme.onPrimaryContainer
                        : _hasInk
                        ? scheme.onSurfaceVariant
                        : scheme.onSurfaceVariant.withValues(
                            alpha: AppAlpha.disabled,
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

  /// Seçili kalem zaten sabit mi.
  bool get _pinned => InkToolMemory.presets.contains(_ink.currentPreset);

  /// Sabitle / kaldır (panelin iğnesi ve ⋯ menüsü — P63 PB3: sabitleme
  /// artık görünür yerde).
  void _togglePin() {
    if (!_pinned) return _pinCurrent();
    final p = _ink.currentPreset;
    InkToolMemory.savePresets([
      for (final x in InkToolMemory.presets)
        if (x != p) x,
    ]);
    AppHaptics.tick();
    _touched();
    setState(() {});
  }

  /// Ayar paneli; kalemlerde iğne düğmesiyle.
  Widget _options() => _Options(
    controller: _ink,
    tool: _current,
    pinned: _ink.eraser || _ink.lasso ? null : _pinned,
    onPin: _togglePin,
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
    AppHaptics.tick();
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
              AppHaptics.tick();
              _touched();
              _ink.applyPreset(p);
            },
            onRemove: () {
              AppHaptics.heavy();
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
    PenTrayTool.fountain: l10n.penFountain,
    PenTrayTool.marker: l10n.penMarker,
    PenTrayTool.highlighter: l10n.penHighlighter,
  };

  /// RENK düğmesi (sütun/şerit): seçili renk; dokununca panel. Kapsüldeki
  /// renk noktasıyla TEK bileşen.
  Widget _colorButton(AppLocalizations l10n) => _Swatch(
    key: const ValueKey('pen-tray-color'),
    color: _ink.color,
    size: 26,
    selected: _panel,
    tooltip: l10n.inkColor,
    onTap: _togglePanel,
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
      tooltip: _fingerLabel(l10n),
      isSelected: _ink.penOnly,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        _ink.penOnly
            ? Icons.draw_rounded
            : InkToolMemory.fingerErases
            ? Icons.auto_fix_normal_outlined
            : Icons.touch_app_outlined,
      ),
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

  /// Yalnız kalem aç/kapa etiketi; kapalıyken parmağın işi (K34: Siler da
  /// olabilir — kapatınca son seçilen Çizer/Siler'e döner).
  String _fingerLabel(AppLocalizations l10n) => _ink.penOnly
      ? l10n.inkPenOnlyOn
      : InkToolMemory.fingerErases
      ? l10n.inkFingerEraseOn
      : l10n.inkPenOnlyOff;

  /// [PenTray.controls] satırı: solda ipucu, sağda geçmiş ve ayarlar.
  Widget _controlRow(BuildContext context) {
    final l10n = context.l10n;
    final hint = _ink.lasso
        ? l10n.inkLassoHint
        : _ink.penOnly
        ? l10n.inkPenOnlyHint
        : widget.hint;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.l,
        end: AppSpace.xs,
        top: AppSpace.xxs,
      ),
      child: Row(
        children: [
          Expanded(
            child: hint == null
                ? const SizedBox.shrink()
                : Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.of(Theme.of(context)).meta,
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
    // Alt şerit: zeminden bir ton, sayfa tarafında (üstte) ince çizgi.
    return Material(
      color: scheme.surfaceContainerLow,
      shape: Border(
        top: BorderSide(color: AppTokens.fromTheme(Theme.of(context)).hairline),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.controls) _controlRow(context),
            // Panel yuvası tek adımda; içerik yalnız boyamada belirir.
            _panelSlot(_options),
            SizedBox(
              height: widget.trayHeight,
              child: Row(
                children: [
                  const SizedBox(width: AppSpace.s),
                  for (final tool in _tools)
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s,
                    ),
                    child: _colorButton(l10n),
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
const double _kDockGap = AppSpace.s;

/// Panel içeriğinin girişteki kayması (kendi boyunun oranı).
const double _kPanelRise = 0.08;

/// Hap ↔ kapsül geçişinin başlangıç ölçeği (taşmadan, hafif).
const double _kSwapScale = 0.92;

/// Geniş kapsülün eni ≈ sabit kısım (4 hızlı renk + gökkuşağı, iki ayraç,
/// geri al/yinele/⋯, kenar payları) + kalem ve eylem başına bir yuva. Bölme
/// bundan darsa kalemler eşit paylaşır, yinele ⋯'e iner (taşma yok).
const double _kWideDockFixed = 400, _kDockSlot = 48;

/// Seçili kalemin kalkış hareketi — kapsül ve şerit aynı kalıp (P63 PB3):
/// yalnız boyama (`AnimatedSlide`), taşmayan eğri; hareketi azaltta kısa.
Widget _liftSlide(
  BuildContext context, {
  required bool selected,
  required double rest,
  required double lifted,
  required Widget child,
}) => AnimatedSlide(
  duration: AppMotion.of(context, AppMotion.selection),
  curve: AppMotion.curveOf(context, AppMotion.emphasized),
  offset: Offset(0, selected ? lifted : rest),
  child: child,
);

/// Kapsüldeki kalemin kırpma kutusu ve kalem resmi (44 × 52 içinde 31 × 68).
const double _kDockToolW = 44, _kDockToolH = 52;
const double _kDockPenW = 31, _kDockPenH = 68;

/// Kapsülde kalemin üst kenarı: dururken 15, seçiliyken 3 dp aşağıda.
const double _kDockRest = 15 / _kDockPenH, _kDockLifted = 3 / _kDockPenH;

/// Kalem resminin çizim kutusu (pen_icons.dart ölçüsü).
const double _kPenArtW = 44, _kPenArtH = 96;

/// Kapsüldeki tek kalem: dik durur, yalnız üst kısmı görünür; seçili kalem
/// yukarı kalkar, ucu çizilen renktedir.
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
            width: _kDockToolW,
            height: _kDockToolH,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: _liftSlide(
                      context,
                      selected: selected,
                      rest: _kDockRest,
                      lifted: _kDockLifted,
                      child: SizedBox(
                        width: _kDockPenW,
                        height: _kDockPenH,
                        child: FittedBox(
                          child: SizedBox(
                            width: _kPenArtW,
                            height: _kPenArtH,
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

/// Renk yuvarlağı — tepsideki TEK renk noktası (kapsül, panel, sütun,
/// şerit, hap). Boy sabit; seçiliyse arada boşluk bırakan ince halka, rengi
/// solarak gelir (boy değişmez).
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

  /// Halka kalınlığı ve halkayla renk arası boşluk.
  static const double _ring = AppSpace.xxs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.selection),
      width: size + 4 * _ring,
      height: size + 4 * _ring,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.primary.withValues(alpha: 0),
          width: _ring,
        ),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Açık zeminde beyaz mürekkep de seçilebilsin.
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: _kSwatchEdge),
            width: _kSwatchEdgeW,
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

/// Renk noktasının ince kenarı (açık zeminde beyaz mürekkep görünsün).
const double _kSwatchEdge = 0.18, _kSwatchEdgeW = 0.8;

/// Şeritteki kalem: dururken resmin %24'ü aşağıda, seçiliyken %2.
const double _kTrayRest = 0.24, _kTrayLifted = 0.02;

/// Seçili aracın altındaki renk çizgisi (22 × 4).
const double _kTrayBarW = 22, _kTrayBarH = 4;

/// Tepsideki tek araç: seçiliyse yukarı kalkar, altında küçük renk
/// çizgisi belirir.
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
                _liftSlide(
                  context,
                  selected: selected,
                  rest: _kTrayRest,
                  lifted: _kTrayLifted,
                  child: SizedBox(
                    width: _kPenArtW,
                    height: _kPenArtH,
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
                    duration: AppMotion.of(context, AppMotion.quick),
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: _kTrayBarW,
                      height: _kTrayBarH,
                      margin: const EdgeInsets.only(bottom: AppSpace.xs),
                      decoration: BoxDecoration(
                        color: tool == PenTrayTool.eraser
                            ? scheme.primary
                            : ink,
                        borderRadius: BorderRadius.circular(AppRadius.hair),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(
                            alpha: AppAlpha.muted,
                          ),
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

/// Panelin satır ölçüleri: önizleme kâğıdı 44, kaydırıcı satırı 48, satır
/// başı simge kutusu 40, değer metni 36 (yazı 1.3'te de taşmaz).
const double _kPreviewH = 44, _kRowH = 48, _kLeadW = 40, _kValueW = 36;

/// Panel renk noktası boyu.
const double _kPanelSwatch = 28;

/// Tepsinin üstünde açılan ayar paneli — TEK KILIK (P63 PB3): gerçek çizgi
/// önizlemesi (+ iğne) · renkler · kalınlık · şeffaflık; araca göre şekiller,
/// kement ya da silgi.
class _Options extends StatelessWidget {
  const _Options({
    required this.controller,
    required this.tool,
    required this.pinned,
    required this.onPin,
  });

  final InkController controller;
  final PenTrayTool tool;

  /// Seçili kalem sabit mi; null = sabitlenemez (silgi, kement).
  final bool? pinned;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final pen = controller.pen;
    final recent = [
      for (final c in InkToolMemory.recentColors.take(4))
        if (!kInkPalette.any((p) => p.toARGB32() == c)) Color(c),
    ];
    Widget dot(Color color) => _Swatch(
      color: color,
      size: _kPanelSwatch,
      selected:
          !controller.eraser && controller.color.toARGB32() == color.toARGB32(),
      onTap: () {
        AppHaptics.tick();
        controller.setColor(color);
      },
    );

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
    // Kaydırıcı satırı: simge · kaydırıcı · değer (tabular rakam).
    Widget sliderRow({
      Key? key,
      required IconData icon,
      required String tooltip,
      required String value,
      required Widget slider,
    }) => SizedBox(
      key: key,
      height: _kRowH,
      child: Row(
        children: [
          SizedBox(
            width: _kLeadW,
            child: Tooltip(
              message: tooltip,
              child: Icon(
                icon,
                size: AppIconSize.m,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: slider),
          SizedBox(
            width: _kValueW,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              style: text.meta.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
    final opacity = pen.fixedOpacity ?? controller.opacity;
    final opacityText = '%${(opacity * 100).round()}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.s,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tool == PenTrayTool.shapes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.m),
              child: Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.s,
                children: [
                  ChoiceChip(
                    avatar: const Icon(
                      Icons.north_east_rounded,
                      size: AppIconSize.s,
                    ),
                    label: Text(l10n.inkArrow),
                    selected: controller.arrow,
                    onSelected: (_) => controller.setArrow(true),
                  ),
                  for (final s in InkShape.values)
                    radioChip(
                      ChoiceChip(
                        avatar: Icon(shapeIcon(s), size: AppIconSize.s),
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
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: controller.hasSelection
                  ? Wrap(
                      spacing: AppSpace.s,
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
                  : Text(l10n.inkLassoHint, style: text.meta),
            ),
          if (tool == PenTrayTool.eraser) ...[
            // Geri alınabilir: hata rengi değil.
            SizedBox(
              height: _kRowH,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.clearInk),
                  onPressed: controller.ink.isEmpty ? null : controller.clear,
                ),
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
            // GERÇEK ÇİZGİ ÖNİZLEMESİ: ekranda ne çıkacaksa o (fosforlu
            // saydam, dolma kalem incelip kalınlaşır); sağında iğne.
            Container(
              height: _kPreviewH,
              decoration: BoxDecoration(
                color: AppTokens.fromTheme(theme).card,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppTokens.fromTheme(theme).hairline),
              ),
              // İğne BAŞTA (plan: sağ uç): telefonda sağ kenardaki yüzen
              // kalem düğmesi paneli örtüyor, iğne altında kalıyordu
              // (G4 turu) — SB13 sabah bakılacak.
              child: Row(
                children: [
                  if (pinned case final p?)
                    IconButton(
                      key: const ValueKey('pen-panel-pin'),
                      tooltip: p ? l10n.unpin : l10n.inkPinPen,
                      isSelected: p,
                      visualDensity: VisualDensity.compact,
                      iconSize: AppIconSize.s,
                      icon: const Icon(Icons.push_pin_outlined),
                      selectedIcon: const Icon(Icons.push_pin),
                      onPressed: onPin,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.m,
                      ),
                      child: PenStrokePreview(
                        argb: controller.penColor.toARGB32(),
                        widthPx: controller.widthPx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final color in kInkPalette) dot(color),
                  for (final color in recent) dot(color),
                  PaletteButton(
                    title: l10n.paletteMore,
                    size: _kPanelSwatch,
                    current: kInkPalette.contains(controller.color)
                        ? null
                        : controller.color,
                    onPicked: controller.setColor,
                  ),
                ],
              ),
            ),
            sliderRow(
              icon: Icons.line_weight_rounded,
              tooltip: l10n.inkWidth,
              value: controller.widthPx.toStringAsFixed(0),
              slider: Slider(
                value: pen.clampWidth(controller.widthPx),
                min: pen.minWidth,
                max: pen.maxWidth,
                onChanged: controller.setWidth,
              ),
            ),
            // Şeffaflık da tepsinin kendi panelinde (kullanıcı isteği
            // 2026-11-08): ayrı ayar sayfasına gitmeden. Fosforlu sabit %40.
            sliderRow(
              key: const ValueKey('pen-tray-opacity'),
              icon: Icons.opacity_rounded,
              tooltip: l10n.inkOpacity,
              value: opacityText,
              slider: Slider(
                value: opacity,
                min: 0.1,
                divisions: 9,
                label: opacityText,
                onChanged: pen.fixedOpacity != null
                    ? null
                    : controller.setOpacity,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sabit kalem çipi: 40 × 40 dokunma alanı, 30 × 30 dairede kalemin
/// gerçek çizgisi (tür, renk, kalınlık bir bakışta).
const double _kChipTap = 40, _kChipDot = 30;

/// Sabitlenmiş kalem düğmesi: dairede kalemin GERÇEK çizgisi
/// (`PenStrokePreview`) — fosforlu saydam, keçeli dolu, tükenmez ince.
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
    // Sabit kalemde renk saydamlıksız kayıtlı: kalemin kendi saydamlığı.
    final argb = pen.apply(Color(preset.color)).toARGB32();
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
            width: _kChipTap,
            height: _kChipTap,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.selection),
                width: _kChipDot,
                height: _kChipDot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(
                            alpha: AppAlpha.strong,
                          ),
                    width: selected ? AppSpace.xxs : 1,
                  ),
                ),
                child: ClipOval(
                  child: PenStrokePreview(
                    argb: argb,
                    widthPx: preset.width,
                    compact: true,
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
