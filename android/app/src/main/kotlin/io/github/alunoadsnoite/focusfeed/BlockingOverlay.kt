package io.github.alunoadsnoite.focusfeed

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.view.Display
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class BlockingOverlay(private val context: Context) {
    companion object { @Volatile var visible = false; private set }
    @Suppress("DEPRECATION")
    private val type = if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY else WindowManager.LayoutParams.TYPE_PHONE
    // A Service is not a visual Context. Use a display/window context on modern
    // Android so native widgets receive the correct window resources and token.
    private val viewContext = if (Build.VERSION.SDK_INT >= 30) {
        val display = (context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager).getDisplay(Display.DEFAULT_DISPLAY)
        context.createDisplayContext(display).createWindowContext(type, null)
    } else context
    private val manager = viewContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var view: LinearLayout? = null
    private var detailView: TextView? = null

    fun show(noBalance: Boolean, detail: String = "") {
        val message = detail.ifEmpty {
            if (noBalance) "Saldo: 0 min. Conclua uma sessão de foco para ganhar recompensa." else ""
        }
        if (view != null) {
            detailView?.text = message
            detailView?.visibility = if (message.isEmpty()) View.GONE else View.VISIBLE
            view?.contentDescription = "Bloqueio do FocusFeed. $message"
            return
        }
        val layout = LinearLayout(viewContext).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 64, 32, 64)
            setBackgroundColor(Color.rgb(12, 46, 44))
        }
        layout.addView(TextView(viewContext).apply {
            text = "Você está em momento de foco! Mantenha a concentração."
            textSize = 26f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
        }, LinearLayout.LayoutParams(-1, -2))
        val detailText = TextView(viewContext).apply {
            text = message
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            visibility = if (message.isEmpty()) View.GONE else View.VISIBLE
        }
        layout.addView(detailText, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 24 })
        detailView = detailText
        layout.addView(Button(viewContext).apply {
            text = "Voltar ao FocusFeed"
            contentDescription = "Voltar ao FocusFeed"
            setOnClickListener {
                // Launch from the user's explicit tap, never automatically.
                try {
                    context.startActivity(Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    })
                    hide()
                } catch (_: Exception) {
                    // Keep the blocker visible if navigation fails.
                }
            }
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 32 })
        layout.contentDescription = "Bloqueio do FocusFeed. $message"
        val params = WindowManager.LayoutParams(-1, -1, type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT)
        params.title = "FocusFeedBlocker"
        manager.addView(layout, params)
        view = layout
        visible = true
    }

    fun hide() {
        val current = view ?: return
        view = null
        detailView = null
        visible = false
        try { manager.removeViewImmediate(current) } catch (_: IllegalArgumentException) { }
    }
}
