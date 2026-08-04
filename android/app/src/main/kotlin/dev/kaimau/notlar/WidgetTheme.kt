package dev.kaimau.notlar

import android.content.Context
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Widget'ın uygulamanın TEMASINI giymesi.
 *
 * KÖK NEDEN: widget renkleri yalnız kaynak niteleyicilerinden (values/ ve
 * values-night/) geliyordu; onları seçen şey SİSTEM gece modudur. Kullanıcı
 * uygulamada "Koyu" seçip telefonu açık modda bıraktığında uygulama koyu,
 * widget kağıt duruyordu (tersi de aynı).
 *
 * ÇÖZÜM: Dart tarafı geçerli temayı `widget_theme` anahtarına yazar
 * ("light" / "dark" / "system"); sağlayıcı sistemden FARKLI bir seçim varsa
 * renkleri ve zemin çizimlerini çalışma anında uygular. "system" seçiliyken
 * hiçbir şey yapılmaz — niteleyiciler zaten doğru olanı seçiyor ve gereksiz
 * `setInt` çağrıları RemoteViews'ı büyütür.
 *
 * NOT: renkler `setTextColor`/`setInt` ile uygulanıyor, zeminler ise HAZIR
 * çizim kaynağı değiştirilerek (`setBackgroundResource`). Zemini düz renge
 * çevirmek köşe yarıçapını ve 1px kenarlığı yok ederdi; API 31 öncesinde
 * (minSdk 23) çizimi çalışma anında boyayacak bir RemoteViews yolu yok.
 */
data class WidgetPalette(
    val background: Int,
    val rowBackground: Int,
    val micButton: Int,
    val noteBackground: Int,
    val micBackground: Int,
    val onSurface: Int,
    val onSurfaceMuted: Int,
    val onAccent: Int,
    val onNote: Int,
    val icon: Int,
    val iconAccent: Int,
)

object WidgetTheme {

    /**
     * Uygulanacak palet; "system" seçiliyse (ya da hiç yazılmamışsa) null —
     * çağıran o zaman hiçbir şeye dokunmaz.
     */
    fun paletteFor(context: Context): WidgetPalette? {
        val choice = HomeWidgetPlugin.getData(context)
            .getString("widget_theme", "system")
        val dark = when (choice) {
            "light" -> false
            "dark" -> true
            else -> return null
        }
        fun color(res: Int) = ContextCompat.getColor(context, res)
        return if (dark) {
            WidgetPalette(
                background = R.drawable.widget_background_dark,
                rowBackground = R.drawable.widget_row_background_dark,
                micButton = R.drawable.widget_mic_button_dark,
                noteBackground = R.drawable.widget_note_background_dark,
                micBackground = R.drawable.widget_mic_background_dark,
                onSurface = color(R.color.widget_dark_on_surface),
                onSurfaceMuted = color(R.color.widget_dark_on_surface_muted),
                onAccent = color(R.color.widget_dark_on_accent),
                onNote = color(R.color.widget_dark_on_note),
                icon = color(R.color.widget_dark_icon),
                iconAccent = color(R.color.widget_dark_icon_accent),
            )
        } else {
            WidgetPalette(
                background = R.drawable.widget_background_light,
                rowBackground = R.drawable.widget_row_background_light,
                micButton = R.drawable.widget_mic_button_light,
                noteBackground = R.drawable.widget_note_background_light,
                micBackground = R.drawable.widget_mic_background_light,
                onSurface = color(R.color.widget_light_on_surface),
                onSurfaceMuted = color(R.color.widget_light_on_surface_muted),
                onAccent = color(R.color.widget_light_on_accent),
                onNote = color(R.color.widget_light_on_note),
                icon = color(R.color.widget_light_icon),
                iconAccent = color(R.color.widget_light_icon_accent),
            )
        }
    }
}

/** `View.setBackgroundResource` — RemotableViewMethod, minSdk 23'te güvenli. */
fun RemoteViews.setBackgroundRes(viewId: Int, resId: Int) =
    setInt(viewId, "setBackgroundResource", resId)

/** `ImageView.setColorFilter(int)` — düzendeki `android:tint` karşılığı. */
fun RemoteViews.setIconTint(viewId: Int, color: Int) =
    setInt(viewId, "setColorFilter", color)
