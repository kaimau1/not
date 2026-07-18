package dev.kaimau.notlar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
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
            if (!text.isNullOrBlank()) {
                if (accumulated.isNotEmpty()) accumulated.append(' ')
                accumulated.append(text)
            }
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
            if (benign && listening) {
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
        override fun onEndOfSpeech() {}
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun firstResult(results: Bundle?): String? =
        results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.firstOrNull()

    // Biriken tamamlanmış metin + o anki kısmi metin.
    private fun joined(partial: String): String =
        if (accumulated.isEmpty()) partial else "$accumulated $partial"
}
