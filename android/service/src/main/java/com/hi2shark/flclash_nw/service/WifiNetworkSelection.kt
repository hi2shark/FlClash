package com.hi2shark.flclash_nw.service

internal data class WifiNetworkCandidate<K>(
    val key: K,
    val ssid: String?,
    val trusted: Boolean,
)

internal enum class WifiNetworkSelectionSource {
    PREFERRED,
    PREFERRED_PENDING,
    FALLBACK_MATCH,
    TRUSTED,
    FIRST,
    FALLBACK_ONLY,
    NONE,
}

internal data class WifiNetworkSelection<K>(
    val key: K?,
    val source: WifiNetworkSelectionSource,
)

internal fun <K> selectWifiNetwork(
    candidates: List<WifiNetworkCandidate<K>>,
    preferredKey: K?,
    fallbackSsid: String?,
): WifiNetworkSelection<K> {
    if (preferredKey != null) {
        val preferred = candidates.firstOrNull { it.key == preferredKey }
        return if (preferred?.ssid != null) {
            WifiNetworkSelection(preferredKey, WifiNetworkSelectionSource.PREFERRED)
        } else {
            WifiNetworkSelection(preferredKey, WifiNetworkSelectionSource.PREFERRED_PENDING)
        }
    }
    if (fallbackSsid != null) {
        val match = candidates.firstOrNull { it.ssid == fallbackSsid }
        if (match != null) {
            return WifiNetworkSelection(match.key, WifiNetworkSelectionSource.FALLBACK_MATCH)
        }
        return WifiNetworkSelection(null, WifiNetworkSelectionSource.FALLBACK_ONLY)
    }
    val trusted = candidates.firstOrNull { it.trusted && it.ssid != null }
    if (trusted != null) {
        return WifiNetworkSelection(trusted.key, WifiNetworkSelectionSource.TRUSTED)
    }
    val first = candidates.firstOrNull()
    return if (first != null) {
        WifiNetworkSelection(first.key, WifiNetworkSelectionSource.FIRST)
    } else {
        WifiNetworkSelection(null, WifiNetworkSelectionSource.NONE)
    }
}
