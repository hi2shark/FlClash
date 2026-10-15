package com.follow.clash.service

internal class PhysicalDefaultNetworkTracker<K> {
    var current: K? = null
        private set

    var preferredWifi: K? = null
        private set

    fun update(key: K, isWifi: Boolean) {
        current = key
        preferredWifi = key.takeIf { isWifi }
    }

    fun lost(key: K): Boolean {
        if (current != key) {
            return false
        }
        current = null
        preferredWifi = null
        return true
    }

    fun clear() {
        current = null
        preferredWifi = null
    }
}
