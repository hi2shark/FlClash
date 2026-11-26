package com.hi2shark.hi2nw.service

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ServiceSuspensionReasonsTest {
    @Test
    fun externalSuspendedDoesNotSetWifiSuspended() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)

        assertTrue(reasons.externalSuspended)
        assertFalse(reasons.wifiSuspended)
        assertTrue(reasons.shouldSuspend)
    }

    @Test
    fun wifiSuspendedDoesNotSetExternalSuspended() {
        val reasons = ServiceSuspensionReasons()

        reasons.setWifiSuspended(true)

        assertFalse(reasons.externalSuspended)
        assertTrue(reasons.wifiSuspended)
        assertTrue(reasons.shouldSuspend)
    }

    @Test
    fun clearingWifiSuspendedKeepsExternalSuspension() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        reasons.setWifiSuspended(false)

        assertTrue(reasons.externalSuspended)
        assertFalse(reasons.wifiSuspended)
        assertTrue(reasons.shouldSuspend)
    }

    @Test
    fun shouldSuspendOnlyWhenAllReasonsClear() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        assertTrue(reasons.shouldSuspend)

        reasons.setExternalSuspended(false)
        assertTrue(reasons.shouldSuspend)

        reasons.setWifiSuspended(false)
        assertFalse(reasons.shouldSuspend)
    }

    @Test
    fun resetClearsAllReasons() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        reasons.reset()

        assertFalse(reasons.externalSuspended)
        assertFalse(reasons.wifiSuspended)
        assertFalse(reasons.shouldSuspend)
    }
}
