import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Web ve masaüstünde yatay kaydırmalı şeritlerin (tema, zemin görseli, renk,
/// desen, ek şeridi vb.) fare tekerleği, fare sürükleme VE sağ/sol ok
/// düğmeleriyle sorunsuz kaydırılmasını sağlar.
///
/// Mobilde yalnızca [builder] çıktısını sarmalar (ek ok çizilmez).
class HorizontalScrollStrip extends StatefulWidget {
  const HorizontalScrollStrip({
    super.key,
    required this.builder,
    this.controller,
    this.step = 220,
    this.showArrowsOnTouch = false,
  });

  final Widget Function(BuildContext context, ScrollController controller)
  builder;
  final ScrollController? controller;
  final double step;
  final bool showArrowsOnTouch;

  @override
  State<HorizontalScrollStrip> createState() => _HorizontalScrollStripState();
}

class _HorizontalScrollStripState extends State<HorizontalScrollStrip> {
  ScrollController? _owned;
  bool _hovered = false;
  bool _canPrev = false;
  bool _canNext = false;

  ScrollController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = ScrollController();
    }
    _controller.addListener(_syncExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());
  }

  @override
  void didUpdateWidget(HorizontalScrollStrip old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      final prev = old.controller ?? _owned;
      prev?.removeListener(_syncExtent);
      if (widget.controller == null) {
        _owned ??= ScrollController();
      } else {
        _owned?.dispose();
        _owned = null;
      }
      _controller.addListener(_syncExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncExtent());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncExtent);
    _owned?.dispose();
    super.dispose();
  }

  void _syncExtent() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final prev = pos.pixels > 2;
    final next =
        pos.maxScrollExtent > 2 && pos.pixels < pos.maxScrollExtent - 2;
    if (prev != _canPrev || next != _canNext) {
      setState(() {
        _canPrev = prev;
        _canNext = next;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final target = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    unawaited(
      _controller.animateTo(
        target,
        duration: AppMotion.short,
        curve: AppMotion.emphasized,
      ),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    final pos = _controller.position;
    if (pos.maxScrollExtent <= 0) return;
    final next = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    if (next == pos.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (_controller.hasClients) _controller.jumpTo(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _syncExtent();
        return false;
      },
      child: widget.builder(context, _controller),
    );
    final showDesktopControls = kIsWeb || _hovered || widget.showArrowsOnTouch;
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.fromTheme(Theme.of(context));

    Widget arrowButton({
      required Key key,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Material(
        key: key,
        color: scheme.surface.withValues(alpha: AppAlpha.strong),
        elevation: 2,
        shape: CircleBorder(side: BorderSide(color: tokens.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: math.max(AppSpace.xxl, AppSpace.xl + AppSpace.xs),
            height: math.max(AppSpace.xxl, AppSpace.xl + AppSpace.xs),
            child: Icon(icon, size: AppIconSize.m, color: scheme.onSurface),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            if (showDesktopControls && _canPrev)
              PositionedDirectional(
                start: AppSpace.xs,
                child: arrowButton(
                  key: const ValueKey('horizontal-strip-prev'),
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _scrollBy(-widget.step),
                ),
              ),
            if (showDesktopControls && _canNext)
              PositionedDirectional(
                end: AppSpace.xs,
                child: arrowButton(
                  key: const ValueKey('horizontal-strip-next'),
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _scrollBy(widget.step),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
