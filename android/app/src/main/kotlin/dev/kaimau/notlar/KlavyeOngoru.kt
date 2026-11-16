package dev.kaimau.notlar

import android.os.Build
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsAnimationCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Klavye ÖNGÖRÜSÜ (kullanıcı 2026-11-16: "alt panoyu Keep'teki gibi yapalım,
 * daha iyisini"): IME animasyonu BAŞLARKEN klavyenin varacağı yüksekliği ve
 * süreyi Dart'a bildirir — alt panel klavyeyi kare kare kovalamak yerine
 * hedefe kısa bir eğriyle önceden gider (`keyboard_snap.dart`, kip `k`).
 *
 * Belge (developer.android.com "Control and animate the software keyboard"):
 * `onStart` çağrıldığında yerleşim ve kök inset'ler BİTİŞ durumundadır →
 * `getRootWindowInsets` görünürlük ve hedef IME yüksekliğini verir.
 *
 * Geri çağrı pencerenin decorView'una, DISPATCH_MODE_CONTINUE_ON_SUBTREE ile
 * kurulur: alt ağaçtaki FlutterView'un kendi geri çağrısı (motorun inset
 * işleyişi) aynen çağrılmaya devam eder; inset'lere dokunulmaz.
 * Yalnız API 30+: daha eskide androidx uyumluluk katmanı geri çağrıyı
 * görünümün OnApplyWindowInsetsListener'ına bağlar ve decorView'unkini ezer —
 * orada Dart son bilinen klavye yüksekliğine düşer.
 */
object KlavyeOngoru {
    fun kur(view: View, kanal: () -> MethodChannel?) {
        if (Build.VERSION.SDK_INT < 30) return
        val ime = WindowInsetsCompat.Type.ime()
        ViewCompat.setWindowInsetsAnimationCallback(
            view,
            object : WindowInsetsAnimationCompat.Callback(DISPATCH_MODE_CONTINUE_ON_SUBTREE) {
                override fun onStart(
                    animation: WindowInsetsAnimationCompat,
                    bounds: WindowInsetsAnimationCompat.BoundsCompat,
                ): WindowInsetsAnimationCompat.BoundsCompat {
                    if (animation.typeMask and ime != 0) {
                        val son = ViewCompat.getRootWindowInsets(view)
                        if (son != null) {
                            val acik = son.isVisible(ime)
                            kanal()?.invokeMethod(
                                "start",
                                mapOf(
                                    "open" to acik,
                                    // Fiziksel piksel; Dart devicePixelRatio'ya böler.
                                    "target" to if (acik) son.getInsets(ime).bottom else 0,
                                    "ms" to animation.durationMillis,
                                ),
                            )
                        }
                    }
                    return bounds
                }

                override fun onProgress(
                    insets: WindowInsetsCompat,
                    runningAnimations: MutableList<WindowInsetsAnimationCompat>,
                ): WindowInsetsCompat = insets
            },
        )
    }
}
