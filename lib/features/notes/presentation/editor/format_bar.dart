import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/widgets/color_palette.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

/// Klavyenin hemen üstünde duran biçim paneli.
///
/// **İKİNCİ KEZ SIFIRDAN** (kullanıcı isteği 2026-10-28: "biçim menüsü
/// üzerine sıfırdan çalış, baştan tasarla, her yönü yerleşim kullanım
/// değiştirebilirsin"). 2026-10-20 sürümü tek satırdı ama en sık işlerin
/// (başlık, renk) hepsi bir TEPSİ arkasındaydı: başlık için iki, renk için
/// iki dokunuş, renk tepsisi de iki satır yer kaplıyordu. Yeni panel ÜÇ SABİT
/// SIRA; sık işlerin hepsi TEK dokunuş:
///  1. **Stil** — Metin · Başlık · Alt başlık hapları + B · I · U.
///  2. **Renk** — solda yazı rengi / vurgu anahtarı (her birinin altında
///     etkin renk şeridi), yanında 5 ton + tam palet + kaldır.
///  3. **Yazı** — yazı tipi tepsisi (Aa), boyut − %100 +, temizle, sayfa
///     görünümü, kapat.
/// Yalnız yazı tipi listesi ve ince ayar kaydırıcıları (boyut, şeffaflık)
/// panelin ÜSTÜNDE açılan tepside; menü katmanı yok, metin örtülmez.
///
/// KRİTİK — ODAK: çubuktaki hiçbir öğe odak istemez
/// (`Focus(canRequestFocus: false, descendantsAreFocusable: false)` +
/// [TextFieldTapRegion]). Aksi hâlde düğmeye dokunmak metin alanının odağını
/// düşürür, odakla birlikte SEÇİM de gider ve biçim uygulanacak metin
/// kalmazdı. Tepsiler de menü rotası açmadığından seçim hiç bozulmaz.
class FormatBar extends StatefulWidget {
  const FormatBar({
    super.key,
    required this.onFormat,
    required this.onClearFormat,
    required this.onRemoveFormat,
    required this.fontFamily,
    required this.fontScale,
    required this.textOpacity,
    required this.hasSelection,
    required this.onFontChanged,
    required this.onScaleChanged,
    required this.onScaleEnd,
    required this.onOpacityChanged,
    required this.onOpacityEnd,
    required this.onClose,
    this.target,
    this.onPageStyle,
    this.onHeading,
  });

  /// Satırı başlık / alt başlık / düz metin yapar (bkz. [setLineHeading]).
  /// null ise başlık düğmesi çizilmez (notun başlık alanı zaten başlık).
  final ValueChanged<RichHeading>? onHeading;

  /// SAYFA görünümü (zemin rengi, çerçeve rengi, zemin görseli) levhasını
  /// açar (kullanıcı isteği 2026-08-10: "sayfa rengi ve yanındaki kısımları
  /// biçim menüsüne al"). null ise düğme hiç çizilmez.
  final VoidCallback? onPageStyle;

  /// Çubuğun yazdığı alan. Yalnız AKTİF BİÇİM vurgusu için gerekli: imleç ya
  /// da seçim değiştikçe hangi düğmenin basılı duracağı buradan hesaplanır
  /// (bkz. [activeRichFormats]). null ise hiçbir düğme vurgulanmaz.
  final FormatTarget? target;

  /// Biçim düğmesine basıldı: seçime uygula (seçim yoksa imlece kutu aç).
  final void Function(RichFormat format, {int? colorIndex}) onFormat;

  /// Seçimdeki tüm biçimleri siler.
  final VoidCallback onClearFormat;

  /// Renk satırındaki "Kaldır": YALNIZ o biçmi (yazı rengi ya da vurgu)
  /// düşürür.
  final ValueChanged<RichFormat> onRemoveFormat;

  final String? fontFamily;
  final double fontScale;

  /// Not metninin opaklığı (0.3–1.0).
  final double textOpacity;

  /// O an metin SEÇİLİ mi? Seçiliyken boyut/şeffaflık yalnız seçime uygulanır
  /// ve bu yüzden sürüklerken sayfa canlı değişmez (değişse kullanıcı hangi
  /// metnin etkileneceğini göremezdi).
  final bool Function() hasSelection;

  final ValueChanged<String?> onFontChanged;

  /// Sürükleme SIRASINDA (canlı önizleme) ve bırakınca (kalıcı kayıt).
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onScaleEnd;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onOpacityEnd;

  final VoidCallback onClose;

  @override
  State<FormatBar> createState() => _FormatBarState();
}

/// Açık duran ince ayar tepsisi (yalnız yazı tipi + kaydırıcılar).
enum _Tray { none, font }

/// Renk satırının yazdığı biçim: yazı rengi mi, vurgu mu.
enum _ColorMode { text, highlight }

/// Kaydırıcının sürüklediği değer.
enum _Slide { size, opacity }

/// Boyut adımı (− / + düğmeleri) ve sınırlar — kaydırıcıyla aynı aralık.
const _kScaleStep = 0.1;
const _kScaleMin = 0.7;
const _kScaleMax = 2.0;

class _FormatBarState extends State<FormatBar> {
  _Tray _tray = _Tray.none;
  _ColorMode _colorMode = _ColorMode.text;

  /// Sürüklerken canlı önizlemenin seyreltilmesi (kullanıcı bulgusu
  /// 2026-10-20: "biçim panelindeki değişiklikler kasıyor"): her kaydırıcı
  /// olayı bütün notu yeni boyla yeniden dizdiriyordu (uzun notta kare
  /// başına onlarca ms). Önizleme en çok 70 ms'de bir uygulanır; bırakınca
  /// son değer kesin yazılır.
  Timer? _liveTimer;
  double? _liveValue;
  _Slide? _liveSlide;

  /// Sürükleme sürerken (ya da seçime uygulandıktan sonra) parmağın değeri.
  /// Seçim varken sayfa değişmediği için kaydırıcı yalnız buradan beslenir
  /// — yoksa topuz parmağın altında donardı.
  final Map<_Slide, double> _drag = {};

  /// İmleçte/seçimde etkin olan biçimler; düğme vurgusu bundan çizilir.
  RichMark _active = RichMark.none;

  /// İmlecin satırının başlık düzeyi.
  RichHeading _heading = RichHeading.normal;

  @override
  void initState() {
    super.initState();
    _watchTarget(null);
  }

  @override
  void didUpdateWidget(covariant FormatBar old) {
    super.didUpdateWidget(old);
    if (old.target?.controller != widget.target?.controller) {
      _watchTarget(old.target);
      // Başka alana geçildi: seçime uygulanmış kaydırıcı değeri artık o
      // alanın değil.
      _drag.clear();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    widget.target?.controller.removeListener(_refreshActive);
    super.dispose();
  }

  /// Denetleyici değişince aboneliği taşı. TextEditingController hem metin
  /// hem SEÇİM değişiminde bildirir; imleci oynatmak da vurguyu tazeler.
  void _watchTarget(FormatTarget? old) {
    old?.controller.removeListener(_refreshActive);
    widget.target?.controller.addListener(_refreshActive);
    // initState/didUpdateWidget'ın arkasından zaten bir build geliyor;
    // setState'siz atama yeterli (ve initState'te setState yasak).
    _active = _computeActive();
    _heading = _computeHeading();
  }

  RichHeading _computeHeading() {
    final controller = widget.target?.controller;
    return controller == null
        ? RichHeading.normal
        : activeRichHeading(controller);
  }

  RichMark _computeActive() {
    final controller = widget.target?.controller;
    return controller == null ? RichMark.none : activeRichFormats(controller);
  }

  void _refreshActive() {
    if (!mounted) return;
    final next = _computeActive();
    final heading = _computeHeading();
    // Her tuş vuruşunda değil, vurgu GERÇEKTEN değişince çiz.
    if (next != _active || heading != _heading) {
      setState(() {
        _active = next;
        _heading = heading;
      });
    }
  }

  void _toggleTray(_Tray tray) =>
      setState(() => _tray = _tray == tray ? _Tray.none : tray);

  double _value(_Slide slide) =>
      _drag[slide] ??
      (slide == _Slide.size ? widget.fontScale : widget.textOpacity);

  void _onSlide(_Slide slide, double value) {
    setState(() => _drag[slide] = value);
    // Canlı önizleme yalnız NOT GENELİNDE: seçim varken değişiklik bırakınca
    // ve yalnız seçime uygulanır.
    if (widget.hasSelection()) return;
    if (_liveSlide != null && _liveSlide != slide) _flushLive();
    _liveSlide = slide;
    _liveValue = value;
    _liveTimer ??= Timer(const Duration(milliseconds: 70), _flushLive);
  }

  void _flushLive() {
    _liveTimer?.cancel();
    _liveTimer = null;
    final value = _liveValue;
    final slide = _liveSlide;
    _liveValue = null;
    _liveSlide = null;
    if (value == null || slide == null || !mounted) return;
    if (slide == _Slide.size) {
      widget.onScaleChanged(value);
    } else {
      widget.onOpacityChanged(value);
    }
  }

  void _onSlideEnd(_Slide slide, double value) {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveValue = null;
    _liveSlide = null;
    // Seçime uygulandıysa topuz BIRAKILDIĞI yerde kalır: not geneli
    // değişmediği için sıfırlansa kaydırıcı %100'e geri zıplar ve kullanıcı
    // az önce ne uyguladığını göremezdi.
    setState(() {
      if (widget.hasSelection()) {
        _drag[slide] = value;
      } else {
        _drag.remove(slide);
      }
    });
    if (slide == _Slide.size) {
      widget.onScaleEnd(value);
    } else {
      widget.onOpacityEnd(value);
    }
  }

  /// − / + düğmesi: boyutu bir adım değiştirip HEMEN uygular (seçim varsa
  /// seçime, yoksa nota — kaydırıcıyı bırakmakla aynı yol).
  void _stepScale(int direction) {
    final current = _value(_Slide.size);
    final next = ((current / _kScaleStep).round() + direction) * _kScaleStep;
    _onSlideEnd(
      _Slide.size,
      double.parse(next.clamp(_kScaleMin, _kScaleMax).toStringAsFixed(2)),
    );
  }

  /// Etkin yazı rengi / vurgu indeksinin ekrandaki rengi (yoksa null).
  static Color? _resolve(int? index) {
    final palette = NoteColors.richPalette;
    if (index == null) return null;
    if (isCustomRichColor(index)) return Color(index);
    if (index < 1 || index > palette.length) return null;
    return palette[index - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final highlightMode = _colorMode == _ColorMode.highlight;
    final size = _value(_Slide.size);
    final divider = Divider(
      height: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
    );
    return TextFieldTapRegion(
      child: Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: Material(
          color: scheme.surfaceContainerHigh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              // İNCE AYAR TEPSİSİ panelin ÜSTÜNDE: göz yazıdan çok
              // uzaklaşmaz, alttaki sıralar parmağın altında oynamaz.
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: switch (_tray) {
                  _Tray.none => const SizedBox(width: double.infinity),
                  _Tray.font => _FontTray(
                    family: widget.fontFamily,
                    onFont: widget.onFontChanged,
                    size: size,
                    opacity: _value(_Slide.opacity),
                    onSlide: _onSlide,
                    onSlideEnd: _onSlideEnd,
                  ),
                },
              ),
              // 1. SIRA — PARAGRAF + YAZI STİLİ: Metin · Başlık · Alt başlık
              // hapları doğrudan (eskiden "Başlık" tepsisinin içindeydi, iki
              // dokunuş) ve B · I · U.
              _PanelRow(
                children: [
                  if (widget.onHeading != null) ...[
                    for (final (h, label, weight) in [
                      (
                        RichHeading.normal,
                        l10n.formatStyleText,
                        FontWeight.w400,
                      ),
                      (RichHeading.h1, l10n.formatStyleH1, FontWeight.w800),
                      (RichHeading.h2, l10n.formatStyleH2, FontWeight.w700),
                    ])
                      Expanded(
                        flex: h == RichHeading.h2 ? 6 : 5,
                        child: _Chip(
                          key: ValueKey('format-heading-${h.name}'),
                          selected: _heading == h,
                          onTap: () => widget.onHeading?.call(h),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: weight),
                          ),
                        ),
                      ),
                    const _Gap(),
                  ],
                  _Btn(
                    key: const ValueKey('format-bold'),
                    flex: widget.onHeading == null ? 1 : 3,
                    icon: Icons.format_bold,
                    tooltip: l10n.formatBold,
                    active: _active.bold,
                    onTap: () => widget.onFormat(RichFormat.bold),
                  ),
                  _Btn(
                    key: const ValueKey('format-italic'),
                    flex: widget.onHeading == null ? 1 : 3,
                    icon: Icons.format_italic,
                    tooltip: l10n.formatItalic,
                    active: _active.italic,
                    onTap: () => widget.onFormat(RichFormat.italic),
                  ),
                  _Btn(
                    key: const ValueKey('format-underline'),
                    flex: widget.onHeading == null ? 1 : 3,
                    icon: Icons.format_underlined,
                    tooltip: l10n.formatUnderline,
                    active: _active.underline,
                    onTap: () => widget.onFormat(RichFormat.underline),
                  ),
                ],
              ),
              divider,
              // 2. SIRA — RENK, TEK DOKUNUŞ: soldaki anahtar satırın neyi
              // boyadığını seçer (yazı / vurgu, her biri etkin rengini
              // şeritte gösterir); tonlar, palet ve kaldır hep görünür.
              _PanelRow(
                children: [
                  _ModeSwitch(
                    mode: _colorMode,
                    textColor: _resolve(_active.color),
                    highlightColor: _resolve(_active.highlight),
                    onChanged: (mode) => setState(() => _colorMode = mode),
                  ),
                  const _Gap(),
                  Expanded(
                    child: _ColorRow(
                      key: ValueKey('format-colors-$_colorMode'),
                      keyPrefix: highlightMode
                          ? 'format-highlight'
                          : 'format-color',
                      label: highlightMode
                          ? l10n.formatHighlight
                          : l10n.formatTextColor,
                      activeIndex: highlightMode
                          ? _active.highlight
                          : _active.color,
                      filled: highlightMode,
                      onPick: (i) => widget.onFormat(
                        highlightMode ? RichFormat.highlight : RichFormat.color,
                        colorIndex: i,
                      ),
                      onRemove: () => widget.onRemoveFormat(
                        highlightMode ? RichFormat.highlight : RichFormat.color,
                      ),
                    ),
                  ),
                ],
              ),
              divider,
              // 3. SIRA — YAZI: yazı tipi tepsisi, boyut − / + (tek dokunuş,
              // ayrıntısı tepside kaydırıcıyla), temizle, sayfa, kapat.
              _PanelRow(
                children: [
                  _Btn(
                    key: const ValueKey('format-font'),
                    icon: Icons.text_fields,
                    tooltip: l10n.formatFontPanel,
                    open: _tray == _Tray.font,
                    onTap: () => _toggleTray(_Tray.font),
                  ),
                  _Btn(
                    key: const ValueKey('format-size-down'),
                    icon: Icons.text_decrease,
                    tooltip: l10n.formatSizeDown,
                    onTap: size <= _kScaleMin + 0.001
                        ? null
                        : () => _stepScale(-1),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '%${(size * 100).round()}',
                      key: const ValueKey('format-size-value'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  _Btn(
                    key: const ValueKey('format-size-up'),
                    icon: Icons.text_increase,
                    tooltip: l10n.formatSizeUp,
                    onTap: size >= _kScaleMax - 0.001
                        ? null
                        : () => _stepScale(1),
                  ),
                  // Biçimi temizle: biçimsiz metinde SOLUK ve tıklanamaz —
                  // düğmenin işe yarayıp yaramadığı görünür.
                  _Btn(
                    key: const ValueKey('format-clear'),
                    icon: Icons.format_clear,
                    tooltip: l10n.formatClear,
                    onTap: _active.isEmpty ? null : widget.onClearFormat,
                  ),
                  if (widget.onPageStyle != null)
                    _Btn(
                      key: const ValueKey('format-page'),
                      icon: Icons.palette_outlined,
                      tooltip: l10n.formatPageColor,
                      onTap: widget.onPageStyle,
                    ),
                  SizedBox(
                    height: 26,
                    child: VerticalDivider(
                      width: 7,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                  ),
                  _Btn(
                    key: const ValueKey('format-close'),
                    icon: Icons.keyboard_arrow_down,
                    tooltip: l10n.close,
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panelin bir sırası: sabit yükseklik, yan pay.
class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(children: children),
    ),
  );
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 6);
}

/// Sıra düğmesi: satıra EŞİT payla yayılır (Expanded), en fazla 52 dp.
/// [open]: tepsisi açık (kenarlık); [active]: biçim imleçte etkin (dolu
/// zemin).
class _Btn extends StatelessWidget {
  const _Btn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.open = false,
    this.flex = 1,
  });

  final IconData icon;
  final String tooltip;

  /// null ise düğme SOLUK ve tıklanamaz (yapacak işi yok).
  final VoidCallback? onTap;
  final bool active;
  final bool open;

  /// Sıradaki pay (stil hapları ile aynı sırada daha büyük verilir).
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final fg = active
        ? scheme.onPrimaryContainer
        : enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.35);
    return Expanded(
      flex: flex,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 52),
          child: Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              selected: active || open,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Ink(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primaryContainer
                        : open
                        ? scheme.surfaceContainerHighest
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: open
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Icon(icon, size: 22, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçilebilir hap (paragraf stili, yazı tipi). Odak istemez.
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
    final scheme = Theme.of(context).colorScheme;
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
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Ink(
            width: 40,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: stripe ?? scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
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
              tooltip: label,
              onTap: () => onPick(i + 1),
              fill: filled ? palette[i].withValues(alpha: 0.45) : palette[i],
              border: filled ? palette[i] : null,
              borderWidth: index == i + 1 ? 3.5 : 2,
              child: index == i + 1
                  ? Icon(
                      Icons.check,
                      size: 16,
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
                : const SweepGradient(
                    colors: [
                      Color(0xFFE57373),
                      Color(0xFFFFD54F),
                      Color(0xFF81C784),
                      Color(0xFF64B5F6),
                      Color(0xFF9575CD),
                      Color(0xFFE57373),
                    ],
                  ),
            child: Icon(
              custom != null ? Icons.check : Icons.palette_outlined,
              size: 15,
              color: custom != null && custom.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
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
              size: 15,
              color: index == null
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
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
                  onTap: () => onFont(font.id),
                  child: Text(
                    noteFontLabel(
                      font.id,
                      defaultLabel: l10n.noteFontDefault,
                      serifLabel: l10n.noteFontSerif,
                      monoLabel: l10n.noteFontMono,
                    ),
                    style: applyNoteFont(
                      const TextStyle(fontSize: 14.5),
                      font.id,
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
  });

  final WrapTextController controller;

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

    Widget letter(String text, {TextStyle? style}) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: scheme.onPrimaryContainer,
          ).merge(style),
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
          color: filled ? color.withValues(alpha: 0.6) : null,
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
