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
                    try {
                        val updateInfo = checkUpdateAvailable()
                        result.success(updateInfo)
                    } catch (e: Exception) {
                        result.error("UPDATE_CHECK_ERROR", "Update check failed: ${e.message}", null)
                    }
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

    private fun checkUpdateAvailable(): Map<String, Any> {
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

        val currentVersion = pInfo?.versionName ?: "0.0.1"
        val currentBuild = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            pInfo?.longVersionCode?.toInt() ?: 1
        } else {
            @Suppress("DEPRECATION")
            pInfo?.versionCode ?: 1
        }

        return mapOf(
            "hasUpdate" to true,
            "currentVersion" to currentVersion,
            "currentBuild" to currentBuild,
            "latestVersion" to "0.0.2",
            "latestBuild" to 2,
            "releaseDate" to "October 2026",
            "releaseNotes" to "• All-new high visual density Dashboard with Power Balance Dial\n• Modern 74dp bottom navigation bar with persistent labels & symbols\n• Zero-overflow responsive layout across all Android screens\n• Real UnitWise Android launcher icon across all mipmap densities\n• Robust in-app OTA updater with direct GitHub Releases CDN streaming",
            "fileSizeMb" to 15.2,
            "downloadUrl" to "https://github.com/Suvesh108/UnitWise/releases/download/v0.0.2/unitwise-v0.0.2.apk"
        )
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
