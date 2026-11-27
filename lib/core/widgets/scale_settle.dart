import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../a11y/motion.dart';
import '../../app/theme/app_tokens.dart';

/// **YUMUŞAK YAZI BOYUTU GEÇİŞİ** (kullanıcı isteği 2026-10-28: "yazı boyutu
/// geçişleri daha yumuşak"). [value] (ör. notun yazı ölçeği) değişince metin
/// yeni boyutunda HEMEN yerleşir ama eski boyuttan yenisine doğru kısa bir
/// ölçek animasyonuyla oturur — "zıplama" yerine büyüyüp küçülme hissi.
///
/// Yalnız BOYAMA katmanında (`Transform`): yerleşim her karede yeniden
/// yapılmaz, uzun notta da maliyetsiz. [enabled] false iken (ör. sayfada
/// yüzen görsel var — sarma ölçümü dönüşümden etkilenmesin) değer aynen
/// uygulanır; ağaç yapısı değişmez (alanın durumu korunur).
class ScaleSettle extends StatefulWidget {
  const ScaleSettle({
    super.key,
    required this.value,
    required this.child,
    this.enabled = true,
    this.alignment = AlignmentDirectional.topStart,
    this.duration = const Duration(milliseconds: 260),
  });

  final double value;
  final Widget child;
  final bool enabled;
  final AlignmentGeometry alignment;
  final Duration duration;

  @override
  State<ScaleSettle> createState() => _ScaleSettleState();
}

class _ScaleSettleState extends State<ScaleSettle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  double _from = 1;

  @override
  void didUpdateWidget(ScaleSettle old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value || !widget.enabled) return;
    if (old.value <= 0 || widget.value <= 0) return;
    _from = (old.value / widget.value).clamp(0.6, 1.6).toDouble();
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = AppMotion.emphasized.transform(_c.value);
        // Hareketi azalt (F15.5): yeni boya anında oturur.
        final scale = widget.enabled && motionOf(context)
            ? lerpDouble(_from, 1, t)!
            : 1.0;
        return Transform.scale(
          scale: scale,
          alignment: widget.alignment,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Açılan panelin içeriği yerinde süzülerek belirir (hafif yukarı kayma +
/// solma). Her yeni kurulumda bir kez oynar (`FadeTransition`, saveLayer yok).
class RevealUp extends StatefulWidget {
  const RevealUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.offset = 14,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  State<RevealUp> createState() => _RevealUpState();
}

class _RevealUpState extends State<RevealUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _c,
    curve: AppMotion.emphasized,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!motionOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(RevealUp old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) _c.duration = widget.duration;
  }

  @override
  void dispose() {
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hareketi azalt (F15.5): içerik anında yerinde.
    if (!motionOf(context)) return widget.child;
    return FadeTransition(
      opacity: _curved,
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
