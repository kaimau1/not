package dev.kaimau.notlar

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import org.json.JSONArray
import org.json.JSONObject

/**
 * **KONUMA BAĞLI HATIRLATICI** (kullanıcı isteği 2026-09-23: "markete gelince
 * hatırlat").
 *
 * Sistem geofence'i (Google Play hizmetleri) kullanılır: konumu UYGULAMA
 * izlemez, işletim sistemi izler ve yalnız sınır geçildiğinde bu alıcıyı
 * uyandırır — pil maliyeti uygulamanın kendisi GPS dinlemesinden çok düşük.
 *
 * Kayıt CİHAZA ÖZEL (SharedPreferences): geofence zaten bu telefonun
 * konumuna kurulu; başka cihazda aynı kaydın anlamı yok. Sistem geofence'leri
 * yeniden başlatmada SİLİYOR — [PlaceBootReceiver] kayıttan geri kurar.
 *
 * Hatırlatıcı TEK SEFERLİKTİR: tetiklenince kayıttan ve sistemden düşer (saat
 * hatırlatıcısı da bir kez çalar). Her markete girişte yeniden çalması
 * kullanıcıyı bildirim yağmuruna tutardı.
 */
object PlaceReminders {
    private const val PREFS = "place_reminders"
    private const val KEY = "items"
    const val CHANNEL = "place_reminders"

    data class Item(
        val id: String,
        val lat: Double,
        val lng: Double,
        val radius: Float,
        val exit: Boolean,
        val title: String,
        val body: String,
        val place: String,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("id", id).put("lat", lat).put("lng", lng)
            .put("radius", radius.toDouble()).put("exit", exit)
            .put("title", title).put("body", body).put("place", place)

        fun toMap(): Map<String, Any> = mapOf(
            "id" to id, "lat" to lat, "lng" to lng,
            "radius" to radius.toDouble(), "exit" to exit,
            "title" to title, "body" to body, "place" to place,
        )

        companion object {
            fun fromJson(o: JSONObject) = Item(
                id = o.getString("id"),
                lat = o.getDouble("lat"),
                lng = o.getDouble("lng"),
                radius = o.getDouble("radius").toFloat(),
                exit = o.optBoolean("exit", false),
                title = o.optString("title"),
                body = o.optString("body"),
                place = o.optString("place"),
            )

            fun fromMap(m: Map<*, *>) = Item(
                id = m["id"] as String,
                lat = (m["lat"] as Number).toDouble(),
                lng = (m["lng"] as Number).toDouble(),
                radius = (m["radius"] as Number).toFloat(),
                exit = m["exit"] as? Boolean ?: false,
                title = m["title"] as? String ?: "",
                body = m["body"] as? String ?: "",
                place = m["place"] as? String ?: "",
            )
        }
    }

    fun list(context: Context): List<Item> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, "[]") ?: "[]"
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { Item.fromJson(array.getJSONObject(it)) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun save(context: Context, items: List<Item>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, array.toString()).apply()
    }

    /** Arka planda konum izni var mı (geofence'in uygulama kapalıyken çalışması için şart). */
    fun hasBackground(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

    fun hasForeground(context: Context): Boolean =
        ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PlaceReminderReceiver::class.java)
        // MUTABLE ŞART: sistem tetiklenen geofence bilgisini bu niyete ekliyor.
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
        return PendingIntent.getBroadcast(context, 7301, intent, flags)
    }

    private fun geofence(item: Item): Geofence = Geofence.Builder()
        .setRequestId(item.id)
        .setCircularRegion(item.lat, item.lng, item.radius)
        .setExpirationDuration(Geofence.NEVER_EXPIRE)
        .setTransitionTypes(
            if (item.exit) Geofence.GEOFENCE_TRANSITION_EXIT
            else Geofence.GEOFENCE_TRANSITION_ENTER
        )
        // Sınır boyunca gidip gelen sinyalde ikinci bir tetik olmasın.
        .setNotificationResponsiveness(60_000)
        .build()

    /**
     * Sisteme kurar ve kayda yazar. [done] true/false ya da hata koduyla döner.
     * Aynı kimlikle eskisi varsa DEĞİŞTİRİLİR (not başına bir konum).
     */
    @SuppressLint("MissingPermission")
    fun add(context: Context, item: Item, done: (String?) -> Unit) {
        if (!hasForeground(context)) return done("no_permission")
        if (!hasBackground(context)) return done("no_background")
        val request = GeofencingRequest.Builder()
            .setInitialTrigger(0)
            .addGeofence(geofence(item))
            .build()
        LocationServices.getGeofencingClient(context)
            .addGeofences(request, pendingIntent(context))
            .addOnSuccessListener {
                save(context, list(context).filter { it.id != item.id } + item)
                done(null)
            }
            .addOnFailureListener { e ->
                val code = (e as? com.google.android.gms.common.api.ApiException)?.statusCode
                done(
                    when (code) {
                        GeofenceStatusCodes.GEOFENCE_NOT_AVAILABLE -> "location_off"
                        GeofenceStatusCodes.GEOFENCE_TOO_MANY_GEOFENCES -> "too_many"
                        else -> "failed"
                    }
                )
            }
    }

    fun remove(context: Context, id: String) {
        try {
            LocationServices.getGeofencingClient(context).removeGeofences(listOf(id))
        } catch (_: Exception) {
        }
        save(context, list(context).filter { it.id != id })
    }

    /** Yeniden başlatmadan sonra kayıttaki bütün geofence'leri geri kurar. */
    @SuppressLint("MissingPermission")
    fun restoreAll(context: Context) {
        val items = list(context)
        if (items.isEmpty() || !hasForeground(context) || !hasBackground(context)) return
        val request = GeofencingRequest.Builder()
            .setInitialTrigger(0)
            .addGeofences(items.map { geofence(it) })
            .build()
        try {
            LocationServices.getGeofencingClient(context)
                .addGeofences(request, pendingIntent(context))
        } catch (_: Exception) {
        }
    }

    fun notify(context: Context, item: Item) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL) == null
        ) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL,
                    context.getString(R.string.place_channel_name),
                    NotificationManager.IMPORTANCE_HIGH
                )
            )
        }
        // Dokunuş notu açar (router `notlar://note/<id>`i tanır; kilitli not
        // uygulamadaki olağan yoldan açıldığı için kilit korunur).
        val open = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("notlar://note/${item.id}"),
            context,
            MainActivity::class.java
        )
        val content = PendingIntent.getActivity(
            context,
            item.id.hashCode(),
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(item.title)
            .setContentText(item.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(item.body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(content)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(item.id.hashCode(), notification)
        } catch (_: SecurityException) {
            // Bildirim izni kapalı: yapılacak bir şey yok.
        }
    }
}

/** Sistem geofence tetiğini alır, bildirimi gösterir ve (tek seferlik) kaydı düşürür. */
class PlaceReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) return
        val ids = event.triggeringGeofences?.map { it.requestId } ?: return
        val items = PlaceReminders.list(context)
        for (id in ids) {
            val item = items.firstOrNull { it.id == id } ?: continue
            PlaceReminders.notify(context, item)
            PlaceReminders.remove(context, id)
        }
    }
}

/** Yeniden başlatma / uygulama güncellemesi sonrası geofence'leri geri kurar. */
class PlaceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> PlaceReminders.restoreAll(context)
        }
    }
}
