import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// **YANA ÇEKİŞLE SAYFA DEĞİŞTİRME** (kullanıcı isteği 2026-10-20: "defterde
/// sağa sola kaydırarak sayfa değiştirilebilsin").
///
/// Ham [Listener]: jest yarışına GİRMEZ. Sayfanın içinde metin alanları,
/// madde sürükleme, seçim tutamaçları ve dikey kaydırma var; bir
/// `HorizontalDragGestureRecognizer` onlarla yarışır ve kazandığında imleç
/// sürükleme / seçim bozulurdu. Burada yalnız parmak KALKINCA bakılır: kısa
/// sürede, belirgin biçimde YATAY ve yeterince uzun bir çekiş sayfa çevirir;
/// geri kalan her hareket (yazma, seçme, kaydırma) olduğu gibi akar.
class PageSwipeDetector extends StatefulWidget {
  const PageSwipeDetector({
    super.key,
    required this.child,
    required this.onSwipe,
    this.enabled = true,
  });

  final Widget child;

  /// +1 = sonraki sayfa (sola çekiş, sağdan sola dillerde sağa), -1 = önceki.
  final ValueChanged<int> onSwipe;
  final bool enabled;

  /// Çekişin en az yatay mesafesi (dp) ve en çok süresi.
  static const double minDistance = 72;
  static const Duration maxDuration = Duration(milliseconds: 450);

  @override
  State<PageSwipeDetector> createState() => _PageSwipeDetectorState();
}

class _PageSwipeDetectorState extends State<PageSwipeDetector> {
  int? _pointer;
  Offset _start = Offset.zero;
  Duration _startTime = Duration.zero;
  bool _multi = false;

  void _down(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch) return;
    if (_pointer != null) {
      // İkinci parmak: yakınlaştırma/iki parmak kaydırma — çekiş sayılmaz.
      _multi = true;
      return;
    }
    _pointer = e.pointer;
    _start = e.position;
    _startTime = e.timeStamp;
    _multi = false;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_multi || !widget.enabled) return;
    final delta = e.position - _start;
    final elapsed = e.timeStamp - _startTime;
    if (elapsed > PageSwipeDetector.maxDuration) return;
    if (delta.dx.abs() < PageSwipeDetector.minDistance) return;
    if (delta.dx.abs() < delta.dy.abs() * 2.2) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward = rtl ? delta.dx > 0 : delta.dx < 0;
    widget.onSwipe(forward ? 1 : -1);
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}
