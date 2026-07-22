import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';
import '../domain/note_type.dart';

/// "+" düğmesi: TEK dokunuş doğrudan yeni METİN notu açar (en sık iş tek
/// harekete indi — Keep davranışı); basılı tutunca madde listesi / sıralı
/// liste / el yazısı / metin seçenekleri etiketli mini düğmeler olarak belirir.
///
/// Seçenekler bir Overlay katmanında, düğmeye demirlenmiş olarak gösterilir:
/// - Böylece açılınca yerinde büyüyüp üstteki sesli asistan düğmesini
///   ittirmez, konum kaymaz (madde 3).
/// - Tam ekran görünmez bir bariyer, sayfanın herhangi bir yerine dokununca
///   menüyü kapatır — tekrar "+" basmaya gerek kalmaz (madde 12).
class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.anchor,
    required this.onCreate,
    required this.onHandwriting,
  });

  /// Menünün demirlendiği nokta. Dashboard bunu mikrofon + "+" sütununun
  /// TAMAMINI saracak şekilde verir; menü sütunun tepesinden açılır ve
  /// mikrofon düğmesinin üstünü örtmez.
  final LayerLink anchor;

  final void Function(NoteType type) onCreate;
  final VoidCallback onHandwriting;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  OverlayEntry? _entry;

  bool get _open => _entry != null;

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
            link: widget.anchor,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -12),
            child: Material(
              color: Colors.transparent,
              child: _StaggeredMenu(
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onInverseSurface,
                ),
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
    // FAB'ın onLongPress'i yok: uzun basış dıştaki GestureDetector'a düşer
    // (InkWell uzun basışı sahiplenmediğinden çakışma olmaz).
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        if (!_open) _openMenu();
      },
      child: FloatingActionButton(
        heroTag: 'add-fab',
        tooltip: l10n.quickAddTooltip,
        onPressed: _open
            ? _close
            // Tek dokunuş = anında metin notu; tip menüsü uzun basışta.
            : () => widget.onCreate(NoteType.text),
        child: AnimatedRotation(
          turns: _open ? 0.125 : 0, // + → × dönüşü
          duration: const Duration(milliseconds: 160),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Seçenekleri "+" düğmesinden çıkıyormuş gibi sırayla açar: her biri
/// aşağıdan hafifçe yükselerek belirir, düğmeye en yakın olan önce.
///
/// Süreler Material hareket ölçütlerine göre: öğe başına ~155 ms, aralarında
/// ~31 ms gecikme (30-50 ms bandı), girişte easeOut. Yalnız opacity/transform
/// canlandırılır — layout hesabı yapılmaz.
class _StaggeredMenu extends StatefulWidget {
  const _StaggeredMenu({required this.children});

  final List<Widget> children;

  @override
  State<_StaggeredMenu> createState() => _StaggeredMenuState();
}

class _StaggeredMenuState extends State<_StaggeredMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    // Erişilebilirlik: sistemde "hareketi azalt" açıksa animasyon yok,
    // menü anında görünür.
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++)
          if (animate)
            _staggered(i, children.length, children[i])
          else
            children[i],
      ],
    );
  }

  Widget _staggered(int index, int count, Widget child) {
    // Liste yukarıdan aşağı dizili; düğmeye en yakın olan SON eleman, bu
    // yüzden gecikme tersten hesaplanır.
    const step = 0.12;
    final start = (count - 1 - index) * step;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        (start + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, inner) => Transform.translate(
          offset: Offset(0, 16 * (1 - animation.value)),
          child: Transform.scale(
            scale: 0.9 + 0.1 * animation.value,
            alignment: Alignment.centerRight,
            child: inner,
          ),
        ),
      ),
    );
  }
}
