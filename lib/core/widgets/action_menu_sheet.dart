import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show BoxHitTestEntry, SemanticsConfiguration;

import '../../app/theme/app_design.dart';
import '../../app/theme/app_tokens.dart';
import '../l10n_ext.dart';
import '../utils/feature_search.dart';
import '../menu_layout.dart';
import 'app_sheet.dart';
import 'expand_reveal.dart';
import 'sheet_header.dart';
import 'sheet_keyboard.dart';
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
  // İç arama kutusu klavyeyi açar: sonuçlar klavyenin üstünde kalsın.
  builder: (sheetContext) => SafeArea(
    child: SheetInsetPadding(child: SingleChildScrollView(child: menu)),
  ),
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
    if (menuId == null) {
      final count =
          quick.length +
          sections.fold<int>(0, (n, s) => n + s.actions.length) +
          footer.length +
          (danger == null ? 0 : 1);
      if (count < searchThreshold) return _body(context, quick, sections);
      return _SearchableMenu(menu: this);
    }
    return _EditableMenu(menu: this);
  }

  Widget _body(
    BuildContext context,
    List<MenuAction> quick,
    List<MenuSection> sections, {
    VoidCallback? onEdit,
    _MenuSearchHost? search,
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
    // İÇ ARAMA (kullanıcı isteği 2026-11-23): kalabalık menüde başlıkta 🔍;
    // dokununca kutu başlığın yerine geçer, yazınca gövde sonuçlarla
    // değişir. Düğme `build`'siz tek çizim nesnesi ([_SearchGlyph]): levhanın
    // açılış karesi ağırlaşmaz (S37).
    final searchActions = [
      ...quick,
      for (final section in visibleSections) ...section.actions,
      ...footer,
      ?danger,
    ];
    final host = searchActions.length >= searchThreshold ? search : null;
    final glyph = host == null || host.menuSearchOpen
        ? null
        : _SearchGlyph(
            key: const ValueKey('menu-search-open'),
            label: context.l10n.menuSearchHint,
            color: scheme.onSurfaceVariant,
            onTap: () => host.setMenuSearchOpen(true),
          );
    final settings = heading.isNotEmpty
        ? null
        : _settingsButton(context, scheme, compact: true, onEdit: onEdit);
    final Widget? inlineEdit = settings == null
        ? null
        : glyph == null
        ? settings
        : Row(mainAxisSize: MainAxisSize.min, children: [glyph, settings]);
    final query = host?.menuQuery.text.trim() ?? '';
    final cardDecoration = AppSurface.sheetCard(theme);
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
          if (host != null && host.menuSearchOpen)
            _searchField(context, host, searchActions)
          else if (heading.isNotEmpty)
            SheetHeader(
              title: heading,
              actions: [?glyph, ?editButton],
              padding: EdgeInsets.zero,
            ),
          if (query.isNotEmpty)
            _searchResults(context, searchActions, query, onLongPress: onEdit)
          else ...[
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
              if (visibleSections.isNotEmpty)
                const SizedBox(height: AppSpace.s),
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
                        _Hairline(
                          color: tokens.hairline,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.m,
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
                          _Hairline(
                            color: tokens.hairline,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xs,
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
        ],
      ),
    );
  }

  /// İç arama yalnız kalabalık menüde (8+ madde): az maddeli menüde kutu
  /// levhayı boşuna uzatırdı.
  static const int searchThreshold = 8;

  /// Sorguya uyan maddeler, en iyi eşleşme önce ([featureMatchScore]).
  static List<MenuAction> searchHits(List<MenuAction> actions, String q) {
    final seen = <String>{};
    final scored = <(int, int, MenuAction)>[];
    for (final (i, a) in actions.indexed) {
      if (!seen.add(a.id)) continue;
      final score = featureMatchScore(q, id: a.id, label: a.label);
      if (score > 0) scored.add((score, i, a));
    }
    scored.sort((x, y) => x.$1 != y.$1 ? y.$1 - x.$1 : x.$2 - y.$2);
    return [for (final e in scored) e.$3];
  }

  Widget _searchField(
    BuildContext context,
    _MenuSearchHost host,
    List<MenuAction> actions,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: SizedBox(
        height: kMinInteractiveDimension,
        child: TextField(
          key: const ValueKey('menu-search'),
          controller: host.menuQuery,
          focusNode: host.menuSearchFocus,
          textInputAction: TextInputAction.search,
          style: AppText.of(theme).body,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainer,
            hintText: l10n.menuSearchHint,
            prefixIcon: const Icon(Icons.search_rounded, size: AppIconSize.m),
            suffixIcon: IconButton(
              key: const ValueKey('menu-search-close'),
              tooltip: l10n.close,
              icon: const Icon(Icons.close_rounded, size: AppIconSize.m),
              onPressed: () => host.setMenuSearchOpen(false),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          ),
          onSubmitted: (q) {
            final hits = searchHits(actions, q.trim());
            if (hits.isNotEmpty) Navigator.pop(context, hits.first.id);
          },
        ),
      ),
    );
  }

  Widget _searchResults(
    BuildContext context,
    List<MenuAction> actions,
    String query, {
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final hits = searchHits(actions, query);
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
        child: Text(
          context.l10n.menuSearchEmpty,
          key: const ValueKey('menu-search-empty'),
          textAlign: TextAlign.center,
          style: text.meta.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return _buildTileGrid(
      hits,
      (a, {required horizontal}) => _buildGridTile(
        context,
        a,
        theme: theme,
        scheme: scheme,
        text: text,
        horizontal: horizontal,
        onLongPress: onLongPress,
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
            // Kilit rozeti (PL6 kapıları) karoda da görünür.
            if (action.badge != null) action.badge!,
          ],
        ),
      ),
    );
  } else {
    final top = action.count > 0 || action.badge != null
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              if (action.count > 0)
                Positioned(
                  right: -14,
                  top: -6,
                  child: _CountPill(
                    count: action.count,
                    highlight: action.highlight,
                  ),
                ),
              if (action.badge != null)
                Positioned(right: -8, top: -6, child: action.badge!),
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

class _EditableMenuState extends State<_EditableMenu>
    with _MenuSearchHost<_EditableMenu> {
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
            return _menu._body(
              context,
              q,
              secs,
              onEdit: _startEdit,
              search: this,
            );
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
    final text = AppText.of(theme);
    final heading = _menu.title?.trim() ?? '';
    final (hiddenIds, quickIds, order) = _state();
    final all = _all;
    final hidden = [
      for (final id in order)
        if (hiddenIds.contains(id) && all[id] != null) all[id]!,
    ];
    final quickFull = quickIds.length >= MenuLayout.maxQuick;

    Widget quickTile(MenuAction a) => _EditQuickTile(
      action: a,
      scheme: scheme,
      text: text,
      onToggleHidden: () => _toggleHidden(a.id),
      onToggleQuick: () => _toggleQuick(a.id),
      onDrop: (dragged) => _move(dragged, a.id),
    );

    Widget sectionTile(MenuAction a) => _EditSectionTile(
      action: a,
      theme: theme,
      scheme: scheme,
      text: text,
      hidden: hiddenIds.contains(a.id),
      inQuick: quickIds.contains(a.id),
      quickFull: quickFull,
      onToggleHidden: () => _toggleHidden(a.id),
      onToggleQuick: () => _toggleQuick(a.id),
      onDrop: (dragged) => _move(dragged, a.id),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading.isNotEmpty)
            SheetHeader(title: heading, padding: EdgeInsets.zero),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.m,
                vertical: AppSpace.s,
              ),
              child: Row(
                spacing: AppSpace.s,
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    size: AppIconSize.s,
                    color: scheme.primary,
                  ),
                  Expanded(
                    child: Text(
                      l10n.menuEditInlineHint(MenuLayout.maxQuick),
                      key: const ValueKey('menu-edit-hint'),
                      style: text.meta,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: AppSpace.m),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: AppAlpha.soft),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.xs,
                        AppSpace.xxs,
                        AppSpace.xs,
                        AppSpace.s,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: AppIconSize.xs,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              l10n.menuQuickRow,
                              style: text.badge.copyWith(color: scheme.primary),
                            ),
                          ),
                          DecoratedBox(
                            decoration: ShapeDecoration(
                              color: scheme.primaryContainer,
                              shape: const StadiumBorder(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.s,
                                vertical: AppSpace.xxs,
                              ),
                              child: Text(
                                '${quick.length} / ${MenuLayout.maxQuick}',
                                style: text.badge.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.xs,
                      children: [
                        for (final a in quick) Expanded(child: quickTile(a)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          for (final section in sections)
            if (section.actions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xs,
                  AppSpace.m,
                  AppSpace.xs,
                  AppSpace.xs,
                ),
                child: SectionLabel(section.title),
              ),
              _buildEditGrid(section.actions, sectionTile),
            ],
          if (hidden.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xs,
                AppSpace.m,
                AppSpace.xs,
                AppSpace.xs,
              ),
              child: SectionLabel(l10n.menuHiddenGroup),
            ),
            _buildEditGrid(hidden, sectionTile),
          ],
          const SizedBox(height: AppSpace.m),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
          ),
          const SizedBox(height: AppSpace.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton.icon(
                  key: const ValueKey('menu-edit-reset'),
                  onPressed: () => MenuLayouts.set(_id, const MenuLayout()),
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    size: AppIconSize.s,
                  ),
                  label: Text(
                    l10n.menuReset,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              FilledButton.icon(
                key: const ValueKey('menu-edit-save'),
                onPressed: () => setState(() => _editing = false),
                icon: const Icon(Icons.check_rounded, size: AppIconSize.s),
                label: Text(l10n.customizeDone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Düzenleme kipinde dengeli 2 sütunlu (geniş ekranda 3 sütunlu) bento
/// ızgarası: her hücre tam sütun genişliğinde, tek kalan son satır tam en.
Widget _buildEditGrid(
  List<MenuAction> actions,
  Widget Function(MenuAction) tile,
) {
  Widget row(List<MenuAction> items) => Row(
    spacing: AppSpace.s,
    children: [for (final a in items) Expanded(child: tile(a))],
  );
  if (actions.length <= 2) return row(actions);
  return LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 560 ? 3 : 2;
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

/// Hızlı satırdaki düzenleme karosu: üstte çakışmayan minik gizle/yıldız
/// şeridi, ortada tonlu simge kutusu, altta kısa ad.
class _EditQuickTile extends StatelessWidget {
  const _EditQuickTile({
    required this.action,
    required this.scheme,
    required this.text,
    required this.onToggleHidden,
    required this.onToggleQuick,
    required this.onDrop,
  });

  final MenuAction action;
  final ColorScheme scheme;
  final AppText text;
  final VoidCallback onToggleHidden;
  final VoidCallback onToggleQuick;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxs,
          AppSpace.xs,
          AppSpace.xxs,
          AppSpace.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _EditMiniAction(
                  key: ValueKey('menu-visible-${action.id}'),
                  icon: Icons.remove_rounded,
                  fg: scheme.error,
                  bg: scheme.errorContainer.withValues(alpha: AppAlpha.muted),
                  tooltip: l10n.menuHiddenGroup,
                  compact: true,
                  onTap: onToggleHidden,
                ),
                _EditMiniAction(
                  key: ValueKey('menu-edit-quick-${action.id}'),
                  icon: Icons.star_rounded,
                  fg: scheme.primary,
                  bg: scheme.primaryContainer,
                  tooltip: l10n.menuQuickRow,
                  compact: true,
                  onTap: onToggleQuick,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(
                  alpha: AppAlpha.soft,
                ),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Icon(
                  action.icon,
                  size: AppIconSize.s,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.badge.copyWith(
                fontWeight: AppWeight.medium,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != action.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => LongPressDraggable<String>(
        key: ValueKey('menu-drag-${action.id}'),
        data: action.id,
        feedback: _dragFeedback(scheme, action),
        childWhenDragging: Opacity(opacity: AppAlpha.disabled, child: card),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: candidates.isNotEmpty
                  ? scheme.primary
                  : Colors.transparent,
              width: AppSpace.xxs,
            ),
          ),
          child: card,
        ),
      ),
    );
  }
}

/// Bölüm ızgarasındaki yatay bento düzenleme karosu: solda tutamak + tonlu
/// simge + ad, sağda çakışmayan yıldız ve gizle/göster hapları.
class _EditSectionTile extends StatelessWidget {
  const _EditSectionTile({
    required this.action,
    required this.theme,
    required this.scheme,
    required this.text,
    required this.hidden,
    required this.inQuick,
    required this.quickFull,
    required this.onToggleHidden,
    required this.onToggleQuick,
    required this.onDrop,
  });

  final MenuAction action;
  final ThemeData theme;
  final ColorScheme scheme;
  final AppText text;
  final bool hidden;
  final bool inQuick;
  final bool quickFull;
  final VoidCallback onToggleHidden;
  final VoidCallback onToggleQuick;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tileColor = hidden
        ? scheme.surfaceContainerLowest
        : theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer;
    final canQuick = inQuick || !quickFull;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(
          color: hidden
              ? scheme.outlineVariant.withValues(alpha: AppAlpha.muted)
              : Colors.transparent,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s,
            vertical: AppSpace.xs,
          ),
          child: Row(
            spacing: AppSpace.xs,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: AppIconSize.xs,
                color: scheme.outline.withValues(alpha: AppAlpha.muted),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: hidden
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer.withValues(
                          alpha: AppAlpha.soft,
                        ),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Icon(
                    action.icon,
                    size: AppIconSize.s,
                    color: hidden
                        ? scheme.onSurfaceVariant.withValues(
                            alpha: AppAlpha.muted,
                          )
                        : scheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.meta.copyWith(
                    color: hidden
                        ? scheme.onSurfaceVariant.withValues(
                            alpha: AppAlpha.muted,
                          )
                        : scheme.onSurface,
                    fontWeight: AppWeight.medium,
                  ),
                ),
              ),
              if (!hidden)
                _EditMiniAction(
                  key: ValueKey('menu-edit-quick-${action.id}'),
                  icon: inQuick
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  fg: inQuick
                      ? scheme.primary
                      : canQuick
                      ? scheme.onSurfaceVariant
                      : scheme.onSurfaceVariant.withValues(
                          alpha: AppAlpha.disabled,
                        ),
                  bg: inQuick
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  tooltip: l10n.menuQuickRow,
                  onTap: canQuick ? onToggleQuick : null,
                ),
              _EditMiniAction(
                key: ValueKey('menu-visible-${action.id}'),
                icon: hidden ? Icons.add_rounded : Icons.remove_rounded,
                fg: hidden ? scheme.onPrimaryContainer : scheme.error,
                bg: hidden
                    ? scheme.primaryContainer
                    : scheme.errorContainer.withValues(alpha: AppAlpha.muted),
                tooltip: hidden ? l10n.customizeShown : l10n.menuHiddenGroup,
                onTap: onToggleHidden,
              ),
            ],
          ),
        ),
      ),
    );
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != action.id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) => LongPressDraggable<String>(
        key: ValueKey('menu-drag-${action.id}'),
        data: action.id,
        feedback: _dragFeedback(scheme, action),
        childWhenDragging: Opacity(opacity: AppAlpha.disabled, child: card),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: candidates.isNotEmpty
                  ? scheme.primary
                  : Colors.transparent,
              width: AppSpace.xxs,
            ),
          ),
          child: card,
        ),
      ),
    );
  }
}

/// Düzenleme karosunun içindeki çakışmasız minik işlem düğmesi (yıldız / gizle).
class _EditMiniAction extends StatelessWidget {
  const _EditMiniAction({
    super.key,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final String tooltip;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpace.xxs : AppSpace.xs),
          child: Icon(
            icon,
            size: compact ? AppIconSize.xs - AppSpace.xxs : AppIconSize.xs,
            color: fg,
          ),
        ),
      ),
    ),
  );
}

Widget _dragFeedback(ColorScheme scheme, MenuAction action) => Material(
  color: Colors.transparent,
  child: Container(
    width: kMinInteractiveDimension,
    height: kMinInteractiveDimension,
    decoration: BoxDecoration(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.l),
      border: Border.all(color: scheme.primary),
    ),
    child: Icon(action.icon, color: scheme.onPrimaryContainer),
  ),
);

/// Menü içi aramanın durumu (sorgu, odak, kutu açık mı). Düzenlenebilir
/// menünün kendi durumunda ([_EditableMenuState]) ya da [_SearchableMenu]'de
/// durur — ayrı katman kurulmaz.
mixin _MenuSearchHost<T extends StatefulWidget> on State<T> {
  final TextEditingController menuQuery = TextEditingController();
  final FocusNode menuSearchFocus = FocusNode(debugLabel: 'menu-search');
  bool menuSearchOpen = false;

  @override
  void initState() {
    super.initState();
    menuQuery.addListener(_onMenuQuery);
  }

  void _onMenuQuery() {
    if (mounted) setState(() {});
  }

  void setMenuSearchOpen(bool open) {
    if (open == menuSearchOpen) return;
    setState(() => menuSearchOpen = open);
    if (open) {
      menuSearchFocus.requestFocus();
    } else {
      menuQuery.clear();
    }
  }

  @override
  void dispose() {
    menuQuery.dispose();
    menuSearchFocus.dispose();
    super.dispose();
  }
}

/// Düzen kaydı olmayan kalabalık menü: yalnız arama durumu için.
class _SearchableMenu extends StatefulWidget {
  const _SearchableMenu({required this.menu});

  final ActionMenu menu;

  @override
  State<_SearchableMenu> createState() => _SearchableMenuState();
}

class _SearchableMenuState extends State<_SearchableMenu>
    with _MenuSearchHost<_SearchableMenu> {
  @override
  Widget build(BuildContext context) => widget.menu._body(
    context,
    widget.menu.quick,
    widget.menu.sections,
    search: this,
  );
}

/// Arama düğmesi: 48 dp, ortada 🔍 — `build`'i olmayan TEK çizim nesnesi
/// (dokunuş ve erişilebilirlik kendi içinde).
class _SearchGlyph extends LeafRenderObjectWidget {
  const _SearchGlyph({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSearchGlyph(label, color, onTap, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSearchGlyph renderObject,
  ) => renderObject
    ..label = label
    ..color = color
    ..onTap = onTap;
}

class _RenderSearchGlyph extends RenderBox {
  _RenderSearchGlyph(this._label, this._color, this.onTap, this._direction) {
    _tap = TapGestureRecognizer()..onTap = () => onTap();
  }

  late final TapGestureRecognizer _tap;
  VoidCallback onTap;
  final TextDirection _direction;
  TextPainter? _painter;

  String _label;
  set label(String v) {
    if (v == _label) return;
    _label = v;
    markNeedsSemanticsUpdate();
  }

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    _painter?.dispose();
    _painter = null;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.constrain(const Size.square(kMinInteractiveDimension));
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) _tap.addPointer(event);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isButton = true
      ..label = _label
      ..textDirection = _direction
      ..onTap = onTap;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    const icon = Icons.search_rounded;
    final p = _painter ??= TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: AppIconSize.m,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: _color,
          height: 1,
        ),
      ),
      textDirection: _direction,
    )..layout();
    p.paint(
      context.canvas,
      offset + Offset((size.width - p.width) / 2, (size.height - p.height) / 2),
    );
  }

  @override
  void dispose() {
    _tap.dispose();
    _painter?.dispose();
    super.dispose();
  }
}

/// Grup ayracı: [padding] içinde 1 dp çizgi — TEK katman (eski Padding +
/// ColoredBox + SizedBox üçlüsünün aynısı; levhanın açılış karesi S37/S53
/// bütçelerinde hafiflesin, iç arama düğmesine yer açılsın).
class _Hairline extends LeafRenderObjectWidget {
  const _Hairline({required this.color, required this.padding});

  final Color color;
  final EdgeInsets padding;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHairline(color, padding);

  @override
  void updateRenderObject(BuildContext context, _RenderHairline renderObject) =>
      renderObject
        ..color = color
        ..padding = padding;
}

class _RenderHairline extends RenderBox {
  _RenderHairline(this._color, this._padding);

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets v) {
    if (v == _padding) return;
    _padding = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    size = constraints.constrain(
      Size(constraints.maxWidth, _padding.vertical + 1),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) => _padding.vertical + 1;

  @override
  double computeMaxIntrinsicHeight(double width) => _padding.vertical + 1;

  @override
  void paint(PaintingContext context, Offset offset) {
    final r = Rect.fromLTWH(
      offset.dx + _padding.left,
      offset.dy + _padding.top,
      size.width - _padding.horizontal,
      1,
    );
    if (r.width > 0) context.canvas.drawRect(r, Paint()..color = _color);
  }
}
