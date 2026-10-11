import 'package:flutter/material.dart';

/// Menü levhasındaki tek işlem.
class MenuAction {
  const MenuAction(
    this.id,
    this.label,
    this.icon, {
    this.selected = false,
    this.count = 0,
    this.highlight = false,
  });

  /// Levha kapanınca dönen anahtar.
  final String id;
  final String label;
  final IconData icon;

  /// Açık durumda mı (sabitli, yıldızlı…) — hızlı satırda dolu çizilir.
  final bool selected;

  /// Sayı rozeti (gelen notlar, arşiv…); 0 = rozet yok.
  final int count;

  /// Rozet vurgu renginde mi (okunmamış gibi dikkat isteyen sayı).
  final bool highlight;
}

/// Sayı rozeti — hızlı satırda simgenin köşesinde, satırlarda sağda.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.highlight});

  final int count;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: highlight ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlight ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Başlıklı işlem grubu.
class MenuSection {
  const MenuSection(this.title, this.actions);

  final String title;
  final List<MenuAction> actions;
}

/// [ActionMenu]'yü alt levhada açar; seçilen işlemin anahtarını döner.
Future<String?> showActionMenuSheet(BuildContext context, ActionMenu menu) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // Büyük yazı ölçeğinde levha varsayılan tavanı aşabilir; kaydırma ağı.
      isScrollControlled: true,
      builder: (sheetContext) =>
          SafeArea(child: SingleChildScrollView(child: menu)),
    );

/// Not menülerinin ORTAK levha düzeni (ana ekranda nota basılı tutma ve
/// editörün ⋮ menüsü).
///
/// KÖK NEDEN (kullanıcı isteği 2026-10-11: "görsellerdeki menüler yeniden
/// dizayn edilip toparlanmalı"): iki menü de 18–20 eşit ağırlıklı, iri
/// kutudan oluşan TEK bir ızgaraydı. Sık kullanılan (sabitle, paylaş) ile
/// seyrek kullanılan (senkronu kapat, istatistik) yan yana, aynı boyda
/// duruyordu; levha ekranın tamamını kaplıyor, "Kopyala" ile "Notu çoğalt"
/// aynı simgeyi taşıyordu. Şimdi üç katman:
///  1. **Hızlı satır** — en sık 4–5 işlem, yuvarlak simge + kısa ad;
///  2. **Başlıklı gruplar** — kalanlar anlamına göre (düzenle, kopyala,
///     araçlar, koruma), iki sütunlu ALÇAK satırlarda;
///  3. **Sil** — ayrı, uyarı renginde, tam genişlikte.
class ActionMenu extends StatelessWidget {
  const ActionMenu({
    super.key,
    this.title,
    required this.quick,
    required this.sections,
    this.danger,
  });

  final String? title;
  final List<MenuAction> quick;
  final List<MenuSection> sections;
  final MenuAction? danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final heading = title?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
            ),
          if (quick.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in quick)
                  Expanded(
                    child: _QuickButton(action: a, scheme: scheme),
                  ),
              ],
            ),
          for (final section in sections)
            if (section.actions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                child: Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.primary,
                  ),
                ),
              ),
              _TileGrid(actions: section.actions, scheme: scheme),
            ],
          if (danger != null) ...[
            const SizedBox(height: 12),
            _Tile(action: danger!, scheme: scheme, danger: true),
          ],
        ],
      ),
    );
  }
}

/// Hızlı satırın düğmesi: yuvarlak simge, altında en çok iki satır ad.
class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.action, required this.scheme});

  final MenuAction action;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final on = action.selected;
    return InkWell(
      key: ValueKey('menu-quick-${action.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, action.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: on ? scheme.primary : scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 22,
                    color: on ? scheme.onPrimary : scheme.onPrimaryContainer,
                  ),
                ),
                if (action.count > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: _CountPill(
                      count: action.count,
                      highlight: action.highlight,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.actions, required this.scheme});

  final List<MenuAction> actions;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final cell = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final a in actions)
              SizedBox(
                width: cell,
                child: _Tile(action: a, scheme: scheme),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.action,
    required this.scheme,
    this.danger = false,
  });

  final MenuAction action;
  final ColorScheme scheme;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? scheme.error : scheme.onSurface;
    return Material(
      key: ValueKey('menu-tile-${action.id}'),
      color: danger
          ? scheme.errorContainer.withValues(alpha: 0.4)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, action.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: danger
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(action.icon, size: 20, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (action.count > 0) ...[
                  const SizedBox(width: 6),
                  _CountPill(count: action.count, highlight: action.highlight),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
