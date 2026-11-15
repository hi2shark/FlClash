package com.hi2shark.flclash_nw.packages

import java.io.InputStream
import kotlin.math.max
import kotlin.math.min

internal class DexReadBuffer(private val maxBytes: Int) {
    var bytes: ByteArray = ByteArray(min(INITIAL_CAPACITY, max(maxBytes, 0)))
        private set

    fun readAll(input: InputStream, sizeHint: Long = -1L): Int {
        if (sizeHint > maxBytes) {
            return OVERSIZED
        }
        if (sizeHint > bytes.size) {
            bytes = ByteArray(sizeHint.toInt())
        }
        var total = 0
        while (true) {
            if (total == bytes.size) {
                if (total >= maxBytes) {
                    return if (input.read() < 0) total else OVERSIZED
                }
                val nextCapacity = min(maxBytes.toLong(), max(bytes.size.toLong() * 2L, 4096L)).toInt()
                bytes = bytes.copyOf(nextCapacity)
            }
            val n = input.read(bytes, total, bytes.size - total)
            if (n < 0) {
                return total
            }
            total += n
        }
    }

    companion object {
        const val OVERSIZED = -1
        private const val INITIAL_CAPACITY = 64 * 1024
    }
}

internal object DexClassPrefixScanner {
    private const val HEADER_SIZE = 112
    private const val ENDIAN_CONSTANT = 0x12345678
    private const val STRING_IDS_SIZE_OFF = 56
    private const val STRING_IDS_OFF_OFF = 60
    private const val TYPE_IDS_SIZE_OFF = 64
    private const val TYPE_IDS_OFF_OFF = 68
    private const val CLASS_DEFS_SIZE_OFF = 96
    private const val CLASS_DEFS_OFF_OFF = 100
    private const val CLASS_DEF_ITEM_SIZE = 32
    private const val INVALID_DEX = Int.MIN_VALUE

    fun containsMatchingClass(
        dex: ByteArray,
        length: Int = dex.size,
        prefixes: List<ByteArray> = ChinaPackageMatcher.DEX_DESCRIPTOR_PREFIXES,
    ): Boolean {
        if (length < HEADER_SIZE || length > dex.size || prefixes.isEmpty()) {
            return false
        }
        if (!hasValidHeader(dex)) {
            return false
        }
        val stringIdsSize = readIntLE(dex, STRING_IDS_SIZE_OFF)
        val stringIdsOff = readIntLE(dex, STRING_IDS_OFF_OFF)
        val typeIdsSize = readIntLE(dex, TYPE_IDS_SIZE_OFF)
        val typeIdsOff = readIntLE(dex, TYPE_IDS_OFF_OFF)
        val classDefsSize = readIntLE(dex, CLASS_DEFS_SIZE_OFF)
        val classDefsOff = readIntLE(dex, CLASS_DEFS_OFF_OFF)
        if (stringIdsSize <= 0 || typeIdsSize <= 0 || classDefsSize <= 0) {
            return false
        }
        if (!tableInBounds(stringIdsOff, stringIdsSize, 4, length) ||
            !tableInBounds(typeIdsOff, typeIdsSize, 4, length) ||
            !tableInBounds(classDefsOff, classDefsSize, CLASS_DEF_ITEM_SIZE, length)
        ) {
            return false
        }

        val rangeStarts = IntArray(prefixes.size)
        val rangeEnds = IntArray(prefixes.size)
        var rangeCount = 0

        for (prefix in prefixes) {
            if (prefix.isEmpty()) continue
            val lo = lowerBound(dex, length, stringIdsOff, stringIdsSize, prefix)
            if (lo == INVALID_DEX) return false
            if (lo >= stringIdsSize) continue
            val matchCmp = compareDexStringToAsciiPrefix(
                dex = dex,
                length = length,
                stringIdsOff = stringIdsOff,
                stringIdx = lo,
                prefix = prefix,
                prefixMatch = true,
            )
            if (matchCmp == INVALID_DEX) return false
            if (matchCmp != 0) continue

            val hi = upperBoundPrefix(dex, length, stringIdsOff, lo + 1, stringIdsSize, prefix)
            if (hi == INVALID_DEX) return false
            if (rangeCount > 0 && lo <= rangeEnds[rangeCount - 1]) {
                rangeEnds[rangeCount - 1] = max(rangeEnds[rangeCount - 1], hi)
            } else {
                rangeStarts[rangeCount] = lo
                rangeEnds[rangeCount] = hi
                rangeCount++
            }
        }

        if (rangeCount == 0) {
            return false
        }

        for (i in 0 until classDefsSize) {
            val classIdx = readIntLE(dex, classDefsOff + i * CLASS_DEF_ITEM_SIZE)
            if (classIdx !in 0 until typeIdsSize) {
                return false
            }
            val descriptorIdx = readIntLE(dex, typeIdsOff + classIdx * 4)
            if (inRanges(descriptorIdx, rangeStarts, rangeEnds, rangeCount)) {
                return true
            }
        }
        return false
    }

    private fun hasValidHeader(dex: ByteArray): Boolean {
        if (dex[0] != 'd'.code.toByte() ||
            dex[1] != 'e'.code.toByte() ||
            dex[2] != 'x'.code.toByte() ||
            dex[3] != '\n'.code.toByte() ||
            dex[7] != 0.toByte()
        ) {
            return false
        }
        for (i in 4..6) {
            val digit = dex[i].toInt() and 0xff
            if (digit !in '0'.code..'9'.code) {
                return false
            }
        }
        return readIntLE(dex, 40) == ENDIAN_CONSTANT
    }

    private fun tableInBounds(offset: Int, count: Int, elementSize: Int, limit: Int): Boolean {
        if (offset < HEADER_SIZE || count < 0) return false
        return offset.toLong() + count.toLong() * elementSize.toLong() <= limit.toLong()
    }

    private fun lowerBound(
        dex: ByteArray,
        length: Int,
        stringIdsOff: Int,
        stringIdsSize: Int,
        prefix: ByteArray,
    ): Int {
        var lo = 0
        var hi = stringIdsSize
        while (lo < hi) {
            val mid = (lo + hi) ushr 1
            val cmp = compareDexStringToAsciiPrefix(
                dex = dex,
                length = length,
                stringIdsOff = stringIdsOff,
                stringIdx = mid,
                prefix = prefix,
                prefixMatch = false,
            )
            if (cmp == INVALID_DEX) return INVALID_DEX
            if (cmp < 0) {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }

    private fun upperBoundPrefix(
        dex: ByteArray,
        length: Int,
        stringIdsOff: Int,
        fromIndex: Int,
        stringIdsSize: Int,
        prefix: ByteArray,
    ): Int {
        var lo = fromIndex
        var hi = stringIdsSize
        while (lo < hi) {
            val mid = (lo + hi) ushr 1
            val cmp = compareDexStringToAsciiPrefix(
                dex = dex,
                length = length,
                stringIdsOff = stringIdsOff,
                stringIdx = mid,
                prefix = prefix,
                prefixMatch = true,
            )
            if (cmp == INVALID_DEX) return INVALID_DEX
            if (cmp <= 0) {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }

    // DEX string_ids are sorted by UTF-16 code units; for pure ASCII prefixes, only
    // MUTF-8 NUL (0xC0 0x80 -> U+0000) orders below ASCII while carrying a >= 0x80 lead byte.
    private fun compareDexStringToAsciiPrefix(
        dex: ByteArray,
        length: Int,
        stringIdsOff: Int,
        stringIdx: Int,
        prefix: ByteArray,
        prefixMatch: Boolean,
    ): Int {
        val dataOff = readIntLE(dex, stringIdsOff + stringIdx * 4)
        val utf8Start = skipUleb128(dex, length, dataOff)
        if (utf8Start < 0) return INVALID_DEX

        var pos = utf8Start
        for (targetByte in prefix) {
            if (pos >= length) return INVALID_DEX
            val b = dex[pos].toInt() and 0xff
            if (b == 0) {
                return -1
            }
            if (b == 0xc0 && pos + 1 < length && (dex[pos + 1].toInt() and 0xff) == 0x80) {
                return -1
            }
            val target = targetByte.toInt() and 0xff
            if (b >= 0x80) {
                return 1
            }
            if (b != target) {
                return if (b < target) -1 else 1
            }
            pos++
        }
        if (prefixMatch) {
            return 0
        }
        if (pos >= length) return INVALID_DEX
        return if (dex[pos].toInt() == 0) 0 else 1
    }

    private fun skipUleb128(dex: ByteArray, length: Int, offset: Int): Int {
        if (offset < 0 || offset >= length) return -1
        var pos = offset
        repeat(5) {
            if (pos >= length) return -1
            val byte = dex[pos++].toInt() and 0xff
            if ((byte and 0x80) == 0) {
                return pos
            }
        }
        return -1
    }

    private fun inRanges(
        value: Int,
        starts: IntArray,
        ends: IntArray,
        count: Int,
    ): Boolean {
        var lo = 0
        var hi = count - 1
        while (lo <= hi) {
            val mid = (lo + hi) ushr 1
            when {
                value < starts[mid] -> hi = mid - 1
                value >= ends[mid] -> lo = mid + 1
                else -> return true
            }
        }
        return false
    }

    private fun readIntLE(dex: ByteArray, offset: Int): Int =
        (dex[offset].toInt() and 0xff) or
            ((dex[offset + 1].toInt() and 0xff) shl 8) or
            ((dex[offset + 2].toInt() and 0xff) shl 16) or
            ((dex[offset + 3].toInt() and 0xff) shl 24)
}
