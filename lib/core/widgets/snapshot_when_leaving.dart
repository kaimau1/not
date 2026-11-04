import 'package:flutter/widgets.dart';

/// Ayrılan (geçişte solup kayan) görünümü BİR KEZ görüntüye alıp o görüntüyü
/// çizer (F26.4, AKICILIK_PLANI K9).
///
/// Ana ekranın segment geçişinde (`AnimatedSwitcher`, 260 ms) eski ve yeni
/// ızgara birlikte ayaktaydı ve ESKİ ızgara — hiç değişmediği hâlde — her
/// karede yarı saydam katmanda baştan rasterleşiyordu (bütün kartlar,
/// küçük resimler). Ayrılan görünüm artık donmuş görüntüdür; yalnız yenisi
/// canlı çizilir. Dokunuşlar da ayrılana gitmez.
///
/// Sarmalayıcı HER ZAMAN ağaçtadır (yalnız [leaving] değişir): yapı
/// değişseydi çocuğun durumu (kaydırma konumu, kart önbellekleri) sıfırdan
/// kurulurdu. Platform görünümü (video) varsa `permissive` olağan çizime
/// döner.
class SnapshotWhenLeaving extends StatefulWidget {
  const SnapshotWhenLeaving({
    super.key,
    required this.leaving,
    required this.child,
  });

  final bool leaving;
  final Widget child;

  @override
  State<SnapshotWhenLeaving> createState() => _SnapshotWhenLeavingState();
}

class _SnapshotWhenLeavingState extends State<SnapshotWhenLeaving> {
  late final SnapshotController _controller = SnapshotController(
    allowSnapshotting: widget.leaving,
  );

  @override
  void didUpdateWidget(SnapshotWhenLeaving oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving != oldWidget.leaving) {
      _controller.allowSnapshotting = widget.leaving;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: widget.leaving,
    child: SnapshotWidget(
      controller: _controller,
      mode: SnapshotMode.permissive,
      child: widget.child,
    ),
  );
}
