part of 'format_bar.dart';

/// Tepsi açan hap: yazı + ▾ (açıkken ▴ ve kenarlık). Odak istemez.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    super.key,
    required this.open,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.cycles = false,
  });

  final bool open;

  /// Basış tepsi açmaz, SIRADAKİ değere geçer: ▾ yerine ⇅ simgesi.
  final bool cycles;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        expanded: cycles ? null : open,
        child: Material(
          color: open ? scheme.primaryContainer : tokens.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
            side: BorderSide(
              color: open ? scheme.primary : tokens.hairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 38,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpace.s,
                  end: AppSpace.xs,
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: enabled
                        ? (open ? scheme.onPrimaryContainer : scheme.onSurface)
                        : scheme.onSurface.withValues(alpha: AppAlpha.disabled),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Center(child: child)),
                      if (enabled)
                        Icon(
                          cycles
                              ? Icons.unfold_more_rounded
                              : open
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: cycles ? AppIconSize.xs : AppIconSize.m,
                          color: open
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                    ],
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

/// Renk hapının simgesi: "A" altında etkin yazı rengi, yanında vurgu
/// kalemi altında etkin vurgu — hangi rengin işlediği tek bakışta.
class _ColorGlyph extends StatelessWidget {
  const _ColorGlyph({required this.text, required this.highlight});

  final Color? text;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget stripe(Color? color) => Container(
      width: 16,
      height: 3,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: color ?? scheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppRadius.hair),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_color_text, size: AppIconSize.xs),
            stripe(text),
          ],
        ),
        const SizedBox(width: AppSpace.s),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.border_color_outlined, size: AppIconSize.xs),
            stripe(highlight),
          ],
        ),
      ],
    );
  }
}

/// Maddenin alt çizgisi: beş türün GERÇEK çizimli seçicisi + ayar (P63 PB6;
/// bkz. [FormatBar.dividerKind]). Tepsi boyu 42 sabit.
class _DividerRow extends StatelessWidget {
  const _DividerRow({
    required this.kind,
    required this.style,
    required this.onPick,
    required this.onStyle,
  });

  final String kind;
  final ItemDivider? style;
  final ValueChanged<String> onPick;
  final VoidCallback? onStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
        child: Row(
          children: [
            Text(l10n.itemMenuLine, style: AppText.of(theme).label),
            const SizedBox(width: AppSpace.s),
            Expanded(
              child: DividerKindPicker(
                selected: kind,
                style: style,
                compact: true,
                scheme: theme.colorScheme,
                onPick: onPick,
              ),
            ),
            if (onStyle != null)
              IconButton(
                key: const ValueKey('format-divider-style'),
                tooltip: l10n.dividerSettings,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune_rounded, size: AppIconSize.m),
                onPressed: onStyle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tepsi satırı: sabit yükseklik, yan pay.
class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
      child: Row(children: children),
    ),
  );
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(width: AppSpace.s);
}

/// B · I · U kapsül içi eşit paylı düğme.
class _Btn extends StatelessWidget {
  const _Btn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final fg = active
        ? scheme.onPrimaryContainer
        : enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: AppAlpha.disabled);
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: active,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.s),
            onTap: onTap,
            child: Ink(
              height: 36,
              decoration: BoxDecoration(
                color: active ? scheme.primaryContainer : null,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Icon(icon, size: AppIconSize.m, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkinci sıradaki sabit genişlikli simge düğmesi.
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.open = false,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final bool open;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final fg = active || open
        ? scheme.onPrimaryContainer
        : enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: AppAlpha.disabled);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: active || open,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: onTap,
          child: Ink(
            width: compact ? 32 : 36,
            height: 36,
            decoration: BoxDecoration(
              color: active || open ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: open ? Border.all(color: scheme.primary) : null,
            ),
            child: Icon(icon, size: AppIconSize.m, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Seçilebilir hap (yazı tipi). Odak istemez.
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
      child: Material(
        color: selected ? scheme.primaryContainer : tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(
            color: selected ? scheme.primary : tokens.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renk sırasının hedef anahtarı: "A" (yazı rengi) ve vurgu kalemi. Her
/// birinin altındaki şerit o an etkin rengini gösterir.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.textColor,
    required this.highlightColor,
    required this.onChanged,
  });

  final _ColorMode mode;
  final Color? textColor;
  final Color? highlightColor;
  final ValueChanged<_ColorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final l10n = context.l10n;
    Widget segment(
      _ColorMode value,
      IconData icon,
      String tooltip,
      Color? stripe,
    ) {
      final selected = mode == value;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          key: ValueKey('format-mode-${value.name}'),
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: () => onChanged(value),
          child: Ink(
            width: 38,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: AppIconSize.s,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppSpace.xxs),
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: stripe ?? scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.hair),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.xxs),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: tokens.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            _ColorMode.text,
            Icons.format_color_text,
            l10n.formatTextColor,
            textColor,
          ),
          segment(
            _ColorMode.highlight,
            Icons.border_color_outlined,
            l10n.formatHighlight,
            highlightColor,
          ),
        ],
      ),
    );
  }
}

/// Tepsinin kabı: aynı iç pay, panelden ince çizgiyle ayrık.
class _TrayBox extends StatelessWidget {
  const _TrayBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.m,
        AppSpace.s,
        AppSpace.m,
        AppSpace.xs,
      ),
      color: theme.colorScheme.surfaceContainer,
      child: child,
    );
  }
}

/// Renk sırası: [Kaldır] + hazır tonlar + tam palet, eşit bölünmüş — dar
/// ekranda da son düğme (tam palet) kenara taşmaz.
class _ColorRow extends StatelessWidget {
  const _ColorRow({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.activeIndex,
    required this.filled,
    required this.onPick,
    required this.onRemove,
  });

  final String keyPrefix;
  final String label;
  final int? activeIndex;
  final bool filled;
  final ValueChanged<int> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final palette = NoteColors.richPalette;
    // Dairelerin ADI (F12.5): beşi de "Yazı rengi" diye okunuyordu.
    final names = richPaletteNames(l10n);
    final index = activeIndex;
    final custom = isCustomRichColor(index) ? Color(index!) : null;

    Widget slot(Widget child) => Expanded(child: Center(child: child));

    Widget circle({
      required Key key,
      required String tooltip,
      required VoidCallback onTap,
      Color? fill,
      Gradient? gradient,
      Color? border,
      double borderWidth = 2,
      Widget? child,
    }) => Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        // Dokunma alanı 36 dp; görünen daire 28.
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                gradient: gradient,
                border: border == null
                    ? null
                    : Border.all(color: border, width: borderWidth),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < palette.length; i++)
          slot(
            circle(
              key: ValueKey('$keyPrefix-${i + 1}'),
              tooltip: i < names.length ? '$label: ${names[i]}' : label,
              onTap: () => onPick(i + 1),
              fill: filled ? palette[i].withValues(alpha: AppAlpha.muted) : palette[i],
              border: filled ? palette[i] : null,
              borderWidth: index == i + 1 ? 3.5 : 2,
              child: index == i + 1
                  ? Icon(
                      Icons.check,
                      size: AppIconSize.xs,
                      color: filled ? palette[i] : Colors.white,
                    )
                  : null,
            ),
          ),
        // TAM PALET: hazır tonlar + özel renk (bkz. color_palette.dart).
        // Özel renk etkinse düğme o renkle dolu ve tikli.
        slot(
          circle(
            key: ValueKey('$keyPrefix-palette'),
            tooltip: l10n.paletteMore,
            onTap: () async {
              final picked = await showColorPaletteSheet(
                context,
                title: label,
                current: custom ?? _FormatBarState._resolve(index),
              );
              if (picked != null) onPick(picked.toARGB32() | 0xFF000000);
            },
            fill: custom,
            gradient: custom != null
                ? null
                : FixedColors.rainbowSweep,
            child: Icon(
              custom != null ? Icons.check : AppIcons.color,
              size: AppIconSize.xs,
              color: custom != null ? FixedColors.inkOn(custom) : Colors.white,
            ),
          ),
        ),
        // KALDIR — hep aynı yerde (biçim yokken soluk): "renk verdim, nasıl
        // geri alırım" sorusunun cevabı her açılışta aynı yerde.
        slot(
          circle(
            key: ValueKey('$keyPrefix-remove'),
            tooltip: l10n.formatRemove,
            onTap: onRemove,
            border: scheme.outline,
            borderWidth: 1.5,
            child: Icon(
              Icons.format_color_reset,
              size: AppIconSize.xs,
              color: index == null
                  ? scheme.onSurfaceVariant.withValues(alpha: AppAlpha.muted)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// YAZI TİPİ tepsisi: yazı tipleri (her biri kendi yazı tipiyle yazılı,
/// yatay kayar) + boyut ve şeffaflık için ince ayar kaydırıcıları.
class _FontTray extends StatelessWidget {
  const _FontTray({
    required this.family,
    required this.onFont,
    required this.size,
    required this.opacity,
    required this.onSlide,
    required this.onSlideEnd,
  });

  final String? family;
  final ValueChanged<String?> onFont;
  final double size;
  final double opacity;
  final void Function(_Slide slide, double value) onSlide;
  final void Function(_Slide slide, double value) onSlideEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = family ?? '';
    preloadRemainingNoteFonts();
    return _TrayBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kNoteFonts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 2),
              itemBuilder: (context, i) {
                final font = kNoteFonts[i];
                return _Chip(
                  key: ValueKey('format-font-${font.id ?? 'default'}'),
                  selected: (font.id ?? '') == current,
                  onTap: () {
                    // PL10: paketten çıkarılan aileyi kullanıcı seçti → indir.
                    if (font.downloadable) {
                      unawaited(fontDownloads.ensure(font.id!, retry: true));
                    }
                    onFont(font.id);
                  },
                  child: ListenableBuilder(
                    listenable: fontDownloads,
                    builder: (context, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          noteFontLabel(
                            font.id,
                            defaultLabel: l10n.noteFontDefault,
                            serifLabel: l10n.noteFontSerif,
                            monoLabel: l10n.noteFontMono,
                          ),
                          style: applyNoteFont(
                            AppText.of(Theme.of(context)).body,
                            font.id,
                            fetch: false,
                          ),
                        ),
                        if (font.downloadable &&
                            !fontDownloads.isReady(font.id!))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Icon(
                              fontDownloads.isFetching(font.id!)
                                  ? Icons.downloading
                                  : Icons.cloud_download_outlined,
                              key: ValueKey('format-font-cloud-${font.id}'),
                              size: AppIconSize.xs,
                              semanticLabel: l10n.fontNeedsDownload,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          _SliderRow(
            key: const ValueKey('format-size-slider'),
            icon: Icons.format_size,
            label: l10n.noteTextSize,
            value: size,
            min: _kScaleMin,
            max: _kScaleMax,
            onChanged: (v) => onSlide(_Slide.size, v),
            onChangeEnd: (v) => onSlideEnd(_Slide.size, v),
          ),
          _SliderRow(
            key: const ValueKey('format-opacity-slider'),
            icon: Icons.opacity,
            label: l10n.noteTextOpacity,
            value: opacity,
            min: 0.3,
            max: 1.0,
            onChanged: (v) => onSlide(_Slide.opacity, v),
            onChangeEnd: (v) => onSlideEnd(_Slide.opacity, v),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Tooltip(
            message: label,
            child: SizedBox(
              width: 28,
              child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '%${(value * 100).round()}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Biçim çubuğunun uygulayacağı hedef: o an odaklı metin alanı.
///
/// Gövde ve her liste maddesi ayrı denetleyici kullanıyor; çubuk hangisine
/// yazacağını bilmeli. Odak değiştikçe editör burayı tazeler.
@immutable
class FormatTarget {
  const FormatTarget({
    required this.controller,
    required this.focusNode,
    required this.commit,
    this.align,
  });

  final WrapTextController controller;

  /// Hizalanabilen hedef (tablo hücresi, 2026-11-23): verilince panelde
  /// Sola · Ortala · Sağa düğmeleri çıkar, seçim buraya yazılır.
  final ValueNotifier<TextAlign>? align;

  /// Alanın odak düğümü: biçim uygulandıktan sonra odak (ve klavye) geri
  /// verilir — kullanıcı yazmaya kaldığı yerden devam eder.
  final FocusNode focusNode;

  /// Metin değişince notu kaydeden geri çağrı (programlı değişiklikte
  /// TextField'ın `onChanged`'i çalışmaz).
  final VoidCallback commit;
}

/// **ETKİN BİÇİMLER — PANEL KAPALIYKEN** (kullanıcı isteği 2026-10-20: "bold
/// italik vb. altta nelerin aktif olduğu görülsün, biçim paneli haricinde").
/// Alt çubuktaki Biçim düğmesinin yanında, imlecin/seçimin üzerindeki
/// biçimleri küçük rozetlerle gösterir; hiçbiri yoksa yer kaplamaz.
///
/// Hedef alan [target] üzerinden izlenir (odak her satırda değiştiği için
/// editörün tamamını yeniden kurmadan), denetleyici yalnız rozetler
/// GERÇEKTEN değişince çizdirir.
class ActiveFormatBadges extends StatefulWidget {
  const ActiveFormatBadges({super.key, required this.target});

  final ValueListenable<FormatTarget?> target;

  @override
  State<ActiveFormatBadges> createState() => _ActiveFormatBadgesState();
}

class _ActiveFormatBadgesState extends State<ActiveFormatBadges> {
  WrapTextController? _controller;
  RichMark _mark = RichMark.none;
  RichHeading _heading = RichHeading.normal;

  @override
  void initState() {
    super.initState();
    widget.target.addListener(_retarget);
    _retarget();
  }

  @override
  void dispose() {
    widget.target.removeListener(_retarget);
    _controller?.removeListener(_refresh);
    super.dispose();
  }

  void _retarget() {
    final next = widget.target.value?.controller;
    if (next == _controller) return;
    _controller?.removeListener(_refresh);
    _controller = next?..addListener(_refresh);
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final c = _controller;
    final mark = c == null ? RichMark.none : activeRichFormats(c);
    final heading = c == null ? RichHeading.normal : activeRichHeading(c);
    if (mark != _mark || heading != _heading) {
      setState(() {
        _mark = mark;
        _heading = heading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = NoteColors.richPalette;
    Color? resolve(int? index) {
      if (index == null) return null;
      if (isCustomRichColor(index)) return Color(index);
      if (index < 1 || index > palette.length) return scheme.primary;
      return palette[index - 1];
    }

    final appText = AppText.of(Theme.of(context));

    Widget letter(String text, {TextStyle? style}) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          text,
          style: appText.badge
              .copyWith(color: scheme.onPrimaryContainer)
              .merge(style),
        ),
      ),
    );

    Widget dot(Color color, {bool filled = true}) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color.withValues(alpha: AppAlpha.muted) : null,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );

    final badges = <Widget>[
      if (_heading != RichHeading.normal)
        letter(
          _heading == RichHeading.h1 ? 'H1' : 'H2',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      if (_mark.bold)
        letter('B', style: const TextStyle(fontWeight: FontWeight.w800)),
      if (_mark.italic)
        letter('I', style: const TextStyle(fontStyle: FontStyle.italic)),
      if (_mark.underline)
        letter(
          'U',
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      if (_mark.color != null) dot(resolve(_mark.color)!, filled: false),
      if (_mark.highlight != null) dot(resolve(_mark.highlight)!),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 2, end: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: badges),
      ),
    );
  }
}
