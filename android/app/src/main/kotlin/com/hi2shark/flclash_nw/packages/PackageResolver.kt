package com.hi2shark.flclash_nw.packages

import android.Manifest
import android.content.pm.ApplicationInfo
import android.content.pm.ComponentInfo
import android.content.pm.PackageManager
import android.os.Build
import com.hi2shark.flclash_nw.models.InstalledPackage
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.zip.ZipFile

internal class PackageResolver(
    private val packageManager: PackageManager,
    private val appPackageName: String,
) {
    private val cacheLock = Any()
    private val scanLock = Any()
    private val chinaPackageCache = ConcurrentHashMap<String, Pair<Long, Boolean>>()

    @Volatile
    private var cachedPackages: List<InstalledPackage>? = null

    val installedPackages: List<InstalledPackage>
        get() = cachedPackages ?: synchronized(cacheLock) {
            cachedPackages ?: loadPackages().also { cachedPackages = it }
        }

    val isInstalledAppsPermissionSupported: Boolean by lazy {
        runCatching { packageManager.getPermissionInfo(GET_INSTALLED_APPS, 0) }.isSuccess
    }

    fun hasInstalledAppsPermission(): Boolean = !isInstalledAppsPermissionSupported ||
        packageManager.checkPermission(GET_INSTALLED_APPS, appPackageName) ==
        PackageManager.PERMISSION_GRANTED

    fun invalidate() {
        synchronized(cacheLock) { cachedPackages = null }
    }

    fun clearTransientCaches() {
        synchronized(cacheLock) { cachedPackages = null }
        chinaPackageCache.clear()
    }

    fun getChinaPackageNames(): List<String> = synchronized(scanLock) {
        val packages = installedPackages
        val activeNames = packages.mapTo(HashSet(packages.size)) { it.packageName }
        chinaPackageCache.keys.retainAll(activeNames)
        val scratch = DexReadBuffer(MAX_DEX_SIZE_BYTES.toInt())
        packages.filter { pkg ->
            val cached = chinaPackageCache[pkg.packageName]
            if (cached != null && cached.first == pkg.lastUpdateTime) {
                cached.second
            } else {
                isChinaPackage(pkg.packageName, scratch).also { matched ->
                    chinaPackageCache[pkg.packageName] = pkg.lastUpdateTime to matched
                }
            }
        }.map { it.packageName }
    }

    private fun loadPackages(): List<InstalledPackage> {
        val flags = PackageManager.GET_PERMISSIONS
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledPackages(flags)
        }
        return packages.asSequence()
            .filter { info ->
                info.packageName != appPackageName && info.packageName != ANDROID_PACKAGE_NAME
            }
            .map { info ->
                InstalledPackage(
                    packageName = info.packageName,
                    label = info.applicationInfo?.loadLabel(packageManager)?.toString()
                        ?: info.packageName,
                    system = info.applicationInfo?.let { applicationInfo ->
                        applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0
                    } == true,
                    internet = info.requestedPermissions
                        ?.contains(Manifest.permission.INTERNET) == true,
                    lastUpdateTime = info.lastUpdateTime,
                )
            }.toList()
    }

    private fun isChinaPackage(packageName: String, scratch: DexReadBuffer): Boolean {
        if (ChinaPackageMatcher.isSkipped(packageName)) {
            return false
        }
        if (ChinaPackageMatcher.matchesKnownPrefix(packageName)) {
            return true
        }

        return try {
            val packageInfo = getPackageInfo(packageName)
            packageInfo.componentNames().any(ChinaPackageMatcher::matchesKnownPrefix) ||
                packageInfo.applicationInfo?.publicSourceDir?.let { scanArchive(it, scratch) } == true
        } catch (_: Exception) {
            false
        }
    }

    private fun getPackageInfo(packageName: String) = if (
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
    ) {
        packageManager.getPackageInfo(
            packageName,
            PackageManager.PackageInfoFlags.of(PACKAGE_INFO_FLAGS.toLong()),
        )
    } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageInfo(packageName, PACKAGE_INFO_FLAGS)
    }

    private fun android.content.pm.PackageInfo.componentNames(): Sequence<String> = sequence {
        yieldAll(services.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(activities.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(receivers.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(providers.orEmpty().asSequence().map(ComponentInfo::name))
    }

    private fun scanArchive(sourcePath: String, scratch: DexReadBuffer): Boolean =
        ZipFile(File(sourcePath)).use { archive ->
            if (archive.entries().asSequence().any { it.name.startsWith("firebase-") }) {
                return false
            }
            archive.entries().asSequence()
                .filter { entry ->
                    entry.name.startsWith("classes") && entry.name.endsWith(".dex")
                }.any { entry ->
                    if (entry.size > MAX_DEX_SIZE_BYTES) {
                        return@any true
                    }
                    val length = archive.getInputStream(entry).use { input ->
                        scratch.readAll(input, entry.size)
                    }
                    if (length == DexReadBuffer.OVERSIZED) {
                        return@any true
                    }
                    DexClassPrefixScanner.containsMatchingClass(scratch.bytes, length)
                }
        }

    companion object {
        const val GET_INSTALLED_APPS = "com.android.permission.GET_INSTALLED_APPS"

        private const val ANDROID_PACKAGE_NAME = "android"
        private const val MAX_DEX_SIZE_BYTES = 15_000_000L

        private val PACKAGE_INFO_FLAGS = PackageManager.GET_ACTIVITIES or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS or
            PackageManager.GET_PROVIDERS
    }
}
