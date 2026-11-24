import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Hazır renkli arka plan görseli: ana ekran zemini (`dashboard_background_sheet`)
/// ve not zemin görseli (`note_editor_appearance`) aynı kataloğu paylaşır.
///
/// Her görsel `assets/backgrounds/<id>.jpg` içinde 900×1600 sıkıştırılmış JPEG
/// olarak gömülüdür (Android + Web çevrimdışı çalışır); ortaları nefes alır ki
/// not kartları ve not metni renkli canlılığın üstünde kolayca okunur kalsın.
@immutable
class DashboardWallpaper {
  const DashboardWallpaper({
    required this.id,
    required this.asset,
    required this.preview,
    required this.dark,
    this.defaultOpacity = 0.60,
  });

  /// SharedPreferences'ta saklanan kalıcı kimlik.
  final String id;

  /// Flutter varlık yolu (`assets/backgrounds/...`).
  final String asset;

  /// Küçük nokta / yüklenirken zemin tonu.
  final Color preview;

  /// Koyu zeminli görsel mi (koyu temayla öne çıkar, yüksek kontrast taşır).
  final bool dark;

  /// İlk seçildiğinde önerilen görünürlük.
  final double defaultOpacity;

  String label(AppLocalizations l10n) => switch (id) {
    DashboardWallpapers.auroraBloom => l10n.wallpaperAuroraBloom,
    DashboardWallpapers.citrusSun => l10n.wallpaperCitrusSun,
    DashboardWallpapers.coralLagoon => l10n.wallpaperCoralLagoon,
    DashboardWallpapers.botanicalGarden => l10n.wallpaperBotanicalGarden,
    DashboardWallpapers.lavenderDream => l10n.wallpaperLavenderDream,
    DashboardWallpapers.terracottaStudio => l10n.wallpaperTerracottaStudio,
    DashboardWallpapers.pastelConfetti => l10n.wallpaperPastelConfetti,
    DashboardWallpapers.goldenMeadow => l10n.wallpaperGoldenMeadow,
    DashboardWallpapers.midnightAurora => l10n.wallpaperMidnightAurora,
    DashboardWallpapers.velvetCosmos => l10n.wallpaperVelvetCosmos,
    _ => id,
  };
}

abstract final class DashboardWallpapers {
  static const auroraBloom = 'aurora_bloom';
  static const citrusSun = 'citrus_sun';
  static const coralLagoon = 'coral_lagoon';
  static const botanicalGarden = 'botanical_garden';
  static const lavenderDream = 'lavender_dream';
  static const terracottaStudio = 'terracotta_studio';
  static const pastelConfetti = 'pastel_confetti';
  static const goldenMeadow = 'golden_meadow';
  static const midnightAurora = 'midnight_aurora';
  static const velvetCosmos = 'velvet_cosmos';

  /// Galerideki sıra: önce aydınlık renkli suluboya/botanik/stüdyo görseller,
  /// sonda koyu kip için gece aurorası ve kadife kozmos.
  static const List<DashboardWallpaper> all = [
    DashboardWallpaper(
      id: auroraBloom,
      asset: 'assets/backgrounds/aurora_bloom.jpg',
      preview: Color(0xFF28B899),
      dark: false,
      defaultOpacity: 0.65,
    ),
    DashboardWallpaper(
      id: citrusSun,
      asset: 'assets/backgrounds/citrus_sun.jpg',
      preview: Color(0xFFF28B3C),
      dark: false,
      defaultOpacity: 0.62,
    ),
    DashboardWallpaper(
      id: coralLagoon,
      asset: 'assets/backgrounds/coral_lagoon.jpg',
      preview: Color(0xFF2DB6BD),
      dark: false,
      defaultOpacity: 0.55,
    ),
    DashboardWallpaper(
      id: botanicalGarden,
      asset: 'assets/backgrounds/botanical_garden.jpg',
      preview: Color(0xFF3E9C74),
      dark: false,
      defaultOpacity: 0.65,
    ),
    DashboardWallpaper(
      id: lavenderDream,
      asset: 'assets/backgrounds/lavender_dream.jpg',
      preview: Color(0xFFB58AE6),
      dark: false,
      defaultOpacity: 0.62,
    ),
    DashboardWallpaper(
      id: terracottaStudio,
      asset: 'assets/backgrounds/terracotta_studio.jpg',
      preview: Color(0xFFD67351),
      dark: false,
      defaultOpacity: 0.62,
    ),
    DashboardWallpaper(
      id: pastelConfetti,
      asset: 'assets/backgrounds/pastel_confetti.jpg',
      preview: Color(0xFFF08AA8),
      dark: false,
      defaultOpacity: 0.68,
    ),
    DashboardWallpaper(
      id: goldenMeadow,
      asset: 'assets/backgrounds/golden_meadow.jpg',
      preview: Color(0xFF69B56F),
      dark: false,
      defaultOpacity: 0.62,
    ),
    DashboardWallpaper(
      id: midnightAurora,
      asset: 'assets/backgrounds/midnight_aurora.jpg',
      preview: Color(0xFF1A9E8F),
      dark: true,
      defaultOpacity: 0.72,
    ),
    DashboardWallpaper(
      id: velvetCosmos,
      asset: 'assets/backgrounds/velvet_cosmos.jpg',
      preview: Color(0xFF8B4EA8),
      dark: true,
      defaultOpacity: 0.72,
    ),
  ];

  static DashboardWallpaper? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }
}
