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

/// **WEB: GERİ → ANA SAYFA, İKİNCİ GERİ → SİTEDEN ÇIK** (kullanıcı isteği
/// 2026-09-26: "sitede geri ana sayfaya dönmeli, 2. geri siteden çıkmalı").
///
/// KÖK NEDEN: go_router her rota değişikliğini tarayıcıya YENİ bir geçmiş
/// kaydı olarak yazıyordu — açılan her not, her bölüm, hatta uygulama
/// içindeki her "geri" bile. Tarayıcının geri düğmesi bu kayıtları tek tek
/// geziyordu: on not açan kullanıcı siteden çıkmak için on kez geri
/// basıyor, arada daha önce kapattığı notlar yeniden açılıyordu.
///
/// Kural: uygulama geçmişte EN ÇOK İKİ kayıt tutar — ana sayfa ve üstünde
/// o an açık olan ekran.
/// * Ana sayfadan bir ekrana geçiş → yeni kayıt (tek sefer).
/// * Ekrandan ekrana geçiş → kaydın YERİNE yazılır (adres doğru kalır ama
///   geçmiş büyümez).
/// * Uygulama içinden ana sayfaya dönüş → tarayıcıda bir kayıt geri gidilir
///   (üstteki kayıt düşer; yoksa geri tuşu iki kez basılmak isterdi).
/// * Site doğrudan bir notun adresiyle açıldıysa ana sayfa kaydı ALTINA
///   eklenir: ilk geri yine ana sayfaya gelir.
/// * Tarayıcının kendi geri/ileri hareketi (adres zaten orada) yalnız
///   kaydedilir, geçmişe yazılmaz.
@visibleForTesting
class HomeFirstHistory {
  HomeFirstHistory(this.driver);

  final HistoryDriver driver;

  bool _started = false;
  Uri? _last;

  /// Ana sayfa kaydının ÜSTÜNDE bir kayıt var mı (bizim eklediğimiz).
  bool _above = false;

  /// Oturum açma ekranı da "ana sayfa" sayılır: ondan geri, siteden çıkış.
  static bool isHome(Uri uri) =>
      uri.path.isEmpty || uri.path == '/' || uri.path == '/login';

  static String _key(Uri uri) =>
      uri.path.isEmpty ? '/' : uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

  static bool _same(Uri a, Uri b) => _key(a) == _key(b);

  /// Yönlendiricinin bildirdiği yeni konum.
  void report(Uri uri, Object? state) {
    final shownRaw = driver.currentPath();
    final shown = shownRaw == null ? null : Uri.parse(shownRaw);
    if (!_started) {
      _started = true;
      _last = uri;
      if (isHome(uri)) {
        driver.update(uri, state, replace: true);
      } else {
        // Doğrudan bir ekranın adresiyle açıldı: altına ana sayfa.
        driver.update(Uri.parse('/'), null, replace: true);
        driver.update(uri, state, replace: false);
        _above = true;
      }
      return;
    }
    final last = _last!;
    if (_same(uri, last)) {
      // Konum aynı (ör. yönlendirme); adres çubuğu geride kaldıysa eşitle.
      if (shown != null && !_same(shown, uri)) {
        driver.update(uri, state, replace: true);
      }
      return;
    }
    _last = uri;
    if (shown != null && _same(shown, uri)) {
      // Tarayıcının kendi geri/ileri hareketi: kayıt zaten orada.
      _above = !isHome(uri);
      return;
    }
    if (isHome(uri)) {
      if (_above && !isHome(last)) {
        _above = false;
        driver.back();
      } else {
        driver.update(uri, state, replace: true);
      }
      return;
    }
    if (_above) {
      driver.update(uri, state, replace: true);
    } else {
      driver.update(uri, state, replace: false);
      _above = true;
    }
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
class HomeFirstRouteInformationProvider extends RouteInformationProvider {
  HomeFirstRouteInformationProvider(
    this._inner, {
    required this.location,
    HistoryDriver? driver,
  }) : _history = HomeFirstHistory(driver ?? browserHistoryDriver());

  final RouteInformationProvider _inner;

  /// Yönlendiricinin en üstteki konumu (bkz. sınıf açıklaması).
  final Uri Function() location;
  final HomeFirstHistory _history;

  @override
  RouteInformation get value => _inner.value;

  @override
  void addListener(VoidCallback listener) => _inner.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _inner.removeListener(listener);

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
