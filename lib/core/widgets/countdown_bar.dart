import 'package:flutter/material.dart';

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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: duration,
      onEnd: onEnd,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          backgroundColor: (color ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.18),
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
