import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_history_driver_stub.dart'
    if (dart.library.js_interop) 'web_history_driver_web.dart'
    as platform;

/// Tarayıcı geçmişine dokunan işlemler — testte sahte bir geçmişle
/// değiştirilir (bkz. test/web_history_test.dart).
abstract class HistoryDriver {
  /// Tarayıcının ŞU AN gösterdiği yol (+ sorgu); bilinmiyorsa null.
  String? currentPath();

  /// Adres çubuğunu [uri] yapar: [replace] ise geçerli kaydın yerine,
  /// değilse yeni bir kayıt olarak.
  void update(Uri uri, Object? state, {required bool replace});

  /// Tarayıcıda bir kayıt geri gider (`history.back()`).
  void back();
}

/// Web'de gerçek tarayıcı geçmişini süren sürücü.
HistoryDriver browserHistoryDriver() => platform.createDriver();

/// **WEB: TARAYICININ GERİ TUŞU = UYGULAMANIN GERİ TUŞU** (kullanıcı
/// isteği 2026-11-20: "web'de menülerde geriye bastığım zaman direkt
/// tamamen geri yapılıyor ve siteden çıkıyor; tüm geri işlevleri kontrol
/// edilmeli").
///
/// KÖK NEDEN: eski kural (2026-09-26, "geri ana sayfaya, ikinci geri siteden
/// çıksın") geçmişte en çok iki kayıt tutuyordu — ana sayfa ve açık ekran.
/// Tarayıcı geri gidince go_router doğrudan o ADRESE gidiyordu: açık menü,
/// iletişim kutusu, alt levha ya da panel (Android'de geri tuşunun önce
/// kapattığı şeyler) hiç sorulmuyordu. Notta menü açıkken geri notu, ana
/// sayfada menü açıkken geri SİTEYİ kapatıyordu.
///
/// Kural: geçmişte uygulamanın iki kaydı durur — TABAN ve üstünde aynı
/// adresli BEKÇİ. Tarayıcının geri tuşu bekçiyi düşürür; bu olay
/// yönlendiriciye GİTMEZ, Android geri tuşunun yolundan geçer ([onBack] =
/// kök `backButtonDispatcher`: önce menü/kutu/levha, sonra `BackCloses`
/// paneli, sonra ekranın kendi kipi, sonra ekran). İşlendiyse bekçi geri
/// konur. İşlenmediyse (kapatılacak bir şey yok):
/// * ana sayfa dışındaysak (site bir notun adresiyle açıldı) ana sayfaya
///   gidilir ([goHome]) — ilk geri yine ana sayfaya gelir;
/// * ana sayfadaysak tabandan da geri gidilir: siteden çıkılır.
/// Konum değişiklikleri (not açma, ekrandan ekrana) en üstteki kaydın
/// YERİNE yazılır: geçmiş büyümez, adres çubuğu doğru kalır.
@visibleForTesting
class HomeFirstHistory {
  HomeFirstHistory(this.driver, {this.onBack, this.goHome});

  final HistoryDriver driver;

  /// Uygulama içi geri (Android geri tuşuyla aynı yol); true = işlendi.
  Future<bool> Function()? onBack;

  /// Kapatılacak bir şey kalmadığında ana sayfaya dönüş.
  void Function()? goHome;

  bool _started = false;
  Uri? _last;
  Object? _lastState;

  /// Taban kaydının üstünde bekçi var mı.
  bool _guard = false;

  /// Bir geri olayı işleniyor (bekçi henüz geri konmadı).
  bool _busy = false;

  /// Siteden çıkış için tarayıcıda geri gidildi.
  bool _leaving = false;

  /// Oturum açma ekranı da "ana sayfa" sayılır: ondan geri, siteden çıkış.
  static bool isHome(Uri uri) =>
      uri.path.isEmpty || uri.path == '/' || uri.path == '/login';

  void _pushGuard() {
    final uri = _last;
    if (uri == null) return;
    driver.update(uri, _lastState, replace: false);
    _guard = true;
  }

  /// Yönlendiricinin bildirdiği yeni konum.
  void report(Uri uri, Object? state) {
    _last = uri;
    _lastState = state;
    if (!_started) {
      _started = true;
      driver.update(uri, state, replace: true);
      _pushGuard();
      return;
    }
    if (_leaving) return;
    // En üstteki kaydın (bekçi ya da işlem sürerken taban) yerine yazılır.
    driver.update(uri, state, replace: true);
    if (!_guard && !_busy) _pushGuard();
  }

  /// Tarayıcı geçmişte gezindi (geri ya da ileri). true = olay burada
  /// işlendi, yönlendirici adrese GİTMEMELİ.
  bool browserNavigated(Uri uri) {
    if (!_started) return false;
    if (_leaving) return true;
    if (!_guard) {
      // Bekçisiz iken gelen hareket: eski bir bekçiye İLERİ gidildi (ya da
      // işlem sürerken ikinci geri). Konum değişmez, bekçi yerinde sayılır.
      if (!_busy) _guard = true;
      return true;
    }
    _guard = false;
    _busy = true;
    unawaited(_handleBack());
    return true;
  }

  Future<void> _handleBack() async {
    var handled = false;
    try {
      handled = await (onBack?.call() ?? Future<bool>.value(false));
    } catch (_) {
      handled = false;
    }
    final last = _last;
    if (!handled && last != null && !isHome(last) && goHome != null) {
      goHome!();
      handled = true;
    }
    _busy = false;
    if (handled) {
      _pushGuard();
      return;
    }
    // Kapatılacak bir şey yok, ana sayfadayız: siteden çık. Önceki sayfa
    // yoksa (sekmenin ilk sayfası) tarayıcı yerinde kalır; bekçi kısa
    // süre sonra yeniden konur ki sonraki geri de çalışsın.
    _leaving = true;
    driver.back();
    Timer(const Duration(milliseconds: 600), () {
      if (!_leaving) return;
      _leaving = false;
      if (!_guard) _pushGuard();
    });
  }
}

/// go_router'ın konum sağlayıcısını sarar: konum ve dinleyiciler olduğu
/// gibi geçer, yalnız TARAYICIYA RAPOR [HomeFirstHistory] kuralıyla yazılır.
/// Yalnız web'de kurulur (bkz. app.dart).
///
/// [location] yönlendiricinin EN ÜSTTEKİ konumunu vermeli (`router.state.uri`).
/// TUZAK (tarayıcıda ölçüldü): go_router'ın bildirdiği `RouteInformation.uri`
/// push'ları GÖRMEZ — not açıkken bile "/" der, yalnız `state` değişir. Eski
/// davranışta tarayıcıya giden de buydu: her push/pop adresi "/" olan YENİ bir
/// kayıt açıyordu, geri tuşu bu görünmez kayıtları tek tek geziyordu.
class HomeFirstRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver {
  HomeFirstRouteInformationProvider(
    this._inner, {
    required this.location,
    Future<bool> Function()? onBack,
    void Function()? goHome,
    HistoryDriver? driver,
  }) : _history = HomeFirstHistory(
         driver ?? browserHistoryDriver(),
         onBack: onBack,
         goHome: goHome,
       );

  final RouteInformationProvider _inner;

  /// Yönlendiricinin en üstteki konumu (bkz. sınıf açıklaması).
  final Uri Function() location;
  final HomeFirstHistory _history;
  int _listeners = 0;

  @override
  RouteInformation get value => _inner.value;

  /// Tarayıcının geri/ileri olayını go_router'dan ÖNCE görmek için gözlemci
  /// içteki sağlayıcıdan önce kaydolur (o da ilk dinleyicide kaydolur;
  /// `WidgetsBinding` olayı ilk `true` dönen gözlemcide keser).
  @override
  void addListener(VoidCallback listener) {
    if (_listeners++ == 0) WidgetsBinding.instance.addObserver(this);
    _inner.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _inner.removeListener(listener);
    if (--_listeners == 0) WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(_history.browserNavigated(routeInformation.uri));

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    Uri uri;
    try {
      uri = location();
    } catch (_) {
      // Eşleşme yoksa (hata sayfası) bildirilen adrese düş.
      uri = routeInformation.uri;
    }
    _history.report(uri, routeInformation.state);
  }
}
