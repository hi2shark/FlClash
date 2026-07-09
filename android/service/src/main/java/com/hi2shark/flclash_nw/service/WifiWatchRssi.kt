package com.hi2shark.flclash_nw.service

/**
 * RSSI hysteresis used while our own VPN is the default network (VALIDATED is
 * obscured). Enter trusted (may suspend) at [RSSI_ENTER_TRUSTED_DBM]; leave
 * trusted (must resume) below [RSSI_EXIT_TRUSTED_DBM]. The band in between keeps
 * the previous decision so a signal hovering near -80 does not flap.
 */
internal object WifiWatchRssi {
    const val RSSI_ENTER_TRUSTED_DBM = -75
    const val RSSI_EXIT_TRUSTED_DBM = -85

    /**
     * Pure RSSI trust with hysteresis.
     * Unknown RSSI is never trusted (fail open — keep proxy active).
     */
    fun isTrusted(rssi: Int?, wasTrusted: Boolean): Boolean {
        if (rssi == null) return false
        return when {
            rssi >= RSSI_ENTER_TRUSTED_DBM -> true
            rssi < RSSI_EXIT_TRUSTED_DBM -> false
            else -> wasTrusted
        }
    }
}
