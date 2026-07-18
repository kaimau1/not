import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../domain/note_type.dart';

/// Keep tarzı açılan "+" düğmesi: dokununca metin / madde listesi /
/// sıralı liste / el yazısı seçenekleri etiketli mini düğmeler olarak
/// üstte belirir; tekrar dokununca kapanır.
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
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _select(VoidCallback action) {
    setState(() => _open = false);
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Seçenekler yalnız açıkken; AnimatedSize ile yumuşak açılır.
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomRight,
          child: !_open
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _option(
                      icon: Icons.draw_outlined,
                      label: l10n.newHandwriting,
                      onTap: widget.onHandwriting,
                    ),
                    _option(
                      icon: Icons.format_list_numbered_rounded,
                      label: l10n.newOrderedList,
                      onTap: () => widget.onCreate(NoteType.ordered),
                    ),
                    _option(
                      icon: Icons.check_box_outlined,
                      label: l10n.newChecklist,
                      onTap: () => widget.onCreate(NoteType.checklist),
                    ),
                    _option(
                      icon: Icons.notes,
                      label: l10n.newTextNote,
                      onTap: () => widget.onCreate(NoteType.text),
                    ),
                  ],
                ),
        ),
        FloatingActionButton(
          heroTag: 'add-fab',
          tooltip: l10n.newTextNote,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0, // + → × dönüşü
            duration: const Duration(milliseconds: 160),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
