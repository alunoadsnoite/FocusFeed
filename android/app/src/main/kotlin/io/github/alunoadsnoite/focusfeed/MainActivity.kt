package io.github.alunoadsnoite.focusfeed

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())
    private var notificationResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focusfeed/permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "check" -> result.success(mapOf("supported" to true, "usage" to NativeAccess.usage(this), "overlay" to Settings.canDrawOverlays(this)))
                    "request" -> {
                        val intent = when (call.argument<String>("permission")) {
                            "usage" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                            else -> null
                        }
                        try {
                            requireNotNull(intent) { "Permissão desconhecida" }
                            startActivity(intent)
                            result.success(null)
                        } catch (_: Exception) { result.error("settings_unavailable", "Não foi possível abrir as configurações.", null) }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focusfeed/session")
            .setMethodCallHandler { call, result ->
                if (call.method == "requestNotifications") {
                    if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        if (notificationResult != null) { result.error("busy", "Solicitação já aberta.", null); return@setMethodCallHandler }
                        val options = getSharedPreferences("focusfeed_options", MODE_PRIVATE)
                        if (options.getBoolean("notifications_asked", false) && !shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)) {
                            startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        options.edit().putBoolean("notifications_asked", true).apply()
                        notificationResult = result
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
                    } else result.success(FocusNotifications.enabled(this))
                    return@setMethodCallHandler
                }
                val arguments = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                NativeSessionRepository.worker.execute {
                    try {
                        if (call.method == "apps") {
                            val apps = InstalledApps.list(this)
                            main.post { result.success(apps) }
                            return@execute
                        }
                        var p = if (call.method == "initialize" || call.method == "status") NativeSessionRepository.restore(this)
                            else NativeSessionRepository.load(this)
                        if (FocusBlockingService.running) p = NativeSessionRepository.advance(this)
                        val backup = NativeSessionRepository.copy(p)
                        p = NativeSessionRepository.copy(p)
                        val elapsed = SystemClock.elapsedRealtime()
                        val wall = System.currentTimeMillis()
                        val boot = NativeSessionRepository.boot(this)
                        var launch = false
                        when (call.method) {
                            "initialize", "status" -> {
                                if (p.session.phase == "locked" && call.method == "initialize" && NativeAccess.canBlock(this)) launch = true
                            }
                            "start" -> {
                                check(NativeAccess.canBlock(this)) { "Ative acesso ao uso e sobreposição no painel de permissões." }
                                SessionEngine.start(p, (arguments["seconds"] as? Number)?.toLong() ?: p.session.focusTotalSeconds, elapsed, wall, boot)
                                launch = true
                            }
                            "pause" -> SessionEngine.pause(p)
                            "stop" -> SessionEngine.stop(p)
                            "reward" -> {
                                check(NativeAccess.canBlock(this)) { "Ative acesso ao uso e sobreposição antes de liberar as redes." }
                                SessionEngine.reward(p, (arguments["seconds"] as? Number)?.toLong() ?: 0, elapsed, wall, boot)
                                launch = true
                            }
                            "duration" -> {
                                require(p.session.phase == "idle") { "Pare a sessão antes de alterar a duração." }
                                val seconds = (arguments["seconds"] as? Number)?.toLong() ?: 0
                                require(seconds in 60..3600)
                                p.session.focusTotalSeconds = seconds
                                p.session.focusRemainingSeconds = seconds
                            }
                            "select" -> {
                                require(p.session.phase == "idle") { "Pare o bloqueio antes de alterar a seleção." }
                                val pkg = arguments["package"] as? String ?: error("App ausente")
                                require(pkg != packageName && pkg.matches(Regex("[A-Za-z0-9_.]+")))
                                p.apps[pkg] = arguments["selected"] as? Boolean ?: false
                            }
                            else -> { main.post { result.notImplemented() }; return@execute }
                        }
                        // Snapshot includes the debit AND reward phase atomically.
                        if (call.method !in setOf("initialize", "status")) NativeSessionRepository.save(this, p)
                        FocusNotifications.drain(this, p)
                        val snapshot = NativeSessionRepository.encode(p).toString()
                        main.post {
                            try {
                                if (launch) {
                                    val intent = Intent(this, FocusBlockingService::class.java)
                                    if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
                                } else if (!SessionEngine.active(p.session)) stopService(Intent(this, FocusBlockingService::class.java))
                                result.success(status(snapshot))
                            } catch (_: Exception) {
                                NativeSessionRepository.worker.execute {
                                    try { NativeSessionRepository.save(this, backup) } finally {
                                        main.post { result.error("service_unavailable", "Não foi possível iniciar o serviço; a alteração foi desfeita.", null) }
                                    }
                                }
                            }
                        }
                    } catch (error: Exception) {
                        main.post { result.error("session_error", error.message ?: "Falha ao salvar a sessão.", null) }
                    }
                }
            }
    }
    private fun status(snapshot: String) = mapOf("progress" to snapshot,
        "monitorRunning" to FocusBlockingService.running,
        "permissionsReady" to NativeAccess.canBlock(this),
        "notificationsEnabled" to FocusNotifications.enabled(this), "platform" to "android")
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 41) {
            notificationResult?.success(FocusNotifications.enabled(this))
            notificationResult = null
        }
    }
    override fun onDestroy() {
        notificationResult?.error("interrupted", "Solicitação de notificação interrompida.", null)
        notificationResult = null
        super.onDestroy()
    }
}
