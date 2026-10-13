package com.example.focus_feed

import org.junit.Assert.*
import org.junit.Test

class SessionEngineTest {
    private val wall = 1791896400000L
    @Test fun completionCreditsExactlyOnce() {
        val p = SessionProgress()
        SessionEngine.start(p, 1500, 1000, wall, 1)
        val id = p.session.id
        SessionEngine.advance(p, 1501000, wall + 1500000, 1)
        SessionEngine.advance(p, 1601000, wall + 1600000, 1)
        assertEquals(300L, p.rewardSeconds)
        assertEquals(1500L, p.focusByDay.values.sum())
        assertEquals(setOf(id), p.credited)
        assertEquals(1, p.events.count { it.id.startsWith("focus-") })
    }
    @Test fun pauseExcludesElapsedIdleTimeAndKeepsSessionId() {
        val p = SessionProgress()
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.advance(p, 10000, wall + 10000, 1)
        val id = p.session.id
        SessionEngine.pause(p)
        SessionEngine.advance(p, 100000, wall + 100000, 1)
        assertEquals(50L, p.session.focusRemainingSeconds)
        SessionEngine.start(p, 60, 100000, wall + 100000, 1)
        assertEquals(id, p.session.id)
        SessionEngine.advance(p, 150000, wall + 150000, 1)
        assertEquals(12L, p.rewardSeconds)
    }
    @Test fun cancelledFocusNeverCredits() {
        val p = SessionProgress()
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.stop(p)
        SessionEngine.advance(p, 70000, wall + 70000, 1)
        assertEquals(0L, p.rewardSeconds)
        assertTrue(p.focusByDay.isEmpty())
    }
    @Test fun zeroBalanceCannotReleaseApps() {
        val p = SessionProgress()
        try { SessionEngine.reward(p, 1, 0, wall, 1); fail("Must reject") } catch (_: IllegalArgumentException) { }
        assertEquals("idle", p.session.phase)
        assertEquals(0L, p.rewardSeconds)
    }
    @Test fun overspendingLeavesStateUnchanged() {
        val p = SessionProgress(rewardSeconds = 12)
        try { SessionEngine.reward(p, 13, 0, wall, 1); fail("Must reject") } catch (_: IllegalArgumentException) { }
        assertEquals(12L, p.rewardSeconds)
    }
    @Test fun rewardFreezesFocusAndAutomaticallyResumes() {
        val p = SessionProgress(rewardSeconds = 300)
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.advance(p, 10000, wall + 10000, 1)
        SessionEngine.reward(p, 10, 10000, wall + 10000, 1)
        SessionEngine.advance(p, 19000, wall + 19000, 1)
        assertEquals(50L, p.session.focusRemainingSeconds)
        assertEquals("reward", p.session.phase)
        SessionEngine.advance(p, 20000, wall + 20000, 1)
        assertEquals("focus", p.session.phase)
        assertEquals(70000L, p.session.deadlineElapsed)
        SessionEngine.advance(p, 70000, wall + 70000, 1)
        assertEquals(302L, p.rewardSeconds)
    }
    @Test fun rewardWithoutFocusReturnsToLockedEvenWithZeroBalance() {
        val p = SessionProgress(rewardSeconds = 12)
        SessionEngine.reward(p, 12, 0, wall, 1)
        SessionEngine.advance(p, 12000, wall + 12000, 1)
        assertEquals("locked", p.session.phase)
        assertEquals(0L, p.rewardSeconds)
        assertEquals("Seu tempo de pausa acabou!", p.events.single().message)
    }
    @Test fun delayedCallbackCompletesRewardAndFocusOnce() {
        val p = SessionProgress(rewardSeconds = 12)
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.reward(p, 12, 0, wall, 1)
        SessionEngine.advance(p, 100000, wall + 100000, 1)
        assertEquals("idle", p.session.phase)
        assertEquals(12L, p.rewardSeconds)
        assertEquals(2, p.events.size)
    }
    @Test fun rebootPausesAtSavedCheckpointWithoutCredit() {
        val p = SessionProgress(rewardSeconds = 12)
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.advance(p, 10000, wall + 10000, 1)
        SessionEngine.advance(p, 1000, wall + 900000, 2)
        assertEquals("paused", p.session.phase)
        assertEquals(50L, p.session.focusRemainingSeconds)
        assertEquals(12L, p.rewardSeconds)
        assertTrue(p.credited.isEmpty())
    }
    @Test fun interruptedRewardDoesNotRefundSpentBalance() {
        val p = SessionProgress(rewardSeconds = 12)
        SessionEngine.reward(p, 12, 0, wall, 1)
        SessionEngine.advance(p, 100, wall + 100000, 2)
        assertEquals("locked", p.session.phase)
        assertEquals(0L, p.rewardSeconds)
        assertEquals(0L, p.session.rewardRemainingSeconds)
    }
    @Test fun wallClockJumpDoesNotFinishFocusEarly() {
        val p = SessionProgress()
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.advance(p, 10000, wall + 9000000, 1)
        assertEquals("focus", p.session.phase)
        assertEquals(50L, p.session.focusRemainingSeconds)
        assertEquals(0L, p.rewardSeconds)
    }
    @Test fun snapshotRoundTripRetainsIdentityAndFractions() {
        val p = SessionProgress(apps = mutableMapOf("com.instagram.android" to false), rewardSeconds = 12)
        SessionEngine.start(p, 60, 0, wall, 1)
        val copy = NativeSessionRepository.decode(NativeSessionRepository.encode(p))
        assertEquals(p, copy)
    }
    @Test fun rewardWhilePausedPreservesTheUnfinishedFocusForResume() {
        val p = SessionProgress(rewardSeconds = 12)
        SessionEngine.start(p, 60, 0, wall, 1)
        SessionEngine.advance(p, 10000, wall + 10000, 1)
        val id = p.session.id
        SessionEngine.pause(p)
        SessionEngine.reward(p, 12, 10000, wall + 10000, 1)
        SessionEngine.advance(p, 22000, wall + 22000, 1)
        assertEquals("locked", p.session.phase)
        SessionEngine.start(p, 60, 22000, wall + 22000, 1)
        assertEquals(id, p.session.id)
        assertEquals(50L, p.session.focusRemainingSeconds)
    }

}
