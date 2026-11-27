import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/dashboard_wallpapers.dart';
import '../../../app/theme/fixed_colors.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart' show localFileExists;
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/color_palette.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/toggle_pop.dart';
import '../../settings/settings_providers.dart';
import 'dashboard_pattern.dart';

/// Galeriden seçilen fotoğrafı uygulamanın kalıcı klasörüne kopyalayıp ana
/// ekran zemini olarak ayarlar (stüdyo ve eski levha ortak kullanır).
Future<void> pickDashboardBackgroundImage(WidgetRef ref) async {
  if (kIsWeb) return;
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2400,
    maxHeight: 2400,
  );
  if (file == null) return;
  final Uint8List bytes = await file.readAsBytes();
  final dir = await getApplicationDocumentsDirectory();
  final target = File('${dir.path}/dashboard_bg_${const Uuid().v4()}.img');
  await target.writeAsBytes(bytes);
  final previous = ref.read(dashboardBackgroundProvider).path;
  ref.read(dashboardBackgroundProvider.notifier).setPath(target.path);
  if (previous != null && previous != target.path) {
    unawaited(File(previous).delete().catchError((_) => File(previous)));
  }
}

/// Ana ekranın zemini: **hazır renkli görseller · renk · desen · takvim şeridi**.
///
/// **RENK, DESEN VE HAZIR ZEMİN GÖRSELLERİ**: kullanıcı hem gömülü renkli
/// arka plan galerisinden tek dokunuşla seçebilir (Android + Web çevrimdışı)
/// hem galerisinden fotoğraf ekleyebilir, isterse zemin rengi ve ince desenle
/// birleştirebilir. Levha açıkken yapılan her seçim ve görünürlük kaydırıcısı
/// ana ekrana CANLI yansır; ayrıca üstteki mini önizleme kartı anlık sonucu
/// özetler.
///
/// Galeriden seçilen fotoğraf uygulamanın kendi klasörüne KOPYALANIR: geçici
/// paylaşım önbelleği silindiğinde zemin kaybolmasın diye.
Future<void> showDashboardBackgroundSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      barrierColor: Theme.of(context).colorScheme.scrim
          .withValues(alpha: AppAlpha.pressed),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        maxWidth: kSheetMaxWidth,
      ),
      builder: (_) => const _DashboardBackgroundSheet(),
    );

class _DashboardBackgroundSheet extends ConsumerWidget {
  const _DashboardBackgroundSheet();

  Future<void> _pick(WidgetRef ref) => pickDashboardBackgroundImage(ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final background = ref.watch(dashboardBackgroundProvider);
    final preset = DashboardWallpapers.byId(background.preset);
    final hasDeviceImage =
        preset == null &&
        background.path != null &&
        localFileExists(background.path!);
    final hasAnyImage = preset != null || hasDeviceImage;
    final showOpacity =
        hasAnyImage || background.pattern != DashboardPattern.none;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.xl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: l10n.dashboardBackground,
            padding: EdgeInsets.zero,
            actions: [
              if (background.isCustomized)
                TextButton.icon(
                  key: const ValueKey('bg-reset-button'),
                  onPressed: () {
                    AppHaptics.tick();
                    ref.read(dashboardBackgroundProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.restart_alt, size: AppIconSize.s),
                  label: Text(l10n.dashboardBackgroundReset),
                ),
            ],
          ),
          Text(l10n.dashboardBackgroundInfo, style: text.meta),
          const SizedBox(height: AppSpace.m),

          // Canlı mini önizleme: aktif renk + desen + görsel + mini kartlar.
          _LiveBackgroundPreview(
            background: background,
            preset: preset,
            hasDeviceImage: hasDeviceImage,
          ),
          const SizedBox(height: AppSpace.m),

          // 1 · Hazır renkli zemin görselleri + cihaz galerisi.
          _BgSectionCard(
            icon: Icons.wallpaper_outlined,
            title: l10n.dashboardBackgroundGallery,
            trailing: hasAnyImage
                ? TextButton(
                    onPressed: () {
                      AppHaptics.tick();
                      final notifier = ref.read(
                        dashboardBackgroundProvider.notifier,
                      );
                      notifier
                        ..setPreset(null)
                        ..setPath(null);
                    },
                    child: Text(l10n.removeBackgroundImage),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 122,
                  child: HorizontalScrollStrip(
                    builder: (_, controller) => ListView.separated(
                      key: const ValueKey('bg-wallpaper-gallery'),
                      controller: controller,
                      scrollDirection: Axis.horizontal,
                      itemCount: DashboardWallpapers.all.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpace.s),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _PlainWallpaperTile(
                            label: l10n.patternNone,
                            selected: !hasAnyImage,
                            onTap: () {
                              AppHaptics.tick();
                              ref.read(dashboardBackgroundProvider.notifier)
                                ..setPreset(null)
                                ..setPath(null);
                            },
                          );
                        }
                        final w = DashboardWallpapers.all[index - 1];
                        return _WallpaperTile(
                          wallpaper: w,
                          label: w.label(l10n),
                          selected: preset?.id == w.id,
                          onTap: () {
                            AppHaptics.tick();
                            ref
                                .read(dashboardBackgroundProvider.notifier)
                                .setPreset(
                                  w.id,
                                  defaultOpacity: w.defaultOpacity,
                                );
                          },
                        );
                      },
                    ),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: AppSpace.m),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('bg-pick-device-image'),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                      ),
                      onPressed: () => _pick(ref),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        size: AppIconSize.s,
                      ),
                      label: Text(
                        hasDeviceImage
                            ? l10n.dashboardBackgroundChange
                            : l10n.dashboardBackgroundFromDevice,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Görünürlük kaydırıcısı (hazır görsel, cihaz fotoğrafı veya desen varken).
          if (showOpacity) ...[
            const SizedBox(height: AppSpace.m),
            _BgSectionCard(
              icon: Icons.opacity,
              title: l10n.dashboardBackgroundOpacity,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: tokens.resolvedTintSoft(scheme),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Text(
                  '%${(background.opacity * 100).round()}',
                  style: text.badge.copyWith(color: scheme.primary),
                ),
              ),
              child: Slider(
                key: const ValueKey('bg-opacity-slider'),
                value: background.opacity.clamp(0.05, 1),
                min: 0.05,
                onChanged: (value) => ref
                    .read(dashboardBackgroundProvider.notifier)
                    .setOpacity(value),
              ),
            ),
          ],

          // 2 · Zemin rengi.
          const SizedBox(height: AppSpace.m),
          _BgSectionCard(
            icon: Icons.color_lens_outlined,
            title: l10n.dashboardBackgroundColor,
            child: Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                _ColorDot(
                  color: null,
                  selected: background.color == null,
                  onTap: () {
                    AppHaptics.tick();
                    ref
                        .read(dashboardBackgroundProvider.notifier)
                        .setColor(null);
                  },
                ),
                for (final argb in _kBackgroundColors)
                  _ColorDot(
                    color: Color(argb),
                    selected: background.color == argb,
                    onTap: () {
                      AppHaptics.tick();
                      ref
                          .read(dashboardBackgroundProvider.notifier)
                          .setColor(argb);
                    },
                  ),
                PaletteButton(
                  title: l10n.dashboardBackgroundColor,
                  size: 38,
                  current:
                      background.color == null ||
                          _kBackgroundColors.contains(background.color)
                      ? null
                      : Color(background.color!),
                  onPicked: (c) {
                    AppHaptics.tick();
                    ref
                        .read(dashboardBackgroundProvider.notifier)
                        .setColor(c.toARGB32());
                  },
                ),
              ],
            ),
          ),

          // 3 · Desen (dengeli 3×2 ızgara).
          const SizedBox(height: AppSpace.m),
          _BgSectionCard(
            icon: Icons.grid_4x4_rounded,
            title: l10n.dashboardBackgroundPattern,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                const gap = AppSpace.s;
                final tileWidth =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                final previewGround = background.color != null
                    ? Color(background.color!)
                    : scheme.surfaceContainerHigh;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final pattern in DashboardPattern.values)
                      SizedBox(
                        width: tileWidth,
                        child: _PatternChip(
                          pattern: pattern,
                          label: _patternLabel(context, pattern),
                          ground: previewGround,
                          selected: background.pattern == pattern,
                          onTap: () {
                            AppHaptics.tick();
                            ref
                                .read(dashboardBackgroundProvider.notifier)
                                .setPattern(pattern);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 4 · Üstte takvim şeridi.
          const SizedBox(height: AppSpace.m),
          Container(
            decoration: AppSurface.sheetCard(theme),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const ValueKey('dashboard-calendar-strip'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.m,
                  vertical: AppSpace.xs,
                ),
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.resolvedTintSoft(scheme),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(
                    Icons.calendar_view_week_outlined,
                    size: AppIconSize.m,
                    color: scheme.primary,
                  ),
                ),
                title: Text(l10n.homeCalendarStrip, style: text.rowTitle),
                subtitle: Text(l10n.homeCalendarStripInfo, style: text.meta),
                value: ref.watch(homeCalendarStripProvider),
                onChanged: (v) {
                  AppHaptics.tick();
                  ref.read(homeCalendarStripProvider.notifier).set(v);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpace.m),
          Container(
            decoration: AppSurface.sheetCard(theme),
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                key: const ValueKey('bg-apply-to-notes'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.m,
                  vertical: AppSpace.xs,
                ),
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.resolvedTintSoft(scheme),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(
                    Icons.note_outlined,
                    size: AppIconSize.m,
                    color: scheme.primary,
                  ),
                ),
                title: Text(
                  l10n.applyHomeBackgroundToNotes,
                  style: text.rowTitle,
                ),
                subtitle: Text(
                  l10n.applyHomeBackgroundToNotesInfo,
                  style: text.meta,
                ),
                value: background.applyToNotes,
                onChanged: (v) {
                  AppHaptics.tick();
                  ref
                      .read(dashboardBackgroundProvider.notifier)
                      .setApplyToNotes(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bölüm kartı: levha zemininden ayrışan temiz çerçeveli blok + simge rozeti.
class _BgSectionCard extends StatelessWidget {
  const _BgSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: AppSurface.sheetCard(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tokens.resolvedTintSoft(scheme),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Icon(icon, size: AppIconSize.xs, color: scheme.primary),
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(child: Text(title, style: text.section)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpace.m),
          child,
        ],
      ),
    );
  }
}

/// Seçili renk + desen + görseli iki minyatür not kartıyla anında gösteren kart.
class _LiveBackgroundPreview extends StatelessWidget {
  const _LiveBackgroundPreview({
    required this.background,
    required this.preset,
    required this.hasDeviceImage,
  });

  final DashboardBackground background;
  final DashboardWallpaper? preset;
  final bool hasDeviceImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final ground = background.color != null
        ? Color(background.color!)
        : scheme.surface;
    final opacity = background.opacity.clamp(0.05, 1).toDouble();
    return Container(
      height: 102,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: tokens.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: ground),
            if (background.pattern != DashboardPattern.none)
              DashboardPatternLayer(
                pattern: background.pattern,
                opacity: opacity,
                cell: 16,
              ),
            if (preset != null)
              Image.asset(
                preset!.asset,
                fit: BoxFit.cover,
                cacheWidth: 640,
                opacity: AlwaysStoppedAnimation(opacity),
              )
            else if (hasDeviceImage)
              Image.file(
                File(background.path!),
                fit: BoxFit.cover,
                cacheWidth: 640,
                opacity: AlwaysStoppedAnimation(opacity),
              ),
            // Mini arama çubuğu + iki not kartı silueti.
            Padding(
              padding: const EdgeInsets.all(AppSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: tokens.hairline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: AppAlpha.disabled,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.hair),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniPreviewCard(
                            tokens: tokens,
                            scheme: scheme,
                            accentLine: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpace.s),
                        Expanded(
                          child: _MiniPreviewCard(
                            tokens: tokens,
                            scheme: scheme,
                            accentLine: scheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPreviewCard extends StatelessWidget {
  const _MiniPreviewCard({
    required this.tokens,
    required this.scheme,
    required this.accentLine,
  });

  final AppTokens tokens;
  final ColorScheme scheme;
  final Color accentLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: tokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: AppAlpha.strong),
              borderRadius: BorderRadius.circular(AppRadius.hair),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Container(
            width: 82,
            height: 3.5,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: AppAlpha.soft),
              borderRadius: BorderRadius.circular(AppRadius.hair),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: accentLine.withValues(alpha: AppAlpha.soft),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Düz" (görsel yok) karosu.
class _PlainWallpaperTile extends StatelessWidget {
  const _PlainWallpaperTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        child: GestureDetector(
          key: const ValueKey('bg-wallpaper-none'),
          onTap: onTap,
          child: SizedBox(
            width: 74,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.short),
                  curve: AppMotion.curveOf(context, AppMotion.emphasized),
                  height: 92,
                  padding: const EdgeInsets.all(AppSpace.xxs),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(
                      color: selected ? scheme.primary : tokens.hairline,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.s),
                    ),
                    child: Center(
                      child: Icon(
                        selected ? Icons.check_circle : Icons.block_outlined,
                        size: AppIconSize.l,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                    fontWeight: selected ? AppWeight.strong : AppWeight.medium,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek hazır renkli zemin görseli karosu.
class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.wallpaper,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DashboardWallpaper wallpaper;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        child: GestureDetector(
          key: ValueKey('bg-wallpaper-${wallpaper.id}'),
          onTap: onTap,
          child: SizedBox(
            width: 74,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.short),
                  curve: AppMotion.curveOf(context, AppMotion.emphasized),
                  height: 92,
                  padding: const EdgeInsets.all(AppSpace.xxs),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(
                      color: selected ? scheme.primary : tokens.hairline,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.s),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: wallpaper.preview),
                        Image.asset(
                          wallpaper.asset,
                          fit: BoxFit.cover,
                          cacheWidth: 240,
                        ),
                        if (selected)
                          Positioned(
                            right: AppSpace.xs,
                            top: AppSpace.xs,
                            child: TogglePop(
                              on: selected,
                              child: CircleAvatar(
                                radius: 9,
                                backgroundColor: scheme.primary,
                                child: Icon(
                                  Icons.check,
                                  size: AppIconSize.xs - 3,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                    fontWeight: selected ? AppWeight.strong : AppWeight.medium,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zemin rengi seçenekleri: hem aydınlık hem koyu, nota uygun yumuşak ve canlı
/// tonlar (kart ızgarası her temada net okunur).
const _kBackgroundColors = <int>[
  0xFFE4EFE9, // adaçayı
  0xFFE3ECF7, // buz mavisi
  0xFFEAE5F6, // lavanta
  0xFFF7E8EC, // gül
  0xFFF8E6DC, // şeftali
  0xFFF5EEDB, // krem
  0xFFECEEF1, // taş grisi
  0xFF1A2520, // koyu adaçayı
  0xFF182230, // gece mavisi
  0xFF281F30, // koyu erik
  0xFF271F1A, // koyu kahve
  0xFF121518, // is
];

String _patternLabel(BuildContext context, DashboardPattern pattern) {
  final l10n = context.l10n;
  return switch (pattern) {
    DashboardPattern.none => l10n.patternNone,
    DashboardPattern.dots => l10n.patternDots,
    DashboardPattern.grid => l10n.patternGrid,
    DashboardPattern.lines => l10n.patternLines,
    DashboardPattern.diagonal => l10n.patternDiagonal,
    DashboardPattern.graph => l10n.patternGraph,
  };
}

/// Tek bir renk dairesi. [color] null ise "renk yok" (temanın yüzeyi).
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.surface;
    return MinTapTarget(
      child: PressScale(
        child: InkResponse(
          onTap: onTap,
          radius: 22,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.short),
            curve: AppMotion.curveOf(context, AppMotion.emphasized),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
            child: color == null
                ? Icon(
                    Icons.format_color_reset,
                    size: AppIconSize.xs,
                    color: selected ? scheme.primary : scheme.outline,
                  )
                : (selected
                      ? TogglePop(
                          on: selected,
                          child: Icon(
                            Icons.check,
                            size: AppIconSize.s,
                            color: FixedColors.inkOn(fill),
                          ),
                        )
                      : null),
          ),
        ),
      ),
    );
  }
}

/// Deseni küçük bir kutuda ÇİZEN seçim çipi.
class _PatternChip extends StatelessWidget {
  const _PatternChip({
    required this.pattern,
    required this.label,
    required this.ground,
    required this.selected,
    required this.onTap,
  });

  final DashboardPattern pattern;
  final String label;
  final Color ground;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.short),
          curve: AppMotion.curveOf(context, AppMotion.emphasized),
          padding: const EdgeInsets.all(AppSpace.xs + 2),
          decoration: BoxDecoration(
            color: selected ? tokens.resolvedTintSoft(scheme) : tokens.card,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: selected ? scheme.primary : tokens.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.s),
                child: SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ColoredBox(
                    color: ground,
                    // Önizlemede desen tam görünürlükte ve küçük aralıkla:
                    // 44 dp'lik kutuda 28 dp'lik aralık tek çizgi gösterirdi.
                    child: DashboardPatternLayer(
                      pattern: pattern,
                      opacity: 1,
                      cell: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.meta.copyWith(
                  fontWeight: selected ? AppWeight.strong : AppWeight.medium,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
