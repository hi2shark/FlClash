package com.hi2shark.flclash_nw.core

import com.hi2shark.flclash_nw.core.mobile.Mobile
import com.hi2shark.flclash_nw.core.mobile.ResultHandler
import com.hi2shark.flclash_nw.core.mobile.TunHandler
import java.net.InetAddress
import java.net.InetSocketAddress

object Core {
    private const val EMPTY_TRAFFIC_JSON = """{"up":0,"down":0}"""

    @Volatile
    private var libraryLoaded = false

    fun forceGC() {
        libraryLoaded = true
        Mobile.forceGC()
    }

    fun forceGCIfLoaded() {
        if (libraryLoaded) {
            Mobile.forceGC()
        }
    }

    fun updateDNS(
        dns: String,
    ) {
        libraryLoaded = true
        Mobile.updateDns(dns)
    }

    fun resetNetwork() {
        libraryLoaded = true
        Mobile.resetNetwork()
    }

    fun parseInetSocketAddress(address: String): InetSocketAddress {
        val host: String
        val portText: String
        if (address.startsWith('[')) {
            val closeBracket = address.indexOf(']')
            require(closeBracket > 1 && closeBracket + 1 < address.length && address[closeBracket + 1] == ':') {
                "Invalid bracketed socket address: $address"
            }
            val rawHost = address.substring(1, closeBracket)
            val zoneIndex = rawHost.indexOf('%')
            host = if (zoneIndex >= 0) rawHost.substring(0, zoneIndex) else rawHost
            require(host.isNotEmpty()) { "Missing host in address: $address" }
            portText = address.substring(closeBracket + 2)
        } else {
            val colon = address.lastIndexOf(':')
            require(colon > 0 && address.indexOf(':') == colon) {
                "Invalid socket address: $address"
            }
            host = address.substring(0, colon)
            portText = address.substring(colon + 1)
        }
        val port = portText.toIntOrNull()
        require(port != null && port in 0..65535) { "Invalid port in address: $address" }
        val literalBytes = if (':' in host) tryParseIpv6(host) else tryParseIpv4(host)
        val inetAddress = if (literalBytes != null) {
            InetAddress.getByAddress(null, literalBytes)
        } else {
            InetAddress.getByName(host)
        }
        return InetSocketAddress(inetAddress, port)
    }

    private fun tryParseIpv4(host: String): ByteArray? {
        val bytes = ByteArray(4)
        var partIndex = 0
        var start = 0
        while (start <= host.length) {
            if (partIndex >= 4) return null
            val dot = host.indexOf('.', start).let { if (it < 0) host.length else it }
            val len = dot - start
            if (len !in 1..3) return null
            if (len > 1 && host[start] == '0') return null
            var value = 0
            for (i in start until dot) {
                val digit = host[i] - '0'
                if (digit !in 0..9) return null
                value = value * 10 + digit
            }
            if (value > 255) return null
            bytes[partIndex++] = value.toByte()
            start = dot + 1
        }
        return if (partIndex == 4) bytes else null
    }

    private fun tryParseIpv6(host: String): ByteArray? {
        if (host.isEmpty()) return null
        val doubleColon = host.indexOf("::")
        if (doubleColon != -1 && host.indexOf("::", doubleColon + 2) != -1) {
            return null
        }
        val headText = if (doubleColon == -1) host else host.substring(0, doubleColon)
        val tailText = if (doubleColon == -1) "" else host.substring(doubleColon + 2)
        val head = IntArray(8)
        val tail = IntArray(8)
        val headCount = parseIpv6Part(headText, head, allowTrailingIpv4 = doubleColon == -1 || tailText.isEmpty())
            ?: return null
        val tailCount = parseIpv6Part(tailText, tail, allowTrailingIpv4 = true)
            ?: return null
        if (doubleColon == -1) {
            if (headCount != 8) return null
        } else if (headCount + tailCount > 7) {
            return null
        }
        val bytes = ByteArray(16)
        for (i in 0 until headCount) {
            bytes[i * 2] = (head[i] ushr 8).toByte()
            bytes[i * 2 + 1] = head[i].toByte()
        }
        val tailStart = 8 - tailCount
        for (i in 0 until tailCount) {
            val outIndex = (tailStart + i) * 2
            bytes[outIndex] = (tail[i] ushr 8).toByte()
            bytes[outIndex + 1] = tail[i].toByte()
        }
        return bytes
    }

    private fun parseIpv6Part(part: String, out: IntArray, allowTrailingIpv4: Boolean): Int? {
        if (part.isEmpty()) return 0
        var count = 0
        var start = 0
        while (start <= part.length) {
            val colon = part.indexOf(':', start).let { if (it < 0) part.length else it }
            if (colon == start) return null
            val token = part.substring(start, colon)
            if ('.' in token) {
                if (!allowTrailingIpv4 || colon != part.length || count > 6) return null
                val ipv4 = tryParseIpv4(token) ?: return null
                out[count++] = ((ipv4[0].toInt() and 0xff) shl 8) or (ipv4[1].toInt() and 0xff)
                out[count++] = ((ipv4[2].toInt() and 0xff) shl 8) or (ipv4[3].toInt() and 0xff)
                return count
            }
            if (token.length > 4 || count >= 8) return null
            var value = 0
            for (ch in token) {
                val hex = when (ch) {
                    in '0'..'9' -> ch - '0'
                    in 'a'..'f' -> ch - 'a' + 10
                    in 'A'..'F' -> ch - 'A' + 10
                    else -> return null
                }
                value = (value shl 4) or hex
            }
            out[count++] = value
            start = colon + 1
        }
        return count
    }

    fun startTun(
        fd: Int,
        protect: (Int) -> Boolean,
        resolveUid: (protocol: Int, source: InetSocketAddress, target: InetSocketAddress) -> Int,
        resolvePackage: (uid: Int) -> String,
        stack: String,
        address: String,
        dns: String,
        options: String,
    ): Boolean {
        libraryLoaded = true
        return Mobile.startTun(
            fd,
            object : TunHandler {
                override fun protect(fd: Int): Boolean = protect(fd)

                override fun resolveUid(
                    protocol: Int,
                    source: String,
                    target: String,
                ): Int {
                    return resolveUid(
                        protocol,
                        parseInetSocketAddress(source),
                        parseInetSocketAddress(target),
                    )
                }

                override fun resolvePackage(uid: Int): String = resolvePackage(uid)
            },
            stack,
            address,
            dns,
            options,
        )
    }

    fun invokeMethod(
        data: String,
        cb: (result: ByteArray?) -> Unit,
    ) {
        libraryLoaded = true
        Mobile.invokeMethod(data, ResultHandler { result -> cb(result) })
    }

    fun updateEventListener(
        callback: ((result: ByteArray) -> Unit)?,
    ) {
        if (callback == null && !libraryLoaded) {
            return
        }
        libraryLoaded = true
        Mobile.setEventListener(
            callback?.let { ResultHandler { result -> it(result ?: ByteArray(0)) } },
        )
    }

    fun quickSetup(
        initParamsString: String,
        setupParamsString: String,
        callback: (result: String?) -> Unit,
    ) {
        libraryLoaded = true
        Mobile.quickSetup(
            initParamsString,
            setupParamsString,
            ResultHandler { result -> callback(result?.decodeToString()) },
        )
    }

    fun stopTun() {
        if (libraryLoaded) {
            Mobile.stopTun()
        }
    }

    fun startListener() {
        libraryLoaded = true
        Mobile.startListener()
    }

    fun stopListener() {
        if (libraryLoaded) {
            Mobile.stopListener()
        }
    }

    fun getTraffic(onlyStatisticsProxy: Boolean): String =
        if (libraryLoaded) Mobile.getTraffic(onlyStatisticsProxy) else EMPTY_TRAFFIC_JSON

    fun getTotalTraffic(onlyStatisticsProxy: Boolean): String =
        if (libraryLoaded) Mobile.getTotalTraffic(onlyStatisticsProxy) else EMPTY_TRAFFIC_JSON
}
