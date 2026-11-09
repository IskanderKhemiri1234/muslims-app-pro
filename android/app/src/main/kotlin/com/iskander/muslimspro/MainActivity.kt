
package com.iskander.muslimspro

import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL_NAME =
            "com.iskander.muslimspro/prayer_countdown"
        private const val APP_INFO_CHANNEL_NAME =
            "com.iskander.muslimspro/app_info"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_INFO_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> result.success(BuildConfig.VERSION_NAME)
                "installApk" -> {
                    try {
                        val filePath = call.argument<String>("filePath")
                            ?: throw IllegalArgumentException(
                                "APK file path is missing."
                            )
                        val apkFile = File(filePath)
                        if (!apkFile.isFile || apkFile.length() <= 0L) {
                            throw IllegalArgumentException(
                                "Downloaded APK file is missing or empty."
                            )
                        }

                        val apkUri = FileProvider.getUriForFile(
                            applicationContext,
                            "${BuildConfig.APPLICATION_ID}.fileprovider",
                            apkFile
                        )
                        val installIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(
                                apkUri,
                                "application/vnd.android.package-archive"
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(installIntent)
                        result.success(true)
                    } catch (exception: Exception) {
                        result.error(
                            "APK_INSTALL_ERROR",
                            exception.message ?: "Unable to open Android installer.",
                            null
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "syncPrayerCountdown" -> {
                    try {
                        val rawEntries = call.argument<List<*>>("entries")
                            ?: throw IllegalArgumentException(
                                "Prayer countdown entries are missing."
                            )

                        val entries = rawEntries.mapIndexed { index, item ->
                            val rawMap = item as? Map<*, *>
                                ?: throw IllegalArgumentException(
                                    "Invalid prayer entry at index $index."
                                )

                            val prayer = rawMap["prayer"] as? String
                                ?: throw IllegalArgumentException(
                                    "Missing prayer identifier at index $index."
                                )

                            val name = rawMap["name"] as? String
                                ?: throw IllegalArgumentException(
                                    "Missing prayer name at index $index."
                                )

                            val timeMillis = (rawMap["timeMillis"] as? Number)
                                ?.toLong()
                                ?: throw IllegalArgumentException(
                                    "Invalid prayer time at index $index."
                                )

                            mapOf<String, Any>(
                                "prayer" to prayer,
                                "name" to name,
                                "timeMillis" to timeMillis
                            )
                        }

                        val title = call.argument<String>("title")
                            ?.takeIf { it.isNotBlank() }
                            ?: throw IllegalArgumentException(
                                "Notification title is missing."
                            )

                        val description =
                            call.argument<String>("description")
                                ?.takeIf { it.isNotBlank() }
                                ?: throw IllegalArgumentException(
                                    "Notification description is missing."
                                )

                        val timezone = call.argument<String>("timezone")
                            ?.takeIf { it.isNotBlank() }
                            ?: throw IllegalArgumentException(
                                "Timezone is missing."
                            )

                        MuminPrayerCountdownNotifications.synchronize(
                            applicationContext,
                            entries,
                            title,
                            description,
                            timezone
                        )

                        result.success(null)

                    } catch (exception: Exception) {
                        result.error(
                            "PRAYER_COUNTDOWN_SYNC_ERROR",
                            exception.message
                                ?: "Unable to synchronize prayer countdown.",
                            null
                        )
                    }
                }

                "cancelPrayerCountdown" -> {
                    try {
                        MuminPrayerCountdownNotifications.cancel(
                            applicationContext
                        )
                        result.success(null)

                    } catch (exception: Exception) {
                        result.error(
                            "PRAYER_COUNTDOWN_CANCEL_ERROR",
                            exception.message
                                ?: "Unable to cancel prayer countdown.",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
