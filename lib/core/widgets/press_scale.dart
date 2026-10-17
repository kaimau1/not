import 'dart:async';

import 'package:flutter/widgets.dart';

/// **BASINCA HAFİFÇE ÇÖKEN KART** — iOS'taki dokunsal his (kullanıcı isteği
/// 2026-10-17: "premium gösteren iPhone gibi akıcılık").
///
/// Parmak kartın üstüne inince kart %3 küçülür, kalkınca yaylı bir eğriyle
/// yerine oturur. Yalnız GÖRSEL bir dönüşüm: dokunuş, uzun basış, sürükleme
/// ve seçim davranışlarına hiç karışmaz (dinleyici [Listener] — jest
/// yarışmasına girmez).
///
/// KAYDIRMADA TİTREMESİN: parmak inince küçülme hemen değil kısa bir süre
/// sonra başlar ve parmak [_slop]'tan fazla kayarsa (liste kaydırılıyor)
/// iptal olur — ızgarada kaydırırken kartlar tek tek "nefes almasın".
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;

  /// Basılıyken ölçek (1 = değişmez).
  final double scale;

  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  static const _delay = Duration(milliseconds: 70);
  static const _slop = 10.0;

  bool _pressed = false;
  Timer? _timer;
  Offset? _down;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _onDown(PointerDownEvent e) {
    if (!widget.enabled) return;
    _down = e.position;
    _timer?.cancel();
    _timer = Timer(_delay, () => _set(true));
  }

  void _onMove(PointerMoveEvent e) {
    final down = _down;
    if (down == null) return;
    if ((e.position - down).distance > _slop) _release();
  }

  void _release() {
    _down = null;
    _timer?.cancel();
    _timer = null;
    _set(false);
  }

  /// Kısa dokunuşta (gecikme dolmadan kalkan parmak) da his kaybolmasın:
  /// kart bir an çöküp geri gelir.
  void _onUp(PointerUpEvent e) {
    final quickTap = _timer?.isActive ?? false;
    _release();
    if (!quickTap || !widget.enabled) return;
    _set(true);
    _timer = Timer(const Duration(milliseconds: 90), () => _set(false));
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _onDown,
    onPointerMove: _onMove,
    onPointerUp: _onUp,
    onPointerCancel: (_) => _release(),
    child: AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: _pressed
          ? const Duration(milliseconds: 110)
          : const Duration(milliseconds: 260),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: widget.child,
    ),
  );
}
