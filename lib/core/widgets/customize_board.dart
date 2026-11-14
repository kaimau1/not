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
/// (sürükle = sırala), altında iki karo öbeği: görünenler (dokun = çıkar) ve
/// eklenebilirler (dokun = ekle).
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
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    Widget tiles(List<CustomizeEntry> list, {required bool inShown}) => Wrap(
      spacing: AppSpace.s,
      runSpacing: AppSpace.s,
      children: [
        for (final e in list)
          _Tile(
            key: ValueKey('$keyPrefix${e.id}'),
            entry: e,
            shown: inShown,
            onTap: () => onToggle(e.id, !inShown),
            trailing: trailingOf?.call(e.id),
          ),
      ],
    );

    final reset = onReset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('${keyPrefix}preview'),
          height: _stripHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.l),
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
    Widget icon(CustomizeEntry e) => Padding(
      key: ValueKey('${keyPrefix}preview-${e.id}'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
      child: Icon(
        e.icon,
        size: AppIconSize.m,
        color: scheme.onSurfaceVariant,
        semanticLabel: e.label,
      ),
    );
    final reorder = onReorder;
    if (reorder == null) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final e in visible) icon(e)]),
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
            child: icon(e),
          ),
      ],
    );
  }
}

/// Bir düğme karosu: görünense dolu zemin + "−", değilse çerçeve + "+".
///
/// Karo öbek değiştirince (görünen ↔ eklenebilir) yeni yerinde yalnız
/// SOLARAK belirir; `Wrap` içinde boy animasyonu yok.
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
    final fg = shown ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final trailing = this.trailing;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.quick),
      curve: AppMotion.curveOf(context, AppMotion.standard),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Material(
        color: shown ? scheme.secondaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: shown
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _tileHeight),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.m,
                AppSpace.s,
                AppSpace.s,
                AppSpace.s,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.icon, size: AppIconSize.s, color: fg),
                  const SizedBox(width: AppSpace.s),
                  Flexible(
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Icon(
                    shown
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    size: AppIconSize.xs,
                    color: shown ? fg : scheme.primary,
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
