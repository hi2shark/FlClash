package com.hi2shark.flclash_nw.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PhysicalDefaultNetworkTrackerTest {
    @Test
    fun staleLostFromPreviousNetworkIsIgnored() {
        val tracker = PhysicalDefaultNetworkTracker<String>()

        tracker.update("home", isWifi = true)
        tracker.update("cellular", isWifi = false)

        assertFalse(tracker.lost("home"))
        assertEquals("cellular", tracker.current)
        assertEquals(null, tracker.preferredWifi)
    }

    @Test
    fun losingCurrentNetworkClearsTrackedState() {
        val tracker = PhysicalDefaultNetworkTracker<String>()
        tracker.update("home", isWifi = true)

        assertTrue(tracker.lost("home"))
        assertEquals(null, tracker.current)
        assertEquals(null, tracker.preferredWifi)
    }
}
