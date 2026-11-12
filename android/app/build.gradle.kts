import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // AppFunctions derleyicisi (Ajan.kt → AjanServisi + notlar_ajan.xml)
    id("com.google.devtools.ksp")
    // Firebase: `google-services.json` (bu klasörde) + Crashlytics. Firebase
    // KÜTÜPHANE sürümleri burada BİLEREK yazılmıyor (BoM yok): FlutterFire
    // eklentileri hepsini `firebase_core`un sabitlediği tek BoM'dan
    // (`FirebaseSDKVersion`, 4.12.1 → 34.15.0) alıyor — ayrı bir BoM en
    // yükseği seçtirip eklentilerin derlendiği sürümden ayırırdı.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Kalıcı imza: CI, keystore'u GitHub Secrets'tan android/app/ altına,
// şifreleri android/key.properties dosyasına yazar; böylece her derleme
// aynı imzayla çıkar ve telefondaki uygulama sorunsuz güncellenir.
// key.properties yoksa (ör. secrets tanımlanmadıysa) debug imzasına düşülür.
/** Kişisel derleme mi (aşağıda `sourceSets`). */
val kisisel = System.getenv("NOTLAR_KISISEL") == "1" || findProperty("kisisel")?.toString() == "true"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

/// Bütün mimariler paketlensin mi (yalnız emülatörde kare ölçümü — F18.7).
val allAbis = System.getenv("NOTLAR_ALL_ABIS") == "1"

android {
    namespace = "dev.kaimau.notlar"
    // receive_sharing_intent 1.9.0 compileSdk 37 istiyor (Google'ın önerdiği
    // çözüm). AGP 9.0.1 için "önerilen üst 36" yalnızca uyarıdır; 37'ye karşı
    // sorunsuz derler. targetSdk çalışma davranışını değiştirmediğinden
    // Flutter varsayılanında bırakılır.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications için gerekli.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.kaimau.notlar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // firebase_auth minSdk 23 gerektirir.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Uygulama adı (F20.2): profil derlemesi "Notlar Ölçüm" adıyla yan yana.
        manifestPlaceholders["appLabel"] = "Notlar"

        // YALNIZ 64 BİT — 1. savunma hattı (kullanıcı isteği 2026-08-16:
        // "32 bit derlenmesin boşuna kota harcamasın").
        //
        // TEK BAŞINA YETMİYOR, ölçüldü: koşu #31951618844'ün boyut raporu
        // yalnız bununla üretilen APK'da ÜÇ mimarinin de durduğunu gösterdi
        // (arm64 50 MB, x86_64 23 MB, armeabi-v7a 14 MB). `libapp.so` ve
        // `libflutter.so` gerçekten tek mimariydi — yani `--target-platform`
        // çalışıyor — ama EKLENTİLERİN yerel kitaplıkları (ML Kit OCR,
        // barkod, pdfium) hepsi paketlenmişti. Asıl kesme aşağıdaki
        // `packaging.jniLibs.excludes` ile yapılıyor; bu blok yine de duruyor
        // çünkü NDK derlemesi olan bir bağımlılık eklenirse onu kaynağında
        // engeller.
        //
        // BEDELİ: uygulama 32 bit cihazlarda (2015 öncesi telefonlar,
        // bazı ucuz tabletler) HİÇ kurulmaz. Bilinçli karar.
        // EMÜLATÖR (F18.7, 2026-11-02): kare ölçümü x86_64 emülatörde koşar;
        // bu süzgeçler orada `libflutter.so`yu da atıyordu → uygulama açılışta
        // çöküyor, `flutter drive` sonsuza dek bekliyordu ("32 dk çıktı yok").
        // `NOTLAR_ALL_ABIS=1` yalnız ölçüm işinde verilir; yayın APK'sı değişmez.
        if (!allAbis) {
            ndk {
                abiFilters += "arm64-v8a"
            }
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    // 32 BİT VE x86 KİTAPLIKLARI PAKETTEN ÇIKAR — 2. (ve etkili) savunma
    // hattı. `defaultConfig.ndk.abiFilters` eklenti AAR'larından gelen hazır
    // `.so` dosyalarını elemedi (yukarıdaki ölçüme bak); paketleme süzgeci
    // ise dosya yoluna bakıp doğrudan atıyor.
    //
    // `splits.abi` yerine bu seçildi: splits çıktı dosyasının adını
    // `app-arm64-v8a-release.apk` yapıyor ve CI'daki yükleme/yayınlama
    // yolları o adı bilmiyor — sessizce "APK yok" hatasına düşerdi.
    packaging {
        jniLibs {
            // BOYUT (kullanıcı bildirimi 2026-10-23: "Türkçe ses eklenince APK
            // ~30 MB büyüdü"): koşu #516 raporu — libonnxruntime.so 28,6 MB,
            // AGP varsayılanı (minSdk ≥ 23) .so'ları APK'da SIKIŞTIRMADAN
            // saklıyor. Sıkıştırınca ORT ~%60, libapp/libflutter/libpdfium
            // da ~%50 küçülür (indirilen APK ~73 → ~45 MB). Bedeli: kurulumda
            // .so'lar diske açılır (kurulu boyut biraz artar) — indirme ve
            // paylaşım boyutu öncelikli.
            useLegacyPackaging = true
            if (!allAbis) {
                excludes += setOf(
                    "**/x86_64/**",
                    "**/x86/**",
                    "**/armeabi-v7a/**",
                    "**/armeabi/**",
                )
            }
        }
    }

    buildTypes {
        // ÖLÇÜM DERLEMESİ YAN YANA (F20.2, AKICILIK_PLANI): `--profile`
        // çıktısı ayrı kimlikle (`dev.kaimau.notlar.olcum`, "Notlar Ölçüm")
        // kurulur → telefondaki release'e (imza uyuşmazlığı → kaldır-kur →
        // VERİ SİLİNİR) hiç dokunmaz. Firebase istemcisi
        // `src/profile/google-services.json`da. Bilinen sınır: uygulama
        // kısayolları (`app_shortcuts.xml`) sabit paket adıyla release'i açar.
        maybeCreate("profile").apply {
            applicationIdSuffix = ".olcum"
            manifestPlaceholders["appLabel"] = "Notlar Ölçüm"
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 KOD KÜÇÜLTME AÇIK (2026-08-16). Bu iki bayrak olmadan
            // `proguardFiles` hiçbir işe yaramıyordu: AGP'de küçültme
            // varsayılan olarak KAPALI, kural dosyaları yalnız açıkken
            // okunur. Kullanılmayan sınıflar (Firebase'in dokunmadığımız
            // modülleri, Syncfusion, ML Kit'in diğer dilleri) ve
            // kullanılmayan kaynaklar APK'dan düşer.
            //
            // Yansıma (reflection) kullanan yollar proguard-rules.pro'da
            // TEK TEK korunuyor — oraya bakmadan kural ekleme/çıkarma.
            isMinifyEnabled = true
            isShrinkResources = true
            // ML Kit metin tanımanın kullanılmayan dil modelleri için R8
            // dontwarn kuralları (bkz. proguard-rules.pro — bunlar olmadan
            // release derlemesi "Missing class ...chinese/korean..." ile
            // düşüyor).
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // KİŞİSEL KÖPRÜ (ses deposu PLAN K4: derleme bayrağı, ürün çeşidi değil): `NOTLAR_KISISEL=1`
    // (ya da `-Pkisisel=true`) verilince release'e `src/kisisel` girer: Harita/Kanallarım/Asistan
    // not alıcısı, izni ve sertifikaları. Verilmezse `src/genel` (boş KisiselKopru): dağıtılan
    // APK'da köprü yok. Debug ve profile hep genel (kendi manifestleri var). CI kullanıcının
    // telefonu için bayrakla derler (build.yml).
    sourceSets {
        getByName("release") {
            if (kisisel) {
                java.srcDir("src/kisisel/kotlin")
                manifest.srcFile("src/kisisel/AndroidManifest.xml")
                res.srcDir("src/kisisel/res")
            } else {
                java.srcDir("src/genel/kotlin")
            }
        }
        getByName("debug") { java.srcDir("src/genel/kotlin") }
        maybeCreate("profile").java.srcDir("src/genel/kotlin")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// METİN TANIMA (OCR) MODELİ GOOGLE PLAY HİZMETLERİNDEN (kullanıcı isteği
// 2026-09-26: "OCR'yi de taşıyalım"). google_mlkit_text_recognition eklentisi
// ML Kit'in GÖMÜLÜ sürümünü getiriyor: libmlkit_google_ocr_pipeline.so
// (11 MB) + ~1 MB model (koşu #409 boyut raporu). Gömülü paket dışlanıp aynı
// API'yi (com.google.mlkit.vision.text + .latin.TextRecognizerOptions) Play
// Hizmetleri üzerinden sunan paket konuyor; eklentinin Java kodu değişmeden
// çalışır. Model manifestteki `com.google.mlkit.vision.DEPENDENCIES`
// (ocr) ile kurulumda iner. BEDEL: Play Hizmetleri olmayan cihazda OCR yok
// (barkodla aynı karar, bkz. gradle.properties).
//
// Dışlama YALNIZ bu modülün yapılandırmalarında: eklenti kendi modülünde
// gömülü pakete karşı derlenir, uygulama paketlenirken yerine bu gelir.
configurations.configureEach {
    exclude(group = "com.google.mlkit", module = "text-recognition")
    exclude(group = "com.google.mlkit", module = "text-recognition-bundled-common")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
    // Konum hatırlatıcısı: sistem geofence'i + tek seferlik konum okuması
    // (bkz. PlaceReminders.kt).
    implementation("com.google.android.gms:play-services-location:21.3.0")
    // Yerel Firestore/Auth: kişisel köprü (src/kisisel, HaritaNotlari.kt) ve Gemini
    // işlevleri (Ajan.kt) notu Flutter açılmadan yazar/okur (ortak yol YerelNot.kt). Sürüm ayrı bir BoM SEÇİLMEZ: FlutterFire'ın
    // kendi kullandığı BoM (firebase_core'un gradle.properties'indeki
    // FirebaseSDKVersion) okunur, eklentilerle hep aynı sürüm kalır.
    implementation(platform("com.google.firebase:firebase-bom:${firebaseSdkVersion()}"))
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-auth")
    // Gemini gibi ajanlar notları uygulamayı açmadan kullanabilsin (Ajan.kt, Android 16+).
    // beta01 AGP 9.1+ ve compileSdk 37 istiyor (AAR metadata'sı).
    implementation("androidx.appfunctions:appfunctions:1.0.0-beta01")
    ksp("androidx.appfunctions:appfunctions-compiler:1.0.0-beta01")
    // Açılış ekranı ilk Flutter karesine dek kalsın (DENEYIM F78.1, K-D8).
    implementation("androidx.core:core-splashscreen:1.0.1")
}

fun firebaseSdkVersion(): String = Properties().apply {
    rootProject.project(":firebase_core").projectDir.resolve("gradle.properties").inputStream().use { load(it) }
}.getProperty("FirebaseSDKVersion")
