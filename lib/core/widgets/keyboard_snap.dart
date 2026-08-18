import 'dart:async';

import 'package:flutter/material.dart';

/// Klavye yüksekliğini **kademeli** veren sarmalayıcı.
///
/// **KÖK NEDEN — "kasma devam ediyor klavye açılırken"** (kullanıcı bulgusu
/// 2026-08-18; 33., 35. ve 36. turlardaki düzeltmelerden sonra da sürüyor).
/// Önceki turlar yeniden KURULUMU (rebuild) durdurdu: alt çubuk artık aynı
/// widget örneğini döndürüyor, tuval sabit tabana kilitlendi. Kalan maliyet
/// YERLEŞİMDİ (layout): `Scaffold.resizeToAvoidBottomInset` gövdenin
/// yüksekliğini klavye animasyonunun HER KARESİNDE (~30 kare) değiştiriyor.
/// Kısıt değişince Flutter alt ağacı yeniden kurmasa bile YENİDEN ÖLÇER —
/// ağır ekranlarda (yüz karta yakın ana ekran ızgarası, görselli not tuvali,
/// PDF görüntüleyici) bu tek başına takılmayı doğuruyor. pdfrx'te ise her
/// yeni yükseklik sayfayı yeniden pişiriyor.
///
/// Çözüm: ilgili ekranda `resizeToAvoidBottomInset: false` yapılır ve klavye
/// boşluğu BURADAN verilir. Değer [step] kademelerine yuvarlandığı için
/// animasyon boyunca ~30 yerleşim yerine 3-4 tane olur; animasyon durunca da
/// tam değere inilir, ekranın altında kademe payı kalmaz.
///
/// `MediaQuery.viewInsetsOf` YALNIZ bu küçük widget'ı dinler; çocuk kademe
/// değişmedikçe **aynı widget örneğidir**, dolayısıyla ara karelerde ne
/// yeniden kurulur ne de yeniden ölçülür.
class KeyboardSnap extends StatefulWidget {
  const KeyboardSnap({super.key, required this.builder, this.step = 96});

  /// Kademeli klavye boşluğuyla çağrılır. Aynı boşluk için AYNI örnek
  /// döndürülür (önbellek burada tutulur), bu yüzden gövdesi serbestçe
  /// pahalı olabilir.
  final Widget Function(BuildContext context, double inset) builder;

  /// Yuvarlama kademesi (dp). Küçük değer daha akıcı ama daha çok yerleşim.
  final double step;

  @override
  State<KeyboardSnap> createState() => _KeyboardSnapState();
}

class _KeyboardSnapState extends State<KeyboardSnap> {
  double _inset = 0;

  /// Son build'te GÖRÜLEN ham (kademelenmemiş) değer.
  ///
  /// KÖK NEDEN (ilk sürümde test kırıldı): kademeleme her `build()`'te yeniden
  /// hesaplanıyordu — animasyon durup [_settle] tam değere indikten SONRA bile
  /// bir sonraki build (ör. tazeleme zamanlayıcısının kendi `setState`'i) aynı
  /// `live` değerini tekrar kademeliyor ve TAM değeri anında geri
  /// YUVARLIYORDU. Kademeleme artık YALNIZ `live` bir ÖNCEKİ build'e göre
  /// DEĞİŞTİYSE uygulanır; değişmediyse [_inset] (kademeli ya da tam) olduğu
  /// gibi kalır.
  double _lastLive = 0;

  Widget? _child;
  Timer? _settle;

  @override
  void didUpdateWidget(KeyboardSnap old) {
    super.didUpdateWidget(old);
    // Üst ekran yeniden kuruldu: `builder` yeni bir kapanış, önbellek bayat.
    // Bu ŞART — yoksa notun içeriği değişse de ekranda eski ağaç kalırdı.
    _child = null;
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  double _quantize(double live) =>
      live <= 0 ? 0 : (live / widget.step).ceil() * widget.step;

  /// Klavye [live] değerinde ~140 ms hareketsiz kalırsa TAM değere iner.
  /// Kademe yukarı yuvarladığı için klavyenin üstünde [step]'e kadar boşluk
  /// kalabilirdi; animasyon durduğunda bu pay silinir.
  void _scheduleSettle(double live) {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 140), () {
      if (!mounted || _inset == live) return;
      setState(() {
        _inset = live;
        _child = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.viewInsetsOf(context).bottom;
    if (live != _lastLive) {
      _lastLive = live;
      final target = _quantize(live);
      if (target != _inset) {
        _inset = target;
        _child = null;
      }
      _scheduleSettle(live);
    }
    return _child ??= widget.builder(context, _inset);
  }
}
