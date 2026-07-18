package dev.kaimau.notlar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
                    segmentEnded = false
                    listening = true
                    startRecognizer(arguments as? String ?: "tr-TR")
                }

                override fun onCancel(arguments: Any?) {
                    listening = false
                    recognizer?.cancel()
                    recognizer?.destroy()
                    recognizer = null
                    speechSink = null
                }
            })
    }

    private fun startRecognizer(locale: String) {
        // SpeechRecognizer yalnızca ana thread'den sürülebilir.
        Handler(Looper.getMainLooper()).post {
            if (!listening) return@post
            recognizer?.destroy()
            val speech = SpeechRecognizer.createSpeechRecognizer(this)
            recognizer = speech
            speech.setRecognitionListener(speechListener(locale))
            speech.startListening(recognizerIntent(locale))
        }
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
            speechSink?.success(mapOf("text" to joined(text)))
        }

        // Ses seviyesi: mikrofon SpeechRecognizer'da olduğundan ayrıca
        // kayıt açılamaz; düğme animasyonu bu değerle beslenir.
        override fun onRmsChanged(rmsdB: Float) {
            val level = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
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
            if (!text.isNullOrBlank()) lastPartial = text
            commitPartial()
            segmentEnded = false
            speechSink?.success(mapOf("text" to accumulated.toString()))
            // Tanıyıcı her sessizlikte kendini kapatır; kullanıcı hâlâ
            // konuşuyorsa kaldığı yerden devam etsin diye yeniden başlatılır.
            // ponytail: yeniden başlatma sırasında ~200 ms sağırlık var; sorun
            // olursa Android 13+ EXTRA_SEGMENTED_SESSION'a geçilir.
            if (listening) startRecognizer(locale)
        }

        override fun onError(error: Int) {
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
                startRecognizer(locale)
                return
            }
            if (listening) {
                speechSink?.error("speech_error", "Konuşma tanıma hatası: $error", null)
            }
        }

        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
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
