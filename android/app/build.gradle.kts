import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kalıcı imza: CI, keystore'u GitHub Secrets'tan android/app/ altına,
// şifreleri android/key.properties dosyasına yazar; böylece her derleme
// aynı imzayla çıkar ve telefondaki uygulama sorunsuz güncellenir.
// key.properties yoksa (ör. secrets tanımlanmadıysa) debug imzasına düşülür.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

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

        // YALNIZ 64 BİT (kullanıcı isteği 2026-08-16: "32 bit derlenmesin
        // boşuna kota harcamasın"). `--target-platform android-arm64` yalnız
        // FLUTTER'ın kendi kitaplıklarını (engine + Dart AOT) tek mimariye
        // indiriyordu; eklentilerin yerel kitaplıkları (ML Kit, pdfium,
        // mobile_scanner, record…) yine üç mimari için de paketleniyordu.
        // abiFilters bunları da keser: APK'da tek bir `arm64-v8a/` klasörü
        // kalır. Bayrak unutulsa bile 32 bit derlenmez.
        //
        // BEDELİ: uygulama 32 bit cihazlarda (2015 öncesi telefonlar,
        // bazı ucuz tabletler) HİÇ kurulmaz. Bilinçli karar.
        ndk {
            abiFilters += "arm64-v8a"
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

    buildTypes {
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
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
