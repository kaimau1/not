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
 * Kanallarım da (com.kanallarim.app, Not.kt) aynı yolu kullanır: oynatıcıdaki "Not al" ve Harita'nın
 * medya panelindeki not düğmesi "YouTube" klasörüne başlıklı ve sabitlenmiş not yazar (isteğe bağlı
 * `folder`, `title`, `pinned` ekleri; yoksa eski Harita davranışı).
 * **VİDEO NOTU** (kullanıcı isteği 2026-10-29): metinde YouTube bağlantısı varsa ([YouTubeNotu]) not
 * videonun KENDİ notuna (`yt_<videoId>`) yazılır: video üste sabit gömülü, başlık videonun başlığı,
 * her not "dk:sn metin" satırı (dokununca video oraya sarar). Aynı videodan gelen sonraki notlar aynı
 * notun sonuna eklenir.
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
        val note = Gelen(
            text, intent.getStringExtra("place"), intent.getStringExtra("title")?.trim().orEmpty(),
            intent.getStringExtra("folder")?.trim()?.ifEmpty { null } ?: FOLDER_NAME, intent.getBooleanExtra("pinned", false),
        )
        val ctx = context.applicationContext
        val result = goAsync()
        Thread {
            val code = try { save(ctx, note, System.currentTimeMillis()) } catch (_: Exception) { 0 }
            if (code == 0) queue(ctx, note)
            result.resultCode = if (code == 0) QUEUED else code
            result.finish()
        }.start()
    }

    /** Gelen not: Harita'nınki başlıksız ve "Haritalar"da, Kanallarım'ınki başlıklı, sabitli ve "YouTube"da. */
    class Gelen(val text: String, val place: String?, val title: String, val folder: String, val pinned: Boolean)

    companion object {
        const val ACTION = "dev.kaimau.notlar.HARITA_NOT"
        const val FOLDER_NAME = "Haritalar"
        const val SAVED = 1
        const val QUEUED = 2
        private const val PREFS = "harita_notlari"

        /** Notu yazar; oturum yoksa 0. Yazım yerelde hemen geçerli, sunucu onayı beklenmez. */
        private fun save(ctx: Context, n: Gelen, atMs: Long): Int {
            val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return 0
            val db = YerelNot.firestore()
            val user = db.collection("users").document(uid)
            val folderId = folderFor(user.collection("folders"), uid, n.folder)
            YouTubeNotu.parse(n.text)?.let { return saveVideo(ctx, user, uid, n, it, folderId, atMs) }
            val doc = user.collection("notes").document()
            // Harita'dan gelen başlıksız: söylenen metin gövdede (kartta olduğu gibi görünür); navigasyondaysa hedef altta
            val body = listOfNotNull(n.text, n.place?.let { "($it)" }).joinToString("\n")
            doc.set(YerelNot.belge(uid, n.title, body, folderId, atMs).apply { put("pinned", n.pinned) })
            return SAVED
        }

        /**
         * Videonun notu `yt_<videoId>`: varsa (çöpte değilse) yeni satır SONUNA eklenir, yoksa video
         * üste sabitli yeni not açılır. Çöpteki eski not yenisiyle değiştirilir.
         */
        private fun saveVideo(
            ctx: Context, user: com.google.firebase.firestore.DocumentReference, uid: String,
            n: Gelen, v: YouTubeNotu, folderId: String, atMs: Long,
        ): Int {
            val doc = user.collection("notes").document("yt_${v.id}")
            // Sunucu 4 sn'de yanıt vermezse (çevrimdışı) önbellek
            val snap = runCatching { Tasks.await(doc.get(), 4, TimeUnit.SECONDS) }.getOrNull()
                ?: runCatching { Tasks.await(doc.get(Source.CACHE), 2, TimeUnit.SECONDS) }.getOrNull()
            val line = v.line()
            if (snap != null && snap.exists() && snap.get("deletedAt") == null) {
                val old = snap.getString("body").orEmpty().trimEnd()
                val update = hashMapOf<String, Any>(
                    "body" to if (old.isEmpty()) line else "$old\n\n$line",
                    "updatedAt" to FieldValue.serverTimestamp(),
                    "updatedBy" to uid,
                )
                if (n.pinned) update["pinned"] = true
                doc.update(update)
                return SAVED
            }
            val title = YouTubeNotu.videoTitle(n.title)
            val dm = ctx.resources.displayMetrics
            // Sabit bölme: genişlikte 16:9, ekranın %45'ini geçmez (Dart'taki defaultPinnedHeight gibi)
            val pane = minOf(dm.widthPixels / dm.density * 9 / 16, dm.heightPixels / dm.density * 0.45f).coerceAtLeast(96f)
            val video = hashMapOf<String, Any?>(
                "id" to java.util.UUID.randomUUID().toString(),
                "kind" to "video",
                "fileName" to title.ifEmpty { "YouTube" },
                "mimeType" to "video/youtube",
                "storagePath" to "",
                "downloadUrl" to "",
                "sizeBytes" to 0,
                "width" to 16,
                "height" to 9,
                "align" to "center",
                "webUrl" to "https://www.youtube.com/watch?v=${v.id}",
                "pinHeight" to pane.toDouble(),
                "createdAt" to com.google.firebase.Timestamp.now(),
            )
            doc.set(
                YerelNot.belge(uid, title, line, folderId, atMs).apply {
                    put("pinned", n.pinned)
                    put("attachments", listOf(video))
                },
            )
            return SAVED
        }

        /**
         * Adı verilen klasör (önbellekte varsa o), yoksa sabit kimlikli klasör açılır. Sabit kimlik
         * ("haritalar", "youtube"): önbellek boşken (çevrimdışı) aynı adla ikinci bir klasör açılmasın.
         */
        private fun folderFor(folders: com.google.firebase.firestore.CollectionReference, uid: String, name: String): String {
            val cached = runCatching {
                Tasks.await(folders.whereEqualTo("name", name).limit(1).get(Source.CACHE), 3, TimeUnit.SECONDS)
            }.getOrNull()
            cached?.documents?.firstOrNull()?.let { return it.id }
            val own = folders.document(name.lowercase(java.util.Locale.ROOT).filter { it.isLetterOrDigit() }.ifEmpty { "harici" })
            val exists = runCatching { Tasks.await(own.get(Source.CACHE), 3, TimeUnit.SECONDS).exists() }.getOrDefault(false)
            if (!exists) {
                own.set(
                    hashMapOf(
                        "name" to name, "icon" to "folder", "hidden" to false, "ownerId" to uid,
                        "sharedWith" to emptyList<String>(), "pending" to emptyList<String>(), "roles" to emptyMap<String, String>(),
                        "createdAt" to FieldValue.serverTimestamp(),
                    ),
                    SetOptions.merge(),
                )
            }
            return own.id
        }

        private fun queue(ctx: Context, n: Gelen) {
            val sp = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            synchronized(this) {
                val arr = runCatching { JSONArray(sp.getString("q", "[]")) }.getOrDefault(JSONArray())
                arr.put(
                    JSONObject().put("t", n.text).put("p", n.place ?: "").put("at", System.currentTimeMillis())
                        .put("b", n.title).put("k", n.folder).put("s", n.pinned),
                )
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
                        val n = Gelen(
                            o.optString("t"), o.optString("p").ifEmpty { null }, o.optString("b"),
                            o.optString("k").ifEmpty { FOLDER_NAME }, o.optBoolean("s"),
                        )
                        val ok = runCatching { save(app, n, o.optLong("at")) }.getOrDefault(0)
                        if (ok == 0) left.put(o)
                    }
                    sp.edit().putString("q", if (left.length() == 0) null else left.toString()).apply()
                }
            }.start()
        }
    }
}

/**
 * Notun metnindeki YouTube video bağlantısı ([id], başlangıç saniyesi [start]) ve bağlantısız metin
 * ([rest]). Dart'taki `youTubeVideoId`/`youTubeStartSeconds` (lib/core/utils/youtube.dart) ile aynı biçimler.
 */
class YouTubeNotu(val id: String, val start: Int, val rest: String) {
    /** Videonun notundaki satır: "0:51 metin" (damga uygulamada dokunulabilir — video_time.dart). */
    fun line(): String = if (rest.isEmpty()) stamp(start) else "${stamp(start)} $rest"

    companion object {
        private val URL = Regex(
            """(?:https?://)?(?:www\.|m\.|music\.)?(?:youtube\.com|youtu\.be|youtube-nocookie\.com)/[^\s<>"]+""",
            RegexOption.IGNORE_CASE,
        )
        private val ID = Regex("""^[A-Za-z0-9_-]{11}$""")

        fun parse(text: String): YouTubeNotu? {
            for (m in URL.findAll(text)) {
                val url = m.value.trimEnd(')', '.', ',', ';', '!', '?')
                val id = videoId(url) ?: continue
                val rest = text.removeRange(m.range).replace(Regex("""[ \t]+\n"""), "\n")
                    .replace(Regex("""\n{3,}"""), "\n\n").trim()
                return YouTubeNotu(id, startSeconds(url), rest)
            }
            return null
        }

        private fun uri(url: String) =
            runCatching { android.net.Uri.parse(if (url.contains("://")) url else "https://$url") }.getOrNull()

        fun videoId(url: String): String? {
            val uri = uri(url) ?: return null
            val host = uri.host?.lowercase() ?: return null
            val segs = uri.pathSegments
            val id = when {
                host == "youtu.be" -> segs.firstOrNull()
                host == "youtube.com" || host.endsWith(".youtube.com") ||
                    host == "youtube-nocookie.com" || host.endsWith(".youtube-nocookie.com") -> when {
                    segs.firstOrNull() == "watch" -> uri.getQueryParameter("v")
                    segs.size >= 2 && segs[0] in setOf("shorts", "live", "embed", "v", "e") -> segs[1]
                    else -> null
                }
                else -> null
            }
            return id?.takeIf { ID.matches(it) }
        }

        fun startSeconds(url: String): Int {
            val raw = uri(url)?.let { it.getQueryParameter("t") ?: it.getQueryParameter("start") }.orEmpty()
            if (raw.isEmpty()) return 0
            raw.removeSuffix("s").toIntOrNull()?.let { return it }
            val m = Regex("""^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$""").find(raw) ?: return 0
            fun part(i: Int) = m.groupValues[i].toIntOrNull() ?: 0
            return part(1) * 3600 + part(2) * 60 + part(3)
        }

        /** "0:07", "1:23", "1:02:03" — formatVideoTimestamp ile aynı. */
        fun stamp(seconds: Int): String {
            val s = seconds.coerceAtLeast(0)
            val h = s / 3600
            val m = s % 3600 / 60
            val ss = (s % 60).toString().padStart(2, '0')
            return if (h > 0) "$h:${m.toString().padStart(2, '0')}:$ss" else "$m:$ss"
        }

        /** Kanallarım başlığı "video · dk:sn · kanal": yalnız videonun adı kalır. */
        fun videoTitle(title: String): String =
            title.replace(Regex("""\s*·\s*\d{1,2}(?::\d{2}){1,2}\s*·.*$"""), "").trim()
    }
}
