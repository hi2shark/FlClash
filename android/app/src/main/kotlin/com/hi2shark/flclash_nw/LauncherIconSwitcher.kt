package com.hi2shark.flclash_nw

import android.content.ComponentName
import android.content.pm.PackageManager

internal object LauncherIconSwitcher {
    const val AUTO_COMPONENT = ".LauncherActivity"
    const val LIGHT_COMPONENT = ".MainActivityAliasLight"
    const val DARK_COMPONENT = ".MainActivityAliasDark"

    private val entries = mapOf(
        "auto" to Entry(AUTO_COMPONENT, defaultEnabled = true),
        "light" to Entry(LIGHT_COMPONENT, defaultEnabled = false),
        "dark" to Entry(DARK_COMPONENT, defaultEnabled = false),
    )

    private data class Entry(
        val suffix: String,
        val defaultEnabled: Boolean,
    )

    fun apply(packageManager: PackageManager, packageName: String, mode: String): Boolean {
        return applyWith(
            mode = mode,
            readState = { suffix ->
                packageManager.getComponentEnabledSetting(
                    ComponentName(packageName, "$packageName$suffix"),
                )
            },
            writeState = { suffix, state ->
                packageManager.setComponentEnabledSetting(
                    ComponentName(packageName, "$packageName$suffix"),
                    state,
                    PackageManager.DONT_KILL_APP,
                )
            },
        )
    }

    fun applyWith(
        mode: String,
        readState: (String) -> Int,
        writeState: (String, Int) -> Unit,
    ): Boolean {
        val selected = entries[mode] ?: return false
        if (!isEnabled(selected, readState(selected.suffix))) {
            writeState(selected.suffix, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        }
        for (entry in entries.values) {
            if (entry.suffix == selected.suffix) {
                continue
            }
            if (isEnabled(entry, readState(entry.suffix))) {
                writeState(entry.suffix, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
            }
        }
        return true
    }

    private fun isEnabled(entry: Entry, state: Int): Boolean = when (state) {
        PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
        PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> entry.defaultEnabled
        else -> false
    }
}
