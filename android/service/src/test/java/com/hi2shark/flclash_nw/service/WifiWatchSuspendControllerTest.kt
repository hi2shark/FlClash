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
    fun transientNullSsidFallsBackToActiveWhenResolutionNeverArrives() {
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

        scheduler.advanceBy(WifiWatchSuspendController.SSID_RESOLUTION_GRACE_MILLIS - 1)
        assertEquals(emptyList(), events)

        // If the SSID never resolves, fall back to the safe default: keep the
        // proxy active and cancel any stale pending suspend.
        scheduler.advanceBy(1)
        assertEquals(listOf(false), events)

        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS * 2)
        assertEquals(listOf(false), events)
    }

    @Test
    fun transientNullSsidWhileSuspendedFallsBackToActiveAfterGracePeriod() {
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

        // Switching APs while suspended: keep the current state briefly while
        // waiting for the SSID to resolve.
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SSID_RESOLUTION_GRACE_MILLIS - 1)
        assertEquals(listOf(true), events)

        // If it never resolves, actively resume instead of hanging forever.
        scheduler.advanceBy(1)
        assertEquals(listOf(true, false), events)
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
    fun transientNullThenTrustedNamedSsidCancelsGraceFallbackAndSuspendsAfterDelay() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SSID_RESOLUTION_GRACE_MILLIS - 1)
        assertEquals(emptyList(), events)

        // Resolve while grace is still pending: cancel grace and start the 5s
        // stability window from this moment.
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS - 1)
        assertEquals(emptyList(), events)
        scheduler.advanceBy(1)
        assertEquals(listOf(true), events)
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

    @Test
    fun cellularDefaultNetworkResumesEvenOnTrustedSsid() {
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

        // WiFi still associated to trusted SSID, but the OS routed the default
        // network via Cellular -> proxy must come back immediately.
        controller.forceResume("default network is Cellular")

        assertEquals(listOf(true, false), events)
    }

    @Test
    fun forceResumeCancelsPendingSuspendBeforeItFires() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        // Within the 5s stability window the default network flips to Cellular.
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS - 1)
        assertEquals(emptyList(), events)

        controller.forceResume("default network is Cellular")

        assertEquals(listOf(false), events)
        // The pending suspend timer must have been cancelled.
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(false), events)
    }

    @Test
    fun forceResumeStaysActiveAcrossTrustedWifiUpdates() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        controller.forceResume("default network is Cellular")

        // Subsequent WiFi capability updates while still on Cellular must NOT
        // re-suspend, even though the SSID is trusted and validated.
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)

        assertEquals(listOf(false), events)
    }

    @Test
    fun clearForceResumeReEvaluatesAndCanSuspendAgain() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        controller.forceResume("default network is Cellular")
        assertEquals(listOf(false), events)

        // Default network leaves Cellular (back to WiFi). Re-evaluation should
        // schedule the stability suspend again.
        controller.clearForceResume("default network is no longer Cellular")
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)

        assertEquals(listOf(false, true), events)
    }

    @Test
    fun clearForceResumeWhileWifiGoneResumesImmediately() {
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

        // Cellular force-resume was active; WiFi then disappears and the
        // delayed default-lost reconsider clears force-resume. With no WiFi
        // present the controller must stay resumed (idempotent — no duplicate
        // setWifiSuspended(false)), not re-schedule suspend.
        controller.forceResume("default network is Cellular")
        assertEquals(listOf(true, false), events)
        controller.updateWifiNetwork(ssid = null, validated = false, wifiPresent = false)
        assertEquals(listOf(true, false), events)
        controller.clearForceResume("active network is not Cellular")

        assertEquals(listOf(true, false), events)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(true, false), events)
    }

    @Test
    fun repeatedTrustedUpdatesDoNotResetPendingSuspendDeadline() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)

        // Capability blips while still trusted must not restart the 5s window.
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS / 2)
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS / 2)

        assertEquals(listOf(true), events)
        assertEquals(null, controller.currentStatus().pendingSuspendDeadline)
    }

    @Test
    fun untrustedUpdateCancelsPendingSuspendAndResumes() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = "Home", validated = true, wifiPresent = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS / 2)

        controller.updateWifiNetwork(ssid = "Home", validated = false, wifiPresent = true)
        assertEquals(listOf(false), events)

        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)
        assertEquals(listOf(false), events)
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
