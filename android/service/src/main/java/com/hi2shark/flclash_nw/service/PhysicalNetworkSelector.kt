package com.hi2shark.flclash_nw.service

internal data class PhysicalNetworkCandidate<K>(
    val key: K,
    val transportPriority: Int,
    val validated: Boolean,
    val losing: Boolean,
) {
    val score: Int
        get() = transportPriority +
            (if (validated) 0 else UNVALIDATED_PENALTY) +
            (if (losing) LOSING_PENALTY else 0)

    companion object {
        const val UNVALIDATED_PENALTY = 50
        const val LOSING_PENALTY = 10
    }
}

internal fun <K> selectPreferredPhysicalNetwork(
    candidates: Iterable<PhysicalNetworkCandidate<K>>,
): K? = candidates.minByOrNull { it.score }?.key
