package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class WifiWatchResumeRetryTest {
    @Test
    fun successfulResumeDoesNotScheduleRetry() {
        val scheduler = ResumeRetryFakeScheduler()
        val applied = mutableListOf<Boolean>()
        val retry = WifiWatchResumeRetry(
            delaysMillis = listOf(500L, 1500L),
            scheduler = scheduler::schedule,
            applySuspended = { suspended ->
                applied += suspended
                ServiceStartResult.success()
            },
        )

        val result = retry.apply(false)

        assertTrue(result.success)
        assertEquals(listOf(false), applied)
        scheduler.advanceBy(10_000)
        assertEquals(listOf(false), applied)
    }

    @Test
    fun failedResumeRetriesUntilSuccess() {
        val scheduler = ResumeRetryFakeScheduler()
        val applied = mutableListOf<Boolean>()
        var calls = 0
        val retry = WifiWatchResumeRetry(
            delaysMillis = listOf(500L, 1500L, 3000L),
            scheduler = scheduler::schedule,
            applySuspended = { suspended ->
                applied += suspended
                calls++
                if (calls == 1) {
                    ServiceStartResult.failure("establish failed")
                } else {
                    ServiceStartResult.success()
                }
            },
        )

        assertFalse(retry.apply(false).success)
        assertEquals(listOf(false), applied)

        scheduler.advanceBy(499)
        assertEquals(listOf(false), applied)

        scheduler.advanceBy(1)
        assertEquals(listOf(false, false), applied)
        scheduler.advanceBy(10_000)
        assertEquals(listOf(false, false), applied)
    }

    @Test
    fun suspendCancelsPendingResumeRetry() {
        val scheduler = ResumeRetryFakeScheduler()
        val applied = mutableListOf<Boolean>()
        val retry = WifiWatchResumeRetry(
            delaysMillis = listOf(500L, 1500L),
            scheduler = scheduler::schedule,
            applySuspended = { suspended ->
                applied += suspended
                if (!suspended) {
                    ServiceStartResult.failure("establish failed")
                } else {
                    ServiceStartResult.success()
                }
            },
        )

        assertFalse(retry.apply(false).success)
        assertEquals(listOf(false), applied)

        assertTrue(retry.apply(true).success)
        assertEquals(listOf(false, true), applied)

        scheduler.advanceBy(10_000)
        assertEquals(listOf(false, true), applied)
    }

    @Test
    fun exhaustedRetriesStopAfterConfiguredAttempts() {
        val scheduler = ResumeRetryFakeScheduler()
        val applied = mutableListOf<Boolean>()
        val retry = WifiWatchResumeRetry(
            delaysMillis = listOf(100L, 200L),
            scheduler = scheduler::schedule,
            applySuspended = { suspended ->
                applied += suspended
                ServiceStartResult.failure("still failing")
            },
        )

        assertFalse(retry.apply(false).success)
        // Initial attempt + 2 retries.
        scheduler.advanceBy(100)
        scheduler.advanceBy(200)
        scheduler.advanceBy(10_000)
        assertEquals(listOf(false, false, false), applied)
    }

    @Test
    fun onAttemptFinishedFiresForInitialAndRetry() {
        val scheduler = ResumeRetryFakeScheduler()
        var finished = 0
        var calls = 0
        val retry = WifiWatchResumeRetry(
            delaysMillis = listOf(500L),
            scheduler = scheduler::schedule,
            applySuspended = {
                calls++
                if (calls == 1) {
                    ServiceStartResult.failure("fail once")
                } else {
                    ServiceStartResult.success()
                }
            },
            onAttemptFinished = { finished++ },
        )

        retry.apply(false)
        assertEquals(1, finished)
        scheduler.advanceBy(500)
        assertEquals(2, finished)
    }
}

private class ResumeRetryFakeScheduler {
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
