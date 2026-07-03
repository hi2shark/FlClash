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
        controller.updateWifiNetwork(ssid = "Home", validated = true)

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
        controller.updateWifiNetwork(ssid = "Home", validated = true)
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS - 1)

        controller.updateWifiNetwork(ssid = "Home", validated = false)

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
        controller.updateWifiNetwork(ssid = "Cafe", validated = true)

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
        controller.updateWifiNetwork(ssid = "Home", validated = false)
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

        controller.updateWifiNetwork(ssid = "Home", validated = true)
        assertEquals(listOf(false), events)

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        scheduler.advanceBy(WifiWatchSuspendController.SUSPEND_DELAY_MILLIS)

        assertEquals(listOf(false, true), events)
    }

    @Test
    fun emptySsidResumesImmediately() {
        val scheduler = FakeScheduler()
        val events = mutableListOf<Boolean>()
        val controller = WifiWatchSuspendController(
            scheduler = scheduler::schedule,
            setWifiSuspended = events::add,
        )

        controller.updateSuspendOnWifiSsids(setOf("Home"))
        controller.updateWifiNetwork(ssid = null, validated = true)

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
        controller.updateWifiNetwork(ssid = "Home", validated = true)
        controller.updateWifiNetwork(ssid = "Cafe", validated = true)
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
