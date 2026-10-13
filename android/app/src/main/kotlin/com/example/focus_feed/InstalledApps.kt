package com.example.focus_feed

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import java.io.ByteArrayOutputStream

object InstalledApps {
    fun list(c: Context): List<Map<String, String>> {
        val pm = c.packageManager
        @Suppress("DEPRECATION")
        return pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
            .distinctBy { it.activityInfo.packageName }
            .filter { it.activityInfo.packageName != c.packageName && it.activityInfo.enabled }
            .map { app ->
                val icon = try {
                    val drawable = app.loadIcon(pm)
                    val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
                    drawable.setBounds(0, 0, 64, 64)
                    drawable.draw(Canvas(bitmap))
                    val bytes = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
                    bitmap.recycle()
                    Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP)
                } catch (_: Exception) { "" }
                mapOf("package" to app.activityInfo.packageName, "label" to app.loadLabel(pm).toString(), "icon" to icon)
            }.sortedBy { it["label"]?.lowercase() }
    }
}
