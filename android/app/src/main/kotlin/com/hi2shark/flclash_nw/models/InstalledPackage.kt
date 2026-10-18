package com.hi2shark.flclash_nw.models

data class InstalledPackage(
    val packageName: String,
    val label: String,
    val system: Boolean,
    val internet: Boolean,
    val lastUpdateTime: Long,
)
