import 'package:flutter/material.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../domain/note.dart';

/// Not zemini ya da çerçevesi için renk seçen ortak alt sayfa. Hem editör,
/// hem kart üç-nokta menüsü, hem de çoklu seçim toplu işlemi kullanır —
/// böylece renk/çerçeve seçimi tek yerde tanımlı kalır.
///
/// [frame] true ise renkler halka (çerçeve) olarak önizlenir; false ise dolu
/// zemin olarak. Seçilen [NoteColor] döner; sayfa kapatılırsa null.
Future<NoteColor?> showNoteColorPicker(
  BuildContext context, {
  required bool frame,
  NoteColor? current,
}) {
  return showModalBottomSheet<NoteColor>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14, left: 2),
                child: Text(
                  frame
                      ? sheetContext.l10n.frameColor
                      : sheetContext.l10n.backgroundColor,
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
              ),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final color in NoteColor.values)
                    _ColorDot(
                      color: color,
                      frame: frame,
                      selected: current == color,
                      onTap: () => Navigator.pop(sheetContext, color),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                frame
                    ? sheetContext.l10n.frameColorInfo
                    : sheetContext.l10n.backgroundColorInfo,
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
