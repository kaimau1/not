package dev.kaimau.notlar

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Typeface
import android.net.Uri
import android.util.Log
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * "ANA EKRANA YERLEŞTİR" (kullanıcı isteği 2026-10-28): notu başlatıcıya
 * sabit kısayol olarak koyar. Dokunulunca `notlar://note/<id>` açılır —
 * konum hatırlatıcısı ve Gemini işlevleriyle aynı yol (router.dart; kilitli
 * not kilitli açılır). Simge notun renginde: ortada kıvrık köşeli sayfa ve
 * başlığın baş harfi, ana ekranda hangi not olduğu bir bakışta anlaşılsın.
 */
object NotKisayolu {
    private val KIMLIK = Regex("[A-Za-z0-9_-]{1,128}")

    fun destekleniyor(context: Context): Boolean =
        ShortcutManagerCompat.isRequestPinShortcutSupported(context)

    fun sabitle(context: Context, id: String, baslik: String, renk: Int, harf: String): Boolean {
        if (!KIMLIK.matches(id)) return false
        if (!ShortcutManagerCompat.isRequestPinShortcutSupported(context)) return false
        val ad = baslik.trim().ifEmpty { "Not" }
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("notlar://note/$id"),
            context,
            MainActivity::class.java
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return try {
            val bilgi = ShortcutInfoCompat.Builder(context, "note_$id")
                .setShortLabel(ad.take(24))
                .setLongLabel(ad.take(80))
                .setIcon(IconCompat.createWithAdaptiveBitmap(simge(renk, harf)))
                .setIntent(intent)
                .build()
            ShortcutManagerCompat.requestPinShortcut(context, bilgi, null)
        } catch (e: Exception) {
            Log.w("NotlarKisayol", "Kisayol eklenemedi: ${e.javaClass.simpleName}")
            false
        }
    }

    /** 108 dp'lik uyarlanabilir simge (432 px): ortadaki güvenli dairede sayfa. */
    private fun simge(renk: Int, harf: String): Bitmap {
        val boy = 432
        val bmp = Bitmap.createBitmap(boy, boy, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.drawColor(renk or 0xFF000000.toInt())
        val w = 176f
        val h = 208f
        val sol = (boy - w) / 2f
        val ust = (boy - h) / 2f
        val kat = 52f
        val r = 22f
        val sayfa = Path()
        sayfa.moveTo(sol + r, ust)
        sayfa.lineTo(sol + w - kat, ust)
        sayfa.lineTo(sol + w, ust + kat)
        sayfa.lineTo(sol + w, ust + h - r)
        sayfa.quadTo(sol + w, ust + h, sol + w - r, ust + h)
        sayfa.lineTo(sol + r, ust + h)
        sayfa.quadTo(sol, ust + h, sol, ust + h - r)
        sayfa.lineTo(sol, ust + r)
        sayfa.quadTo(sol, ust, sol + r, ust)
        sayfa.close()
        val golge = Paint(Paint.ANTI_ALIAS_FLAG)
        golge.color = Color.argb(46, 0, 0, 0)
        c.save()
        c.translate(0f, 9f)
        c.drawPath(sayfa, golge)
        c.restore()
        val beyaz = Paint(Paint.ANTI_ALIAS_FLAG)
        beyaz.color = Color.WHITE
        c.drawPath(sayfa, beyaz)
        val kivrim = Path()
        kivrim.moveTo(sol + w - kat, ust)
        kivrim.lineTo(sol + w - kat, ust + kat - 12f)
        kivrim.quadTo(sol + w - kat, ust + kat, sol + w - kat + 12f, ust + kat)
        kivrim.lineTo(sol + w, ust + kat)
        kivrim.close()
        val gri = Paint(Paint.ANTI_ALIAS_FLAG)
        gri.color = Color.rgb(224, 224, 224)
        c.drawPath(kivrim, gri)
        val yazi = Paint(Paint.ANTI_ALIAS_FLAG)
        yazi.color = koyu(renk)
        yazi.textSize = 104f
        yazi.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        yazi.textAlign = Paint.Align.CENTER
        val metin = harf.ifEmpty { "N" }
        val y = ust + h / 2f + 8f - (yazi.descent() + yazi.ascent()) / 2f
        c.drawText(metin, boy / 2f, y, yazi)
        return bmp
    }

    /** Harf rengi: zeminin koyulaştırılmış hâli (açık not renginde okunur). */
    private fun koyu(renk: Int): Int {
        val r = (Color.red(renk) * 0.42f).toInt()
        val g = (Color.green(renk) * 0.42f).toInt()
        val b = (Color.blue(renk) * 0.42f).toInt()
        return Color.rgb(r, g, b)
    }
}
