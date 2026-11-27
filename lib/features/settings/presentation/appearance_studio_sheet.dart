import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/dashboard_wallpapers.dart';
import '../../../app/theme/note_colors.dart';
import '../../../app/theme/note_themes.dart';
import '../../../core/app_icons.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/color_palette.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/widgets/press_scale.dart';
import '../../calendar/data/holiday_source.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../entitlement/presentation/pro_lock.dart';
import '../../notes/domain/archive_paper.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/color_picker_sheet.dart';
import '../../notes/presentation/dashboard_background_sheet.dart';
import '../../notes/presentation/editor/notebook_paper.dart';
import '../settings_providers.dart';
import 'settings_screen.dart';
import 'theme_picker.dart';

/// Görünüm stüdyosunun açıldığı bağlam.
enum AppearanceContext { home, note, calendar, settings }

/// Görünüm stüdyosunun üst sekmeleri.
enum AppearanceTab { theme, background, layout }

/// Editör açıkken notun kendi görünümünü canlı düzenlemek için köprü.
@immutable
class NoteAppearanceBridge {
  const NoteAppearanceBridge({
    required this.readNote,
    required this.onTheme,
    required this.onColor,
    required this.onFrame,
    required this.onPresetWallpaper,
    required this.onPickImage,
    required this.onRemoveImage,
    this.onCropImage,
    required this.onBgOpacity,
    required this.onPaper,
    required this.onLineSpacing,
    required this.onPaged,
    required this.onUseHomeBackground,
  });

  final Note Function() readNote;
  final ValueChanged<String> onTheme;
  final ValueChanged<NoteColorPick> onColor;
  final ValueChanged<NoteColorPick> onFrame;
  final Future<void> Function(DashboardWallpaper wallpaper) onPresetWallpaper;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onRemoveImage;
  final Future<void> Function()? onCropImage;
  final ValueChanged<double> onBgOpacity;
  final ValueChanged<ArchivePaper> onPaper;
  final ValueChanged<double> onLineSpacing;
  final ValueChanged<bool> onPaged;
  final VoidCallback onUseHomeBackground;
}

/// Tema · Zemin · Düzen ayarlarını tek yerden yöneten birleşik görünüm stüdyosu.
Future<void> showAppearanceStudio(
  BuildContext context, {
  AppearanceContext contextMode = AppearanceContext.home,
  AppearanceTab? initialTab,
  NoteAppearanceBridge? noteBridge,
}) {
  final startTab =
      initialTab ??
      (contextMode == AppearanceContext.note
          ? AppearanceTab.background
          : AppearanceTab.theme);
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    barrierColor: contextMode == AppearanceContext.note
        ? Colors.transparent
        : Theme.of(context).colorScheme.scrim
              .withValues(alpha: AppAlpha.pressed),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      maxWidth: kSheetMaxWidth,
    ),
    builder: (_) => _AppearanceStudioSheet(
      contextMode: contextMode,
      initialTab: startTab,
      noteBridge: noteBridge,
    ),
  );
}

class _AppearanceStudioSheet extends ConsumerStatefulWidget {
  const _AppearanceStudioSheet({
    required this.contextMode,
    required this.initialTab,
    this.noteBridge,
  });

  final AppearanceContext contextMode;
  final AppearanceTab initialTab;
  final NoteAppearanceBridge? noteBridge;

  @override
  ConsumerState<_AppearanceStudioSheet> createState() =>
      _AppearanceStudioSheetState();
}

class _AppearanceStudioSheetState
    extends ConsumerState<_AppearanceStudioSheet> {
  late AppearanceTab _tab = widget.initialTab;
  int? _themeGroupFilter;

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final text = AppText.of(theme);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settingsAppearance,
                        style: text.sheetTitle,
                      ),
                    ),
                    FilledButton.tonal(
                      key: const ValueKey('appearance-studio-done'),
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.ok),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                SegmentedButton<AppearanceTab>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: AppearanceTab.theme,
                      icon: const Icon(
                        AppIcons.appearance,
                        size: AppIconSize.xs,
                      ),
                      label: Text(
                        l10n.appearanceTabTheme,
                        key: const ValueKey('appearance-tab-theme'),
                      ),
                    ),
                    ButtonSegment(
                      value: AppearanceTab.background,
                      icon: const Icon(
                        Icons.wallpaper_outlined,
                        size: AppIconSize.xs,
                      ),
                      label: Text(
                        l10n.appearanceTabBackground,
                        key: const ValueKey('appearance-tab-background'),
                      ),
                    ),
                    ButtonSegment(
                      value: AppearanceTab.layout,
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: AppIconSize.xs,
                      ),
                      label: Text(
                        l10n.appearanceTabLayout,
                        key: const ValueKey('appearance-tab-layout'),
                      ),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (sel) {
                    AppHaptics.tick();
                    setState(() => _tab = sel.first);
                  },
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.xs,
                AppSpace.l,
                AppSpace.xl,
              ),
              child: switch (_tab) {
                AppearanceTab.theme => _buildThemeTab(context),
                AppearanceTab.background => _buildBackgroundTab(context),
                AppearanceTab.layout => _buildLayoutTab(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTab(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = AppTokens.fromTheme(theme);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    final family = ref.watch(themeFamilyProvider);
    final brightnessMode = ref.watch(themeBrightnessModeProvider);
    final font = ref.watch(appFontProvider);
    final unlocked = ref.watch(proFeatureProvider(ProFeature.extraAppearance));
    final previewBrightness = switch (brightnessMode) {
      AppBrightnessMode.light => Brightness.light,
      AppBrightnessMode.dark => Brightness.dark,
      AppBrightnessMode.system => theme.brightness,
    };
    final groups = themeFamilyGroups(
      context,
      font,
      previewBrightness: previewBrightness,
    );
    final options = _themeGroupFilter == null
        ? [for (final g in groups) ...g.$2]
        : groups[_themeGroupFilter!].$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StudioSectionCard(
          icon: Icons.brightness_6_outlined,
          title: l10n.themePickerTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ThemeBrightnessSegmented(),
              const SizedBox(height: AppSpace.m),
              const DarkScheduleEditor(),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: AppIcons.appearance,
          title: l10n.themeGroupAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HorizontalScrollStrip(
                builder: (_, controller) => SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StudioPill(
                        label: l10n.themeGroupAll,
                        selected: _themeGroupFilter == null,
                        onTap: () => setState(() => _themeGroupFilter = null),
                      ),
                      for (var i = 0; i < groups.length; i++) ...[
                        const SizedBox(width: AppSpace.s),
                        _StudioPill(
                          label: groups[i].$1,
                          selected: _themeGroupFilter == i,
                          onTap: () => setState(() => _themeGroupFilter = i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              SizedBox(
                height: 122,
                child: HorizontalScrollStrip(
                  builder: (_, controller) => ListView.separated(
                    key: const ValueKey('studio-theme-list'),
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (_, i) {
                      final o = options[i];
                      final locked = themeFamilyLocked(
                        o.$1,
                        family,
                        unlocked: unlocked,
                      );
                      return SizedBox(
                        width: 90,
                        child: ThemeChoiceCard(
                          key: ValueKey('studio-theme-${o.$1.name}'),
                          label: o.$2,
                          themes: [o.$3],
                          selected: o.$1 == family,
                          locked: locked,
                          onTap: () {
                            if (locked) {
                              openProScreen(context, popFirst: true);
                              return;
                            }
                            AppHaptics.tick();
                            ref.read(themeFamilyProvider.notifier).set(o.$1);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.brightnessModeToggleTooltip(switch (brightnessMode) {
                  AppBrightnessMode.system => l10n.brightnessModeAuto,
                  AppBrightnessMode.light => l10n.brightnessModeLight,
                  AppBrightnessMode.dark => l10n.brightnessModeDark,
                }),
                style: text.meta.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(
          height: tokens.hairline != Colors.transparent ? AppSpace.xs : 0,
        ),
      ],
    );
  }

  Widget _buildBackgroundTab(BuildContext context) {
    final bridge = widget.noteBridge;
    if (bridge != null) return _buildNoteBackgroundTab(context, bridge);
    return _buildGlobalBackgroundTab(context);
  }

  Widget _buildGlobalBackgroundTab(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final bg = ref.watch(dashboardBackgroundProvider);
    final notifier = ref.read(dashboardBackgroundProvider.notifier);
    final noteThemeNames = _noteThemeNames(l10n);
    final hasAnyImage = bg.preset != null || bg.path != null;
    final showOpacity = hasAnyImage || bg.pattern != DashboardPattern.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bg.isCustomized)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('studio-bg-reset'),
              onPressed: () {
                AppHaptics.tick();
                notifier.reset();
              },
              icon: const Icon(Icons.restart_alt, size: AppIconSize.s),
              label: Text(l10n.dashboardBackgroundReset),
            ),
          ),
        _StudioSectionCard(
          icon: Icons.wallpaper_outlined,
          title: l10n.bgSubTabWallpapers,
          trailing: hasAnyImage
              ? TextButton(
                  onPressed: () {
                    AppHaptics.tick();
                    notifier
                      ..setPreset(null)
                      ..setPath(null);
                  },
                  child: Text(l10n.removeBackgroundImage),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 118,
                child: HorizontalScrollStrip(
                  builder: (_, controller) => ListView.separated(
                    key: const ValueKey('studio-wallpaper-list'),
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: DashboardWallpapers.all.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return _SquareChoiceTile(
                          key: const ValueKey('studio-wallpaper-none'),
                          label: l10n.patternNone,
                          selected: !hasAnyImage && bg.noteTheme == null,
                          onTap: () {
                            AppHaptics.tick();
                            notifier
                              ..setPreset(null)
                              ..setPath(null)
                              ..setNoteTheme(null);
                          },
                          child: Icon(
                            Icons.block_outlined,
                            size: AppIconSize.m,
                            color: scheme.onSurfaceVariant,
                          ),
                        );
                      }
                      final w = DashboardWallpapers.all[index - 1];
                      return _WallpaperChoiceTile(
                        key: ValueKey('studio-wallpaper-${w.id}'),
                        wallpaper: w,
                        label: w.label(l10n),
                        selected: bg.preset == w.id,
                        onTap: () {
                          AppHaptics.tick();
                          notifier.setPreset(
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
                FilledButton.tonalIcon(
                  onPressed: () => pickDashboardBackgroundImage(ref),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    size: AppIconSize.s,
                  ),
                  label: Text(
                    bg.path != null
                        ? l10n.dashboardBackgroundChange
                        : l10n.dashboardBackgroundFromDevice,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showOpacity) ...[
          const SizedBox(height: AppSpace.m),
          _StudioSectionCard(
            icon: Icons.opacity,
            title: l10n.dashboardBackgroundOpacity,
            trailing: Text(
              '%${(bg.opacity * 100).round()}',
              style: text.badge.copyWith(color: scheme.primary),
            ),
            child: Slider(
              value: bg.opacity.clamp(0.05, 1.0),
              min: 0.05,
              onChanged: notifier.setOpacity,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: Icons.auto_awesome_outlined,
          title: l10n.bgSubTabIllustrated,
          child: SizedBox(
            height: 112,
            child: HorizontalScrollStrip(
              builder: (_, controller) => ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemCount: NoteThemes.all.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
                itemBuilder: (_, i) {
                  final id = i == 0 ? '' : NoteThemes.all[i - 1].id;
                  final selected = i == 0
                      ? bg.noteTheme == null
                      : bg.noteTheme == id;
                  return _IllustratedThemeTile(
                    key: ValueKey('studio-notetheme-$id'),
                    id: id,
                    label: noteThemeNames[id] ?? id,
                    selected: selected,
                    onTap: () {
                      AppHaptics.tick();
                      notifier.setNoteTheme(i == 0 ? null : id);
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: Icons.color_lens_outlined,
          title: '${l10n.bgSubTabColors} & ${l10n.bgSubTabPatterns}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HorizontalScrollStrip(
                builder: (_, controller) => SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ColorSwatchDot(
                        color: null,
                        selected: bg.color == null,
                        onTap: () {
                          AppHaptics.tick();
                          notifier.setColor(null);
                        },
                      ),
                      for (final argb in _kStudioBgColors) ...[
                        const SizedBox(width: AppSpace.s),
                        _ColorSwatchDot(
                          color: Color(argb),
                          selected: bg.color == argb,
                          onTap: () {
                            AppHaptics.tick();
                            notifier.setColor(argb);
                          },
                        ),
                      ],
                      const SizedBox(width: AppSpace.s),
                      PaletteButton(
                        title: l10n.dashboardBackgroundColor,
                        current:
                            bg.color == null ||
                                _kStudioBgColors.contains(bg.color)
                            ? null
                            : Color(bg.color!),
                        onPicked: (c) {
                          AppHaptics.tick();
                          notifier.setColor(c.toARGB32());
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              HorizontalScrollStrip(
                builder: (_, controller) => SingleChildScrollView(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in DashboardPattern.values) ...[
                        _StudioPill(
                          label: _patternLabel(l10n, p),
                          selected: bg.pattern == p,
                          onTap: () {
                            AppHaptics.tick();
                            notifier.setPattern(p);
                          },
                        ),
                        if (p != DashboardPattern.values.last)
                          const SizedBox(width: AppSpace.s),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        Container(
          decoration: AppSurface.sheetCard(theme),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: const ValueKey('studio-apply-to-notes'),
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
              value: bg.applyToNotes,
              onChanged: (v) {
                AppHaptics.tick();
                notifier.setApplyToNotes(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBackgroundTab(
    BuildContext context,
    NoteAppearanceBridge bridge,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dashBg = ref.watch(dashboardBackgroundProvider);
    final note = bridge.readNote();
    final noteThemeNames = _noteThemeNames(l10n);
    final homeBgActive = dashBg.applyToNotes && dashBg.isCustomized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (homeBgActive && note.hasExplicitBackground) ...[
          FilledButton.tonalIcon(
            key: const ValueKey('studio-note-use-home'),
            onPressed: () {
              AppHaptics.tick();
              bridge.onUseHomeBackground();
              _refresh();
            },
            icon: const Icon(Icons.home_outlined, size: AppIconSize.s),
            label: Text(l10n.noteUseHomeBackground),
          ),
          const SizedBox(height: AppSpace.m),
        ],
        _StudioSectionCard(
          icon: Icons.auto_awesome_outlined,
          title: l10n.bgSubTabIllustrated,
          child: SizedBox(
            height: 112,
            child: HorizontalScrollStrip(
              builder: (_, controller) => ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemCount: NoteThemes.all.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
                itemBuilder: (_, i) {
                  final id = i == 0 ? '' : NoteThemes.all[i - 1].id;
                  final isPlain =
                      i == 0 &&
                      (note.isExplicitlyPlain ||
                          (!note.hasExplicitBackground && !homeBgActive));
                  final selected = i == 0 ? isPlain : note.theme == id;
                  return _IllustratedThemeTile(
                    key: ValueKey('studio-note-theme-$id'),
                    id: id,
                    label: noteThemeNames[id] ?? id,
                    selected: selected,
                    onTap: () {
                      AppHaptics.tick();
                      if (i == 0) {
                        bridge.onTheme(
                          homeBgActive ? Note.plainThemeSentinel : '',
                        );
                      } else {
                        bridge.onTheme(id);
                      }
                      _refresh();
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: Icons.wallpaper_outlined,
          title: l10n.bgSubTabWallpapers,
          trailing: note.backgroundImageId != null
              ? TextButton(
                  onPressed: () async {
                    unawaited(AppHaptics.tick());
                    await bridge.onRemoveImage();
                    _refresh();
                  },
                  child: Text(l10n.removeBackgroundImage),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 118,
                child: HorizontalScrollStrip(
                  builder: (_, controller) => ListView.separated(
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: DashboardWallpapers.all.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (_, index) {
                      final w = DashboardWallpapers.all[index];
                      return _WallpaperChoiceTile(
                        key: ValueKey('studio-note-wallpaper-${w.id}'),
                        wallpaper: w,
                        label: w.label(l10n),
                        selected: false,
                        onTap: () async {
                          unawaited(AppHaptics.tick());
                          await bridge.onPresetWallpaper(w);
                          _refresh();
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        await bridge.onPickImage();
                        _refresh();
                      },
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        size: AppIconSize.s,
                      ),
                      label: Text(l10n.noteBackgroundImage),
                    ),
                  ),
                  if (note.backgroundImageId != null &&
                      bridge.onCropImage != null) ...[
                    const SizedBox(width: AppSpace.s),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final onCrop = bridge.onCropImage!;
                        Navigator.pop(context);
                        await onCrop();
                      },
                      icon: const Icon(Icons.crop, size: AppIconSize.s),
                      label: Text(l10n.crop),
                    ),
                  ],
                ],
              ),
              if (note.backgroundImageId != null) ...[
                const SizedBox(height: AppSpace.s),
                Slider(
                  value: note.backgroundOpacity.clamp(0.05, 1.0),
                  min: 0.05,
                  onChanged: (v) {
                    bridge.onBgOpacity(v);
                    _refresh();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: Icons.color_lens_outlined,
          title: l10n.bgSubTabColors,
          child: HorizontalScrollStrip(
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in NoteColor.values) ...[
                    _ColorSwatchDot(
                      color: c == NoteColor.none ? null : NoteColors.swatch(c),
                      selected: note.customColor == null && note.color == c,
                      onTap: () {
                        AppHaptics.tick();
                        bridge.onColor((color: c, custom: null));
                        _refresh();
                      },
                    ),
                    const SizedBox(width: AppSpace.s),
                  ],
                  PaletteButton(
                    title: l10n.backgroundColor,
                    current: note.customColor == null
                        ? null
                        : Color(note.customColor!),
                    onPicked: (picked) {
                      AppHaptics.tick();
                      bridge.onColor((
                        color: NoteColor.none,
                        custom: picked.toARGB32(),
                      ));
                      _refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: Icons.border_color_outlined,
          title: l10n.bgSubTabFrame,
          child: HorizontalScrollStrip(
            builder: (_, controller) => SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in NoteColor.values) ...[
                    _ColorSwatchDot(
                      color: c == NoteColor.none ? null : NoteColors.swatch(c),
                      selected:
                          note.customFrameColor == null && note.frameColor == c,
                      onTap: () {
                        AppHaptics.tick();
                        bridge.onFrame((color: c, custom: null));
                        _refresh();
                      },
                    ),
                    const SizedBox(width: AppSpace.s),
                  ],
                  PaletteButton(
                    title: l10n.frameColor,
                    current: note.customFrameColor == null
                        ? null
                        : Color(note.customFrameColor!),
                    onPicked: (picked) {
                      AppHaptics.tick();
                      bridge.onFrame((
                        color: NoteColor.none,
                        custom: picked.toARGB32(),
                      ));
                      _refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _StudioSectionCard(
          icon: AppIcons.notebook,
          title: l10n.bgSubTabPaper,
          trailing: Icon(
            note.paged ? Icons.check_circle : Icons.circle_outlined,
            size: AppIconSize.s,
            color: note.paged ? scheme.primary : scheme.onSurfaceVariant,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.bgSubTabPaper),
                value: note.paged,
                onChanged: (v) {
                  AppHaptics.tick();
                  bridge.onPaged(v);
                  _refresh();
                },
              ),
              NotebookPaperPicker(
                initial: note.archivePaper,
                onChanged: (paper) {
                  bridge.onPaper(paper);
                  _refresh();
                },
              ),
              const SizedBox(height: AppSpace.s),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 1, label: Text(l10n.lineSpacingNormal)),
                  ButtonSegment(
                    value: Note.lineSpacingWide,
                    label: Text(l10n.lineSpacingWide),
                  ),
                  ButtonSegment(
                    value: Note.lineSpacingWider,
                    label: Text(l10n.lineSpacingWider),
                  ),
                ],
                selected: {note.lineSpacing},
                onSelectionChanged: (sel) {
                  AppHaptics.tick();
                  bridge.onLineSpacing(sel.first);
                  _refresh();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutTab(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final font = ref.watch(appFontProvider);
    final step = nearestFontScaleStep(ref.watch(fontScaleProvider));
    final bridge = widget.noteBridge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.contextMode == AppearanceContext.calendar) ...[
          _StudioSectionCard(
            icon: Icons.calendar_today_outlined,
            title: l10n.calendarHolidays,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.calendarHolidays),
                  value: ref.watch(showHolidaysProvider),
                  onChanged: (_) =>
                      ref.read(showHolidaysProvider.notifier).toggle(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.homeCalendarStrip),
                  subtitle: Text(l10n.homeCalendarStripInfo),
                  value: ref.watch(homeCalendarStripProvider),
                  onChanged: (v) =>
                      ref.read(homeCalendarStripProvider.notifier).set(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.m),
        ],
        if (widget.contextMode != AppearanceContext.calendar) ...[
          _StudioSectionCard(
            icon: Icons.text_fields,
            title: l10n.appFontSetting,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(font),
                  subtitle: Text(appFontScaleLabel(l10n, step)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => unawaited(showAppFontSheet(context, ref)),
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.s,
                  runSpacing: AppSpace.s,
                  children: [
                    for (final s in FontScaleStep.values)
                      _StudioPill(
                        label: appFontScaleLabel(l10n, s),
                        selected: s == step,
                        onTap: () {
                          AppHaptics.tick();
                          ref.read(fontScaleProvider.notifier).setStep(s);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.m),
        ],
        if (bridge == null && widget.contextMode != AppearanceContext.calendar)
          _StudioSectionCard(
            icon: Icons.view_agenda_outlined,
            title: l10n.cardElementsHeader,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.homeCalendarStrip),
                  subtitle: Text(l10n.homeCalendarStripInfo),
                  value: ref.watch(homeCalendarStripProvider),
                  onChanged: (v) =>
                      ref.read(homeCalendarStripProvider.notifier).set(v),
                ),
                const CardElementsRow(),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.m),
        Container(
          decoration: AppSurface.sheetCard(theme),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              key: const ValueKey('studio-open-personalize'),
              leading: const Icon(Icons.tune_rounded, size: AppIconSize.m),
              title: Text(l10n.personalizeTitle),
              subtitle: Text(l10n.personalizeEditBars),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final router = GoRouter.maybeOf(context);
                Navigator.pop(context);
                if (router != null) {
                  unawaited(router.push('/personalize'));
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

const _kStudioBgColors = <int>[
  0xFFEFF3EC,
  0xFFF3EFE6,
  0xFFEAEFFA,
  0xFFF7EBEF,
  0xFFE5F2EC,
  0xFFFCF3E3,
  0xFFF1EBFB,
  0xFF1F2622,
  0xFF1D2230,
  0xFF28222B,
  0xFF27241E,
  0xFF182423,
];

Map<String, String> _noteThemeNames(AppLocalizations l10n) => {
  '': l10n.noteThemeNone,
  NoteThemes.aurora: l10n.noteThemeAurora,
  NoteThemes.citrus: l10n.noteThemeCitrus,
  NoteThemes.botanical: l10n.noteThemeBotanical,
  NoteThemes.terracotta: l10n.noteThemeTerracotta,
  NoteThemes.confetti: l10n.noteThemeConfetti,
  NoteThemes.cobalt: l10n.noteThemeCobalt,
  NoteThemes.palm: l10n.noteThemePalm,
  NoteThemes.lagoon: l10n.noteThemeLagoon,
  NoteThemes.night: l10n.noteThemeNight,
  NoteThemes.sunset: l10n.noteThemeSunset,
  NoteThemes.sakura: l10n.noteThemeSakura,
  NoteThemes.waves: l10n.noteThemeWaves,
  NoteThemes.meadow: l10n.noteThemeMeadow,
  NoteThemes.paper: l10n.noteThemePaper,
};

String _patternLabel(AppLocalizations l10n, DashboardPattern p) => switch (p) {
  DashboardPattern.none => l10n.patternNone,
  DashboardPattern.dots => l10n.patternDots,
  DashboardPattern.grid => l10n.patternGrid,
  DashboardPattern.lines => l10n.patternLines,
  DashboardPattern.diagonal => l10n.patternDiagonal,
  DashboardPattern.graph => l10n.patternGraph,
};

class _StudioSectionCard extends StatelessWidget {
  const _StudioSectionCard({
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
      decoration: AppSurface.sheetCard(theme),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.m),
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
                    child: Icon(
                      icon,
                      size: AppIconSize.xs,
                      color: scheme.primary,
                    ),
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
        ),
      ),
    );
  }
}

class _StudioPill extends StatelessWidget {
  const _StudioPill({
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
    final text = AppText.of(theme);
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs + 2,
          ),
          child: Text(
            label,
            style: text.label.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: selected ? AppWeight.strong : AppWeight.medium,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareChoiceTile extends StatelessWidget {
  const _SquareChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          child: Column(
            children: [
              Container(
                height: 88,
                width: 74,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(
                    color: selected ? scheme.primary : tokens.hairline,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.badge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WallpaperChoiceTile extends StatelessWidget {
  const _WallpaperChoiceTile({
    super.key,
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
    final scheme = Theme.of(context).colorScheme;
    return _SquareChoiceTile(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(wallpaper.asset, fit: BoxFit.cover, cacheWidth: 240),
          if (selected)
            Positioned(
              right: AppSpace.xs,
              top: AppSpace.xs,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: scheme.primary,
                child: Icon(
                  Icons.check,
                  size: AppIconSize.xs,
                  color: scheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IllustratedThemeTile extends StatelessWidget {
  const _IllustratedThemeTile({
    super.key,
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SquareChoiceTile(
      label: label,
      selected: selected,
      onTap: onTap,
      child: id.isEmpty
          ? Center(
              child: Icon(
                Icons.block_outlined,
                size: AppIconSize.m,
                color: scheme.onSurfaceVariant,
              ),
            )
          : NoteThemeBackdrop(
              themeId: id,
              child: Center(
                child: selected
                    ? CircleAvatar(
                        radius: 10,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.check,
                          size: AppIconSize.xs,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  const _ColorSwatchDot({
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
    final tokens = AppTokens.fromTheme(Theme.of(context));
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : tokens.hairline,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: AppIconSize.s,
                color: color == null
                    ? scheme.primary
                    : (ThemeData.estimateBrightnessForColor(color!) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black),
              )
            : (color == null
                  ? Icon(
                      Icons.block_outlined,
                      size: AppIconSize.s,
                      color: scheme.onSurfaceVariant,
                    )
                  : null),
      ),
    );
  }
}
