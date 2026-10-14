package io.github.alunoadsnoite.focusfeed

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

/** A separate test APK activity that permits overlays, unlike Android Settings. */
class BlockableTestActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply {
            text = "FocusFeed test target"
            textSize = 24f
        })
    }
}
