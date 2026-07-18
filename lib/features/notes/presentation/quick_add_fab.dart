import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/note_type.dart';

/// Keep tarzı açılan "+" düğmesi: dokununca metin / madde listesi /
/// sıralı liste / el yazısı seçenekleri etiketli mini düğmeler olarak
/// üstte belirir.
///
/// Seçenekler bir Overlay katmanında, düğmeye demirlenmiş olarak gösterilir:
/// - Böylece açılınca yerinde büyüyüp üstteki sesli asistan düğmesini
///   ittirmez, konum kaymaz (madde 3).
/// - Tam ekran görünmez bir bariyer, sayfanın herhangi bir yerine dokununca
///   menüyü kapatır — tekrar "+" basmaya gerek kalmaz (madde 12).
class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.onCreate,
    required this.onHandwriting,
  });

  final void Function(NoteType type) onCreate;
  final VoidCallback onHandwriting;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  void _toggle() => _open ? _close() : _openMenu();

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _openMenu() {
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dışarı dokununca kapanan tam ekran (görünmez) bariyer.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          // Seçenekler "+" düğmesinin hemen üstüne demirlenir (layout'u
          // değiştirmez, sesli asistan düğmesi yerinden oynamaz).
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -12),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _option(
                    icon: Icons.draw_outlined,
                    label: context.l10n.newHandwriting,
                    onTap: widget.onHandwriting,
                  ),
                  _option(
                    icon: Icons.format_list_numbered_rounded,
                    label: context.l10n.newOrderedList,
                    onTap: () => widget.onCreate(NoteType.ordered),
                  ),
                  _option(
                    icon: Icons.check_box_outlined,
                    label: context.l10n.newChecklist,
                    onTap: () => widget.onCreate(NoteType.checklist),
                  ),
                  _option(
                    icon: Icons.notes,
                    label: context.l10n.newTextNote,
                    onTap: () => widget.onCreate(NoteType.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _select(VoidCallback action) {
    _close();
    action();
  }

  Widget _option({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: scheme.onInverseSurface),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.small(
            heroTag: 'quick-add-$label',
            onPressed: () => _select(onTap),
            child: Icon(icon, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CompositedTransformTarget(
      link: _link,
      child: FloatingActionButton(
        heroTag: 'add-fab',
        tooltip: l10n.newTextNote,
        onPressed: _toggle,
        child: AnimatedRotation(
          turns: _open ? 0.125 : 0, // + → × dönüşü
          duration: const Duration(milliseconds: 160),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
