
package com.iskander.muslimspro

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
