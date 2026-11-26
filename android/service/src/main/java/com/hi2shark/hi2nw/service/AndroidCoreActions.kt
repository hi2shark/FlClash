package com.hi2shark.hi2nw.service

import com.hi2shark.hi2nw.common.GlobalState
import com.hi2shark.hi2nw.core.Core

object AndroidCoreActions {
    fun startListener(): Boolean = runListenerAction("startListener") {
        Core.startListener()
    }

    fun stopListener(): Boolean = runListenerAction("stopListener") {
        Core.stopListener()
    }

    private fun runListenerAction(name: String, action: () -> Unit): Boolean =
        runCatching(action)
            .onFailure { error -> GlobalState.log("Core action $name failed: $error") }
            .isSuccess
}
