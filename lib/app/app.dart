import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_update.dart';
import '../core/l10n_ext.dart';
import '../core/widgets/customizable.dart';
import '../core/widgets/undo_snackbar.dart';
import '../features/notes/presentation/note_write_issues.dart';
import '../features/settings/settings_providers.dart';
import 'router.dart';
import 'web_history.dart';
import 'theme/app_theme.dart';

/// Sistem dil listesinden uygulamanın dilini seçer; hiçbiri tutmazsa
/// AÇIKÇA Türkçe'ye düşer.
///
/// Flutter'ın varsayılanı eşleşme yoksa `supportedLocales.first`tir; o liste
/// ise `gen-l10n` tarafından ALFABETİK üretiliyor (de, en, es, tr). Yani
/// Almanca eklendiği anda, sistemi ör. Fransızca olan bir kullanıcı uygulamayı
/// Almanca görürdü — dil eklemenin sessiz yan etkisi. Sıradaki dil (Arapça)
/// eklenince de bu kural değişmemeli.
Locale resolveLocale(List<Locale>? locales, Iterable<Locale> supported) {
  for (final locale in locales ?? const <Locale>[]) {
    for (final option in supported) {
      if (option.languageCode == locale.languageCode) return option;
    }
  }
  return const Locale('tr');
}

/// TİPOGRAFİ CİHAZDAN BAĞIMSIZ (kullanıcı, 2026-08-07: "yazı boyutu ve
/// fontumuz tüm telefonlarda sabit olmalı sadece uygulama içerisinden
/// değiştirilebilmeli"). Sistemin yazı ayarları uygulamanınkiyle DEĞİŞTİRİLİR:
///
/// 1. **Yazı boyutu**: `TextScaler.linear(fontScale)` sistem ölçeğiyle
///    ÇARPMAZ, onun YERİNE geçer — Ayarlar → Görünüm → Yazı boyutu tek söz
///    sahibi. (Bu zaten böyleydi; kural artık yazılı ve testli.)
/// 2. **Kalın metin** (erişilebilirlik → "Bold text"): açık bırakılsa
///    telefonun her yerinde yazılar kalınlaşır ve ince/kalın ayrımına dayanan
///    başlık-gövde hiyerarşisi düzleşirdi.
/// 3. **Yazı tipi**: cihazın sistem fontuna hiç düşülmemesi için yazı tipi
///    kataloğunun tamamı APK'ya gömüldü (bkz. pubspec `assets/google_fonts/`);
///    hangisinin kullanılacağı Ayarlar → Görünüm → Yazı tipi'nden seçilir.
///
/// Android'in "Ekran boyutu" (yoğunluk) ayarı KAPSAM DIŞI: o metni değil tüm
/// arayüzü ölçekler, uygulamadan bastırılamaz.
Widget fixedTypography(BuildContext context, Widget child, double fontScale) =>
    MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(fontScale), boldText: false),
      child: child,
    );

/// **GERİ TUŞU HER ZAMAN ÇERÇEVEYE** (kullanıcı bulgusu 2026-10-17:
/// "paylaşılanlar sayfasından geri gidince uygulama kapanıyor").
///
/// KÖK NEDEN: Android'e "geri tuşunu Flutter mı karşılayacak"
/// (`setFrameworkHandlesBack`) bilgisi, geçmişi EN SON değişen Navigator'ın
/// bildiriminden gidiyor. Klasör/Benimle paylaşılanlar sayfası kabuğun İÇ
/// Navigator'ına sayfasız rota olarak açılıyor; oradan açılan not DIŞ
/// kabuğa biniyor. Not kapanınca dış Navigator "geri alacak bir şeyim yok"
/// (false) bildiriyor ve bu, iç Navigator'daki sayfasız rotayı görmeden
/// platforma ulaşıyor → FlutterFragmentActivity geri geri çağrısını kapatıyor,
/// sonraki geri tuşu Activity'yi bitiriyor: uygulama kapanıyor
/// (bkz. test/requests_2026_10_17_d_test.dart).
///
/// Çözüm: platforma hep "çerçeve karşılar" denir. Gerçekten geri alacak bir
/// şey yoksa yönlendirici `popRoute`'ta false döner ve Flutter kendisi
/// `SystemNavigator.pop()` çağırır — ana ekrandan çıkış eskisi gibi çalışır.
/// Web'de varsayılan kalır (tarayıcı geçmişi ayrı yönetiliyor).
bool alwaysHandleBack(NavigationNotification notification) {
  final state = WidgetsBinding.instance.lifecycleState;
  // Varsayılanla aynı: motor hazır değilken platforma yazılmaz.
  if (state == null || state == AppLifecycleState.detached) return true;
  SystemNavigator.setFrameworkHandlesBack(true);
  return true;
}

/// Web'de tarayıcı geçmişini "önce ana sayfa, sonra çıkış" kuralıyla yazan
/// konum sağlayıcısı (bkz. [HomeFirstRouteInformationProvider]). Yönlendirici
/// başına TEK örnek: her build'de yenisi kurulsa geçmiş durumu sıfırlanırdı.
final _webRouteInfoProvider = Provider<RouteInformationProvider?>((ref) {
  if (!kIsWeb) return null;
  final router = ref.watch(routerProvider);
  return HomeFirstRouteInformationProvider(
    router.routeInformationProvider,
    // EN ÜSTTEKİ eşleşme — push'lanmış not dahil (bkz. currentLocation).
    location: () => router.state.uri,
  );
});

class NotlarApp extends ConsumerWidget {
  const NotlarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final webInfo = ref.watch(_webRouteInfoProvider);
    final themeMode = ref.watch(effectiveThemeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final font = ref.watch(appFontProvider);
    final paper = ref.watch(themeChoiceProvider) == AppThemeChoice.paper;

    return MaterialApp.router(
      title: 'Notlar',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      // Web: go_router'ın parçaları AYRI verilir ki tarayıcı geçmişine
      // yazan sağlayıcı sarılabilsin; öbür platformlarda olduğu gibi.
      routerConfig: webInfo == null ? router : null,
      routeInformationProvider: webInfo,
      routeInformationParser: webInfo == null
          ? null
          : router.routeInformationParser,
      routerDelegate: webInfo == null ? null : router.routerDelegate,
      backButtonDispatcher: webInfo == null
          ? null
          : router.backButtonDispatcher,
      onNavigationNotification: kIsWeb ? null : alwaysHandleBack,
      theme: paper ? AppTheme.paper(font: font) : AppTheme.light(font: font),
      darkTheme: AppTheme.dark(font: font),
      themeMode: themeMode,
      // null = sistem dilini kullan. Ayarlar'dan elle seçilirse o dil sabitlenir.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: resolveLocale,
      builder: (context, child) {
        // Tarihlerin dili tek yerden kurulur. Eskiden her çağrı yerinde
        // `DateFormat('d MMM', 'tr')` yazılıydı: uygulama İngilizce'ye
        // alınsa bile tarihler Türkçe kalıyordu (ve 'tr' sembolleri o dilde
        // yüklü olmadığından biçimlendirici sessizce en_US'e düşüyordu).
        // Etkin yerel ayarı kullanmak güvenli: `flutter_localizations` o
        // dilin tarih sembollerini zaten yüklüyor, ayrıca bir başlatma
        // (initializeDateFormatting) gerekmiyor.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        // **SİSTEM GEZİNME ÇUBUĞU** (kullanıcı bulgusu 2026-09-23, ekran
        // görüntüsü: editörün alt çubuğunun altında beyaz bir şerit).
        // KÖK NEDEN: uygulama ekranı kenardan kenara çiziyor ama gezinme
        // çubuğu için hiçbir stil vermiyordu. Android, üç tuşlu gezinmede
        // okunurluk için çubuğa kendiliğinden yarı saydam BEYAZ bir perde
        // koyuyor ("contrast enforced") — kâğıt renkli notun dibinde ekranın
        // bir parçası kopmuş gibi duruyordu, koyu temada da parlıyordu.
        // Perde kapatılır, çubuk saydam olur ve altındaki sayfa (notun
        // rengi) görünür; tuş simgeleri temaya göre açık/koyu seçilir.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: fixedTypography(
            context,
            // DÜZENLEME MODU şeridi bütün ekranların üstünde (bkz.
            // customizable.dart) — mod kapalıyken ağaca hiçbir şey eklemez.
            CustomizeModeHost(
              // Eski istemci kapısı (F1.5): `config/app.minClient` bu
              // sürümün veri sürümünü aştıysa tepede "güncelle" şeridi.
              child: UpdateRequiredBanner(
                // Not yazım sorunları (F1.6: 1 MiB sınırı / sunucu reddi).
                child: NoteWriteIssueListener(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
            fontScale,
          ),
        );
      },
    );
  }
}
