import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/widgets/focus_ring.dart';
import '../core/app_update.dart';
import 'release_notes_toast.dart';
import '../core/l10n_ext.dart';
import '../core/widgets/customizable.dart';
import '../core/widgets/undo_snackbar.dart';
import '../features/settings/presentation/app_lock.dart';
import '../features/notes/presentation/note_write_issues.dart';
import '../features/settings/settings_providers.dart';
import 'app_services.dart';
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
///    sahibi. İLK AÇILIŞTA başlangıç değeri sistem ölçeğinin en yakın
///    kademesidir (F4.7 — büyük yazı kullanan kişi küçük yazıyla
///    karşılanmasın); sonrası uygulama ayarı.
/// 2. **Kalın metin** (erişilebilirlik → "Bold text"): açık bırakılsa
///    telefonun her yerinde yazılar kalınlaşır ve ince/kalın ayrımına dayanan
///    başlık-gövde hiyerarşisi düzleşirdi.
/// 3. **Yazı tipi**: cihazın sistem fontuna hiç düşülmemesi için yazı tipi
///    kataloğunun tamamı APK'ya gömüldü (bkz. pubspec `assets/google_fonts/`);
///    hangisinin kullanılacağı Ayarlar → Görünüm → Yazı tipi'nden seçilir.
///
/// Android'in "Ekran boyutu" (yoğunluk) ayarı KAPSAM DIŞI: o metni değil tüm
/// arayüzü ölçekler, uygulamadan bastırılamaz.
///
/// **İSTİSNA — "Sistem yazı boyutunu izle"** (F15.1, erişilebilirlik;
/// varsayılan KAPALI, yani yukarıdaki kural varsayılanda aynen geçerli):
/// [followSystem] açıkken uygulamanın kademesi sistem ölçeğiyle ÇARPILIR ve
/// sistemin kalın metin ayarı geçer. Çarpım [maxFollowedTextScale]'de durur:
/// "Çok büyük" kademe × sistemin en büyüğü (2×) 2,7 eder, o boyda çubuklar ve
/// kartlar okunmaz olur; 2× Android'in kendi üst sınırı.
Widget fixedTypography(
  BuildContext context,
  Widget child,
  double fontScale, {
  bool followSystem = false,
}) => _FixedTypography(
  fontScale: fontScale,
  followSystem: followSystem,
  child: child,
);

/// [fixedTypography]'nin kendi öğesi. **MediaQuery bağımlılığı BURADA**
/// (ölçüm 2026-11-10): `MediaQuery.of` doğrudan MaterialApp.builder'ın
/// bağlamında okunuyordu — klavye animasyonunun HER KARESİNDE (viewInsets
/// değişir) builder yeniden koşup AppLockGate → … → AppServices zincirini
/// baştan kuruyordu. Artık yalnız bu küçük öğe yeniden kurulur; [child]
/// aynı örnek kalır.
class _FixedTypography extends StatelessWidget {
  const _FixedTypography({
    required this.fontScale,
    required this.followSystem,
    required this.child,
  });

  final double fontScale;
  final bool followSystem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final system = MediaQuery.of(context);
    final scale = followSystem
        ? (fontScale * system.textScaler.scale(14) / 14).clamp(
            0.5,
            maxFollowedTextScale,
          )
        : fontScale;
    return MediaQuery(
      data: system.copyWith(
        textScaler: TextScaler.linear(scale),
        boldText: followSystem && system.boldText,
      ),
      child: child,
    );
  }
}

/// "Sistem yazı boyutunu izle" açıkken toplam yazı ölçeğinin üst sınırı.
const double maxFollowedTextScale = 2.0;

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
/// (bkz. test/shared_notes_back_test.dart).
///
/// Çözüm: platforma hep "çerçeve karşılar" denir. Gerçekten geri alacak bir
/// şey yoksa yönlendirici `popRoute`'ta false döner ve Flutter kendisi
/// `SystemNavigator.pop()` çağırır — ana ekrandan çıkış eskisi gibi çalışır.
/// Web'de varsayılan kalır (tarayıcı geçmişi ayrı yönetiliyor).
///
/// F22.7 (K4): değer hep `true` — her gezinme bildiriminde (her rota
/// değişimi, her `PopScope` güncellemesi) platform kanalına aynı çağrıyı
/// yazmak ana iş parçacığını boşuna bekletiyordu (Flutter 3.47'de Dart UI =
/// Android ana iş parçacığı). Bir kez yazılır; motor ayrılınca (`detached`,
/// Activity yeniden kurulabilir) unutulur ve sonraki bildirimde yine yazılır.
bool alwaysHandleBack(NavigationNotification notification) {
  final state = WidgetsBinding.instance.lifecycleState;
  // Varsayılanla aynı: motor hazır değilken platforma yazılmaz.
  if (state == null || state == AppLifecycleState.detached) {
    _handlesBackSent = false;
    return true;
  }
  if (_handlesBackSent) return true;
  _handlesBackSent = true;
  _handlesBackReset ??= AppLifecycleListener(
    onDetach: () => _handlesBackSent = false,
  );
  SystemNavigator.setFrameworkHandlesBack(true);
  return true;
}

bool _handlesBackSent = false;
AppLifecycleListener? _handlesBackReset;

/// Testler için: bir sonraki bildirimde kanal çağrısı yeniden yazılsın.
@visibleForTesting
void resetAlwaysHandleBackCache() => _handlesBackSent = false;

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
    final followSystemText = ref.watch(followSystemTextScaleProvider);
    final font = ref.watch(appFontProvider);
    final choice = ref.watch(themeChoiceProvider);

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
      // ESC = GERİ (kullanıcı isteği 2026-11-08, web ve tablet): kapatılabilir
      // açılır pencere/levha/menü rotası kapanır, sayfada sistem geri
      // tuşunun yolu ([EscBackAction]). DismissIntent'e bağlanmadı: metin
      // alanı odaktayken EditableText onu sayfa rotasının devre dışı
      // eyleminde durduruyordu (Esc hiçbir şey yapmıyordu).
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): const EscBackIntent(),
      },
      actions: {...WidgetsApp.defaultActions, EscBackIntent: EscBackAction()},
      // Koyu kip (Koyu seçimi, sistem ya da gece zamanlaması) seçili ailenin
      // KENDİ koyu hâlini kullanır.
      theme: AppTheme.of(choice.family, Brightness.light, font: font),
      darkTheme: AppTheme.of(choice.family, Brightness.dark, font: font),
      themeMode: themeMode,
      // ÖLÇÜLDÜ (TEMA_PLANI F34.3, v1.1.669): varsayılan 200 ms geçiş her karede
      // `ThemeData.lerp` + tam ağaç, telefonda kare başına 50–66 ms, dört
      // kareye düşüyordu (hedef < 12 ms). Tek keskin kare daha iyi.
      themeAnimationDuration: Duration.zero,
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
            // Durum çubuğu da saydam, altında ekranın zemini (F30.6). AppBar'lı
            // ekranda AppBar kendi zeminine göre seçer; bu, AppBar'sız ana ekran.
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
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
            // Uygulama kilidi (F18.6, varsayılan kapalı) her şeyin üstünde.
            // Klavye odak halkası (F80.3) gezginin, levhaların ve
            // pencerelerin ÜSTÜNDE boyanır; dokunmatikte çizilmez.
            KeyboardFocusRing(
              child: AppLockGate(
              child: CustomizeModeHost(
              // Eski istemci kapısı (F1.5): `config/app.minClient` bu
              // sürümün veri sürümünü aştıysa tepede "güncelle" şeridi.
              child: UpdateRequiredBanner(
                // Not yazım sorunları (F1.6: 1 MiB sınırı / sunucu reddi).
                child: NoteWriteIssueListener(
                  // Oturum servisleri (F2.4) — ana ekranın build'inden çıktı.
                  child: AppUpdateRunner(
                    child: ReleaseNotesToast(
                      child: AppServices(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
            ),
            fontScale,
            followSystem: followSystemText,
          ),
        );
      },
    );
  }
}

/// Esc tuşu (bkz. [EscBackAction]).
class EscBackIntent extends Intent {
  const EscBackIntent();
}

/// Esc'in en üst düzey karşılığı: açılır rota (diyalog, levha, menü) varsa
/// onu kapatır; yoksa geri tuşu gibi davranır — kök yönlendiricinin geri
/// dağıtıcısı (PopScope, BackButtonListener, iç içe gezginler sırasıyla);
/// yönlendirici yoksa en yakın gezgin.
class EscBackAction extends ContextAction<EscBackIntent> {
  @override
  Object? invoke(EscBackIntent intent, [BuildContext? context]) {
    final ctx = context ?? primaryFocus?.context;
    if (ctx == null || !ctx.mounted) return null;
    final route = ModalRoute.of(ctx);
    if (route is PopupRoute) {
      unawaited(Navigator.of(ctx).maybePop());
      return null;
    }
    final dispatcher = Router.maybeOf(ctx)?.backButtonDispatcher;
    if (dispatcher != null) {
      unawaited(dispatcher.invokeCallback(Future<bool>.value(false)));
    } else {
      unawaited(Navigator.maybeOf(ctx)?.maybePop());
    }
    return null;
  }
}
