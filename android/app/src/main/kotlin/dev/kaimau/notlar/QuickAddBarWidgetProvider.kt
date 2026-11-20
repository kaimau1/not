package dev.kaimau.notlar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Hızlı ekle çubuğu, 4×1 (HE-3, PLAN §1.4/3): arama çubuğu gibi "+ Hızlı ekle:
 * yaz ya da söyle". Dokununca HIZLI EKLE levhası açılır (notlar://ekle).
 * Veri göstermez; periyodik güncelleme yok. 1×1: [QuickAddWidgetProvider].
 */
class QuickAddBarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val views = RemoteViews(context.packageName, R.layout.quick_add_bar_widget).apply {
            setOnClickPendingIntent(
                R.id.quick_add_bar_root,
                deepLinkIntent(context, "notlar://ekle", requestCode = 50)
            )
            WidgetTheme.paletteFor(context)?.let { palette ->
                setBackgroundRes(R.id.quick_add_bar_root, palette.background)
                setIconTint(R.id.quick_add_bar_icon, palette.iconAccent)
                setTextColor(R.id.quick_add_bar_label, palette.onSurfaceMuted)
            }
        }
        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
