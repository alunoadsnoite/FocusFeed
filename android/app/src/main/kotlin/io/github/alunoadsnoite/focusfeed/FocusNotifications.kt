package io.github.alunoadsnoite.focusfeed

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

object FocusNotifications {
    fun enabled(c: Context): Boolean {
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return (Build.VERSION.SDK_INT < 33 || c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) && manager.areNotificationsEnabled()
    }
    private fun open(c: Context) = PendingIntent.getActivity(c, 0, Intent(c, MainActivity::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    fun ongoing(c: Context, phase: String): Notification {
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel("focus", "Monitor de foco", NotificationManager.IMPORTANCE_LOW))
        val stop = PendingIntent.getBroadcast(c, 1, Intent(c, SessionReceiver::class.java).setAction("focusfeed.STOP"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, "focus") else {
            @Suppress("DEPRECATION") Notification.Builder(c)
        }
        return builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (phase == "reward") "FocusFeed: recompensa ativa" else "FocusFeed: bloqueio ativo")
            .setContentText(if (phase == "reward") "Redes liberadas temporariamente." else "Toque para voltar ao FocusFeed.")
            .setContentIntent(open(c)).setOngoing(true)
            .addAction(Notification.Action.Builder(null, "Parar", stop).build()).build()
    }
    fun alert(c: Context, event: SessionEvent) {
        if (!enabled(c)) return
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel("results", "Conclusão e recompensa", NotificationManager.IMPORTANCE_DEFAULT))
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, "results") else {
            @Suppress("DEPRECATION") Notification.Builder(c)
        }
        manager.notify(event.id.hashCode(), builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(event.title).setContentText(event.message).setStyle(Notification.BigTextStyle().bigText(event.message))
            .setContentIntent(open(c)).setAutoCancel(true).build())
    }
    fun drain(c: Context, progress: SessionProgress) {
        if (progress.events.isEmpty()) return
        progress.events.toList().forEach { alert(c, it) }
        progress.events.clear()
        NativeSessionRepository.save(c, progress)
    }
}
