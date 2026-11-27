part of 'pen_tray.dart';

/// "Silgi açık" hapı (kullanıcı isteği 2026-11-22: silgi açıkken kalemin
/// yazmadığı fark edilmiyordu).
class EraserOnBadge extends StatelessWidget {
  const EraserOnBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const ValueKey('pen-eraser-on'),
      decoration: ShapeDecoration(
        color: scheme.secondaryContainer,
        shape: StadiumBorder(
          side: BorderSide(
            color: scheme.secondary.withValues(alpha: AppAlpha.soft),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.m,
          vertical: AppSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.xs,
          children: [
            EraserGlyph(
              size: AppIconSize.xs,
              filled: true,
              color: scheme.onSecondaryContainer,
            ),
            Text(
              context.l10n.eraserOn,
              style: AppText.of(theme).badge.copyWith(
                color: scheme.onSecondaryContainer,
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

/// Kapsüldeki kalemin kırpma kutusu ve kalem resmi (44 × 56 içinde 31 × 68).
const double _kDockToolW = 44, _kDockToolH = 56;
const double _kDockPenW = 31, _kDockPenH = 68;

/// Kapsülde kalemin üst kenarı: dururken 17, seçiliyken 4 dp aşağıda.
const double _kDockRest = 17 / _kDockPenH, _kDockLifted = 4 / _kDockPenH;

/// Kalem resminin çizim kutusu (pen_icons.dart ölçüsü).
const double _kPenArtW = 44, _kPenArtH = 96;

/// Kapsüldeki tek kalem: dik durur, yalnız üst kısmı görünür; seçili kalem
/// yumuşak tonlu yuvada yukarı kalkar, altında renk çizgisi belirir.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
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
                  if (selected)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xxs,
                          vertical: AppSpace.xs,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: AppAlpha.soft,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                        ),
                      ),
                    ),
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
                  if (selected)
                    Positioned(
                      bottom: AppSpace.xs,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tool == PenTrayTool.eraser
                              ? scheme.primary
                              : ink,
                          borderRadius: BorderRadius.circular(AppRadius.hair),
                        ),
                        child: const SizedBox(width: 16, height: 3),
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
        width: math.max(size + 14, 38),
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

/// Panelin satır ölçüleri: önizleme kâğıdı 44, kaydırıcı satırı 42, satır
/// başı simge kutusu 32, değer metni 40 (yazı 1.3'te de taşmaz).
const double _kPreviewH = 44, _kRowH = 42, _kLeadW = 32, _kValueW = 40;

/// Panel renk noktası boyu.
const double _kPanelSwatch = 28;

/// Tepsinin üstünde açılan ayar paneli — TEK KILIK (P63 PB3): araç başlığı
/// + iğne · gerçek çizgi önizlemesi · hızlı kalınlık noktaları · renkler ·
/// kalınlık · şeffaflık; araca göre şekiller, kement ya da silgi.
class _Options extends StatelessWidget {
  const _Options({
    required this.controller,
    required this.tool,
    required this.toolLabel,
    required this.pinned,
    required this.onPin,
  });

  final InkController controller;
  final PenTrayTool tool;
  final String toolLabel;

  /// Seçili kalem sabit mi; null = sabitlenemez (silgi, kement).
  final bool? pinned;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
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
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    );
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
                size: AppIconSize.s,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(data: sliderTheme, child: slider),
          ),
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
    final widthVal = pen.clampWidth(controller.widthPx);
    final widthPresets = [
      pen.minWidth,
      pen.minWidth + (pen.maxWidth - pen.minWidth) * 0.25,
      pen.minWidth + (pen.maxWidth - pen.minWidth) * 0.58,
      pen.maxWidth,
    ];

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
            Row(
              children: [
                EraserGlyph(
                  size: AppIconSize.s,
                  filled: true,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text(
                    toolLabel,
                    style: text.label.copyWith(fontWeight: AppWeight.strong),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: controller.ink.isEmpty ? null : controller.clear,
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    size: AppIconSize.s,
                  ),
                  label: Text(l10n.clearInk),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
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
            // ÜST BAŞLIK: iğne (solda, sağdaki yüzen kalem düğmesinden uzak —
            // SB13) · araç adı · hızlı kalınlık noktaları.
            Row(
              children: [
                if (pinned case final p?) ...[
                  IconButton(
                    key: const ValueKey('pen-panel-pin'),
                    tooltip: p ? l10n.unpin : l10n.inkPinPen,
                    isSelected: p,
                    visualDensity: VisualDensity.compact,
                    iconSize: AppIconSize.s,
                    style: IconButton.styleFrom(
                      backgroundColor: p
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHigh,
                      foregroundColor: p
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.push_pin_outlined),
                    selectedIcon: const Icon(Icons.push_pin),
                    onPressed: onPin,
                  ),
                  const SizedBox(width: AppSpace.s),
                ],
                Expanded(
                  child: Text(
                    toolLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.label.copyWith(fontWeight: AppWeight.strong),
                  ),
                ),
                // Hızlı kalınlık noktaları: tek dokunuşla ince/orta/kalın.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widthPresets.length; i++)
                      _WidthDot(
                        size: 6.0 + i * 3.0,
                        color: controller.color,
                        selected: (widthVal - widthPresets[i]).abs() <
                            (pen.maxWidth - pen.minWidth) * 0.12,
                        onTap: () {
                          AppHaptics.tick();
                          controller.setWidth(widthPresets[i]);
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            // GERÇEK ÇİZGİ ÖNİZLEMESİ: ekranda ne çıkacaksa o (fosforlu
            // saydam, dolma kalem incelip kalınlaşır).
            Container(
              height: _kPreviewH,
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: tokens.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                child: PenStrokePreview(
                  argb: controller.penColor.toARGB32(),
                  widthPx: controller.widthPx,
                ),
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
                value: widthVal,
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

/// Hızlı kalınlık düğmesi: tek dokunuşta ince/orta/kalın geçişi.
class _WidthDot extends StatelessWidget {
  const _WidthDot({
    required this.size,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double size;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      radius: AppSpace.l,
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? scheme.primaryContainer : null,
            ),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? scheme.primary : color,
                    border: Border.all(
                      color: scheme.onSurface.withValues(alpha: _kSwatchEdge),
                      width: _kSwatchEdgeW,
                    ),
                  ),
                  child: SizedBox.square(dimension: size),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sabit kalem çipi: 36 × 36 dokunma alanı, 28 × 28 dairede kalemin
/// gerçek çizgisi (tür, renk, kalınlık bir bakışta).
const double _kChipTap = 36, _kChipDot = 28;

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
