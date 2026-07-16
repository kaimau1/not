import 'package:flutter/material.dart';

import '../../features/notes/domain/note.dart';

/// Not renk belirteçlerini temaya (açık/koyu) uygun gerçek renklere çözer.
abstract final class NoteColors {
  static const _light = <NoteColor, Color>{
    NoteColor.red: Color(0xFFFFF1F0),
    NoteColor.amber: Color(0xFFFFF7E0),
    NoteColor.green: Color(0xFFEFF8EE),
    NoteColor.blue: Color(0xFFEDF4FE),
    NoteColor.purple: Color(0xFFF6F0FC),
  };

  static const _dark = <NoteColor, Color>{
    NoteColor.red: Color(0xFF2B1D1C),
    NoteColor.amber: Color(0xFF2A2417),
    NoteColor.green: Color(0xFF1B241B),
    NoteColor.blue: Color(0xFF1A2230),
    NoteColor.purple: Color(0xFF241E2E),
  };

  /// Kart/editör arka planı. [NoteColor.none] için temanın yüzey rengi döner.
  static Color surface(BuildContext context, NoteColor color) {
    final scheme = Theme.of(context).colorScheme;
    if (color == NoteColor.none) return scheme.surfaceContainerLow;
    final map = Theme.of(context).brightness == Brightness.dark ? _dark : _light;
    return map[color] ?? scheme.surfaceContainerLow;
  }

  /// Renk seçicideki nokta rengi (daha doygun ton).
  static Color swatch(NoteColor color) => switch (color) {
        NoteColor.none => const Color(0xFF9E9E9E),
        NoteColor.red => const Color(0xFFE57373),
        NoteColor.amber => const Color(0xFFFFC94D),
        NoteColor.green => const Color(0xFF81C784),
        NoteColor.blue => const Color(0xFF64A5F5),
        NoteColor.purple => const Color(0xFFB39DDB),
      };
}
