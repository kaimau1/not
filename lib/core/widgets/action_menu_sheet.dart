import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n_ext.dart';
import '../menu_layout.dart';
import 'app_sheet.dart';
import 'expand_reveal.dart';
import 'sheet_header.dart';
import 'sheet_tile.dart';

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
    this.badge,
  });

  /// Simgenin köşesindeki küçük işaret (misafirde hesap kilidi, F43.5).
  final Widget? badge;

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
///
/// TUTAMAK HER MENÜDE (kullanıcı isteği 2026-11-14: "üstte tutamacı yok,
/// tutup aşağı çekemiyorum, sadece ✕ kapatıyor" — K-D7'nin "✕ varsa tutamak
/// yok" kuralı kalktı). Levha durum çubuğunun altında durur ([showAppSheet]
/// `useSafeArea`): ⚙ ve ✕ telefonun üst çubuğuyla çakışmaz.
///
/// [requestFocus] false: levha odağı almaz (klavye açıkken çağıran klavyeyi
/// levhanın İLK karesinden sonra indirir — bkz. not editörü `_openNoteMenu`).
Future<String?> showActionMenuSheet(
  BuildContext context,
  ActionMenu menu, {
  bool? requestFocus,
}) => showAppSheet<String>(
      context: context,
      requestFocus: requestFocus,
      showDragHandle: true,
      // Büyük yazı ölçeğinde levha varsayılan tavanı aşabilir; kaydırma ağı.
      isScrollControlled: true,
      builder: (sheetContext) =>
          SafeArea(child: SingleChildScrollView(child: menu)),
    );

/// Çok işlemli menülerin ORTAK levha düzeni (kart ⋮, not ⋮, not "+", ana ekran
/// ⋮, çoklu seçim ⋮).
///
/// **MENÜ BİÇİMİ KURALI (TUTARLILIK F38.6, H1):** nota/eke ait çok işlemli menü
/// bu levha; tek seçimli ya da en çok dört maddelik araç listesi (sıralama,
/// görüntüleyici ⋮, kalem ayarı) açılır menü (`PopupMenuButton`). Ek menüleri
/// F40.1'de aynı kurala geçer.
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
    this.footer = const [],
    this.menuId,
    this.collapsible = false,
  });

  /// **KATLANIR GRUPLAR** (kullanıcı isteği 2026-11-16: "çok fazla buton var;
  /// kayan çekmeceler gibi gruplandırılsın"): her grubun başlığı dokununca
  /// açılıp kapanan bir çekmece. Varsayılan yalnız İLK grup açık; kullanıcının
  /// açtığı/kapattığı oturum boyunca hatırlanır ([menuId] başına).
  final bool collapsible;

  /// Oturum boyunca açık/kapalı gruplar: menü kimliği → (grup adı → açık mı).
  static final Map<String, Map<String, bool>> _folds = {};

  /// Testler için: hatırlanan açık/kapalı durumlarını siler.
  @visibleForTesting
  static void resetFolds() => _folds.clear();

  /// Kullanıcının düzenleyebildiği menünün kimliği ([MenuLayouts]); verilince
  /// başlıkta "Düzenle" düğmesi çıkar (gizle/göster, sırala, hızlı satır).
  final String? menuId;

  /// Notun değil ekranın/uygulamanın işi olan maddeler (Ekranı düzenle,
  /// Ayarlar — F12.1). Araçların arasında durunca not işi sanılıyordu; Sil'in
  /// altındaki ince satır da levhayı ~50 dp uzatıyor ve başlıktaki ⚙ ile
  /// üç ayrı "düzenle" kapısı oluyordu (DENEYIM D11). Şimdi başlıktaki ⚙'nin
  /// açılır menüsünde: Menüyü düzenle · Ekranı düzenle · Ayarlar (K-D10).
  final List<MenuAction> footer;

  /// Başlık satırı (ad + ✕) çizilecek mi — çizilirse levhada tutamak yok.
  bool get hasHeader => (title?.trim() ?? '').isNotEmpty;

  final String? title;
  final List<MenuAction> quick;
  final List<MenuSection> sections;
  final MenuAction? danger;

  /// Düzenin uygulanmış hâli: (hızlı satır, gruplar).
  (List<MenuAction>, List<MenuSection>) _arranged(
    MenuLayout layout,
    String otherTitle,
  ) {
    final all = <String, MenuAction>{
      for (final a in quick) a.id: a,
      for (final sec in sections)
        for (final a in sec.actions) a.id: a,
    };
    final quickIds = layout.quick ?? [for (final a in quick) a.id];
    final quickOut = [
      for (final id in quickIds)
        if (all[id] case final a? when !layout.hidden.contains(id)) a,
    ].take(MenuLayout.maxQuick).toList();
    final inQuick = {for (final a in quickOut) a.id};
    final sectionsOut = [
      for (final sec in sections)
        MenuSection(
          sec.title,
          layout.sorted([
            for (final a in sec.actions)
              if (!inQuick.contains(a.id) && !layout.hidden.contains(a.id)) a,
          ], (a) => a.id),
        ),
    ];
    // Varsayılan hızlı satırdan çıkarılanlar bir grupta kalır (kaybolmaz).
    final orphans = layout.sorted([
      for (final a in quick)
        if (!inQuick.contains(a.id) && !layout.hidden.contains(a.id)) a,
    ], (a) => a.id);
    if (orphans.isEmpty) return (quickOut, sectionsOut);
    // TEK GRUPLU MENÜDE (ana ekran ⋮) öksüzler o grubun SONUNA katılır
    // (kullanıcı bulgusu 2026-11-14: "ana menüdeki 3 nokta düzensiz" —
    // "Uygulama" ızgarası yarım satırla bitiyor, altında tek maddelik
    // "Diğer" grubu duruyordu).
    if (sectionsOut.length == 1) {
      final only = sectionsOut.single;
      sectionsOut[0] = MenuSection(only.title, [...only.actions, ...orphans]);
    } else {
      sectionsOut.add(MenuSection(otherTitle, orphans));
    }
    return (quickOut, sectionsOut);
  }

  @override
  Widget build(BuildContext context) {
    if (menuId == null) return _body(context, quick, sections);
    return _EditableMenu(menu: this);
  }

  Widget _body(
    BuildContext context,
    List<MenuAction> quick,
    List<MenuSection> sections, {
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final heading = title?.trim() ?? '';
    final editButton = _settingsButton(
      context,
      scheme,
      compact: false,
      onEdit: onEdit,
    );
    final visibleSections = [
      for (final section in sections)
        if (section.actions.isNotEmpty) section,
    ];
    final inlineEdit = heading.isNotEmpty
        ? null
        : _settingsButton(context, scheme, compact: true, onEdit: onEdit);
    final cardDecoration = BoxDecoration(
      color: tokens.card,
      borderRadius: BorderRadius.circular(AppRadius.l),
      border: Border.all(color: tokens.hairline),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading.isNotEmpty)
            SheetHeader(
              title: heading,
              actions: [?editButton],
              padding: EdgeInsets.zero,
            ),
          if (quick.isNotEmpty) ...[
            DecoratedBox(
              decoration: cardDecoration,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.s,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in quick)
                      Expanded(
                        child: _buildQuickButton(
                          context,
                          a,
                          scheme: scheme,
                          text: text,
                          onLongPress: onEdit,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (visibleSections.isNotEmpty) const SizedBox(height: AppSpace.s),
          ],
          if (collapsible && visibleSections.isNotEmpty)
            DecoratedBox(
              decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, section) in visibleSections.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.m,
                        ),
                        child: ColoredBox(
                          color: tokens.hairline,
                          child: const SizedBox(height: 1),
                        ),
                      ),
                    _FoldSection(
                      key: ValueKey('menu-fold-${section.title}'),
                      folds: _folds.putIfAbsent(menuId ?? '', () => {}),
                      title: section.title,
                      count: section.actions.length,
                      initiallyOpen: i == 0,
                      trailing: i == 0 ? inlineEdit : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.s,
                          0,
                          AppSpace.s,
                          AppSpace.m,
                        ),
                        child: _buildTileGrid(
                          section.actions,
                          (a, {required horizontal}) => _buildGridTile(
                            context,
                            a,
                            theme: theme,
                            scheme: scheme,
                            text: text,
                            horizontal: horizontal,
                            onLongPress: onEdit,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (!collapsible && visibleSections.isNotEmpty)
            DecoratedBox(
              decoration: cardDecoration,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, section) in visibleSections.indexed) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xs,
                          ),
                          child: SizedBox(
                            height: 1,
                            child: ColoredBox(color: tokens.hairline),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.xs,
                          AppSpace.xxs,
                          AppSpace.xs,
                          AppSpace.xs,
                        ),
                        // Başlıksız menüde ⚙ kendi satırını kaplamasın
                        // (kullanıcı bulgusu 2026-11-06): ilk bölüm
                        // başlığının sağında durur.
                        child: i == 0 && inlineEdit != null
                            ? SizedBox(
                                height: AppSpace.xxxl,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style: text.section,
                                      ),
                                    ),
                                    inlineEdit,
                                  ],
                                ),
                              )
                            : Text(section.title, style: text.section),
                      ),
                      _buildTileGrid(
                        section.actions,
                        (a, {required horizontal}) => _buildGridTile(
                          context,
                          a,
                          theme: theme,
                          scheme: scheme,
                          text: text,
                          horizontal: horizontal,
                          onLongPress: onEdit,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Bölüm yoksa ⚙ en altta, küçük.
          if (visibleSections.isEmpty && inlineEdit != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: inlineEdit,
            ),
          if (danger case final d?) ...[
            const SizedBox(height: AppSpace.s),
            DestructiveRow(
              key: ValueKey('menu-tile-${d.id}'),
              icon: d.icon,
              label: d.label,
              onTap: () => Navigator.pop(context, d.id),
            ),
          ],
        ],
      ),
    );
  }

  /// Başlıktaki ⚙: düzenlenebilir menüde "Menüyü düzenle"; [footer] varsa
  /// küçük açılır menü (Menüyü düzenle · Ekranı düzenle · Ayarlar — K-D10).
  /// İkisi de yoksa null.
  Widget? _settingsButton(
    BuildContext context,
    ColorScheme scheme, {
    required bool compact,
    VoidCallback? onEdit,
  }) {
    if (menuId == null && footer.isEmpty) return null;
    final l10n = context.l10n;
    final icon = Icon(
      footer.isEmpty ? Icons.tune : Icons.settings_outlined,
      size: compact ? AppIconSize.m : null,
      color: compact ? scheme.onSurfaceVariant : null,
    );
    if (footer.isEmpty) {
      return IconButton(
        key: const ValueKey('menu-edit'),
        tooltip: l10n.menuEdit,
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact ? EdgeInsets.zero : null,
        icon: icon,
        onPressed: onEdit,
      );
    }
    const editId = 'menu.editLayout';
    return PopupMenuButton<String>(
      key: const ValueKey('menu-edit'),
      tooltip: l10n.settings,
      icon: icon,
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(AppSpace.s),
      onSelected: (id) {
        if (id == editId) {
          onEdit?.call();
        } else {
          Navigator.pop(context, id);
        }
      },
      itemBuilder: (_) => [
        if (menuId != null && onEdit != null)
          PopupMenuItem(
            key: const ValueKey('menu-edit-layout'),
            value: editId,
            child: _PopupRow(icon: Icons.tune, label: l10n.menuEdit),
          ),
        for (final a in footer)
          PopupMenuItem(
            key: ValueKey('menu-footer-${a.id}'),
            value: a.id,
            child: _PopupRow(icon: a.icon, label: a.label),
          ),
      ],
    );
  }
}

/// ⚙ açılır menüsünün satırı: simge + ad.
class _PopupRow extends StatelessWidget {
  const _PopupRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: AppIconSize.m,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: AppSpace.m),
      Flexible(child: Text(label)),
    ],
  );
}

/// Hızlı satırın düğmesi: yuvarlak köşeli simge kutusu + altında kısa ad.
Widget _buildQuickButton(
  BuildContext context,
  MenuAction action, {
  required ColorScheme scheme,
  required AppText text,
  VoidCallback? onLongPress,
}) {
  final on = action.selected;
  final badgeBox = Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: on
          ? scheme.primary
          : action.neutral
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.m),
    ),
    child: Icon(
      action.icon,
      size: AppIconSize.m,
      color: on
          ? scheme.onPrimary
          : action.neutral
          ? scheme.onSurfaceVariant
          : scheme.onPrimaryContainer,
    ),
  );
  final iconWidget = action.count > 0 || action.badge != null
      ? Stack(
          clipBehavior: Clip.none,
          children: [
            badgeBox,
            if (action.count > 0)
              Positioned(
                right: -8,
                top: -4,
                child: _CountPill(
                  count: action.count,
                  highlight: action.highlight,
                ),
              ),
            if (action.badge != null)
              Positioned(right: -4, top: -4, child: action.badge!),
          ],
        )
      : badgeBox;
  return InkWell(
    key: ValueKey('menu-quick-${action.id}'),
    borderRadius: BorderRadius.circular(AppRadius.m),
    onTap: () => Navigator.pop(context, action.id),
    onLongPress: onLongPress,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xxs,
        vertical: AppSpace.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.xs,
        children: [
          iconWidget,
          Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.meta.copyWith(
              color: scheme.onSurface,
              fontWeight: AppWeight.medium,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Katlanır grup ([ActionMenu.collapsible]): başlık satırı (ad · sayı · ok)
/// dokununca ızgarayı aşağı kayarak açar/kapatır.
class _FoldSection extends StatefulWidget {
  const _FoldSection({
    super.key,
    required this.folds,
    required this.title,
    required this.count,
    required this.initiallyOpen,
    required this.child,
    this.trailing,
  });

  final Map<String, bool> folds;
  final String title;
  final int count;
  final bool initiallyOpen;
  final Widget child;
  final Widget? trailing;

  @override
  State<_FoldSection> createState() => _FoldSectionState();
}

class _FoldSectionState extends State<_FoldSection> {
  late bool _open = widget.folds[widget.title] ?? widget.initiallyOpen;

  void _toggle() {
    setState(() => _open = !_open);
    widget.folds[widget.title] = _open;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                expanded: _open,
                child: InkWell(
                  key: ValueKey('menu-fold-head-${widget.title}'),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  onTap: _toggle,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: kMinInteractiveDimension,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.m,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: SectionLabel(widget.title)),
                          if (!_open && widget.count > 0) ...[
                            Text('${widget.count}', style: text.meta),
                            const SizedBox(width: AppSpace.s),
                          ],
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: _open
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpace.xxs),
                              child: AnimatedRotation(
                                turns: _open ? 0.5 : 0,
                                duration: AppMotion.of(
                                  context,
                                  AppMotion.short,
                                ),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: AppIconSize.s,
                                  color: _open
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ?widget.trailing,
          ],
        ),
        ExpandReveal(open: _open, child: widget.child),
      ],
    );
  }
}

/// Grup ızgarası: boş hücre bırakmayan dengeli bento satırları
/// (kullanıcı isteği 2026-10-20: 3 sütun; 2026-11-21: boşluksuz tam genişlik
/// satırlar — 1–2 öğeli satırlar yatay hap karo, 3+ öğeli satırlar kompakt
/// dikey karo).
Widget _buildTileGrid(
  List<MenuAction> actions,
  Widget Function(MenuAction action, {required bool horizontal}) tile,
) {
  Widget row(List<MenuAction> items) => Row(
    spacing: AppSpace.s,
    children: [
      for (final a in items)
        Expanded(child: tile(a, horizontal: items.length <= 2)),
    ],
  );
  // 3 ve altı öğe her genişlikte (en az 3 sütun) tek satır: LayoutBuilder
  // ve Column kurulmaz (S37 bütçesi).
  if (actions.length <= 3) return row(actions);
  return LayoutBuilder(
    builder: (context, constraints) {
      // Telefonda 3, geniş ekranda (tablet, web) 4–6 sütun.
      final columns = (constraints.maxWidth / 108).floor().clamp(3, 6);
      final rows = <List<MenuAction>>[];
      for (var i = 0; i < actions.length; i += columns) {
        final end = i + columns;
        rows.add(
          actions.sublist(i, end > actions.length ? actions.length : end),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s,
        children: [for (final r in rows) row(r)],
      );
    },
  );
}

/// Grup ızgarasının hücresi: tonlu yuvarlak köşeli kart.
/// [horizontal] doğruysa (1–2 öğeli satır) simge solda, ad yanında — boş
/// hücre bırakmaz ve kompakt kalır.
Widget _buildGridTile(
  BuildContext context,
  MenuAction action, {
  required ThemeData theme,
  required ColorScheme scheme,
  required AppText text,
  bool horizontal = false,
  VoidCallback? onLongPress,
  VoidCallback? onTap,
}) {
  final on = action.selected;
  final tileColor = on
      ? scheme.primary
      : theme.brightness == Brightness.dark
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainer;
  final fg = on ? scheme.onPrimary : scheme.onSurface;
  final icon = Icon(
    action.icon,
    size: AppIconSize.m,
    color: on ? scheme.onPrimary : scheme.primary,
  );
  final labelStyle = text.meta.copyWith(
    color: fg,
    fontWeight: AppWeight.medium,
  );
  final Widget body;
  if (horizontal) {
    body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.m,
          vertical: AppSpace.xs,
        ),
        child: Row(
          spacing: AppSpace.s,
          children: [
            icon,
            Expanded(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            if (action.count > 0)
              _CountPill(count: action.count, highlight: action.highlight),
          ],
        ),
      ),
    );
  } else {
    final top = action.count > 0
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              Positioned(
                right: -14,
                top: -6,
                child: _CountPill(
                  count: action.count,
                  highlight: action.highlight,
                ),
              ),
            ],
          )
        : icon;
    body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xs,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.xs,
          children: [
            top,
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
  return InkWell(
    key: ValueKey('menu-tile-${action.id}'),
    borderRadius: BorderRadius.circular(AppRadius.m),
    onTap: onTap ?? () => Navigator.pop(context, action.id),
    onLongPress: onLongPress,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: body,
    ),
  );
}

/// **MENÜYÜ YERİNDE DÜZENLE** (kullanıcı isteği 2026-11-19: "menüyü düzenle
/// alanları anlaşılır değil; direkt menü üzerinde düzenlenmeli — basılı
/// tutarak yer değiştirme, gizleme, gösterme direkt menü üzerinde").
///
/// Eski ayrı "Menüyü düzenle" levhası (iki çip panosu) kalktı: ⚙ → "Menüyü
/// düzenle" ya da herhangi bir işleme BASILI TUTMAK aynı menüyü düzenleme
/// kipine alır. Kipte: karoyu basılı tutup başka karonun üstüne bırak =
/// sırala (hızlı satıra bırakmak satıra alır, en çok [MenuLayout.maxQuick]);
/// ⊖ gizler (alttaki "Gizlenenler"e iner), ⊕ geri getirir; ☆ hızlı satıra
/// alır/çıkarır. Değişiklik ANINDA kaydedilir (P50); "Bitti" kipten çıkar,
/// "Varsayılan" kaydı siler.
class _EditableMenu extends StatefulWidget {
  const _EditableMenu({required this.menu});

  final ActionMenu menu;

  @override
  State<_EditableMenu> createState() => _EditableMenuState();
}

class _EditableMenuState extends State<_EditableMenu> {
  bool _editing = false;

  ActionMenu get _menu => widget.menu;
  String get _id => _menu.menuId!;

  void _startEdit() {
    if (_editing) return;
    setState(() => _editing = true);
  }

  Map<String, MenuAction> get _all => {
    for (final a in _menu.quick) a.id: a,
    for (final s in _menu.sections)
      for (final a in s.actions) a.id: a,
  };

  /// Varsayılan sıradaki bütün kimlikler (gruplar, sonra yalnız hızlı
  /// satırda olanlar) — eski düzenleyiciyle aynı kayıt biçimi.
  List<String> get _defaultOrder => [
    for (final s in _menu.sections)
      for (final a in s.actions) a.id,
    for (final a in _menu.quick)
      if (!_menu.sections.any((s) => s.actions.any((x) => x.id == a.id))) a.id,
  ];

  /// Düzenin çözülmüş hâli: (gizliler, hızlı satır, sıra).
  (Set<String>, List<String>, List<String>) _state() {
    final layout = MenuLayouts.of(_id);
    final all = _all;
    final hidden = {...layout.hidden};
    final quick = [
      for (final id in layout.quick ?? [for (final a in _menu.quick) a.id])
        if (all.containsKey(id) && !hidden.contains(id)) id,
    ].take(MenuLayout.maxQuick).toList();
    final order = layout.sorted(_defaultOrder, (id) => id);
    return (hidden, quick, order);
  }

  void _save(Set<String> hidden, List<String> quick, List<String> order) =>
      MenuLayouts.set(
        _id,
        MenuLayout(hidden: hidden, quick: quick, order: order),
      );

  void _toggleHidden(String id) {
    final (hidden, quick, order) = _state();
    if (!hidden.remove(id)) {
      hidden.add(id);
      quick.remove(id);
    }
    _save(hidden, quick, order);
  }

  void _toggleQuick(String id) {
    final (hidden, quick, order) = _state();
    if (!quick.remove(id)) {
      if (quick.length >= MenuLayout.maxQuick) return;
      quick.add(id);
      hidden.remove(id);
    }
    _save(hidden, quick, order);
  }

  /// [dragged] karosu [target] karosunun üstüne bırakıldı.
  void _move(String dragged, String target) {
    if (dragged == target) return;
    final (hidden, quick, order) = _state();
    final tq = quick.indexOf(target);
    if (tq >= 0) {
      // Hızlı satıra bırakıldı: satırda hedefin yerine girer.
      final dq = quick.indexOf(dragged);
      if (dq >= 0) quick.removeAt(dq);
      var at = quick.indexOf(target);
      if (dq >= 0 && dq < tq) at += 1;
      quick.insert(at, dragged);
      hidden.remove(dragged);
      while (quick.length > MenuLayout.maxQuick) {
        quick.removeLast();
      }
    } else {
      quick.remove(dragged);
      // Gizlenenlerin üstüne bırakmak gizler, görünenin üstüne göstermek.
      if (hidden.contains(target)) {
        hidden.add(dragged);
      } else {
        hidden.remove(dragged);
      }
      final from = order.indexOf(dragged);
      final to = order.indexOf(target);
      if (from >= 0 && to >= 0) {
        order.removeAt(from);
        final at = order.indexOf(target);
        order.insert(from < to ? at + 1 : at, dragged);
      }
    }
    _save(hidden, quick, order);
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, MenuLayout>>(
        valueListenable: MenuLayouts.layouts,
        builder: (context, _, _) {
          final (q, secs) = _menu._arranged(
            MenuLayouts.of(_id),
            context.l10n.menuSectionOther,
          );
          if (!_editing) {
            return _menu._body(context, q, secs, onEdit: _startEdit);
          }
          return _editBody(context, q, secs);
        },
      );

  Widget _editBody(
    BuildContext context,
    List<MenuAction> quick,
    List<MenuSection> sections,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heading = _menu.title?.trim() ?? '';
    final (hiddenIds, quickIds, order) = _state();
    final all = _all;
    final hidden = [
      for (final id in order)
        if (hiddenIds.contains(id) && all[id] != null) all[id]!,
    ];
    final quickFull = quickIds.length >= MenuLayout.maxQuick;
    Widget tile(MenuAction a, {required bool inQuick}) => _EditTile(
      action: a,
      scheme: scheme,
      hidden: hiddenIds.contains(a.id),
      inQuick: inQuick,
      quickFull: quickFull,
      onToggleHidden: () => _toggleHidden(a.id),
      onToggleQuick: () => _toggleQuick(a.id),
      onDrop: (dragged) => _move(dragged, a.id),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading.isNotEmpty)
            SheetHeader(title: heading, padding: EdgeInsets.zero),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpace.s),
            child: Text(
              l10n.menuEditInlineHint(MenuLayout.maxQuick),
              key: const ValueKey('menu-edit-hint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (quick.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(
                  alpha: AppAlpha.hairline,
                ),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in quick)
                    Expanded(child: tile(a, inQuick: true)),
                ],
              ),
            ),
          for (final section in sections)
            if (section.actions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                child: SectionLabel(section.title),
              ),
              _buildTileGrid(
                section.actions,
                (a, {required horizontal}) => tile(a, inQuick: false),
              ),
            ],
          if (hidden.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              child: SectionLabel(l10n.menuHiddenGroup),
            ),
            _buildTileGrid(
              hidden,
              (a, {required horizontal}) => tile(a, inQuick: false),
            ),
          ],
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              TextButton(
                key: const ValueKey('menu-edit-reset'),
                onPressed: () => MenuLayouts.set(_id, const MenuLayout()),
                child: Text(l10n.menuReset),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('menu-edit-save'),
                onPressed: () => setState(() => _editing = false),
                child: Text(l10n.customizeDone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Düzenleme kipindeki karo: basılı tutup sürüklenir, başka karo onu kabul
/// eder; köşelerde ⊖/⊕ (gizle/göster) ve ☆ (hızlı satır).
class _EditTile extends StatelessWidget {
  const _EditTile({
    required this.action,
    required this.scheme,
    required this.hidden,
    required this.inQuick,
    required this.quickFull,
    required this.onToggleHidden,
    required this.onToggleQuick,
    required this.onDrop,
  });

  final MenuAction action;
  final ColorScheme scheme;
  final bool hidden;
  final bool inQuick;
  final bool quickFull;
  final VoidCallback onToggleHidden;
  final VoidCallback onToggleQuick;
  final ValueChanged<String> onDrop;

  Widget _badge({
    required Key key,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) => Tooltip(
    message: tooltip,
    child: InkResponse(
      key: key,
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppIconSize.m, color: color),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final face = Opacity(
      opacity: hidden ? 0.45 : 1,
      child: IgnorePointer(
        child: _buildGridTile(
          context,
          action,
          theme: theme,
          scheme: scheme,
          text: AppText.of(theme),
          onTap: () {},
        ),
      ),
    );
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != action.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          LongPressDraggable<String>(
            key: ValueKey('menu-drag-${action.id}'),
            data: action.id,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black26),
                  ],
                ),
                child: Icon(action.icon, color: scheme.onPrimaryContainer),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: face),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(
                  color: candidates.isNotEmpty
                      ? scheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: face,
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: _badge(
              key: ValueKey('menu-visible-${action.id}'),
              icon: hidden
                  ? Icons.add_circle_rounded
                  : Icons.remove_circle_rounded,
              color: hidden ? scheme.primary : scheme.error,
              tooltip: hidden ? l10n.customizeShown : l10n.menuHiddenGroup,
              onTap: onToggleHidden,
            ),
          ),
          if (!hidden)
            PositionedDirectional(
              end: 0,
              top: 0,
              child: _badge(
                key: ValueKey('menu-edit-quick-${action.id}'),
                icon: inQuick ? Icons.star_rounded : Icons.star_border_rounded,
                color: inQuick || !quickFull
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withValues(alpha: AppAlpha.disabled),
                tooltip: l10n.menuQuickRow,
                onTap: inQuick || !quickFull ? onToggleQuick : null,
              ),
            ),
        ],
      ),
    );
  }
}
