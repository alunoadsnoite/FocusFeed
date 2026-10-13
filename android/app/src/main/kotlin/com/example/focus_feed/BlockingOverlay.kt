package com.example.focus_feed

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class BlockingOverlay(private val context: Context) {
    companion object { @Volatile var visible = false; private set }
    private val manager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var view: LinearLayout? = null

    fun show(noBalance: Boolean) {
        if (view != null) return
        val layout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 64, 32, 64)
            setBackgroundColor(Color.rgb(12, 46, 44))
        }
        layout.addView(TextView(context).apply {
            text = "Você está em momento de foco! Mantenha a concentração."
            textSize = 26f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
        }, LinearLayout.LayoutParams(-1, -2))
        if (noBalance) layout.addView(TextView(context).apply {
            text = "Saldo: 0 min. Conclua uma sessão de foco para ganhar recompensa."
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
        }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 24 })
        layout.addView(Button(context).apply {
            text = "Voltar ao FocusFeed"
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
        @Suppress("DEPRECATION")
        val type = if (Build.VERSION.SDK_INT >= 26) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else WindowManager.LayoutParams.TYPE_PHONE
        val params = WindowManager.LayoutParams(-1, -1, type,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.OPAQUE)
        manager.addView(layout, params)
        view = layout
        visible = true
    }

    fun hide() {
        val current = view ?: return
        view = null
        visible = false
        try { manager.removeViewImmediate(current) } catch (_: IllegalArgumentException) { }
    }
}
