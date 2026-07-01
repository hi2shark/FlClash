package com.hi2shark.flclash_nw

import android.app.Application
import android.content.Context
import com.hi2shark.flclash_nw.common.GlobalState

class Application : Application() {

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
