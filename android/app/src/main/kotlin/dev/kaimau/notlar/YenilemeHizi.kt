package dev.kaimau.notlar

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewGroup

/**
 * Yüksek yenileme hızı (kullanıcı isteği 2026-11-16: "120 Hz desteği").
 *
 * İki ayrı, belgelenmiş istek birlikte verilir:
 * 1. Pencere: `WindowManager.LayoutParams.preferredDisplayModeId` (API 23) —
 *    AYNI çözünürlükteki en hızlı mod (çözünürlük değişmez).
 * 2. Flutter'ın çizdiği yüzey: `Surface.setFrameRate` (API 30) — bazı OEM'ler
 *    (MIUI/HyperOS) pencere tercihini uygulama başına hız listesiyle eziyor;
 *    yüzey oyu SurfaceFlinger'a doğrudan gider.
 *
 * **120 tavanı:** 144 Hz modu olsa da 120 seçilir — not uygulamasında 144'ün
 * görünür getirisi yok, kare başı iş %20 artar (pil/ısınma). Aynı çözünürlükte
 * 120 ve altı mod yoksa en hızlısı.
 *
 * Yüzey yeniden doğunca ve ekran modu/çözünürlüğü değişince istek yinelenir.
 */
class YenilemeHizi(private val activity: Activity) :
    DisplayManager.DisplayListener, SurfaceHolder.Callback {
    // Dart kararı gelene dek (pil tasarrufu → false) hiçbir şey istenmez.
    private var yuksek: Boolean? = null
    private var dinliyor = false
    private var yuzey: SurfaceView? = null
    private var sonOzet = ""
    // Yüzeye en son verilen oy (belge: setFrameRate sık çağrılmaz).
    private var yuzeyHz = -1f

    private val ekran: Display?
        get() = if (Build.VERSION.SDK_INT >= 30) {
            activity.display
        } else {
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay
        }

    /** Dart'tan: [yuksek] false = sistemin seçimi (pil tasarrufu). Özet döner. */
    fun uygula(yuksek: Boolean): String {
        this.yuksek = yuksek
        if (!dinliyor) {
            (activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager)
                .registerDisplayListener(this, Handler(Looper.getMainLooper()))
            dinliyor = true
        }
        return tazele()
    }

    /** O an ekranın gerçek yenileme hızı (Ayarlar → sürüm satırı). */
    fun etkinHz(): Double? = try {
        ekran?.refreshRate?.toDouble()
    } catch (_: Exception) {
        null
    }

    fun birak() {
        if (dinliyor) {
            (activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager)
                .unregisterDisplayListener(this)
            dinliyor = false
        }
        yuzey?.holder?.removeCallback(this)
        yuzey = null
    }

    private fun tazele(): String = try {
        val d = ekran
        if (d == null) {
            "ekran yok"
        } else {
            val etkin = d.mode
            val hedef = if (yuksek == true) hedefMod(d.supportedModes, etkin) else null
            val id = hedef?.modeId ?: 0
            val w = activity.window
            if (w.attributes.preferredDisplayModeId != id) {
                w.attributes = w.attributes.apply { preferredDisplayModeId = id }
            }
            yuzeyeUygula(hedef?.refreshRate ?: 0f)
            val ozet = "etkin ${etkin.refreshRate} Hz (mod ${etkin.modeId}, " +
                "${etkin.physicalWidth}x${etkin.physicalHeight}) · istenen " +
                (hedef?.let { "${it.refreshRate} Hz (mod ${it.modeId})" } ?: "sistem") +
                " · modlar " + d.supportedModes.joinToString("/") {
                    "${it.physicalWidth}x${it.physicalHeight}@${it.refreshRate.toInt()}"
                }
            // `adb logcat -s NotlarEkran` — yalnız değişince (LTPO ekranlar
            // onDisplayChanged'i sık yollar).
            if (ozet != sonOzet) {
                sonOzet = ozet
                Log.i("NotlarEkran", ozet)
            }
            ozet
        }
    } catch (e: Exception) {
        Log.w("NotlarEkran", "uygulanamadi", e)
        "hata: ${e.message}"
    }

    private fun yuzeyeUygula(hz: Float) {
        if (Build.VERSION.SDK_INT < 30) return
        var sv = yuzey
        if (sv == null || !sv.isAttachedToWindow) {
            sv?.holder?.removeCallback(this)
            sv = yuzeyBul(activity.window.decorView)
            sv?.holder?.addCallback(this)
            yuzey = sv
            yuzeyHz = -1f
        }
        val s = sv?.holder?.surface ?: return
        if (s.isValid && hz != yuzeyHz) {
            s.setFrameRate(hz, Surface.FRAME_RATE_COMPATIBILITY_DEFAULT)
            yuzeyHz = hz
        }
    }

    // Flutter'ın çizim yüzeyi (FlutterSurfaceView) görünüm ağacındaki ilk
    // SurfaceView'dir.
    private fun yuzeyBul(v: View): SurfaceView? {
        if (v is SurfaceView) return v
        if (v is ViewGroup) {
            for (i in 0 until v.childCount) yuzeyBul(v.getChildAt(i))?.let { return it }
        }
        return null
    }

    override fun onDisplayChanged(displayId: Int) {
        if (yuksek != null && displayId == ekran?.displayId) tazele()
    }

    override fun onDisplayAdded(displayId: Int) {}
    override fun onDisplayRemoved(displayId: Int) {}

    override fun surfaceCreated(holder: SurfaceHolder) {
        yuzeyHz = -1f // yeni yüzey oyu taşımaz
        if (yuksek != null) tazele()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}
    override fun surfaceDestroyed(holder: SurfaceHolder) {}

    companion object {
        private const val TAVAN_HZ = 120.5f

        /** Etkin modla AYNI çözünürlükte, 120 Hz'i aşmayan en hızlı mod. */
        fun hedefMod(modlar: Array<Display.Mode>, etkin: Display.Mode): Display.Mode? {
            val ayni = modlar.filter {
                it.physicalWidth == etkin.physicalWidth &&
                    it.physicalHeight == etkin.physicalHeight
            }
            return ayni.filter { it.refreshRate <= TAVAN_HZ }.ifEmpty { ayni }
                .maxByOrNull { it.refreshRate }
        }
    }
}
