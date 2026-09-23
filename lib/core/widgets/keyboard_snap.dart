import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Klavye boşluğunu İKİ AYRI yoldan veren sarmalayıcı: gövdeye KARARLI
/// (yerleşim için), alt çubuğa CANLI (yalnız boyama için).
///
/// **KÖK NEDEN — "kasma büyük oranda çözüldü ama hâlâ var, alt çubuk klavye
/// açılıp kapanırken kayıyor"** (kullanıcı bulgusu 2026-08-22, ekran
/// görüntüsünde biçim/ekle/seç çubuğu işaretli).
///
/// Bu widget'ın ÖNCEKİ sürümü klavye yüksekliğini 96 dp'lik KADEMELERE
/// yuvarlıyordu. Doğru yöne gitmişti — yerleşim sayısı ~30'dan 3-4'e indi,
/// kasma gerçekten azaldı — ama yerine görünür bir kusur koydu: alt çubuk
/// artık 0 → 96 → 192 → 288 → (tam değer) diye DÖRT SIÇRAYIŞLA yukarı
/// çıkıyordu. Kullanıcının gördüğü "zıplama" tam olarak buydu. Yani kademe,
/// pahalı yerleşimle akıcı hareket arasındaki bir UZLAŞMAYDI ve ikisini de
/// tam veremiyordu.
///
/// **Kökten çözüm — ikisinin AYNI değerden beslenmesi gerekmiyor.**
///
/// * **Yerleşim (pahalı, seyrek olmalı)**: gövdenin boşluğu animasyon
///   BOYUNCA HİÇ değişmez. Klavye açılırken gövde tam boyunda kalır (kısalan
///   kısım zaten klavyenin ve çubuğun ardındadır, görünmez); kapanırken daha
///   İLK karede tam boya döner (açılacak alan böylece boş değil, DOLU
///   ortaya çıkar). Boşluk yalnızca klavye ~140 ms durduğunda (yani açılış
///   bittiğinde) gerçek değerine oturur. Sonuç: bir açılış/kapanış çevriminde
///   gövde TOPLAM İKİ KEZ ölçülür — kare başına değil.
/// * **Hareket (bedava, kare kare olmalı)**: alt çubuk [KeyboardSlide] ile
///   klavyeyi kare kare izler ama yalnız BOYAMA katmanında (`Transform` +
///   `RepaintBoundary`). Yerleşim yoktur, dolayısıyla kademeye de gerek
///   yoktur: hareket cihazın yenileme hızında akar.
///
/// Böylece kasma (yerleşim yok) ve zıplama (kademe yok) aynı anda biter.
///
/// Kullanım: ilgili ekranda `resizeToAvoidBottomInset: false` yapılır, gövde
/// [builder]'ın verdiği kararlı boşlukla doldurulur, klavyeyle birlikte
/// kayması istenen çubuk AYNI boşluk verilerek [KeyboardSlide] ile sarılır.
/// Çubuğun kendisi [builder]'ın DIŞINDA kurulup içeri aynı örnek olarak
/// verilmelidir; yoksa boşluk her oturduğunda çubuk da baştan kurulur.
class KeyboardSnap extends StatefulWidget {
  const KeyboardSnap({
    super.key,
    required this.builder,
    this.onSettled,
    this.settle = const Duration(milliseconds: 140),
  });

  /// Kararlı klavye boşluğuyla çağrılır. Aynı boşluk için AYNI örnek
  /// döndürülür (önbellek burada tutulur), bu yüzden gövdesi serbestçe
  /// pahalı olabilir.
  final Widget Function(BuildContext context, double inset) builder;

  /// Boşluk oturup YENİ YERLEŞİM EKRANA GELDİKTEN sonra çağrılır.
  ///
  /// Neden gerekli: `EditableText` imleci klavyenin üstüne kaydırmak için
  /// `didChangeMetrics`e (yani klavye yüksekliğinin değiştiği KARELERE)
  /// bakar. Burada gövde o karelerde bilerek TAM BOYUNDA tutulduğu için
  /// Flutter "imleç zaten görünüyor" diye kaydırmaz; boşluk ise 140 ms sonra
  /// oturur ve alanı klavyenin ardında bırakabilir. Çağıran bu geri
  /// bildirimde odaklı alanın İMLECİNİ görünür kılar (bkz. editördeki
  /// `_revealCaret`).
  final ValueChanged<double>? onSettled;

  /// Klavyenin "durdu" sayılması için gereken hareketsizlik süresi. Bu süre
  /// dolmadan gövde yeniden ölçülmez.
  final Duration settle;

  @override
  State<KeyboardSnap> createState() => _KeyboardSnapState();
}

class _KeyboardSnapState extends State<KeyboardSnap> {
  /// Gövdenin yerleşiminde kullanılan KARARLI boşluk. Animasyon sırasında 0,
  /// klavye durduğunda gerçek yükseklik.
  double _inset = 0;

  /// Son build'te GÖRÜLEN ham (canlı) değer.
  ///
  /// KÖK NEDEN (önceki sürümde test kırıldı): hedef her `build()`'te yeniden
  /// hesaplanıyordu — klavye durup boşluk oturduktan SONRA bile bir sonraki
  /// build (ör. tazeleme zamanlayıcısının kendi `setState`'i) aynı değeri
  /// tekrar işleyip oturmuş boşluğu geri ALIYORDU. Hesap artık YALNIZ `live`
  /// bir önceki build'e göre DEĞİŞTİYSE yapılır.
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

  /// Klavye [live] değerinde [KeyboardSnap.settle] kadar hareketsiz kalırsa
  /// gövde gerçek yüksekliğe oturur. Açılışta bu, animasyonun BİTTİĞİ andır:
  /// gövdenin kısalan kısmı o sırada klavyenin ardındadır, yani ölçüm gözle
  /// görülmez.
  void _scheduleSettle(double live) {
    _settle?.cancel();
    _settle = Timer(widget.settle, () {
      if (!mounted || _inset == live) return;
      setState(() {
        _inset = live;
        _child = null;
      });
      // Yeni yerleşim ekrana geldikten SONRA: geri bildirimi alan taraf
      // (odaklı alanı görünür kılmak gibi) gerçek ölçülerle çalışsın.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettled?.call(live);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.viewInsetsOf(context).bottom;
    if (live != _lastLive) {
      _lastLive = live;
      // Klavye HAREKET HÂLİNDE: gövde tam boyuna döner ve animasyon bitene
      // kadar öyle kalır. Kapanışta bunun ayrıca bir faydası var — açılan
      // alan içeriğiyle birlikte ortaya çıkar, bir kare bile boş görünmez.
      if (_inset != 0) {
        _inset = 0;
        _child = null;
      }
      _scheduleSettle(live);
    }
    return _child ??= widget.builder(context, _inset);
  }
}

/// Çocuğunu klavyenin üstünde KARE KARE tutar — ama yalnız BOYAYARAK.
///
/// [KeyboardSnap] gövdeye KARARLI bir boşluk verir ([inset]); çubuk o
/// boşluğun üstüne yerleşmiştir. Canlı klavye yüksekliği o boşluktan farklı
/// olduğu her karede aradaki FARK kadar ötelenir, böylece çubuğun alt kenarı
/// HER KAREDE tam olarak klavyenin üst kenarına oturur — animasyonun
/// ortasında bile.
///
/// Neden bedava:
/// * `MediaQuery.viewInsetsOf` YALNIZ bu küçük widget'ı dinler; [child]
///   dışarıdan hazır gelen AYNI örnek olduğu için alt ağaç hiç kurulmaz.
/// * Değişen tek şey `Transform`un ötelemesi → `markNeedsPaint`. Hiçbir
///   yerleşim (layout) yoktur, dolayısıyla kademeye de gerek yoktur.
/// * Dıştaki `RepaintBoundary` boyama isteğinin ekranın geri kalanına
///   yayılmasını keser; çağıranın çocuğa koyduğu sınır sayesinde de çubuğun
///   rasteri yeniden çizilmez, hazır katman yalnız yeni konuma taşınır.
class KeyboardSlide extends StatelessWidget {
  const KeyboardSlide({super.key, required this.inset, required this.child});

  /// [KeyboardSnap]'in gövdeye verdiği KARARLI boşluk.
  final double inset;

  /// Kaydırılacak ağaç. Çağıran tarafta bir `RepaintBoundary` ile sarılı
  /// olması beklenir (bkz. sınıf açıklaması).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final live = MediaQuery.viewInsetsOf(context).bottom;
    // **GEZİNME ÇUBUĞU PAYI BURADA, SABİT** (kullanıcı bulgusu 2026-09-23:
    // "klavye açılırken alt alan hâlâ takılarak, kayarak yukarı çıkıyor").
    //
    // KÖK NEDEN: çubuğun içindeki `BottomAppBar` kendi `SafeArea`sını
    // taşıyor ve alt güvenli alanı `MediaQuery.padding`den okuyor. O değer
    // "gezinme çubuğu − klavye" demek: klavye yükselirken İLK ~48 dp'de kare
    // kare sıfıra iniyor. Yani animasyonun başında çubuğun YÜKSEKLİĞİ her
    // karede değişiyor, gövdenin `Column`u her karede yeniden yerleşiyordu —
    // [KeyboardSnap]'in bütün emeği ilk karelerde boşa gidiyor, çubuk da
    // klavyeyle değil kendi küçülmesiyle hareket ediyordu (kayma + takılma).
    //
    // Artık çubuğun altındaki pay (gezinme çubuğu yüksekliği —
    // `viewPadding`, klavyeden etkilenmez) BURADA veriliyor ve yalnız
    // KARARLI boşlukla değişiyor: klavye kapalıyken pay var, klavye OTURUNCA
    // yok. Çubuğun içi `padding.bottom = 0` görür, yüksekliği animasyon
    // boyunca hiç değişmez; aradaki her fark yine yalnız ötelemeyle kapanır.
    final nav = MediaQuery.viewPaddingOf(context).bottom;
    final pad = inset > 0 ? 0.0 : nav;
    // Çubuğun İÇERİĞİNİN ekranın dibinden olması gereken uzaklığı: klavye
    // gezinme çubuğundan alçaksa (kapalı ya da açılışın ilk kareleri)
    // gezinme çubuğunun üstü, değilse klavyenin üstü.
    final floor = math.max(nav, live);
    // Pozitif = AŞAĞI. Yerleşimdeki yer (boşluk + pay) ile olması gereken
    // yer arasındaki fark; boşluk oturunca kendiliğinden sıfırlanır — oturma
    // anı ekranda görünmez.
    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, inset + pad - floor),
        child: Padding(
          padding: EdgeInsets.only(bottom: pad),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
    );
  }
}
