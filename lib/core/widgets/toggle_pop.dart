import 'package:flutter/widgets.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';

/// **İĞNE/YILDIZ TEPKİSİ** (DENEYIM F77.3-1): [on] değişince [child] bir kez
/// 1 → 1,15 → 1 atar (`quick`, `standard`). Yalnız boyamada (`Transform`):
/// yerleşim değişmez, ağaç şekli hiç değişmez. Denetleyici ilk değişimde
/// kurulur (satır başına kalıcı ticker yok). Hareket azaltılmışsa atmaz.
class TogglePop extends StatefulWidget {
  const TogglePop({super.key, required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  State<TogglePop> createState() => _TogglePopState();
}

class _TogglePopState extends State<TogglePop>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Animation<double> _scale = const AlwaysStoppedAnimation(1);

  static final _pop = TweenSequence<double>([
    for (final (a, b) in [(1.0, 1.15), (1.15, 1.0)])
      TweenSequenceItem(
        tween: Tween(begin: a, end: b)
            .chain(CurveTween(curve: AppMotion.standard)),
        weight: 1,
      ),
  ]);

  @override
  void didUpdateWidget(TogglePop old) {
    super.didUpdateWidget(old);
    if (old.on == widget.on || !motionOf(context)) return;
    final c = _c ??= AnimationController(vsync: this, duration: AppMotion.quick);
    _scale = c.drive(_pop);
    c.forward(from: 0);
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
