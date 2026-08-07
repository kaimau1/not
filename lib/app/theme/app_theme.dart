import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/note_fonts.dart';

/// Premium sade görünüm: tek tohum renk, ince kenarlıklar, gölgesiz yüzeyler,
/// koyu temada siyaha yakın arka plan.
abstract final class AppTheme {
  static const Color seed = Color(0xFF4A5CCC);

  /// Kağıt temasının tohum rengi: sıcak sepya; saman kağıdı yüzeylerle uyumlu.
  static const Color paperSeed = Color(0xFF8A6C3C);

  /// Kurulmuş temalar (anahtar: parlaklık + kağıt + yazı tipi).
  ///
  /// KÖK NEDEN (kasma — "font değişince kasıyor"): `NotlarApp.build` her
  /// çalıştığında `theme:` ve `darkTheme:` için İKİ tam [ThemeData] sıfırdan
  /// kuruluyordu. Her biri bir `ColorScheme.fromSeed` (Material'ın HCT renk
  /// algoritması) ve bir `appFontTextTheme` (paketin on beş metin biçimini
  /// tek tek kuran çağrısı) demek; ölçülebilir birkaç milisaniye. Kök widget
  /// yalnız ayar değişince değil, yönlendirici/dil/tema kipi her
  /// kıpırdadığında da yeniden kurulduğu için bu bedel kare bütçesine
  /// giriyordu — ayarlardan yazı tipini değiştirmek gibi arka arkaya birkaç
  /// build üreten işlemlerde de gözle görülür takılma yapıyordu.
  ///
  /// Ayrıca ÖNEMLİ bir ikinci kazanç: aynı ayarlar için AYNI nesne dönüyor.
  /// `Theme.updateShouldNotify` temaları `==` ile karşılaştırır ve
  /// [ThemeData]'nın `==`'i yüzlerce alanı dolaşır; kimlik eşitliği bu
  /// karşılaştırmayı da bedavaya indirir ve tema değişmediğinde ağacın
  /// tamamının yeniden çizilmesini önler.
  ///
  /// Önbellek SINIRSIZ DEĞİL: katalogda 19 yazı tipi × 3 tema = en çok 57
  /// giriş, hepsi de kullanıcının gerçekten seçebildiği kombinasyonlar.
  static final Map<String, ThemeData> _cache = {};

  /// Testlerin (ve yazı tipi kataloğu değişirse çalışma anının) önbelleği
  /// boşaltabilmesi için.
  @visibleForTesting
  static void clearCache() => _cache.clear();

  /// [font] uygulamanın genel yazı tipi (Ayarlar → Görünüm → Yazı tipi);
  /// null ise varsayılan ([kAppDefaultFont]) kullanılır.
  static ThemeData light({String? font}) => _cached(Brightness.light, font);

  static ThemeData dark({String? font}) => _cached(Brightness.dark, font);

  /// "Kağıt" teması: açık temanın hafif saman kağıdı renkli sürümü.
  static ThemeData paper({String? font}) =>
      _cached(Brightness.light, font, paper: true);

  static ThemeData _cached(
    Brightness brightness,
    String? font, {
    bool paper = false,
  }) => _cache.putIfAbsent(
    '${brightness.name}|$paper|${font ?? ''}',
    () => _base(brightness, paper: paper, font: font),
  );

  static ThemeData _base(
    Brightness brightness, {
    bool paper = false,
    String? font,
  }) {
    final isDark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: paper ? paperSeed : seed,
      brightness: brightness,
    );
    if (paper) {
      // Hafif saman kağıdı tonları: sıcak, sarımsı krem yüzeyler.
      scheme = scheme.copyWith(
        surface: const Color(0xFFF5EDD8),
        surfaceContainerLowest: const Color(0xFFFBF5E6),
        surfaceContainerLow: const Color(0xFFF0E6CC),
        surfaceContainer: const Color(0xFFEBDFC2),
        surfaceContainerHigh: const Color(0xFFE4D6B4),
        surfaceContainerHighest: const Color(0xFFDCCDA7),
      );
    }
    if (isDark) {
      scheme = scheme.copyWith(
        surface: const Color(0xFF0E0E11),
        surfaceContainerLowest: const Color(0xFF0A0A0C),
        surfaceContainerLow: const Color(0xFF16161A),
        surfaceContainer: const Color(0xFF1A1A1F),
        surfaceContainerHigh: const Color(0xFF212127),
        surfaceContainerHighest: const Color(0xFF28282F),
      );
    }

    // Uygulamanın tipografisi: varsayılan Inter Tight, kullanıcı Ayarlar →
    // Görünüm → Yazı tipi'nden katalogdaki her yazı tipine geçebilir.
    // Dosyaların TAMAMI APK'ya GÖMÜLÜ (`assets/google_fonts/`), yani
    // `google_fonts` burada ağa hiç çıkmaz ve yazı tipi her telefonda AYNI
    // çizilir — indirme başarısız olduğunda cihazın sistem fontuna düşme
    // davranışı bitti (bkz. pubspec'teki gerekçe). Gömülü ağırlıklar 400 ve
    // 500: paketin gövde temasına yüklediği ağırlıklar bunlar, daha kalın
    // metinler bu iki yüzden türetiliyor.
    final textTheme = appFontTextTheme(
      ThemeData(brightness: brightness).textTheme,
      font,
    );

    final desktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: desktop ? VisualDensity.compact : VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        backgroundColor: scheme.surface,
        selectedColor: scheme.secondaryContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
