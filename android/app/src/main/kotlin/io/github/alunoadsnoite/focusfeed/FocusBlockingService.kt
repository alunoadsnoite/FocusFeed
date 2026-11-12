package io.github.alunoadsnoite.focusfeed

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
    companion object {
        @Volatile var running = false
    }
    private val main = Handler(Looper.getMainLooper())
    private lateinit var overlay: BlockingOverlay
    private val foreground = ForegroundActivityTracker()
    private var phase = ""
    private var notificationLanguage = ""
    private var destroyed = false
    private var generation = 0

    private val poll: Runnable = object : Runnable {
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
                    val remaining = if (currentPhase == "focus") p.session.focusRemainingSeconds else p.session.rewardRemainingSeconds
                    val total = if (currentPhase == "focus") p.session.focusTotalSeconds else 0L
                    val screen = (getSystemService(POWER_SERVICE) as PowerManager).isInteractive
                    val unlocked = !(getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked

                    // Trabalho de consulta e iteração fica fora do main thread.
                    var foregroundPackage: String? = null
                    if (screen && unlocked && currentPhase != "reward") {
                        val now = System.currentTimeMillis()
                        val events = (getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager)
                            .queryEvents(ForegroundActivityTracker.queryStart(now), now)
                        val event = UsageEvents.Event()
                        while (events.hasNextEvent()) {
                            events.getNextEvent(event)
                            when (event.eventType) {
                                UsageEvents.Event.ACTIVITY_RESUMED -> foreground.resume(
                                    event.packageName, event.className, event.timeStamp)
                                UsageEvents.Event.ACTIVITY_PAUSED -> foreground.pause(
                                    event.packageName, event.className, event.timeStamp)
                            }
                        }
                        foregroundPackage = foreground.packageName
                    }

                    main.post {
                        if (destroyed || token != generation) return@post
                        if (!active) { overlay.hide(); stopSelf(); return@post }
                        try {
                            val language = AppLanguage.tag(this@FocusBlockingService)
                            if (phase != currentPhase || notificationLanguage != language) {
                                phase = currentPhase
                                notificationLanguage = language
                                promote(currentPhase, remaining, total)
                            }
                            val blocked = currentPhase != "reward" && screen && unlocked &&
                                foregroundPackage != null && foregroundPackage in selected &&
                                foregroundPackage != packageName
                            if (blocked) overlay.show(balance == 0L, detail(p)) else overlay.hide()
                            // Com a tela desligada não há mudança visual a detectar.
                            main.postDelayed(this, if (screen) 500L else 2000L)
                        } catch (_: Exception) {
                            failClosedSession("Monitor indisponível. Retome o foco no app.")
                        }
                    }
                } catch (_: Exception) {
                    main.post { if (!destroyed) failClosedSession("Falha ao salvar a sessão. Retome pelo app.") }
                }
            }
        }
    }

    private fun detail(p: SessionProgress): String {
        val s = p.session
        val text = AppLanguage.resources(this)
        return when (s.phase) {
            "focus" -> text.getString(R.string.block_focus, SessionEngine.label(s.focusRemainingSeconds), SessionEngine.label(s.focusTotalSeconds / 5))
            "reward" -> text.getString(R.string.block_reward, SessionEngine.label(s.rewardRemainingSeconds))
            "locked" -> if (p.rewardSeconds > 0)
                text.getString(R.string.block_balance, SessionEngine.label(p.rewardSeconds))
            else
                text.getString(R.string.block_empty)
            else -> ""
        }
    }

    override fun onCreate() {
        super.onCreate()
        running = true
        overlay = BlockingOverlay(this)
        // Must promote promptly, before asynchronous disk work.
        promote("focus")
    }
    private fun promote(phase: String, remaining: Long = 0, total: Long = 0) {
        val notification = FocusNotifications.ongoing(this, phase, remaining, total)
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
