package io.github.alunoadsnoite.focusfeed

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

object AppLanguage {
    const val DEFAULT_TAG = "pt-BR"
    const val KEY = "language"
    val supported = setOf(DEFAULT_TAG, "en-US", "es-ES")

    fun tag(context: Context): String {
        val saved = context.getSharedPreferences("focusfeed_options", Context.MODE_PRIVATE)
            .getString(KEY, DEFAULT_TAG) ?: DEFAULT_TAG
        return if (saved in supported) saved else DEFAULT_TAG
    }

    fun resources(context: Context): Context {
        val locale = Locale.forLanguageTag(tag(context))
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(locale)
        return context.createConfigurationContext(configuration)
    }
}
