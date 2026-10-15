package com.follow.clash.service

import org.junit.Assert.assertEquals
import org.junit.Test

class DefaultNetworkResumePolicyTest {
    @Test
    fun cellularForcesResume() {
        assertEquals(
            DefaultNetworkResumeAction.FORCE,
            defaultNetworkResumeAction(isCellular = true, isOwnVpn = false),
        )
    }

    @Test
    fun vpnKeepsExistingResumeHold() {
        assertEquals(
            DefaultNetworkResumeAction.KEEP,
            defaultNetworkResumeAction(isCellular = false, isOwnVpn = true),
        )
    }

    @Test
    fun thirdPartyVpnClearsResumeHold() {
        assertEquals(
            DefaultNetworkResumeAction.CLEAR,
            defaultNetworkResumeAction(isCellular = false, isOwnVpn = false),
        )
    }

    @Test
    fun nonCellularNonVpnClearsResumeHold() {
        assertEquals(
            DefaultNetworkResumeAction.CLEAR,
            defaultNetworkResumeAction(isCellular = false, isOwnVpn = false),
        )
    }
}
