package com.hi2shark.hi2nw

import android.app.Application
import android.content.ComponentCallbacks2
import android.content.Context
import com.hi2shark.hi2nw.common.GlobalState
import com.hi2shark.hi2nw.core.Core
import com.hi2shark.hi2nw.service.trimCoreMemory
import java.util.concurrent.CopyOnWriteArraySet

class FlClashApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }

    @Suppress("DEPRECATION")
    override fun onTrimMemory(level: Int) {
        trimCoreMemory(level)
        if (shouldTrimTransientCaches(level)) {
            trimCallbacks.forEach { it() }
        }
        super.onTrimMemory(level)
    }

    override fun onLowMemory() {
        Core.forceGCIfLoaded()
        trimCallbacks.forEach { it() }
        super.onLowMemory()
    }

    companion object {
        private val trimCallbacks = CopyOnWriteArraySet<() -> Unit>()

        fun registerTrimCallback(callback: () -> Unit) {
            trimCallbacks.add(callback)
        }

        fun unregisterTrimCallback(callback: () -> Unit) {
            trimCallbacks.remove(callback)
        }

        @Suppress("DEPRECATION")
        private fun shouldTrimTransientCaches(level: Int): Boolean = when (level) {
            ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN,
            ComponentCallbacks2.TRIM_MEMORY_BACKGROUND,
            ComponentCallbacks2.TRIM_MEMORY_MODERATE,
            ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW,
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            -> true
            else -> false
        }
    }
}
