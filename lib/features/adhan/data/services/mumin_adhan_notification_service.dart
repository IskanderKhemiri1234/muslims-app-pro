
import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/domain/services/global_prayer_calculation_service.dart';

/// Schedules local notifications for the five daily prayers.
///
/// Schedules high-priority prayer notifications and forwards their launch
/// payloads to the application so the selected Adhan experience can open.
class MuminAdhanNotificationService {
  MuminAdhanNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    GlobalPrayerCalculationService? calculationService,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _calculationService =
            calculationService ?? const GlobalPrayerCalculationService();

  static final StreamController<MuminPrayerAlert> _prayerAlertController =
      StreamController<MuminPrayerAlert>.broadcast();

  /// Emits the prayer and its scheduled local clock time when Android opens
  /// the app through the full-screen notification or its notification action.
  static Stream<MuminPrayerAlert> get prayerAlerts =>
      _prayerAlertController.stream;

  static void _handleNotificationResponse(
    NotificationResponse response,
  ) {
    final alert = MuminPrayerAlert.fromPayload(response.payload);
    if (alert != null) {
      _prayerAlertController.add(alert);
    }
  }

  static const String _enabledPrefix = 'mumin_adhan_enabled_';

  static const String _scheduleStateKey =
      'mumin_adhan_schedule_state_v2';

  static const String _legacyScheduledIdsKey =
      'mumin_adhan_scheduled_notification_ids';

  static const String channelId = 'mumin_prayer_time_alerts';
  static const String channelName = 'Mumin Pro Prayer Alerts';

  static const List<Prayer> supportedPrayers = <Prayer>[
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

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // A full-screen notification that starts a terminated app is not
    // delivered through onDidReceiveNotificationResponse. Recover its
    // payload from the launch details and dispatch it through the same route.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        _handleNotificationResponse(response);
      }
    }
  }

  
  /// Requests Android notification permission after an explicit user action.
  Future<bool> requestNotificationPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.requestNotificationsPermission() ?? false;
  }

  /// Checks notification permission without prompting the user.
  Future<bool> areNotificationsEnabled() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.areNotificationsEnabled() ?? false;
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

  /// Opens Android's special-access screen for full-screen Adhan alerts.
  Future<bool> requestFullScreenIntentPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    return await android.requestFullScreenIntentPermission() ?? false;
  }

  Future<Set<Prayer>> getEnabledPrayers() async {
    final preferences = await SharedPreferences.getInstance();

    return Set<Prayer>.unmodifiable(
      supportedPrayers.where(
        (prayer) => preferences.getBool(_preferenceKey(prayer)) ?? false,
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

  /// Rebuilds notifications for the next seven local calendar days.
  ///
  /// Two alternating ID banks are used. The currently active bank remains
  /// untouched until every notification in the replacement bank is scheduled
  /// and its state has been persisted successfully.
  Future<int> reschedule({
    required PrayerController controller,
    required String Function(Prayer prayer) prayerName,
    required String notificationBody,
    bool preferExact = false,
  }) async {
    await initialize();

    if (notificationBody.trim().isEmpty) {
      throw ArgumentError.value(
        notificationBody,
        'notificationBody',
        'Notification body cannot be empty.',
      );
    }

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
    final previousState = await _readScheduleState();
    final activeBank = previousState.bank;
    final stagingBank = activeBank == 0 ? 1 : 0;

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
        fullScreenIntent: true,
      ),
    );

    final stagedIds = <int>[];

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

          final id = _notificationId(
            date: date,
            prayer: prayer,
            bank: stagingBank,
          );

          await _plugin.zonedSchedule(
            id: id,
            title: prayerName(prayer),
            body: notificationBody,
            scheduledDate: prayerTime,
            notificationDetails: details,
            androidScheduleMode: scheduleMode,
            payload: 'mumin_adhan:${prayer.name}:'
                '${prayerTime.hour}:${prayerTime.minute}',
          );

          stagedIds.add(id);
        }
      }

      final preferences = await SharedPreferences.getInstance();

      final stateSaved = await preferences.setString(
        _scheduleStateKey,
        jsonEncode(<String, Object>{
          'bank': stagingBank,
          'ids': stagedIds,
        }),
      );

      if (!stateSaved) {
        throw StateError(
          'Could not persist the new prayer notification schedule.',
        );
      }

      // The new schedule is now active. Old notifications can be removed.
      await _cancelIdsSafely(previousState.ids);

      // Clean up schedules created by the older implementation.
      final legacyIds = await _readLegacyIds();
      await _cancelIdsSafely(legacyIds);

      return stagedIds.length;
    } catch (error, stackTrace) {
      // If the state was already committed, do not cancel the active bank.
      final latestState = await _readScheduleState();

      final committed =
          latestState.bank == stagingBank &&
          _sameIds(latestState.ids, stagedIds);

      if (!committed) {
        await _cancelIdsSafely(stagedIds);
      }

      debugPrint('Mumin Pro: prayer scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  /// Schedules a one-off verification alert through the same Android
  /// channel and full-screen notification path used by real prayer alerts.
  /// It never changes prayer notification preferences or the regular schedule.
  Future<void> scheduleTestAlert({
    required Prayer prayer,
    required tz.Location timezone,
    required DateTime? prayerTime,
    required String prayerName,
    required String notificationBody,
  }) async {
    await initialize();
    _validatePrayer(prayer);

    if (!await areNotificationsEnabled()) {
      throw StateError('Android notifications are not enabled for Mumin Pro.');
    }
    if (notificationBody.trim().isEmpty) {
      throw ArgumentError.value(
        notificationBody,
        'notificationBody',
        'Test notification body cannot be empty.',
      );
    }

    // A one-off test should be as prompt as Android currently permits.
    // This reads the OS grant only; it does not alter the user's saved setting.
    final exactAllowed = await canScheduleExactNotifications();
    final scheduleMode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final trigger = tz.TZDateTime.now(timezone).add(
      const Duration(seconds: 20),
    );
    final clock = prayerTime ?? trigger;

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
        fullScreenIntent: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: 73106,
      title: prayerName,
      body: notificationBody,
      scheduledDate: trigger,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: 'mumin_adhan:${prayer.name}:'
          '${clock.hour}:${clock.minute}',
    );
  }

  /// Reports the IDs saved by the scheduler against Android's actual
  /// pending-notification queue. This is intentionally separate from the
  /// persistent countdown diagnostics.
  Future<Map<String, Object?>> getScheduleDiagnostics() async {
    await initialize();

    final state = await _readScheduleState();
    final pendingRequests = await _plugin.pendingNotificationRequests();
    final activeIds = state.ids.toSet();
    final actualRequests = pendingRequests
        .where((request) => activeIds.contains(request.id))
        .toList(growable: false);
    final actualIds = actualRequests.map((request) => request.id).toSet();
    final missingIds = state.ids
        .where((id) => !actualIds.contains(id))
        .toList(growable: false);
    final testPending = pendingRequests.any((request) => request.id == 73106);

    return <String, Object?>{
      'savedScheduleCount': state.ids.length,
      'pendingScheduleCount': actualRequests.length,
      'missingScheduleCount': missingIds.length,
      'missingScheduleIds': missingIds,
      'testAlertPending': testPending,
      'pendingEntries': actualRequests.map((request) {
        final alert = MuminPrayerAlert.fromPayload(request.payload);
        return <String, Object?>{
          'id': request.id,
          'title': request.title,
          'body': request.body,
          'prayer': alert?.prayer.name,
          'payload': request.payload,
        };
      }).toList(growable: false),
    };
  }

  Future<void> cancelTestAlert() async {
    await initialize();
    await _plugin.cancel(id: 73106);
  }

  Future<void> cancelPreviouslyScheduled() async {
    await initialize();
    await _cancelPreviouslyScheduled();
  }

  Future<void> _cancelPreviouslyScheduled() async {
    final state = await _readScheduleState();
    final legacyIds = await _readLegacyIds();

    await _cancelIdsSafely(state.ids);
    await _cancelIdsSafely(legacyIds);

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_scheduleStateKey);
    await preferences.remove(_legacyScheduledIdsKey);
  }

  Future<_NotificationScheduleState> _readScheduleState() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_scheduleStateKey);

    if (raw == null || raw.trim().isEmpty) {
      return const _NotificationScheduleState(
        bank: 0,
        ids: <int>[],
      );
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        throw const FormatException('Invalid schedule state.');
      }

      final bankValue = decoded['bank'];
      final idsValue = decoded['ids'];

      final bank = bankValue is int ? bankValue : 0;

      final ids = idsValue is List
          ? idsValue.whereType<int>().toSet().toList(growable: false)
          : const <int>[];

      return _NotificationScheduleState(
        bank: bank == 1 ? 1 : 0,
        ids: ids,
      );
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: invalid saved schedule state: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Do not silently erase unknown state. Cancellation is handled
      // separately by the explicit reset operation.
      return const _NotificationScheduleState(
        bank: 0,
        ids: <int>[],
      );
    }
  }

  Future<List<int>> _readLegacyIds() async {
    final preferences = await SharedPreferences.getInstance();

    try {
      final values =
          preferences.getStringList(_legacyScheduledIdsKey) ??
              const <String>[];

      return values
          .map(int.tryParse)
          .whereType<int>()
          .toSet()
          .toList(growable: false);
    } catch (error) {
      debugPrint(
        'Mumin Pro: legacy notification IDs could not be read: $error',
      );
      return const <int>[];
    }
  }

  Future<void> _cancelIdsSafely(Iterable<int> ids) async {
    for (final id in ids.toSet()) {
      try {
        await _plugin.cancel(id: id);
      } catch (error, stackTrace) {
        debugPrint(
          'Mumin Pro: could not cancel notification $id: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  bool _sameIds(List<int> first, List<int> second) {
    if (first.length != second.length) return false;

    final secondSet = second.toSet();

    return first.every(secondSet.contains);
  }

  String _preferenceKey(Prayer prayer) =>
      '$_enabledPrefix${prayer.name}';

  /// Produces Android-safe 32-bit IDs.
  ///
  /// The date component is YYYYMMDD. Multiplying by two reserves
  /// one independent ID bank bit without exceeding signed 32-bit range.
  int _notificationId({
    required DateTime date,
    required Prayer prayer,
    required int bank,
  }) {
    final prayerIndex = supportedPrayers.indexOf(prayer) + 1;

    final dateKey =
        date.year * 10000 + date.month * 100 + date.day;

    return (dateKey * 10 + prayerIndex) * 2 + bank;
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

/// Details carried by a scheduled prayer notification.
class MuminPrayerAlert {
  const MuminPrayerAlert({
    required this.prayer,
    this.prayerTime,
  });

  final Prayer prayer;

  /// A local clock-time carrier. Its calendar date is intentionally ignored.
  final DateTime? prayerTime;

  static MuminPrayerAlert? fromPayload(String? payload) {
    const prefix = 'mumin_adhan:';
    if (payload == null || !payload.startsWith(prefix)) return null;

    final parts = payload.substring(prefix.length).split(':');
    if (parts.isEmpty) return null;

    Prayer? prayer;
    for (final candidate in MuminAdhanNotificationService.supportedPrayers) {
      if (candidate.name == parts.first) {
        prayer = candidate;
        break;
      }
    }

    if (prayer == null) return null;

    DateTime? prayerTime;
    if (parts.length >= 3) {
      final hour = int.tryParse(parts[1]);
      final minute = int.tryParse(parts[2]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        prayerTime = DateTime(2000, 1, 1, hour, minute);
      }
    }

    return MuminPrayerAlert(
      prayer: prayer,
      prayerTime: prayerTime,
    );
  }
}

class _NotificationScheduleState {
  const _NotificationScheduleState({
    required this.bank,
    required this.ids,
  });

  final int bank;
  final List<int> ids;
}
