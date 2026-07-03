package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class VpnSuspendControllerTest {
    @Test
    fun resumeStartsTunWithoutStartingListenerSeparately() {
        val events = mutableListOf<String>()
        val controller = VpnSuspendController(
            currentOptions = { "vpn-options" },
            stopTun = { events += "stopTun" },
            startTun = { options -> events += "startTun:$options" },
        )

        val result = controller.setSuspended(false)

        assertTrue(result.success)
        assertEquals(listOf("startTun:vpn-options"), events)
    }

    @Test
    fun suspendStopsTun() {
        val events = mutableListOf<String>()
        val controller = VpnSuspendController(
            currentOptions = { "vpn-options" },
            stopTun = { events += "stopTun" },
            startTun = { options -> events += "startTun:$options" },
        )

        val result = controller.setSuspended(true)

        assertTrue(result.success)
        assertEquals(listOf("stopTun"), events)
    }

    @Test
    fun unchangedSuspendStateDoesNotRestartTun() {
        val events = mutableListOf<String>()
        val controller = VpnSuspendController(
            currentOptions = { "vpn-options" },
            stopTun = { events += "stopTun" },
            startTun = { options -> events += "startTun:$options" },
            isSuspended = { true },
        )

        val result = controller.setSuspended(true)

        assertTrue(result.success)
        assertEquals(emptyList(), events)
    }

    @Test
    fun resumeFailsWhenVpnOptionsAreMissing() {
        val events = mutableListOf<String>()
        val controller = VpnSuspendController<String>(
            currentOptions = { null },
            stopTun = { events += "stopTun" },
            startTun = { options -> events += "startTun:$options" },
        )

        val result = controller.setSuspended(false)

        assertEquals(false, result.success)
        assertEquals("VPN options empty", result.message)
        assertEquals(emptyList(), events)
    }

    @Test
    fun resumeStopsTunBeforeRethrowingWhenStartTunFails() {
        val events = mutableListOf<String>()
        val controller = VpnSuspendController(
            currentOptions = { "vpn-options" },
            stopTun = { events += "stopTun" },
            startTun = { options ->
                events += "startTun:$options"
                throw IllegalStateException("start failed")
            },
        )

        val error = assertFailsWith<IllegalStateException> {
            controller.setSuspended(false)
        }

        assertEquals("start failed", error.message)
        assertEquals(listOf("startTun:vpn-options", "stopTun"), events)
    }
}
