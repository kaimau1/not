package dev.kaimau.notlar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * Sesli Not Asistanı widget'ı: tek mikrofon düğmesi. Dokununca uygulama
 * doğrudan sesli not ekranıyla açılır (notlar://voice) — kayıt biter bitmez
 * yapay zeka notu oluşturur. 1x1'den başlar, istenen boyuta çekilebilir.
 */
class VoiceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.voice_widget).apply {
                setOnClickPendingIntent(
                    R.id.voice_widget_root,
                    deepLinkIntent(context, "notlar://voice", requestCode = 10)
                )
                WidgetTheme.paletteFor(context)?.let { palette ->
                    setBackgroundRes(R.id.voice_widget_root, palette.micBackground)
                    setIconTint(R.id.voice_widget_mic, palette.onAccent)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/** notlar:// derin bağlantısını MainActivity'de açan PendingIntent üretir. */
internal fun deepLinkIntent(
    context: Context,
    uri: String,
    requestCode: Int
): PendingIntent {
    val intent = Intent(
        Intent.ACTION_VIEW,
        Uri.parse(uri),
        context,
        MainActivity::class.java
    )
    return PendingIntent.getActivity(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}
