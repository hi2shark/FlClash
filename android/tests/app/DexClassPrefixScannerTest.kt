package com.hi2shark.flclash_nw.packages

import com.hi2shark.flclash_nw.core.Core
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class DexClassPrefixScannerTest {

    @Test
    fun `matches domestic vendor and packer classes defined in class_defs`() {
        val dex = buildMinimalDex(
            definedTypes = listOf("Lorg/mozilla/firefox/App;", "Lcom/tencent/mm/ui/LauncherUI;"),
        )
        assertTrue(DexClassPrefixScanner.containsMatchingClass(dex))

        val packerDex = buildMinimalDex(
            definedTypes = listOf("Ls/h/e/l/l/S;"),
        )
        assertTrue(DexClassPrefixScanner.containsMatchingClass(packerDex))

        val qihooDex = buildMinimalDex(
            definedTypes = listOf("Lcom/qihoo360/replugin/Entry;"),
        )
        assertTrue(DexClassPrefixScanner.containsMatchingClass(qihooDex))
    }

    @Test
    fun `ignores domestic descriptors that are only referenced in type_ids or string_ids`() {
        val dex = buildMinimalDex(
            definedTypes = listOf("Lorg/mozilla/firefox/App;", "Lcom/spotify/music/MainActivity;"),
            extraReferencedTypes = listOf("Lcom/tencent/mm/opensdk/openapi/IWXAPI;"),
            extraStrings = listOf("Lcom/alipay/sdk/app/PayTask;"),
        )
        assertFalse(DexClassPrefixScanner.containsMatchingClass(dex))
    }

    @Test
    fun `handles topologically ordered class_defs that are not sorted by class_idx`() {
        val dex = buildMinimalDex(
            definedTypes = listOf("Lz/BaseClass;", "Lcom/baidu/mobstat/StatService;"),
            preserveDefinedOrder = true,
        )
        assertTrue(DexClassPrefixScanner.containsMatchingClass(dex))
    }

    @Test
    fun `handles mutf8 nul and non-ascii strings in utf16 sort order`() {
        val dex = buildMinimalDex(
            definedTypes = listOf("Lcom/bytedance/sdk/Entry;"),
            extraStrings = listOf("\u0000leadingNul", "L\u0000afterL", "Lcom/\u4e2d\u6587;"),
        )
        assertTrue(DexClassPrefixScanner.containsMatchingClass(dex))
    }

    @Test
    fun `rejects truncated or malformed dex images without throwing`() {
        assertFalse(DexClassPrefixScanner.containsMatchingClass(ByteArray(16)))
        val valid = buildMinimalDex(definedTypes = listOf("Lcom/tencent/Foo;"))
        assertFalse(DexClassPrefixScanner.containsMatchingClass(valid, length = 80))

        val badEndian = valid.copyOf()
        badEndian[40] = 0
        assertFalse(DexClassPrefixScanner.containsMatchingClass(badEndian))

        val badStringOffset = valid.copyOf()
        ByteBuffer.wrap(badStringOffset, 112, 4).order(ByteOrder.LITTLE_ENDIAN).putInt(999_999)
        assertFalse(DexClassPrefixScanner.containsMatchingClass(badStringOffset))
    }

    @Test
    fun `DexReadBuffer enforces maxBytes even when zip entry size is unknown`() {
        val buffer = DexReadBuffer(maxBytes = 1024)
        val exact = ByteArray(1024) { (it and 0xff).toByte() }
        assertEquals(1024, buffer.readAll(ByteArrayInputStream(exact), sizeHint = -1L))
        assertArrayEquals(exact, buffer.bytes.copyOf(1024))

        val oversized = ByteArray(1025)
        assertEquals(
            DexReadBuffer.OVERSIZED,
            buffer.readAll(ByteArrayInputStream(oversized), sizeHint = -1L),
        )
        assertEquals(
            DexReadBuffer.OVERSIZED,
            buffer.readAll(ByteArrayInputStream(ByteArray(8)), sizeHint = 2048L),
        )
    }

    @Test
    fun `Core parses literal IPv4, IPv6, and scoped IPv6 socket addresses`() {
        val v4 = Core.parseInetSocketAddress("192.168.1.42:8080")
        assertEquals(8080, v4.port)
        assertArrayEquals(byteArrayOf(192.toByte(), 168.toByte(), 1, 42), v4.address.address)

        val v6Scoped = Core.parseInetSocketAddress("[fe80::1%wlan0]:5353")
        assertEquals(5353, v6Scoped.port)
        val expectedScoped = ByteArray(16).apply {
            this[0] = 0xfe.toByte()
            this[1] = 0x80.toByte()
            this[15] = 1
        }
        assertArrayEquals(expectedScoped, v6Scoped.address.address)

        val v4Mapped = Core.parseInetSocketAddress("[::ffff:10.0.0.1]:443")
        assertEquals(443, v4Mapped.port)
        assertArrayEquals(byteArrayOf(10, 0, 0, 1), v4Mapped.address.address)

        val nat64 = Core.parseInetSocketAddress("[64:ff9b::10.0.0.1]:443")
        assertEquals(443, nat64.port)
        val expectedNat64 = ByteArray(16).apply {
            this[1] = 0x64
            this[2] = 0xff.toByte()
            this[3] = 0x9b.toByte()
            this[12] = 10
            this[15] = 1
        }
        assertArrayEquals(expectedNat64, nat64.address.address)
    }

    @Test
    fun `Core constructs socket addresses from raw IPv4 and IPv6 bytes`() {
        val v4 = Core.toInetSocketAddress(byteArrayOf(10, 0, 0, 2), 8080)
        assertEquals(8080, v4.port)
        assertArrayEquals(byteArrayOf(10, 0, 0, 2), v4.address.address)

        val v6Bytes = ByteArray(16).apply {
            this[0] = 0x20
            this[1] = 0x01
            this[15] = 1
        }
        val v6 = Core.toInetSocketAddress(v6Bytes, 443)
        assertEquals(443, v6.port)
        assertArrayEquals(v6Bytes, v6.address.address)
    }

    private fun buildMinimalDex(
        definedTypes: List<String>,
        extraReferencedTypes: List<String> = emptyList(),
        extraStrings: List<String> = emptyList(),
        preserveDefinedOrder: Boolean = false,
    ): ByteArray {
        val allTypes = (definedTypes + extraReferencedTypes).distinct()
        val allStrings = (allTypes + extraStrings + "Ljava/lang/Object;")
            .distinct()
            .sortedWith { a, b -> compareUtf16(a, b) }
        val stringIndex = allStrings.withIndex().associate { (i, s) -> s to i }

        val sortedTypes = allTypes.sortedBy { stringIndex.getValue(it) }
        val typeIndex = sortedTypes.withIndex().associate { (i, t) -> t to i }

        val orderedDefs = if (preserveDefinedOrder) {
            definedTypes
        } else {
            definedTypes.sortedBy { typeIndex.getValue(it) }
        }

        val headerSize = 112
        val stringIdsOff = headerSize
        val typeIdsOff = stringIdsOff + allStrings.size * 4
        val classDefsOff = typeIdsOff + sortedTypes.size * 4
        val stringDataBase = classDefsOff + orderedDefs.size * 32

        val stringPool = ByteArrayOutputStream()
        val stringOffsets = IntArray(allStrings.size)
        for ((index, value) in allStrings.withIndex()) {
            stringOffsets[index] = stringDataBase + stringPool.size()
            writeUleb128(stringPool, value.length)
            writeMutf8(stringPool, value)
            stringPool.write(0)
        }

        val poolBytes = stringPool.toByteArray()
        val totalSize = stringDataBase + poolBytes.size
        val buf = ByteBuffer.allocate(totalSize).order(ByteOrder.LITTLE_ENDIAN)

        buf.put(byteArrayOf('d'.code.toByte(), 'e'.code.toByte(), 'x'.code.toByte(), '\n'.code.toByte(), '0'.code.toByte(), '3'.code.toByte(), '9'.code.toByte(), 0))
        buf.position(32)
        buf.putInt(totalSize)
        buf.putInt(headerSize)
        buf.putInt(0x12345678)
        buf.position(56)
        buf.putInt(allStrings.size)
        buf.putInt(stringIdsOff)
        buf.putInt(sortedTypes.size)
        buf.putInt(typeIdsOff)
        buf.position(96)
        buf.putInt(orderedDefs.size)
        buf.putInt(classDefsOff)

        buf.position(stringIdsOff)
        for (off in stringOffsets) {
            buf.putInt(off)
        }
        buf.position(typeIdsOff)
        for (type in sortedTypes) {
            buf.putInt(stringIndex.getValue(type))
        }
        buf.position(classDefsOff)
        for (defined in orderedDefs) {
            buf.putInt(typeIndex.getValue(defined))
            buf.putInt(1)
            buf.putInt(-1)
            buf.putInt(0)
            buf.putInt(-1)
            buf.putInt(0)
            buf.putInt(0)
            buf.putInt(0)
        }
        buf.position(stringDataBase)
        buf.put(poolBytes)
        return buf.array()
    }

    private fun compareUtf16(a: String, b: String): Int {
        val limit = minOf(a.length, b.length)
        for (i in 0 until limit) {
            val cmp = a[i].code.compareTo(b[i].code)
            if (cmp != 0) return cmp
        }
        return a.length.compareTo(b.length)
    }

    private fun writeUleb128(out: ByteArrayOutputStream, value: Int) {
        var remaining = value
        do {
            var byte = remaining and 0x7f
            remaining = remaining ushr 7
            if (remaining != 0) {
                byte = byte or 0x80
            }
            out.write(byte)
        } while (remaining != 0)
    }

    private fun writeMutf8(out: ByteArrayOutputStream, text: String) {
        for (ch in text) {
            val code = ch.code
            when {
                code == 0 -> {
                    out.write(0xc0)
                    out.write(0x80)
                }
                code < 0x80 -> out.write(code)
                code < 0x800 -> {
                    out.write(0xc0 or (code ushr 6))
                    out.write(0x80 or (code and 0x3f))
                }
                else -> {
                    out.write(0xe0 or (code ushr 12))
                    out.write(0x80 or ((code ushr 6) and 0x3f))
                    out.write(0x80 or (code and 0x3f))
                }
            }
        }
    }
}
