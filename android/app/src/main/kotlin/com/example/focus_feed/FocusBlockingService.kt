package com.example.focus_feed

import android.app.Service
import android.app.KeyguardManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

class FocusBlockingService : Service() {
    companion object { @Volatile var running = false }
    private val main = Handler(Looper.getMainLooper())
    private lateinit var overlay: BlockingOverlay
    private var foreground: String? = null
    private var cursor = 0L
    private var phase = ""
    private var destroyed = false
    private var generation = 0
    private val poll = object : Runnable {
        override fun run() {
            if (destroyed) return
            val token = generation
            NativeSessionRepository.worker.execute {
                try {
                    val p = NativeSessionRepository.advance(this@FocusBlockingService)
                    if (!NativeAccess.canBlock(this@FocusBlockingService) && SessionEngine.active(p.session)) {
                        SessionEngine.interrupt(p, "Permissão revogada. Monitor interrompido e foco pausado.")
                        NativeSessionRepository.save(this@FocusBlockingService, p)
                    }
                    FocusNotifications.drain(this@FocusBlockingService, p)
                    val active = SessionEngine.active(p.session) && NativeAccess.canBlock(this@FocusBlockingService)
                    val currentPhase = p.session.phase
                    val selected = p.apps.filterValues { it }.keys.toSet()
                    val balance = p.rewardSeconds
                    main.post {
                        if (destroyed || token != generation) return@post
                        if (!active) { overlay.hide(); stopSelf(); return@post }
                        try {
                            if (phase != currentPhase) {
                                phase = currentPhase
                                promote(phase)
                            }
                            val now = System.currentTimeMillis()
                            val events = (getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager).queryEvents(cursor, now)
                            val event = UsageEvents.Event()
                            while (events.hasNextEvent()) {
                                events.getNextEvent(event)
                                @Suppress("DEPRECATION")
                                when (event.eventType) {
                                    UsageEvents.Event.MOVE_TO_FOREGROUND -> foreground = event.packageName
                                    UsageEvents.Event.MOVE_TO_BACKGROUND -> if (foreground == event.packageName) foreground = null
                                }
                            }
                            cursor = now
                            val screen = (getSystemService(POWER_SERVICE) as PowerManager).isInteractive
                            val unlocked = !(getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked
                            if (currentPhase != "reward" && screen && unlocked && foreground in selected && foreground != packageName) overlay.show(balance == 0L)
                            else overlay.hide()
                            main.postDelayed(this, 500)
                        } catch (_: Exception) { failClosedSession("Monitor indisponível. Retome o foco no app.") }
                    }
                } catch (_: Exception) { main.post { if (!destroyed) failClosedSession("Falha ao salvar a sessão. Retome pelo app.") } }
            }
        }
    }
    override fun onCreate() {
        super.onCreate()
        running = true
        overlay = BlockingOverlay(this)
        foreground = packageName
        cursor = System.currentTimeMillis()
        // Must promote promptly, before asynchronous disk work.
        promote("focus")
    }
    private fun promote(phase: String) {
        val notification = FocusNotifications.ongoing(this, phase)
        if (Build.VERSION.SDK_INT >= 34) startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(1, notification)
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        generation++
        main.removeCallbacksAndMessages(null)
        overlay.hide()
        main.post(poll)
        return START_STICKY
    }
    private fun failClosedSession(message: String) {
        overlay.hide()
        NativeSessionRepository.worker.execute {
            try {
                val p = NativeSessionRepository.load(this)
                SessionEngine.interrupt(p, message)
                NativeSessionRepository.save(this, p)
            } finally { main.post { stopSelf() } }
        }
    }
    override fun onDestroy() {
        destroyed = true
        running = false
        generation++
        main.removeCallbacksAndMessages(null)
        overlay.hide()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
    override fun onBind(intent: Intent?): IBinder? = null
}
