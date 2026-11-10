package dev.kaimau.notlar

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * **GÜNCELLEMEDEN SONRA YENİDEN AÇ** (2026-11-10, kullanıcı: *"oto güncellemeden
 * sonra uygulama kapanıyor, otomatik geri açılsın"*).
 *
 * Android, kendini güncelleyen uygulamanın sürecini kurulumda öldürür; yeni
 * sürüm kendiliğinden açılmaz. [ApkGuncelleme] commit'ten hemen önce
 * [mark] ile işaret bırakır; sistem yeni sürümü kurunca
 * `MY_PACKAGE_REPLACED` gönderir ve bu alıcı — işaret tazeyse (elle Play/adb
 * kurulumunda açılmasın diye) — ana ekranı yeniden açar.
 *
 * Android 10+ arka plandan etkinlik başlatmayı çoğu cihazda engeller; bu
 * yüzden aynı anda "Güncellendi — açmak için dokun" bildirimi de konur
 * (kişisel derlemede tam ekran niyetiyle: kilitliyken doğrudan açılır).
 * Uygulama açılınca bildirim [clear] ile kalkar.
 */
object GuncellemeSonrasiAc {
    private const val PREFS = "notlar_guncelleme"
    private const val KEY = "relaunch_at"
    private const val CHANNEL = "app_update"
    private const val NOTIFICATION_ID = 0x6E07
    private const val FRESH_MS = 15 * 60_000L

    // Senkron yazım bilerek: commit'ten hemen sonra kurulum süreci öldürür.
    @SuppressLint("ApplySharedPref")
    fun mark(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong(KEY, System.currentTimeMillis()).commit()
    }

    fun unmark(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(KEY).apply()
    }

    fun clear(context: Context) {
        try {
            NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }

    internal fun onReplaced(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val at = prefs.getLong(KEY, 0L)
        prefs.edit().remove(KEY).apply()
        val age = System.currentTimeMillis() - at
        if (at == 0L || age < 0 || age > FRESH_MS) return
        val open = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        notify(context, open)
        try {
            context.startActivity(open)
        } catch (_: Exception) {
            // Arka plandan başlatma engellendi: bildirim duruyor.
        }
    }

    @SuppressLint("MissingPermission")
    private fun notify(context: Context, open: Intent) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL) == null
        ) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    context.getString(R.string.update_channel_name),
                    NotificationManager.IMPORTANCE_HIGH
                )
            )
        }
        val pi = PendingIntent.getActivity(
            context, NOTIFICATION_ID, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val canFullScreen = if (Build.VERSION.SDK_INT >= 34) {
            manager.canUseFullScreenIntent()
        } else {
            true
        }
        val builder = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notlar)
            .setContentTitle(context.getString(R.string.update_done_title))
            .setContentText(context.getString(R.string.update_done_body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(true)
            .setTimeoutAfter(10 * 60_000L)
            .setContentIntent(pi)
        if (canFullScreen) builder.setFullScreenIntent(pi, true)
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // Bildirim izni kapalı: yalnız doğrudan açma denenir.
        }
    }
}

/** `MY_PACKAGE_REPLACED`: kendi güncellememizden sonra uygulamayı yeniden açar. */
class GuncellemeSonrasiAlici : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            GuncellemeSonrasiAc.onReplaced(context)
        }
    }
}
