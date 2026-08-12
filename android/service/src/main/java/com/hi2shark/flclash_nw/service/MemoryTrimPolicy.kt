package com.hi2shark.flclash_nw.service

/**
 * Decides whether a trim-memory callback should trigger Core.forceGC().
 * Pure logic with injectable clock for unit tests; does not hold Service refs.
 */
internal class MemoryTrimPolicy(
    private val minIntervalMs: Long = 30_000L,
    private val nowMs: () -> Long = System::currentTimeMillis,
) {
    companion object {
        /** [android.content.ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN] */
        const val TRIM_MEMORY_UI_HIDDEN: Int = 20
    }

    @Volatile
    private var lastTriggerMs: Long = 0L

    fun shouldForceGc(level: Int): Boolean {
        if (level < TRIM_MEMORY_UI_HIDDEN) {
            return false
        }
        val now = nowMs()
        if (lastTriggerMs > 0L && now - lastTriggerMs < minIntervalMs) {
            return false
        }
        lastTriggerMs = now
        return true
    }
}
