package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MemoryTrimPolicyTest {
    @Test
    fun ignoresLevelsBelowUiHidden() {
        var now = 1_000L
        val policy = MemoryTrimPolicy(minIntervalMs = 30_000L, nowMs = { now })

        assertFalse(policy.shouldForceGc(5))
        assertFalse(policy.shouldForceGc(10))
        assertFalse(policy.shouldForceGc(15))
        assertFalse(policy.shouldForceGc(19))
    }

    @Test
    fun triggersOnUiHiddenAndAbove() {
        var now = 1_000L
        val policy = MemoryTrimPolicy(minIntervalMs = 30_000L, nowMs = { now })

        assertTrue(policy.shouldForceGc(MemoryTrimPolicy.TRIM_MEMORY_UI_HIDDEN))
        now = 40_000L
        assertTrue(policy.shouldForceGc(40))
        now = 80_000L
        assertTrue(policy.shouldForceGc(80))
    }

    @Test
    fun throttlesWithinMinInterval() {
        var now = 1_000L
        val policy = MemoryTrimPolicy(minIntervalMs = 30_000L, nowMs = { now })

        assertTrue(policy.shouldForceGc(MemoryTrimPolicy.TRIM_MEMORY_UI_HIDDEN))
        now = 20_000L
        assertFalse(policy.shouldForceGc(40))
        now = 31_000L
        assertTrue(policy.shouldForceGc(40))
    }
}
