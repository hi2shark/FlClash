package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class WifiWatchRssiHysteresisTest {
    @Test
    fun entersTrustedAtEnterThreshold() {
        assertTrue(
            WifiWatchRssi.isTrusted(
                WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM,
                wasTrusted = false,
            ),
        )
        assertTrue(WifiWatchRssi.isTrusted(-70, wasTrusted = false))
    }

    @Test
    fun exitsTrustedBelowExitThreshold() {
        assertFalse(
            WifiWatchRssi.isTrusted(
                WifiWatchRssi.RSSI_EXIT_TRUSTED_DBM - 1,
                wasTrusted = true,
            ),
        )
        assertFalse(WifiWatchRssi.isTrusted(-90, wasTrusted = true))
    }

    @Test
    fun midBandKeepsPreviousDecision() {
        val mid = (WifiWatchRssi.RSSI_ENTER_TRUSTED_DBM + WifiWatchRssi.RSSI_EXIT_TRUSTED_DBM) / 2
        assertTrue(WifiWatchRssi.isTrusted(mid, wasTrusted = true))
        assertFalse(WifiWatchRssi.isTrusted(mid, wasTrusted = false))
    }

    @Test
    fun unknownRssiIsNeverTrusted() {
        assertFalse(WifiWatchRssi.isTrusted(null, wasTrusted = true))
        assertFalse(WifiWatchRssi.isTrusted(null, wasTrusted = false))
    }
}
