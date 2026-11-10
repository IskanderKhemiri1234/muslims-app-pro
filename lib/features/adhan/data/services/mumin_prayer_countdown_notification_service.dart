
import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/domain/services/global_prayer_calculation_service.dart';

/// Prepares the upcoming prayer events for Android's persistent
/// countdown notification.
///
/// Android owns the actual countdown, so it continues updating while
/// Flutter is paused or the application is not visible.
class MuminPrayerCountdownNotificationService {
  MuminPrayerCountdownNotificationService({
    GlobalPrayerCalculationService? calculationService,
    MethodChannel? channel,
  })  : _calculationService =
            calculationService ?? const GlobalPrayerCalculationService(),
        _channel = channel ?? _defaultChannel;

  static const MethodChannel _defaultChannel =
      MethodChannel('com.iskander.muslimspro/prayer_countdown');

  static const int _daysAhead = 90;

  static const List<Prayer> _countdownPrayers = <Prayer>[
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  final GlobalPrayerCalculationService _calculationService;
  final MethodChannel _channel;

  static const String diagnosticsStatusKey = 'mumin_countdown_diag_status';
  static const String diagnosticsErrorKey = 'mumin_countdown_diag_error';
  static const String diagnosticsGeneratedEntriesKey =
      'mumin_countdown_diag_generated_entries';
  static const String diagnosticsLastSyncAtKey =
      'mumin_countdown_diag_last_sync_at';
  static const String diagnosticsTimezoneKey = 'mumin_countdown_diag_timezone';
  static const String diagnosticsNextPrayerKey =
      'mumin_countdown_diag_next_prayer';
  static const String diagnosticsNextPrayerTimeKey =
      'mumin_countdown_diag_next_prayer_time';

  Future<Map<String, Object?>> getAndroidDiagnostics() async {
    final diagnostics = await _channel.invokeMapMethod<String, Object?>(
      'getPrayerCountdownDiagnostics',
    );
    if (diagnostics == null) {
      throw StateError('Android returned an empty countdown diagnostics report.');
    }
    return diagnostics;
  }

  Future<void> saveDiagnosticFailure(Object error) async {
    await _saveDiagnostics(
      status: 'failed',
      error: error.toString(),
    );
  }

  Future<void> _saveDiagnostics({
    required String status,
    String? error,
    int? generatedEntries,
    String? timezone,
    String? nextPrayer,
    int? nextPrayerTimeMillis,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(diagnosticsStatusKey, status);
    if (error == null || error.isEmpty) {
      await preferences.remove(diagnosticsErrorKey);
    } else {
      await preferences.setString(diagnosticsErrorKey, error);
    }
    if (generatedEntries != null) {
      await preferences.setInt(
        diagnosticsGeneratedEntriesKey,
        generatedEntries,
      );
    }
    if (timezone != null) {
      await preferences.setString(diagnosticsTimezoneKey, timezone);
    }
    if (nextPrayer != null) {
      await preferences.setString(diagnosticsNextPrayerKey, nextPrayer);
    }
    if (nextPrayerTimeMillis != null) {
      await preferences.setInt(
        diagnosticsNextPrayerTimeKey,
        nextPrayerTimeMillis,
      );
    }
    await preferences.setString(
      diagnosticsLastSyncAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Sends a validated future prayer schedule to Android.
  ///
  /// The notification itself is created and maintained by the
  /// Android implementation connected through [_channel].
  Future<void> synchronize({
    required PrayerController controller,
    required String Function(Prayer prayer) prayerName,
    required String notificationTitle,
    required String notificationDescription,
  }) async {
    await _saveDiagnostics(status: 'generating');

    if (!controller.isInitialized || !controller.hasUsableSchedule) {
      throw StateError(
        'Prayer countdown synchronization stopped: the prayer controller is not initialized or has no usable schedule.',
      );
    }

    final timezone = controller.timezoneLocation;

    if (timezone == null) {
      throw StateError(
        'Prayer countdown synchronization stopped: the prayer timezone is not initialized.',
      );
    }

    if (notificationTitle.trim().isEmpty ||
        notificationDescription.trim().isEmpty) {
      throw ArgumentError(
        'Countdown notification text cannot be empty.',
      );
    }

    final now = tz.TZDateTime.now(timezone);

    final entries = <Map<String, Object>>[];

    for (var dayOffset = 0; dayOffset < _daysAhead; dayOffset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
      );

      final schedule = _calculationService.calculate(
        latitude: controller.latitude,
        longitude: controller.longitude,
        localDate: date,
        timezone: timezone,
        method: controller.method,
        madhab: controller.madhab,
      );

      for (final prayer in _countdownPrayers) {
        final prayerTime = schedule.timeForPrayer(prayer);

        if (prayerTime == null || !prayerTime.isAfter(now)) {
          continue;
        }

        final translatedName = prayerName(prayer).trim();

        if (translatedName.isEmpty) {
          throw StateError(
            'Missing localized name for ${prayer.name}.',
          );
        }

        entries.add(
          <String, Object>{
            'prayer': prayer.name,
            'name': translatedName,
            'englishName': _englishPrayerName(prayer),
            'timeMillis': prayerTime.millisecondsSinceEpoch,
          },
        );
      }
    }

    entries.sort(
      (first, second) =>
          (first['timeMillis']! as int)
              .compareTo(second['timeMillis']! as int),
    );

    if (entries.isEmpty) {
      await cancel();
      throw StateError(
        'No future prayer times were generated for the persistent countdown.',
      );
    }

    await _saveDiagnostics(
      status: 'sending',
      generatedEntries: entries.length,
      timezone: timezone.name,
      nextPrayer: entries.first['name']! as String,
      nextPrayerTimeMillis: entries.first['timeMillis']! as int,
    );

    try {
      await _channel.invokeMethod<void>(
        'syncPrayerCountdown',
        <String, Object>{
          'entries': entries,
          'title': notificationTitle,
          'description': notificationDescription,
          'timezone': timezone.name,
        },
      );
    } catch (error) {
      await _saveDiagnostics(
        status: 'failed',
        error: error.toString(),
        generatedEntries: entries.length,
        timezone: timezone.name,
        nextPrayer: entries.first['name']! as String,
        nextPrayerTimeMillis: entries.first['timeMillis']! as int,
      );
      rethrow;
    }

    await _saveDiagnostics(
      status: 'synchronized',
      generatedEntries: entries.length,
      timezone: timezone.name,
      nextPrayer: entries.first['name']! as String,
      nextPrayerTimeMillis: entries.first['timeMillis']! as int,
    );
  }

  String _englishPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }

  /// Removes the persistent countdown notification and its alarm.
  Future<void> cancel() async {
    await _channel.invokeMethod<void>(
      'cancelPrayerCountdown',
    );
  }
}
