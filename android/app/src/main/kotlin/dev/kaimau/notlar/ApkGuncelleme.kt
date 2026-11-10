package dev.kaimau.notlar

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import java.io.File

/**
 * **UYGULAMANIN KENDİ GÜNCELLEMESİ — PackageInstaller oturumu** (2026-11-10,
 * kullanıcı: *"oto güncelleme doğru çalışmıyor, dosya okuyucuda iyi çalışıyor,
 * onun gibi yapalım"*; kaynak: dosya-okuyucu `ci/ApkKurulum.kt`).
 *
 * ESKİDEN: indirilen APK `ACTION_VIEW` ile sistemin paket yükleyicisine
 * veriliyordu — her güncellemede onay penceresi, sonuç Dart'a hiç dönmüyordu
 * ("started" deyip bitiyordu; kullanıcı vazgeçti mi, kurulum düştü mü belli
 * değildi).
 *
 * ŞİMDİ: APK bir kurulum oturumuna yazılır ve commit edilir. Android 12+'da
 * `USER_ACTION_NOT_REQUIRED` istenir: bu uygulama kurulumun sahibiyse (bir
 * kez kendi kendini güncelledikten sonra) onay penceresi ÇIKMADAN kurulur;
 * değilse sistem tek dokunuşluk "Güncelle" sorar — Android'in kuralı.
 *
 * Sonuç: `done` · `aborted` · `need_permission` (bilinmeyen kaynak izni
 * ekranı açıldı) · `missing` · `unsupported` · `error:<ileti>`.
 */
object ApkGuncelleme {
    private const val ACTION = "dev.kaimau.notlar.APK_GUNCELLEME"
    private val main = Handler(Looper.getMainLooper())

    fun install(activity: Activity, path: String, done: (String) -> Unit) {
        val file = File(path)
        if (!file.isFile) {
            done("missing"); return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !activity.packageManager.canRequestPackageInstalls()
        ) {
            try {
                activity.startActivity(
                    Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                        .setData(Uri.parse("package:" + activity.packageName))
                )
            } catch (_: Exception) {
            }
            done("need_permission"); return
        }
        val ctx = activity.applicationContext
        Thread {
            var session: PackageInstaller.Session? = null
            try {
                val installer = ctx.packageManager.packageInstaller
                val params = PackageInstaller.SessionParams(
                    PackageInstaller.SessionParams.MODE_FULL_INSTALL
                )
                params.setAppPackageName(ctx.packageName)
                if (Build.VERSION.SDK_INT >= 31) {
                    params.setRequireUserAction(
                        PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED
                    )
                }
                val id = installer.createSession(params)
                val s = installer.openSession(id)
                session = s
                s.openWrite("base.apk", 0, file.length()).use { out ->
                    file.inputStream().use { it.copyTo(out, 1 shl 16) }
                    s.fsync(out)
                }
                main.post { commit(activity, s, id, done) }
            } catch (e: Exception) {
                try {
                    session?.abandon()
                } catch (_: Exception) {
                }
                main.post { done("error:" + (e.message ?: e.javaClass.simpleName)) }
            }
        }.start()
    }

    private fun commit(
        activity: Activity,
        session: PackageInstaller.Session,
        id: Int,
        done: (String) -> Unit,
    ) {
        val ctx = activity.applicationContext
        val action = "$ACTION.$id"
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE
                )
                if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                    @Suppress("DEPRECATION")
                    val confirm = if (Build.VERSION.SDK_INT >= 33) {
                        intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                    } else {
                        intent.getParcelableExtra(Intent.EXTRA_INTENT)
                    }
                    if (confirm != null) {
                        try {
                            activity.startActivity(
                                confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                        } catch (e: Exception) {
                            finish(c, this, done, "error:" + (e.message ?: "confirm"))
                        }
                    }
                    return
                }
                val result = when (status) {
                    PackageInstaller.STATUS_SUCCESS -> "done"
                    PackageInstaller.STATUS_FAILURE_ABORTED -> "aborted"
                    else -> "error:" + (
                        intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                            ?: "status $status")
                }
                finish(c, this, done, result)
            }
        }
        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= 33) {
            ctx.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            ctx.registerReceiver(receiver, filter)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
        val pi = PendingIntent.getBroadcast(
            ctx, id, Intent(action).setPackage(ctx.packageName), flags
        )
        try {
            session.commit(pi.intentSender)
            session.close()
        } catch (e: Exception) {
            finish(ctx, receiver, done, "error:" + (e.message ?: e.javaClass.simpleName))
        }
    }

    private fun finish(c: Context, r: BroadcastReceiver, done: (String) -> Unit, v: String) {
        try {
            c.applicationContext.unregisterReceiver(r)
        } catch (_: Exception) {
        }
        done(v)
    }
}
