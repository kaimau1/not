package dev.kaimau.notlar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth (biyometrik not kilidi) FragmentActivity gerektirir.
// Ek olarak Ayarlar'daki "İzinler" bölümü için küçük bir sistem köprüsü
// (MethodChannel) sağlar: mikrofon iznini SORMADAN denetleme ve sistem
// ayarı ekranlarını (uygulama detayları / pil optimizasyonu) açma.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dev.kaimau.notlar/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
}
