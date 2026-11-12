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
    fun ongoing(c: Context, phase: String, remaining: Long = 0, total: Long = 0): Notification {
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val text = AppLanguage.resources(c)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel("focus", text.getString(R.string.channel_focus), NotificationManager.IMPORTANCE_LOW))
        val stop = PendingIntent.getBroadcast(c, 1, Intent(c, SessionReceiver::class.java).setAction("focusfeed.STOP"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val pause = PendingIntent.getBroadcast(c, 2, Intent(c, SessionReceiver::class.java).setAction("focusfeed.PAUSE"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, "focus") else {
            @Suppress("DEPRECATION") Notification.Builder(c)
        }
        builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (phase == "reward") text.getString(R.string.notification_reward) else text.getString(R.string.notification_block))
            .setContentText(
                when {
                    phase == "reward" -> text.getString(R.string.notification_unblocked)
                    phase == "focus" && remaining > 0 -> text.getString(R.string.notification_remaining, SessionEngine.label(remaining))
                    else -> text.getString(R.string.notification_open)
                }
            )
            .setContentIntent(open(c)).setOngoing(true)
        if (phase == "focus") builder.addAction(Notification.Action.Builder(null, text.getString(R.string.notification_pause), pause).build())
        builder.addAction(Notification.Action.Builder(null, text.getString(R.string.notification_stop), stop).build())
        if (total > 0) {
            val done = (total - remaining).coerceIn(0, total)
            builder.setProgress(1000, ((done * 1000) / total).toInt(), false)
        }
        return builder.build()
    }
    fun alert(c: Context, event: SessionEvent) {
        if (!enabled(c)) return
        val manager = c.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val text = AppLanguage.resources(c)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(
            NotificationChannel("results", text.getString(R.string.channel_results), NotificationManager.IMPORTANCE_DEFAULT))
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(c, "results") else {
            @Suppress("DEPRECATION") Notification.Builder(c)
        }
        // The queue can contain notifications created before language selection existed.
        val (title, body) = when {
            event.id.startsWith("reward-") ->
                text.getString(R.string.notification_reward_end) to text.getString(R.string.notification_reward_body)
            event.id.startsWith("focus-") && event.message.startsWith("Foco concluído! Você ganhou ") ->
                text.getString(R.string.notification_focus_end) to text.getString(
                    R.string.notification_focus_body,
                    event.message.removePrefix("Foco concluído! Você ganhou ").removeSuffix(".")
                )
            event.id == "reboot" ->
                text.getString(R.string.notification_interrupted) to text.getString(R.string.notification_reboot)
            else -> event.title to event.message
        }
        manager.notify(event.id.hashCode(), builder.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title).setContentText(body).setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(open(c)).setAutoCancel(true).build())
    }
    fun drain(c: Context, progress: SessionProgress) {
        if (progress.events.isEmpty()) return
        progress.events.toList().forEach { alert(c, it) }
        progress.events.clear()
        NativeSessionRepository.save(c, progress)
    }
}
