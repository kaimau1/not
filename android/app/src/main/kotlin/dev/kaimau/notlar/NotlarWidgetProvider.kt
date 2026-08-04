package dev.kaimau.notlar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Ana ekran widget'ı: son notların başlıklarını gösterir, dokununca
 * uygulamayı açar. Veriler Dart tarafından (WidgetService) yazılır.
 *
 * Başlıklar tek bir metin yığını olarak gelir (satır başıyla ayrılmış) ve
 * burada SABİT sayıda satır görünümüne dağıtılır. RemoteViews kendi başına
 * dinamik liste kuramaz — o, ayrı bir RemoteViewsService ister; dört satır
 * için o altyapıyı kurmak gereksiz ağırlıktı.
 */
class NotlarWidgetProvider : AppWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.widget_row_1,
        R.id.widget_row_2,
        R.id.widget_row_3,
        R.id.widget_row_4
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val titles = data.getString("widget_notes", "")
            .orEmpty()
            .split("\n")
            .filter { it.isNotBlank() }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.notlar_widget).apply {
                setTextViewText(R.id.widget_count, data.getString("widget_count", ""))

                // Not kalmadıysa satır kartları yerine tek satırlık bilgi metni.
                setViewVisibility(
                    R.id.widget_empty,
                    if (titles.isEmpty()) View.VISIBLE else View.GONE
                )
                if (titles.isEmpty()) {
                    setTextViewText(
                        R.id.widget_empty,
                        context.getString(R.string.widget_no_notes)
                    )
                }
                rowIds.forEachIndexed { index, rowId ->
                    val title = titles.getOrNull(index)
                    setViewVisibility(rowId, if (title == null) View.GONE else View.VISIBLE)
                    if (title != null) setTextViewText(rowId, title)
                }

                // Uygulamada sistemden farklı bir tema seçiliyse renkleri
                // çalışma anında uygula (bkz. WidgetTheme).
                WidgetTheme.paletteFor(context)?.let { palette ->
                    setBackgroundRes(R.id.widget_root, palette.background)
                    setTextColor(R.id.widget_title, palette.onSurface)
                    setTextColor(R.id.widget_count, palette.onSurfaceMuted)
                    setTextColor(R.id.widget_empty, palette.onSurfaceMuted)
                    setBackgroundRes(R.id.widget_mic, palette.micButton)
                    setIconTint(R.id.widget_mic, palette.onAccent)
                    rowIds.forEach { rowId ->
                        setBackgroundRes(rowId, palette.rowBackground)
                        setTextColor(rowId, palette.onSurface)
                    }
                }

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
