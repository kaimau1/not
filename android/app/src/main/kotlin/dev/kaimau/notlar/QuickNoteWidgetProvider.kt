package dev.kaimau.notlar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Hızlı Not widget'ı: tek düğme. Dokununca uygulama doğrudan YENİ bir metin
 * notu editörüyle açılır (notlar://new?type=text) — ana ekrandan tek dokunuşla
 * yazmaya başla. Veri göstermediği için hiç periyodik güncellenmez (pil dostu).
 */
class QuickNoteWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_note_widget).apply {
                setOnClickPendingIntent(
                    R.id.quick_note_root,
                    deepLinkIntent(context, "notlar://new?type=text", requestCode = 30)
                )
                WidgetTheme.paletteFor(context)?.let { palette ->
                    setBackgroundRes(R.id.quick_note_root, palette.noteBackground)
                    setIconTint(R.id.quick_note_icon, palette.onNote)
                    setTextColor(R.id.quick_note_label, palette.onNote)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
