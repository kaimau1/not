import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show BoxHitTestResult, RenderProxyBox;

import '../viewers/ink_layer.dart';

/// Kalem/izinli girdiyi daha parmak inerken kazanır: altındaki metin alanı,
/// kaydırma ve sayfa çekişi bu dokunuşu hiç görmez. İzinsiz girdi (kalem
/// kipinde parmak) yarışa girmez, yani yazıya dokunup klavyeyle yazılır.
/// Kalem yazarken değen avuç da üstlenilir (yutulur, bkz.
/// [InkController.claims]). Kalem kipi kapalıyken kalemin TEK BAŞINA tıkı
/// ([InkController.stylusTapMayPass]) kıpırdamazsa bırakılır: alttaki
/// kutucuk/metin tıklanır; kayarsa çizgi olur.
class _InkClaimRecognizer extends OneSequenceGestureRecognizer {
  _InkClaimRecognizer(this.ink);

  InkController ink;
  final Map<int, Offset> _taps = {};

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      ink.claims(event.kind) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (ink.stylusTapMayPass(event.kind)) {
      _taps[event.pointer] = event.position;
      return;
    }
    _settle(event.pointer, GestureDisposition.accepted);
  }

  void _settle(int pointer, GestureDisposition disposition) {
    _taps.remove(pointer);
    resolvePointer(pointer, disposition);
    stopTrackingPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    final start = _taps[event.pointer];
    if (start == null) return;
    if (event is PointerMoveEvent &&
        (event.position - start).distance > InkController.stylusTapSlop) {
      _settle(event.pointer, GestureDisposition.accepted);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _settle(event.pointer, GestureDisposition.rejected);
    }
  }

  @override
  void rejectGesture(int pointer) {
    _taps.remove(pointer);
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'ink claim';
}

/// Kalemi (izinli girdiyi) ve kalem yazarken değen AVUCU üstlenen sarmalayıcı
/// (bkz. [_InkClaimRecognizer]). Sabit/gömülü PDF'in kalem katmanı da
/// kullanır (2026-11-10: orada avuç sayfayı kaydırıp çeviriyordu; parmak
/// yine kaydırır, çünkü izinsiz girdi yarışa girmez).
class InkClaim extends StatelessWidget {
  const InkClaim({super.key, required this.ink, required this.child});

  final InkController ink;
  final Widget child;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    gestures: {
      _InkClaimRecognizer:
          GestureRecognizerFactoryWithHandlers<_InkClaimRecognizer>(
            () => _InkClaimRecognizer(ink),
            (r) => r.ink = ink,
          ),
    },
    child: child,
  );
}

/// **SAYFANIN ÜSTÜNDEKİ EL YAZISI** (kullanıcı isteği 2026-11-02: "kalemle
/// yazma ve normal sayfa bütünleşik olsun, her yere kalemle yazılabilsin,
/// klavyeyle de aynı notta yazılabilsin").
///
/// Çizim görsel olarak nota girmez, sayfanın üstünde saydam bir katmandır:
/// yazı onun altında kalmaz, parmak dokunuşu katmandan geçer. Noktalar
/// `x/genişlik`, `y/GENİŞLİK` birimindedir ([InkPageLayer.uniform]) — sayfa
/// uzadıkça çizim kaymaz. Sınır: metin sonradan akarsa çizim birlikte kaymaz;
/// ekran genişliği değişirse çizim genişlikle orantılı büyür.
class PageInkStack extends StatefulWidget {
  const PageInkStack({
    super.key,
    required this.ink,
    required this.page,
    required this.penActive,
    required this.scroll,
    required this.child,
  });

  final InkController ink;

  /// 1 tabanlı metin sayfası.
  final int page;

  /// Kalem kipi açık: sayfanın altında yazmaya devam edecek boş yer bırakılır.
  final bool penActive;

  /// Parmakla çizilirken iki parmak bununla kaydırır.
  final ScrollController scroll;

  final Widget child;

  @override
  State<PageInkStack> createState() => _PageInkStackState();
}

class _PageInkStackState extends State<PageInkStack> {
  double _bottom = 0;
  final Map<int, double> _fingers = {};

  @override
  void initState() {
    super.initState();
    _bottom = _measure();
    widget.ink.addListener(_onInk);
  }

  @override
  void didUpdateWidget(PageInkStack old) {
    super.didUpdateWidget(old);
    if (old.ink != widget.ink) {
      old.ink.removeListener(_onInk);
      widget.ink.addListener(_onInk);
    }
    if (old.page != widget.page) _bottom = _measure();
  }

  @override
  void dispose() {
    widget.ink.removeListener(_onInk);
    super.dispose();
  }

  /// Çizginin en alt noktası (genişlik birimiyle).
  double _measure() {
    var bottom = 0.0;
    for (final s in widget.ink.ink) {
      if (s.page != widget.page) continue;
      for (var i = 1; i < s.points.length; i += 2) {
        bottom = math.max(bottom, s.points[i]);
      }
    }
    return bottom;
  }

  /// Her harekette bütün çizgileri taramamak için son nokta yeter: en alt
  /// nokta ancak son çizgiyle büyür. Küçülme sonraki açılışta ölçülür.
  void _onInk() {
    final last = widget.ink.ink.lastOrNull;
    if (last == null || last.points.length < 2) return;
    final y = last.points.last;
    if (y > _bottom + 0.05) setState(() => _bottom = y);
  }

  void _fingerScroll(PointerMoveEvent e) {
    if (!_fingers.containsKey(e.pointer)) return;
    _fingers[e.pointer] = e.position.dy;
    if (_fingers.length < 2 || !widget.scroll.hasClients) return;
    widget.ink.beginNav();
    final pos = widget.scroll.position;
    pos.jumpTo(
      (pos.pixels - e.delta.dy / _fingers.length).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      ),
    );
  }

  void _fingerUp(int pointer) {
    _fingers.remove(pointer);
    if (_fingers.length < 2) widget.ink.endNav();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    widget.ink.passStylusTaps = !widget.penActive;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          widget.child,
          SizedBox(
            width: box.maxWidth,
            height:
                _bottom * box.maxWidth +
                (widget.penActive ? viewport * 0.7 : 24),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                if (e.kind == PointerDeviceKind.touch &&
                    widget.ink.accepts(e.kind)) {
                  _fingers[e.pointer] = e.position.dy;
                }
              },
              onPointerMove: _fingerScroll,
              onPointerUp: (e) => _fingerUp(e.pointer),
              onPointerCancel: (e) => _fingerUp(e.pointer),
              child: RawGestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                gestures: {
                  _InkClaimRecognizer:
                      GestureRecognizerFactoryWithHandlers<_InkClaimRecognizer>(
                        () => _InkClaimRecognizer(widget.ink),
                        (_) {},
                      ),
                },
                child: _SkipExclusions(
                  child: InkPageLayer(
                    controller: widget.ink,
                    page: widget.page,
                    uniform: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **SAYFA KALEMİNİN DOKUNMADIĞI KUTU** (2026-11-09: "gömülü PDF'e yazınca
/// yazı sayfaya gidiyor"). Sayfa mürekkebi tüm sayfanın ÜSTÜNDE; bu bölgenin
/// içine düşen dokunuş sayfa katmanına hiç ulaşmaz (isabet testi), alttaki
/// kutu (kendi kalem katmanıyla) alır.
class InkExclusionZone extends StatefulWidget {
  const InkExclusionZone({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  /// [global] bir bölgenin içinde mi.
  static bool covers(Offset global) {
    for (final s in _zones) {
      if (!s.widget.enabled || !s.mounted) continue;
      final box = s.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final local = box.globalToLocal(global);
      if ((Offset.zero & box.size).contains(local)) return true;
    }
    return false;
  }

  static final Set<_InkExclusionZoneState> _zones = {};

  @override
  State<InkExclusionZone> createState() => _InkExclusionZoneState();
}

class _InkExclusionZoneState extends State<InkExclusionZone> {
  @override
  void initState() {
    super.initState();
    InkExclusionZone._zones.add(this);
  }

  @override
  void dispose() {
    InkExclusionZone._zones.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// [InkExclusionZone] içindeki noktada isabet vermez.
class _SkipExclusions extends SingleChildRenderObjectWidget {
  const _SkipExclusions({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSkipExclusions();
}

class _RenderSkipExclusions extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (InkExclusionZone._zones.isNotEmpty &&
        InkExclusionZone.covers(localToGlobal(position))) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
