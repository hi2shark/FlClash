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

    @Test
    fun idleSuspendedDoesNotAffectOtherReasons() {
        val reasons = ServiceSuspensionReasons()

        reasons.setIdleSuspended(true)

        assertFalse(reasons.externalSuspended)
        assertFalse(reasons.wifiSuspended)
        assertTrue(reasons.idleSuspended)
        assertTrue(reasons.shouldSuspend)
    }

    @Test
    fun clearingIdleSuspendedKeepsWifiAndExternalSuspension() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        reasons.setIdleSuspended(true)
        reasons.setIdleSuspended(false)

        assertTrue(reasons.externalSuspended)
        assertTrue(reasons.wifiSuspended)
        assertFalse(reasons.idleSuspended)
        assertTrue(reasons.shouldSuspend)
    }

    @Test
    fun shouldSuspendOnlyWhenAllReasonsClear() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        reasons.setIdleSuspended(true)
        assertTrue(reasons.shouldSuspend)

        reasons.setExternalSuspended(false)
        assertTrue(reasons.shouldSuspend)

        reasons.setWifiSuspended(false)
        assertTrue(reasons.shouldSuspend)

        reasons.setIdleSuspended(false)
        assertFalse(reasons.shouldSuspend)
    }

    @Test
    fun resetClearsAllThreeReasons() {
        val reasons = ServiceSuspensionReasons()

        reasons.setExternalSuspended(true)
        reasons.setWifiSuspended(true)
        reasons.setIdleSuspended(true)
        reasons.reset()

        assertFalse(reasons.externalSuspended)
        assertFalse(reasons.wifiSuspended)
        assertFalse(reasons.idleSuspended)
        assertFalse(reasons.shouldSuspend)
    }
}
