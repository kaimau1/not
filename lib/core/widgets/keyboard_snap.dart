import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';

/// Klavye boşluğunun DAR KANALI (F60.S5, kullanıcı 2026-11-11: "klavye
/// açılırken alt paneldeki titreme kasmayı kökünden çöz, tekrar yaşanmayacak
/// şekilde").
///
/// **KÖK NEDEN.** Klavye hareket ederken `MediaQuery` her karede değişir
/// (`viewInsets.bottom` büyür, `padding.bottom` erir). Editörün `Scaffold`'ı
/// — `resizeToAvoidBottomInset: false` olsa bile — `MediaQuery`'ye bağlıdır:
/// her karede kendi iskeletini (Material, üst çubuk yuvası, her yuvaya yeni
/// bir `MediaQuery`) yeniden kurar ve yerleşim kutusunu yeniden dizer;
/// altındaki her `SafeArea` ve `viewInsetsOf` okuyan her widget da öyle.
/// Ölçüm (412×915, 18 karelik klavye): hareket karesi başına ≈ 87 kurulum +
/// 1 yerleşim; klavyeyi GERÇEKTEN izlemesi gereken yapraklar ise 5-6 tane.
/// Kareler pahalılaşınca kare düşer; klavye ilerler, çubuk bir kare geride
/// kalır — görülen titreme budur (çubuğun konum hesabı her karede doğru).
///
/// **Çözüm — iki ayrı kanal.** Bu kapsam ekranın `Scaffold`'ının ÜSTÜNE
/// konur:
/// * Alt ağaca **KARARLI** bir `MediaQuery` verir: `viewInsets.bottom` ve
///   `padding.bottom` klavye hareket ederken HİÇ değişmez; klavye
///   [settle] kadar durunca (açılış bitti) gerçek değere oturur, yeniden
///   kıpırdadığı ilk karede sıfıra döner. Yani bir açılış/kapanış çevriminde
///   en çok İKİ kez değişir — `Scaffold`, `SafeArea` ve farkında olmadan
///   `MediaQuery` okuyan her şey kare kare kurulamaz.
/// * **CANLI** değer yalnız [KeyboardInset.liveOf] ile okunur; bağımlılık
///   okuyan YAPRAKTA kalır ([KeyboardSlide], klavye anahtarı, seçim çubuğu).
///
/// Kapsam yoksa (başka ekranlar, yalın testler) [KeyboardInset.liveOf]
/// `MediaQuery.viewInsetsOf`'a düşer; [KeyboardSnap] kendi sayacını kullanır.
///
/// Kural: bu kapsamın altında klavyeyi kare kare izlemesi gereken yeni bir
/// widget `MediaQuery.viewInsetsOf` DEĞİL [KeyboardInset.liveOf] okur
/// (bekçi: `test/keyboard_jank_guard_test.dart` S17).
class KeyboardInsetScope extends StatefulWidget {
  const KeyboardInsetScope({
    super.key,
    required this.child,
    this.settle = const Duration(milliseconds: 140),
  });

  /// Çağıranın kurduğu ağaç: klavye karelerinde AYNI örnek kalır, kurulmaz.
  final Widget child;

  /// Klavyenin "durdu" sayılması için gereken hareketsizlik süresi.
  final Duration settle;

  @override
  State<KeyboardInsetScope> createState() => _KeyboardInsetScopeState();
}

class _KeyboardInsetScopeState extends State<KeyboardInsetScope> {
  /// Alt ağacın gördüğü KARARLI boşluk: hareket sırasında 0, durunca gerçek.
  double _stable = 0;
  double _lastLive = 0;
  Timer? _settle;

  /// Motor şu an ANİMASYON karesi mi veriyor (bkz. [_trackEngine]).
  bool _animating = false;
  double _lastStep = double.infinity;

  /// **ALT PANEL TİTREMESİ — KÖK NEDEN** (P55, cihaz izi 2026-11-13, Mi Note
  /// 10 Lite API 31, 3 düğmeli gezinme): Flutter motoru klavye animasyonu
  /// sürerken IME boşluğundan gezinme çubuğunu DÜŞÜYOR
  /// (`ImeSyncDeferringInsetsCallback.onProgress`, `SDK_INT < 35`),
  /// animasyon bitince tam değeri veriyor: 18 → … → 253,1 → 300,7. Videoda
  /// klavyenin görünen üst kenarı her karede bildirilen + 47,3 dp. Çubuk
  /// bildirilen değere oturduğu için açılış/kapanış boyunca öneri şeridinin
  /// ALTINDA kalıyor, klavye durunca birden beliriyordu. Widget testleri
  /// göremiyordu: sahte boşluk "gerçek" klavyeydi.
  ///
  /// Düzeltme: animasyon karelerinde canlı değer + gezinme çubuğu. Durum
  /// makinesi: her değişiklik animasyon başlatır (dinlenmeden çıkış —
  /// kapanışın ilk karesi 300,7 → 253,5 de böyle: + 47,3 = aynı yer); bitiş
  /// karesi = yavaşlamış hareketin ardından tam gezinme çubuğu boyunda TEK
  /// yukarı adım (motorun `onEnd`'i) ya da 0; ya da klavye [settle] kadar
  /// durdu. Yanlış tanırsa çubuk birkaç kare eski yerde (bugünkü hâl) kalır.
  ///
  /// **Birleşen bitiş karesi** (S47, 2026-11-15): `onProgress` platform, kare
  /// UI iş parçacığında; fazları kayınca bir Flutter karesine son bir-iki
  /// ilerleme adımı + bitiş BİRLİKTE düşer: adım = gezinme + kuyruk. Eskiden
  /// yalnız `+ 3` dp kuyruk tanınıyordu; kısa/hızlı klavyede kuyruk daha
  /// büyük → bitiş "animasyon karesi" sayılıp çubuk 140 ms gezinme boyu kadar
  /// YUKARIDA kalıyor, sonra iniyordu (S47 oturma sıçraması). Kuyruk artık
  /// yavaşlayan hareketin en çok iki adımı kadar olabilir.
  void _trackEngine(double live, double nav) {
    final step = live - _lastLive;
    final tail = math.max(0.0, _lastStep);
    final endJump =
        _animating &&
        step >= nav - 1 &&
        step <= nav + 2 * tail + 3 &&
        _lastStep > -nav / 4 &&
        _lastStep < nav / 4 &&
        live > 2 * nav;
    _animating = live > 0 && !endJump;
    _lastStep = step;
  }

  @override
  void dispose() {
    _settle?.cancel();
    KeyboardInset.moving.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final live = media.viewInsets.bottom;
    final nav = media.viewPadding.bottom;
    if (live != _lastLive) {
      _trackEngine(live, nav);
      _lastLive = live;
      // HAREKET HÂLİNDE: gövde tam boyda (bkz. [KeyboardSnap]).
      _stable = 0;
      KeyboardInset.moving.value = true;
      _settle?.cancel();
      _settle = Timer(widget.settle, () {
        KeyboardInset.moving.value = false;
        if (!mounted) return;
        // Klavye durdu: değer ne olursa olsun artık "animasyon karesi" değil.
        if (_stable == live && !_animating) return;
        setState(() {
          _stable = live;
          _animating = false;
        });
      });
    }
    // Android'in kuralı (alt pay = gezinme çubuğu − klavye), ama KARARLI
    // boşlukla: hareket boyunca pay yerinde kalır, oturunca tek adımda kalkar.
    return _LiveInset(
      value: _animating && KeyboardInset.navExcludedWhileAnimating && live > 0
          ? live + nav
          : live,
      child: _OpenInset(
        value: live > 0,
        child: _StableInset(
          value: _stable,
          child: MediaQuery(
            data: media.copyWith(
              viewInsets: media.viewInsets.copyWith(bottom: _stable),
              padding: media.padding.copyWith(
                bottom: math.max(0.0, nav - _stable),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _OpenInset extends InheritedWidget {
  const _OpenInset({required this.value, required super.child});
  final bool value;

  @override
  bool updateShouldNotify(_OpenInset old) => value != old.value;
}

class _LiveInset extends InheritedWidget {
  const _LiveInset({required this.value, required super.child});
  final double value;

  @override
  bool updateShouldNotify(_LiveInset old) => value != old.value;
}

class _StableInset extends InheritedWidget {
  const _StableInset({required this.value, required super.child});
  final double value;

  @override
  bool updateShouldNotify(_StableInset old) => value != old.value;
}

/// Klavye boşluğunu okuyan yaprakların kapısı (bkz. [KeyboardInsetScope]).
abstract final class KeyboardInset {
  /// Flutter motoru klavye ANİMASYONU sürerken IME boşluğundan gezinme
  /// çubuğunu düşüyor mu (Android < 35, bkz. [KeyboardInsetScope]).
  /// Açılışta [init] doldurur; testte elle.
  static bool navExcludedWhileAnimating = false;

  /// Android API düzeyini yerel köprüden bir kez okur (ilk kareden sonra).
  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final sdk = await const MethodChannel(
        'dev.kaimau.notlar/system',
      ).invokeMethod<int>('sdkInt');
      // Motor: `Build.VERSION.SDK_INT < API_35` iken düşer.
      navExcludedWhileAnimating = sdk != null && sdk < 35;
    } catch (_) {
      // Köprü yoksa eski davranış.
    }
  }

  /// Klavye ŞU AN hareket ediyor mu (açılış/kapanış animasyonu; durunca
  /// [KeyboardInsetScope.settle] sonra false). Kimse dinleyerek kurulmaz:
  /// ertelenebilir işler (ör. uzun listenin kademeli kurulumu,
  /// `ItemsEditor._growBudget`) yalnız `.value`'ya bakıp beklemeye alınır.
  static final ValueNotifier<bool> moving = ValueNotifier(false);

  /// CANLI klavye yüksekliği (kare kare). Çağıran widget klavyenin her
  /// karesinde yeniden kurulur — yalnız küçük yapraklarda oku.
  static double liveOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LiveInset>()?.value ??
      MediaQuery.viewInsetsOf(context).bottom;

  /// Klavye görünüyor mu (canlı değer > 0). Kapsamın altında çağıran
  /// yalnız klavye BELİRİNCE ve KAYBOLUNCA kurulur — kare kare değil.
  static bool openOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_OpenInset>()?.value ??
      MediaQuery.viewInsetsOf(context).bottom > 0;

  /// KARARLI boşluk (hareket sırasında 0); kapsam yoksa null.
  static double? maybeStableOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StableInset>()?.value;
}

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
    // Kapsam varsa sayaç ONDA (bkz. [KeyboardInsetScope]): bu widget klavye
    // karelerinde hiç kurulmaz, yalnız kararlı boşluk değişince.
    final scoped = KeyboardInset.maybeStableOf(context);
    if (scoped != null) {
      _settle?.cancel();
      _settle = null;
      if (scoped != _inset) {
        _inset = scoped;
        _child = null;
        if (scoped > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onSettled?.call(scoped);
          });
        }
      }
      return _child ??= widget.builder(context, _inset);
    }
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
class KeyboardSlide extends StatefulWidget {
  const KeyboardSlide({super.key, required this.inset, required this.child});

  /// [KeyboardSnap]'in gövdeye verdiği KARARLI boşluk.
  final double inset;

  /// Kaydırılacak ağaç. Çağıran tarafta bir `RepaintBoundary` ile sarılı
  /// olması beklenir (bkz. sınıf açıklaması).
  final Widget child;

  /// **ALT PANEL KİPİ** (S47, kullanıcı 2026-11-15: "klavye açılırken alt
  /// panel zıplaya zıplaya açılıyor … panel klavye açılırken gizlenip geri
  /// gelebilir mesela"). Cihazda kıyaslandı (2026-11-15, test telefonu ekran kaydı): c en akıcı → varsayılan c;
  /// derlemede `--dart-define=ALT_PANEL_KIP=a|b|c`:
  /// * `a` — panel iletilen klavye değerini kare kare BİREBİR izler (bugünkü
  ///   hâl). Klavyeyle konumu hep aynı, ama değerler Flutter karelerine
  ///   düzensiz düştüğünde (0/1/2 adım) panel takılıp sıçrar.
  /// * `b` — yumuşatma: panel hedefe her karede kalan yolun [smoothing]
  ///   oranı kadar yaklaşır (tek yön, aşma yok). Takılma kareleri dolar,
  ///   bedeli klavyenin biraz gerisinden gelmek.
  /// * `c` — klavye hareket ederken panel hızla solar, klavye oturunca
  ///   yerinde belirir.
  static String mode = const String.fromEnvironment(
    'ALT_PANEL_KIP',
    defaultValue: 'c',
  );

  /// `b` kipinde kare başına kalan yolun kapatılan oranı.
  static double smoothing = 0.6;

  /// `c`: klavye bu süre kıpırdamazsa panel belirir (kararlı boşluğun
  /// 140 ms'sini beklemeden). Kısa olursa takılan klavye karesinde panel
  /// erken görünüp yeniden gizlenebilir (cihazda ayar düğmesi).
  static Duration quiet = AppMotion.exitOf(AppMotion.instant); // ≈ 67 ms

  @override
  State<KeyboardSlide> createState() => _KeyboardSlideState();
}

class _KeyboardSlideState extends State<KeyboardSlide>
    with TickerProviderStateMixin {
  /// `b`: ekrandaki taban (ekranın dibinden uzaklık) ve hedef.
  double? _shown;
  double _target = 0;
  late final Ticker _ticker = createTicker((_) {
    if (mounted) setState(() {});
  });

  /// `c`: panelin görünürlüğü (1 = görünür). `FadeTransition` bir RENDER
  /// nesnesi sarmalayıcısı: animasyon kareleri yalnız boyar, hiçbir öğe
  /// yeniden kurulmaz (AnimatedOpacity klavye karesi başına +1 kurulum
  /// ekliyordu, S17/S45 mandalı). Eğri `animateTo`'da: ayrı CurvedAnimation
  /// / Tween nesnesi yok (her geçişte yenisi sızıyordu: editor_leak_test).
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _hidden = false;

  /// `c` — **KLAVYE HAREKETİNİ ERKEN YAKALAMA** (kullanıcı videosu
  /// 2026-11-15, `docs/perf/kullanici_video_2026-11-15.md`: kapanışta boşluk
  /// 2 → 58 → 2 → 74 → 130 px zikzak). Eskiden panel klavye değeri
  /// DEĞİŞTİĞİ karede 67 ms'lik solmaya başlıyordu: değer klavyeden bir-iki
  /// kare geç geldiği ve solmanın ilk kareleri hâlâ opak olduğu için panel
  /// kapanışın başında klavyeden AYRIK görünüyordu (zikzağın ilk kareleri).
  /// Şimdi (1) gizleme ANINDA (aynı kare opaklık 0), (2) odak sinyali: klavye
  /// açıkken odak metin alanından çıkınca (kapanacak) ya da kapalıyken metin
  /// alanına girince (açılacak) panel inset değişimini beklemeden gizlenir.
  /// Klavye [_expectTimeout] içinde kıpırdamazsa (donanım klavyesi vb.)
  /// geri gelir. Geri tuşuyla kapanışta odak değişmez: o yol (1)'e kalır.
  bool _expect = false;
  static const _expectTimeout = AppMotion.medium;

  /// `c`: klavye [KeyboardSlide.quiet] boyunca kıpırdamadı → panel, gövdenin
  /// kararlı boşluğu (140 ms) oturmadan belirir. Konum ötelemeyle zaten
  /// doğru; boşluk oturunca öteleme sıfırlanır, görünen yer aynı kalır.
  bool _quiet = false;
  double _lastLive = 0;
  Timer? _timer;

  static bool get _softKeyboard =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (KeyboardSlide.mode == 'c' && _softKeyboard) {
      FocusManager.instance.addListener(_onFocus);
    }
  }

  /// Odak metin düzenleyicisinde mi (yazılım klavyesi açık olacak mı).
  static bool _textFocused() =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  bool _wasText = _textFocused();

  void _onFocus() {
    final text = _textFocused();
    final changed = text != _wasText;
    _wasText = text;
    // Klavye açıkken metinden ÇIKIŞ = kapanacak; kapalıyken metne GİRİŞ =
    // açılacak. Alanlar arası geçiş (madde Enter'ı vb.) sinyal değil.
    if (!mounted || _expect || !changed || (_lastLive > 0) == text) return;
    _timer?.cancel();
    _timer = Timer(_expectTimeout, () {
      if (mounted && _expect) setState(() => _expect = false);
    });
    setState(() => _expect = true);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    _timer?.cancel();
    _ticker.dispose();
    _fade.dispose();
    super.dispose();
  }

  /// `c`: canlı değer değişti — beklenen hareket başladı (artık inset
  /// kuralı yönetir), sessizlik sayacı baştan.
  void _trackMotion(double live, bool moving) {
    if (live == _lastLive) return;
    _lastLive = live;
    _expect = false;
    _quiet = false;
    _timer?.cancel();
    _timer = moving
        ? Timer(KeyboardSlide.quiet, () {
            if (mounted) setState(() => _quiet = true);
          })
        : null;
  }

  /// `b`: hedefe kare başına [KeyboardSlide.smoothing] oranında yaklaş;
  /// hedef ulaşılınca saat durur (boşta kare yok).
  double _smooth(double target) {
    final shown = _shown;
    if (shown == null || KeyboardSlide.mode != 'b') {
      _shown = target;
      if (_ticker.isActive) _ticker.stop();
      return target;
    }
    if (target != _target) {
      _target = target;
      if (!_ticker.isActive) {
        // Bu kare değişikliğin karesi: ilk adım burada, sonrakiler saatle.
        _ticker.start();
      }
    }
    final gap = _target - shown;
    final next = gap.abs() < 0.5
        ? _target
        : shown + gap * KeyboardSlide.smoothing;
    if (next == _target && _ticker.isActive) _ticker.stop();
    return _shown = next;
  }

  @override
  Widget build(BuildContext context) {
    final inset = widget.inset;
    final live = KeyboardInset.liveOf(context);
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
    final floor = _smooth(math.max(nav, live));
    // `c`: klavye hareket ederken (canlı > 0 ama kararlı boşluk henüz
    // oturmadı) panel görünmez. Ağaç şekli kipten bağımsız (Opacity hep var).
    final moving = live > 0 && inset == 0;
    if (KeyboardSlide.mode == 'c') _trackMotion(live, moving);
    final hide =
        KeyboardSlide.mode == 'c' && (_expect || (moving && !_quiet));
    // Pozitif = AŞAĞI. Yerleşimdeki yer (boşluk + pay) ile olması gereken
    // yer arasındaki fark; boşluk oturunca kendiliğinden sıfırlanır — oturma
    // anı ekranda görünmez.
    Widget panel = Padding(
      padding: EdgeInsets.only(bottom: pad),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: widget.child,
      ),
    );
    // Solma sarmalayıcısı YALNIZ `c` kipinde (kip derlemede sabit, ağaç
    // şekli çalışırken değişmez): a/b'de klavye karesi başına +1 kurulum
    // olurdu (S17 mandalı).
    if (KeyboardSlide.mode == 'c') {
      if (hide != _hidden) {
        _hidden = hide;
        if (hide) {
          // ANINDA: hareketin ilk karesinde panel klavyeden ayrık görünmez.
          _fade.value = 0;
        } else {
          // Beliriş yumuşak; panel bu karede zaten doğru yerde (öteleme).
          _fade.animateTo(
            1,
            duration: AppMotion.quick,
            curve: AppMotion.standard,
          );
        }
      }
      panel = FadeTransition(opacity: _fade, child: panel);
    }
    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, inset + pad - floor),
        child: panel,
      ),
    );
  }
}

/// Klavyenin EVRESİ: açık mı, açılırken tahmini yüksekliği ne.
typedef KeyboardPhase = ({bool open, double estimate});

/// Klavyenin AŞAMASI — [KeyboardPhase]'in kapanışı ayrı söyleyen biçimi (bkz.
/// [KeyboardStageWatcher]). [open]: klavye ekranda (kapanırken de);
/// [closing]: iniyor; [estimate]: tam boy tahmini.
typedef KeyboardStage = ({bool open, bool closing, double estimate});

/// Klavyenin aşamasını HİÇBİR WIDGET KURMADAN izler (P49): pencere ölçüsü
/// değişince ([WidgetsBindingObserver.didChangeMetrics]) [stage] güncellenir
/// — yalnız aşama DEĞİŞİNCE haber verir (klavye görününce, inmeye
/// başlayınca, bitince; tahmin büyürse).
///
/// Neden [KeyboardPhaseListener] değil: o, klavyenin her karesinde kurulur;
/// bir `LayoutBuilder`'ın altındaysa her kurulum o `LayoutBuilder`'ı da
/// dizilmek üzere işaretler (S17 "dizilen sınır"). Ayrıca evreyi bir kare
/// SONRA bildirir. Sabit ek bölmesi boyunu klavyenin göründüğü ve bittiği
/// karede TEK ADIMDA değiştirir (kasma listesi §6); bunun için aşamayı o
/// karenin kurulumundan ÖNCE bilmesi gerekir.
class KeyboardStageWatcher with WidgetsBindingObserver {
  KeyboardStageWatcher() {
    WidgetsBinding.instance.addObserver(this);
    didChangeMetrics();
  }

  final stage = ValueNotifier<KeyboardStage>((
    open: false,
    closing: false,
    estimate: 0,
  ));

  double _last = 0;
  double _cycleMax = 0;
  bool _closing = false;

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final live = view.viewInsets.bottom / view.devicePixelRatio;
    if (live <= 0) {
      if (_cycleMax > 0) _KeyboardPhaseListenerState._memory = _cycleMax;
      _cycleMax = 0;
      _closing = false;
    } else {
      _cycleMax = math.max(_cycleMax, live);
      if (live > _last) {
        _closing = false;
      } else if (live < _last && live < _cycleMax * 0.85) {
        _closing = true;
      }
    }
    _last = live;
    final memory = _KeyboardPhaseListenerState._memory;
    stage.value = (
      open: live > 0,
      closing: _closing,
      estimate: live <= 0
          ? 0
          : math.max(
              _cycleMax,
              memory > 0
                  ? memory
                  : view.physicalSize.height / view.devicePixelRatio * 0.38,
            ),
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stage.dispose();
  }
}

/// Klavyenin AÇILIŞ/KAPANIŞ EVRESİNİ bildiren dinleyici — kare kare DEĞİL,
/// yalnız evre değişince ([onChanged]).
///
/// Neden: klavye açılırken sabit medya, belge bölmesi gibi ÜST parçaların
/// boyu değişmemeli (kullanıcı bulgusu 2026-10-20: "görsel, video, PDF
/// sabitken ya da balonlu kipte klavye açılınca görsel boyut değiştiriyor,
/// odak kayıyor"). [KeyboardSnap] gövdeyi klavye OTURDUKTAN sonra tek seferde
/// kısaltıyor; o anda üst parça da küçülüp zıplıyordu. Bu dinleyiciyle parça
/// klavyenin açıldığını İLK karede öğrenir, kendi görünür penceresini
/// ([KeyboardClipWindow]) klavyeyle birlikte yumuşakça daraltır — gövde
/// oturduğunda hedefte durduğu için hiçbir şey zıplamaz.
///
/// [child] çağıranın kurduğu AYNI örnek olmalı: klavyenin her karesinde
/// yalnız bu küçük widget kurulur, alt ağaç ellenmez.
class KeyboardPhaseListener extends StatefulWidget {
  const KeyboardPhaseListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final ValueChanged<KeyboardPhase> onChanged;
  final Widget child;

  @override
  State<KeyboardPhaseListener> createState() => _KeyboardPhaseListenerState();
}

class _KeyboardPhaseListenerState extends State<KeyboardPhaseListener> {
  /// Son açılışın TAM klavye yüksekliği (süreç ömrü): bir sonraki açılışın
  /// hedefi ilk karede bilinsin.
  static double _memory = 0;

  double _last = 0;
  double _cycleMax = 0;
  KeyboardPhase _reported = (open: false, estimate: 0);

  @override
  Widget build(BuildContext context) {
    final live = KeyboardInset.liveOf(context);
    final screen = MediaQuery.sizeOf(context).height;
    KeyboardPhase next;
    if (live <= 0) {
      if (_cycleMax > 0) _memory = _cycleMax;
      _cycleMax = 0;
      next = (open: false, estimate: 0);
    } else if (live < _last && live < _cycleMax * 0.85) {
      // KAPANIYOR: pencere klavyeyle birlikte geri açılsın (sonunu
      // beklemesin).
      next = (open: false, estimate: 0);
    } else {
      _cycleMax = math.max(_cycleMax, live);
      final guess = _memory > 0 ? _memory : screen * 0.38;
      next = (open: true, estimate: math.max(_cycleMax, guess));
    }
    _last = live;
    if (next != _reported) {
      _reported = next;
      // Kurulum sırasında üst widget'a setState yaptırılmaz: bir kare sonra.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _reported == next) widget.onChanged(next);
      });
    }
    return widget.child;
  }
}

/// Çocuğunu TAM boyunda ([full]) yerleştirip yalnız üstten [visible] kadarını
/// gösteren pencere; [visible] değişince pencere yumuşakça daralır/genişler.
///
/// Çocuk hiçbir karede yeniden ÖLÇÜLMEZ (kısıtı sabit): görsel/video/belge
/// küçülmez, zıplamaz — altındaki parça üstüne kayar gibi örter. Kırpılan
/// kısım dokunuş da almaz.
///
/// [shrink] açıkken kırpmak yerine çocuk pencereye SIĞACAK kadar ölçeklenir
/// (kullanıcı isteği 2026-10-20: "video klavye açılınca yumuşakça küçülsün,
/// kapanınca eski hâline dönsün"). Ölçek yalnız boyama katmanında
/// (`Transform`) — çocuk yine yeniden ölçülmez; yanlarda kalan pay
/// [background] ile boyanır.
class KeyboardClipWindow extends StatelessWidget {
  const KeyboardClipWindow({
    super.key,
    required this.full,
    required this.visible,
    required this.child,
    this.animate = true,
    this.shrink = false,
    this.background,
  });

  final double full;
  final double visible;
  final bool shrink;
  final Color? background;

  /// false iken (ör. kullanıcı ayracı sürüklerken) pencere parmağı anında
  /// izler.
  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final target = visible.clamp(0.0, full);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: animate ? const Duration(milliseconds: 260) : Duration.zero,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, shown, child) {
        final scale = full > 0 ? (shown / full).clamp(0.0, 1.0) : 1.0;
        Widget window = SizedBox(
          height: shown,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: full,
              maxHeight: full,
              // Ağaç yapısı ölçekten bağımsız (oynatıcının durumu korunsun):
              // shrink açıkken Transform her karede var, 1'de etkisiz.
              child: shrink
                  ? Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: child,
                    )
                  : child,
            ),
          ),
        );
        if (background case final color?) {
          window = ColoredBox(color: color, child: window);
        }
        return window;
      },
    );
  }
}
