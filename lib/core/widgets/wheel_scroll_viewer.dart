import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `InteractiveViewer` + fare tekerleği düzeltmesi: tekerlek içteki dikey
/// kaydırmayı çalıştırsın, yakınlaştırma yalnız Ctrl+tekerlekle olsun.
///
/// Neden: `InteractiveViewer` tekerlek sinyalini PointerSignalResolver'a
/// girmeden doğrudan zoom sayar; içteki kaydırma ancak ilk tıkta çalışır, sonra
/// "yakın" sayılıp kilitlenir ve tekerlek hep zoom yapar (web, sabit PDF).
/// Olay sırası en derinden köke olduğu için alttaki dinleyici matrisi
/// InteractiveViewer'dan ÖNCE saklar, üstteki ondan SONRA geri yükler.
/// Dokunmatik jestler ve izleyici paneli (trackpad) etkilenmez.
class WheelScrollViewer extends StatefulWidget {
  const WheelScrollViewer({
    super.key,
    required this.controller,
    required this.panEnabled,
    required this.child,
    this.maxScale = 4,
  });

  final TransformationController controller;
  final bool panEnabled;
  final double maxScale;
  final Widget child;

  @override
  State<WheelScrollViewer> createState() => _WheelScrollViewerState();
}

class _WheelScrollViewerState extends State<WheelScrollViewer> {
  Matrix4? _before;

  bool _plainWheel(PointerSignalEvent e) =>
      e is PointerScrollEvent &&
      e.kind != PointerDeviceKind.trackpad &&
      !HardwareKeyboard.instance.isControlPressed;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (e) {
      final before = _before;
      if (before != null && _plainWheel(e)) widget.controller.value = before;
    },
    child: InteractiveViewer(
      transformationController: widget.controller,
      maxScale: widget.maxScale,
      panEnabled: widget.panEnabled,
      child: Listener(
        onPointerSignal: (e) => _before = widget.controller.value.clone(),
        child: widget.child,
      ),
    ),
  );
}
