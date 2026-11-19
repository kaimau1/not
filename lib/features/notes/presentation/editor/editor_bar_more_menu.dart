import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';

/// Alt çubuk düğmesinin menüdeki karşılığı: (simge, ad, iş, etkin).
typedef BarMoreSpec = (IconData, String, VoidCallback, bool);

/// **ALT ÇUBUĞUN ⋯ MENÜSÜ** (kullanıcı isteği 2026-11-19: "alt panel 3
/// noktasında diğer butonlar eksik; düzenle butonu olmalı, hangileri hemen
/// görülecek hangileri menüsü içinde olacak seçilebilmeli — ayrı ekranda
/// değil, direkt menü üzerinde").
///
/// Normal kipte: çubuğa sığmayan VE çubuktan kaldırılmış (gizli) bütün
/// düğmeler, en altta "Düzenle". Düzenle kipinde AYNI menü yerinde liste
/// olur: 📌 = çubukta / menüde, basılı tutup sürükle = sırala. Değişiklik
/// anında kaydedilir ([Personalize.update]); çubuk arkada canlı yenilenir.
///
/// Konum düğmenin kendi bağlamından ([anchor]); seçilen düğmenin işi
/// menü kapandıktan sonra çalışır.
Future<void> showEditorBarMore({
  required BuildContext anchor,
  required List<String> menuIds,
  required List<String> available,
  required BarMoreSpec Function(String id) spec,
}) async {
  final box = anchor.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(anchor).context.findRenderObject()! as RenderBox;
  final picked = await showMenu<String>(
    context: anchor,
    position: RelativeRect.fromRect(
      box.localToGlobal(Offset.zero, ancestor: overlay) & box.size,
      Offset.zero & overlay.size,
    ),
    items: [_BarMoreEntry(menuIds: menuIds, available: available, spec: spec)],
  );
  if (picked != null) spec(picked).$3();
}

class _BarMoreEntry extends PopupMenuEntry<String> {
  const _BarMoreEntry({
    required this.menuIds,
    required this.available,
    required this.spec,
  });

  final List<String> menuIds;
  final List<String> available;
  final BarMoreSpec Function(String id) spec;

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(String? value) => false;

  @override
  State<_BarMoreEntry> createState() => _BarMoreEntryState();
}

class _BarMoreEntryState extends State<_BarMoreEntry> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) =>
      _editing ? _editor(context) : _list(context);

  Widget _row(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: key,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIconSize.m,
                color: active ? scheme.primary : null,
              ),
              const SizedBox(width: AppSpace.m),
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, id) in widget.menuIds.indexed)
          if (widget.spec(id) case (final icon, final label, _, final on))
            _row(
              context,
              key: ValueKey('editor-bar-more-$i'),
              icon: icon,
              label: label,
              active: on,
              onTap: () => Navigator.pop(context, id),
            ),
        if (widget.menuIds.isNotEmpty) const Divider(height: 1),
        _row(
          context,
          key: const ValueKey('editor-bar-more-edit'),
          icon: Icons.tune,
          label: l10n.barMoreEdit,
          onTap: () => setState(() => _editing = true),
        ),
      ],
    );
  }

  /// Kullanıcının kalıcı sırasında, bu notta bulunan düğmeler.
  List<String> _ordered(List<String> side) => [
    for (final id in side)
      if (widget.available.contains(id)) id,
  ];

  /// [visible] içindeki yer değişimini tam sıraya ([full]) işler: bu notta
  /// olmayan düğmeler yerinde kalır.
  static List<String> _apply(
    List<String> full,
    List<String> visible,
    int from,
    int to,
  ) {
    final moved = List.of(visible);
    moved.insert(to, moved.removeAt(from));
    final it = moved.iterator;
    return [
      for (final id in full)
        if (!visible.contains(id)) id else (it..moveNext()).current,
    ];
  }

  Widget _editor(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Personalize.prefs,
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        final sides = prefs.barSides;
        final left = _ordered(sides.left), right = _ordered(sides.right);
        Widget group(
          String key,
          List<String> ids,
          void Function(int, int) onReorder,
        ) => ReorderableListView(
          key: ValueKey('editor-bar-more-group-$key'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: onReorder,
          children: [
            for (final (i, id) in ids.indexed)
              _editRow(context, id, i, prefs.storedShows(id)),
          ],
        );
        // Sabit genişlik: açılır menü içeriğinin içsel genişliğini sorar,
        // kayan liste bunu veremez (menünün tavanı 280 dp).
        return SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.s,
                ),
                child: Text(
                  l10n.barMoreEditHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              group(
                'left',
                left,
                (from, to) => Personalize.update(
                  (p) => p.copyWith(
                    barOrder: _apply(p.barSides.left, left, from, to),
                  ),
                ),
              ),
              if (right.isNotEmpty) ...[
                const Divider(height: 1),
                group(
                  'right',
                  right,
                  (from, to) => Personalize.update(
                    (p) => p.copyWith(
                      aiOrder: _apply(p.barSides.right, right, from, to),
                    ),
                  ),
                ),
              ],
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                  child: TextButton(
                    key: const ValueKey('editor-bar-more-done'),
                    onPressed: () => setState(() => _editing = false),
                    child: Text(l10n.customizeDone),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _editRow(BuildContext context, String id, int index, bool pinned) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, _, _) = widget.spec(id);
    return ReorderableDelayedDragStartListener(
      key: ValueKey('editor-bar-more-row-$id'),
      index: index,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.l),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: AppIconSize.s,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.s),
              Icon(icon, size: AppIconSize.m),
              const SizedBox(width: AppSpace.m),
              Expanded(child: Text(label)),
              IconButton(
                key: ValueKey('editor-bar-more-pin-$id'),
                tooltip: pinned ? l10n.barMoreToMenu : l10n.barMoreToBar,
                isSelected: pinned,
                icon: const Icon(Icons.push_pin_outlined),
                selectedIcon: Icon(Icons.push_pin, color: scheme.primary),
                onPressed: () =>
                    Personalize.update((p) => p.withVisible(id, !pinned)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
