package com.hi2shark.flclash_nw.service

import com.hi2shark.flclash_nw.common.BroadcastAction
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.common.sendBroadcast

interface IBaseService {
    fun handleCreate() {
        GlobalState.log("Service create")
        BroadcastAction.SERVICE_CREATED.sendBroadcast()
    }

    fun handleDestroy() {
        GlobalState.log("Service destroy")
        BroadcastAction.SERVICE_DESTROYED.sendBroadcast()
    }

    fun start()

    fun stop()
}