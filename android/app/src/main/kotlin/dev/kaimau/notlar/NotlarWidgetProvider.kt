package dev.kaimau.notlar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Ana ekran widget'ı: son notların başlıklarını gösterir, dokununca
 * uygulamayı açar. Veriler Dart tarafından (WidgetService) yazılır.
 */
class NotlarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.notlar_widget).apply {
                setTextViewText(R.id.widget_notes, data.getString("widget_notes", "Henüz not yok"))
                setTextViewText(R.id.widget_count, data.getString("widget_count", ""))

                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launchIntent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                // Mikrofon: sesli not yakalama ekranını doğrudan açar.
                val voiceIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("notlar://voice"),
                    context,
                    MainActivity::class.java
                )
                val voicePendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    voiceIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_mic, voicePendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
