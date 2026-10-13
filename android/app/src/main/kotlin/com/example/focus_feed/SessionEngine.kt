package com.example.focus_feed

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

/** Pure state machine: the service and UI never credit/spend independently. */
data class FocusSession(
    var id: String = "",
    var phase: String = "idle",
    var focusTotalSeconds: Long = 1500,
    var focusRemainingSeconds: Long = 1500,
    var rewardRemainingSeconds: Long = 0,
    var deadlineElapsed: Long = 0,
    var deadlineWall: Long = 0,
    var boot: Int = -1,
    var resumeFocus: Boolean = false,
    var launchGraceElapsed: Long = 0,
)
data class SessionEvent(val id: String, val title: String, val message: String)
data class SessionProgress(
    val apps: MutableMap<String, Boolean> = mutableMapOf(),
    var rewardSeconds: Long = 0,
    val focusByDay: MutableMap<String, Long> = mutableMapOf(),
    var session: FocusSession = FocusSession(),
    val credited: MutableSet<String> = mutableSetOf(),
    val events: MutableList<SessionEvent> = mutableListOf(),
    var notice: String = "",
)

object SessionEngine {
    fun active(s: FocusSession) = s.phase in setOf("focus", "reward", "locked")
    fun secondsLeft(end: Long, now: Long) = ((end - now + 999) / 1000).coerceAtLeast(0)

    fun start(p: SessionProgress, seconds: Long, elapsed: Long, wall: Long, boot: Int) {
        require(seconds in 1..3600) { "Escolha uma duração entre 1 segundo e 60 minutos." }
        require(p.session.phase !in setOf("focus", "reward")) { "Já existe uma sessão ativa." }
        val s = if (p.session.phase == "paused" || (p.session.phase == "locked" && p.session.focusRemainingSeconds > 0 && p.session.id.isNotEmpty())) p.session else FocusSession(
            id = UUID.randomUUID().toString(), focusTotalSeconds = seconds, focusRemainingSeconds = seconds)
        require(s.focusRemainingSeconds > 0)
        s.phase = "focus"
        s.launchGraceElapsed = elapsed + 10000
        s.boot = boot
        s.deadlineElapsed = elapsed + s.focusRemainingSeconds * 1000
        s.deadlineWall = wall + s.focusRemainingSeconds * 1000
        s.resumeFocus = false
        p.session = s
        p.notice = ""
    }

    fun advance(p: SessionProgress, elapsed: Long, wall: Long, boot: Int) {
        val s = p.session
        if (!active(s)) return
        if (s.boot != boot && s.phase != "locked") {
            interrupt(p, "Celular reiniciado. O foco foi pausado; nenhum crédito foi gerado durante a interrupção.")
            return
        }
        if (s.phase == "reward") {
            s.rewardRemainingSeconds = secondsLeft(s.deadlineElapsed, elapsed)
            if (s.rewardRemainingSeconds > 0) return
            p.events.add(SessionEvent("reward-${s.id}-${s.deadlineWall}", "Pausa encerrada", "Seu tempo de pausa acabou!"))
            s.phase = if (s.resumeFocus) "focus" else "locked"
            if (s.resumeFocus) {
                s.deadlineElapsed += s.focusRemainingSeconds * 1000
                s.deadlineWall += s.focusRemainingSeconds * 1000
                s.resumeFocus = false
            }
        }
        if (s.phase == "focus") {
            s.focusRemainingSeconds = secondsLeft(s.deadlineElapsed, elapsed)
            if (s.focusRemainingSeconds == 0L) {
                if (p.credited.add(s.id)) {
                    val earned = s.focusTotalSeconds / 5
                    p.rewardSeconds += earned
                    val day = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(s.deadlineWall))
                    p.focusByDay[day] = (p.focusByDay[day] ?: 0) + s.focusTotalSeconds
                    p.events.add(SessionEvent("focus-${s.id}", "Foco concluído! Você ganhou ${label(earned)}."))
                }
                s.phase = "idle"
                s.deadlineElapsed = 0
                s.deadlineWall = 0
                p.notice = "Foco concluído. Recompensa adicionada ao saldo."
            }
        }
    }

    fun reward(p: SessionProgress, seconds: Long, elapsed: Long, wall: Long, boot: Int) {
        require(seconds in 1..86400 && seconds <= p.rewardSeconds) { "Saldo de recompensa insuficiente." }
        require(p.session.phase != "reward") { "Já existe uma recompensa ativa." }
        val s = p.session
        s.resumeFocus = s.phase == "focus"
        if (s.phase !in setOf("focus", "paused")) s.focusRemainingSeconds = 0
        if (s.id.isEmpty()) s.id = UUID.randomUUID().toString()
        p.rewardSeconds -= seconds
        s.phase = "reward"
        s.launchGraceElapsed = elapsed + 10000
        s.rewardRemainingSeconds = seconds
        s.boot = boot
        s.deadlineElapsed = elapsed + seconds * 1000
        s.deadlineWall = wall + seconds * 1000
        p.notice = ""
    }

    fun pause(p: SessionProgress) {
        require(p.session.phase == "focus") { "Não há foco em andamento." }
        p.session.phase = "paused"
        p.session.launchGraceElapsed = 0
        p.session.deadlineElapsed = 0
        p.session.deadlineWall = 0
    }

    fun interrupt(p: SessionProgress, message: String) {
        val s = p.session
        if (s.phase in setOf("focus", "reward")) {
            val canResume = s.focusRemainingSeconds > 0 && s.id.isNotEmpty()
            s.phase = if (canResume) "paused" else "locked"
            s.rewardRemainingSeconds = 0
            s.resumeFocus = false
            s.deadlineElapsed = 0
            s.deadlineWall = 0
        }
        s.launchGraceElapsed = 0
        p.notice = message
    }

    fun stop(p: SessionProgress) {
        p.session = FocusSession(focusTotalSeconds = p.session.focusTotalSeconds,
            focusRemainingSeconds = p.session.focusTotalSeconds)
        p.notice = ""
    }

    fun label(seconds: Long) = if (seconds % 60 == 0L) "${seconds / 60} min" else "${seconds / 60} min ${seconds % 60} s"
}
