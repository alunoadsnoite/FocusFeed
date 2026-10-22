package io.github.alunoadsnoite.focusfeed

import org.junit.Assert.*
import org.junit.Test

class ForegroundActivityTrackerTest {
    @Test fun delayedEventIsAcceptedOnNextOverlappingPoll() {
        val tracker = ForegroundActivityTracker()
        tracker.resume("focusfeed", "Main", 1000)
        // At 2000 the event at 1900 is not available yet. At 2500 the
        // overlapping query includes it; the old cursor=2000 would lose it.
        val delayedEventTime = 1900L
        val nextQueryStart = ForegroundActivityTracker.queryStart(2500)
        assertTrue(delayedEventTime >= nextQueryStart)
        assertTrue(delayedEventTime < 2000)
        tracker.resume("selected.app", "Main", delayedEventTime)
        assertEquals("selected.app", tracker.packageName)
    }

    @Test fun latePauseOfPreviousActivityDoesNotClearCurrentActivity() {
        val tracker = ForegroundActivityTracker()
        tracker.resume("selected.app", "Splash", 1000)
        tracker.resume("selected.app", "Main", 1100)
        tracker.pause("selected.app", "Splash", 1200)
        assertEquals("selected.app", tracker.packageName)
    }

    @Test fun replayCannotReplaceNewerForegroundWithOldEvents() {
        val tracker = ForegroundActivityTracker()
        tracker.resume("selected.app", "Main", 1000)
        tracker.pause("selected.app", "Main", 2000)
        tracker.resume("launcher", "Home", 2100)
        tracker.resume("selected.app", "Main", 1000)
        tracker.pause("selected.app", "Main", 2000)
        assertEquals("launcher", tracker.packageName)
    }

    @Test fun currentActivityPauseClearsForegroundAndNextLaunchRestoresIt() {
        val tracker = ForegroundActivityTracker()
        tracker.resume("selected.app", "Main", 1000)
        tracker.pause("selected.app", "Main", 2000)
        assertNull(tracker.packageName)
        tracker.resume("selected.app", "Main", 3000)
        assertEquals("selected.app", tracker.packageName)
    }
}
