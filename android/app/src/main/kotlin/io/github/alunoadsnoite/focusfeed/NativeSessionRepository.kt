package io.github.alunoadsnoite.focusfeed

import android.content.Context
import android.os.SystemClock
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.Executors

/** All mutations use this executor, including service ticks and reboot handling. */
object NativeSessionRepository {
    val worker = Executors.newSingleThreadExecutor()
    private const val KEY = "progress_v2"
    private var cached: SessionProgress? = null
    private var lastCheckpoint = 0L

    private fun prefs(c: Context) = c.getSharedPreferences("focusfeed_progress", Context.MODE_PRIVATE)
    fun boot(c: Context) = Settings.Global.getInt(c.contentResolver, Settings.Global.BOOT_COUNT, 0)
    fun load(c: Context): SessionProgress {
        cached?.let { return it }
        val stored = prefs(c).getString(KEY, null)
        val old = prefs(c).getString("progress_v1", null)
        val p = if (stored != null) decode(JSONObject(stored)) else if (old != null) migrate(JSONObject(old)) else SessionProgress()
        cached = p
        return p
    }
    fun save(c: Context, p: SessionProgress) {
        check(prefs(c).edit().putString(KEY, encode(p).toString()).commit()) { "Não foi possível salvar o progresso." }
        cached = p
        lastCheckpoint = SystemClock.elapsedRealtime()
    }
    internal fun forgetCacheForTests() { cached = null; lastCheckpoint = 0L }
    fun copy(p: SessionProgress) = decode(encode(p))
    fun advance(c: Context, forceSave: Boolean = false): SessionProgress {
        val p = load(c)
        if (FocusBlockingService.running) p.session.launchGraceElapsed = 0
        val oldPhase = p.session.phase
        val oldEvents = p.events.size
        SessionEngine.advance(p, SystemClock.elapsedRealtime(), System.currentTimeMillis(), boot(c))
        if (forceSave || oldPhase != p.session.phase || oldEvents != p.events.size ||
            SystemClock.elapsedRealtime() - lastCheckpoint >= 5000) save(c, p)
        return p
    }
    fun restore(c: Context): SessionProgress {
        val p = load(c)
        if (p.session.phase in setOf("focus", "reward") && !FocusBlockingService.running) {
            // startForegroundService is asynchronous; do not mistake its startup
            // for a stopped monitor. No credit is advanced during this grace period.
            if (p.session.boot == boot(c) && (p.session.launchGraceElapsed - SystemClock.elapsedRealtime()) in 1..10000) return p
            val message = if (p.session.boot != boot(c)) "Celular reiniciado. Retome o foco pausado quando estiver pronto."
                else "Monitor interrompido. Foco pausado para evitar contar tempo sem proteção."
            SessionEngine.interrupt(p, message)
            save(c, p)
        }
        return p
    }
    fun encode(p: SessionProgress): JSONObject {
        val s = p.session
        return JSONObject().put("version", 2).put("apps", JSONObject(p.apps as Map<*, *>))
            .put("rewardSeconds", p.rewardSeconds).put("focusByDay", JSONObject(p.focusByDay as Map<*, *>))
            .put("credited", JSONArray(p.credited.toList())).put("notice", p.notice)
            .put("events", JSONArray(p.events.map { JSONObject().put("id", it.id).put("title", it.title).put("message", it.message) }))
            .put("session", JSONObject().put("id", s.id).put("phase", s.phase)
                .put("focusTotalSeconds", s.focusTotalSeconds).put("focusRemainingSeconds", s.focusRemainingSeconds)
                .put("rewardRemainingSeconds", s.rewardRemainingSeconds).put("deadlineElapsed", s.deadlineElapsed)
                .put("deadlineWall", s.deadlineWall).put("boot", s.boot).put("resumeFocus", s.resumeFocus).put("launchGraceElapsed", s.launchGraceElapsed))
    }
    fun decode(j: JSONObject): SessionProgress {
        require(j.getInt("version") == 2) { "Versão de progresso incompatível." }
        val apps = mutableMapOf<String, Boolean>()
        val a = j.getJSONObject("apps")
        a.keys().forEach { require(a.get(it) is Boolean); apps[it] = a.getBoolean(it) }
        val history = mutableMapOf<String, Long>()
        val h = j.getJSONObject("focusByDay")
        h.keys().forEach { val n = h.getLong(it); require(n >= 0); history[it] = n }
        val balance = j.getLong("rewardSeconds"); require(balance >= 0)
        val s = j.getJSONObject("session")
        val session = FocusSession(s.getString("id"), s.getString("phase"), s.getLong("focusTotalSeconds"),
            s.getLong("focusRemainingSeconds"), s.getLong("rewardRemainingSeconds"), s.getLong("deadlineElapsed"),
            s.getLong("deadlineWall"), s.getInt("boot"), s.getBoolean("resumeFocus"), s.optLong("launchGraceElapsed", 0))
        require(session.phase in setOf("idle", "focus", "paused", "reward", "locked"))
        require(session.focusRemainingSeconds >= 0 && session.focusTotalSeconds in 1..3600 && session.rewardRemainingSeconds >= 0)
        val credited = j.optJSONArray("credited") ?: JSONArray()
        val events = j.optJSONArray("events") ?: JSONArray()
        return SessionProgress(apps, balance, history, session,
            (0 until credited.length()).map { credited.getString(it) }.toMutableSet(),
            (0 until events.length()).map { val e = events.getJSONObject(it); SessionEvent(e.getString("id"), e.getString("title"), e.getString("message")) }.toMutableList(),
            j.optString("notice", ""))
    }
    private fun migrate(j: JSONObject): SessionProgress {
        require(j.getInt("version") == 1) { "Versão de progresso incompatível." }
        val p = SessionProgress(rewardSeconds = j.getLong("rewardSeconds"))
        require(p.rewardSeconds >= 0)
        val packages = mapOf("Instagram" to "com.instagram.android", "TikTok" to "com.zhiliaoapp.musically", "YouTube" to "com.google.android.youtube")
        val apps = j.getJSONObject("apps")
        apps.keys().forEach { packages[it]?.let { pkg -> p.apps[pkg] = apps.getBoolean(it) } }
        val h = j.getJSONObject("focusByDay")
        h.keys().forEach { val n = h.getLong(it); require(n >= 0); p.focusByDay[it] = n }
        return p
    }
}
