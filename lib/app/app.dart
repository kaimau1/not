import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/l10n_ext.dart';
import '../core/widgets/undo_snackbar.dart';
import '../features/settings/settings_providers.dart';
import 'router.dart';
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
/// 3. **Yazı tipi**: cihazın sistem fontuna hiç düşülmemesi için Inter Tight
///    APK'ya gömüldü (bkz. pubspec `assets/google_fonts/`).
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

class NotlarApp extends ConsumerWidget {
  const NotlarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(effectiveThemeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final paper = ref.watch(themeChoiceProvider) == AppThemeChoice.paper;

    return MaterialApp.router(
      title: 'Notlar',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      theme: paper ? AppTheme.paper() : AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
        return fixedTypography(
          context,
          child ?? const SizedBox.shrink(),
          fontScale,
        );
      },
    );
  }
}
