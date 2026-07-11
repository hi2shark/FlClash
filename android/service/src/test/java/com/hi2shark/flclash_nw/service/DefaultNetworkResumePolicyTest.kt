package com.hi2shark.flclash_nw.service

import kotlin.test.Test
import kotlin.test.assertEquals

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
