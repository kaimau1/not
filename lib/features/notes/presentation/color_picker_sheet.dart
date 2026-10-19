import 'package:flutter/material.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../domain/note.dart';
import '../../../core/widgets/app_sheet.dart';

/// Notun TEK rengi + isteğe bağlı KENAR VURGUSU (F3.6; eskiden ayrı "zemin"
/// ve "çerçeve" seçicileri vardı). Hem editör, hem kart menüsü, hem de çoklu
/// seçim toplu işlemi kullanır.
typedef NoteColorChoice = ({NoteColor color, bool accent});

/// [onChanged] verilirse şerit **Keep gibi** davranır: dokunulan renk ANINDA
/// uygulanır ve şerit AÇIK kalır. [onChanged] yoksa seçim döndürülür ve
/// şerit kapanır (kart menüsü ve toplu işlem — önizlenecek sayfa yok).
Future<NoteColorChoice?> showNoteColorPicker(
  BuildContext context, {
  NoteColor? current,
  bool accent = false,
  ValueChanged<NoteColorChoice>? onChanged,
}) {
  return showAppSheet<NoteColorChoice>(
    context: context,
    showDragHandle: true,
    // Canlı seçimde karartı YOK: kullanıcı rengi seçerken sayfanın gerçek
    // hâlini görmeli.
    barrierColor: onChanged == null ? null : Colors.transparent,
    builder: (sheetContext) {
      var picked = current;
      var withAccent = accent;
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final scheme = Theme.of(sheetContext).colorScheme;
          void apply(NoteColor color, {bool close = true}) {
            final choice = (color: color, accent: withAccent);
            if (onChanged == null) {
              if (close) Navigator.pop(sheetContext, choice);
              return;
            }
            setSheetState(() => picked = color);
            onChanged(choice);
          }

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
                      sheetContext.l10n.backgroundColor,
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
                              frame: withAccent,
                              selected: picked == color,
                              onTap: () => apply(color),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    key: const ValueKey('note-color-accent'),
                    contentPadding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                    title: Text(sheetContext.l10n.noteColorAccent),
                    subtitle: Text(
                      sheetContext.l10n.backgroundColorInfo,
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    value: withAccent,
                    onChanged: (v) {
                      setSheetState(() => withAccent = v);
                      // Canlı şeritte vurgu anında uygulanır; seç-kapan
                      // şeritte bir renk seçilince birlikte döner.
                      final color = picked;
                      if (color != null) apply(color, close: false);
                    },
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
