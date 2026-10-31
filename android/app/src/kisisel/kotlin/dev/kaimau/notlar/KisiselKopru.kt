package dev.kaimau.notlar

import android.content.Context

/** Kişisel derlemenin MainActivity kancası: oturumsuzken sıraya alınan köprü notları yazılır. */
object KisiselKopru {
    fun basla(ctx: Context) = HaritaNotAlici.flushPending(ctx)
}
