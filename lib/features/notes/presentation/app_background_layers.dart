import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/dashboard_wallpapers.dart';
import '../../../core/utils/image_cache_budget.dart';
import '../../../core/utils/local_file.dart' show localFileExists;
import '../../settings/settings_providers.dart';
import 'dashboard_pattern.dart';

/// Saydam üst çubuğun (zemin varken) durum çubuğu stili: simgeler temanın
/// parlaklığına göre — opak `surface` zeminle aynı sonuç.
SystemUiOverlayStyle statusBarOverZemin(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
  );
}

/// Ana ekran ve Takvim ekranının ortak tam ekran zemini: **renk → desen →
/// görsel** (üçü de isteğe bağlı, üst üste binebilirler).
List<Widget> buildAppBackgroundLayers(BuildContext context, WidgetRef ref) {
  final background = ref.watch(dashboardBackgroundProvider);
  final layers = <Widget>[];
  final color = background.color;
  if (color != null) {
    layers.add(Positioned.fill(child: ColoredBox(color: Color(color))));
  }
  if (background.pattern != DashboardPattern.none) {
    layers.add(
      Positioned.fill(
        child: DashboardPatternLayer(
          pattern: background.pattern,
          opacity: background.opacity,
        ),
      ),
    );
  }
  final preset = DashboardWallpapers.byId(background.preset);
  final path = background.path;
  final hasFile = preset == null && path != null && localFileExists(path);
  final opacity = background.opacity.clamp(0.05, 1).toDouble();
  Widget? imageLayer;
  if (preset != null || hasFile) {
    final targetWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(64, ImageCacheBudget.maxWallpaperWidth);
    final ImageProvider provider = preset != null
        ? ResizeImage(AssetImage(preset.asset), width: targetWidth)
        : ResizeImage(FileImage(File(path!)), width: targetWidth);
    final key = ValueKey(preset != null ? 'preset:${preset.id}' : 'file:$path');
    // PİL: `Opacity` widget'ı yerine görselin KENDİ opaklığı; sonsuz en/boy
    // `AnimatedSwitcher`'daki gevşek kısıtta `BoxFit.cover`ın ekranı tam
    // kaplamasını sağlar.
    imageLayer = RepaintBoundary(
      key: key,
      child: Image(
        image: provider,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(opacity),
      ),
    );
  }
  if (imageLayer != null) {
    layers.add(
      Positioned.fill(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.medium),
          switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
          switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
          child: imageLayer,
        ),
      ),
    );
  }
  return layers;
}
