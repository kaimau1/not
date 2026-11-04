import 'package:flutter/painting.dart';

import '../../features/notes/domain/note.dart';
import '../l10n_ext.dart';

/// **RENK ADLARI** (F15.2, erişilebilirlik): renk daireleri ekran okuyucuda
/// adsızdı ya da hepsi aynı adla ("Yazı rengi") okunuyordu. Görünen renk
/// seçicilerin hepsi adını buradan alır.

/// Satır içi biçim paletinin (`NoteColors.richPalette`) beş rengi, sırayla.
List<String> richPaletteNames(AppLocalizations l10n) => [
  l10n.colorNameRed,
  l10n.colorNameYellow,
  l10n.colorNameGreen,
  l10n.colorNameBlue,
  l10n.colorNamePurple,
];

/// Not zemini / çerçeve şeridindeki hazır tonun adı.
String noteColorName(AppLocalizations l10n, NoteColor color) => switch (color) {
  NoteColor.none => l10n.colorNameNone,
  NoteColor.red => l10n.colorNameCoral,
  NoteColor.peach => l10n.colorNamePeach,
  NoteColor.amber => l10n.colorNameHoney,
  NoteColor.green => l10n.colorNameGreen,
  NoteColor.sage => l10n.colorNameSage,
  NoteColor.blue => l10n.colorNameBlue,
  NoteColor.storm => l10n.colorNameStorm,
  NoteColor.purple => l10n.colorNameLavender,
  NoteColor.blossom => l10n.colorNamePink,
  NoteColor.clay => l10n.colorNameClay,
  NoteColor.chalk => l10n.colorNameChalk,
};

/// Tam paletteki (`kPaletteColors`, 5 satır × 8 sütun) [index]. tonun adı:
/// sütun renk ailesi, satır açıklık; son satır beyazdan siyaha nötr dizi.
String paletteColorName(AppLocalizations l10n, int index) {
  final row = index ~/ 8;
  final col = index % 8;
  if (row >= 4) {
    return switch (col) {
      0 => l10n.colorNameWhite,
      7 => l10n.colorNameBlack,
      1 || 2 => l10n.colorShade(l10n.colorNameGray, l10n.colorToneLight),
      5 || 6 => l10n.colorShade(l10n.colorNameGray, l10n.colorToneDark),
      _ => l10n.colorNameGray,
    };
  }
  final family = [
    l10n.colorNameRed,
    l10n.colorNameOrange,
    l10n.colorNameYellow,
    l10n.colorNameGreen,
    l10n.colorNameCyan,
    l10n.colorNameBlue,
    l10n.colorNamePurple,
    l10n.colorNamePink,
  ][col];
  return switch (row) {
    0 => l10n.colorShade(family, l10n.colorToneLight),
    2 => l10n.colorShade(family, l10n.colorToneVivid),
    3 => l10n.colorShade(family, l10n.colorToneDark),
    _ => family,
  };
}

/// Herhangi bir rengin yaklaşık adı (ton + açıklık) — elle seçilmiş paletler
/// (balon renkleri, dolgu) için. Doygunluğu düşük renk gri dizisine düşer.
String colorNameFor(AppLocalizations l10n, Color color) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.saturation < 0.15 || hsl.lightness > 0.94 || hsl.lightness < 0.08) {
    if (hsl.lightness > 0.9) return l10n.colorNameWhite;
    if (hsl.lightness < 0.15) return l10n.colorNameBlack;
    return hsl.lightness > 0.6
        ? l10n.colorShade(l10n.colorNameGray, l10n.colorToneLight)
        : hsl.lightness < 0.35
        ? l10n.colorShade(l10n.colorNameGray, l10n.colorToneDark)
        : l10n.colorNameGray;
  }
  final h = hsl.hue;
  final family = h < 15 || h >= 340
      ? l10n.colorNameRed
      : h < 40
      ? l10n.colorNameOrange
      : h < 70
      ? l10n.colorNameYellow
      : h < 160
      ? l10n.colorNameGreen
      : h < 200
      ? l10n.colorNameCyan
      : h < 255
      ? l10n.colorNameBlue
      : h < 300
      ? l10n.colorNamePurple
      : l10n.colorNamePink;
  if (hsl.lightness > 0.75) return l10n.colorShade(family, l10n.colorToneLight);
  if (hsl.lightness < 0.35) return l10n.colorShade(family, l10n.colorToneDark);
  return family;
}
