package dev.kaimau.notlar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.tasks.Tasks
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.Source
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * **HARİTA KÖPRÜSÜ — KİŞİSEL ÖZELLİK** (kullanıcı isteği 2026-10-28: "hey harita
 * not al ile not uygulaması ile bağlantı sağlanır, Haritalar klasörüne not
 * alınır, not uygulaması ön plana gelmez").
 *
 * Harita uygulaması (com.harita.ankara, NoteBridge.kt) söyleneni sıralı yayınla
 * gönderir; bu alıcı notu ARKA PLANDA, Flutter motoru açılmadan, yerel Firestore
 * SDK'sıyla `users/{uid}/notes`a yazar (klasör: "Haritalar", yoksa açılır).
 * Notlar öne gelmez. Firestore çevrimdışıyken yazım diskteki kuyrukta bekler.
 * Oturum yoksa not cihazda sıraya alınır, uygulama açılınca ([flushPending],
 * MainActivity.onCreate) yazılır.
 *
 * **GENEL SÜRÜMDE KALDIRILIR**: bu dosya (not yazma ortak [YerelNot]'ta, o
 * Gemini işlevleri için kalır) + AndroidManifest'teki
 * `HaritaNotAlici` girdisi + build.gradle.kts'teki "Harita köprüsü"
 * bağımlılıkları + MainActivity'deki tek `flushPending` satırı. Başka hiçbir
 * yere dokunmaz (HAFIZA.md › Harita köprüsü).
 */
class HaritaNotAlici : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val text = intent.getStringExtra("text")?.trim().orEmpty()
        if (text.isEmpty()) return
        val place = intent.getStringExtra("place")
        val ctx = context.applicationContext
        val result = goAsync()
        Thread {
            val code = try { save(ctx, text, place, System.currentTimeMillis()) } catch (_: Exception) { 0 }
            if (code == 0) queue(ctx, text, place)
            result.resultCode = if (code == 0) QUEUED else code
            result.finish()
        }.start()
    }

    companion object {
        const val ACTION = "dev.kaimau.notlar.HARITA_NOT"
        const val FOLDER_NAME = "Haritalar"
        /** Klasörün sabit kimliği: önbellek boşken (çevrimdışı) ikinci bir "Haritalar" açılmasın. */
        private const val FOLDER_ID = "haritalar"
        const val SAVED = 1
        const val QUEUED = 2
        private const val PREFS = "harita_notlari"

        /** Notu yazar; oturum yoksa 0. Yazım yerelde hemen geçerli, sunucu onayı beklenmez. */
        private fun save(ctx: Context, text: String, place: String?, atMs: Long): Int {
            val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return 0
            val db = YerelNot.firestore()
            val user = db.collection("users").document(uid)
            val folderId = folderFor(user.collection("folders"), uid)
            val doc = user.collection("notes").document()
            // başlıksız, söylenen metin gövdede (kartta olduğu gibi görünür); navigasyondaysa hedef altta
            val body = listOfNotNull(text, place?.let { "($it)" }).joinToString("\n")
            doc.set(YerelNot.belge(uid, "", body, folderId, atMs))
            return SAVED
        }

        /** "Haritalar" adlı klasör (önbellekte varsa o), yoksa sabit kimlikli klasör açılır. */
        private fun folderFor(folders: com.google.firebase.firestore.CollectionReference, uid: String): String {
            val cached = runCatching {
                Tasks.await(folders.whereEqualTo("name", FOLDER_NAME).limit(1).get(Source.CACHE), 3, TimeUnit.SECONDS)
            }.getOrNull()
            cached?.documents?.firstOrNull()?.let { return it.id }
            val own = folders.document(FOLDER_ID)
            val exists = runCatching { Tasks.await(own.get(Source.CACHE), 3, TimeUnit.SECONDS).exists() }.getOrDefault(false)
            if (!exists) {
                own.set(
                    hashMapOf(
                        "name" to FOLDER_NAME, "icon" to "folder", "hidden" to false, "ownerId" to uid,
                        "sharedWith" to emptyList<String>(), "pending" to emptyList<String>(), "roles" to emptyMap<String, String>(),
                        "createdAt" to FieldValue.serverTimestamp(),
                    ),
                    SetOptions.merge(),
                )
            }
            return FOLDER_ID
        }

        private fun queue(ctx: Context, text: String, place: String?) {
            val sp = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            synchronized(this) {
                val arr = runCatching { JSONArray(sp.getString("q", "[]")) }.getOrDefault(JSONArray())
                arr.put(JSONObject().put("t", text).put("p", place ?: "").put("at", System.currentTimeMillis()))
                sp.edit().putString("q", arr.toString()).apply()
            }
        }

        /** Oturum yokken sıraya alınan notlar (uygulama açılınca, arkada). */
        fun flushPending(ctx: Context) {
            val app = ctx.applicationContext
            val sp = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (sp.getString("q", null).isNullOrEmpty()) return
            Thread {
                synchronized(this) {
                    val arr = runCatching { JSONArray(sp.getString("q", "[]")) }.getOrDefault(JSONArray())
                    val left = JSONArray()
                    for (i in 0 until arr.length()) {
                        val o = arr.optJSONObject(i) ?: continue
                        val ok = runCatching { save(app, o.optString("t"), o.optString("p").ifEmpty { null }, o.optLong("at")) }.getOrDefault(0)
                        if (ok == 0) left.put(o)
                    }
                    sp.edit().putString("q", if (left.length() == 0) null else left.toString()).apply()
                }
            }.start()
        }
    }
}
