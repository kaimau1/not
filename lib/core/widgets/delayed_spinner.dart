import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';

/// **GECİKMELİ HALKA** (DENEYIM_PLANI §2.3, ilke 5): 300 ms altında biten
/// işte halka hiç görünmez; daha uzun sürerse `AppMotion.quick` sürede
/// solarak belirir. Hareket azaltılmışsa solma yok, doğrudan belirir.
class DelayedSpinner extends StatefulWidget {
  const DelayedSpinner({
    super.key,
    this.delay = AppMotion.medium, // 300 ms eşiği
    this.child = const CircularProgressIndicator(),
  });

  final Duration delay;
  final Widget child;

  @override
  State<DelayedSpinner> createState() => _DelayedSpinnerState();
}

class _DelayedSpinnerState extends State<DelayedSpinner> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _visible ? 1 : 0,
    duration: motionOf(context) ? AppMotion.quick : Duration.zero,
    child: widget.child,
  );
}
