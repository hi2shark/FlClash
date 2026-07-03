package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals

class WifiWatchSuspendControllerTest {
    @Test
    fun trustedValidatedWifiSuspendsOnlyAfterStabilityDelay() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)

        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS - 1)
        assertEquals(emptyList(), events)
        scheduler.advanceBy(1)
        assertEquals(listOf(true), events)
    }

    @Test
    fun unsafeWifiResumesImmediatelyAndCancelsPendingSuspend() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS - 1)

        controller.updateWifiNetwork(ssid = "Home", validated = false, wifiPresent = true)

        assertEquals(listOf(false), events)
        scheduler.advanceBy(1)
        assertEquals(listOf(false), events)
    }

    @Test
    fun untrustedWifiResumesImmediately() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Cafe", validated = true, wifiPresent = true)

        assertEquals(listOf(false), events)
    }

    @Test
    fun weakWifiKeepsProxyActiveWhileWifiIsNotValidated() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = false, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS * 12)

        assertEquals(listOf(false), events)
    }

    @Test
    fun trustedSsidUpdatesReevaluateCurrentWifiNetwork() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        assertEquals(listOf(false), events)

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)

        assertEquals(listOf(false, true), events)
    }

    @Test
    fun wifiGoneResumesImmediately() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        // WiFi transport entirely gone — resume right away.
        controller.updateWifiNetwork(ssid = null, validated = true, wifiPresent = false)

        assertEquals(listOf(false), events)
    }

    @Test
    fun staleDelayedTaskDoesNotSuspendAfterWifiBecomesUnsafe() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        controller.updateWifiNetwork(ssid = "Cafe", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)

        assertEquals(listOf(false), events)
    }

    // --- Regression: transient null SSID during an AP switch (wifi still present) ---

    @Test
    fun transientNullSsidWhileWifiPresentHoldsPendingSuspend() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        // AP switch blip: WiFi transport still present, SSID not yet resolved.
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        assertEquals(emptyList(), events)

        // Pending suspend must survive the blip and still fire after the delay.
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(true), events)
    }

    @Test
    fun transientNullSsidWhileSuspendedKeepsSuspended() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(true), events)

        // Switching APs while suspended: blip must NOT resume.
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS * 2)
        assertEquals(listOf(true), events)
    }

    @Test
    fun transientNullThenUntrustedNamedSsidResumesImmediately() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(true), events)

        // Blip during the switch...
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        assertEquals(listOf(true), events)
        // ...then the new AP resolves to a named, untrusted SSID -> resume now.
        controller.updateWifiNetwork(ssid = "Cafe", validated = true, wifiPresent = true)

        assertEquals(listOf(true, false), events)
    }

    @Test
    fun transientNullThenWifiGoneResumesImmediately() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(true), events)

        // Blip, then the WiFi transport actually goes away -> resume now.
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        assertEquals(listOf(true), events)
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = false)

        assertEquals(listOf(true, false), events)
    }
}

private class FakeScheduler {
    private var now = 0L
    private val tasks = mutableListOf<Task>()

    fun schedule(delayMillis: Long, action: () -> Unit): WifiWatchSuspendController.Cancellable {
        val task = Task(dueAt = now + delayMillis, action = action)
        tasks += task
        return object : WifiWatchSuspendController.Cancellable {
            override fun cancel() {
                task.cancelled = true
            }
        }
    }

    fun advanceBy(millis: Long) {
        now += millis
        val readyTasks = tasks
            .filter { it.dueAt <= now }
            .sortedBy { it.dueAt }
            .toList()
        tasks.removeAll(readyTasks.toSet())
        readyTasks
            .filterNot { it.cancelled }
            .forEach { it.action() }
    }

    private data class Task(
        val dueAt: Long,
        val action: () -> Unit,
        var cancelled: Boolean = false,
    )
}
