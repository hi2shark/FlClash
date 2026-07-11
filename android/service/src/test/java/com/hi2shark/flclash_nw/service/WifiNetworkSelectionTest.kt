package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals

class WifiNetworkSelectionTest {
    @Test
    fun preferredDefaultWifiWinsOverStaleTrustedWifi() {
        val selection = selectWifiNetwork(
            candidates = listOf(
                WifiNetworkCandidate(key = "old-home", ssid = "Home", trusted = true),
                WifiNetworkCandidate(key = "new-cafe", ssid = "Cafe", trusted = false),
            ),
            preferredKey = "new-cafe",
            fallbackSsid = "Home",
        )

        assertEquals(WifiNetworkSelection("new-cafe", WifiNetworkSelectionSource.PREFERRED), selection)
    }

    @Test
    fun unmatchedDeviceSsidUsesFailOpenFallback() {
        val selection = selectWifiNetwork(
            candidates = listOf(
                WifiNetworkCandidate(key = "old-home", ssid = "Home", trusted = true),
            ),
            preferredKey = null,
            fallbackSsid = "Cafe",
        )

        assertEquals(WifiNetworkSelection<String>(null, WifiNetworkSelectionSource.FALLBACK_ONLY), selection)
    }

    @Test
    fun preferredWifiMissingFromCallbackCacheStaysUnresolved() {
        val selection = selectWifiNetwork(
            candidates = listOf(
                WifiNetworkCandidate(key = "old-home", ssid = "Home", trusted = true),
            ),
            preferredKey = "new-cafe",
            fallbackSsid = "Home",
        )

        assertEquals(
            WifiNetworkSelection("new-cafe", WifiNetworkSelectionSource.PREFERRED_PENDING),
            selection,
        )
    }

    @Test
    fun preferredWifiWithUnresolvedSsidStaysPending() {
        val selection = selectWifiNetwork(
            candidates = listOf(
                WifiNetworkCandidate(key = "new-cafe", ssid = null, trusted = false),
                WifiNetworkCandidate(key = "old-home", ssid = "Home", trusted = true),
            ),
            preferredKey = "new-cafe",
            fallbackSsid = "Home",
        )

        assertEquals(
            WifiNetworkSelection("new-cafe", WifiNetworkSelectionSource.PREFERRED_PENDING),
            selection,
        )
    }
}
