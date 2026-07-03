package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

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
}
