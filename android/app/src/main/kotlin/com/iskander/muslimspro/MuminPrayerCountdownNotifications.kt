package com.iskander.muslimspro

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.widget.RemoteViews
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object MuminPrayerCountdownNotifications {

    private const val CHANNEL_ID = "mumin_next_prayer_countdown"
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

            if (timestamp <= 0L || name.isEmpty() || prayer.isEmpty()) {
                return@forEach
            }

            jsonEntries.put(
                JSONObject()
                    .put("timeMillis", timestamp)
                    .put("name", name)
                    .put("prayer", prayer)
            )
        }

        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(ENTRIES_KEY, jsonEntries.toString())
            .putString(TITLE_KEY, title)
            .putString(DESCRIPTION_KEY, description)
            .putString(TIMEZONE_KEY, timezone)
            .apply()

        refresh(context)
    }

    fun cancel(context: Context) {
        cancelAlarm(context)

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        manager.cancel(NOTIFICATION_ID)

        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    fun refresh(context: Context) {
        createNotificationChannel(context)

        val preferences =
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

        val storedEntries = preferences.getString(ENTRIES_KEY, null)
            ?: run {
                cancelAlarm(context)
                return
            }

        val entries = try {
            JSONArray(storedEntries)
        } catch (_: Exception) {
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

            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager

            manager.cancel(NOTIFICATION_ID)
            return
        }

        val name = nextEntry.optString("name")
        val title = preferences.getString(TITLE_KEY, "Mumin Pro")
            ?: "Mumin Pro"
        val description = preferences.getString(DESCRIPTION_KEY, "")
            ?: ""

        showNotification(
            context = context,
            title = title,
            prayerName = name,
            description = description,
            targetTime = nextTime
        )

        scheduleNextTransition(context, nextTime)
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
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
            return
        }

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val contentIntent = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
                .setPriority(Notification.PRIORITY_LOW)
        }.apply {
            setSmallIcon(R.drawable.ic_mumin_notification)
            setContentTitle(title)
            setContentText(
                if (description.isBlank()) {
                    prayerName
                } else {
                    "$prayerName • $description"
                }
            )
            setContentIntent(contentIntent)
            setCategory(Notification.CATEGORY_STATUS)
            setVisibility(Notification.VISIBILITY_PUBLIC)
            setShowWhen(true)
            setWhen(targetTime)
            setUsesChronometer(true)
            setOngoing(true)
            setAutoCancel(false)
            setOnlyAlertOnce(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                setChronometerCountDown(true)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val compactView = RemoteViews(
                context.packageName,
                R.layout.mumin_prayer_countdown_collapsed
            ).apply {
                setTextViewText(R.id.mumin_countdown_title, title)
                setTextViewText(R.id.mumin_countdown_prayer, prayerName)
                setChronometer(
                    R.id.mumin_countdown_timer,
                    targetTime,
                    null,
                    true
                )
                setChronometerCountDown(
                    R.id.mumin_countdown_timer,
                    true
                )
            }

            val expandedView = RemoteViews(
                context.packageName,
                R.layout.mumin_prayer_countdown_expanded
            ).apply {
                setTextViewText(R.id.mumin_countdown_title, title)
                setTextViewText(R.id.mumin_countdown_prayer, prayerName)
                setTextViewText(
                    R.id.mumin_countdown_label,
                    description
                )
                setChronometer(
                    R.id.mumin_countdown_timer,
                    targetTime,
                    null,
                    true
                )
                setChronometerCountDown(
                    R.id.mumin_countdown_timer,
                    true
                )
            }

            builder
                .setStyle(Notification.DecoratedCustomViewStyle())
                .setCustomContentView(compactView)
                .setCustomBigContentView(expandedView)
        }

        val notification = builder.build()

        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun scheduleNextTransition(
        context: Context,
        targetTime: Long
    ) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(
            context,
            MuminPrayerCountdownReceiver::class.java
        ).apply {
            action = "com.iskander.muslimspro.NEXT_PRAYER"
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        targetTime,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        targetTime,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    targetTime,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    targetTime,
                    pendingIntent
                )
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                targetTime,
                pendingIntent
            )
        }
    }

    private fun cancelAlarm(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(
            context,
            MuminPrayerCountdownReceiver::class.java
        ).apply {
            action = "com.iskander.muslimspro.NEXT_PRAYER"
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
}

class MuminPrayerCountdownReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        MuminPrayerCountdownNotifications.refresh(context)
    }
}

class MuminPrayerCountdownBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                MuminPrayerCountdownNotifications.refresh(context)
            }
        }
    }
}
