import '../../app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

import 'app_notice.dart';

/// Belirtilen süre boyunca dolu→boş küçülen ince bir çubuk. Otomatik kapanan
/// bildirim/paneller için "ne kadar süre kalacağı" görsel olarak belli olur.
/// [onEnd] verilirse süre bitince çağrılır (paneli kendisi kapatmak için).
class CountdownBar extends StatelessWidget {
  const CountdownBar({
    super.key,
    required this.duration,
    this.onEnd,
    this.color,
  });

  final Duration duration;
  final VoidCallback? onEnd;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    // K-38: TweenAnimationBuilder her karede ClipRRect +
    // LinearProgressIndicator kuruyordu; adımlı boyama aynı görünümü verir.
    return SteppedCountdown(
      duration: duration,
      onEnd: onEnd,
      height: 3,
      color: c,
      trackColor: c.withValues(alpha: 0.18),
      radius: AppRadius.hair,
    );
  }
}
