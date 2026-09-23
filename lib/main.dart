import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/utils/display_rate.dart';
import 'core/utils/local_file.dart';
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
  // Web'de tarayıcının kendi sağ tık menüsü kapatılır: not kartlarına sağ
  // tıklayınca uygulamanın bağlam menüsü açılsın (masaüstündeki gibi),
  // tarayıcınınki üstüne binmesin. Metin alanları Flutter'ın kendi
  // kes/kopyala/yapıştır menüsünü gösterir.
  if (kIsWeb) unawaited(BrowserContextMenu.disableContextMenu());

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

  // Kenardan kenara çizim her Android sürümünde AÇIK: Android 15+ bunu
  // zaten zorunlu kılıyor; eski sürümlerde de aynı yerleşim olsun ki
  // gezinme çubuğu (saydam, bkz. app.dart) her cihazda aynı görünsün.
  if (!kIsWeb && Platform.isAndroid) {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  if (!DefaultFirebaseOptions.isConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Offline-first: yerel önbellek her platformda açık ve sınırsız.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();

  // Ek dosyalarının kök klasörü: yerel yol artık Firestore'dan okunmuyor,
  // (noteId, ekId, dosyaAdı)ndan türetiliyor — taban BURADA bir kez çözülür
  // (birkaç ms; ilk not ayrıştırılmadan hazır olmalı).
  if (!kIsWeb) {
    try {
      appSupportPath = (await getApplicationSupportDirectory()).path;
    } catch (_) {
      // Taban çözülemedi: ekler yalnız buluttan gösterilir, uygulama çalışır.
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NotlarApp(),
    ),
  );

  // İlk kareyi GEÇİKTİRMEYEN kurulumlar runApp'ten sonra yapılır:
  // - App Check: Play Integrity turu 300-1500 ms sürebiliyor ve zorlama
  //   kapalıyken hiçbir istek token'ın hazır olmasını beklemiyor; açılışı
  //   bloklamasının hiçbir getirisi yoktu.
  // - Yüksek yenileme hızı: ilk kareyi etkilemez; bazı OEM'ler Flutter'ı
  //   60 Hz'e sabitlediği için istek yine de gerekli.
  unawaited(_activateAppCheck());
  unawaited(DisplayRate.apply());
  _lifecycle = AppLifecycleListener(
    // Pil tasarrufu kipi uygulama arkadayken açılıp kapanabilir: yenileme
    // hızı kararı her öne gelişte yeniden verilir (bkz. [DisplayRate]).
    onResume: () => unawaited(DisplayRate.apply()),
    // **RAM**: uygulama arka plana geçince çözülmüş görsel önbelleği
    // boşaltılır (ekranda KULLANILAN görseller etkilenmez, yalnız
    // önbellekte bekleyenler). Arkadaki uygulamanın bellek ayak izi
    // küçüldükçe sistemin onu öldürme olasılığı düşer — öldürülen uygulama
    // soğuk açılışta her şeyi baştan yükler, bu da pili yakar.
    onPause: PaintingBinding.instance.imageCache.clear,
  );
}

/// Uygulama yaşam döngüsü dinleyicisi (bkz. [main]). Referans tutulur ki
/// dinleyici uygulama boyunca yaşasın.
// ignore: unused_element
AppLifecycleListener? _lifecycle;
