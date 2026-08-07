import 'package:flutter/material.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../domain/note.dart';

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
Future<NoteColor?> showNoteColorPicker(
  BuildContext context, {
  required bool frame,
  NoteColor? current,
  ValueChanged<NoteColor>? onChanged,
}) {
  return showModalBottomSheet<NoteColor>(
    context: context,
    showDragHandle: true,
    // Canlı seçimde karartı YOK ve levha dar: kullanıcı rengi seçerken
    // sayfanın gerçek hâlini görmeli, karartılmış hâlini değil.
    barrierColor: onChanged == null ? null : Colors.transparent,
    builder: (sheetContext) {
      var picked = current;
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
                                if (onChanged == null) {
                                  Navigator.pop(sheetContext, color);
                                  return;
                                }
                                setSheetState(() => picked = color);
                                onChanged(color);
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
