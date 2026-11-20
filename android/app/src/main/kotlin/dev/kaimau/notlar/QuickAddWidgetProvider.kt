package dev.kaimau.notlar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Hızlı ekle widget'ı, 1×1 (HE-3, PLAN §1.4/3): tek "+" düğmesi. Dokununca
 * uygulama HIZLI EKLE levhasıyla açılır (notlar://ekle) — yaz ya da söyle,
 * seçtiğin nota eklensin. Veri göstermez; periyodik güncelleme yok.
 * 4×1 çubuk: [QuickAddBarWidgetProvider].
 */
class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
            setOnClickPendingIntent(
                R.id.quick_add_root,
                deepLinkIntent(context, "notlar://ekle", requestCode = 50)
            )
            WidgetTheme.paletteFor(context)?.let { palette ->
                setBackgroundRes(R.id.quick_add_root, palette.noteBackground)
                setIconTint(R.id.quick_add_icon, palette.onNote)
            }
        }
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
