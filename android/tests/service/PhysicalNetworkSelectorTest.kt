package com.hi2shark.hi2nw.service

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PhysicalNetworkSelectorTest {
    @Test
    fun `prefers validated wifi over validated cellular`() {
        val selected = selectPreferredPhysicalNetwork(
            listOf(
                PhysicalNetworkCandidate("cellular", transportPriority = 4, validated = true, losing = false),
                PhysicalNetworkCandidate("wifi", transportPriority = 0, validated = true, losing = false),
            ),
        )

        assertEquals("wifi", selected)
    }

    @Test
    fun `prefers validated cellular over unvalidated wifi`() {
        val selected = selectPreferredPhysicalNetwork(
            listOf(
                PhysicalNetworkCandidate("wifi", transportPriority = 0, validated = false, losing = false),
                PhysicalNetworkCandidate("cellular", transportPriority = 4, validated = true, losing = false),
            ),
        )

        assertEquals("cellular", selected)
    }

    @Test
    fun `prefers validated cellular over losing validated wifi`() {
        val selected = selectPreferredPhysicalNetwork(
            listOf(
                PhysicalNetworkCandidate("wifi", transportPriority = 0, validated = true, losing = true),
                PhysicalNetworkCandidate("cellular", transportPriority = 4, validated = true, losing = false),
            ),
        )

        assertEquals("cellular", selected)
    }

    @Test
    fun `falls back to transport priority when no network is validated`() {
        val selected = selectPreferredPhysicalNetwork(
            listOf(
                PhysicalNetworkCandidate("cellular", transportPriority = 4, validated = false, losing = false),
                PhysicalNetworkCandidate("wifi", transportPriority = 0, validated = false, losing = false),
            ),
        )

        assertEquals("wifi", selected)
    }

    @Test
    fun `returns null when no candidates exist`() {
        assertNull(selectPreferredPhysicalNetwork(emptyList<PhysicalNetworkCandidate<String>>()))
    }
}
