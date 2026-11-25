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
    DashboardWallpapers.sakuraBreeze => l10n.wallpaperSakuraBreeze,
    DashboardWallpapers.oceanMist => l10n.wallpaperOceanMist,
    DashboardWallpapers.autumnMaple => l10n.wallpaperAutumnMaple,
    DashboardWallpapers.sageLinen => l10n.wallpaperSageLinen,
    DashboardWallpapers.peachHorizon => l10n.wallpaperPeachHorizon,
    DashboardWallpapers.nordicPaper => l10n.wallpaperNordicPaper,
    DashboardWallpapers.midnightAurora => l10n.wallpaperMidnightAurora,
    DashboardWallpapers.velvetCosmos => l10n.wallpaperVelvetCosmos,
    DashboardWallpapers.starryPine => l10n.wallpaperStarryPine,
    DashboardWallpapers.obsidianGold => l10n.wallpaperObsidianGold,
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
  static const sakuraBreeze = 'sakura_breeze';
  static const oceanMist = 'ocean_mist';
  static const autumnMaple = 'autumn_maple';
  static const sageLinen = 'sage_linen';
  static const peachHorizon = 'peach_horizon';
  static const nordicPaper = 'nordic_paper';
  static const midnightAurora = 'midnight_aurora';
  static const velvetCosmos = 'velvet_cosmos';
  static const starryPine = 'starry_pine';
  static const obsidianGold = 'obsidian_gold';

  /// Galerideki sıra: önce aydınlık renkli suluboya/botanik/stüdyo görseller,
  /// sonda koyu kip için gece aurorası, kadife kozmos, yıldızlı çam ve obsidyen altın.
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
      id: sakuraBreeze,
      asset: 'assets/backgrounds/sakura_breeze.jpg',
      preview: Color(0xFFE8A4B3),
      dark: false,
      defaultOpacity: 0.68,
    ),
    DashboardWallpaper(
      id: oceanMist,
      asset: 'assets/backgrounds/ocean_mist.jpg',
      preview: Color(0xFF5FB6C9),
      dark: false,
      defaultOpacity: 0.65,
    ),
    DashboardWallpaper(
      id: autumnMaple,
      asset: 'assets/backgrounds/autumn_maple.jpg',
      preview: Color(0xFFD17A42),
      dark: false,
      defaultOpacity: 0.64,
    ),
    DashboardWallpaper(
      id: sageLinen,
      asset: 'assets/backgrounds/sage_linen.jpg',
      preview: Color(0xFF7CA382),
      dark: false,
      defaultOpacity: 0.68,
    ),
    DashboardWallpaper(
      id: peachHorizon,
      asset: 'assets/backgrounds/peach_horizon.jpg',
      preview: Color(0xFFEBA082),
      dark: false,
      defaultOpacity: 0.65,
    ),
    DashboardWallpaper(
      id: nordicPaper,
      asset: 'assets/backgrounds/nordic_paper.jpg',
      preview: Color(0xFFC49D6A),
      dark: false,
      defaultOpacity: 0.68,
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
    DashboardWallpaper(
      id: starryPine,
      asset: 'assets/backgrounds/starry_pine.jpg',
      preview: Color(0xFF284664),
      dark: true,
      defaultOpacity: 0.74,
    ),
    DashboardWallpaper(
      id: obsidianGold,
      asset: 'assets/backgrounds/obsidian_gold.jpg',
      preview: Color(0xFFC8A45D),
      dark: true,
      defaultOpacity: 0.74,
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
