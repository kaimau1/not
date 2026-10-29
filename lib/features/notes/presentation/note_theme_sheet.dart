import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/note_themes.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';

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
Future<NoteAppearanceAction?> showNoteThemeSheet(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onTheme,
  bool paper = false,
}) {
  return showAppSheet<NoteAppearanceAction>(
    context: context,
    showDragHandle: true,
    barrierColor: Colors.transparent,
    builder: (sheetContext) =>
        _ThemeSheet(current: current, onTheme: onTheme, paper: paper),
  );
}

class _ThemeSheet extends StatefulWidget {
  const _ThemeSheet({
    required this.current,
    required this.onTheme,
    required this.paper,
  });

  final String current;
  final ValueChanged<String> onTheme;
  final bool paper;

  @override
  State<_ThemeSheet> createState() => _ThemeSheetState();
}

class _ThemeSheetState extends State<_ThemeSheet> {
  late String _selected = NoteThemes.byId(widget.current) == null
      ? ''
      : widget.current;

  void _pick(String id) {
    if (id == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = id);
    widget.onTheme(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final names = <String, String>{
      '': l10n.noteThemeNone,
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.noteAppearance,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ids.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _ThemeTile(
                  key: ValueKey('theme-tile-${ids[i]}'),
                  id: ids[i],
                  label: names[ids[i]] ?? ids[i],
                  selected: _selected == ids[i],
                  onTap: () => _pick(ids[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (action, icon, label) in [
                    (
                      NoteAppearanceAction.color,
                      Icons.palette_outlined,
                      l10n.backgroundColor,
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
                        Icons.menu_book_outlined,
                        l10n.archivePaper,
                      ),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        avatar: Icon(icon, size: 18, color: scheme.primary),
                        label: Text(label),
                        shape: const StadiumBorder(),
                        onPressed: () => Navigator.pop(context, action),
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
/// çerçevesi ve hafif büyüme (yumuşak geçişle).
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
  static const double _h = 112;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = NoteThemes.byId(id);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: _w + 8,
                height: _h + 8,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: selected ? 0.16 : 0.08,
                        ),
                        blurRadius: selected ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: theme == null
                        ? _PlainPreview(scheme: scheme)
                        : CustomPaint(
                            painter: NoteThemePainter(theme, dark: dark),
                            child: const SizedBox.expand(),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sade": temasız sayfa — düz yüzey üstünde birkaç satır çizgisi.
class _PlainPreview extends StatelessWidget {
  const _PlainPreview({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerLow,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
