# Follow-up to the FocusFeed 1.0.1 device review

Review: https://gitlab.com/fdroid/fdroiddata/-/merge_requests/52413#note_4067639531

Joerg observed two APKPure launches without an overlay during an approximately
35-second window on Samsung / Android 15. This patch addresses two weaknesses
in foreground tracking; it does not claim to establish the cause on that device.

The service previously moved its query cursor directly to the current time every
500 ms. An event delivered later with an earlier timestamp would never be read.
It now queries a bounded ten-second overlap. The tracker ignores older events,
so replay cannot replace a newer foreground activity. State survives empty polls.
Delivery delayed by more than that window is still outside this recovery bound.

The old tracker also cleared a package for any pause from that package. The new
tracker compares the activity class too, so a late pause from a previous activity
does not clear another activity already resumed in the same app. Android reports
these lifecycle events per activity:
https://developer.android.com/reference/android/app/usage/UsageEvents.Event

Four JVM regression tests cover the overlap boundary, late pause of a different
activity in the same package, replay of old events, and leaving/reopening a target.
A new instrumentation scenario requires visible blocking on two consecutive
launches, with the overlay hidden when returning to FocusFeed.

Changelogs for the existing F-Droid ABI codes 4011/4012/4013 are now included in
both listing locales. They copy the existing 1.0.1 notes; they do not represent a
new app release. The recipe still pins 3170e6e8, tagged v1.0.1-fdroid.1, four
commits after v1.0.1. This patch requires integration and a new source release /
recipe update before its native change can be distributed by F-Droid.

## Validation

Flutter 3.47.7 analysis and all 20 Flutter tests passed. Android compilation and
JVM tests are in progress while missing Flutter artifacts download. No Samsung,
APKPure or physical-device retest is claimed. Local Android 16 and Android 11
emulators terminated during startup, before the app could be installed. The new
instrumentation scenario therefore remains unexecuted in this environment.
