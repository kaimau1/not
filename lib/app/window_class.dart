import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// **Pencere sınıfı tek yerde** (F67.1, B11). Eskiden aynı pencere bir yerde
/// "tablet", başka yerde "telefon" sayılıyordu (600/640/840 dağınıktı; yatay
/// telefon 851×393 dp genişliğinden ötürü bölünmüş görünüm açıyordu — F66.7).
///
/// Bileşen İÇİ sığdırma eşikleri (bir kutunun kendi genişliği: 340, 400, 520…)
/// burada DEĞİL; bunlar pencereyi değil kutuyu ölçer.
enum WindowWidth {
  /// < 600
  compact,

  /// 600–839
  medium,

  /// 840–1199
  expanded,

  /// ≥ 1200
  large,
}

enum WindowHeight {
  /// < 480 (yatay telefon; klavyeli yatay tablet)
  short,

  /// 480–899
  regular,

  /// ≥ 900
  tall,
}

class WindowClass {
  const WindowClass(
    this.width,
    this.height,
    this.touchFirst, {
    this.compactDevice = false,
  });

  final WindowWidth width;
  final WindowHeight height;

  /// Web'de false (fare/klavye öncelikli), Android'de true.
  final bool touchFirst;

  /// CİHAZ telefon mu: dokunmatik ve EN KISA kenar < 600 — yatayda da telefon
  /// kalır (F66.7). Web'de hep false (tarayıcı penceresi genişliğiyle karar).
  final bool compactDevice;

  bool atLeast(WindowWidth w) => width.index >= w.index;

  static WindowClass of(BuildContext context) =>
      fromSize(MediaQuery.sizeOf(context), web: kIsWeb);

  static WindowClass fromSize(Size size, {required bool web}) {
    final w = size.width;
    final h = size.height;
    return WindowClass(
      w < 600
          ? WindowWidth.compact
          : w < 840
          ? WindowWidth.medium
          : w < 1200
          ? WindowWidth.expanded
          : WindowWidth.large,
      h < 480
          ? WindowHeight.short
          : h < 900
          ? WindowHeight.regular
          : WindowHeight.tall,
      !web,
      compactDevice: !web && size.shortestSide < 600,
    );
  }
}

/// Ana-detay düzenine geçiş genişliği — İÇERİK alanının genişliği (geniş
/// ekranda gezinme rayı düşülmüş hâli, bkz. AppFrame).
///
/// 900 → 840 (2026-09-22, geniş ekran tasarımı): Material 3'ün "geniş"
/// pencere sınıfı. Ray eklenince 1024 dp'lik yatay tabletin içerik alanı
/// ~940'a iniyor; 900 sınırı küçük tabletleri tek panele düşürme riskine
/// çok yakındı. 840'ta liste (260–380) + editör (≥ 360) hâlâ sığıyor. Dikey
/// tablet (~800) ve telefon tek panelde kalır.
const double kSplitBreakpoint = 840;

/// **NOT AÇIKKEN** ana-detay sınırı (kullanıcı isteği 2026-11-02: "tablet
/// modunda not açılınca direkt ekranı kapladı; soldaki dashboard en soldaki
/// menünün yerine gelsin, tek sütunluk olsun, menü gizlensin"). Not açıkken
/// ray çekmeceye döner (bkz. AppFrame) ve liste tek sütuna iner; dikey tablet
/// (~800 dp) ve açık katlanabilir (~670 dp) de listeyle notu yan yana
/// gösterebilir: 260 dp liste + ≥ 380 dp not.
const double kNoteSplitBreakpoint = 640;

/// **Dikey tablette liste çekmece gibi** (J3, F44.7): 800 dp'de liste + not
/// notu ~460 dp'ye indiriyordu. Bu genişliğin altında DİKEY pencerede not açılınca
/// liste kenara çekilir; ☰ geri getirir, başka nota geçince yine çekilir.
const double kPortraitListBreakpoint = 960;

/// Sabit ekin yan yerleşiminin açıldığı en dar editör genişliği (dp).
const double kPinnedSideMinWidth = 840;

/// Not sayfasının en geniş hâli (bkz. `_buildCanvas`) — geniş ekranda
/// satırlar okunur uzunlukta kalsın.
const double kReadingWidth = 760;

/// Liste kabuğun sol panelinde mi çizilecek? [window] kabuğun boyutu.
///
/// Not açık olsun olmasın aynı sınır (2026-11-02). Telefon CİHAZI yatayda da
/// bölünmez (F66.7: 851×393 dp'de bölünmüş görünüm açılıyordu).
bool splitActiveFor(Size window, {bool web = kIsWeb}) =>
    window.width >= kNoteSplitBreakpoint &&
    !WindowClass.fromSize(window, web: web).compactDevice;
