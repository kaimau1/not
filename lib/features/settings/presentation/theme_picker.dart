import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../settings_providers.dart';

/// Tema seçeneklerinin TEK listesi (Ayarlar → Görünüm ve ana ekrandaki tema
/// levhası aynı sırayı gösterir). Üçüncü öğe önizlemede çizilen tema(lar):
/// Sistem açık + koyu iki yarım.
List<(AppThemeChoice, String, List<ThemeData>)> themeChoiceOptions(
  BuildContext context,
  String font,
) {
  final l10n = context.l10n;
  ThemeData of(ThemeFamily f, Brightness b) => AppTheme.of(f, b, font: font);
  ThemeData light(ThemeFamily f) => of(f, Brightness.light);
  final sage = light(ThemeFamily.sage);
  final dark = of(ThemeFamily.sage, Brightness.dark);
  return [
    (AppThemeChoice.system, l10n.themeSystem, [sage, dark]),
    (AppThemeChoice.sage, l10n.themeSage, [sage]),
    (
      AppThemeChoice.porcelain,
      l10n.themePorcelain,
      [light(ThemeFamily.porcelain)],
    ),
    (AppThemeChoice.clay, l10n.themeClay, [light(ThemeFamily.clay)]),
    (
      AppThemeChoice.lavender,
      l10n.themeLavender,
      [light(ThemeFamily.lavender)],
    ),
    (AppThemeChoice.olive, l10n.themeOlive, [light(ThemeFamily.olive)]),
    (AppThemeChoice.white, l10n.themeWhite, [light(ThemeFamily.white)]),
    (AppThemeChoice.straw, l10n.themeStraw, [light(ThemeFamily.straw)]),
    (AppThemeChoice.cream, l10n.themeCream, [light(ThemeFamily.cream)]),
    (AppThemeChoice.peach, l10n.themePeach, [light(ThemeFamily.peach)]),
    (AppThemeChoice.mint, l10n.themeMint, [light(ThemeFamily.mint)]),
    // CANLI TEMALAR (2026-11-06).
    (AppThemeChoice.ocean, l10n.themeOcean, [light(ThemeFamily.ocean)]),
    (AppThemeChoice.rose, l10n.themeRose, [light(ThemeFamily.rose)]),
    (
      AppThemeChoice.tangerine,
      l10n.themeTangerine,
      [light(ThemeFamily.tangerine)],
    ),
    (AppThemeChoice.emerald, l10n.themeEmerald, [light(ThemeFamily.emerald)]),
    (
      AppThemeChoice.amethyst,
      l10n.themeAmethyst,
      [light(ThemeFamily.amethyst)],
    ),
    (AppThemeChoice.dark, l10n.themeDark, [dark]),
  ];
}

/// TEMA KARTLARI ızgarası (Ayarlar → Görünüm).
///
/// Kullanıcı isteği 2026-09-26: eski seçici dört ETİKETSİZ simgeydi. Her
/// seçenek küçük bir ÖNİZLEME (zemin, kart, yazı, vurgu) + altında adı;
/// seçili kart birincil renkle çerçevelenir.
class ThemeChoiceGrid extends ConsumerWidget {
  const ThemeChoiceGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(themeChoiceProvider);
    final options = themeChoiceOptions(context, ref.watch(appFontProvider));
    // Dar ekranda üçlü sıralar, ortada altı, genişte dokuz sütun.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final w = constraints.maxWidth;
        final perRow = w < 440 ? 3 : (w < 760 ? 6 : 9);
        final width = (w - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: ThemeChoiceCard(
                  label: option.$2,
                  themes: option.$3,
                  selected: choice == option.$1,
                  onTap: () =>
                      ref.read(themeChoiceProvider.notifier).set(option.$1),
                ),
              ),
          ],
        );
      },
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
  return showAppSheet<void>(
    context: context,
    barrierColor: Colors.transparent,
    showDragHandle: true,
    builder: (_) => _ThemePickerSheet(initial: before),
  );
}

class _ThemePickerSheet extends ConsumerStatefulWidget {
  const _ThemePickerSheet({required this.initial});

  final AppThemeChoice initial;

  @override
  ConsumerState<_ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends ConsumerState<_ThemePickerSheet> {
  /// Seçili tema görünür alanda açılsın (yalnız açılışta).
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: math.max(
      0,
      (AppThemeChoice.values.indexOf(widget.initial) - 1) * 88.0,
    ),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final choice = ref.watch(themeChoiceProvider);
    final options = themeChoiceOptions(context, ref.watch(appFontProvider));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.themePickerTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (choice != initial)
                    TextButton(
                      key: const ValueKey('theme-sheet-revert'),
                      onPressed: () {
                        ref.read(themeChoiceProvider.notifier).set(initial);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.cancel),
                    ),
                  FilledButton.tonal(
                    key: const ValueKey('theme-sheet-done'),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 104,
              child: ListView.separated(
                key: const ValueKey('theme-sheet-list'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                controller: _scroll,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final o = options[i];
                  return SizedBox(
                    width: 80,
                    child: ThemeChoiceCard(
                      key: ValueKey('theme-sheet-${o.$1.name}'),
                      label: o.$2,
                      themes: o.$3,
                      selected: o.$1 == choice,
                      onTap: () =>
                          ref.read(themeChoiceProvider.notifier).set(o.$1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek tema seçeneği: mini önizleme (zemin + kâğıt kart + yazı + vurgu) +
/// ad. [themes] iki tane ise (Sistem) önizleme ortadan açık/koyu ikiye
/// bölünür.
class ThemeChoiceCard extends StatelessWidget {
  const ThemeChoiceCard({
    super.key,
    required this.label,
    required this.themes,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<ThemeData> themes;
  final bool selected;
  final VoidCallback onTap;

  Widget _preview(ThemeData theme) {
    final c = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    return ColoredBox(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tokens.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 22, height: 4, color: c.onSurface),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 3,
                  color: c.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 3),
                Container(width: 18, height: 3, color: c.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        for (final t in themes) Expanded(child: _preview(t)),
                      ],
                    ),
                    if (selected)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: scheme.primary,
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
