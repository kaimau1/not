package dev.kaimau.notlar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/**
 * Hızlı Eylemler widget'ı: yeni metin notu, alışveriş listesi, sıralı liste
 * ve sesli not — hepsi ana ekrandan tek dokunuşla. Veri göstermediği için
 * hiç periyodik güncellenmez (pil dostu).
 */
class QuickActionsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_actions_widget).apply {
                setOnClickPendingIntent(
                    R.id.qa_new_note,
                    deepLinkIntent(context, "notlar://new?type=text", requestCode = 20)
                )
                setOnClickPendingIntent(
                    R.id.qa_checklist,
                    deepLinkIntent(context, "notlar://new?type=checklist", requestCode = 21)
                )
                setOnClickPendingIntent(
                    R.id.qa_ordered,
                    deepLinkIntent(context, "notlar://new?type=ordered", requestCode = 22)
                )
                setOnClickPendingIntent(
                    R.id.qa_mic,
                    deepLinkIntent(context, "notlar://voice", requestCode = 23)
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
