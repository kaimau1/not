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
class FormatBar extends StatelessWidget {
  const FormatBar({
    super.key,
    required this.onFormat,
    required this.onClearFormat,
    required this.fontFamily,
    required this.fontScale,
    required this.textOpacity,
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
  final ValueChanged<String?> onFontChanged;

  /// Sürükleme SIRASINDA (canlı önizleme) ve bırakınca (kalıcı kayıt).
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onScaleEnd;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onOpacityEnd;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
              // 1. satır: karakter biçimleri.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    _Btn(
                      icon: Icons.format_bold,
                      tooltip: l10n.formatBold,
                      onTap: () => onFormat(RichFormat.bold),
                    ),
                    _Btn(
                      icon: Icons.format_italic,
                      tooltip: l10n.formatItalic,
                      onTap: () => onFormat(RichFormat.italic),
                    ),
                    _Btn(
                      icon: Icons.format_underlined,
                      tooltip: l10n.formatUnderline,
                      onTap: () => onFormat(RichFormat.underline),
                    ),
                    const SizedBox(width: 8),
                    _ColorPicker(
                      icon: Icons.format_color_text,
                      tooltip: l10n.formatTextColor,
                      onPick: (i) => onFormat(RichFormat.color, colorIndex: i),
                    ),
                    _ColorPicker(
                      icon: Icons.format_color_fill,
                      tooltip: l10n.formatHighlight,
                      filled: true,
                      onPick: (i) =>
                          onFormat(RichFormat.highlight, colorIndex: i),
                    ),
                    const SizedBox(width: 8),
                    // Biçimi temizle: seçimdeki (ya da imlecin bulunduğu
                    // parçadaki) her biçim tek dokunuşta gider — düğmeleri
                    // tek tek geri basmak gerekmez.
                    _Btn(
                      icon: Icons.format_clear,
                      tooltip: l10n.formatClear,
                      onTap: onClearFormat,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.close,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              // 2. satır: yazı tipi + CANLI boyut.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final font in kNoteFonts)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  selected:
                                      (fontFamily ?? '') == (font.id ?? ''),
                                  onSelected: (_) => onFontChanged(font.id),
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    _label(l10n, font),
                                    // Çip metni yazı tipinin KENDİSİYLE
                                    // çizilir: seçmeden önce nasıl duracağı
                                    // görünür.
                                    style: applyNoteFont(
                                      const TextStyle(fontSize: 13),
                                      font.id,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 3. satır: CANLI boyut. Sürüklerken metin anında büyür/küçülür;
              // kaydırıcı sayfanın altında sabit durduğu için parmağın
              // altından kaçmaz (Ayarlar'daki tuzağın tersi).
              _SliderRow(
                icon: Icons.text_fields,
                tooltip: l10n.noteTextSize,
                value: fontScale,
                min: 0.7,
                max: 2,
                onChanged: onScaleChanged,
                onChangeEnd: onScaleEnd,
              ),
              // 4. satır: şeffaflık. En düşük değer bilerek %30 — daha
              // soluğunda metin kâğıt üstünde okunmaz hâle geliyor ve
              // kullanıcı yazdığını göremediği için ayarı geri bulamazdı.
              _SliderRow(
                icon: Icons.opacity,
                tooltip: l10n.noteTextOpacity,
                value: textOpacity,
                min: 0.3,
                max: 1,
                onChanged: onOpacityChanged,
                onChangeEnd: onOpacityEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(AppLocalizations l10n, NoteFontOption font) =>
      noteFontLabel(
        font.id,
        defaultLabel: l10n.noteFontDefault,
        serifLabel: l10n.noteFontSerif,
        monoLabel: l10n.noteFontMono,
      );
}

/// Simge + kaydırıcı + yüzde: boyut ve şeffaflık aynı düzeni kullanır.
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.tooltip,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final IconData icon;
  final String tooltip;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
    child: Row(
      children: [
        Tooltip(message: tooltip, child: Icon(icon, size: 16)),
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
          width: 46,
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
                  padding: const EdgeInsets.only(right: 10),
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
