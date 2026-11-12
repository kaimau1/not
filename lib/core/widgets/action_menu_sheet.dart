import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n_ext.dart';
import '../menu_layout.dart';
import 'app_sheet.dart';
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
/// Başlıklı menüde ✕ var → tutamak ÇİZİLMEZ (DENEYIM K-D7; aşağı çekerek
/// kapatma yine çalışır). Başlıksız menüde ✕ yok, tutamak kalır.
Future<String?> showActionMenuSheet(BuildContext context, ActionMenu menu) =>
    showAppSheet<String>(
      context: context,
      showDragHandle: !menu.hasHeader,
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
  });

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
    if (orphans.isNotEmpty) sectionsOut.add(MenuSection(otherTitle, orphans));
    return (quickOut, sectionsOut);
  }

  @override
  Widget build(BuildContext context) {
    final id = menuId;
    if (id == null) return _body(context, quick, sections);
    return ValueListenableBuilder<Map<String, MenuLayout>>(
      valueListenable: MenuLayouts.layouts,
      builder: (context, _, _) {
        final (q, secs) = _arranged(
          MenuLayouts.of(id),
          context.l10n.menuSectionOther,
        );
        return _body(context, q, secs);
      },
    );
  }

  Future<void> _edit(BuildContext context) => showAppSheet<void>(
    context: context,
    // Düzenleyicide SheetHeader (✕) var → tutamak yok (K-D7).
    showDragHandle: false,
    isScrollControlled: true,
    builder: (_) => _MenuLayoutEditor(menu: this),
  );

  Widget _body(
    BuildContext context,
    List<MenuAction> quick,
    List<MenuSection> sections,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final heading = title?.trim() ?? '';
    final editButton = _settingsButton(context, scheme, compact: false);
    final visibleSections = [
      for (final section in sections)
        if (section.actions.isNotEmpty) section,
    ];
    final inlineEdit = heading.isNotEmpty
        ? null
        : _settingsButton(context, scheme, compact: true);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Menü levhasında başlık = notun adı, ✕ sağda (F16.2).
          // Tutamak yok (K-D7): başlık levhanın tepesinden 56 dp'lik satır.
          if (heading.isNotEmpty)
            SheetHeader(
              title: heading,
              actions: [?editButton],
              padding: EdgeInsets.zero,
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
          for (final (i, section) in visibleSections.indexed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              // Başlıksız menüde ⚙ kendi satırını kaplamasın (kullanıcı
              // bulgusu 2026-11-06: "düzenleme simgesi üstte boşa bir satır
              // kaplıyor"): ilk bölüm başlığının sağında durur.
              child: i == 0 && inlineEdit != null
                  ? SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Expanded(child: SectionLabel(section.title)),
                          inlineEdit,
                        ],
                      ),
                    )
                  : SectionLabel(section.title),
            ),
            _TileGrid(actions: section.actions, scheme: scheme),
          ],
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
        onPressed: () => _edit(context),
      );
    }
    const editId = 'menu.editLayout';
    return PopupMenuButton<String>(
      key: const ValueKey('menu-edit'),
      tooltip: l10n.settings,
      icon: icon,
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
      onSelected: (id) {
        if (id == editId) {
          _edit(context);
        } else {
          Navigator.pop(context, id);
        }
      },
      itemBuilder: (_) => [
        if (menuId != null)
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
                if (action.badge != null)
                  Positioned(right: -4, top: -4, child: action.badge!),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.2),
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
                fontSize: 12,
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

/// **MENÜYÜ DÜZENLE**: işlemleri sürükleyerek sırala, göz ile gizle/göster,
/// yıldız ile hızlı satıra al (en çok [MenuLayout.maxQuick]). Kaydet anında
/// menüye yansır; "Varsayılan" kaydı siler.
class _MenuLayoutEditor extends StatefulWidget {
  const _MenuLayoutEditor({required this.menu});

  final ActionMenu menu;

  @override
  State<_MenuLayoutEditor> createState() => _MenuLayoutEditorState();
}

class _MenuLayoutEditorState extends State<_MenuLayoutEditor> {
  late final MenuLayout _start = MenuLayouts.of(widget.menu.menuId!);
  late final Map<String, MenuAction> _all = {
    for (final a in widget.menu.quick) a.id: a,
    for (final s in widget.menu.sections)
      for (final a in s.actions) a.id: a,
  };
  late final Set<String> _hidden = {..._start.hidden};
  late final List<String> _quick = [
    ...?_start.quick?.where(_all.containsKey),
    if (_start.quick == null) for (final a in widget.menu.quick) a.id,
  ];
  late final List<String> _order = _start.sorted(
    [
      for (final s in widget.menu.sections)
        for (final a in s.actions) a.id,
      for (final a in widget.menu.quick)
        if (!widget.menu.sections.any((s) => s.actions.any((x) => x.id == a.id)))
          a.id,
    ],
    (id) => id,
  );

  void _save() {
    MenuLayouts.set(
      widget.menu.menuId!,
      MenuLayout(
        hidden: _hidden,
        quick: _quick,
        order: _order,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.menuEdit),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.menuEditHint(MenuLayout.maxQuick),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) => setState(() {
                  _order.insert(to, _order.removeAt(from));
                }),
                children: [
                  for (var i = 0; i < _order.length; i++)
                    if (_all[_order[i]] case final a?)
                      ListTile(
                        key: ValueKey('menu-edit-${a.id}'),
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle),
                        ),
                        title: Row(
                          children: [
                            Icon(a.icon, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.label,
                                style: TextStyle(
                                  color: _hidden.contains(a.id)
                                      ? scheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              key: ValueKey('menu-quick-${a.id}'),
                              tooltip: l10n.menuQuickRow,
                              isSelected: _quick.contains(a.id),
                              icon: const Icon(Icons.star_outline),
                              selectedIcon: Icon(
                                Icons.star,
                                color: scheme.primary,
                              ),
                              onPressed: () => setState(() {
                                if (_quick.contains(a.id)) {
                                  _quick.remove(a.id);
                                } else if (_quick.length < MenuLayout.maxQuick) {
                                  _quick.add(a.id);
                                  _hidden.remove(a.id);
                                }
                              }),
                            ),
                            IconButton(
                              key: ValueKey('menu-visible-${a.id}'),
                              tooltip: l10n.menuShowHide,
                              icon: Icon(
                                _hidden.contains(a.id)
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() {
                                if (!_hidden.remove(a.id)) {
                                  _hidden.add(a.id);
                                  _quick.remove(a.id);
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  TextButton(
                    key: const ValueKey('menu-edit-reset'),
                    onPressed: () {
                      MenuLayouts.set(
                        widget.menu.menuId!,
                        const MenuLayout(),
                      );
                      Navigator.pop(context);
                    },
                    child: Text(l10n.menuReset),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('menu-edit-save'),
                    onPressed: _save,
                    child: Text(l10n.eventSave),
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

