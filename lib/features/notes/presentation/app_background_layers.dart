import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/dashboard_wallpapers.dart';
import '../../../app/theme/note_themes.dart';
import '../../../core/utils/image_cache_budget.dart';
import '../../../core/utils/local_file.dart' show localFileExists;
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import 'dashboard_pattern.dart';

/// Ana ekrandan notlara devralınan zemin uygulanmalı mı?
bool noteInheritsHomeBackground(Note note, DashboardBackground dashBg) =>
    dashBg.applyToNotes && dashBg.isCustomized && !note.hasExplicitBackground;

/// Notun kendi zemini yoksa ve "Notlara da uygula" açıksa, ana ekrandaki
/// çizimli tema veya düz renk not örneğine geçici olarak giydirilir.
Note effectiveNoteWithHomeBg(Note note, DashboardBackground dashBg) {
  if (!noteInheritsHomeBackground(note, dashBg)) return note;
  if (dashBg.noteTheme case final themeId?
      when NoteThemes.byId(themeId) != null) {
    return note.copyWith(theme: themeId);
  }
  if (dashBg.color case final argb?) {
    return note.copyWith(customColor: argb);
  }
  return note;
}

/// Ana ekrandan notlara devralınan desen ve zemin görselini (duvar kâğıdı veya
/// cihaz fotoğrafı) [child] katmanının arkasına sarar.
Widget wrapWithInheritedHomeBg(
  BuildContext context, {
  required Note note,
  required DashboardBackground dashBg,
  required Widget child,
  int? maxDecodeWidth,
  bool expand = false,
}) {
  if (!noteInheritsHomeBackground(note, dashBg)) return child;
  final preset = DashboardWallpapers.byId(dashBg.preset);
  final path = dashBg.path;
  final hasFile = preset == null && path != null && localFileExists(path);
  final hasPattern = dashBg.pattern != DashboardPattern.none;
  if (!hasPattern && preset == null && !hasFile) return child;
  final opacity = dashBg.opacity.clamp(0.05, 1.0).toDouble();
  final layers = <Widget>[];
  if (hasPattern) {
    layers.add(
      Positioned.fill(
        child: DashboardPatternLayer(pattern: dashBg.pattern, opacity: opacity),
      ),
    );
  }
  if (preset != null || hasFile) {
    final screenW =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(64, ImageCacheBudget.maxWallpaperWidth);
    final decodeW = maxDecodeWidth != null && maxDecodeWidth < screenW
        ? maxDecodeWidth
        : screenW;
    final ImageProvider provider = preset != null
        ? ResizeImage(AssetImage(preset.asset), width: decodeW)
        : ResizeImage(FileImage(File(path!)), width: decodeW);
    layers.add(
      Positioned.fill(
        child: Image(
          image: provider,
          fit: BoxFit.cover,
          opacity: AlwaysStoppedAnimation(opacity),
        ),
      ),
    );
  }
  layers.add(child);
  return Stack(
    fit: expand ? StackFit.expand : StackFit.loose,
    children: layers,
  );
}

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
  if (background.noteTheme case final themeId?
      when NoteThemes.byId(themeId) != null) {
    layers.add(
      Positioned.fill(
        child: NoteThemeBackdrop(
          themeId: themeId,
          child: const SizedBox.expand(),
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
