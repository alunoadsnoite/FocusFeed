package io.github.alunoadsnoite.focusfeed

/** Tracks activity identity, retaining state when a poll contains no new events. */
internal class ForegroundActivityTracker {
    companion object {
        // Bounded overlap recovers late event delivery without an unbounded query.
        fun queryStart(now: Long) = maxOf(0L, now - 10_000L)
    }
    var packageName: String? = null
        private set
    private var className: String? = null
    private var timestamp = Long.MIN_VALUE

    fun resume(pkg: String, activity: String?, time: Long) {
        if (time < timestamp) return
        packageName = pkg
        className = activity
        timestamp = time
    }

    fun pause(pkg: String, activity: String?, time: Long) {
        // A previous activity may pause after another activity in the same app
        // resumes. Its pause must not erase the newly resumed activity.
        if (time < timestamp || pkg != packageName || activity != className) return
        packageName = null
        className = null
        timestamp = time
    }
}
