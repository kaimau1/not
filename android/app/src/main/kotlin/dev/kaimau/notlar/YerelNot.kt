package dev.kaimau.notlar

import com.google.android.gms.tasks.Tasks
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.PersistentCacheSettings
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.Source
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Flutter motoru açılmadan, yerel Firestore SDK'sıyla not yazıp okumanın ORTAK yolu.
 * İki kullanıcısı var: kişisel köprü (src/kisisel, yalnız kişisel derlemede:
 * Harita, Kanallarım, Asistan) ve ajan işlevleri ([AjanTemel], Gemini). Şema `Note.toMap`'in yazdığıyla aynı alanları
 * taşır; Dart tarafında yeni zorunlu bir alan eklenirse burası da güncellenir.
 */
object YerelNot {
    /**
     * Flutter'ın main.dart'ta verdiği ayarın AYNISI (persistence + 100 MB,
     * AppConstants.firestoreCacheBytes). Örnek bu süreçte ilk burada
     * başlarsa FlutterFire aynı ayarı yeniden verir; Firestore AYNI ayara
     * izin verir, FARKLI ayarda istisna atar — değer değişirse burası da.
     */
    private const val CACHE_BYTES = 100L * 1024 * 1024

    fun firestore(): FirebaseFirestore {
        val db = FirebaseFirestore.getInstance()
        runCatching {
            db.firestoreSettings = FirebaseFirestoreSettings.Builder()
                .setLocalCacheSettings(PersistentCacheSettings.newBuilder().setSizeBytes(CACHE_BYTES).build())
                .build()
        }
        return db
    }

    /** Düz metin notunun belgesi; [folderId] null ise klasörsüz. */
    fun belge(uid: String, title: String, body: String, folderId: String?, atMs: Long): HashMap<String, Any?> =
        hashMapOf(
            "schema" to 1,
            "type" to "text",
            "title" to title,
            "body" to body,
            "items" to emptyList<Any>(),
            "attachments" to emptyList<Any>(),
            "tags" to emptyList<Any>(),
            "folderId" to folderId,
            "color" to "default",
            "frameColor" to "default",
            "pinned" to false,
            "starred" to false,
            "locked" to false,
            "orderIndex" to -atMs.toDouble(),
            "createdAt" to FieldValue.serverTimestamp(),
            "updatedAt" to FieldValue.serverTimestamp(),
            "deletedAt" to null,
            "archivedAt" to null,
            "reminderAt" to null,
            "createdBy" to uid,
            "updatedBy" to uid,
        )

    /** Uygulama dışına verilebilen not: kimlik, başlık, metin (maddeler satır satır), son düzenleme (ms). */
    class Gorunen(val id: String, val title: String, val text: String, val updatedMs: Long)

    private val TR: Locale = Locale.forLanguageTag("tr")
    private val BOSLUK = Regex("\\s+")

    /**
     * Silinmemiş, arşivlenmemiş, KİLİTSİZ ve GİZLİ klasörde olmayan son notlar (en yeni önce).
     * GİZLİLİK: kilit ve gizleme notun uygulama dışına çıkmaması için var; ajan da köprü de dışarıdır.
     */
    fun gorunurNotlar(uid: String, sinir: Int): List<Gorunen> {
        val user = firestore().collection("users").document(uid)
        val gizli = oku(user.collection("folders").whereEqualTo("hidden", true)).map { it.id }.toSet()
        // Sıralama cihazda: deletedAt eşitliği + updatedAt sıralaması bileşik dizin isterdi
        // (Dart tarafı da aynı tek filtreyle okuyor, bkz. notes_repository.dart)
        val notlar = oku(user.collection("notes").whereEqualTo("deletedAt", null))
            .sortedByDescending { it.getTimestamp("updatedAt")?.toDate()?.time ?: Long.MAX_VALUE }
        return notlar.asSequence()
            .filter { it.get("archivedAt") == null && it.getBoolean("locked") != true }
            .filter { it.getString("folderId")?.let { f -> f in gizli } != true }
            .map(::gorunen)
            .take(sinir)
            .toList()
    }

    /** Söylenen kelimeleri (büyük/küçük harf duyarsız) HEPSİ başlıkta ya da metinde geçen notlar. */
    fun ara(notlar: List<Gorunen>, sorgu: List<String>): List<Gorunen> {
        val kelimeler = sorgu.flatMap { it.lowercase(TR).split(BOSLUK) }.filter { it.isNotEmpty() }
        if (kelimeler.isEmpty()) return emptyList()
        return notlar.filter { n ->
            val metin = (n.title + "\n" + n.text).lowercase(TR)
            kelimeler.all { it in metin }
        }
    }

    // Önce sunucu (taze), ağ yoksa önbellek: cevap çevrimdışıyken de dönebilsin
    private fun oku(q: Query): List<DocumentSnapshot> =
        runCatching { Tasks.await(q.get(), 8, TimeUnit.SECONDS).documents }
            .getOrElse { Tasks.await(q.get(Source.CACHE), 3, TimeUnit.SECONDS).documents }

    private fun gorunen(d: DocumentSnapshot): Gorunen {
        val govde = d.getString("body").orEmpty()
        @Suppress("UNCHECKED_CAST")
        val maddeler = (d.get("items") as? List<Map<String, Any?>>).orEmpty().joinToString("\n") { m ->
            (if (m["checked"] == true) "[x] " else "") + (m["text"] as? String).orEmpty()
        }
        return Gorunen(
            d.id, d.getString("title").orEmpty(), listOf(govde, maddeler).filter { it.isNotBlank() }.joinToString("\n"),
            d.getTimestamp("updatedAt")?.toDate()?.time ?: 0L,
        )
    }
}
