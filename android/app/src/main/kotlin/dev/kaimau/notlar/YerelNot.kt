package dev.kaimau.notlar

import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.PersistentCacheSettings

/**
 * Flutter motoru açılmadan, yerel Firestore SDK'sıyla not yazmanın ORTAK yolu.
 * İki kullanıcısı var: Harita köprüsü ([HaritaNotAlici], kişisel) ve ajan
 * işlevleri ([AjanTemel], Gemini). Şema `Note.toMap`'in yazdığıyla aynı alanları
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
}
