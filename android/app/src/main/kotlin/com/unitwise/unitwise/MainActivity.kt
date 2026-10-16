package com.unitwise.unitwise

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.unitwise.platform/energy"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getDevicePowerStats" -> {
                    try {
                        val stats = getDevicePowerInfo()
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get power stats: ${e.message}", null)
                    }
                }
                "shareText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val title = call.argument<String>("title") ?: "Share UnitWise Report"
                    shareReportText(text, title)
                    result.success(true)
                }
                "triggerHaptic" -> {
                    triggerHapticFeedback()
                    result.success(true)
                }
                "checkForUpdate" -> {
                    checkUpdateAvailableAsync(result)
                }
                "startUpdateDownload" -> {
                    val downloadUrl = call.argument<String>("url") ?: ""
                    val version = call.argument<String>("version") ?: "1.1.0"
                    downloadUpdateInternal(downloadUrl, version, result)
                }
                "installUpdate" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    try {
                        val success = triggerInternalPackageInstall(filePath)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", "Failed to launch installer: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getDevicePowerInfo(): Map<String, Any> {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager

        val batteryLevel = batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
        val isCharging = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val status = batteryManager?.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS) ?: -1
            status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL
        } else {
            false
        }

        val isPowerSaveMode = powerManager?.isPowerSaveMode ?: false

        return mapOf(
            "batteryLevel" to batteryLevel,
            "isCharging" to isCharging,
            "isPowerSaveMode" to isPowerSaveMode,
            "androidVersion" to Build.VERSION.RELEASE,
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "isOnlineDevice" to true
        )
    }

    private fun shareReportText(content: String, subject: String) {
        val sendIntent: Intent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, content)
            putExtra(Intent.EXTRA_SUBJECT, subject)
            type = "text/plain"
        }
        val shareIntent = Intent.createChooser(sendIntent, subject)
        startActivity(shareIntent)
    }

    private fun triggerHapticFeedback() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(40)
                }
            }
        } catch (_: Exception) {
            // Ignore if vibration permissions are not present
        }
    }

    private fun checkUpdateAvailableAsync(result: MethodChannel.Result) {
        Thread {
            try {
                val pInfo = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.PackageInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(packageName, 0)
                    }
                } catch (_: Exception) {
                    null
                }

                val currentVersion = pInfo?.versionName ?: "0.0.6"
                val currentBuild = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    pInfo?.longVersionCode?.toInt() ?: 6
                } else {
                    @Suppress("DEPRECATION")
                    pInfo?.versionCode ?: 6
                }

                var latestVersion = "0.0.6"
                var latestBuild = 6
                var releaseDate = "October 2026"
                var releaseNotes = "• Real live network auto-detection for smart plugs\n• Fluid spring-eased animations across all sections\n• Streamlined Settings\n• Multi-property isolation"
                var fileSizeMb = 15.6
                var downloadUrl = "https://github.com/Suvesh108/UnitWise/releases/download/v0.0.6/unitwise-v0.0.6.apk"

                // 1. Live network query to GitHub Releases API
                try {
                    val url = URL("https://api.github.com/repos/Suvesh108/UnitWise/releases/latest")
                    val conn = (url.openConnection() as HttpURLConnection).apply {
                        connectTimeout = 8000
                        readTimeout = 8000
                        setRequestProperty("User-Agent", "UnitWise-App")
                        setRequestProperty("Accept", "application/vnd.github.v3+json")
                    }
                    if (conn.responseCode == 200) {
                        val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                        val json = JSONObject(responseText)
                        val tagName = json.optString("tag_name", "").replace("v", "").trim()
                        if (tagName.isNotEmpty()) {
                            latestVersion = tagName
                            latestBuild = tagName.split(".").lastOrNull()?.toIntOrNull() ?: 5
                        }
                        val body = json.optString("body", "")
                        if (body.isNotEmpty()) {
                            releaseNotes = body
                        }
                        val publishedAt = json.optString("published_at", "")
                        if (publishedAt.length >= 10) {
                            releaseDate = publishedAt.substring(0, 10)
                        }
                        val assets = json.optJSONArray("assets")
                        if (assets != null && assets.length() > 0) {
                            for (i in 0 until assets.length()) {
                                val asset = assets.getJSONObject(i)
                                val name = asset.optString("name", "")
                                if (name.endsWith(".apk")) {
                                    downloadUrl = asset.optString("browser_download_url", downloadUrl)
                                    val size = asset.optLong("size", 0)
                                    if (size > 0) {
                                        fileSizeMb = ((size / (1024.0 * 1024.0)) * 10).toInt() / 10.0
                                    }
                                    break
                                }
                            }
                        }
                    }
                } catch (_: Exception) {
                    // Fallback to local manifest on offline/network errors
                }

                val hasUpdate = isVersionNewer(latestVersion, currentVersion)
                val updateMap = mapOf(
                    "hasUpdate" to hasUpdate,
                    "currentVersion" to currentVersion,
                    "currentBuild" to currentBuild,
                    "latestVersion" to latestVersion,
                    "latestBuild" to latestBuild,
                    "releaseDate" to releaseDate,
                    "releaseNotes" to releaseNotes,
                    "fileSizeMb" to fileSizeMb,
                    "downloadUrl" to downloadUrl
                )

                Handler(Looper.getMainLooper()).post {
                    result.success(updateMap)
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("UPDATE_CHECK_ERROR", "Update check failed: ${e.message}", null)
                }
            }
        }.start()
    }

    private fun isVersionNewer(latest: String, current: String): Boolean {
        try {
            val latestParts = latest.split(".").map { it.toIntOrNull() ?: 0 }
            val currentParts = current.split(".").map { it.toIntOrNull() ?: 0 }
            for (i in 0 until maxOf(latestParts.size, currentParts.size)) {
                val l = latestParts.getOrElse(i) { 0 }
                val c = currentParts.getOrElse(i) { 0 }
                if (l > c) return true
                if (l < c) return false
            }
        } catch (_: Exception) {}
        return false
    }

    private fun downloadUpdateInternal(downloadUrl: String, version: String, result: MethodChannel.Result) {
        Thread {
            try {
                val updateDir = File(cacheDir, "updates")
                if (!updateDir.exists()) {
                    updateDir.mkdirs()
                }
                val outputFile = File(updateDir, "unitwise-v$version.apk")
                if (outputFile.exists()) {
                    outputFile.delete()
                }

                if (!downloadUrl.startsWith("http://") && !downloadUrl.startsWith("https://")) {
                    throw Exception("Invalid download URL: $downloadUrl")
                }

                var currentUrl = downloadUrl
                var redirects = 0
                var conn: HttpURLConnection? = null

                // Traverse redirects (GitHub Releases redirect to AWS S3 CDN: objects.githubusercontent.com)
                while (redirects < 6) {
                    val url = URL(currentUrl)
                    conn = (url.openConnection() as HttpURLConnection).apply {
                        connectTimeout = 15000
                        readTimeout = 30000
                        instanceFollowRedirects = true
                        setRequestProperty("User-Agent", "UnitWise-OTA-Updater")
                    }
                    conn.connect()
                    val code = conn.responseCode
                    if (code in listOf(HttpURLConnection.HTTP_MOVED_PERM, HttpURLConnection.HTTP_MOVED_TEMP, 307, 308)) {
                        val newLocation = conn.getHeaderField("Location")
                        if (!newLocation.isNullOrEmpty()) {
                            currentUrl = newLocation
                            redirects++
                            conn.disconnect()
                            continue
                        }
                    }
                    break
                }

                if (conn == null || conn.responseCode != HttpURLConnection.HTTP_OK) {
                    throw Exception("Download server returned HTTP ${conn?.responseCode ?: -1}")
                }

                val fileLength = conn.contentLength
                val input: InputStream = conn.inputStream
                val output = FileOutputStream(outputFile)

                val data = ByteArray(8192)
                var total: Long = 0
                var count: Int
                while (input.read(data).also { count = it } != -1) {
                    total += count.toLong()
                    output.write(data, 0, count)
                    val progress = if (fileLength > 0) (total * 100 / fileLength).toInt() else 0
                    runOnUiThread {
                        methodChannel?.invokeMethod(
                            "onDownloadProgress",
                            mapOf("progress" to progress, "downloaded" to total, "total" to fileLength)
                        )
                    }
                }
                output.flush()
                output.close()
                input.close()
                conn.disconnect()

                if (!outputFile.exists() || outputFile.length() == 0L) {
                    throw Exception("Downloaded file is empty")
                }

                runOnUiThread {
                    methodChannel?.invokeMethod(
                        "onDownloadProgress",
                        mapOf("progress" to 100, "downloaded" to outputFile.length(), "total" to outputFile.length())
                    )
                    result.success(outputFile.absolutePath)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("DOWNLOAD_ERROR", "Internal download failed: ${e.message}", null)
                }
            }
        }.start()
    }

    private fun triggerInternalPackageInstall(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        // On Android 8.0+ (Oreo), check if app is permitted to request package installs
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!packageManager.canRequestPackageInstalls()) {
                val manageIntent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(manageIntent)
                return false
            }
        }

        val authority = "${applicationContext.packageName}.fileprovider"
        val apkUri: Uri = FileProvider.getUriForFile(applicationContext, authority, file)

        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(installIntent)
        return true
    }
}
