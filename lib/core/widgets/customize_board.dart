// P63 iskelet — docs/plan_tasarim_B.md §6.1
import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Önizleme şeridinin ve karonun boyu.
const double _stripHeight = 48;
const double _tileHeight = 40;

/// Panonun bir öğesi: kalıcı kimlik + simge + ad.
typedef CustomizeEntry = ({String id, IconData icon, String label});

/// **DÜZENLEME PANOSU**: bir yüzeyin (alt çubuk, hızlı satır, "+" paneli…)
/// düğmelerini göster/gizle ve sırala. Üstte yüzeyin önizleme şeridi
/// (sürükle = sırala), altında iki dengeli bento öbeği: görünenler
/// (dokun = çıkar) ve eklenebilirler (dokun = ekle).
///
/// Pano DURUM TUTMAZ ve sıra hesaplamaz: [shown] ne ise onu çizer, her
/// dokunuşu hemen bildirir (kaydet adımı yok — değişiklik anında uygulanır).
class CustomizeBoard extends StatelessWidget {
  const CustomizeBoard({
    super.key,
    required this.entries,
    required this.shown,
    required this.onToggle,
    this.onReorder,
    this.onReset,
    required this.shownLabel,
    required this.availableLabel,
    this.emptyLabel,
    this.resetLabel,
    this.keyPrefix = 'customize-',
    this.trailingOf,
  });

  /// Yüzeyin TÜM öğeleri, varsayılan sırada.
  final List<CustomizeEntry> entries;

  /// Görünenlerin kimlikleri, EKRAN sırasıyla. [entries]'te olmayan kimlik
  /// yok sayılır.
  final List<String> shown;

  /// Karoya dokunuldu: `visible` öğenin YENİ hâli.
  final void Function(String id, bool visible) onToggle;

  /// Önizleme şeridinde sürükleme bitti; dizinler [shown] içinde ve
  /// `newIndex` öğe çıkarıldıktan SONRAKİ yerdir (`onReorderItem` anlamı).
  /// null = sırası olmayan yüzey: şerit sürüklenmez.
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// null = "Varsayılana dön" çizilmez.
  final VoidCallback? onReset;

  final String shownLabel;
  final String availableLabel;

  /// Hiç görünen yokken önizleme şeridindeki yazı.
  final String? emptyLabel;
  final String? resetLabel;

  /// Karo `'$keyPrefix<id>'`, önizleme `'${keyPrefix}preview'`, sıfırla
  /// `'${keyPrefix}reset'` anahtarını alır.
  final String keyPrefix;

  /// Karonun sonundaki ikincil düğme (ör. "öbür kapsüle taşı").
  final Widget? Function(String id)? trailingOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final byId = {for (final e in entries) e.id: e};
    final visible = [for (final id in shown) ?byId[id]];
    final shownIds = shown.toSet();
    final available = [
      for (final e in entries)
        if (!shownIds.contains(e.id)) e,
    ];

    Widget group(String title, int count) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.m, bottom: AppSpace.s),
      child: Text(
        '$title · $count',
        style: text.label.copyWith(
          color: scheme.primary,
          fontWeight: AppWeight.strong,
        ),
      ),
    );

    Widget tiles(List<CustomizeEntry> list, {required bool inShown}) {
      if (list.isEmpty) return const SizedBox.shrink();
      Widget cell(CustomizeEntry e) => _Tile(
        key: ValueKey('$keyPrefix${e.id}'),
        entry: e,
        shown: inShown,
        onTap: () => onToggle(e.id, !inShown),
        trailing: trailingOf?.call(e.id),
      );
      Widget row(List<CustomizeEntry> items) => Row(
        spacing: AppSpace.s,
        children: [for (final e in items) Expanded(child: cell(e))],
      );
      if (list.length <= 2) return row(list);
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / 170).floor().clamp(2, 4);
          final rows = <List<CustomizeEntry>>[];
          for (var i = 0; i < list.length; i += columns) {
            final end = i + columns;
            rows.add(list.sublist(i, end > list.length ? list.length : end));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s,
            children: [for (final r in rows) row(r)],
          );
        },
      );
    }

    final reset = onReset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('${keyPrefix}preview'),
          height: _stripHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
            ),
          ),
          child: _strip(theme, visible),
        ),
        group(shownLabel, visible.length),
        tiles(visible, inShown: true),
        // Hepsi görünürken boş öbek ve "· 0" başlığı çizilmez.
        if (available.isNotEmpty) ...[
          group(availableLabel, available.length),
          tiles(available, inShown: false),
        ],
        if (reset != null) ...[
          const SizedBox(height: AppSpace.m),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: ValueKey('${keyPrefix}reset'),
              onPressed: reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(resetLabel ?? ''),
            ),
          ),
        ],
      ],
    );
  }

  Widget _strip(ThemeData theme, List<CustomizeEntry> visible) {
    final scheme = theme.colorScheme;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          emptyLabel ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.of(theme).meta,
        ),
      );
    }
    Widget iconPill(CustomizeEntry e) => Padding(
      key: ValueKey('${keyPrefix}preview-${e.id}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: scheme.primary.withValues(alpha: AppAlpha.soft),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s),
            child: Icon(
              e.icon,
              size: AppIconSize.s,
              color: scheme.primary,
              semanticLabel: e.label,
            ),
          ),
        ),
      ),
    );
    final reorder = onReorder;
    if (reorder == null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final e in visible) iconPill(e)]),
      );
    }
    return ReorderableListView(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      onReorderItem: reorder,
      children: [
        for (final (i, e) in visible.indexed)
          ReorderableDelayedDragStartListener(
            key: ValueKey('${keyPrefix}drag-${e.id}'),
            index: i,
            child: iconPill(e),
          ),
      ],
    );
  }
}

/// Dengeli bento düğme karosu: görünense tonlu kart + "−" hapı, değilse
/// çerçeveli sade kart + "+" hapı.
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.entry,
    required this.shown,
    required this.onTap,
    this.trailing,
  });

  final CustomizeEntry entry;
  final bool shown;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final trailing = this.trailing;
    return Material(
      color: shown ? tokens.card : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: shown
              ? scheme.primary.withValues(alpha: AppAlpha.soft)
              : tokens.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _tileHeight),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.s,
              AppSpace.xs,
              AppSpace.xs,
              AppSpace.xs,
            ),
            child: Row(
              spacing: AppSpace.s,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: shown
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xs),
                    child: Icon(
                      entry.icon,
                      size: AppIconSize.s,
                      color: shown
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.meta.copyWith(
                      color: shown
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: AppWeight.medium,
                    ),
                  ),
                ),
                ?trailing,
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: shown
                        ? scheme.errorContainer.withValues(
                            alpha: AppAlpha.muted,
                          )
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xs),
                    child: Icon(
                      shown ? Icons.remove_rounded : Icons.add_rounded,
                      size: AppIconSize.xs,
                      color: shown
                          ? scheme.error
                          : scheme.onPrimaryContainer,
                    ),
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
