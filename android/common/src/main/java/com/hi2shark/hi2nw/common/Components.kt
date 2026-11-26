package com.hi2shark.hi2nw.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.hi2shark.hi2nw"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.ServiceBroadcastReceiver")
}
