package dev.kaimau.notlar

import android.Manifest
import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.location.Geocoder
import android.location.Location
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import android.util.Rational
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/** Seçilen dosyaların önbelleğe kopyası (büyük video/ses saniyeler sürer —
 *  video kapak karesi kuyruğunu bekletmesin diye ayrı iş parçacığı). */
private val pickExecutor: java.util.concurrent.ExecutorService by lazy {
    java.util.concurrent.Executors.newSingleThreadExecutor { r ->
        Thread(r, "notlar-pick").apply { isDaemon = true }
    }
}

/** Video karesi/süresi işleri için süreç ömürlü tek iş parçacığı. */
private val sharedMediaExecutor: java.util.concurrent.ExecutorService by lazy {
    java.util.concurrent.Executors.newSingleThreadExecutor { r ->
        Thread(r, "notlar-media").apply { isDaemon = true }
    }
}

// local_auth (biyometrik not kilidi) FragmentActivity gerektirir.
// Ek olarak iki köprü sağlar:
// 1) Ayarlar'daki "İzinler" bölümü için sistem köprüsü (MethodChannel):
//    mikrofon iznini SORMADAN denetleme, sistem ayarı ekranlarını açma.
// 2) Cihazın YERLEŞİK konuşma tanıması (EventChannel): dikte ve sesli not
//    asistanı bunu kullanır — ücretsiz, anlık ve Gemini kotası yakmaz.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dev.kaimau.notlar/system"
    private val speechChannelName = "dev.kaimau.notlar/speech"

    private var recognizer: SpeechRecognizer? = null
    private var speechSink: EventChannel.EventSink? = null

    // Tamamlanmış konuşma parçaları burada birikir; Flutter'a her olayda
    // "o ana kadarki tam metin" gider, böylece Dart tarafı biriktirme
    // yapmak zorunda kalmaz.
    private val accumulated = StringBuilder()

    // Kullanıcı hâlâ dinlemedeyse (stopSpeech çağrılmadıysa) tanıyıcı
    // sessizlikte kendiliğinden kapandığında yeniden başlatılır.
    private var listening = false

    // Yeniden başlatma pil korumaları. Tanıyıcı sessizlikte ~3 sn'de bir
    // kapanıp yeniden kurulur; bu döngü frensiz kalırsa (ör. mikrofonu başka
    // uygulama kaptığında) ana thread'de sıcak bir bind/unbind döngüsüne
    // dönüşüyor ve dinleme unutulursa mikrofon + servis süresiz açık kalıyor.
    private val mainHandler = Handler(Looper.getMainLooper())

    // Video kareleri/süreleri TEK arka plan iş parçacığında. KÖK NEDEN
    // (kullanıcı bulgusu 2026-10-15: "güncellemeden sonra kasma"): ana ekran
    // kartları videolu notun kapak karesini istemeye başlayınca
    // MediaMetadataRetriever + tam boy JPEG sıkıştırma ANA iş parçacığında
    // koşuyordu (kart başına 100-500 ms). Android'in ana iş parçacığı
    // Flutter'ın vsync ve dokunuş olaylarını da taşıdığı için her kapak bir
    // kare takılması demekti. Tek iş parçacığı: çözücüler aynı anda
    // yarışmasın. Etkinlik başına değil SÜREÇ başına (bkz. companion):
    // ekran döndükçe yeni iş parçacığı birikmesin.
    private val mediaExecutor get() = sharedMediaExecutor
    private var pendingRestart: Runnable? = null
    private var lastStartAt = 0L
    private var rapidRestarts = 0
    private var lastProgressAt = 0L

    // 1,5 sn'den kısa arayla dönen restart "hızlı" sayılır; art arda 5 kez
    // olursa tanıma gerçekten bozuktur, dinleme bitirilir. 2 dk boyunca tek
    // kelime gelmediyse kullanıcı büyük olasılıkla uzaklaştı: mikrofonu
    // süresiz açık tutmak yerine oturum kapatılır (birikmiş metin korunur).
    private val rapidRestartWindowMs = 1_500L
    private val maxRapidRestarts = 5
    private val idleTimeoutMs = 2 * 60_000L

    // Son gönderilen ses seviyesi (RMS olay seli kısılırken karşılaştırılır).
    private var lastRmsLevel = -1f

    // Son DOLU ara sonuç. Tanıyıcı final sonucu boş döndürebiliyor ya da
    // sessizlikte NO_MATCH ile kapanabiliyor; o durumda konuşulan metin
    // yalnızca burada kalır. Biriktirilmezse "Bitir"de metin kaybolur.
    private var lastPartial = ""

    // Tanıyıcı "konuşma bitti" dedi mi. Kısa duraklamada oturum kapanmadan
    // segment değişebiliyor; bu bayrak, gelen yeni ara sonucun öncekinin
    // devamı değil YENİ bir parça olduğunu söyler.
    private var segmentEnded = false

    // İnternetsiz tanıma tercihi (Ayarlar). Dil paketi yoksa tanıyıcı 12/13
    // (dil desteklenmiyor / kullanılamıyor) ile düşer; o zaman tercih bu
    // oturum için bırakılır ve çevrimiçi tanımayla sürülür.
    private var preferOffline = false

    // Tanı için: yalnızca uzunluk ve olay tipi yazılır, konuşma METNİ asla
    // loglanmaz (döküm kişisel veridir, logcat'e sızmamalı).
    private val logTag = "NotlarSpeech"

    // RESİM İÇİNDE RESİM (video oynatıcı ekranları): Dart tarafı oynatıcı
    // açıkken "otomatik PiP"i açar; kullanıcı ana ekrana çıkınca etkinlik
    // küçük pencereye geçer. Pencere değişimi Dart'a "pipChanged" ile
    // bildirilir — oynatıcı o sırada çubukları gizleyip yalnız videoyu çizer.
    private var systemChannel: MethodChannel? = null
    private var autoPip = false
    private var pipRatio = Rational(16, 9)

    private val pipSupported: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    private fun pipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        val builder = PictureInPictureParams.Builder().setAspectRatio(pipRatio)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(autoPip)
            builder.setSeamlessResizeEnabled(true)
        }
        return builder.build()
    }

    // PiP en-boy oranı Android'de 1:2.39 ile 2.39:1 arasında olmalı; dışı
    // IllegalArgumentException atar (dikey çekilmiş 9:21 video gibi).
    private fun clampedRatio(w: Int, h: Int): Rational {
        if (w <= 0 || h <= 0) return Rational(16, 9)
        val r = w.toDouble() / h
        return when {
            r > 2.39 -> Rational(239, 100)
            r < 1 / 2.39 -> Rational(100, 239)
            else -> Rational(w, h)
        }
    }

    private fun enterPip(): Boolean {
        // Sürüm denetimi ÇAĞRININ yanında: lint (NewApi) özellik içindeki
        // denetimi görmez ve sürüm derlemesini durdururdu.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !pipSupported) return false
        val params = pipParams() ?: return false
        return try {
            enterPictureInPictureMode(params)
        } catch (e: Exception) {
            Log.w("NotlarPip", "PiP acilamadi: ${e.javaClass.simpleName}")
            false
        }
    }

    // Android 12 öncesi otomatik geçiş yok: ana ekran tuşu bu kancayı çağırır.
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoPip && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) enterPip()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        systemChannel?.invokeMethod("pipChanged", isInPictureInPictureMode)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureSpeechChannel(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        systemChannel = channel
        channel
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pipSupported" -> result.success(pipSupported)
                    // Oynatıcı hemen küçük pencereye alınır (PiP düğmesi).
                    "enterPip" -> {
                        pipRatio = clampedRatio(
                            call.argument<Int>("w") ?: 16,
                            call.argument<Int>("h") ?: 9
                        )
                        result.success(enterPip())
                    }
                    // Oynatıcı açık/kapalı: açıkken ana ekrana çıkmak PiP'e geçer.
                    "setAutoPip" -> {
                        autoPip = call.argument<Boolean>("enabled") ?: false
                        pipRatio = clampedRatio(
                            call.argument<Int>("w") ?: 16,
                            call.argument<Int>("h") ?: 9
                        )
                        val params = pipParams()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            pipSupported && params != null
                        ) {
                            try {
                                setPictureInPictureParams(params)
                            } catch (e: Exception) {
                                Log.w("NotlarPip", "PiP ayari yazilamadi: ${e.javaClass.simpleName}")
                            }
                        }
                        result.success(pipSupported)
                    }
                    // Cihazda konuşma tanıma var mı (Google uygulaması /
                    // RecognitionService). Yoksa Dart tarafı eski ses yoluna
                    // düşer.
                    "speechAvailable" ->
                        result.success(SpeechRecognizer.isRecognitionAvailable(this))
                    // Dinlemeyi bitir: son sonuç onResults ile gelir, ardından
                    // akış kapanır.
                    "stopSpeech" -> {
                        listening = false
                        pendingRestart?.let { mainHandler.removeCallbacks(it) }
                        pendingRestart = null
                        recognizer?.stopListening()
                        result.success(true)
                    }
                    // Mikrofon iznini yalnızca OKUR (sistem iletişim kutusu
                    // açmaz); ekran açılışında durumu göstermek için.
                    "micPermissionGranted" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.RECORD_AUDIO
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    // Kamera izni: yalnızca OKUR (görüntülü not için gerekir).
                    "cameraPermissionGranted" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.CAMERA
                        ) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    // Kamera iznini İSTER: sistem kutusu açılır, sonuç
                    // onRequestPermissionsResult ile aynı çağrıya döner.
                    "requestCamera" -> {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.CAMERA
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            result.success(true)
                        } else {
                            cameraResult = result
                            requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                cameraRequestCode
                            )
                        }
                    }
                    // Belge seçimi UYGULAMA SEÇİCİ ile (kullanıcı isteği
                    // 2026-08-09: "belge seçileceği zaman dosya tarayıcısını
                    // seçebilmeliyim").
                    //
                    // KÖK NEDEN: `file_selector` Android'de ACTION_OPEN_DOCUMENT
                    // kullanır; o niyeti YALNIZCA sistemin belge kullanıcı
                    // arayüzü (DocumentsUI) karşılar ve açılan çekmecede ancak
                    // DocumentsProvider yazmış sağlayıcılar (Drive, OneDrive,
                    // cihaz deposu) görünür — telefonun KENDİ dosya yöneticisi
                    // uygulaması (MIUI Dosyalar vb.) seçenek olarak hiç çıkmaz.
                    // ACTION_GET_CONTENT'i `createChooser` ile açmak sıradan bir
                    // uygulama seçimi olur: DocumentsUI de listede kalır ama
                    // yanına dosya yöneticileri ve galeri de gelir.
                    //
                    // Seçilen içerik URI'si kalıcı DEĞİL (izin yalnız bu
                    // niyet boyunca) — dosya hemen önbelleğe kopyalanır ve
                    // Dart tarafına gerçek bir yol döner; çağıranların tamamı
                    // yol/bayt bekliyor.
                    "pickDocuments" -> {
                        if (pickResult != null) {
                            result.error("busy", "Dosya seçici zaten açık", null)
                        } else {
                            val mimes = call.argument<List<String>>("mimeTypes")
                                ?: listOf("*/*")
                            val multiple = call.argument<Boolean>("multiple") ?: false
                            val title = call.argument<String>("title")
                            val extensions = call.argument<List<String>>("extensions")
                                ?: emptyList()
                            val viaFileApp = call.argument<Boolean>("fileApp") ?: true
                            val intent = getContentIntent(mimes, multiple, title, extensions)
                            pickResult = result
                            pickIntent = intent
                            pickTitle = title
                            // EKOSİSTEM (kullanıcı isteği 2026-10-17: "bizim
                            // dosya yöneticisi programımız yüklü ise onunla
                            // senkron ve uyumlu çalışalım"): Dosya Okuyucu
                            // kuruluysa seçim DOĞRUDAN onun seçicisinde açılır
                            // — istenen türün bütün dosyaları, en yenisi üstte
                            // (bkz. dosya-okuyucu `PickFileScreen`). Orada
                            // "Diğer kaynaklar"a basılırsa sonuç
                            // RESULT_FIRST_USER döner ve aşağıdaki seçici açılır.
                            val launched = viaFileApp && launchFileApp(intent)
                            if (!launched && !launchChooser(intent, title, excludeFileApp = false)) {
                                // Hiçbir uygulama karşılamadı: Dart tarafı
                                // `file_selector` yoluna düşer.
                                pickResult = null
                                pickIntent = null
                                result.error("unavailable", "seçici yok", null)
                            }
                        }
                    }
                    // Dosya Okuyucu (kardeş uygulama) kurulu mu — ayarlardaki
                    // "Dosyaları Dosya Okuyucu ile seç" satırı yalnız o zaman
                    // görünür.
                    "fileAppInstalled" -> result.success(fileAppResolves())
                    // EKİ FARKLI KAYDET (kullanıcı isteği 2026-10-17): kullanıcı
                    // yeri ve adı sistemin kaydet penceresinde seçer; dosya
                    // oraya kopyalanır. true = kaydedildi, false = iptal.
                    "saveDocument" -> {
                        val path = call.argument<String>("path")
                        if (saveResult != null || path == null) {
                            result.error("busy", "Kaydetme penceresi zaten açık", null)
                        } else {
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                                .addCategory(Intent.CATEGORY_OPENABLE)
                                .setType(call.argument<String>("mimeType") ?: "*/*")
                                .putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: "ek")
                            saveResult = result
                            saveSource = path
                            try {
                                startActivityForResult(intent, saveRequestCode)
                            } catch (e: Exception) {
                                saveResult = null
                                saveSource = null
                                result.error("unavailable", "kaydetme penceresi yok", null)
                            }
                        }
                    }
                    // Videonun KAPAK KARESİ (balonlu görüntülü not): çekilen
                    // videodan tek bir kare çıkarılır ve o karenin üzerine
                    // balon/vurgu konabilen belge sayfası kurulur.
                    "videoFrame" -> {
                        val path = call.argument<String>("path")
                        // atUs verilmezse kapak karesi (bkz. videoFrame).
                        val atUs = call.argument<Number>("atUs")?.toLong()
                        // maxSide verilirse KÜÇÜK RESİM: uzun kenar bu kadar
                        // piksele indirilir (kart kapağı için tam boy kare
                        // ve sıkıştırması boşa iş).
                        val maxSide = call.argument<Number>("maxSide")?.toInt()
                        if (path == null) {
                            result.error("args", "path gerekli", null)
                        } else {
                            mediaExecutor.execute {
                                val bytes = videoFrame(path, atUs, maxSide)
                                mainHandler.post { result.success(bytes) }
                            }
                        }
                    }
                    // Videonun SES İZİNİ yeniden kodlamadan .m4a'ya ayırır
                    // (transkript): 200 MB'lık bir video yerine birkaç MB'lık
                    // ses gönderilir. AAC dışı izde false döner, Dart tarafı
                    // videonun kendisini gönderir.
                    "extractAudio" -> {
                        val path = call.argument<String>("path")
                        val out = call.argument<String>("out")
                        if (path == null || out == null) {
                            result.error("args", "path/out gerekli", null)
                        } else {
                            mediaExecutor.execute {
                                val ok = extractAudioTrack(path, out)
                                mainHandler.post { result.success(ok) }
                            }
                        }
                    }
                    // Videonun toplam süresi (ms). Balonlu görüntülü not
                    // kaç kare örnekleyeceğini buna göre seçiyor.
                    "videoDuration" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("args", "path gerekli", null)
                        } else {
                            mediaExecutor.execute {
                                val ms = videoDurationMs(path)
                                mainHandler.post { result.success(ms) }
                            }
                        }
                    }
                    // Uygulama detay ayarları: kullanıcı kalıcı reddettiği bir
                    // izni buradan elle açabilir.
                    "openAppSettings" -> {
                        startActivity(appDetailsIntent())
                        result.success(true)
                    }
                    // Pil optimizasyonu ekranı: hatırlatıcılar gecikmesin diye
                    // uygulama muaf tutulabilir. ACTION_IGNORE_BATTERY_
                    // OPTIMIZATION_SETTINGS özel izin gerektirmez (Play güvenli);
                    // cihazda yoksa uygulama detaylarına düşer.
                    // Sistemin PİL TASARRUFU kipi açık mı? Açıkken uygulama
                    // ekranı yüksek yenileme hızına ZORLAMAZ (bkz.
                    // display_rate.dart) — kullanıcı pili korumak isterken
                    // 120 Hz'e kilitlemek o isteği çiğnemek olurdu.
                    // ── KONUM HATIRLATICISI (bkz. PlaceReminders.kt) ──
                    // İzin durumu: "background" (tam), "foreground" (yalnız
                    // uygulama açıkken — geofence'e yetmez), "none".
                    "placePermission" -> result.success(placePermissionState())
                    // Önce ön plan (konum), sonra ayrı adımda "her zaman".
                    // Android 11+ ikinci isteği sistemin AYAR sayfasına
                    // yönlendirir; dönüşte sonuç yine buraya gelir.
                    "requestPlacePermission" -> {
                        val background = call.argument<Boolean>("background") == true
                        val permissions = if (background &&
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                        ) {
                            arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                        } else {
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            )
                        }
                        placeResult?.success(placePermissionState())
                        placeResult = result
                        requestPermissions(permissions, placeRequestCode)
                    }
                    "placeCurrentLocation" -> currentLocation(result)
                    "placeGeocode" -> geocode(call.argument<String>("query") ?: "", result)
                    "placeList" -> result.success(
                        PlaceReminders.list(this).map { it.toMap() }
                    )
                    "placeAdd" -> {
                        val item = PlaceReminders.Item.fromMap(call.arguments as Map<*, *>)
                        PlaceReminders.add(this, item) { error ->
                            result.success(error)
                        }
                    }
                    "placeRemove" -> {
                        PlaceReminders.remove(this, call.argument<String>("id") ?: "")
                        result.success(true)
                    }
                    "powerSaveMode" -> {
                        val power = getSystemService(POWER_SERVICE) as? PowerManager
                        result.success(power?.isPowerSaveMode ?: false)
                    }
                    "openBatterySettings" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                        } catch (_: Exception) {
                            startActivity(appDetailsIntent())
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Kamera izin isteğinin bekleyen yanıtı (aynı anda tek istek olur).
    private var cameraResult: MethodChannel.Result? = null
    private var placeResult: MethodChannel.Result? = null
    private val placeRequestCode = 4712

    private fun placePermissionState(): String = when {
        !PlaceReminders.hasForeground(this) -> "none"
        !PlaceReminders.hasBackground(this) -> "foreground"
        else -> "background"
    }

    /** O anki konum (tek okuma, düşük güç önceliği) — {lat, lng} ya da null. */
    @SuppressLint("MissingPermission")
    private fun currentLocation(result: MethodChannel.Result) {
        if (!PlaceReminders.hasForeground(this)) return result.success(null)
        val client = LocationServices.getFusedLocationProviderClient(this)
        client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, null)
            .addOnSuccessListener { location: Location? ->
                if (location == null) {
                    result.success(null)
                } else {
                    result.success(
                        mapOf("lat" to location.latitude, "lng" to location.longitude)
                    )
                }
            }
            .addOnFailureListener { result.success(null) }
    }

    /**
     * Adres/yer adı → en çok beş sonuç. Sistemin Geocoder'ı: ek anahtar ya da
     * ücretli harita servisi gerekmiyor. Ağ çağrısı olduğu için ayrı iş
     * parçacığında; sonuç ana iş parçacığına döner.
     */
    private fun geocode(query: String, result: MethodChannel.Result) {
        if (query.isBlank() || !Geocoder.isPresent()) {
            return result.success(emptyList<Map<String, Any>>())
        }
        Thread {
            val found = try {
                @Suppress("DEPRECATION")
                Geocoder(this).getFromLocationName(query, 5)
                    .orEmpty()
                    .map { a ->
                        val name = (0..a.maxAddressLineIndex)
                            .mapNotNull { a.getAddressLine(it) }
                            .joinToString(", ")
                            .ifBlank { a.featureName ?: query }
                        mapOf("name" to name, "lat" to a.latitude, "lng" to a.longitude)
                    }
            } catch (_: Exception) {
                emptyList()
            }
            runOnUiThread { result.success(found) }
        }.start()
    }
    private val cameraRequestCode = 4711

    // Belge seçicinin bekleyen yanıtı (aynı anda tek istek olur).
    private var pickResult: MethodChannel.Result? = null
    private val pickRequestCode = 4713

    // EKİ FARKLI KAYDET: sistemin "kaydet" penceresi (ACTION_CREATE_DOCUMENT)
    // açıkken bekleyen yanıt ve kopyalanacak kaynak dosya.
    private var saveResult: MethodChannel.Result? = null
    private var saveSource: String? = null
    private val saveRequestCode = 4714

    /// Açık seçimin taban niyeti ve başlığı ("Diğer kaynaklar" dönüşünde
    /// aynı istekle sistem seçicisi açılsın diye saklanır).
    private var pickIntent: Intent? = null
    private var pickTitle: String? = null

    // ── EKOSİSTEM SÖZLEŞMESİ — Dosya Okuyucu (kardeş uygulama) ─────────
    // İki depoda AYNI değerler: dosya-okuyucu `ci/PickerActivity.kt`.
    private val fileAppPackage = "com.dosyaokuyucu.dosya_okuyucu"
    private val extraExtensions = "com.dosyaokuyucu.extra.EXTENSIONS"
    private val extraCaller = "com.dosyaokuyucu.extra.CALLER"
    private val extraOtherSourcesOk = "com.dosyaokuyucu.extra.OTHER_SOURCES_OK"
    private val extraOtherSource = "com.dosyaokuyucu.extra.OTHER_SOURCE"

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickRequestCode) {
            onPickResult(resultCode, data)
            return
        }
        if (requestCode == saveRequestCode) {
            onSaveResult(resultCode, data)
            return
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == placeRequestCode) {
            placeResult?.success(placePermissionState())
            placeResult = null
        }
        if (requestCode == cameraRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            cameraResult?.success(granted)
            cameraResult = null
        }
    }

    // ---- Belge seçici ------------------------------------------------

    /// Seçicinin taban niyeti: `ACTION_GET_CONTENT` + tür süzgeci.
    ///
    /// TÜR SÜZGECİ (kullanıcı bulgusu 2026-10-17: "dosya eklerken açılan
    /// dosya yöneticisi istenen uzantıya göre süzmeli, şu an ana sayfa
    /// açılıyor ve bulmak çok zor"): birden çok MIME verildiğinde `type`
    /// eskiden düz `*/*` oluyordu — EXTRA_MIME_TYPES'a bakmayan dosya
    /// yöneticileri (Dosya Okuyucu dahil) her şeyi gösteriyordu. Artık hepsi
    /// aynı aileden geliyorsa (`image/jpeg` + `image/png`) `type` o aile
    /// (`image/*`); kesin liste yine EXTRA_MIME_TYPES'ta. Uzantı listesi ve
    /// başlık, Dosya Okuyucu'nun süzgeci için ayrı ekstralarla gider
    /// (başka uygulamalar tanımadıkları ekstrayı yok sayar).
    private fun getContentIntent(
        mimes: List<String>,
        multiple: Boolean,
        title: String?,
        extensions: List<String>,
    ): Intent = Intent(Intent.ACTION_GET_CONTENT).apply {
        addCategory(Intent.CATEGORY_OPENABLE)
        type = intentTypeOf(mimes)
        if (mimes.size > 1) {
            putExtra(Intent.EXTRA_MIME_TYPES, mimes.toTypedArray())
        }
        if (multiple) putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        if (!title.isNullOrBlank()) putExtra(Intent.EXTRA_TITLE, title)
        if (extensions.isNotEmpty()) {
            putExtra(extraExtensions, extensions.map { it.lowercase() }.toTypedArray())
        }
        putExtra(extraCaller, getString(R.string.widget_title))
        // Bu çağıran "Diğer kaynaklar" dönüşünü anlıyor: Dosya Okuyucu düğmeyi
        // yalnız o zaman gösterir (başka bir uygulama RESULT_FIRST_USER'ı
        // sessiz bir iptal sanardı).
        putExtra(extraOtherSourcesOk, true)
    }

    /// Tek MIME → kendisi; hepsi aynı aileden → `aile/*`; yoksa `*/*`.
    private fun intentTypeOf(mimes: List<String>): String {
        if (mimes.isEmpty()) return "*/*"
        if (mimes.size == 1) return mimes[0]
        val families = mimes.map { it.substringBefore('/') }.toSet()
        val family = families.singleOrNull()
        return if (family != null && family != "*") "$family/*" else "*/*"
    }

    /// Dosya Okuyucu niyeti karşılayabiliyor mu (kurulu + seçici kipi var).
    private fun fileAppResolves(): Boolean = try {
        val probe = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            setPackage(fileAppPackage)
        }
        packageManager.queryIntentActivities(probe, 0).isNotEmpty()
    } catch (e: Exception) {
        false
    }

    private fun launchFileApp(base: Intent): Boolean {
        if (!fileAppResolves()) return false
        return try {
            startActivityForResult(Intent(base).setPackage(fileAppPackage), pickRequestCode)
            true
        } catch (e: Exception) {
            Log.d(logTag, "dosya okuyucu acilamadi: $e")
            false
        }
    }

    /// Sıradan "hangi uygulamayla?" seçimi. [excludeFileApp]: Dosya
    /// Okuyucu'dan "Diğer kaynaklar" ile gelindiyse listede tekrar çıkmasın.
    private fun launchChooser(base: Intent, title: String?, excludeFileApp: Boolean): Boolean {
        return try {
            val chooser = Intent.createChooser(base, title)
            if (excludeFileApp && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val excluded = packageManager.queryIntentActivities(
                    Intent(base).setPackage(fileAppPackage), 0
                ).map {
                    android.content.ComponentName(it.activityInfo.packageName, it.activityInfo.name)
                }
                if (excluded.isNotEmpty()) {
                    chooser.putExtra(Intent.EXTRA_EXCLUDE_COMPONENTS, excluded.toTypedArray())
                }
            }
            startActivityForResult(chooser, pickRequestCode)
            true
        } catch (e: Exception) {
            false
        }
    }

    /// Seçilen içerik URI'lerini önbelleğe kopyalar ve {path, name} listesi
    /// döndürür. İptalde BOŞ liste (hata değil) — çağıran sessizce vazgeçer.
    ///
    /// KASMA (2026-10-17): kopyalama eskiden ANA iş parçacığındaydı — 200 MB'lık
    /// bir ses/video seçilince arayüz saniyelerce donuyor, uzun dosyada ANR
    /// riski doğuyordu. Artık medya iş parçacığında; sonuç ana iş parçacığına
    /// döner. URI okuma izni etkinlik ömrü boyunca geçerli, arka planda
    /// okumak güvenli.
    private fun onSaveResult(resultCode: Int, data: Intent?) {
        val pending = saveResult ?: return
        val source = saveSource
        saveResult = null
        saveSource = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null || source == null) {
            pending.success(false)
            return
        }
        pickExecutor.execute {
            val ok = try {
                contentResolver.openOutputStream(uri, "w")?.use { out ->
                    java.io.File(source).inputStream().use { inp -> inp.copyTo(out, 256 * 1024) }
                } != null
            } catch (e: Exception) {
                Log.d(logTag, "farkli kaydet yazilamadi: $e")
                false
            }
            mainHandler.post {
                if (ok) pending.success(true) else pending.error("write", "yazılamadı", null)
            }
        }
    }

    private fun onPickResult(resultCode: Int, data: Intent?) {
        val pending = pickResult ?: return
        // Dosya Okuyucu'nun "Diğer kaynaklar" düğmesi: aynı istekle sistem
        // seçicisi açılır (Dosya Okuyucu hariç); sonuç yine buraya düşer.
        if (resultCode == RESULT_FIRST_USER &&
            data?.getBooleanExtra(extraOtherSource, false) == true
        ) {
            val base = pickIntent
            if (base != null && launchChooser(base, pickTitle, excludeFileApp = true)) return
        }
        pickResult = null
        pickIntent = null
        pickTitle = null
        if (resultCode != RESULT_OK || data == null) {
            pending.success(emptyList<Map<String, String>>())
            return
        }
        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i).uri?.let(uris::add)
            }
        } else {
            data.data?.let(uris::add)
        }
        pickExecutor.execute {
            val out = mutableListOf<Map<String, String>>()
            for (uri in uris) {
                val name = displayName(uri)
                try {
                    // Ad ÖNBELLEK YOLUNDA korunur: çağıranların bir kısmı uzantıya
                    // bakıyor (PDF mi sunum mu) ve rastgele adlı bir kopya o
                    // denetimleri düşürürdü. Çakışmayı klasör önler.
                    val dir = java.io.File(cacheDir, "secim_${System.nanoTime()}")
                    dir.mkdirs()
                    val file = java.io.File(dir, name)
                    contentResolver.openInputStream(uri)?.use { inp ->
                        file.outputStream().use { out2 -> inp.copyTo(out2, 256 * 1024) }
                    }
                    if (file.length() > 0) {
                        out.add(mapOf("path" to file.absolutePath, "name" to name))
                    } else {
                        file.delete()
                    }
                } catch (e: Exception) {
                    Log.d(logTag, "secim kopyalanamadi: $e")
                }
            }
            mainHandler.post { pending.success(out) }
        }
    }

    /// İçerik URI'sinin görünen adı; sağlayıcı vermezse damgalı bir ad.
    private fun displayName(uri: Uri): String {
        try {
            contentResolver.query(uri, null, null, null, null)?.use { c ->
                val index = c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (index >= 0 && c.moveToFirst()) {
                    val value = c.getString(index)
                    if (!value.isNullOrBlank()) return sanitize(value)
                }
            }
        } catch (e: Exception) {
            Log.d(logTag, "secim adi okunamadi: $e")
        }
        val ext = contentResolver.getType(uri)
            ?.let { android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(it) }
        return "belge_${System.currentTimeMillis()}" + if (ext != null) ".$ext" else ""
    }

    /// Dosya adından yol ayırıcılarını temizler (sağlayıcı adına "../" koyarsa
    /// kopya önbellek klasörünün DIŞINA yazılırdı).
    private fun sanitize(name: String): String =
        name.replace('/', '_').replace('\\', '_').trim().ifEmpty { "belge" }

    /// Videodan kapak karesi (JPEG baytları); çıkarılamazsa null.
    private fun videoFrame(path: String, atUs: Long? = null, maxSide: Int? = null): ByteArray? {
        val retriever = android.media.MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            // atUs verilmişse O ANIN karesi (en yakın anahtar kare — tam
            // kare aramak uzun videoda saniyeler sürüyor), yoksa 1. saniye:
            // sıfırıncı kare çoğu çekimde karanlık/bulanık oluyor.
            val sync = android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC
            val timeUs = atUs ?: 1_000_000L
            var frame: android.graphics.Bitmap? = null
            if (maxSide != null && maxSide > 0 &&
                android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1
            ) {
                // Çözücü kareyi DOĞRUDAN küçük üretir (tam boy bitmap hiç
                // oluşmaz) — kapak için en ucuz yol.
                val w = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
                )?.toIntOrNull() ?: 0
                val h = retriever.extractMetadata(
                    android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
                )?.toIntOrNull() ?: 0
                if (w > 0 && h > 0) {
                    val scale = maxSide.toFloat() / maxOf(w, h)
                    val tw = maxOf(1, (w * minOf(1f, scale)).toInt())
                    val th = maxOf(1, (h * minOf(1f, scale)).toInt())
                    frame = retriever.getScaledFrameAtTime(timeUs, sync, tw, th)
                }
            }
            if (frame == null) {
                frame = (
                    if (atUs != null) {
                        retriever.getFrameAtTime(atUs, sync)
                    } else {
                        retriever.getFrameAtTime(1_000_000)
                    }
                    ) ?: retriever.frameAtTime ?: return null
            }
            var output: android.graphics.Bitmap = frame!!
            if (maxSide != null && maxSide > 0 && maxOf(output.width, output.height) > maxSide) {
                val scale = maxSide.toFloat() / maxOf(output.width, output.height)
                val scaled = android.graphics.Bitmap.createScaledBitmap(
                    output,
                    maxOf(1, (output.width * scale).toInt()),
                    maxOf(1, (output.height * scale).toInt()),
                    true
                )
                if (scaled != output) output.recycle()
                output = scaled
            }
            val out = java.io.ByteArrayOutputStream()
            output.compress(
                android.graphics.Bitmap.CompressFormat.JPEG,
                if (maxSide != null) 80 else 88,
                out
            )
            output.recycle()
            out.toByteArray()
        } catch (e: Exception) {
            Log.d(logTag, "video karesi alinamadi: $e")
            null
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    /// Videonun ilk AAC ses izini [out] yoluna MPEG-4 (.m4a) olarak kopyalar.
    /// Örnekler yeniden KODLANMAZ (MediaExtractor -> MediaMuxer), saniyeler
    /// sürer. İz yoksa, AAC değilse ya da yazım bozulursa false (yarım dosya
    /// silinir).
    private fun extractAudioTrack(path: String, out: String): Boolean {
        val extractor = android.media.MediaExtractor()
        var muxer: android.media.MediaMuxer? = null
        var ok = false
        try {
            extractor.setDataSource(path)
            var track = -1
            var format: android.media.MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(android.media.MediaFormat.KEY_MIME) ?: continue
                if (mime == "audio/mp4a-latm") {
                    track = i
                    format = f
                    break
                }
            }
            if (track < 0 || format == null) return false
            extractor.selectTrack(track)
            val m = android.media.MediaMuxer(
                out,
                android.media.MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )
            muxer = m
            val outTrack = m.addTrack(format)
            m.start()
            val maxInput =
                if (format.containsKey(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    format.getInteger(android.media.MediaFormat.KEY_MAX_INPUT_SIZE)
                } else {
                    0
                }
            val buffer = java.nio.ByteBuffer.allocate(maxOf(maxInput, 256 * 1024))
            val info = android.media.MediaCodec.BufferInfo()
            var samples = 0
            while (true) {
                buffer.clear()
                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break
                val time = extractor.sampleTime
                if (time >= 0) {
                    info.offset = 0
                    info.size = size
                    info.presentationTimeUs = time
                    info.flags =
                        if ((extractor.sampleFlags and
                                android.media.MediaExtractor.SAMPLE_FLAG_SYNC) != 0
                        ) {
                            android.media.MediaCodec.BUFFER_FLAG_KEY_FRAME
                        } else {
                            0
                        }
                    m.writeSampleData(outTrack, buffer, info)
                    samples++
                }
                if (!extractor.advance()) break
            }
            m.stop()
            ok = samples > 0
        } catch (e: Exception) {
            Log.d(logTag, "ses izi ayrilamadi: $e")
            ok = false
        } finally {
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
            try {
                extractor.release()
            } catch (_: Exception) {
            }
            if (!ok) {
                try {
                    java.io.File(out).delete()
                } catch (_: Exception) {
                }
            }
        }
        return ok
    }

    // Videonun süresi (ms); okunamazsa 0.
    private fun videoDurationMs(path: String): Long {
        val retriever = android.media.MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            val key = android.media.MediaMetadataRetriever.METADATA_KEY_DURATION
            retriever.extractMetadata(key)?.toLongOrNull() ?: 0L
        } catch (e: Exception) {
            Log.d(logTag, "video suresi alinamadi: $e")
            0L
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun appDetailsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

    // ---- Yerleşik konuşma tanıma -------------------------------------
    // Akışa abone olunmak dinlemeyi BAŞLATIR, aboneliği bırakmak İPTAL eder;
    // "bitir" (son metni al) MethodChannel'daki stopSpeech ile yapılır.
    private fun configureSpeechChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, speechChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    speechSink = events
                    accumulated.setLength(0)
                    lastPartial = ""
                    lastRmsLevel = -1f
                    segmentEnded = false
                    listening = true
                    rapidRestarts = 0
                    lastProgressAt = SystemClock.elapsedRealtime()
                    // Argüman "tr-TR" ya da "tr-TR|offline" (internetsiz tanıma
                    // tercihi — bkz. DeviceSpeech.listen).
                    val parts = (arguments as? String ?: "tr-TR").split('|')
                    preferOffline = parts.contains("offline")
                    startRecognizer(parts.first().ifBlank { "tr-TR" })
                }

                override fun onCancel(arguments: Any?) {
                    stopRecognizer()
                    speechSink = null
                }
            })
    }

    private fun startRecognizer(locale: String) {
        // SpeechRecognizer yalnızca ana thread'den sürülebilir.
        mainHandler.post {
            if (!listening) return@post
            lastStartAt = SystemClock.elapsedRealtime()
            recognizer?.destroy()
            val speech = SpeechRecognizer.createSpeechRecognizer(this)
            recognizer = speech
            speech.setRecognitionListener(speechListener(locale))
            speech.startListening(recognizerIntent(locale))
        }
    }

    // Sessizlik kapanışlarından sonra çağrılır. startRecognizer'dan farkı
    // frenler: (1) 2 dk hiç metin gelmediyse oturum biter; (2) art arda hızlı
    // dönen restart'lar üstel gecikmeyle yavaşlatılır ve tavana vurunca
    // dinleme kapatılır — çıplak döngü, bozuk tanıyıcıda saniyede onlarca
    // kez servis bind'ı yapıp pili eritiyordu.
    private fun restartRecognizer(locale: String) {
        val now = SystemClock.elapsedRealtime()
        if (now - lastProgressAt > idleTimeoutMs) {
            Log.d(logTag, "restart yok: ${idleTimeoutMs / 1000}s ilerleme yok, oturum kapatildi")
            finishListening("speech_idle", "Uzun süre konuşma algılanmadı, dinleme durduruldu")
            return
        }
        if (now - lastStartAt < rapidRestartWindowMs) rapidRestarts++ else rapidRestarts = 0
        if (rapidRestarts >= maxRapidRestarts) {
            Log.d(logTag, "restart yok: $rapidRestarts hizli dongu, oturum kapatildi")
            finishListening("speech_error", "Konuşma tanıma tekrar tekrar başarısız oldu")
            return
        }
        if (rapidRestarts == 0) {
            startRecognizer(locale)
            return
        }
        val delay = (300L shl (rapidRestarts - 1)).coerceAtMost(2_400L)
        Log.d(logTag, "restart geciktirildi: n=$rapidRestarts delay=${delay}ms")
        val restart = Runnable {
            pendingRestart = null
            if (listening) startRecognizer(locale)
        }
        pendingRestart = restart
        mainHandler.postDelayed(restart, delay)
    }

    // Dinlemeyi durdurur ve tanıyıcıyı serbest bırakır (akışı kapatmaz).
    private fun stopRecognizer() {
        listening = false
        pendingRestart?.let { mainHandler.removeCallbacks(it) }
        pendingRestart = null
        recognizer?.cancel()
        recognizer?.destroy()
        recognizer = null
    }

    // Oturumu uygulama adına bitirir: birikmiş metin son kez gönderilir ki
    // kullanıcının söyledikleri kaybolmasın, ardından hata olayıyla Dart
    // tarafına "dinleme bitti" bilgisi düşer (ekranlar hatayı gösterir,
    // biriken metni korur — bkz. voice_capture_sheet/voice_assistant).
    private fun finishListening(code: String, message: String) {
        commitPartial()
        if (accumulated.isNotEmpty()) {
            speechSink?.success(mapOf("text" to accumulated.toString()))
        }
        stopRecognizer()
        speechSink?.error(code, message, null)
    }

    // Uygulama arka plana düşünce mikrofon bırakılır: FGS'siz bir uygulamanın
    // arka planda dinlemeye devam etmesi hem pil hem gizlilik sorunu; Android
    // 11+ zaten mikrofonu bir süre sonra keser ama restart döngüsü CPU
    // yakmayı sürdürüyordu.
    override fun onStop() {
        if (listening) {
            Log.d(logTag, "onStop: arka plan, dinleme kapatildi")
            finishListening("speech_background", "Uygulama arka plana alındı, dinleme durduruldu")
        }
        super.onStop()
    }

    private fun recognizerIntent(locale: String): Intent =
        Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            // Konuştukça metin aksın (yalnız bitişte değil).
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            // İnternetsiz tanıma: cihazda dil paketi varsa ağa gidilmez.
            if (preferOffline) putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            // Düşünmek için duraksayan kullanıcıda tanıyıcı erken kapanmasın.
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
                3000
            )
        }

    private fun speechListener(locale: String) = object : RecognitionListener {
        override fun onPartialResults(results: Bundle?) {
            val text = firstResult(results) ?: return
            if (text.isBlank()) return
            // KISA DURAKLAMA SORUNU: tanıyıcı, oturumu kapatmadan ve
            // onResults GÖNDERMEDEN segmenti bitirip ara sonucu sıfırdan
            // başlatabiliyor. Eskiden birikim yalnızca onResults'ta dolduğu
            // için duraklamadan öncesi hiç kalıcı olmuyor, sonraki ara sonuç
            // ekrandakini tümüyle siliyordu. Devam değilse önce kalıcı yap.
            val continues = isContinuation(text, lastPartial)
            Log.d(
                logTag,
                "partial len=${text.length} last=${lastPartial.length} " +
                    "cont=$continues ended=$segmentEnded acc=${accumulated.length}"
            )
            if (!continues) commitPartial()
            segmentEnded = false
            lastPartial = text
            lastProgressAt = SystemClock.elapsedRealtime()
            speechSink?.success(mapOf("text" to joined(text)))
        }

        // Ses seviyesi: mikrofon SpeechRecognizer'da olduğundan ayrıca
        // kayıt açılamaz; düğme animasyonu bu değerle beslenir.
        override fun onRmsChanged(rmsdB: Float) {
            val level = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
            // Tanıyıcı saniyede ~10-20 RMS üretir; görünmez farkları kanala
            // taşımak Flutter tarafında boşuna rebuild demek (pil). Yalnız
            // gözle seçilir değişim gönderilir.
            if (kotlin.math.abs(level - lastRmsLevel) < 0.04f) return
            lastRmsLevel = level
            speechSink?.success(mapOf("level" to level.toDouble()))
        }

        override fun onResults(results: Bundle?) {
            val text = firstResult(results)
            Log.d(
                logTag,
                "results len=${text?.length ?: -1} last=${lastPartial.length} " +
                    "acc=${accumulated.length} listening=$listening"
            )
            // Google tanıyıcısı stopListening() sonrası final sonucu NULL
            // döndürebiliyor (SODA'da olağan) — ölçümle doğrulandı. O durumda
            // son dolu ara sonuç kullanılmazsa konuşulan cümle tamamen
            // kaybolur ve Flutter'a boş metin gidip ekrandakini de siler.
            // Final sonuç varsa aynı segmentin ara sonucunun yerini alır.
            if (!text.isNullOrBlank()) {
                lastPartial = text
                lastProgressAt = SystemClock.elapsedRealtime()
            }
            commitPartial()
            segmentEnded = false
            speechSink?.success(mapOf("text" to accumulated.toString()))
            // Tanıyıcı her sessizlikte kendini kapatır; kullanıcı hâlâ
            // konuşuyorsa kaldığı yerden devam etsin diye yeniden başlatılır.
            // ponytail: yeniden başlatma sırasında ~200 ms sağırlık var; sorun
            // olursa Android 13+ EXTRA_SEGMENTED_SESSION'a geçilir.
            if (listening) restartRecognizer(locale)
        }

        override fun onError(error: Int) {
            // KÖK NEDEN ("Konuşma tanıma çalışmadı" izin varken çıkıyordu):
            // tanıyıcı her sessizlikte kapanıp yeniden kuruluyor; YENİ örnek,
            // eski oturum kapanırken ölmekte olan servise bağlandığı için
            // anında ERROR_SERVER_DISCONNECTED alıyor. Ölçüm (logcat): error=7
            // → 17 ms sonra iki kez error=11 → 5 ms sonra onStartListening ve
            // onMicrophoneOpened, yani tanıma ASLINDA sorunsuz başlıyor. Bu
            // geçici gürültü ölümcül sanılınca dikte boşuna öldürülüyordu.
            //
            // Yeniden BAŞLATMIYORUZ: 11'in kendisi yeniden kurulumun ürünü,
            // restart tetiklemek sonsuz döngü olurdu — yalnızca yutulur.
            // Takas: tanıma gerçekten ölürse uyarı çıkmaz, kullanıcı metnin
            // gelmediğini görür; sessiz veri kaybı değil, görünür eksik.
            if (error == SpeechRecognizer.ERROR_SERVER_DISCONNECTED) {
                Log.d(logTag, "error=11 yeniden kurulum gurultusu, yok sayildi")
                return
            }
            // İnternetsiz tanıma istendi ama dil paketi yok (12 =
            // ERROR_LANGUAGE_NOT_SUPPORTED, 13 = ERROR_LANGUAGE_UNAVAILABLE —
            // API 31 sabitleri, eski SDK'larda da derlensin diye sayı):
            // kullanıcı sessiz kalmasın, çevrimiçi tanımaya düşülür.
            if (preferOffline && (error == 12 || error == 13) && listening) {
                Log.d(logTag, "error=$error cevrimdisi paket yok, cevrimici devam")
                preferOffline = false
                restartRecognizer(locale)
                return
            }
            // Sessizlik/eşleşmeme hata değildir: dinlemeye devam et.
            val benign = error == SpeechRecognizer.ERROR_NO_MATCH ||
                error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT
            Log.d(
                logTag,
                "error=$error benign=$benign last=${lastPartial.length} " +
                    "acc=${accumulated.length}"
            )
            if (benign && listening) {
                // Yeniden başlatmadan ÖNCE ara sonucu kalıcı hale getir;
                // aksi hâlde sessizlikte kapanan her turda söylenen kaybolur.
                if (lastPartial.isNotBlank()) {
                    commitPartial()
                    speechSink?.success(mapOf("text" to accumulated.toString()))
                }
                segmentEnded = false
                restartRecognizer(locale)
                return
            }
            if (listening) {
                speechSink?.error("speech_error", "Konuşma tanıma hatası: $error", null)
            }
        }

        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        // Google'ın servisi bu geri çağrıyı beslemiyor (2026-07-25'te cihazda
        // ölçüldü — hiç düşmedi).
        override fun onBufferReceived(buffer: ByteArray?) {}

        // Tanıyıcı konuşmanın bittiğini algıladı. Oturum kapanmadan yeni bir
        // parça başlayabilir; bayrak sayesinde sonraki ara sonuç öncekinin
        // üzerine yazmaz.
        override fun onEndOfSpeech() {
            Log.d(logTag, "endOfSpeech last=${lastPartial.length}")
            segmentEnded = true
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    // Son ara sonucu kalıcı yapar. Parçalar SATIR SONU ile ayrılır: liste
    // notlarında her duraklama ayrı madde olur (Dart '\n'den böler), metin
    // notlarında boşluğa çevrilir.
    private fun commitPartial() {
        val part = lastPartial.trim()
        lastPartial = ""
        if (part.isEmpty()) return
        if (accumulated.isEmpty()) {
            accumulated.append(part)
            return
        }
        // Tanıyıcı, ara sonucu sıfırladıktan sonra final sonuçta ÖNCEKİ
        // parçayı da kapsayabiliyor. O parçayı iki kez yazmamak için önceki
        // satır geri alınır (yoksa "abc" + "abc def" = "abc abc def").
        val lastLine = accumulated.substring(accumulated.lastIndexOf('\n') + 1)
        if (lastLine.isNotEmpty() && part.startsWith(lastLine)) {
            accumulated.setLength(accumulated.length - lastLine.length)
        } else {
            accumulated.append('\n')
        }
        accumulated.append(part)
    }

    // Yeni ara sonuç, öncekinin AYNI segmentteki hali mi? Tanıyıcı aynı
    // segmentte metni uzatır ya da kuyruğunu düzeltir; yeni segmentte baştan
    // başlar. Kararsızlıkta "aynı segment DEĞİL" denir: kötü ihtimalde bir
    // kelime tekrarlanır, iyi ihtimalde konuşma korunur — kullanıcının
    // söylediğini kaybetmektense tekrar etmek yeğdir.
    private fun isContinuation(new: String, old: String): Boolean {
        if (old.isEmpty()) return true
        if (segmentEnded) return false
        if (new.startsWith(old) || old.startsWith(new)) return true
        // Kuyruk düzeltmesi baştaki kelimeyi korur; yeni segment korumaz.
        return new.substringBefore(' ') == old.substringBefore(' ')
    }

    private fun firstResult(results: Bundle?): String? =
        results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()

    // Biriken tamamlanmış metin + o anki kısmi metin.
    private fun joined(partial: String): String =
        if (accumulated.isEmpty()) partial else "$accumulated\n$partial"
}
