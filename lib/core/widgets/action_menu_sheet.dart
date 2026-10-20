import 'package:flutter/material.dart';
import 'app_sheet.dart';

/// Menü levhasındaki tek işlem.
class MenuAction {
  const MenuAction(
    this.id,
    this.label,
    this.icon, {
    this.selected = false,
    this.count = 0,
    this.highlight = false,
    this.neutral = false,
  });

  /// Hızlı satırda GRİ (nötr) çizilsin mi — içerik değil uygulama işi olan
  /// düğme (Ayarlar) öbür kısayollardan renkle ayrışsın.
  final bool neutral;

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
    showAppSheet<String>(
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
///     araçlar, koruma), üç sütunlu küçük simge ızgarasında (2026-10-20);
///  3. **Sil** — ayrı, uyarı renginde, tam genişlikte.
class ActionMenu extends StatelessWidget {
  const ActionMenu({
    super.key,
    this.title,
    required this.quick,
    required this.sections,
    this.danger,
    this.wideSections = false,
  });

  /// Gruplar yuvarlak simge ızgarası yerine İKİ SÜTUNLU geniş satırlarla
  /// (simge + yanında ad) çizilsin mi. Ana ekranın ⋮ menüsü (kullanıcı
  /// bulgusu 2026-10-20: "üstte 5 buton, altta 2'şerli sola yaslanmış, iyi
  /// değil"): ikişer maddelik gruplar üç sütunlu ızgarada sola yığılıp
  /// sağda boşluk bırakıyordu. Geniş satır ekranı tam doldurur.
  final bool wideSections;

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
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
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
              if (wideSections)
                _TileColumns(actions: section.actions, scheme: scheme)
              else
                _TileGrid(actions: section.actions, scheme: scheme),
            ],
          if (danger != null) ...[
            const SizedBox(height: 10),
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
                    color: on
                        ? scheme.primary
                        : action.neutral
                        ? scheme.surfaceContainerHighest
                        : scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 22,
                    color: on
                        ? scheme.onPrimary
                        : action.neutral
                        ? scheme.onSurfaceVariant
                        : scheme.onPrimaryContainer,
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

/// Grup ızgarası: ÜÇ SÜTUN, hızlı satırdaki gibi yuvarlak simge + altında
/// kısa ad (kullanıcı isteği 2026-10-20: "not menüsü üstteki 4'lü gibi
/// simge olsun, 3 sütun olsun, daha düzgün sığsın"). Eskiden iki sütunlu,
/// yazısı yanda alçak satırlardı; levha yine ekranı dolduruyordu.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.actions, required this.scheme});

  final List<MenuAction> actions;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 4.0;
        // Telefonda 3, geniş ekranda (tablet, web) 4–6 sütun.
        final columns = (constraints.maxWidth / 120).floor().clamp(3, 6);
        final cell = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final a in actions)
              SizedBox(
                width: cell,
                child: _GridTile(action: a, scheme: scheme),
              ),
          ],
        );
      },
    );
  }
}

/// Geniş grup düzeni: iki sütun [_Tile]; tek kalan son madde tam genişlik.
class _TileColumns extends StatelessWidget {
  const _TileColumns({required this.actions, required this.scheme});

  final List<MenuAction> actions;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i += 2)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + 2 < actions.length ? gap : 0,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Tile(action: actions[i], scheme: scheme),
                    ),
                    if (i + 1 < actions.length) ...[
                      const SizedBox(width: gap),
                      Expanded(
                        child: _Tile(action: actions[i + 1], scheme: scheme),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grup ızgarasının hücresi: hızlı satırın düğmesinden küçük ve NÖTR renkli
/// (sık kullanılan dört işlem renkleriyle öne çıksın).
class _GridTile extends StatelessWidget {
  const _GridTile({required this.action, required this.scheme});

  final MenuAction action;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final on = action.selected;
    return InkWell(
      key: ValueKey('menu-tile-${action.id}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, action.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: on
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 20,
                    color: on ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
                if (action.count > 0)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: _CountPill(
                      count: action.count,
                      highlight: action.highlight,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.2,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
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
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, action.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: danger ? 12 : 8,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: danger
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (danger)
                  Icon(action.icon, size: 20, color: color)
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: action.selected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      action.icon,
                      size: 18,
                      color: action.selected ? scheme.onPrimary : color,
                    ),
                  ),
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
