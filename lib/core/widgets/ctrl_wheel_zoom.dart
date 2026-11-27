import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// **WEB'DE CTRL + TEKERLEK = YAZI BOYUTU** (kullanıcı isteği 2026-11-27:
/// "web'de Ctrl + fare tekerleğiyle en azından yazı boyutu büyüyüp
/// küçülmeli").
///
/// KÖK NEDEN: Flutter web tekerlek olayını kaydırılabilir alana verir ve
/// tarayıcının varsayılanını (sayfa yakınlaştırma) engeller; Ctrl basılıyken
/// de yalnız sayfa kayıyordu. Bu sarmalayıcı isabet yoluna KENDİNİ en başa
/// koyar: işaretçi sinyali çözücüsüne ilk o kaydolur, Ctrl (ya da ⌘) basılı
/// tekerlekte kaydırma yerine [onZoom] (+1 büyüt, -1 küçült) çalışır.
/// Ctrl'siz tekerlek hiç etkilenmez.
class CtrlWheelZoom extends SingleChildRenderObjectWidget {
  const CtrlWheelZoom({super.key, required this.onZoom, super.child});

  final ValueChanged<int> onZoom;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderCtrlWheelZoom(onZoom);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCtrlWheelZoom renderObject,
  ) {
    renderObject.onZoom = onZoom;
  }
}

class RenderCtrlWheelZoom extends RenderProxyBox {
  RenderCtrlWheelZoom(this.onZoom);

  ValueChanged<int> onZoom;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    // Önce kendisi: çözücüye kaydırılabilir alanlardan ÖNCE kaydolur.
    result.add(BoxHitTestEntry(this, position));
    hitTestChildren(result, position: position);
    return true;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    if (!keys.isControlPressed && !keys.isMetaPressed) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => onZoom(dy < 0 ? 1 : -1),
    );
  }
}
