package io.github.alunoadsnoite.focusfeed

import android.app.NotificationManager
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import java.io.File
import java.io.FileOutputStream
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.*
import org.junit.runner.RunWith
import java.util.concurrent.Callable
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class NativeFlowTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private fun shell(command: String) {
        instrumentation.uiAutomation.executeShellCommand(command).use { fd ->
            java.io.FileInputStream(fd.fileDescriptor).use { it.readBytes() }
        }
    }
    private fun <T> worker(action: () -> T): T = NativeSessionRepository.worker.submit(Callable { action() }).get(10, TimeUnit.SECONDS)
    private fun waitFor(condition: () -> Boolean) {
        val end = SystemClock.elapsedRealtime() + 10000
        while (!condition() && SystemClock.elapsedRealtime() < end) Thread.sleep(100)
        Assert.assertTrue("Condition did not become true", condition())
    }
    @Before fun setup() {
        context.stopService(Intent(context, FocusBlockingService::class.java))
        waitFor { !FocusBlockingService.running }
        shell("appops set ${context.packageName} GET_USAGE_STATS allow")
        shell("appops set ${context.packageName} SYSTEM_ALERT_WINDOW allow")
        shell("pm grant ${context.packageName} android.permission.POST_NOTIFICATIONS")
        worker {
            context.getSharedPreferences("focusfeed_progress", Context.MODE_PRIVATE).edit().clear().commit()
            NativeSessionRepository.forgetCacheForTests()
            NativeSessionRepository.save(context, SessionProgress())
        }
        instrumentation.startActivitySync(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        instrumentation.waitForIdleSync()
        instrumentation.uiAutomation.serviceInfo = instrumentation.uiAutomation.serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }
        Thread.sleep(300)
    }
    @After fun cleanup() {
        shell("appops set ${context.packageName} GET_USAGE_STATS allow")
        worker { SessionEngine.stop(NativeSessionRepository.load(context)); NativeSessionRepository.save(context, NativeSessionRepository.load(context)) }
        context.stopService(Intent(context, FocusBlockingService::class.java))
        waitFor { !FocusBlockingService.running }
    }
    private val blockablePackage get() = instrumentation.context.packageName
    private fun openBlockableApp() {
        context.startActivity(Intent().setClassName(blockablePackage, BlockableTestActivity::class.java.name)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
    private fun focus(seconds: Long) {
        worker {
            val p = NativeSessionRepository.load(context)
            p.apps[blockablePackage] = true
            SessionEngine.start(p, seconds, SystemClock.elapsedRealtime(), System.currentTimeMillis(), NativeSessionRepository.boot(context))
            NativeSessionRepository.save(context, p)
        }
        context.startForegroundService(Intent(context, FocusBlockingService::class.java))
        waitFor { FocusBlockingService.running }
    }
    @Test fun focusCompletesPersistsCreditAndPostsNotification() {
        focus(5)
        waitFor { worker { NativeSessionRepository.load(context).session.phase == "idle" } }
        Assert.assertEquals(1L, worker { NativeSessionRepository.load(context).rewardSeconds })
        Assert.assertTrue((context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).activeNotifications
            .any { it.notification.extras.getString("android.title") == "Foco concluído!" })
        worker { NativeSessionRepository.forgetCacheForTests() }
        Assert.assertEquals(1L, worker { NativeSessionRepository.load(context).rewardSeconds })
        Assert.assertEquals(1, worker { NativeSessionRepository.load(context).credited.size })
    }
    @Test fun zeroBalanceStillShowsOverlayForSelectedApp() {
        focus(60)
        openBlockableApp()
        waitFor { BlockingOverlay.visible }
        waitFor { instrumentation.uiAutomation.windows.any { window ->
            window.root?.findAccessibilityNodeInfosByText("Você está em momento de foco!")?.isNotEmpty() == true
        } }
        Assert.assertEquals(0L, worker { NativeSessionRepository.load(context).rewardSeconds })
        if (InstrumentationRegistry.getArguments().getString("captureScreenshots") == "true") {
            val screenshot = requireNotNull(instrumentation.uiAutomation.takeScreenshot())
            FileOutputStream(File(context.cacheDir, "focusfeed-blocking.png")).use {
                Assert.assertTrue(screenshot.compress(Bitmap.CompressFormat.PNG, 100, it))
            }
            screenshot.recycle()
        }
    }
    @Test fun rewardExpiresAndReblocksWithoutFlutterCallback() {
        worker {
            val p = NativeSessionRepository.load(context)
            p.rewardSeconds = 2; p.apps[blockablePackage] = true
            SessionEngine.reward(p, 2, SystemClock.elapsedRealtime(), System.currentTimeMillis(), NativeSessionRepository.boot(context))
            NativeSessionRepository.save(context, p)
        }
        context.startForegroundService(Intent(context, FocusBlockingService::class.java))
        waitFor { FocusBlockingService.running }
        openBlockableApp()
        Assert.assertFalse(BlockingOverlay.visible)
        waitFor { BlockingOverlay.visible }
        Assert.assertEquals("locked", worker { NativeSessionRepository.load(context).session.phase })
        Assert.assertEquals(0L, worker { NativeSessionRepository.load(context).rewardSeconds })
    }
    @Test fun revokedPermissionStopsProtectionAndPausesFocus() {
        focus(60)
        shell("appops set ${context.packageName} GET_USAGE_STATS deny")
        waitFor { !FocusBlockingService.running }
        Assert.assertEquals("paused", worker { NativeSessionRepository.load(context).session.phase })
        Assert.assertEquals(0L, worker { NativeSessionRepository.load(context).rewardSeconds })
        Assert.assertFalse(BlockingOverlay.visible)
    }
    @Test fun migrationPreservesOldSelectionBalanceAndHistory() {
        worker {
            context.getSharedPreferences("focusfeed_progress", Context.MODE_PRIVATE).edit().clear()
                .putString("progress_v1", """{"version":1,"apps":{"Instagram":false,"YouTube":true},"rewardSeconds":312,"focusByDay":{"2026-10-13":1500}}""").commit()
            NativeSessionRepository.forgetCacheForTests()
            val p = NativeSessionRepository.load(context)
            Assert.assertEquals(312L, p.rewardSeconds)
            Assert.assertEquals(false, p.apps["com.instagram.android"])
            Assert.assertEquals(1500L, p.focusByDay["2026-10-13"])
        }
    }
}
