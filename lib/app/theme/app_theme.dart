import 'package:flutter/material.dart';

import '../../core/utils/note_fonts.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'page_transitions.dart';

/// Uygulamanın teması: üç aile (bkz. [ThemeFamily] — "masa ve kâğıt"), her
/// birinin açık ve koyu hâli. Renkler [FamilyPalettes]'ten, şemada karşılığı
/// olmayanlar [AppTokens]'tan.
///
/// Eski "kırık beyaz", "kağıt" ve "beyaz" temaları kalktı (TEMA_PLANI K2,
/// 2026-11-04); kayıtlı seçimler `ThemeChoiceNotifier`'da yeni ailelere
/// eşlenir.
abstract final class AppTheme {
  /// Kurulmuş temalar (anahtar: aile + parlaklık + yazı tipi).
  ///
  /// KÖK NEDEN (kasma — "font değişince kasıyor"): `NotlarApp.build` her
  /// çalıştığında `theme:` ve `darkTheme:` için İKİ tam [ThemeData] sıfırdan
  /// kuruluyordu. Her biri bir `ColorScheme.fromSeed` (Material'ın HCT renk
  /// algoritması) ve bir `appFontTextTheme` (paketin on beş metin biçimini
  /// tek tek kuran çağrısı) demek; ölçülebilir birkaç milisaniye. Kök widget
  /// yalnız ayar değişince değil, yönlendirici/dil/tema kipi her
  /// kıpırdadığında da yeniden kurulduğu için bu bedel kare bütçesine
  /// giriyordu.
  ///
  /// Ayrıca aynı ayarlar için AYNI nesne dönüyor: `Theme.updateShouldNotify`
  /// temaları `==` ile karşılaştırır ve [ThemeData]'nın `==`'i yüzlerce alanı
  /// dolaşır; kimlik eşitliği bu karşılaştırmayı bedavaya indirir. Okunurluk
  /// düzeltmesi (bkz. `NoteInkScope`) zıt temayı da buradan alır — not
  /// başına yeni tema kurulmaz.
  ///
  /// Önbellek SINIRSIZ DEĞİL: 19 yazı tipi × 3 aile × 2 parlaklık = en çok
  /// 114 giriş, hepsi kullanıcının gerçekten seçebildiği kombinasyonlar.
  static final Map<String, ThemeData> _cache = {};

  /// Testlerin (ve yazı tipi kataloğu değişirse çalışma anının) önbelleği
  /// boşaltabilmesi için.
  @visibleForTesting
  static void clearCache() => _cache.clear();

  /// Varsayılan ailenin (Adaçayı) açık hâli. [font] uygulamanın genel yazı
  /// tipi (Ayarlar → Görünüm → Yazı tipi); null ise varsayılan.
  static ThemeData light({String? font}) =>
      of(ThemeFamily.sage, Brightness.light, font: font);

  static ThemeData dark({String? font}) =>
      of(ThemeFamily.sage, Brightness.dark, font: font);

  static ThemeData of(
    ThemeFamily family,
    Brightness brightness, {
    String? font,
  }) => _cache.putIfAbsent(
    '${family.name}|${brightness.name}|${font ?? ''}',
    () => _base(family, brightness, font),
  );

  /// [theme] ile aynı aile ve yazı tipinde, ZIT parlaklıktaki tema: açık
  /// temada koyu bir not zemini (ya da tersi) seçilince notun içi bu temayla
  /// çizilir — yazı, simge, imleç ve kutucuklar zemine göre okunur kalır.
  static ThemeData opposite(ThemeData theme) {
    final tokens = AppTokens.fromTheme(theme);
    return of(
      tokens.family,
      theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      font: tokens.font,
    );
  }

  static ThemeData _base(
    ThemeFamily family,
    Brightness brightness,
    String? font,
  ) {
    final isDark = brightness == Brightness.dark;
    final t = FamilyPalettes.of(family, brightness);
    // fromSeed yalnız hata rolleri ve gölge/karartma için; diğer her rol
    // ailenin elle verilmiş değeri.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: t.primary,
          brightness: brightness,
        ).copyWith(
          primary: t.primary,
          onPrimary: t.onPrimary,
          primaryContainer: t.primaryContainer,
          onPrimaryContainer: t.onPrimaryContainer,
          secondary: t.secondary,
          onSecondary: t.onSecondary,
          secondaryContainer: t.secondaryContainer,
          onSecondaryContainer: t.onSecondaryContainer,
          tertiary: t.tertiary,
          onTertiary: t.onTertiary,
          tertiaryContainer: t.tertiaryContainer,
          onTertiaryContainer: t.onTertiaryContainer,
          surface: t.ground,
          onSurface: t.ink,
          onSurfaceVariant: t.muted,
          surfaceContainerLowest: t.lowest,
          // KATMAN SIRASI (masa ve kâğıt): açık temada Low/Container zeminden
          // AÇIK (kart dili: liste satırı, giriş kutusu, alt levha kâğıt
          // gibi durur), High/Highest zeminden koyu (seçili, basılı, iskelet).
          surfaceContainerLow: isDark ? t.card : t.sheet,
          surfaceContainer: t.field,
          surfaceContainerHigh: t.high,
          surfaceContainerHighest: t.highest,
          surfaceTint: Colors.transparent,
          outline: t.outline,
          outlineVariant: t.hair,
          inverseSurface: t.inverse,
          onInverseSurface: t.onInverse,
          inversePrimary: t.inversePrimary,
          shadow: t.ink,
          scrim: isDark ? Colors.black : t.ink,
        );
    final tokens = AppTokens(
      family: family,
      font: font,
      card: t.card,
      hairline: t.ink.withValues(alpha: isDark ? 0.10 : 0.08),
      cardShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.32)
              : t.ink.withValues(alpha: 0.07),
          offset: const Offset(0, 1),
        ),
      ],
      cardRadius: 16,
    );

    // Uygulamanın tipografisi: varsayılan Inter Tight, kullanıcı Ayarlar →
    // Görünüm → Yazı tipi'nden katalogdaki her yazı tipine geçebilir.
    // Dosyaların TAMAMI APK'ya GÖMÜLÜ (`assets/google_fonts/`), yani
    // `google_fonts` burada ağa hiç çıkmaz ve yazı tipi her telefonda AYNI
    // çizilir.
    final textTheme = appFontTextTheme(
      ThemeData(brightness: brightness).textTheme,
      font,
    ).apply(bodyColor: t.ink, displayColor: t.ink);

    final sheetShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: textTheme,
      extensions: [tokens],
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      // METİN SEÇİMİ (kullanıcı bulgusu 2026-10-15: "metin seçim kalitesi
      // düzeltilmeli"). M3 varsayılanı seçimi birincil rengin %40'ıyla
      // boyuyordu; seçili kelime yazının üstüne basılmış koyu bir blok gibi
      // duruyordu. Daha açık bir zemin seçimi gösterir ama yazıyı örtmez.
      textSelectionTheme: TextSelectionThemeData(
        // İmleç yazı rengiyle (kullanıcı bulgusu 2026-11-12: webde imleç açık
        // kalıp renkli notta görünmüyordu); onSurface zeminde hep okunur.
        cursorColor: scheme.onSurface,
        selectionColor: scheme.primary.withValues(alpha: isDark ? 0.38 : 0.24),
        selectionHandleColor: scheme.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      // ÇİP: seçili = vurgunun açık tonu (bugüne dek zeminle neredeyse aynı
      // renkteydi), seçisiz = şeffaf + ince çizgi.
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.9)),
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        showCheckmark: false,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? t.field : t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(isDark ? t.field : t.card),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
      // EKLE DÜĞMESİ vurgunun kendisi (eskiden açık bej kap — ekranda
      // kayboluyordu).
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 3,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.sheet,
        modalBackgroundColor: t.sheet,
        surfaceTintColor: Colors.transparent,
        shape: sheetShape,
        dragHandleColor: scheme.onSurface.withValues(alpha: 0.25),
        modalBarrierColor: scheme.scrim.withValues(alpha: 0.32),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.sheet,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: t.sheet,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.onPrimaryContainer,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant.withValues(alpha: 0.5),
        circularTrackColor: Colors.transparent,
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
    // ONAY PENCERELERİ levhalarla aynı dili konuşsun (DENEYIM F76.4): başlık
    // `sheetTitle` (M3 varsayılanı 24 pt `headlineSmall`), gövde `body`.
    final text = AppText.of(theme);
    return theme.copyWith(
      dialogTheme: theme.dialogTheme.copyWith(
        titleTextStyle: text.sheetTitle,
        contentTextStyle: text.body,
      ),
    );
  }
}
