package dev.kaimau.notlar

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * HIZLI EKLE'YE UYGULAMA DIŞINDAN GİRİŞ (HE-3, PLAN §1.4/3): hepsi aynı
 * `notlar://ekle` derin bağlantısıyla HIZLI EKLE levhasını açar (router.dart,
 * ayrı ekran yok). Metin varsa `metin` sorgusuyla alana yazılı gelir; levha
 * kendiliğinden EKLEMEZ, kullanıcı hedefi görüp Ekle'ye basar.
 */
internal fun hizliEkleIntent(context: Context, metin: String = ""): Intent {
    val uri = Uri.Builder().scheme("notlar").authority("ekle").apply {
        if (metin.isNotEmpty()) appendQueryParameter("metin", metin)
    }.build()
    return Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
}

/**
 * Paylaşım levhasındaki ve metin seçim menüsündeki (PROCESS_TEXT) "Nota ekle".
 * Arayüzü yok: metni alır, MainActivity'yi `notlar://ekle?metin=…` ile açar,
 * kapanır. Ana "Notlar" paylaşım hedefi (yeni not) olduğu gibi kalır.
 */
class NotaEkle : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val gelen = when (intent?.action) {
            Intent.ACTION_PROCESS_TEXT -> intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
            Intent.ACTION_SEND -> intent.getCharSequenceExtra(Intent.EXTRA_TEXT)
            else -> null
        }
        // Uzun paylaşım URI'yi şişirmesin (Dart tarafı da aynı sınırı uygular).
        val metin = gelen?.toString()?.trim().orEmpty().take(SINIR)
        startActivity(hizliEkleIntent(this, metin))
        finish()
    }

    private companion object {
        const val SINIR = 2000
    }
}

/** Hızlı ayar karosu "Hızlı ekle": dokununca panel kapanır, levha açılır. */
@RequiresApi(Build.VERSION_CODES.N)
class HizliEkleKarosu : TileService() {
    override fun onClick() {
        super.onClick()
        if (isLocked) unlockAndRun { ac() } else ac()
    }

    @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
    private fun ac() {
        val intent = hizliEkleIntent(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    60,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
        } else {
            startActivityAndCollapse(intent)
        }
    }
}
