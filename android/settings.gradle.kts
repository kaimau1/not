pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("com.google.devtools.ksp") version "2.3.12" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // Crashlytics (F1.9, 2026-10-19 — kullanıcı isteği, Firebase belgesinin
    // önerdiği kurulum): google-services `google-services.json`dan
    // `google_app_id` kaynağını üretir, Crashlytics eklentisi derleme
    // kimliğini ve R8 eşleme dosyasını yükler (Kotlin yığınları okunur olur).
    id("com.google.gms.google-services") version "4.5.0" apply false
    id("com.google.firebase.crashlytics") version "3.0.8" apply false
}

include(":app")
