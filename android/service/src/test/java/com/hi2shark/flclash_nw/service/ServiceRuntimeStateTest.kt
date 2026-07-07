package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ServiceRuntimeStateTest {
    @Test
    fun markStartedUsesCurrentTimeWhenNoPreviousRuntimeExists() {
        val state = ServiceRuntimeState(now = { 1234L })

        val runTime = state.markStarted(previousRunTime = 0L)

        assertEquals(1234L, runTime)
        assertEquals(1234L, state.runTime)
        assertTrue(state.isRunning)
        assertFalse(state.isSuspended)
    }

    @Test
    fun markStartedPreservesExistingRuntimeWhenRestartingServiceShell() {
        val state = ServiceRuntimeState(now = { 9999L })

        val runTime = state.markStarted(previousRunTime = 4567L)

        assertEquals(4567L, runTime)
        assertEquals(4567L, state.runTime)
        assertTrue(state.isRunning)
    }

    @Test
    fun markStartFailedClearsRuntimeAndSuspendedState() {
        val state = ServiceRuntimeState(now = { 1000L })
        state.markStarted()
        state.setSuspended(true)

        state.markStartFailed()

        assertEquals(0L, state.runTime)
        assertFalse(state.isRunning)
        assertFalse(state.isSuspended)
    }

    @Test
    fun disconnectClearsRuntimeAndSuspendedState() {
        val state = ServiceRuntimeState(now = { 1000L })
        state.markStarted()
        state.setSuspended(true)

        state.markDisconnected()

        assertEquals(0L, state.runTime)
        assertFalse(state.isRunning)
        assertFalse(state.isSuspended)
    }

    @Test
    fun suspendAndResumeKeepLogicalRuntime() {
        val state = ServiceRuntimeState(now = { 1000L })
        state.markStarted()

        val suspendedRunTime = state.setSuspended(true)
        val resumedRunTime = state.setSuspended(false)

        assertEquals(1000L, suspendedRunTime)
        assertEquals(1000L, resumedRunTime)
        assertEquals(1000L, state.runTime)
        assertTrue(state.isRunning)
        assertFalse(state.isSuspended)
    }

    @Test
    fun isSuspendedFlowReflectsInitialValue() {
        val state = ServiceRuntimeState(now = { 1000L })

        assertEquals(false, state.isSuspendedFlow.value)
    }

    @Test
    fun setSuspendedEmitsNewValueToFlow() {
        val state = ServiceRuntimeState(now = { 1000L })
        state.markStarted()

        assertEquals(false, state.isSuspendedFlow.value)
        state.setSuspended(true)
        // The value must be observable through the flow (not just the getter),
        // otherwise NotificationModule's combine would never re-emit.
        assertEquals(true, state.isSuspendedFlow.value)
    }

    @Test
    fun markStoppedResetsSuspendedFlowToFalse() {
        val state = ServiceRuntimeState(now = { 1000L })
        state.markStarted()
        state.setSuspended(true)

        state.markStopped()

        assertEquals(false, state.isSuspendedFlow.value)
        assertEquals(false, state.isSuspended)
    }
}
