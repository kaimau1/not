import 'package:flutter/material.dart';

import 'zoom_math.dart';

/// İçeriği **çift dokunuşla** yakınlaştıran, sonra iki parmakla serbestçe
/// yakınlaştırıp uzaklaştırılabilen kutu.
///
/// Slaytlarda kullanılıyor: sunum sayfası ekrana sığdırılmış hâlde geliyor ve
/// küçük yazılar okunmuyordu (kullanıcı isteği 2026-08-08: "sayfalara zoom
/// yapamıyorum; çift tıklayınca zoom yapsın, sonra iki parmakla zoom in/out
/// olsun").
///
/// Çift dokunuş DOKUNULAN NOKTAYA yakınlaşır (ekranın ortasına değil):
/// okunmak istenen yer parmağın altındaki yerdir. İkinci çift dokunuş sığdır
/// hâline döner. Geçiş animasyonlu — ani sıçrama nerede olduğunu kaybettirir.
///
/// [onZoomChanged] yakınlaşma durumu değişince bildirir; slayt görüntüleyicisi
/// bununla `PageView`i kilitler — yakınken yatay sürükleme slayt değiştirmek
/// değil, büyütülmüş sayfada gezinmektir.
class ZoomBox extends StatefulWidget {
  const ZoomBox({
    super.key,
    required this.child,
    this.onZoomChanged,
    this.maxScale = 5,
    this.doubleTapScale = 2.5,
    this.enabled = true,
  });

  final Widget child;
  final ValueChanged<bool>? onZoomChanged;
  final double maxScale;

  /// false ise jestler kapalı ama ölçek KORUNUR — çizim kipinde tek parmak
  /// çizmeli, yakınlaştırma da kaybolmamalı.
  final bool enabled;

  /// Çift dokunuşun götürdüğü ölçek.
  final double doubleTapScale;

  @override
  State<ZoomBox> createState() => _ZoomBoxState();
}

class _ZoomBoxState extends State<ZoomBox> with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _tween;

  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onMatrixChanged);
    _anim.addListener(() {
      final tween = _tween;
      if (tween != null) _controller.value = tween.value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final zoomed = isZoomed(_controller.value);
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
    // Yalnız durum DEĞİŞİNCE yeniden çizilir: her ölçek karesinde setState
    // çağırmak yakınlaştırmayı takılmalı gösterirdi.
    setState(() {});
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _controller.value, end: target).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _anim.forward(from: 0);
  }

  /// Kutunun son ölçülen boyu — çift dokunuşun sınır hesabı için.
  Size _viewport = Size.zero;

  void _handleDoubleTap(TapDownDetails details) {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    // Dokunulan nokta sabit kalacak şekilde ölçekle; sonuç kutunun içine
    // sıkıştırılır (kenara yakın dokunuşta boşluk açılmasın). Hesap tam
    // ekran görsel görüntüleyicisiyle ORTAK: bkz. zoom_math.dart.
    _animateTo(
      zoomAt(
        current: _controller.value,
        viewportPoint: details.localPosition,
        viewport: _viewport,
        scale: widget.doubleTapScale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _viewport = constraints.biggest;
      return _gestures();
    },
  );

  Widget _gestures() => GestureDetector(
    // Çift dokunuşun KONUMU gerekiyor; `onDoubleTap` konum vermiyor, bu
    // yüzden `onDoubleTapDown` ile yakalanıp burada saklanıyor.
    onDoubleTapDown: widget.enabled ? _handleDoubleTap : null,
    onDoubleTap: widget.enabled ? () {} : null,
    child: InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: widget.maxScale,
      // Yakın değilken kaydırma KAPALI: sığdırılmış slaytta tek parmak
      // hareketi listeyi kaydırmalı, boşlukta gezinme değil.
      panEnabled: widget.enabled && _zoomed,
      scaleEnabled: widget.enabled,
      child: widget.child,
    ),
  );
}
