package com.hi2shark.flclash_nw

import android.app.Application
import android.content.Context
import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.core.Core
import com.hi2shark.flclash_nw.service.trimCoreMemory

class FlClashApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }

    override fun onTrimMemory(level: Int) {
        trimCoreMemory(level)
        super.onTrimMemory(level)
    }

    override fun onLowMemory() {
        Core.forceGCIfLoaded()
        super.onLowMemory()
    }
}
