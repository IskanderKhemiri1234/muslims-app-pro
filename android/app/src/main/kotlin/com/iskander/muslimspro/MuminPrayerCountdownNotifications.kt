package com.iskander.muslimspro

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

object MuminPrayerCountdownNotifications {

    private const val TAG = "MuminPrayerCountdown"
    private const val CHANNEL_ID = "mumin_next_prayer_countdown_v2"
    private const val NOTIFICATION_ID = 73104
    private const val PREFERENCES = "mumin_prayer_countdown"
    private const val ENTRIES_KEY = "entries"
    private const val TITLE_KEY = "title"
    private const val DESCRIPTION_KEY = "description"
    private const val TIMEZONE_KEY = "timezone"
    private const val ALARM_REQUEST_CODE = 73105

    fun synchronize(
        context: Context,
        entries: List<Map<String, Any>>,
        title: String,
        description: String,
        timezone: String
    ) {
        val jsonEntries = JSONArray()
        entries.forEach { entry ->
            val timestamp = (entry["timeMillis"] as? Number)?.toLong()
                ?: return@forEach
            val name = entry["name"]?.toString()?.trim().orEmpty()
            val prayer = entry["prayer"]?.toString().orEmpty()
            val englishName = entry["englishName"]?.toString()?.trim()
                .orEmpty().ifBlank { prayer }

            if (timestamp <= 0L || name.isEmpty() || prayer.isEmpty()) {
                return@forEach
            }

            jsonEntries.put(
                JSONObject()
                    .put("timeMillis", timestamp)
                    .put("name", name)
                    .put("englishName", englishName)
                    .put("prayer", prayer)
            )
        }

        check(jsonEntries.length() > 0) {
            "No valid future prayer entries reached Android."
        }

        val saved = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(ENTRIES_KEY, jsonEntries.toString())
            .putString(TITLE_KEY, title)
            .putString(DESCRIPTION_KEY, description)
            .putString(TIMEZONE_KEY, timezone)
            .commit()

        check(saved) {
            "Android could not persist the next-prayer schedule."
        }

        Log.i(TAG, "SYNC persisted entries=${jsonEntries.length()} timezone=$timezone")
        refresh(context)
    }

    fun diagnostics(context: Context): Map<String, Any?> {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.getNotificationChannel(CHANNEL_ID)
        } else {
            null
        }
        val storedEntries = preferences.getString(ENTRIES_KEY, null)
        val entries = try {
            storedEntries?.let { JSONArray(it) }
        } catch (exception: Exception) {
            null
        }
        val now = System.currentTimeMillis()
        var nextPrayer: JSONObject? = null
        var nextPrayerTime = Long.MAX_VALUE
        if (entries != null) {
            for (index in 0 until entries.length()) {
                val entry = entries.optJSONObject(index) ?: continue
                val timestamp = entry.optLong("timeMillis", 0L)
                if (timestamp > now && timestamp < nextPrayerTime) {
                    nextPrayer = entry
                    nextPrayerTime = timestamp
                }
            }
        }
        var activeNotification = false
        var activeNotificationCheckError: String? = null
        try {
            activeNotification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.activeNotifications.any { it.id == NOTIFICATION_ID }
            } else {
                false
            }
        } catch (exception: SecurityException) {
            activeNotificationCheckError = exception.message ?: exception.javaClass.simpleName
        }

        val permissionGranted =
            Build.VERSION.SDK_INT < 33 ||
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        val notificationsEnabled =
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        val channelImportance = channel?.importance ?: -1

        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "permissionGranted" to permissionGranted,
            "notificationsEnabled" to notificationsEnabled,
            "channelId" to CHANNEL_ID,
            "channelExists" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || channel != null),
            "channelImportance" to channelImportance,
            "channelBlocked" to (channelImportance == NotificationManager.IMPORTANCE_NONE),
            "notificationId" to NOTIFICATION_ID,
            "activeNotification" to activeNotification,
            "activeNotificationCheckError" to activeNotificationCheckError,
            "scheduleStored" to (storedEntries != null),
            "storedEntriesCount" to (entries?.length() ?: 0),
            "timezone" to preferences.getString(TIMEZONE_KEY, null),
            "nextPrayerName" to nextPrayer?.optString("name"),
            "nextPrayerEnglishName" to nextPrayer?.optString("englishName"),
            "nextPrayerTimeMillis" to nextPrayer?.optLong("timeMillis")
        )
    }

    fun cancel(context: Context) {
        cancelAlarm(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        manager.cancel(NOTIFICATION_ID)
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        Log.i(TAG, "Countdown notification and next-prayer alarm cancelled")
    }

    fun refresh(context: Context) {
        createNotificationChannel(context)
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val storedEntries = preferences.getString(ENTRIES_KEY, null) ?: run {
            cancelAlarm(context)
            Log.w(TAG, "REFRESH skipped: no stored prayer schedule")
            return
        }

        val entries = try {
            JSONArray(storedEntries)
        } catch (exception: Exception) {
            Log.e(TAG, "REFRESH failed: stored prayer schedule is invalid", exception)
            cancel(context)
            return
        }

        val now = System.currentTimeMillis()
        var nextEntry: JSONObject? = null
        var nextTime = Long.MAX_VALUE
        for (index in 0 until entries.length()) {
            val entry = entries.optJSONObject(index) ?: continue
            val timestamp = entry.optLong("timeMillis", 0L)
            if (timestamp > now && timestamp < nextTime) {
                nextEntry = entry
                nextTime = timestamp
            }
        }

        if (nextEntry == null) {
            cancelAlarm(context)
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            manager.cancel(NOTIFICATION_ID)
            Log.w(TAG, "REFRESH found no future prayer in stored schedule")
            return
        }

        val prayerName = nextEntry.optString("englishName")
            .ifBlank { nextEntry.optString("name") }
        val title = preferences.getString(TITLE_KEY, "Mumin Pro") ?: "Mumin Pro"
        val description = preferences.getString(DESCRIPTION_KEY, "") ?: ""

        // Schedule the transition before posting UI. A notification rendering
        // failure must never prevent the next prayer refresh from being armed.
        scheduleNextTransition(context, nextTime)
        showNotification(context, title, prayerName, description, nextTime)
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Mumin Pro",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Persistent countdown to the next prayer"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
        val createdChannel = manager.getNotificationChannel(CHANNEL_ID)
        check(createdChannel != null &&
            createdChannel.importance != NotificationManager.IMPORTANCE_NONE) {
            "The new Mumin Pro persistent-countdown notification channel is blocked."
        }
        Log.i(
            TAG,
            "CHANNEL_READY id=$CHANNEL_ID importance=${createdChannel.importance}"
        )
    }

    private fun createBaseBuilder(
        context: Context,
        title: String,
        prayerName: String,
        description: String,
        targetTime: Long
    ): Notification.Builder {
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }

        return builder.apply {
            setSmallIcon(R.drawable.ic_mumin_notification)
            setContentTitle(title)
            setContentText(
                if (description.isBlank()) prayerName else "$prayerName • $description"
            )
            setContentIntent(contentIntent)
            setCategory(Notification.CATEGORY_STATUS)
            setVisibility(Notification.VISIBILITY_PUBLIC)
            setShowWhen(true)
            // Notification chronometers use elapsedRealtime(), not
            // wall-clock epoch milliseconds. Passing targetTime directly
            // makes Android calculate an invalid countdown base.
            val remainingMillis =
                (targetTime - System.currentTimeMillis()).coerceAtLeast(0L)
            setWhen(SystemClock.elapsedRealtime() + remainingMillis)
            setUsesChronometer(true)
            setOngoing(true)
            setAutoCancel(false)
            setOnlyAlertOnce(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                setChronometerCountDown(true)
            }
        }
    }

    private fun showNotification(
        context: Context,
        title: String,
        prayerName: String,
        description: String,
        targetTime: Long
    ) {
        if (
            Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("POST_NOTIFICATIONS is not granted.")
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            throw IllegalStateException("Android reports notifications disabled.")
        }
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL_ID)?.importance ==
                NotificationManager.IMPORTANCE_NONE
        ) {
            throw IllegalStateException("The Mumin Pro countdown channel is blocked.")
        }

        val remainingMillis = (targetTime - System.currentTimeMillis()).coerceAtLeast(0L)
        val chronometerBase = SystemClock.elapsedRealtime() + remainingMillis

        // Phase 1: post a complete platform-native notification first. It is
        // deliberately independent of RemoteViews and remains as fallback.
        val baseNotification = createBaseBuilder(
            context, title, prayerName, description, targetTime
        ).build()
        manager.notify(NOTIFICATION_ID, baseNotification)
        Log.i(
            TAG,
            "BASE_POSTED id=$NOTIFICATION_ID target=$targetTime remainingMs=$remainingMillis"
        )

        if (!isNotificationActive(manager)) {
            throw IllegalStateException(
                "NotificationManager.notify returned but notification $NOTIFICATION_ID is not active."
            )
        }

        // Phase 2: enhance the already-visible notification. Any failure in
        // custom layout inflation/action application leaves the base intact.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        try {
            val compactView = RemoteViews(
                context.packageName,
                R.layout.mumin_prayer_countdown_collapsed
            ).apply {
                setImageViewResource(R.id.mumin_countdown_logo, R.drawable.mumin_pro_brand)
                setTextViewText(R.id.mumin_countdown_title, title)
                setTextViewText(R.id.mumin_countdown_prayer, prayerName)
                setChronometer(R.id.mumin_countdown_timer, chronometerBase, null, true)
                setChronometerCountDown(R.id.mumin_countdown_timer, true)
            }

            val expandedView = RemoteViews(
                context.packageName,
                R.layout.mumin_prayer_countdown_expanded
            ).apply {
                setImageViewResource(R.id.mumin_countdown_logo, R.drawable.mumin_pro_brand)
                setTextViewText(R.id.mumin_countdown_title, title)
                setTextViewText(R.id.mumin_countdown_prayer, prayerName)
                setTextViewText(R.id.mumin_countdown_label, description)
                setChronometer(R.id.mumin_countdown_timer, chronometerBase, null, true)
                setChronometerCountDown(R.id.mumin_countdown_timer, true)
            }

            val customNotification = createBaseBuilder(
                context, title, prayerName, description, targetTime
            )
                .setStyle(Notification.DecoratedCustomViewStyle())
                .setCustomContentView(compactView)
                .setCustomBigContentView(expandedView)
                .build()

            manager.notify(NOTIFICATION_ID, customNotification)
            Log.i(TAG, "CUSTOM_POSTED id=$NOTIFICATION_ID")
            if (!isNotificationActive(manager)) {
                Log.e(TAG, "CUSTOM_POST not active; restoring platform-native notification")
                manager.notify(NOTIFICATION_ID, baseNotification)
            }
        } catch (exception: Exception) {
            Log.e(
                TAG,
                "CUSTOM_RENDER_SETUP_FAILED; retaining/restoring platform-native notification",
                exception
            )
            manager.notify(NOTIFICATION_ID, baseNotification)
        } catch (error: LinkageError) {
            Log.e(
                TAG,
                "CUSTOM_RENDER_LINKAGE_FAILED; retaining/restoring platform-native notification",
                error
            )
            manager.notify(NOTIFICATION_ID, baseNotification)
        }

        if (!isNotificationActive(manager)) {
            throw IllegalStateException(
                "Countdown notification is not present in NotificationManager.activeNotifications after fallback."
            )
        }
        Log.i(TAG, "VERIFY_ACTIVE id=$NOTIFICATION_ID active=true")
    }

    private fun isNotificationActive(manager: NotificationManager): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            manager.activeNotifications.any { it.id == NOTIFICATION_ID }
        } catch (exception: SecurityException) {
            Log.e(TAG, "Unable to inspect active notifications", exception)
            false
        }
    }

    private fun scheduleNextTransition(context: Context, targetTime: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, MuminPrayerCountdownReceiver::class.java).apply {
            action = "com.iskander.muslimspro.NEXT_PRAYER"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, targetTime, pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, targetTime, pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, targetTime, pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent)
            }
            Log.i(TAG, "NEXT_TRANSITION_SCHEDULED target=$targetTime")
        } catch (exception: SecurityException) {
            Log.w(TAG, "Exact alarm rejected; scheduling an inexact idle-safe alarm", exception)
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, targetTime, pendingIntent
            )
        }
    }

    private fun cancelAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, MuminPrayerCountdownReceiver::class.java).apply {
            action = "com.iskander.muslimspro.NEXT_PRAYER"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
}

class MuminPrayerCountdownReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.i("MuminPrayerCountdown", "NEXT_PRAYER_RECEIVER action=${intent?.action}")
        try {
            MuminPrayerCountdownNotifications.refresh(context)
        } catch (exception: Exception) {
            Log.e("MuminPrayerCountdown", "NEXT_PRAYER_REFRESH_FAILED", exception)
        }
    }
}

class MuminPrayerCountdownBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                Log.i("MuminPrayerCountdown", "BOOT_REFRESH action=${intent.action}")
                try {
                    MuminPrayerCountdownNotifications.refresh(context)
                } catch (exception: Exception) {
                    Log.e("MuminPrayerCountdown", "BOOT_REFRESH_FAILED", exception)
                }
            }
        }
    }
}
