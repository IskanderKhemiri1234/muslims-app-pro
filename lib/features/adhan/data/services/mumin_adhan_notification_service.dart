
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/domain/services/global_prayer_calculation_service.dart';

/// Schedules local notifications for the five daily prayers.
///
/// This service schedules notifications only.
/// It does not start a complete Adhan recording in the background.
class MuminAdhanNotificationService {
  MuminAdhanNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    GlobalPrayerCalculationService? calculationService,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _calculationService =
            calculationService ?? const GlobalPrayerCalculationService();

  static const String _enabledPrefix = 'mumin_adhan_enabled_';
  static const String _scheduledIdsKey =
      'mumin_adhan_scheduled_notification_ids';

  static const String channelId = 'mumin_prayer_time_alerts';
  static const String channelName = 'Mumin Pro Prayer Alerts';

  static const List<Prayer> supportedPrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  final FlutterLocalNotificationsPlugin _plugin;
  final GlobalPrayerCalculationService _calculationService;

  Future<void>? _initialization;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final pending = _initialization ??= _initializePlugin();

    try {
      await pending;
      _isInitialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.requestNotificationsPermission() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<bool> canScheduleExactNotifications() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<Set<Prayer>> getEnabledPrayers() async {
    final preferences = await SharedPreferences.getInstance();

    return Set<Prayer>.unmodifiable(
      supportedPrayers.where(
        (prayer) =>
            preferences.getBool(_preferenceKey(prayer)) ?? false,
      ),
    );
  }

  Future<void> setPrayerEnabled(
    Prayer prayer, {
    required bool enabled,
  }) async {
    _validatePrayer(prayer);

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setBool(
      _preferenceKey(prayer),
      enabled,
    );

    if (!saved) {
      throw StateError(
        'Could not save the Adhan notification preference.',
      );
    }
  }

  /// Rebuilds the next seven local calendar days.
  ///
  /// Existing notification IDs are retained when they are still needed.
  /// Only stale IDs are cancelled after the new schedule succeeds.
  Future<int> reschedule({
    required PrayerController controller,
    required String Function(Prayer prayer) prayerName,
    required String notificationBody,
    bool preferExact = false,
  }) async {
    await initialize();

    final enabledPrayers = await getEnabledPrayers();

    if (enabledPrayers.isEmpty) {
      await _cancelPreviouslyScheduled();
      return 0;
    }

    final location = controller.timezoneLocation;

    if (location == null || controller.timezoneId == null) {
      throw StateError(
        'A valid discovered timezone is required before scheduling.',
      );
    }

    if (!controller.latitude.isFinite ||
        !controller.longitude.isFinite ||
        controller.latitude < -90 ||
        controller.latitude > 90 ||
        controller.longitude < -180 ||
        controller.longitude > 180) {
      throw StateError(
        'Valid location coordinates are required for scheduling.',
      );
    }

    final exactAllowed =
        preferExact && await canScheduleExactNotifications();

    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final localNow = tz.TZDateTime.now(location);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription:
            'Prayer time notifications calculated for your location.',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );

    final newIds = <int>[];

    try {
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = DateTime(
          localNow.year,
          localNow.month,
          localNow.day + dayOffset,
        );

        final schedule = _calculationService.calculate(
          latitude: controller.latitude,
          longitude: controller.longitude,
          localDate: date,
          timezone: location,
          method: controller.method,
          madhab: controller.madhab,
        );

        for (final prayer in supportedPrayers) {
          if (!enabledPrayers.contains(prayer)) continue;

          final prayerTime = schedule.timeForPrayer(prayer);

          if (prayerTime == null || !prayerTime.isAfter(localNow)) {
            continue;
          }

          final id = _notificationId(date, prayer);

          await _plugin.zonedSchedule(
            id: id,
            title: prayerName(prayer),
            body: notificationBody,
            scheduledDate: prayerTime,
            notificationDetails: details,
            androidScheduleMode: scheduleMode,
            payload: 'mumin_adhan:${prayer.name}',
          );

          newIds.add(id);
        }
      }

      final preferences = await SharedPreferences.getInstance();

      final previousIds =
          preferences.getStringList(_scheduledIdsKey) ?? const [];

      final newIdSet = newIds.toSet();

      for (final value in previousIds) {
        final oldId = int.tryParse(value);

        if (oldId == null || newIdSet.contains(oldId)) continue;

        await _plugin.cancel(id: oldId);
      }

      final saved = await preferences.setStringList(
        _scheduledIdsKey,
        newIds.map((id) => id.toString()).toList(),
      );

      if (!saved) {
        throw StateError(
          'Could not persist scheduled notification identifiers.',
        );
      }

      return newIds.length;
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: prayer scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  Future<void> cancelPreviouslyScheduled() async {
    await initialize();
    await _cancelPreviouslyScheduled();
  }

  Future<void> _cancelPreviouslyScheduled() async {
    final preferences = await SharedPreferences.getInstance();

    final previousIds =
        preferences.getStringList(_scheduledIdsKey) ?? const [];

    for (final value in previousIds) {
      final id = int.tryParse(value);
      if (id == null) continue;

      await _plugin.cancel(id: id);
    }

    await preferences.remove(_scheduledIdsKey);
  }

  String _preferenceKey(Prayer prayer) =>
      '$_enabledPrefix${prayer.name}';

  int _notificationId(DateTime date, Prayer prayer) {
    final prayerIndex = supportedPrayers.indexOf(prayer) + 1;

    return date.year * 100000 +
        date.month * 1000 +
        date.day * 10 +
        prayerIndex;
  }

  void _validatePrayer(Prayer prayer) {
    if (!supportedPrayers.contains(prayer)) {
      throw ArgumentError.value(
        prayer,
        'prayer',
        'Only the five daily prayers can have notifications.',
      );
    }
  }
}
