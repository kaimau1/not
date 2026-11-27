import 'package:flutter/material.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/fixed_colors.dart';
import '../../../app/theme/note_colors.dart';
import '../../../app/theme/note_themes.dart';
import '../../../core/a11y/chip_roles.dart';
import '../../../core/app_icons.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/color_palette.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/toggle_pop.dart';
import '../domain/note.dart';
import 'color_picker_sheet.dart';

/// Görünüm levhasının alt satırındaki seçenekler.
enum NoteAppearanceAction { color, frame, image, paper }

/// **NOTUN GÖRÜNÜMÜ — TEMA ŞERİDİ** (kullanıcı isteği 2026-10-28: "notun
/// görselini, rengini değiştirme ekranı güzel"; örnek uygulamada palete
/// basınca altta küçük sayfa önizlemeleri kayar, dokunulan ANINDA uygulanır).
///
/// Levha karartısız ve alçak: not arkada canlı görünür, kullanıcı temalar
/// arasında gezinip sonucu sayfanın kendisinde görür. Seçili kart vurgu
/// rengi çerçeveyle hafifçe büyür. Alt satır renk, çerçeve, zemin görseli
/// (ve defterde kâğıt) gibi ayrıntılı seçeneklere götürür — seçilen eylem
/// döner, çağıran açar.
///
/// **DÜZ RENKLER** (kullanıcı isteği 2026-10-29: "daha sade düz seçenekler,
/// renk paleti ile renk de seçilebilmeli"): temaların altında desensiz düz
/// zemin kartları ve en sonda tam palet; seçilen renk ANINDA [onColor] ile
/// uygulanır (çizilmiş tema kalkar). "Sade" hem temayı hem rengi kaldırır.
Future<NoteAppearanceAction?> showNoteThemeSheet(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onTheme,
  NoteColor color = NoteColor.none,
  int? customColor,
  ValueChanged<NoteColorPick>? onColor,
  bool paper = false,
}) {
  return showAppSheet<NoteAppearanceAction>(
    context: context,
    showDragHandle: true,
    barrierColor: Colors.transparent,
    // Düz renk satırıyla levha varsayılan 9/16 sınırını aşabiliyor:
    // içeriği kadar uzar, kısa ekranda kayar.
    isScrollControlled: true,
    builder: (sheetContext) => _ThemeSheet(
      current: current,
      onTheme: onTheme,
      color: color,
      customColor: customColor,
      onColor: onColor,
      paper: paper,
    ),
  );
}

class _ThemeSheet extends StatefulWidget {
  const _ThemeSheet({
    required this.current,
    required this.onTheme,
    required this.color,
    required this.customColor,
    required this.onColor,
    required this.paper,
  });

  final String current;
  final ValueChanged<String> onTheme;
  final NoteColor color;
  final int? customColor;
  final ValueChanged<NoteColorPick>? onColor;
  final bool paper;

  @override
  State<_ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<_ThemeSheet> {
  late String _selected = NoteThemes.byId(widget.current) == null
      ? ''
      : widget.current;

  late NoteColor _color = widget.customColor == null
      ? widget.color
      : NoteColor.none;
  late int? _custom = widget.customColor;

  bool get _plain =>
      _selected.isEmpty && _color == NoteColor.none && _custom == null;

  void _pick(String id) {
    final onColor = widget.onColor;
    // "Sade" rengi de kaldırır (düz renkler artık aynı levhada).
    if (id.isEmpty && onColor != null && !_plain) {
      AppHaptics.tick();
      setState(() {
        _selected = '';
        _color = NoteColor.none;
        _custom = null;
      });
      widget.onTheme('');
      onColor((color: NoteColor.none, custom: null));
      return;
    }
    if (id == _selected) return;
    AppHaptics.tick();
    setState(() => _selected = id);
    widget.onTheme(id);
  }

  void _pickColor(NoteColorPick pick) {
    AppHaptics.tick();
    setState(() {
      _selected = '';
      _color = pick.color;
      _custom = pick.custom;
    });
    widget.onColor?.call(pick);
  }

  Future<void> _pickPalette() async {
    final l10n = context.l10n;
    final c = await showColorPaletteSheet(
      context,
      title: l10n.backgroundColor,
      current: _custom == null ? null : Color(_custom!),
    );
    if (c == null || !mounted) return;
    _pickColor((color: NoteColor.none, custom: c.toARGB32() | 0xFF000000));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final names = <String, String>{
      '': l10n.noteThemeNone,
      NoteThemes.aurora: l10n.noteThemeAurora,
      NoteThemes.citrus: l10n.noteThemeCitrus,
      NoteThemes.botanical: l10n.noteThemeBotanical,
      NoteThemes.terracotta: l10n.noteThemeTerracotta,
      NoteThemes.confetti: l10n.noteThemeConfetti,
      NoteThemes.cobalt: l10n.noteThemeCobalt,
      NoteThemes.palm: l10n.noteThemePalm,
      NoteThemes.lagoon: l10n.noteThemeLagoon,
      NoteThemes.night: l10n.noteThemeNight,
      NoteThemes.sunset: l10n.noteThemeSunset,
      NoteThemes.sakura: l10n.noteThemeSakura,
      NoteThemes.waves: l10n.noteThemeWaves,
      NoteThemes.meadow: l10n.noteThemeMeadow,
      NoteThemes.paper: l10n.noteThemePaper,
    };
    final ids = ['', for (final t in NoteThemes.all) t.id];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: l10n.noteAppearance),
            SizedBox(
              height: 148,
              child: HorizontalScrollStrip(
                builder: (_, controller) => ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  itemCount: ids.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.m),
                  itemBuilder: (context, i) => _ThemeTile(
                    key: ValueKey('theme-tile-${ids[i]}'),
                    id: ids[i],
                    label: names[ids[i]] ?? ids[i],
                    selected: ids[i].isEmpty && widget.onColor != null
                        ? _plain
                        : _selected == ids[i],
                    onTap: () => _pick(ids[i]),
                  ),
                ),
              ),
            ),
            if (widget.onColor != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.m,
                  AppSpace.l,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.m,
                    AppSpace.s,
                    AppSpace.m,
                    AppSpace.m,
                  ),
                  decoration: AppSurface.sheetCard(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noteFlatColors,
                        style: text.meta.copyWith(
                          fontWeight: AppWeight.strong,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s),
                      SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final c in NoteColor.values)
                              if (c != NoteColor.none)
                                _FlatTile(
                                  key: ValueKey('flat-color-${c.id}'),
                                  fill: NoteColors.surface(context, c),
                                  selected:
                                      _selected.isEmpty &&
                                      _custom == null &&
                                      _color == c,
                                  onTap: () =>
                                      _pickColor((color: c, custom: null)),
                                ),
                            _FlatTile(
                              key: const ValueKey('flat-color-palette'),
                              fill: _custom == null ? null : Color(_custom!),
                              selected: _selected.isEmpty && _custom != null,
                              palette: true,
                              tooltip: l10n.paletteMore,
                              onTap: _pickPalette,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.m),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
              child: Row(
                children: [
                  for (final (action, icon, label) in [
                    // "Zemin rengi" → "Özel renk…" (F12.6): düz renkler hemen
                    // üstteki satırda; bu düğme ADLI renk seçicisini açar,
                    // ikinci bir "zemin rengi" gibi okunuyordu.
                    (
                      NoteAppearanceAction.color,
                      Icons.colorize_outlined,
                      l10n.customColor,
                    ),
                    (
                      NoteAppearanceAction.frame,
                      Icons.crop_square_rounded,
                      l10n.frameColor,
                    ),
                    (
                      NoteAppearanceAction.image,
                      Icons.wallpaper_outlined,
                      l10n.noteBackgroundImage,
                    ),
                    if (widget.paper)
                      (
                        NoteAppearanceAction.paper,
                        AppIcons.notebook,
                        l10n.archivePaper,
                      ),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpace.s,
                      ),
                      child: actionChip(
                        ActionChip(
                          avatar: Icon(
                            icon,
                            size: AppIconSize.s,
                            color: scheme.primary,
                          ),
                          label: Text(label),
                          shape: const StadiumBorder(),
                          onPressed: () => Navigator.pop(context, action),
                        ),
                      ),
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

/// Şeritteki tek tema: küçük sayfa önizlemesi + adı. Seçiliyken vurgu
/// çerçevesi ve temiz oturma geçişi (bulanık gölge yok — GLES uyumlu).
class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    super.key,
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _w = 78;
  static const double _h = 110;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final scheme = themeData.colorScheme;
    final tokens = AppTokens.fromTheme(themeData);
    final text = AppText.of(themeData);
    final dark = themeData.brightness == Brightness.dark;
    final noteTheme = NoteThemes.byId(id);
    final duration = AppMotion.of(context, AppMotion.short);
    final curve = AppMotion.curveOf(context, AppMotion.emphasized);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              AnimatedContainer(
                duration: duration,
                curve: curve,
                width: _w + AppSpace.s,
                height: _h + AppSpace.s,
                padding: const EdgeInsets.all(AppSpace.xxs),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(color: tokens.hairline),
                    boxShadow: tokens.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        noteTheme == null
                            ? _PlainPreview(scheme: scheme)
                            : CustomPaint(
                                painter: NoteThemePainter(
                                  noteTheme,
                                  dark: dark,
                                ),
                                child: const SizedBox.expand(),
                              ),
                        if (selected)
                          Positioned(
                            right: AppSpace.xs,
                            top: AppSpace.xs,
                            child: TogglePop(
                              on: selected,
                              child: CircleAvatar(
                                radius: 9,
                                backgroundColor: scheme.primary,
                                child: Icon(
                                  Icons.check,
                                  size: AppIconSize.xs - 3,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label,
                maxLines: 1,
                style: text.meta.copyWith(
                  fontWeight: selected ? AppWeight.strong : AppWeight.medium,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Düz zemin kartı (desensiz küçük sayfa); [palette] ise tam paleti açan
/// gökkuşağı kart (özel renk seçiliyse o renkte).
class _FlatTile extends StatelessWidget {
  const _FlatTile({
    super.key,
    required this.fill,
    required this.selected,
    required this.onTap,
    this.palette = false,
    this.tooltip,
  });

  final Color? fill;
  final bool selected;
  final VoidCallback onTap;
  final bool palette;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = this.fill;
    final checkInk = fill == null ? Colors.white : FixedColors.inkOn(fill);
    Widget tile = PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.short),
          curve: AppMotion.curveOf(context, AppMotion.emphasized),
          width: 46,
          height: 58,
          margin: const EdgeInsetsDirectional.only(end: AppSpace.s),
          padding: const EdgeInsets.all(AppSpace.xxs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              color: fill,
              border: Border.all(color: scheme.outlineVariant, width: 0.6),
              gradient: palette && fill == null
                  ? FixedColors.rainbowSweep
                  : null,
            ),
            child: palette
                ? Icon(AppIcons.color, size: AppIconSize.m, color: checkInk)
                : (selected
                      ? TogglePop(
                          on: selected,
                          child: Icon(
                            Icons.check,
                            size: AppIconSize.s,
                            color: checkInk,
                          ),
                        )
                      : null),
          ),
        ),
      ),
    );
    final tip = tooltip;
    if (tip != null) tile = Tooltip(message: tip, child: tile);
    return Semantics(button: true, selected: selected, child: tile);
  }
}

/// "Sade": temasız sayfa — düz yüzey üstünde birkaç satır çizgisi.
class _PlainPreview extends StatelessWidget {
  const _PlainPreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTokens.of(context).card,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                width: i == 3 ? 26 : 38,
                height: 3,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.hair),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
