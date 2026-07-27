import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/widgets/setup_required_screen.dart';
import 'features/settings/settings_providers.dart';
import 'firebase_options.dart';

/// App Check: isteklerin gerçekten BU uygulamadan geldiğini kanıtlar.
///
/// Neden gerekli: dahili AI çağrıları projenin Gemini faturasından karşılanıyor.
/// App Check olmadan, API uç noktasını ele geçiren biri sınırsız istek atıp
/// faturayı şişirebilir; kota sayacı istemcide olduğu için onu da atlayabilir.
///
/// ÖNEMLİ — şu an yalnızca TOKEN ÜRETİLİYOR, zorlama YOK. Firebase konsolunda
/// "Enforce" açılmadan hiçbir istek reddedilmez; bu bilinçli sıradır:
///   1. (burası) uygulama token üretmeye başlar,
///   2. konsolda birkaç gün "doğrulanmamış istek" oranı izlenir,
///   3. oran sıfıra yaklaşınca zorlama açılır.
/// Ters sırada açılırsa tüm kullanıcılar aniden hata alır.
///
/// Play Integrity, uygulamanın Play üzerinden dağıtılmasını bekler; elle
/// kurulan APK'da doğrulama başarısız olabilir — zorlama kapalı olduğu için
/// bu bir sorun değil, yalnız o istekler "doğrulanmamış" sayılır.
Future<void> _activateAppCheck() async {
  // Yalnız Android: masaüstünde App Check eklentisi yok, çağrı hata verir.
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await FirebaseAppCheck.instance.activate(
      // Hata ayıklama derlemesi Play Integrity'den geçemez; debug sağlayıcısı
      // logcat'e bir token basar, o token konsola elle eklenir.
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  } catch (e) {
    // App Check kurulamazsa uygulama yine çalışmalı (zorlama kapalı).
    debugPrint('App Check etkinleştirilemedi: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'Notlar',
      size: Size(1100, 750),
      minimumSize: Size(400, 500),
      center: true,
    );
    unawaited(
      windowManager.waitUntilReadyToShow(options, () async {
        await windowManager.show();
        await windowManager.focus();
      }),
    );
  }

  if (!kIsWeb && Platform.isAndroid) {
    // Yüksek yenileme hızlı ekranlarda (120/144/165 Hz) en yüksek modu iste.
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Desteklenmeyen cihazlarda sessizce geç.
    }
  }

  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _activateAppCheck();

  // Offline-first: yerel önbellek her platformda açık ve sınırsız.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NotlarApp(),
    ),
  );
}
