import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import 'text_wrap.dart';

/// Klavyenin hemen üstünde duran biçim çubuğu.
///
/// Neden alt sayfa değil de SABİT çubuk: biçim, yazarken kullanılan bir şey.
/// Seçim menüsünden açılan bir sayfa her seferinde (seç → menü → sayfa →
/// düğme) dört adım demekti ve yazı tipi/boyut palet sayfasının içine gömülü
/// olduğundan bulunamıyordu. Çubuk açıkken düğmeler tek dokunuş.
///
/// KRİTİK — ODAK: çubuktaki hiçbir öğe odak istemez
/// (`Focus(canRequestFocus: false, descendantsAreFocusable: false)` +
/// [TextFieldTapRegion]). Aksi hâlde düğmeye dokunmak metin alanının odağını
/// düşürür, odakla birlikte SEÇİM de gider ve biçim uygulanacak metin
/// kalmazdı.
///
/// YÜKSEKLİK (v1.0.175): çubuk dört satırdı (biçimler + yazı tipi çipleri +
/// boyut + şeffaflık); klavye de açıkken nota kala kala ekranın beşte biri
/// kalıyordu. Artık İKİ satır: yazı tipleri açılır menüye girdi, boyut ve
/// şeffaflık ise TEK kaydırıcıyı paylaşıyor (baştaki düğme hangisini
/// sürüklediğini değiştirir).
class FormatBar extends StatefulWidget {
  const FormatBar({
    super.key,
    required this.onFormat,
    required this.onClearFormat,
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
  });

  /// Biçim düğmesine basıldı: seçime uygula (seçim yoksa imlece kutu aç).
  final void Function(RichFormat format, {int? colorIndex}) onFormat;

  /// Seçimdeki tüm biçimleri siler.
  final VoidCallback onClearFormat;

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

/// Tek kaydırıcının o an neyi sürüklediği.
enum _SliderMode { size, opacity }

class _FormatBarState extends State<FormatBar> {
  _SliderMode _mode = _SliderMode.size;

  /// Sürükleme sürerken parmağın değeri. Seçim varken sayfa değişmediği için
  /// kaydırıcı yalnız buradan beslenir — yoksa topuz parmağın altında donardı.
  double? _drag;

  double get _value =>
      _drag ??
      (_mode == _SliderMode.size ? widget.fontScale : widget.textOpacity);

  double get _min => _mode == _SliderMode.size ? 0.7 : 0.3;
  double get _max => _mode == _SliderMode.size ? 2.0 : 1.0;

  void _onChanged(double value) {
    setState(() => _drag = value);
    // Canlı önizleme yalnız NOT GENELİNDE: seçim varken değişiklik bırakınca
    // ve yalnız seçime uygulanır.
    if (widget.hasSelection()) return;
    if (_mode == _SliderMode.size) {
      widget.onScaleChanged(value);
    } else {
      widget.onOpacityChanged(value);
    }
  }

  void _onChangeEnd(double value) {
    // Seçime uygulandıysa topuz BIRAKILDIĞI yerde kalır: not geneli
    // değişmediği için sıfırlansa kaydırıcı %100'e geri zıplar ve kullanıcı
    // az önce ne uyguladığını göremezdi.
    setState(() => _drag = widget.hasSelection() ? value : null);
    if (_mode == _SliderMode.size) {
      widget.onScaleEnd(value);
    } else {
      widget.onOpacityEnd(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final sizeMode = _mode == _SliderMode.size;
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
              // 1. satır: karakter biçimleri + yazı tipi menüsü.
              SizedBox(
                height: 44,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      _Btn(
                        icon: Icons.format_bold,
                        tooltip: l10n.formatBold,
                        onTap: () => widget.onFormat(RichFormat.bold),
                      ),
                      _Btn(
                        icon: Icons.format_italic,
                        tooltip: l10n.formatItalic,
                        onTap: () => widget.onFormat(RichFormat.italic),
                      ),
                      _Btn(
                        icon: Icons.format_underlined,
                        tooltip: l10n.formatUnderline,
                        onTap: () => widget.onFormat(RichFormat.underline),
                      ),
                      const SizedBox(width: 8),
                      _ColorPicker(
                        icon: Icons.format_color_text,
                        tooltip: l10n.formatTextColor,
                        onPick: (i) =>
                            widget.onFormat(RichFormat.color, colorIndex: i),
                      ),
                      _ColorPicker(
                        icon: Icons.format_color_fill,
                        tooltip: l10n.formatHighlight,
                        filled: true,
                        onPick: (i) => widget.onFormat(
                          RichFormat.highlight,
                          colorIndex: i,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Biçimi temizle: seçimdeki (ya da imlecin bulunduğu
                      // parçadaki) her biçim tek dokunuşta gider — düğmeleri
                      // tek tek geri basmak gerekmez.
                      _Btn(
                        icon: Icons.format_clear,
                        tooltip: l10n.formatClear,
                        onTap: widget.onClearFormat,
                      ),
                      const SizedBox(width: 4),
                      _FontMenu(
                        family: widget.fontFamily,
                        onChanged: widget.onFontChanged,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.close,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
              // 2. satır: TEK kaydırıcı — baştaki düğme boyut ile şeffaflık
              // arasında geçiş yapar. Sürüklerken metin anında değişir
              // (kaydırıcı sayfanın altında sabit durduğu için parmağın
              // altından kaçmaz); seçim varsa değişiklik bırakınca seçime iner.
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 2),
                child: Row(
                  children: [
                    // ADI YAZILI düğme: yalnız damla ikonu koyunca şeffaflık
                    // ayarını "bilmeyen asla bulamıyordu". Düğme hem o an
                    // neyin sürüklendiğini söyler hem de dokununca ötekine
                    // geçer.
                    Tooltip(
                      message: sizeMode
                          ? l10n.noteTextOpacity
                          : l10n.noteTextSize,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: Icon(
                          sizeMode ? Icons.text_fields : Icons.opacity,
                          size: 18,
                        ),
                        label: Text(
                          sizeMode ? l10n.noteTextSize : l10n.noteTextOpacity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => setState(() {
                          _drag = null;
                          _mode = sizeMode
                              ? _SliderMode.opacity
                              : _SliderMode.size;
                        }),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _value.clamp(_min, _max),
                        min: _min,
                        max: _max,
                        onChanged: _onChanged,
                        onChangeEnd: _onChangeEnd,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '%${(_value * 100).round()}',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yazı tipi seçimi: çipler satır kaplıyordu, artık açılır menü. Her satır
/// KENDİ yazı tipiyle yazılır — seçmeden önce nasıl duracağı görünür.
class _FontMenu extends StatelessWidget {
  const _FontMenu({required this.family, required this.onChanged});

  final String? family;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.noteFont,
      // null bir menü değeri "iptal" ile karışıyor; varsayılan için boş dize.
      onSelected: (value) => onChanged(value.isEmpty ? null : value),
      icon: const Icon(Icons.font_download_outlined, size: 22),
      itemBuilder: (context) => [
        for (final font in kNoteFonts)
          PopupMenuItem<String>(
            value: font.id ?? '',
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: (font.id ?? '') == (family ?? '')
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                Expanded(
                  child: Text(
                    noteFontLabel(
                      font.id,
                      defaultLabel: l10n.noteFontDefault,
                      serifLabel: l10n.noteFontSerif,
                      monoLabel: l10n.noteFontMono,
                    ),
                    style: applyNoteFont(const TextStyle(fontSize: 15), font.id),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 22),
    onPressed: onTap,
  );
}

/// Renk düğmesi: dokununca paletten seçtirir (menü, odak istemez).
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.icon,
    required this.tooltip,
    required this.onPick,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final ValueChanged<int> onPick;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = NoteColors.richPalette;
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      onSelected: onPick,
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 44,
          child: Row(
            children: [
              for (var i = 0; i < palette.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, i + 1),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? palette[i].withValues(alpha: 0.45)
                            : Colors.transparent,
                        border: Border.all(color: palette[i], width: 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
