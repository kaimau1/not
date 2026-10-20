import 'package:flutter/material.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../domain/note.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/color_palette.dart';

/// Renk seçiminin sonucu: hazır ton ya da PALETTEN özel renk ([custom] ARGB;
/// doluyken [color] `none` — bkz. `Note.customColor`).
typedef NoteColorPick = ({NoteColor color, int? custom});

/// Not zemini ya da çerçevesi için renk seçen ortak alt şerit. Hem editör,
/// hem kart üç-nokta menüsü, hem de çoklu seçim toplu işlemi kullanır —
/// böylece renk/çerçeve seçimi tek yerde tanımlı kalır.
///
/// [frame] true ise renkler halka (çerçeve) olarak önizlenir; false ise dolu
/// zemin olarak.
///
/// [onChanged] verilirse şerit **Keep gibi** davranır (kullanıcı isteği:
/// "seçici alt şeride insin"): dokunulan renk ANINDA uygulanır ve şerit AÇIK
/// kalır, kullanıcı tonlar arasında gezinip sayfayı canlı görebilir. Şerit
/// kapanınca son seçilen renk yine döner. [onChanged] yoksa eski davranış
/// sürer: seçilen renk döndürülür ve şerit kapanır (kart menüsü ve toplu
/// işlem böyle kullanıyor — orada canlı önizlenecek bir sayfa yok).
///
/// Şeridin sonundaki palet düğmesi tam paleti açar (kullanıcı isteği
/// 2026-10-20: "aynı renk paleti çerçeve, zemin rengine de gelsin").
Future<NoteColorPick?> showNoteColorPicker(
  BuildContext context, {
  required bool frame,
  NoteColor? current,
  int? currentCustom,
  ValueChanged<NoteColorPick>? onChanged,
}) {
  return showAppSheet<NoteColorPick>(
    context: context,
    showDragHandle: true,
    // Canlı seçimde karartı YOK ve levha dar: kullanıcı rengi seçerken
    // sayfanın gerçek hâlini görmeli, karartılmış hâlini değil.
    barrierColor: onChanged == null ? null : Colors.transparent,
    builder: (sheetContext) {
      var picked = currentCustom == null ? current : null;
      var pickedCustom = currentCustom;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final scheme = Theme.of(sheetContext).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      frame
                          ? sheetContext.l10n.frameColor
                          : sheetContext.l10n.backgroundColor,
                      style: Theme.of(sheetContext).textTheme.titleSmall,
                    ),
                  ),
                  // TEK SATIR, yatay kaydırmalı: on iki ton dar ekranda alt
                  // alta sarılınca şerit bir pencereye dönüşüyordu.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final color in NoteColor.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _ColorDot(
                              color: color,
                              frame: frame,
                              selected: picked == color,
                              onTap: () {
                                final choice = (color: color, custom: null);
                                if (onChanged == null) {
                                  Navigator.pop(sheetContext, choice);
                                  return;
                                }
                                setSheetState(() {
                                  picked = color;
                                  pickedCustom = null;
                                });
                                onChanged(choice);
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _PaletteDot(
                            custom: pickedCustom,
                            frame: frame,
                            onTap: () async {
                              final c = await showColorPaletteSheet(
                                sheetContext,
                                title: frame
                                    ? sheetContext.l10n.frameColor
                                    : sheetContext.l10n.backgroundColor,
                                current: pickedCustom == null
                                    ? null
                                    : Color(pickedCustom!),
                              );
                              if (c == null || !sheetContext.mounted) return;
                              final choice = (
                                color: NoteColor.none,
                                custom: c.toARGB32() | 0xFF000000,
                              );
                              if (onChanged == null) {
                                Navigator.pop(sheetContext, choice);
                                return;
                              }
                              setSheetState(() {
                                picked = null;
                                pickedCustom = choice.custom;
                              });
                              onChanged(choice);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Text(
                      frame
                          ? sheetContext.l10n.frameColorInfo
                          : sheetContext.l10n.backgroundColorInfo,
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.frame,
    required this.selected,
    required this.onTap,
  });

  final NoteColor color;
  final bool frame;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final swatch = NoteColors.swatch(color);
    final isNone = color == NoteColor.none;
    // Çerçeve önizlemesi: içi boş, kenarı renkli halka. Zemin önizlemesi: dolu.
    final decoration = frame && !isNone
        ? BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: swatch, width: 4),
          )
        : BoxDecoration(color: swatch, shape: BoxShape.circle);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: decoration,
          child: isNone
              ? const Icon(Icons.format_color_reset_outlined, size: 20)
              : (selected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: frame ? swatch : scheme.onSurface,
                      )
                    : null),
        ),
      ),
    );
  }
}

/// Şeridin sonundaki palet düğmesi: özel renk seçiliyse o rengi gösterir.
class _PaletteDot extends StatelessWidget {
  const _PaletteDot({
    required this.custom,
    required this.frame,
    required this.onTap,
  });

  final int? custom;
  final bool frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = custom != null;
    return Tooltip(
      message: context.l10n.paletteMore,
      child: InkWell(
        key: const ValueKey('note-color-palette'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected && !frame ? Color(custom!) : null,
              border: selected && frame
                  ? Border.all(color: Color(custom!), width: 4)
                  : null,
              gradient: selected
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
            ),
            child: Icon(
              selected ? Icons.check : Icons.palette_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
