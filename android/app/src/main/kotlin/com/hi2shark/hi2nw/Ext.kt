package com.hi2shark.hi2nw

import android.app.Application
import android.content.Context.MODE_PRIVATE
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import androidx.core.graphics.drawable.toBitmap
import com.hi2shark.hi2nw.common.GlobalState
import com.hi2shark.hi2nw.models.SharedState
import com.google.gson.Gson
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

private const val ICON_ORPHAN_TTL_DAYS = 30L
private const val ICON_TOUCH_INTERVAL_DAYS = 7L
private val iconSweepStarted = AtomicBoolean(false)

val Application.sharedState: SharedState
    get() = try {
        val preferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val json = preferences.getString("flutter.sharedState", null)
        Gson().fromJson(json, SharedState::class.java) ?: SharedState()
    } catch (_: Exception) {
        SharedState()
    }

private var lastToast: Toast? = null

fun Application.showToast(text: String?) {
    if (text.isNullOrEmpty()) return
    Handler(Looper.getMainLooper()).post {
        lastToast?.cancel()
        lastToast = Toast.makeText(this, text, Toast.LENGTH_LONG).apply {
            show()
        }
    }
}

// A directory per package, so a new version replaces only that package's icon
// file; `icons` holds the flat layout of earlier releases.
private val packageIconDir by lazy {
    val cacheDir = GlobalState.application.cacheDir
    File(cacheDir, "icons").deleteRecursively()
    File(cacheDir, "package_icons")
}

suspend fun PackageManager.getPackageIconPath(packageName: String): String =
    withContext(Dispatchers.IO) {
        val iconDir = packageIconDir.apply { mkdirs() }
        pruneStaleIconsOnce(iconDir)
        return@withContext try {
            val lastUpdateTime = getPackageInfo(packageName, 0).lastUpdateTime
            val packageDir = File(iconDir, packageName)
            val iconFile = File(packageDir, "$lastUpdateTime.webp")
            if (iconFile.exists()) {
                val now = System.currentTimeMillis()
                if (now - iconFile.lastModified() > TimeUnit.DAYS.toMillis(ICON_TOUCH_INTERVAL_DAYS)) {
                    iconFile.setLastModified(now)
                }
                return@withContext iconFile.absolutePath
            }
            packageDir.deleteRecursively()
            packageDir.mkdirs()

            val icon = getApplicationIcon(packageName)
            saveDrawableToFile(icon, iconFile)
            iconFile.absolutePath
        } catch (_: Exception) {
            val defaultIconFile = File(iconDir, "default_icon.webp")
            if (!defaultIconFile.exists()) {
                saveDrawableToFile(defaultActivityIcon, defaultIconFile)
            }
            defaultIconFile.absolutePath
        }
    }

private suspend fun saveDrawableToFile(drawable: Drawable, file: File) {
    val bitmap = withContext(Dispatchers.Default) {
        drawable.toBitmap(width = 128, height = 128)
    }
    // Callers trust any file that exists, so only a complete one may take its name.
    val partial = File.createTempFile(file.name, ".tmp", file.parentFile)
    try {
        @Suppress("DEPRECATION")
        val format = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bitmap.CompressFormat.WEBP_LOSSY
        } else {
            Bitmap.CompressFormat.WEBP
        }
        val written = FileOutputStream(partial).use { fos ->
            bitmap.compress(format, 90, fos)
        }
        if (!written || !partial.renameTo(file)) {
            throw IOException("could not write ${file.name}")
        }
    } finally {
        partial.delete()
        if (!bitmap.isRecycled) bitmap.recycle()
    }
}

private fun pruneStaleIconsOnce(iconDir: File) {
    if (!iconSweepStarted.compareAndSet(false, true)) {
        return
    }
    val cutoff = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(ICON_ORPHAN_TTL_DAYS)
    iconDir.listFiles()?.forEach { entry ->
        if (entry.name == "default_icon.webp") {
            return@forEach
        }
        val latestModified = if (entry.isDirectory) {
            entry.listFiles()?.maxOfOrNull { it.lastModified() } ?: entry.lastModified()
        } else {
            entry.lastModified()
        }
        if (latestModified < cutoff) {
            entry.deleteRecursively()
        }
    }
}

inline fun <reified T : FlutterPlugin> FlutterEngine.plugin(): T? {
    return plugins.get(T::class.java) as T?
}

fun MethodChannel.invokeMethodOnMainThread(method: String, arguments: Any? = null) {
    Handler(Looper.getMainLooper()).post {
        invokeMethod(method, arguments)
    }
}
