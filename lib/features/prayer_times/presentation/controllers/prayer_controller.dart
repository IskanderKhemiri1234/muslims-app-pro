
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/location_datasource.dart';

class PrayerController extends ChangeNotifier
    with WidgetsBindingObserver {
  PrayerController({
    LocationDataSource? locationSource,
  }) : _locationSource =
            locationSource ?? LocationDataSource() {
    WidgetsBinding.instance.addObserver(this);

    clock.value = DateTime.now();

    unawaited(retryInitialization());
  }

  final LocationDataSource _locationSource;

  // --------------------------------------------------
  // PERSISTENCE
  // --------------------------------------------------

  static const String _latitudeKey = 'prayer_latitude';
  static const String _longitudeKey = 'prayer_longitude';
  static const String _methodKey = 'prayer_method';
  static const String _madhabKey = 'prayer_madhab';

  Future<void> _settingsWriteQueue = Future<void>.value();

  // --------------------------------------------------
  // DEFAULT SETTINGS
  // --------------------------------------------------

  double latitude = 33.5731;
  double longitude = -7.5898;

  String city = 'Casablanca';

  CalculationMethod method =
      CalculationMethod.muslimWorldLeague;

  Madhab madhab = Madhab.shafi;

  // --------------------------------------------------
  // PRAYER STATE
  // --------------------------------------------------

  PrayerTimes? _prayerTimes;
  PrayerTimes? _tomorrowPrayerTimes;

  DateTime? _scheduleDate;
  DateTime? _nextPrayerAt;

  Prayer _nextPrayer = Prayer.none;

  PrayerTimes? get prayerTimes => _prayerTimes;

  Prayer get nextPrayer => _nextPrayer;

  DateTime? get nextPrayerTime => _nextPrayerAt;

  // --------------------------------------------------
  // CLOCK
  // --------------------------------------------------

  final ValueNotifier<DateTime> clock =
      ValueNotifier<DateTime>(DateTime.now());

  Timer? _timer;

  static const Duration _clockInterval =
      Duration(seconds: 1);

  // --------------------------------------------------
  // STATUS
  // --------------------------------------------------

  bool isLoadingLocation = false;
  bool isInitialized = false;

  String? message;

  bool _disposed = false;

  bool get isDisposed => _disposed;

  Future<void>? _initializationTask;

  // --------------------------------------------------
  // COUNTDOWN
  // --------------------------------------------------

  Duration get remaining {
    final target = _nextPrayerAt;

    if (target == null) {
      return Duration.zero;
    }

    final difference = target.difference(clock.value);

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  Future<void> retryInitialization() {
    if (_disposed) {
      return Future<void>.value();
    }

    // Prevent concurrent initialization.
    final existingTask = _initializationTask;

    if (existingTask != null) {
      return existingTask;
    }

    final task = _performInitialization();

    _initializationTask = task;

    return task.whenComplete(() {
      if (identical(_initializationTask, task)) {
        _initializationTask = null;
      }
    });
  }

  Future<void> _performInitialization() async {
    try {
      isInitialized = false;
      message = null;

      _notifySafely();

      await _loadSettings();

      if (_disposed) return;

      _calculateSchedule();

      if (_disposed) return;

      isInitialized = true;

      _startClock();

      message = null;
    } catch (error, stackTrace) {
      debugPrint(
        'Prayer initialization error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      isInitialized = true;

      message = 'Unable to calculate prayer times.';

      _stopClock();
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  bool _isValidCoordinates(
    double lat,
    double lon,
  ) {
    return lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  bool _isValidDate(DateTime date) {
    return date.year >= 1 &&
        date.year <= 9999;
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // --------------------------------------------------
  // LOAD SETTINGS
  // --------------------------------------------------

  Future<void> _loadSettings() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      if (_disposed) return;

      final savedLatitude =
          prefs.getDouble(_latitudeKey);

      final savedLongitude =
          prefs.getDouble(_longitudeKey);

      if (savedLatitude != null &&
          savedLongitude != null &&
          _isValidCoordinates(
            savedLatitude,
            savedLongitude,
          )) {
        latitude = savedLatitude;
        longitude = savedLongitude;
        city = 'Saved location';
      }

      final savedMethod =
          prefs.getString(_methodKey);

      if (savedMethod != null) {
        for (final calculationMethod
            in CalculationMethod.values) {
          if (calculationMethod.name == savedMethod) {
            method = calculationMethod;
            break;
          }
        }
      }

      final savedMadhab =
          prefs.getString(_madhabKey);

      switch (savedMadhab) {
        case 'hanafi':
          madhab = Madhab.hanafi;
          break;

        case 'shafi':
          madhab = Madhab.shafi;
          break;
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Prayer settings load error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      // Preserve safe defaults.
    }
  }

  // --------------------------------------------------
  // SAVE SETTINGS
  // --------------------------------------------------

  Future<void> _saveSettings() {
    if (_disposed) {
      return Future<void>.value();
    }

    // Capture a consistent settings snapshot.
    final savedLatitude = latitude;
    final savedLongitude = longitude;
    final savedMethod = method.name;

    final savedMadhab =
        madhab == Madhab.hanafi
            ? 'hanafi'
            : 'shafi';

    final operation = _settingsWriteQueue.then(
      (_) async {
        if (_disposed) return;

        final prefs =
            await SharedPreferences.getInstance();

        if (_disposed) return;

        await prefs.setDouble(
          _latitudeKey,
          savedLatitude,
        );

        await prefs.setDouble(
          _longitudeKey,
          savedLongitude,
        );

        await prefs.setString(
          _methodKey,
          savedMethod,
        );

        await prefs.setString(
          _madhabKey,
          savedMadhab,
        );
      },
    );

    // Keep the queue alive even if one write fails.
    _settingsWriteQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Prayer settings save error: $error',
        );
      },
    );

    return _settingsWriteQueue;
  }

  // --------------------------------------------------
  // PRAYER CALCULATION
  // --------------------------------------------------

  PrayerTimes _createPrayerTimes(
    DateTime date,
  ) {
    if (!_isValidCoordinates(latitude, longitude)) {
      throw StateError(
        'Invalid prayer calculation coordinates.',
      );
    }

    if (!_isValidDate(date)) {
      throw StateError(
        'Invalid prayer calculation date.',
      );
    }

    final coordinates = Coordinates(
      latitude,
      longitude,
    );

    final dateComponents =
        DateComponents.from(date);

    // Obtain fresh parameters for each calculation.
    final parameters = method.getParameters();

    parameters.madhab = madhab;

    return PrayerTimes(
      coordinates,
      dateComponents,
      parameters,
    );
  }

  DateTime _nextCalendarDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day + 1,
    );
  }

  // Calculate everything before committing the new schedule.
  // This prevents partially updated prayer state.
  void _calculateSchedule() {
    if (_disposed) return;

    final now = DateTime.now();

    final today = _createPrayerTimes(now);

    final tomorrowDate = _nextCalendarDay(now);

    final tomorrow = _createPrayerTimes(
      tomorrowDate,
    );

    final next = _findNextPrayer(
      today: today,
      tomorrow: tomorrow,
      now: now,
    );

    // Commit only after successful calculations.
    _prayerTimes = today;
    _tomorrowPrayerTimes = tomorrow;

    _scheduleDate = now;

    _nextPrayer = next.$1;
    _nextPrayerAt = next.$2;
  }

  // --------------------------------------------------
  // NEXT PRAYER ENGINE
  // --------------------------------------------------

  (
    Prayer,
    DateTime?,
  ) _findNextPrayer({
    required PrayerTimes today,
    required PrayerTimes tomorrow,
    required DateTime now,
  }) {
    const dailyPrayers = <Prayer>[
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in dailyPrayers) {
      final prayerTime =
          today.timeForPrayer(prayer);

      if (prayerTime != null &&
          prayerTime.isAfter(now)) {
        return (
          prayer,
          prayerTime,
        );
      }
    }

    // After Isha, tomorrow's Fajr is next.
    final tomorrowFajr =
        tomorrow.timeForPrayer(Prayer.fajr);

    if (tomorrowFajr != null &&
        tomorrowFajr.isAfter(now)) {
      return (
        Prayer.fajr,
        tomorrowFajr,
      );
    }

    return (
      Prayer.none,
      null,
    );
  }

  void _refreshNextPrayer(DateTime now) {
    final today = _prayerTimes;
    final tomorrow = _tomorrowPrayerTimes;

    if (today == null || tomorrow == null) {
      _nextPrayer = Prayer.none;
      _nextPrayerAt = null;
      return;
    }

    final next = _findNextPrayer(
      today: today,
      tomorrow: tomorrow,
      now: now,
    );

    _nextPrayer = next.$1;
    _nextPrayerAt = next.$2;
  }

  // --------------------------------------------------
  // CLOCK ENGINE
  // --------------------------------------------------

  void _startClock() {
    if (_disposed) return;

    _stopClock();

    _synchronizeClock();

    _timer = Timer.periodic(
      _clockInterval,
      (_) {
        if (_disposed) return;

        _synchronizeClock();
      },
    );
  }

  void _synchronizeClock() {
    if (_disposed) return;

    final now = DateTime.now();

    final previous = clock.value;

    clock.value = now;

    // Detect date changes, including midnight.
    if (_scheduleDate == null ||
        !_isSameDate(now, _scheduleDate!)) {
      _recalculateSafely();
      return;
    }

    // Detect significant system clock changes.
    final expectedElapsed =
        _clockInterval.inMilliseconds;

    final actualElapsed =
        now.difference(previous).inMilliseconds;

    if (actualElapsed < 0 ||
        actualElapsed > expectedElapsed * 5) {
      _recalculateSafely();
      return;
    }

    // Refresh when the next prayer has arrived.
    final target = _nextPrayerAt;

    if (target != null &&
        !now.isBefore(target)) {
      _refreshNextPrayer(now);
      _notifySafely();
    }
  }

  void _recalculateSafely() {
    if (_disposed) return;

    try {
      _calculateSchedule();
      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint(
        'Prayer schedule recalculation error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      message =
          'Unable to refresh prayer times.';

      _notifySafely();
    }
  }

  void _stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  // --------------------------------------------------
  // APPLICATION LIFECYCLE
  // --------------------------------------------------

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      _recalculateSafely();

      _startClock();

      _notifySafely();
    } else {
      _stopClock();
    }
  }

  // --------------------------------------------------
  // LOCATION
  // --------------------------------------------------

  Future<void> updateLocation() async {
    if (_disposed || isLoadingLocation) return;

    isLoadingLocation = true;
    message = null;

    _notifySafely();

    try {
      final Position position =
          await _locationSource.getCurrentLocation();

      if (_disposed) return;

      final newLatitude = position.latitude;
      final newLongitude = position.longitude;

      if (!_isValidCoordinates(
        newLatitude,
        newLongitude,
      )) {
        throw StateError(
          'Received invalid location coordinates.',
        );
      }

      final previousLatitude = latitude;
      final previousLongitude = longitude;
      final previousCity = city;

      try {
        latitude = newLatitude;
        longitude = newLongitude;
        city = 'Current location';

        _calculateSchedule();
      } catch (_) {
        // Roll back if calculation fails.
        latitude = previousLatitude;
        longitude = previousLongitude;
        city = previousCity;

        rethrow;
      }

      await _saveSettings();

      if (_disposed) return;

      message =
          'Location updated successfully.';
    } catch (error, stackTrace) {
      debugPrint(
        'Location update error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      message = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed) {
        isLoadingLocation = false;
        _notifySafely();
      }
    }
  }

  // --------------------------------------------------
  // CALCULATION SETTINGS
  // --------------------------------------------------

  void changeMethod(
    CalculationMethod value,
  ) {
    if (_disposed || method == value) return;

    _applySettingsChange(
      newMethod: value,
    );
  }

  void changeMadhab(
    Madhab value,
  ) {
    if (_disposed || madhab == value) return;

    _applySettingsChange(
      newMadhab: value,
    );
  }

  void _applySettingsChange({
    CalculationMethod? newMethod,
    Madhab? newMadhab,
  }) {
    final previousMethod = method;
    final previousMadhab = madhab;

    try {
      if (newMethod != null) {
        method = newMethod;
      }

      if (newMadhab != null) {
        madhab = newMadhab;
      }

      _calculateSchedule();

      message = null;

      unawaited(_saveSettings());

      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint(
        'Prayer settings update error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      // Restore previous settings.
      method = previousMethod;
      madhab = previousMadhab;

      // Restore the previous schedule.
      try {
        _calculateSchedule();
      } catch (restoreError) {
        debugPrint(
          'Prayer schedule restoration error: '
          '$restoreError',
        );
      }

      message =
          'Unable to update prayer calculation settings.';

      _notifySafely();
    }
  }

  // --------------------------------------------------
  // SAFE NOTIFICATION
  // --------------------------------------------------

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // DISPOSAL
  // --------------------------------------------------

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _stopClock();

    clock.dispose();

    super.dispose();
  }
}
