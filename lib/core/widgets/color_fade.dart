import 'package:flutter/widgets.dart';

import '../../app/theme/app_tokens.dart';

/// Rengi değişince eskisinden yenisine soluklaşır (TEMA_PLANI F34.4), ağaç
/// yeniden kurulmadan: [child] aynı örnek, yalnız [builder]ın kapağı değişir.
///
/// Denetleyici İLK DEĞİŞİMDE kurulur: kartta kullanıldığı için kart başına
/// kalıcı animasyon/ticker YOK (akıcılık bütçesi, AKICILIK F21). [identity]
/// değişirse (hücre başka nota geçti, tema değişti) rengi anında alır — tema
/// değişiminde ekrandaki bütün kartlar aynı anda animasyona girmesin.
class ColorFade extends StatefulWidget {
  const ColorFade({
    super.key,
    required this.color,
    required this.identity,
    required this.builder,
    required this.child,
  });

  final Color color;
  final Object identity;
  final Widget Function(BuildContext context, Color color, Widget child)
  builder;
  final Widget child;

  @override
  State<ColorFade> createState() => _ColorFadeState();
}

class _ColorFadeState extends State<ColorFade>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Color? _from;

  /// [to] ile [_from] arasındaki o anki renk.
  Color _at(Color to) {
    final from = _from;
    final c = _controller;
    if (from == null || c == null) return to;
    return Color.lerp(from, to, AppMotion.standard.transform(c.value))!;
  }

  @override
  void didUpdateWidget(ColorFade old) {
    super.didUpdateWidget(old);
    if (old.identity != widget.identity) {
      _controller?.stop();
      _from = null;
      return;
    }
    if (old.color == widget.color) return;
    // Yarıda değişirse göründüğü renkten devam eder.
    _from = _at(old.color);
    final controller = _controller ??= AnimationController(vsync: this)
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _from = null;
      });
    controller
      ..duration = AppMotion.of(context, AppMotion.short)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _at(widget.color), widget.child);
}
