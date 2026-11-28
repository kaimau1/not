import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/app_icons.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/toggle_pop.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../entitlement/presentation/pro_lock.dart';
import '../settings_providers.dart';

typedef ThemeOption = (AppThemeChoice, String, List<ThemeData>);
typedef ThemeFamilyOption = (ThemeFamily, String, ThemeData);

/// Aile seçiminde PRO kilidi kontrolü (`ThemeChoiceCard` ile uyumlu).
bool themeFamilyLocked(
  ThemeFamily option,
  ThemeFamily current, {
  required bool unlocked,
}) => AppearanceGate.locked(
  option.name,
  free: AppearanceGate.freeThemes,
  current: current.name,
  unlocked: unlocked,
);

/// Her tema ailesinde **Otomatik · Açık · Koyu** 3-lü parlaklık anahtarı.
class ThemeBrightnessSegmented extends ConsumerWidget {
  const ThemeBrightnessSegmented({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeBrightnessModeProvider);
    return SegmentedButton<AppBrightnessMode>(
      key: const ValueKey('appearance-brightness'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: AppBrightnessMode.system,
          icon: const Icon(
            Icons.brightness_auto_outlined,
            size: AppIconSize.xs,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.brightnessModeAuto, maxLines: 1, softWrap: false),
          ),
        ),
        ButtonSegment(
          value: AppBrightnessMode.light,
          icon: const Icon(Icons.light_mode_outlined, size: AppIconSize.xs),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.brightnessModeLight, maxLines: 1, softWrap: false),
          ),
        ),
        ButtonSegment(
          value: AppBrightnessMode.dark,
          icon: const Icon(Icons.dark_mode_outlined, size: AppIconSize.xs),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.brightnessModeDark, maxLines: 1, softWrap: false),
          ),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (sel) {
        AppHaptics.tick();
        ref.read(themeBrightnessModeProvider.notifier).set(sel.first);
      },
    );
  }
}

/// PL6 `extraAppearance` kapısı: bu tema şimdi YENİ seçim için kilitli mi.
/// Seçili tema ve ücretsiz temel set ([AppearanceGate]) hiç kilitlenmez.
bool themeChoiceLocked(
  AppThemeChoice option,
  AppThemeChoice current, {
  required bool unlocked,
}) => AppearanceGate.locked(
  option.name,
  free: AppearanceGate.freeThemes,
  current: current.name,
  unlocked: unlocked,
);

/// **ÜÇ GRUP** (DENEYIM_PLANI F73.4, K-D9): Sakin · Kâğıt · Canlı. Aile
/// silinmez, yalnız sıra ve grup adı. "Koyu" Sakin'in sonunda.
const themeChoiceGroupOrder = <List<AppThemeChoice>>[
  [
    AppThemeChoice.system,
    AppThemeChoice.sage,
    AppThemeChoice.porcelain,
    AppThemeChoice.clay,
    AppThemeChoice.lavender,
    AppThemeChoice.olive,
    AppThemeChoice.mint,
    AppThemeChoice.peach,
    AppThemeChoice.dark,
  ],
  [
    AppThemeChoice.white,
    AppThemeChoice.straw,
    AppThemeChoice.cream,
    AppThemeChoice.classic,
    AppThemeChoice.newsprint,
    AppThemeChoice.notebook,
    AppThemeChoice.graphite,
    AppThemeChoice.ledger,
  ],
  [
    AppThemeChoice.ocean,
    AppThemeChoice.rose,
    AppThemeChoice.tangerine,
    AppThemeChoice.emerald,
    AppThemeChoice.amethyst,
  ],
];

const _groupIcons = <IconData>[
  Icons.spa_outlined,
  Icons.description_outlined,
  AppIcons.appearance,
];

/// Gruplu tema seçenekleri: (grup adı, seçenekler).
List<(String, List<ThemeOption>)> themeChoiceGroups(
  BuildContext context,
  String font, {
  Brightness? previewBrightness,
}) {
  final l10n = context.l10n;
  final b = previewBrightness ?? Brightness.light;
  final all = {
    for (final o in _allThemeOptions(context, font, previewBrightness: b))
      o.$1: o,
  };
  final names = [
    l10n.themeGroupCalm,
    l10n.themeGroupPaper,
    l10n.themeGroupVivid,
  ];
  return [
    for (var i = 0; i < themeChoiceGroupOrder.length; i++)
      (names[i], [for (final c in themeChoiceGroupOrder[i]) all[c]!]),
  ];
}

/// 20 özgün tema ailesini gruplar halinde ve seçili parlaklıkta döndürür.
List<(String, List<ThemeFamilyOption>)> themeFamilyGroups(
  BuildContext context,
  String font, {
  Brightness? previewBrightness,
}) {
  final l10n = context.l10n;
  final b = previewBrightness ?? Theme.of(context).brightness;
  final names = [
    l10n.themeGroupCalm,
    l10n.themeGroupPaper,
    l10n.themeGroupVivid,
  ];
  const order = <List<ThemeFamily>>[
    [
      ThemeFamily.sage,
      ThemeFamily.porcelain,
      ThemeFamily.clay,
      ThemeFamily.lavender,
      ThemeFamily.olive,
      ThemeFamily.mint,
      ThemeFamily.peach,
    ],
    [
      ThemeFamily.white,
      ThemeFamily.straw,
      ThemeFamily.cream,
      ThemeFamily.classic,
      ThemeFamily.newsprint,
      ThemeFamily.notebook,
      ThemeFamily.graphite,
      ThemeFamily.ledger,
    ],
    [
      ThemeFamily.ocean,
      ThemeFamily.rose,
      ThemeFamily.tangerine,
      ThemeFamily.emerald,
      ThemeFamily.amethyst,
    ],
  ];
  String labelOf(ThemeFamily f) => switch (f) {
    ThemeFamily.sage => l10n.themeSage,
    ThemeFamily.porcelain => l10n.themePorcelain,
    ThemeFamily.clay => l10n.themeClay,
    ThemeFamily.lavender => l10n.themeLavender,
    ThemeFamily.olive => l10n.themeOlive,
    ThemeFamily.mint => l10n.themeMint,
    ThemeFamily.peach => l10n.themePeach,
    ThemeFamily.white => l10n.themeWhite,
    ThemeFamily.straw => l10n.themeStraw,
    ThemeFamily.cream => l10n.themeCream,
    ThemeFamily.classic => l10n.themeClassic,
    ThemeFamily.newsprint => l10n.themeNewsprint,
    ThemeFamily.notebook => l10n.themeNotebook,
    ThemeFamily.graphite => l10n.themeGraphite,
    ThemeFamily.ledger => l10n.themeLedger,
    ThemeFamily.ocean => l10n.themeOcean,
    ThemeFamily.rose => l10n.themeRose,
    ThemeFamily.tangerine => l10n.themeTangerine,
    ThemeFamily.emerald => l10n.themeEmerald,
    ThemeFamily.amethyst => l10n.themeAmethyst,
  };
  return [
    for (var i = 0; i < order.length; i++)
      (
        names[i],
        [
          for (final f in order[i])
            (f, labelOf(f), AppTheme.of(f, b, font: font)),
        ],
      ),
  ];
}

/// Tema seçeneklerinin TEK listesi (Ayarlar → Görünüm ve ana ekrandaki tema
/// levhası aynı sırayı gösterir) — gruplar sırasıyla düzleştirilmiş.
List<ThemeOption> themeChoiceOptions(
  BuildContext context,
  String font, {
  Brightness? previewBrightness,
}) => [
  for (final g in themeChoiceGroups(
    context,
    font,
    previewBrightness: previewBrightness,
  ))
    ...g.$2,
];

/// Üçüncü öğe önizlemede çizilen tema(lar): Sistem açık + koyu iki yarım.
List<ThemeOption> _allThemeOptions(
  BuildContext context,
  String font, {
  Brightness previewBrightness = Brightness.light,
}) {
  final l10n = context.l10n;
  ThemeData of(ThemeFamily f, Brightness b) => AppTheme.of(f, b, font: font);
  ThemeData preview(ThemeFamily f) => of(f, previewBrightness);
  final sage = preview(ThemeFamily.sage);
  final dark = of(ThemeFamily.sage, Brightness.dark);
  return [
    (
      AppThemeChoice.system,
      l10n.themeSystem,
      [of(ThemeFamily.sage, Brightness.light), dark],
    ),
    (AppThemeChoice.sage, l10n.themeSage, [sage]),
    (
      AppThemeChoice.porcelain,
      l10n.themePorcelain,
      [preview(ThemeFamily.porcelain)],
    ),
    (AppThemeChoice.clay, l10n.themeClay, [preview(ThemeFamily.clay)]),
    (
      AppThemeChoice.lavender,
      l10n.themeLavender,
      [preview(ThemeFamily.lavender)],
    ),
    (AppThemeChoice.olive, l10n.themeOlive, [preview(ThemeFamily.olive)]),
    (AppThemeChoice.white, l10n.themeWhite, [preview(ThemeFamily.white)]),
    (AppThemeChoice.straw, l10n.themeStraw, [preview(ThemeFamily.straw)]),
    (AppThemeChoice.cream, l10n.themeCream, [preview(ThemeFamily.cream)]),
    (AppThemeChoice.peach, l10n.themePeach, [preview(ThemeFamily.peach)]),
    (AppThemeChoice.mint, l10n.themeMint, [preview(ThemeFamily.mint)]),
    // CANLI TEMALAR (2026-11-06).
    (AppThemeChoice.ocean, l10n.themeOcean, [preview(ThemeFamily.ocean)]),
    (AppThemeChoice.rose, l10n.themeRose, [preview(ThemeFamily.rose)]),
    (
      AppThemeChoice.tangerine,
      l10n.themeTangerine,
      [preview(ThemeFamily.tangerine)],
    ),
    (AppThemeChoice.emerald, l10n.themeEmerald, [preview(ThemeFamily.emerald)]),
    (
      AppThemeChoice.amethyst,
      l10n.themeAmethyst,
      [preview(ThemeFamily.amethyst)],
    ),
    // SADE KLASİK TEMALAR (2026-11-08).
    (AppThemeChoice.classic, l10n.themeClassic, [preview(ThemeFamily.classic)]),
    (
      AppThemeChoice.newsprint,
      l10n.themeNewsprint,
      [preview(ThemeFamily.newsprint)],
    ),
    (
      AppThemeChoice.notebook,
      l10n.themeNotebook,
      [preview(ThemeFamily.notebook)],
    ),
    (
      AppThemeChoice.graphite,
      l10n.themeGraphite,
      [preview(ThemeFamily.graphite)],
    ),
    (AppThemeChoice.ledger, l10n.themeLedger, [preview(ThemeFamily.ledger)]),
    (AppThemeChoice.dark, l10n.themeDark, [dark]),
  ];
}

/// TEMA KARTLARI ızgarası (Ayarlar → Görünüm).
///
/// Üstte etkin temanın canlı palet kartı, altında üç grup (Sakin · Kâğıt ·
/// Canlı): her kart minyatür bir Notlar arayüzü + üç palet noktası çizer ki
/// bütün 22 tema tek bakışta birbirinden ayrılsın.
class ThemeChoiceGrid extends ConsumerWidget {
  const ThemeChoiceGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(themeChoiceProvider);
    final unlocked = ref.watch(proFeatureProvider(ProFeature.extraAppearance));
    final brightnessMode = ref.watch(themeBrightnessModeProvider);
    final previewBrightness = switch (brightnessMode) {
      AppBrightnessMode.light => Brightness.light,
      AppBrightnessMode.dark => Brightness.dark,
      AppBrightnessMode.system => Theme.of(context).brightness,
    };
    final groups = themeChoiceGroups(
      context,
      ref.watch(appFontProvider),
      previewBrightness: previewBrightness,
    );
    final active = _findActiveOption(groups, choice);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.s;
        final w = constraints.maxWidth;
        final perRow = w < 440 ? 3 : (w < 760 ? 5 : 7);
        final width = (w - gap * (perRow - 1)) / perRow;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (active != null) ...[
              _ActiveThemeBanner(groupName: active.$1, option: active.$2),
              const SizedBox(height: AppSpace.l),
            ],
            for (var g = 0; g < groups.length; g++) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: g == 0 ? 0 : AppSpace.l,
                  bottom: AppSpace.s,
                ),
                child: _ThemeGroupHeader(
                  icon: _groupIcons[g],
                  title: groups[g].$1,
                  count: groups[g].$2.length,
                ),
              ),
              Wrap(
                spacing: gap,
                runSpacing: AppSpace.m,
                children: [
                  for (final option in groups[g].$2)
                    SizedBox(
                      width: width,
                      child: ThemeChoiceCard(
                        label: option.$2,
                        themes: option.$3,
                        selected: choice == option.$1,
                        locked: themeChoiceLocked(
                          option.$1,
                          choice,
                          unlocked: unlocked,
                        ),
                        onTap: () {
                          if (themeChoiceLocked(
                            option.$1,
                            choice,
                            unlocked: unlocked,
                          )) {
                            openProScreen(context);
                            return;
                          }
                          AppHaptics.tick();
                          ref.read(themeChoiceProvider.notifier).set(option.$1);
                        },
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  static (String, ThemeOption)? _findActiveOption(
    List<(String, List<ThemeOption>)> groups,
    AppThemeChoice choice,
  ) {
    for (final (name, options) in groups) {
      for (final o in options) {
        if (o.$1 == choice) return (name, o);
      }
    }
    return null;
  }
}

/// Üstte seçili temayı ve canlı renk paletini sergileyen vitrin kartı.
class _ActiveThemeBanner extends StatelessWidget {
  const _ActiveThemeBanner({required this.groupName, required this.option});

  final String groupName;
  final ThemeOption option;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final swatches = <Color>[
      scheme.surface,
      tokens.card,
      scheme.primary,
      scheme.primaryContainer,
      scheme.secondary,
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: AppSurface.paper(theme),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.resolvedTintSoft(scheme),
              borderRadius: BorderRadius.circular(AppRadius.m),
              border: Border.all(color: tokens.resolvedAccentBorder(scheme)),
            ),
            child: Icon(
              AppIcons.appearance,
              size: AppIconSize.m,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.themeActiveLabel}: ${option.$2}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.label.copyWith(fontWeight: AppWeight.strong),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(groupName, style: text.meta),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < swatches.length; i++)
                Container(
                  width: 16,
                  height: 16,
                  margin: EdgeInsetsDirectional.only(
                    start: i == 0 ? 0 : AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: swatches[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.hairline),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeGroupHeader extends StatelessWidget {
  const _ThemeGroupHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: tokens.resolvedTintSoft(scheme),
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Icon(icon, size: AppIconSize.xs, color: scheme.primary),
        ),
        const SizedBox(width: AppSpace.s),
        Expanded(child: SectionLabel(title)),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: text.badge.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// **TEMA LEVHASI** (kullanıcı isteği 2026-11-06: "menüde tema seçim düğmesi
/// olsun; basınca altta temalar, üstte ana ekran canlı görünsün"). Alçak
/// levha, perde YOK: dokunulan tema anında uygulanır, ana ekran levhanın
/// üstünde yeni renkleriyle görünür. Kayıt ayarlardaki seçimle aynı
/// (`themeChoiceProvider`); "Vazgeç" açılıştaki temaya döner.
Future<void> showThemePickerSheet(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final before = container.read(themeChoiceProvider);
  final beforeBrightness = container.read(themeBrightnessModeProvider);
  return showAppSheet<void>(
    context: context,
    barrierColor: Colors.transparent,
    showDragHandle: true,
    builder: (_) =>
        _ThemePickerSheet(initial: before, initialBrightness: beforeBrightness),
  );
}

/// Levha sırası (gruplar düzleştirilmiş) ve grup başlarının indeksleri.
final List<AppThemeChoice> _themeOrder = [
  for (final g in themeChoiceGroupOrder) ...g,
];
final Set<int> _groupStarts = {
  for (final g in themeChoiceGroupOrder) _themeOrder.indexOf(g.first),
};

class _ThemePickerSheet extends ConsumerStatefulWidget {
  const _ThemePickerSheet({
    required this.initial,
    required this.initialBrightness,
  });

  final AppThemeChoice initial;
  final AppBrightnessMode initialBrightness;

  @override
  ConsumerState<_ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends ConsumerState<_ThemePickerSheet> {
  /// Seçili tema görünür alanda açılsın (yalnız açılışta).
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: math.max(
      0,
      (_themeOrder.indexOf(widget.initial) - 1) * 98.0,
    ),
  );

  /// Hızlı grup süzgeci: null = Tümü, 0/1/2 = Sakin/Kâğıt/Canlı.
  int? _groupFilter;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _selectGroup(int? index) {
    if (_groupFilter == index) return;
    AppHaptics.tick();
    setState(() => _groupFilter = index);
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final choice = ref.watch(themeChoiceProvider);
    final brightnessMode = ref.watch(themeBrightnessModeProvider);
    final previewBrightness = switch (brightnessMode) {
      AppBrightnessMode.light => Brightness.light,
      AppBrightnessMode.dark => Brightness.dark,
      AppBrightnessMode.system => theme.brightness,
    };
    final unlocked = ref.watch(proFeatureProvider(ProFeature.extraAppearance));
    final font = ref.watch(appFontProvider);
    final groups = themeChoiceGroups(
      context,
      font,
      previewBrightness: previewBrightness,
    );
    final options = _groupFilter == null
        ? themeChoiceOptions(
            context,
            font,
            previewBrightness: previewBrightness,
          )
        : groups[_groupFilter!].$2;
    final changed =
        choice != initial || brightnessMode != widget.initialBrightness;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.m,
                AppSpace.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.themePickerTitle, style: text.sheetTitle),
                  ),
                  if (changed)
                    TextButton(
                      key: const ValueKey('theme-sheet-revert'),
                      onPressed: () {
                        AppHaptics.tick();
                        ref.read(themeChoiceProvider.notifier).set(initial);
                        ref
                            .read(themeBrightnessModeProvider.notifier)
                            .set(widget.initialBrightness);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.cancel),
                    ),
                  const SizedBox(width: AppSpace.xs),
                  FilledButton.tonal(
                    key: const ValueKey('theme-sheet-done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: ThemeBrightnessSegmented(),
            ),
            // Hızlı grup süzgeci: Tümü · Sakin · Kâğıt · Canlı.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.m,
              ),
              child: Row(
                children: [
                  _SheetGroupPill(
                    label: l10n.themeGroupAll,
                    selected: _groupFilter == null,
                    tokens: tokens,
                    scheme: scheme,
                    text: text,
                    onTap: () => _selectGroup(null),
                  ),
                  for (var i = 0; i < groups.length; i++) ...[
                    const SizedBox(width: AppSpace.s),
                    _SheetGroupPill(
                      label: groups[i].$1,
                      selected: _groupFilter == i,
                      tokens: tokens,
                      scheme: scheme,
                      text: text,
                      onTap: () => _selectGroup(i),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: 122,
              child: HorizontalScrollStrip(
                controller: _scroll,
                builder: (_, controller) => ListView.separated(
                  key: const ValueKey('theme-sheet-list'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  controller: controller,
                  itemCount: options.length,
                  separatorBuilder: (_, i) => SizedBox(
                    width: _groupFilter == null && _groupStarts.contains(i + 1)
                        ? AppSpace.l
                        : AppSpace.s,
                  ),
                  itemBuilder: (context, i) {
                    final o = options[i];
                    return SizedBox(
                      width: 90,
                      child: ThemeChoiceCard(
                        key: ValueKey('theme-sheet-${o.$1.name}'),
                        label: o.$2,
                        themes: o.$3,
                        selected: o.$1 == choice,
                        locked: themeChoiceLocked(
                          o.$1,
                          choice,
                          unlocked: unlocked,
                        ),
                        onTap: () {
                          if (themeChoiceLocked(
                            o.$1,
                            choice,
                            unlocked: unlocked,
                          )) {
                            // Levha kapanır (seçim değişmedi: "Vazgeç" gerekmez).
                            openProScreen(context, popFirst: true);
                            return;
                          }
                          AppHaptics.tick();
                          ref.read(themeChoiceProvider.notifier).set(o.$1);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetGroupPill extends StatelessWidget {
  const _SheetGroupPill({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.scheme,
    required this.text,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppTokens tokens;
  final ColorScheme scheme;
  final AppText text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.quick),
          curve: AppMotion.curveOf(context, AppMotion.emphasized),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? tokens.resolvedAccentBorder(scheme)
                  : tokens.hairline,
            ),
          ),
          child: Text(
            label,
            style: text.label.copyWith(
              fontWeight: selected ? AppWeight.strong : AppWeight.medium,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek tema seçeneği: tek `CustomPaint` ile gerçekçi minyatür Notlar arayüzü
/// (zemin + arama çubuğu + iki kart + sıcak etiket + vurgu FAB) + ad + üç
/// palet noktası. [themes] iki tane ise (Sistem) açık/koyu ikiye bölünür.
class ThemeChoiceCard extends StatelessWidget {
  const ThemeChoiceCard({
    super.key,
    required this.label,
    required this.themes,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final List<ThemeData> themes;
  final bool selected;
  final VoidCallback onTap;

  /// PL6: yeni seçim için kilitli (köşede kilit; dokunuş Pro ekranına gider).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final hostTheme = Theme.of(context);
    final scheme = hostTheme.colorScheme;
    final tokens = AppTokens.fromTheme(hostTheme);
    final text = AppText.of(hostTheme);
    final leadScheme = themes.first.colorScheme;
    final swatchColors = <Color>[
      leadScheme.surface,
      leadScheme.primary,
      leadScheme.secondary,
    ];

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.short),
                curve: AppMotion.curveOf(context, AppMotion.emphasized),
                height: 74,
                padding: const EdgeInsets.all(AppSpace.xxs),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  border: Border.all(
                    color: selected ? scheme.primary : tokens.hairline,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _MiniThemePreviewPainter(themes)),
                      if (locked && !selected)
                        Positioned(
                          right: AppSpace.xs,
                          top: AppSpace.xs,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: scheme.surface,
                            child: const ProLockBadge(),
                          ),
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
              const SizedBox(height: AppSpace.xs + 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.meta.copyWith(
                  fontWeight: selected ? AppWeight.strong : AppWeight.medium,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < swatchColors.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: AppSpace.xxs),
                      decoration: BoxDecoration(
                        color: swatchColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.hairline, width: 0.6),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek geçişte minyatür Notlar ekranı çizer: zemin, üst arama kapsülü, iki
/// kâğıt not kartı (biri sıcak etiketli, biri birincil şeritli) ve sağ altta
/// vurgu "+" düğmesi. İki tema verilirse (Sistem) ortadan ikiye bölünür.
class _MiniThemePreviewPainter extends CustomPainter {
  const _MiniThemePreviewPainter(this.themes);

  final List<ThemeData> themes;

  @override
  void paint(Canvas canvas, Size size) {
    if (themes.isEmpty || size.isEmpty) return;
    if (themes.length == 1) {
      _paintMiniApp(canvas, Offset.zero & size, themes.first);
      return;
    }
    final half = size.width / 2;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, half, size.height));
    _paintMiniApp(canvas, Offset.zero & size, themes.first);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(half, 0, size.width - half, size.height));
    _paintMiniApp(canvas, Offset.zero & size, themes.last);
    canvas.restore();

    // Ortada ince açık/koyu ayırıcı çizgi.
    canvas.drawLine(
      Offset(half, 0),
      Offset(half, size.height),
      Paint()
        ..color = themes.first.colorScheme.outlineVariant
        ..strokeWidth = 1,
    );
  }

  void _paintMiniApp(Canvas c, Rect bounds, ThemeData theme) {
    final s = theme.colorScheme;
    final t = AppTokens.fromTheme(theme);
    final w = bounds.width;
    final h = bounds.height;
    final pad = 5.0;

    // 1. Zemin (masa).
    c.drawRect(bounds, Paint()..color = s.surface);

    // 2. Üst arama hapı.
    final searchRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, pad, w - pad * 2, 11),
      const Radius.circular(AppRadius.pill),
    );
    c.drawRRect(searchRect, Paint()..color = t.card);
    c.drawRRect(
      searchRect,
      Paint()
        ..color = t.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    // Arama içi sol çizgi + sağ vurgu noktası.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + 5, pad + 4.2, (w - pad * 2) * 0.42, 2.6),
        const Radius.circular(AppRadius.hair),
      ),
      Paint()..color = s.onSurfaceVariant.withValues(alpha: AppAlpha.soft),
    );
    c.drawCircle(
      Offset(w - pad - 5.5, pad + 5.5),
      2.6,
      Paint()..color = s.primary,
    );

    // 3. İki minyatür not kartı (masa üstünde kâğıt).
    final cardsTop = pad + 15;
    final gap = 4.0;
    final cardW = (w - pad * 2 - gap) / 2;
    final leftH = h - cardsTop - pad;
    final rightH = leftH * 0.72;

    // Sol kart: başlık + metin + sıcak etiket hapı.
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, cardsTop, cardW, leftH),
      const Radius.circular(AppRadius.xs + 2),
    );
    c.drawRRect(leftRect, Paint()..color = t.card);
    c.drawRRect(
      leftRect,
      Paint()
        ..color = t.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + 4, cardsTop + 5, cardW * 0.68, 3.2),
        const Radius.circular(AppRadius.hair),
      ),
      Paint()..color = s.onSurface.withValues(alpha: AppAlpha.strong),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + 4, cardsTop + 11, cardW * 0.80, 2.4),
        const Radius.circular(AppRadius.hair),
      ),
      Paint()..color = s.onSurfaceVariant.withValues(alpha: AppAlpha.disabled),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + 4, cardsTop + 16, cardW * 0.56, 2.4),
        const Radius.circular(AppRadius.hair),
      ),
      Paint()..color = s.onSurfaceVariant.withValues(alpha: AppAlpha.soft),
    );
    // Sıcak etiket hapı (secondaryContainer + secondary).
    if (leftH >= 32) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pad + 4, cardsTop + leftH - 11, cardW * 0.58, 6),
          const Radius.circular(AppRadius.xs),
        ),
        Paint()..color = s.secondaryContainer,
      );
      c.drawCircle(
        Offset(pad + 7.5, cardsTop + leftH - 8),
        1.6,
        Paint()..color = s.secondary,
      );
    }

    // Sağ kart: yumuşak birincil vurgu şeridi + iki satır.
    final rightX = pad + cardW + gap;
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rightX, cardsTop, cardW, rightH),
      const Radius.circular(AppRadius.xs + 2),
    );
    c.drawRRect(rightRect, Paint()..color = t.card);
    c.drawRRect(
      rightRect,
      Paint()
        ..color = t.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX + 4, cardsTop + 5, cardW * 0.72, 5.5),
        const Radius.circular(AppRadius.xs),
      ),
      Paint()..color = s.primaryContainer,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rightX + 4, cardsTop + 14, cardW * 0.65, 2.6),
        const Radius.circular(AppRadius.hair),
      ),
      Paint()..color = s.onSurface.withValues(alpha: AppAlpha.muted),
    );

    // 4. Sağ altta vurgu "+" düğmesi.
    const fabSize = 13.0;
    final fabRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - pad - fabSize, h - pad - fabSize, fabSize, fabSize),
      const Radius.circular(AppRadius.xs),
    );
    c.drawRRect(fabRect, Paint()..color = s.primary);
    final cx = w - pad - fabSize / 2;
    final cy = h - pad - fabSize / 2;
    final plusPaint = Paint()
      ..color = s.onPrimary
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - 3, cy), Offset(cx + 3, cy), plusPaint);
    c.drawLine(Offset(cx, cy - 3), Offset(cx, cy + 3), plusPaint);
  }

  @override
  bool shouldRepaint(_MiniThemePreviewPainter old) =>
      old.themes.length != themes.length ||
      old.themes.first.colorScheme != themes.first.colorScheme ||
      old.themes.last.colorScheme != themes.last.colorScheme;
}
