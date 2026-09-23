package dev.kaimau.notlar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.format.DateFormat
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.Date

/**
 * **BUGÜN** widget'ı (kullanıcı isteği 2026-09-23: "günlük brifing widget'ı —
 * ana ekranda bugünün hatırlatıcıları").
 *
 * Dart tarafı (WidgetService) önümüzdeki günlerin hatırlatıcılarını
 * `widget_today` anahtarına "epochMillis<TAB>başlık" satırları olarak yazar.
 * BUGÜNE ait olanlar burada, ÇİZİM ANINDA süzülür: gece yarısı geçince
 * uygulama hiç açılmasa da widget doğru günü gösterir (saatlik
 * `updatePeriodMillis` onUpdate'i yeniden çağırır — ağ yok, uygulama
 * başlatılmaz; yalnız kayıtlı metin yeniden okunur).
 *
 * Geçmiş saatteki hatırlatıcılar soluk değil, üstü çizili de değil — yalnız
 * sırası korunur; bugünün tamamı bir bakışta görünsün.
 */
class TodayWidgetProvider : AppWidgetProvider() {

    private val rowIds = intArrayOf(
        R.id.today_row_1,
        R.id.today_row_2,
        R.id.today_row_3,
        R.id.today_row_4
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val start = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val dayStart = start.timeInMillis
        start.add(Calendar.DAY_OF_YEAR, 1)
        val dayEnd = start.timeInMillis
        val timeFormat = DateFormat.getTimeFormat(context)

        val today = data.getString("widget_today", "")
            .orEmpty()
            .split("\n")
            .mapNotNull { line ->
                val tab = line.indexOf('\t')
                if (tab <= 0) return@mapNotNull null
                val at = line.substring(0, tab).toLongOrNull() ?: return@mapNotNull null
                if (at < dayStart || at >= dayEnd) return@mapNotNull null
                at to line.substring(tab + 1)
            }
            .sortedBy { it.first }

        val dateLabel = DateFormat.getLongDateFormat(context).format(Date())

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_widget).apply {
                setTextViewText(R.id.today_date, dateLabel)
                setTextViewText(
                    R.id.today_count,
                    if (today.isEmpty()) "" else today.size.toString()
                )
                setViewVisibility(
                    R.id.today_empty,
                    if (today.isEmpty()) View.VISIBLE else View.GONE
                )
                rowIds.forEachIndexed { index, rowId ->
                    val item = today.getOrNull(index)
                    setViewVisibility(rowId, if (item == null) View.GONE else View.VISIBLE)
                    if (item != null) {
                        setTextViewText(
                            rowId,
                            "${timeFormat.format(Date(item.first))}  ${item.second}"
                        )
                    }
                }
                // Dördü aşan hatırlatıcılar: "+N daha".
                val more = today.size - rowIds.size
                setViewVisibility(R.id.today_more, if (more > 0) View.VISIBLE else View.GONE)
                if (more > 0) {
                    setTextViewText(
                        R.id.today_more,
                        context.getString(R.string.widget_today_more, more)
                    )
                }

                WidgetTheme.paletteFor(context)?.let { palette ->
                    setBackgroundRes(R.id.today_root, palette.background)
                    setTextColor(R.id.today_title, palette.onSurface)
                    setTextColor(R.id.today_date, palette.onSurfaceMuted)
                    setTextColor(R.id.today_count, palette.onSurfaceMuted)
                    setTextColor(R.id.today_empty, palette.onSurfaceMuted)
                    setTextColor(R.id.today_more, palette.onSurfaceMuted)
                    rowIds.forEach { rowId ->
                        setBackgroundRes(rowId, palette.rowBackground)
                        setTextColor(rowId, palette.onSurface)
                    }
                }

                // Dokunuş Hatırlatıcılar ekranını açar.
                val intent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("notlar://reminders"),
                    context,
                    MainActivity::class.java
                )
                val pending = PendingIntent.getActivity(
                    context,
                    4,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.today_root, pending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
