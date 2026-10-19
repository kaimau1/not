
import 'package:flutter/material.dart';

import '../../core/utils/note_fonts.dart';
import 'page_transitions.dart';

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
      // Kağıt tonu: SARI-GRİ arası, ılık ama doygun olmayan yüzeyler.
      //
      // Sarı YARIYA İNDİRİLDİ (kullanıcı isteği 2026-08-10: "kağıt tonunun
      // sarısını biraz azalt, çok sarı; hafif grileşebilir, sarı gri arası").
      // Eski küme saman kağıdıydı — en koyu yüzeyde kırmızı ile mavi kanal
      // arasındaki fark 53 birimdi (0xFFDCCDA7), yani belirgin sarı. Kanal
      // farkı yarıya indirilip parlaklık korunarak ton griye çekildi: kağıt
      // hissi (yüzeyler hâlâ sıcak tarafta) kalır, sarılık göze batmaz.
      scheme = scheme.copyWith(
        surface: const Color(0xFFF3EFE3),
        surfaceContainerLowest: const Color(0xFFFAF7EF),
        surfaceContainerLow: const Color(0xFFEDE8DA),
        surfaceContainer: const Color(0xFFE7E1D1),
        surfaceContainerHigh: const Color(0xFFDFD9C7),
        surfaceContainerHighest: const Color(0xFFD6CFBB),
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

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      // METİN SEÇİMİ (kullanıcı bulgusu 2026-10-15: "metin seçim kalitesi
      // düzeltilmeli"). M3 varsayılanı seçimi birincil rengin %40'ıyla
      // boyuyordu; kâğıt temasının koyu kahvesinde seçili kelime yazının
      // üstüne basılmış koyu bir blok gibi duruyor, harfler zor okunuyordu.
      // Daha açık bir zemin seçimi gösterir ama yazıyı örtmez; tutamaçlar ve
      // imleç birincil renkte kalır (nerede tutulacağı belli olsun).
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(
          alpha: brightness == Brightness.dark ? 0.38 : 0.24,
        ),
        selectionHandleColor: scheme.primary,
      ),
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
      // EKRAN GEÇİŞLERİ iPhone gibi yandan kayar (bkz. page_transitions.dart).
      // Web'de tarayıcının bildirdiği platforma göre seçilir: masaüstü
      // tarayıcıda (Windows/Linux/Mac) solma kalır, pencere içi geçiş kaymaz.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
