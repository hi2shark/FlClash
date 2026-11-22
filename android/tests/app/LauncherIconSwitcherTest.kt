package com.hi2shark.flclash_nw

import android.content.pm.PackageManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LauncherIconSwitcherTest {
    @Test
    fun `fresh install on auto writes nothing`() {
        val states = mutableMapOf<String, Int>()
        val writes = mutableListOf<Pair<String, Int>>()

        val ok = LauncherIconSwitcher.applyWith(
            mode = "auto",
            readState = { states[it] ?: PackageManager.COMPONENT_ENABLED_STATE_DEFAULT },
            writeState = { suffix, state ->
                states[suffix] = state
                writes.add(suffix to state)
            },
        )

        assertTrue(ok)
        assertTrue(writes.isEmpty())
    }

    @Test
    fun `enables the new alias before disabling the previous entry`() {
        val states = mutableMapOf<String, Int>()
        val writes = mutableListOf<Pair<String, Int>>()

        assertTrue(
            LauncherIconSwitcher.applyWith(
                mode = "dark",
                readState = { states[it] ?: PackageManager.COMPONENT_ENABLED_STATE_DEFAULT },
                writeState = { suffix, state ->
                    states[suffix] = state
                    writes.add(suffix to state)
                },
            ),
        )
        assertEquals(
            listOf(
                LauncherIconSwitcher.DARK_COMPONENT to PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                LauncherIconSwitcher.AUTO_COMPONENT to PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            ),
            writes,
        )

        writes.clear()
        assertTrue(
            LauncherIconSwitcher.applyWith(
                mode = "light",
                readState = { states[it] ?: PackageManager.COMPONENT_ENABLED_STATE_DEFAULT },
                writeState = { suffix, state ->
                    states[suffix] = state
                    writes.add(suffix to state)
                },
            ),
        )
        assertEquals(
            listOf(
                LauncherIconSwitcher.LIGHT_COMPONENT to PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                LauncherIconSwitcher.DARK_COMPONENT to PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            ),
            writes,
        )
    }

    @Test
    fun `rejects an unknown mode without touching components`() {
        val writes = mutableListOf<Pair<String, Int>>()

        val ok = LauncherIconSwitcher.applyWith(
            mode = "neon",
            readState = { PackageManager.COMPONENT_ENABLED_STATE_DEFAULT },
            writeState = { suffix, state -> writes.add(suffix to state) },
        )

        assertFalse(ok)
        assertTrue(writes.isEmpty())
    }
}
