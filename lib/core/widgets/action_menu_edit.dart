part of 'action_menu_sheet.dart';

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
