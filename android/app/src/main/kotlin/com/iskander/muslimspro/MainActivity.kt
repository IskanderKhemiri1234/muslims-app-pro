
package com.iskander.muslimspro

import android.content.Intent
import android.location.Geocoder
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.Executors

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL_NAME =
            "com.iskander.muslimspro/prayer_countdown"
        private const val APP_INFO_CHANNEL_NAME =
            "com.iskander.muslimspro/app_info"
        private val geocodingExecutor = Executors.newSingleThreadExecutor()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_INFO_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> result.success(BuildConfig.VERSION_NAME)
                "reverseGeocode" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val languageCode = call.argument<String>("languageCode")
                        ?.trim()
                        ?.lowercase(Locale.ROOT)
                        ?.takeIf { it in setOf("ar", "en", "fr") }
                        ?: "en"

                    if (latitude == null || longitude == null ||
                        !latitude.isFinite() || !longitude.isFinite() ||
                        latitude !in -90.0..90.0 ||
                        longitude !in -180.0..180.0
                    ) {
                        result.error(
                            "INVALID_COORDINATES",
                            "Valid latitude and longitude are required.",
                            null
                        )
                    } else {
                        geocodingExecutor.execute {
                            try {
                                if (!Geocoder.isPresent()) {
                                    throw IllegalStateException(
                                        "Geocoding is not available on this device."
                                    )
                                }

                                val geocoder = Geocoder(
                                    this@MainActivity,
                                    Locale.forLanguageTag(languageCode)
                                )

                                @Suppress("DEPRECATION")
                                val addresses = geocoder.getFromLocation(
                                    latitude,
                                    longitude,
                                    5
                                )

                                val address = addresses
                                    ?.firstOrNull { it.maxAddressLineIndex >= 0 }
                                    ?: addresses?.firstOrNull()

                                val placeName = listOfNotNull(
                                    address?.subLocality,
                                    address?.thoroughfare,
                                    address?.featureName
                                ).firstOrNull { it.isNotBlank() }

                                val city = listOfNotNull(
                                    address?.locality,
                                    address?.subAdminArea,
                                    address?.subLocality,
                                    address?.adminArea
                                ).firstOrNull { it.isNotBlank() }

                                val region = listOfNotNull(
                                    address?.adminArea,
                                    address?.subAdminArea
                                ).firstOrNull { it.isNotBlank() }

                                val payload = mapOf(
                                    "placeName" to placeName,
                                    "city" to city,
                                    "region" to region,
                                    "country" to address?.countryName,
                                    "formattedAddress" to address?.getAddressLine(0)
                                )

                                runOnUiThread {
                                    result.success(payload)
                                }
                            } catch (exception: Exception) {
                                runOnUiThread {
                                    result.error(
                                        "REVERSE_GEOCODING_ERROR",
                                        exception.message
                                            ?: "Unable to resolve the current place name.",
                                        null
                                    )
                                }
                            }
                        }
                    }
                }
                "verifyApk" -> {
                    try {
                        val filePath = call.argument<String>("filePath")
                            ?: throw IllegalArgumentException(
                                "APK file path is missing."
                            )
                        val expectedSha256 = call.argument<String>("sha256")
                            ?.trim()
                            ?.lowercase(Locale.ROOT)
                            ?: throw IllegalArgumentException(
                                "Expected APK SHA-256 digest is missing."
                            )

                        if (!expectedSha256.matches(Regex("^[0-9a-f]{64}$"))) {
                            throw IllegalArgumentException(
                                "Expected APK SHA-256 digest is invalid."
                            )
                        }

                        val apkFile = File(filePath)
                        if (!apkFile.isFile || apkFile.length() <= 0L) {
                            throw IllegalArgumentException(
                                "Downloaded APK file is missing or empty."
                            )
                        }

                        val digest = MessageDigest.getInstance("SHA-256")
                        FileInputStream(apkFile).buffered().use { input ->
                            val buffer = ByteArray(64 * 1024)
                            while (true) {
                                val bytesRead = input.read(buffer)
                                if (bytesRead < 0) break
                                digest.update(buffer, 0, bytesRead)
                            }
                        }

                        val actualSha256 = digest.digest().joinToString("") {
                            "%02x".format(it.toInt() and 0xff)
                        }
                        val isValid = MessageDigest.isEqual(
                            actualSha256.toByteArray(Charsets.US_ASCII),
                            expectedSha256.toByteArray(Charsets.US_ASCII)
                        )
                        result.success(isValid)
                    } catch (exception: Exception) {
                        result.error(
                            "APK_VERIFICATION_ERROR",
                            exception.message ?: "Unable to verify the downloaded APK.",
                            null
                        )
                    }
                }
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

                "getPrayerCountdownDiagnostics" -> {
                    try {
                        result.success(
                            MuminPrayerCountdownNotifications.diagnostics(
                                applicationContext
                            )
                        )
                    } catch (exception: Exception) {
                        result.error(
                            "PRAYER_COUNTDOWN_DIAGNOSTICS_ERROR",
                            exception.message
                                ?: "Unable to read Android countdown diagnostics.",
                            null
                        )
                    }
                }

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

                            val englishName = rawMap["englishName"] as? String
                                ?: prayer

                            val timeMillis = (rawMap["timeMillis"] as? Number)
                                ?.toLong()
                                ?: throw IllegalArgumentException(
                                    "Invalid prayer time at index $index."
                                )

                            mapOf<String, Any>(
                                "prayer" to prayer,
                                "name" to name,
                                "englishName" to englishName,
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
