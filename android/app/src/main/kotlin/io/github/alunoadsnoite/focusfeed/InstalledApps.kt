package io.github.alunoadsnoite.focusfeed

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import java.io.ByteArrayOutputStream

object InstalledApps {
    private data class CachedIcon(val version: Long, val encoded: String)

    // A lista é recarregada ao abrir o app; decodificar/encodar todos os ícones
    // novamente a cada initialize é caro. O cache é invalidado por atualização
    // do pacote e vive apenas no processo.
    private val iconCache = mutableMapOf<String, CachedIcon>()

    fun list(c: Context): List<Map<String, String>> {
        val pm = c.packageManager
        @Suppress("DEPRECATION")
        return pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
            .distinctBy { it.activityInfo.packageName }
            .filter { it.activityInfo.packageName != c.packageName && it.activityInfo.enabled }
            .map { app ->
                val pkg = app.activityInfo.packageName
                val label = app.loadLabel(pm).toString()
                mapOf("package" to pkg, "label" to label, "icon" to icon(pm, pkg, app))
            }.sortedBy { it["label"]?.lowercase() }
    }

    private fun icon(pm: android.content.pm.PackageManager, pkg: String, app: android.content.pm.ResolveInfo): String {
        val version = try {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(pkg, 0).lastUpdateTime
        } catch (_: Exception) {
            0L
        }
        iconCache[pkg]?.let { if (it.version == version) return it.encoded }
        val encoded = try {
            val drawable = app.loadIcon(pm)
            val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
            drawable.setBounds(0, 0, 64, 64)
            drawable.draw(Canvas(bitmap))
            val bytes = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
            bitmap.recycle()
            Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            ""
        }
        iconCache[pkg] = CachedIcon(version, encoded)
        return encoded
    }
}
