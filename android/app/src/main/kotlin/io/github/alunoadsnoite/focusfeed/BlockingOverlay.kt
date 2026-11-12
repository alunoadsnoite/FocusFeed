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
    private var headingView: TextView? = null
    private var backButton: Button? = null

    fun show(noBalance: Boolean, detail: String = "") {
        val strings = AppLanguage.resources(context)
        val message = detail.ifEmpty {
            if (noBalance) strings.getString(R.string.block_empty) else ""
        }
        if (view != null) {
            headingView?.text = strings.getString(R.string.block_heading)
            backButton?.text = strings.getString(R.string.block_back)
            backButton?.contentDescription = strings.getString(R.string.block_back)
            detailView?.text = message
            detailView?.visibility = if (message.isEmpty()) View.GONE else View.VISIBLE
            view?.contentDescription = strings.getString(R.string.block_accessibility, message)
            return
        }
        val layout = LinearLayout(viewContext).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(32, 64, 32, 64)
            setBackgroundColor(Color.rgb(12, 46, 44))
        }
        val heading = TextView(viewContext).apply {
            this.text = strings.getString(R.string.block_heading)
            textSize = 26f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
        }
        headingView = heading
        layout.addView(heading, LinearLayout.LayoutParams(-1, -2))
        val detailText = TextView(viewContext).apply {
            this.text = message
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            visibility = if (message.isEmpty()) View.GONE else View.VISIBLE
        }
        layout.addView(detailText, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 24 })
        detailView = detailText
        val back = Button(viewContext).apply {
            this.text = strings.getString(R.string.block_back)
            contentDescription = strings.getString(R.string.block_back)
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
        }
        backButton = back
        layout.addView(back, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 32 })
        layout.contentDescription = strings.getString(R.string.block_accessibility, message)
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
        headingView = null
        backButton = null
        visible = false
        try { manager.removeViewImmediate(current) } catch (_: IllegalArgumentException) { }
    }
}
