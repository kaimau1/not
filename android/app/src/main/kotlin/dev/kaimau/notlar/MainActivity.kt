package dev.kaimau.notlar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

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

    // Tanı için: yalnızca uzunluk ve olay tipi yazılır, konuşma METNİ asla
    // loglanmaz (döküm kişisel veridir, logcat'e sızmamalı).
    private val logTag = "NotlarSpeech"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureSpeechChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
                    // Keep tarzı sesli not: Google'ın sesli giriş EKRANI açılır;
                    // kullanıcı konuşur, dönüşte hem metin hem Google'ın KENDİ
                    // kaydettiği ses dosyası gelir (belgesiz GET_AUDIO ekstrası —
                    // Keep de bunu kullanır). Tek mikrofon istemcisi Google
                    // olduğundan kendi kaydımızla mikrofon kavgası (Android'de
                    // son açan kazanır; ölçümle doğrulandı) hiç doğmaz.
                    "voiceInputWithAudio" -> {
                        if (voiceInputResult != null) {
                            result.error("busy", "Sesli giriş zaten açık", null)
                        } else {
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(
                                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                                )
                                putExtra(
                                    RecognizerIntent.EXTRA_LANGUAGE,
                                    call.argument<String>("locale") ?: "tr-TR"
                                )
                                putExtra("android.speech.extra.GET_AUDIO_FORMAT", "audio/AMR")
                                putExtra("android.speech.extra.GET_AUDIO", true)
                            }
                            try {
                                voiceInputResult = result
                                startActivityForResult(intent, voiceInputRequestCode)
                            } catch (e: Exception) {
                                // Sesli giriş ekranı yok (Google uygulaması kapalı
                                // ya da kaldırılmış): çağıran eski yoluna düşer.
                                voiceInputResult = null
                                result.error("unavailable", "$e", null)
                            }
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
                            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                // Tek MIME `type`e, gerisi EXTRA_MIME_TYPES'a:
                                // yalnız extra verilirse bazı uygulamalar hiç
                                // süzmüyor, yalnız type verilirse çoklu tür
                                // anlatılamıyor.
                                type = if (mimes.size == 1) mimes[0] else "*/*"
                                if (mimes.size > 1) {
                                    putExtra(Intent.EXTRA_MIME_TYPES, mimes.toTypedArray())
                                }
                                if (multiple) {
                                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                                }
                            }
                            try {
                                pickResult = result
                                startActivityForResult(
                                    Intent.createChooser(intent, title),
                                    pickRequestCode
                                )
                            } catch (e: Exception) {
                                // Hiçbir uygulama karşılamadı: Dart tarafı
                                // `file_selector` yoluna düşer.
                                pickResult = null
                                result.error("unavailable", "$e", null)
                            }
                        }
                    }
                    // Videonun KAPAK KARESİ (balonlu görüntülü not): çekilen
                    // videodan tek bir kare çıkarılır ve o karenin üzerine
                    // balon/vurgu konabilen belge sayfası kurulur.
                    "videoFrame" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("args", "path gerekli", null)
                        } else {
                            result.success(videoFrame(path))
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
    private val cameraRequestCode = 4711

    // Sesli giriş ekranının bekleyen yanıtı (aynı anda tek istek olur).
    private var voiceInputResult: MethodChannel.Result? = null
    private val voiceInputRequestCode = 4712

    // Belge seçicinin bekleyen yanıtı (aynı anda tek istek olur).
    private var pickResult: MethodChannel.Result? = null
    private val pickRequestCode = 4713

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickRequestCode) {
            onPickResult(resultCode, data)
            return
        }
        if (requestCode != voiceInputRequestCode) return
        val pending = voiceInputResult ?: return
        voiceInputResult = null
        if (resultCode != RESULT_OK || data == null) {
            // İptal (geri tuşu / konuşma yok): hata değil, boş dönüş.
            pending.success(null)
            return
        }
        val text = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
            ?.firstOrNull() ?: ""
        // Google'ın kaydettiği ses content URI ile gelir; URI kalıcı olmadığı
        // için hemen önbelleğe kopyalanır. GET_AUDIO belgesiz: Google ileride
        // vermeyi keserse audioPath null gider, çağıran yalnız metinle sürer.
        var audioPath: String? = null
        val uri = data.data
        if (uri != null) {
            try {
                val f = java.io.File(cacheDir, "sesligiris_${System.currentTimeMillis()}.amr")
                contentResolver.openInputStream(uri)?.use { inp ->
                    f.outputStream().use { out -> inp.copyTo(out) }
                }
                if (f.length() > 0) audioPath = f.absolutePath else f.delete()
            } catch (e: Exception) {
                Log.d(logTag, "sesli giris ses kopyalanamadi: $e")
            }
        }
        Log.d(logTag, "sesli giris text=${text.length} audio=${audioPath != null}")
        pending.success(mapOf("text" to text, "audioPath" to audioPath))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == cameraRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            cameraResult?.success(granted)
            cameraResult = null
        }
    }

    // ---- Belge seçici ------------------------------------------------

    /// Seçilen içerik URI'lerini önbelleğe kopyalar ve {path, name} listesi
    /// döndürür. İptalde BOŞ liste (hata değil) — çağıran sessizce vazgeçer.
    private fun onPickResult(resultCode: Int, data: Intent?) {
        val pending = pickResult ?: return
        pickResult = null
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
        val out = mutableListOf<Map<String, String>>()
        for (uri in uris) {
            val name = displayName(uri)
            try {
                // Ad ÖNBELLEK YOLUNDA korunur: çağıranların bir kısmı uzantıya
                // bakıyor (PDF mi sunum mu) ve rastgele adlı bir kopya o
                // denetimleri düşürürdü. Çakışmayı klasör önler.
                val dir = java.io.File(cacheDir, "secim_${System.currentTimeMillis()}")
                dir.mkdirs()
                val file = java.io.File(dir, name)
                contentResolver.openInputStream(uri)?.use { inp ->
                    file.outputStream().use { out2 -> inp.copyTo(out2) }
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
        pending.success(out)
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
    private fun videoFrame(path: String): ByteArray? {
        val retriever = android.media.MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            // 1. saniye: sıfırıncı kare çoğu çekimde karanlık/bulanık oluyor.
            val frame = retriever.getFrameAtTime(1_000_000)
                ?: retriever.frameAtTime
                ?: return null
            val out = java.io.ByteArrayOutputStream()
            frame.compress(android.graphics.Bitmap.CompressFormat.JPEG, 88, out)
            frame.recycle()
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
                    startRecognizer(arguments as? String ?: "tr-TR")
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
    // yakmayı sürdürüyordu. (voiceInputWithAudio yolunda listening=false
    // olduğundan Google'ın sesli giriş ekranı açılırken buraya takılmaz.)
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
        // ölçüldü — hiç düşmedi); ses dosyası isteyen akış voiceInputWithAudio
        // köprüsünü kullanır.
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
