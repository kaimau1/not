import 'package:flutter/material.dart';

import '../../features/notes/domain/note.dart';
import 'note_themes.dart';

/// Not renk belirteçlerini temaya (açık/koyu) uygun gerçek renklere çözer.
abstract final class NoteColors {
  /// Keep'in not renkleri (kullanıcı isteği: "palet Keep tonlarına dönsün").
  /// Değerler Keep'in kendi paletinden alındı; koyu temada ayrı bir küme
  /// kullanılır — açık tonları karartmak gri ve bulanık sonuç veriyordu.
  static const _light = <NoteColor, Color>{
    NoteColor.red: Color(0xFFFAAFA8),
    NoteColor.peach: Color(0xFFF39F76),
    NoteColor.amber: Color(0xFFFFF8B8),
    NoteColor.green: Color(0xFFE2F6D3),
    NoteColor.sage: Color(0xFFB4DDD3),
    NoteColor.blue: Color(0xFFD4E4ED),
    NoteColor.storm: Color(0xFFAECCDC),
    NoteColor.purple: Color(0xFFD3BFDB),
    NoteColor.blossom: Color(0xFFF6E2DD),
    NoteColor.clay: Color(0xFFE9E3D4),
    NoteColor.chalk: Color(0xFFEFEFF1),
  };

  static const _dark = <NoteColor, Color>{
    NoteColor.red: Color(0xFF77172E),
    NoteColor.peach: Color(0xFF692B17),
    NoteColor.amber: Color(0xFF7C4A03),
    NoteColor.green: Color(0xFF264D3B),
    NoteColor.sage: Color(0xFF0C625D),
    NoteColor.blue: Color(0xFF256377),
    NoteColor.storm: Color(0xFF284255),
    NoteColor.purple: Color(0xFF472E5B),
    NoteColor.blossom: Color(0xFF6C394F),
    NoteColor.clay: Color(0xFF4B443A),
    NoteColor.chalk: Color(0xFF232427),
  };

  /// Kart/editör arka planı. [NoteColor.none] için temanın yüzey rengi döner.
  static Color surface(BuildContext context, NoteColor color) {
    final scheme = Theme.of(context).colorScheme;
    if (color == NoteColor.none) return scheme.surfaceContainerLow;
    final map = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    return map[color] ?? scheme.surfaceContainerLow;
  }

  /// Notun GERÇEK zemini: paletten özel renk seçildiyse o (okunur kalsın
  /// diye tema yüzeyine karıştırılmış — açıkta %55, koyuda %35), yoksa
  /// hazır ton ([surface]).
  static Color noteSurface(BuildContext context, Note note) {
    // Çizilmiş tema rengin önünde: notun düz zemini temanın alt tonu.
    final theme = NoteThemes.byId(note.theme);
    if (theme != null) {
      return theme
          .palette(Theme.of(context).brightness == Brightness.dark)
          .base;
    }
    final custom = note.customColor;
    if (custom == null) return surface(context, note.color);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      Color(custom).withValues(alpha: dark ? 0.35 : 0.55),
      scheme.surfaceContainerLow,
    );
  }

  /// Kart çerçevesinin rengi (özel renk önce); çerçeve yoksa null.
  static Color? noteFrame(Note note) {
    final custom = note.customFrameColor;
    if (custom != null) return Color(custom);
    if (note.frameColor == NoteColor.none) return null;
    return swatch(note.frameColor);
  }

  /// Satır içi biçimlendirmenin renk paleti: metindeki `==2:...==` /
  /// `%%2:...%%` işaretlerindeki 1..5 indeksinin karşılığı. Not renkleriyle
  /// AYNI palet kullanılır — kullanıcı iki ayrı renk kümesi öğrenmesin.
  static List<Color> get richPalette => const [
    Color(0xFFE57373),
    Color(0xFFFFC94D),
    Color(0xFF81C784),
    Color(0xFF64A5F5),
    Color(0xFFB39DDB),
  ];

  /// Renk seçicideki nokta rengi. Zeminin KENDİSİ gösterilir: kullanıcı
  /// noktaya bakınca sayfanın ne renk olacağını görür (Keep de böyle).
  /// [NoteColor.none] için tema yüzeyi kullanılamaz (bağlam yok), nötr gri.
  static Color swatch(NoteColor color) => color == NoteColor.none
      ? const Color(0xFF9E9E9E)
      : (_light[color] ?? const Color(0xFF9E9E9E));
}
