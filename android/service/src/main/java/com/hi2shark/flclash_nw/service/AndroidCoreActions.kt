package com.hi2shark.flclash_nw.service

import com.hi2shark.flclash_nw.common.GlobalState
import com.hi2shark.flclash_nw.core.Core
import com.google.gson.Gson
import com.google.gson.JsonParser
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

object AndroidCoreActions {
    private val gson = Gson()

    fun startListener(): Boolean = invokeBooleanAction("startListener")

    fun stopListener(): Boolean = invokeBooleanAction("stopListener")

    private fun invokeBooleanAction(method: String): Boolean {
        val latch = CountDownLatch(1)
        var success = false
        val data = gson.toJson(
            mapOf(
                "id" to "android_$method",
                "method" to method,
            ),
        )
        Core.invokeMethod(data) { result ->
            success = result?.decodeToString()?.takeIf { it.isNotEmpty() }
                ?.let { parseBooleanResult(it) } == true
            latch.countDown()
        }
        val completed = latch.await(3, TimeUnit.SECONDS)
        if (!completed) {
            GlobalState.log("Core action $method timeout")
        }
        return completed && success
    }

    private fun parseBooleanResult(result: String): Boolean {
        return runCatching {
            val json = JsonParser.parseString(result).asJsonObject
            json["error"] == null && json["result"]?.asBoolean == true
        }.getOrDefault(false)
    }
}
