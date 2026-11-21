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
 * **AKILLI LİSTE** ana ekran aracı (AL-6 / P97): en güncel açık alışveriş veya
 * kontrol listesini, kalan madde sayısını ve ilk 5 işaretlenmemiş maddesini
 * gösterir. Karta dokununca liste notu doğrudan açılır; `+` düğmesi hızlı ekle
 * levhasını (`notlar://ekle`) başlatır.
 */
class SmartListWidgetProvider : AppWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.smart_list_row_1,
        R.id.smart_list_row_2,
        R.id.smart_list_row_3,
        R.id.smart_list_row_4,
        R.id.smart_list_row_5
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val noteId = data.getString("widget_list_id", "").orEmpty().trim()
        val rawTitle = data.getString("widget_list_title", "").orEmpty().trim()
        val remaining = data.getString("widget_list_remaining", "0")?.toIntOrNull() ?: 0
        val total = data.getString("widget_list_total", "0")?.toIntOrNull() ?: 0
        val items = data.getString("widget_list_items", "")
            .orEmpty()
            .split("\n")
            .filter { it.isNotBlank() }

        val title = rawTitle.ifEmpty { context.getString(R.string.widget_smart_list_label) }
        val badge = when {
            noteId.isEmpty() -> ""
            remaining > 0 -> context.getString(R.string.widget_smart_list_remaining, remaining)
            total > 0 -> context.getString(R.string.widget_smart_list_done)
            else -> ""
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.smart_list_widget).apply {
                setTextViewText(R.id.smart_list_title, title)
                setTextViewText(R.id.smart_list_count, badge)

                val showEmpty = items.isEmpty()
                setViewVisibility(
                    R.id.smart_list_empty,
                    if (showEmpty) View.VISIBLE else View.GONE
                )
                if (showEmpty) {
                    val emptyText = if (noteId.isNotEmpty() && total > 0) {
                        context.getString(R.string.widget_smart_list_all_done)
                    } else {
                        context.getString(R.string.widget_smart_list_empty)
                    }
                    setTextViewText(R.id.smart_list_empty, emptyText)
                }

                rowIds.forEachIndexed { index, rowId ->
                    val item = items.getOrNull(index)
                    setViewVisibility(rowId, if (item == null) View.GONE else View.VISIBLE)
                    if (item != null) {
                        setTextViewText(rowId, "☐ $item")
                    }
                }

                val more = remaining - rowIds.size
                setViewVisibility(
                    R.id.smart_list_more,
                    if (more > 0) View.VISIBLE else View.GONE
                )
                if (more > 0) {
                    setTextViewText(
                        R.id.smart_list_more,
                        context.getString(R.string.widget_smart_list_more, more)
                    )
                }

                WidgetTheme.paletteFor(context)?.let { palette ->
                    setBackgroundRes(R.id.smart_list_root, palette.background)
                    setTextColor(R.id.smart_list_title, palette.onSurface)
                    setTextColor(R.id.smart_list_count, palette.onSurfaceMuted)
                    setTextColor(R.id.smart_list_empty, palette.onSurfaceMuted)
                    setTextColor(R.id.smart_list_more, palette.onSurfaceMuted)
                    setBackgroundRes(R.id.smart_list_add, palette.micButton)
                    setIconTint(R.id.smart_list_add, palette.onAccent)
                    rowIds.forEach { rowId ->
                        setBackgroundRes(rowId, palette.rowBackground)
                        setTextColor(rowId, palette.onSurface)
                    }
                }

                // Karta dokununca etkin liste açılır; açık liste yoksa yeni kontrol listesi.
                val openUri = if (noteId.isNotEmpty()) {
                    Uri.parse("notlar://note/$noteId")
                } else {
                    Uri.parse("notlar://new?type=checklist")
                }
                val openIntent = Intent(
                    Intent.ACTION_VIEW,
                    openUri,
                    context,
                    MainActivity::class.java
                )
                val openPending = PendingIntent.getActivity(
                    context,
                    17,
                    openIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.smart_list_root, openPending)

                // "+" düğmesi: Hızlı ekle levhası (yaz ya da söyle, listeye düşsün).
                val addIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("notlar://ekle"),
                    context,
                    MainActivity::class.java
                )
                val addPending = PendingIntent.getActivity(
                    context,
                    18,
                    addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.smart_list_add, addPending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
