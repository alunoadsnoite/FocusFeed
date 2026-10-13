package io.github.alunoadsnoite.focusfeed

import android.app.AppOpsManager
import android.content.Context
import android.os.Process
import android.provider.Settings

object NativeAccess {
    fun usage(c: Context): Boolean {
        val ops = c.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        @Suppress("DEPRECATION")
        return ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), c.packageName) == AppOpsManager.MODE_ALLOWED
    }
    fun canBlock(c: Context) = usage(c) && Settings.canDrawOverlays(c)
}
