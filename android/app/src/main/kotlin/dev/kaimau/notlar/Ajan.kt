package dev.kaimau.notlar

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import androidx.annotation.RequiresApi
import androidx.appfunctions.AppFunctionDeclaration
import androidx.appfunctions.AppFunctionInvalidArgumentException
import androidx.appfunctions.AppFunctionPermissionRequiredException
import androidx.appfunctions.AppFunctionSerializable
import androidx.appfunctions.AppFunctionService
import androidx.appfunctions.AppFunctionServiceEntryPoint
import com.google.android.gms.tasks.Tasks
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.Source
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale
import java.util.concurrent.TimeUnit

/*
 * Gemini gibi bir ajanın Notlar'ı açmadan kullanabileceği işlevler (Android 16+ AppFunctions).
 * Harita köprüsüyle aynı yol: Flutter motoru açılmaz, yerel Firestore SDK'sı yazar/okur
 * ([YerelNot]); çevrimdışıyken yazım diskteki kuyrukta bekler.
 *
 * GİZLİLİK: kilitli notlar ve gizli klasörlerdeki notlar ajana HİÇ gösterilmez — kilit ve
 * gizleme, notun uygulama dışına çıkmaması için var; ajan da uygulama dışıdır.
 * KDoc'lar ajanın okuduğu açıklamadır; işlevin ne zaman seçileceğini o belirler.
 */

/** A note in the Notlar app. */
@AppFunctionSerializable(isDescribedByKDoc = true)
data class AjanNot(
    /** The note id. */
    val id: String,
    /** The note title; may be empty. */
    val title: String,
    /** The note text; checklist items are given one per line, checked ones prefixed with "[x]". */
    val text: String,
)

/** Launch intentToOpen to show the note in Notlar. */
@AppFunctionSerializable(isDescribedByKDoc = true)
data class AjanAcma(
    /** Launch this to open the note in the Notlar app. */
    val intentToOpen: PendingIntent,
    /** The note id that will open. */
    val noteId: String,
)

@RequiresApi(36)
@AppFunctionServiceEntryPoint(serviceName = "AjanServisi", appFunctionXmlFileName = "notlar_ajan")
abstract class AjanTemel : AppFunctionService() {

    /**
     * Creates a new text note in the Notlar app.
     *
     * @param text The note content.
     * @param title Optional title; leave empty for an untitled note.
     * @return The created note.
     */
    @AppFunctionDeclaration(isDescribedByKDoc = true)
    suspend fun createNote(text: String, title: String?): AjanNot = withContext(Dispatchers.IO) {
        if (text.isBlank()) throw AppFunctionInvalidArgumentException("text boş olamaz")
        val uid = uid()
        val doc = kullanici(uid).collection("notes").document()
        // Sunucu onayı beklenmez: yazım yerelde hemen geçerli, çevrimdışıyken kuyrukta bekler
        doc.set(YerelNot.belge(uid, title?.trim().orEmpty(), text.trim(), null, System.currentTimeMillis()))
        AjanNot(doc.id, title?.trim().orEmpty(), text.trim())
    }

    /**
     * Searches the user's notes in the Notlar app by words in the title or text.
     *
     * @param query Words to look for (all must appear, case-insensitive).
     * @return Up to 10 matching notes, most recently edited first.
     */
    @AppFunctionDeclaration(isDescribedByKDoc = true)
    suspend fun searchNotes(query: String): List<AjanNot> = withContext(Dispatchers.IO) {
        val kelimeler = query.lowercase(TR).split(Regex("\\s+")).filter { it.isNotEmpty() }
        if (kelimeler.isEmpty()) throw AppFunctionInvalidArgumentException("query boş olamaz")
        gorunurNotlar(SON_SINIR).filter { n ->
            val metin = (n.title + "\n" + n.text).lowercase(TR)
            kelimeler.all { it in metin }
        }.take(10)
    }

    /**
     * Lists the user's most recently edited notes in the Notlar app.
     *
     * @return Up to 10 notes, most recent first.
     */
    @AppFunctionDeclaration(isDescribedByKDoc = true)
    suspend fun recentNotes(): List<AjanNot> = withContext(Dispatchers.IO) { gorunurNotlar(10) }

    /**
     * Opens a note in the Notlar app (a locked note still asks for its lock).
     *
     * @param noteId Id from searchNotes, recentNotes or createNote.
     */
    @AppFunctionDeclaration(isDescribedByKDoc = true)
    fun openNote(noteId: String): AjanAcma {
        if (!KIMLIK.matches(noteId)) throw AppFunctionInvalidArgumentException("Geçersiz not kimliği: $noteId")
        // router.dart › notlar://note/<id>: konum hatırlatıcısının bildirimiyle aynı yol
        val i = Intent(Intent.ACTION_VIEW, Uri.parse("notlar://note/$noteId"), this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val pi = PendingIntent.getActivity(this, noteId.hashCode(), i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return AjanAcma(pi, noteId)
    }

    private fun uid(): String = FirebaseAuth.getInstance().currentUser?.uid
        ?: throw AppFunctionPermissionRequiredException("Notlar'da oturum açık değil; uygulamayı açıp giriş yapın")

    private fun kullanici(uid: String): DocumentReference = YerelNot.firestore().collection("users").document(uid)

    /** Silinmemiş, arşivlenmemiş, kilitsiz ve gizli klasörde olmayan son notlar. */
    private fun gorunurNotlar(sinir: Int): List<AjanNot> {
        val user = kullanici(uid())
        val gizli = oku(user.collection("folders").whereEqualTo("hidden", true))
            .map { it.id }.toSet()
        // Sıralama cihazda: deletedAt eşitliği + updatedAt sıralaması bileşik dizin isterdi
        // (Dart tarafı da aynı tek filtreyle okuyor, bkz. notes_repository.dart)
        val notlar = oku(user.collection("notes").whereEqualTo("deletedAt", null))
            .sortedByDescending { it.getTimestamp("updatedAt")?.toDate()?.time ?: Long.MAX_VALUE }
        return notlar.asSequence()
            .filter { it.get("archivedAt") == null && it.getBoolean("locked") != true }
            .filter { it.getString("folderId")?.let { f -> f in gizli } != true }
            .map(::ajanNot)
            .take(sinir)
            .toList()
    }

    // Önce sunucu (taze), ağ yoksa önbellek: ajan cevabı çevrimdışıyken de dönebilsin
    private fun oku(q: Query): List<DocumentSnapshot> =
        runCatching { Tasks.await(q.get(), 8, TimeUnit.SECONDS).documents }
            .getOrElse { Tasks.await(q.get(Source.CACHE), 3, TimeUnit.SECONDS).documents }

    private fun ajanNot(d: DocumentSnapshot): AjanNot {
        val govde = d.getString("body").orEmpty()
        @Suppress("UNCHECKED_CAST")
        val maddeler = (d.get("items") as? List<Map<String, Any?>>).orEmpty().joinToString("\n") { m ->
            (if (m["checked"] == true) "[x] " else "") + (m["text"] as? String).orEmpty()
        }
        return AjanNot(d.id, d.getString("title").orEmpty(), listOf(govde, maddeler).filter { it.isNotBlank() }.joinToString("\n"))
    }

    private companion object {
        val TR: Locale = Locale.forLanguageTag("tr")
        /** Firestore otomatik kimliği (20 harf/rakam); yol enjeksiyonuna karşı. */
        val KIMLIK = Regex("[A-Za-z0-9_-]{1,64}")
        /** Aramanın taradığı en yeni not sayısı (Firestore'da tam metin araması yok). */
        const val SON_SINIR = 500
    }
}
