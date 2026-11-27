part of 'ink_layer.dart';

/// Kalem kipi açılınca gösterilecek kısa durum bildirimi (K34: Siler kipi
/// dahil parmağın gerçekten ne yaptığını söyler).
String penModeHintText(AppLocalizations l10n, FingerTool tool) =>
    switch (tool) {
      FingerTool.scroll || FingerTool.auto => l10n.penModePenOnlyOn,
      FingerTool.erase => l10n.inkFingerEraseOn,
      FingerTool.draw => l10n.penModePenOnlyOff,
    };

/// "Parmak: Otomatik · Kaydırır · Çizer · Siler" (K34, F63.6) — kalem ayarları
/// sayfası ve Ayarlar → Kalem ortak. Yalnız seçili kipin kısa açıklamasını
/// gösterir (uzun duvar metni yerine anında anlaşılır tek satır).
class InkFingerToolPicker extends StatefulWidget {
  const InkFingerToolPicker({super.key, required this.onChanged});

  final void Function(FingerTool) onChanged;

  @override
  State<InkFingerToolPicker> createState() => _InkFingerToolPickerState();
}

class _InkFingerToolPickerState extends State<InkFingerToolPicker> {
  String _description(AppLocalizations l10n) => switch (InkToolMemory.fingerTool) {
    FingerTool.auto => InkToolMemory.effectiveFingerTool == FingerTool.scroll
        ? l10n.inkFingerAutoNowScroll
        : l10n.inkFingerAutoNowDraw,
    FingerTool.scroll => l10n.inkPenOnlyHint,
    FingerTool.draw => l10n.inkPenOnlyOff,
    FingerTool.erase => l10n.inkFingerEraseOn,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.back_hand_outlined, size: AppIconSize.m),
          title: Text(l10n.inkFingerToolTitle),
          subtitle: Text(_description(l10n)),
        ),
        // Dört seçenek dar telefonda simgeli sığmaz: 440 dp altında yalnız
        // yazı (ayar sayfası; editörde değil — LayoutBuilder burada ucuz).
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s),
          child: LayoutBuilder(
            builder: (context, box) {
              final icons = box.maxWidth >= 440;
              ButtonSegment<FingerTool> seg(
                FingerTool value,
                Widget icon,
                String label,
              ) => ButtonSegment(
                value: value,
                icon: icons ? icon : null,
                label: Text(label, maxLines: 1, softWrap: false),
              );
              return SegmentedButton<FingerTool>(
                key: const ValueKey('ink-finger-tool'),
                showSelectedIcon: false,
                segments: [
                  seg(
                    FingerTool.auto,
                    const Icon(Icons.auto_awesome_outlined, size: AppIconSize.s),
                    l10n.inkFingerAuto,
                  ),
                  seg(
                    FingerTool.scroll,
                    const Icon(Icons.swipe_vertical_outlined, size: AppIconSize.s),
                    l10n.inkFingerScroll,
                  ),
                  seg(
                    FingerTool.draw,
                    const Icon(Icons.gesture_rounded, size: AppIconSize.s),
                    l10n.inkFingerDraw,
                  ),
                  seg(
                    FingerTool.erase,
                    const EraserGlyph(size: AppIconSize.s),
                    l10n.inkFingerErase,
                  ),
                ],
                selected: {InkToolMemory.fingerTool},
                onSelectionChanged: (s) =>
                    setState(() => widget.onChanged(s.first)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class InkSettingsSheet extends StatelessWidget {
  const InkSettingsSheet({super.key, required this.controller});

  final InkController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final pen = controller.pen;
    final fixed = pen.fixedOpacity;
    final opacity = fixed ?? controller.opacity;
    final opacityText = '%${(opacity * 100).round()}';

    Widget padRow(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
      child: child,
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          0,
          AppSpace.l,
          AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.inkSettings,
              padding: const EdgeInsets.only(bottom: AppSpace.m),
            ),
            // 1. ÖNİZLEME VE KALEM AYARI
            GroupCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.m,
                    AppSpace.l,
                    AppSpace.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // GERÇEK ÇİZGİ ÖNİZLEMESİ (koyu temada da uyumlu kâğıt)
                      Container(
                        height: 56,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.m,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          border: Border.all(color: tokens.hairline),
                        ),
                        child: PenStrokePreview(
                          argb: controller.penColor.toARGB32(),
                          widthPx: controller.widthPx,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Text(l10n.inkWidth, style: text.label),
                          ),
                          Expanded(
                            child: Slider(
                              value: pen.clampWidth(controller.widthPx),
                              min: pen.minWidth,
                              max: pen.maxWidth,
                              label: controller.widthPx.toStringAsFixed(0),
                              onChanged: controller.setWidth,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              controller.widthPx.toStringAsFixed(0),
                              textAlign: TextAlign.end,
                              style: text.meta.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Text(l10n.inkOpacity, style: text.label),
                          ),
                          Expanded(
                            child: Slider(
                              // Fosforlu / dolma kalemin saydamlığı sabit (türü
                              // ondan okunuyor).
                              value: opacity,
                              min: 0.1,
                              divisions: 9,
                              label: opacityText,
                              onChanged: fixed != null
                                  ? null
                                  : controller.setOpacity,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              opacityText,
                              textAlign: TextAlign.end,
                              style: text.meta.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (InkToolMemory.recentColors.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(l10n.inkRecentColors, style: text.meta),
                        const SizedBox(height: AppSpace.s),
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.s,
                          children: [
                            for (final c in InkToolMemory.recentColors)
                              InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                onTap: () => controller.setColor(Color(c)),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: controller.color.toARGB32() == c
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                      width: controller.color.toARGB32() == c
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            // 2. PARMAK DAVRANIŞI
            GroupCard(
              children: [
                padRow(
                  InkFingerToolPicker(
                    key: const ValueKey('ink-finger-tool'),
                    onChanged: controller.setFingerTool,
                  ),
                ),
                padRow(_AutoStylusSwitch()),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            // 3. AKILLI ÇİZİM VE YARDIMCILAR
            GroupCard(
              children: [
                padRow(
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.line_weight_rounded,
                      size: AppIconSize.m,
                    ),
                    title: Text(l10n.inkPressureTitle),
                    subtitle: Text(l10n.inkPressureInfo),
                    value: controller.pressure,
                    onChanged: controller.setPressure,
                  ),
                ),
                padRow(
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.category_outlined,
                      size: AppIconSize.m,
                    ),
                    title: Text(l10n.inkShapeSnapTitle),
                    subtitle: Text(l10n.inkShapeSnapInfo),
                    value: controller.shapeSnap,
                    onChanged: controller.setShapeSnap,
                  ),
                ),
                padRow(
                  SwitchListTile(
                    key: const ValueKey('ink-shape-suggest'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(
                      Icons.auto_fix_high_rounded,
                      size: AppIconSize.m,
                    ),
                    title: Text(l10n.inkShapeSuggestTitle),
                    subtitle: Text(l10n.inkShapeSuggestInfo),
                    value: controller.shapeSuggest,
                    onChanged: controller.setShapeSuggest,
                  ),
                ),
                padRow(
                  StatefulBuilder(
                    builder: (context, setLocal) => SwitchListTile(
                      key: const ValueKey('ink-mark-fix'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(
                        Icons.rule_rounded,
                        size: AppIconSize.m,
                      ),
                      title: Text(l10n.inkMarkFixTitle),
                      subtitle: Text(l10n.inkMarkFixInfo),
                      value: InkToolMemory.markFix ?? false,
                      onChanged: (v) =>
                          setLocal(() => InkToolMemory.saveMarkFix(v)),
                    ),
                  ),
                ),
                padRow(
                  StatefulBuilder(
                    builder: (context, setLocal) => SwitchListTile(
                      key: const ValueKey('ink-quick-swap-setting'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(
                        Icons.swap_horiz_rounded,
                        size: AppIconSize.m,
                      ),
                      title: Text(l10n.inkQuickSwapTitle),
                      subtitle: Text(l10n.inkQuickSwapInfo),
                      value: InkToolMemory.quickSwap,
                      onChanged: (v) =>
                          setLocal(() => InkToolMemory.saveQuickSwap(v)),
                    ),
                  ),
                ),
                padRow(
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const EraserGlyph(),
                    title: Text(l10n.inkPartialEraserTitle),
                    subtitle: Text(l10n.inkPartialEraserInfo),
                    value: controller.partialEraser,
                    onChanged: controller.setPartialEraser,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            GroupCard(
              children: [
                padRow(
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.edit_note,
                      size: AppIconSize.m,
                    ),
                    title: Text(l10n.inkStylusTipsTitle),
                    subtitle: Text(l10n.inkStylusTips),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                onPressed: controller.ink.isEmpty
                    ? null
                    : () {
                        controller.clear();
                        Navigator.pop(context);
                      },
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: AppIconSize.s,
                ),
                label: Text(l10n.clearInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Çizim modunda İKİ PARMAK yakınlaştırma + kaydırmayı görüntüleyicinin
/// dönüşüm matrisine kendisi uygular. Görüntüleyicinin kendi jest tanıyıcısına
/// güvenilmez: hem Flutter hem pdfrx InteractiveViewer'ı, mesafe değişmeden
/// birlikte hareket eden iki parmağı "pan" sayar ve `panEnabled:false`'ta
/// (çizim modu) tamamen yok sayar — "yazarken kaydıramıyorum" hatasının kökü.
///
/// Katman jest arenasına girmeyen [Listener] ile TÜM parmakları (sayfa dışı —
/// kenar boşluğu — dahil) sayar; ikinci parmak iner inmez [InkController.beginNav]
/// ile çizimi askıya alır ve odak/mesafe farkından matrisi günceller. Çizim
/// modunda görüntüleyicinin `panEnabled` VE `scaleEnabled`'ı kapatılmalıdır ki
/// jest çifte işlenmesin.
class InkNavLayer extends StatefulWidget {
  const InkNavLayer({
    super.key,
    required this.enabled,
    required this.controller,
    required this.getMatrix,
    required this.setMatrix,
    required this.minScale,
    required this.maxScale,
    this.clampToBounds = false,
    required this.child,
  });

  /// Yalnız çizim modunda aktif; kapalıyken dokunuşlara hiç karışmaz.
  final bool enabled;

  final InkController controller;

  /// Görüntüleyicinin güncel dönüşümü (hazır değilse null dönebilir).
  final Matrix4? Function() getMatrix;

  /// Yeni dönüşümü görüntüleyiciye yazar (görüntüleyici kendi sınırlarını
  /// ayrıca uygulayabilir — pdfrx `value` setter'ı konumu normalleştirir).
  final ValueChanged<Matrix4> setMatrix;

  /// Toplam ölçek bu aralıkta tutulur.
  final double minScale;
  final double maxScale;

  /// true ise çeviri, içeriğin (bu katmanla aynı boyutta varsayılır) görünür
  /// alanı örtmesini koruyacak şekilde kırpılır (Flutter InteractiveViewer'lı
  /// slayt görünümü — doğrudan controller yazımı IV sınır denetiminden geçmez).
  final bool clampToBounds;

  final Widget child;

  @override
  State<InkNavLayer> createState() => _InkNavLayerState();
}

class _InkNavLayerState extends State<InkNavLayer> {
  /// Basılı parmaklar: pointer id → katman-yerel konum.
  final Map<int, Offset> _pts = {};
  Offset? _lastFocal;
  double? _lastDist;

  void _reset() {
    _lastFocal = null;
    _lastDist = null;
  }

  (Offset, double) _focalAndDist() {
    final pts = _pts.values.toList();
    final focal = (pts[0] + pts[1]) / 2;
    return (focal, (pts[0] - pts[1]).distance);
  }

  /// Kalem (stylus) gezinmeye karışmaz; kalem yazarken ekrana değen parmak
  /// (avuç içi) da gezinme sayılmaz.
  bool _ignored(PointerEvent e) =>
      e.kind == PointerDeviceKind.stylus ||
      e.kind == PointerDeviceKind.invertedStylus ||
      e.kind == PointerDeviceKind.mouse ||
      widget.controller.isPalm(e.kind);

  void _down(PointerDownEvent e) {
    if (!widget.enabled || _ignored(e)) return;
    _pts[e.pointer] = e.localPosition;
    if (_pts.length == 1 && widget.controller.penOnly) {
      // "Yalnız kalem": tek parmak KAYDIRIR (çizmez).
      _lastFocal = e.localPosition;
      _lastDist = null;
    } else if (_pts.length == 2) {
      // "Yalnız kalem"de parmak zaten çizmiyor; iptal edilecek çizgi kalemin
      // olabilir — dokunma.
      if (!widget.controller.penOnly) widget.controller.beginNav();
      final (focal, dist) = _focalAndDist();
      _lastFocal = focal;
      _lastDist = dist;
    } else if (_pts.length > 2) {
      _reset();
    }
  }

  void _move(PointerMoveEvent e) {
    if (!widget.enabled || !_pts.containsKey(e.pointer)) return;
    _pts[e.pointer] = e.localPosition;
    if (_pts.length == 1 && widget.controller.penOnly) {
      final matrix = widget.getMatrix();
      final last = _lastFocal;
      _lastFocal = e.localPosition;
      if (matrix == null || last == null) return;
      final pan = e.localPosition - last;
      var m = Matrix4.translationValues(pan.dx, pan.dy, 0).multiplied(matrix);
      if (widget.clampToBounds) m = _clamp(m);
      widget.setMatrix(m);
      return;
    }
    if (_pts.length != 2) return;
    final matrix = widget.getMatrix();
    if (matrix == null) return;
    final (focal, dist) = _focalAndDist();
    final lastFocal = _lastFocal, lastDist = _lastDist;
    _lastFocal = focal;
    _lastDist = dist;
    if (lastFocal == null || lastDist == null || lastDist <= 0 || dist <= 0) {
      return;
    }
    final scale = matrix.getMaxScaleOnAxis();
    // Toplam ölçek [minScale, maxScale] dışına çıkmayacak kadar ölçekle.
    final k =
        (scale * (dist / lastDist)).clamp(widget.minScale, widget.maxScale) /
        scale;
    final pan = focal - lastFocal;
    var m = Matrix4.translationValues(pan.dx, pan.dy, 0).multiplied(matrix);
    if (k != 1) {
      m = Matrix4.translationValues(focal.dx, focal.dy, 0)
          .multiplied(Matrix4.diagonal3Values(k, k, 1))
          .multiplied(Matrix4.translationValues(-focal.dx, -focal.dy, 0))
          .multiplied(m);
    }
    if (widget.clampToBounds) m = _clamp(m);
    widget.setMatrix(m);
  }

  void _up(int pointer) {
    if (_pts.remove(pointer) == null) return;
    if (_pts.length == 1 && widget.controller.penOnly) {
      // İki parmaktan biri kalktı: kalan parmakla kaydırma sürer.
      widget.controller.endNav();
      _lastFocal = _pts.values.first;
      _lastDist = null;
    } else if (_pts.length < 2) {
      widget.controller.endNav();
      _reset();
    } else {
      final (focal, dist) = _focalAndDist();
      _lastFocal = focal;
      _lastDist = dist;
    }
  }

  /// İçerik bu katmanla aynı boyutta: çeviri, görüntü alanında boşluk
  /// açılmayacak aralığa kırpılır.
  Matrix4 _clamp(Matrix4 m) {
    final box = context.size;
    if (box == null || box.isEmpty) return m;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final x = t.x.clamp(box.width * (1 - s), 0.0).toDouble();
    final y = t.y.clamp(box.height * (1 - s), 0.0).toDouble();
    return Matrix4.translationValues(
      x,
      y,
      0,
    ).multiplied(Matrix4.diagonal3Values(s, s, 1));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (e) => _up(e.pointer),
      onPointerCancel: (e) => _up(e.pointer),
      child: widget.child,
    );
  }
}

/// Bir sayfa/slaydın çizgilerini oranlardan ekran boyutuna ölçekleyerek çizer.
class InkPainter extends CustomPainter {
  InkPainter(List<InkStroke> strokes, this.page, {this.revision = 0})
    // SAYFA SÜZGECİ ÖNCEDEN: `paint` her karede TÜM belgenin çizgilerini
    // geziyordu (başka sayfalarınkini de). Uzun bir çizim oturumunda her yeni
    // nokta, o ana kadarki bütün noktaların yeniden taranması demekti —
    // "kasma birikip artıyor" tarifinin çizim tarafındaki karşılığı.
    : strokes = [
        for (final s in strokes)
          if (s.page == page) s,
      ];

  final List<InkStroke> strokes;
  final int page;

  /// Denetleyicinin değişim sayacı: [shouldRepaint] buna bakar.
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      paintInkStroke(canvas, size, s);
    }
  }

  /// KÖK NEDEN: burası KOŞULSUZ `true` döndürüyordu — çizgiler hiç
  /// değişmemişken bile (görüntüleyicinin her yeniden çiziminde) tüm katman
  /// yeniden rasterize ediliyordu.
  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) =>
      oldDelegate.revision != revision || oldDelegate.page != page;
}

/// "Kalemi otomatik algıla" (cihaz tercihi, [InkToolMemory.autoStylus]):
/// denetleyiciye bağlı değil — editör kalem dokunuşunda buna bakar.
class _AutoStylusSwitch extends StatefulWidget {
  @override
  State<_AutoStylusSwitch> createState() => _AutoStylusSwitchState();
}

class _AutoStylusSwitchState extends State<_AutoStylusSwitch> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.edit_note),
      title: Text(l10n.inkAutoStylusTitle),
      subtitle: Text(l10n.inkAutoStylusInfo),
      value: InkToolMemory.autoStylus,
      onChanged: (value) => setState(() => InkToolMemory.saveAutoStylus(value)),
    );
  }
}
