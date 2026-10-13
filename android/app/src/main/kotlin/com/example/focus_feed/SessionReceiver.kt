package com.example.focus_feed

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Never launch an overlay/FGS automatically from a reboot broadcast. */
class SessionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        NativeSessionRepository.worker.execute {
            try {
                val p = NativeSessionRepository.load(context)
                if (intent.action == "focusfeed.STOP") {
                    SessionEngine.stop(p)
                    NativeSessionRepository.save(context, p)
                    context.stopService(Intent(context, FocusBlockingService::class.java))
                } else if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
                    if (SessionEngine.active(p.session)) {
                        SessionEngine.interrupt(p, "Celular reiniciado. Retome o foco pausado no FocusFeed; nenhum crédito foi gerado enquanto estava desligado.")
                        NativeSessionRepository.save(context, p)
                        FocusNotifications.alert(context, SessionEvent("reboot", "Sessão interrompida", p.notice))
                    }
                }
            } catch (_: Exception) {
                // Existing data is preserved; the app exposes storage errors on reopen.
            } finally { pending.finish() }
        }
    }
}
