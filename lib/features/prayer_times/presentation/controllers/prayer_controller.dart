
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
    _initialize();
  }

  final LocationDataSource _locationSource;

  // Persistent settings keys.
  static const String _latitudeKey = 'prayer_latitude';
  static const String _longitudeKey = 'prayer_longitude';
  static const String _methodKey = 'prayer_method';
  static const String _madhabKey = 'prayer_madhab';

  // Default location: Casablanca.
  double latitude = 33.5731;
  double longitude = -7.5898;
  String city = 'Casablanca';

  CalculationMethod method =
      CalculationMethod.muslimWorldLeague;

  Madhab madhab = Madhab.shafi;

  PrayerTimes? _prayerTimes;
  PrayerTimes? _tomorrowPrayerTimes;

  DateTime? _scheduleDate;
  DateTime? _nextPrayerAt;

  Prayer _nextPrayer = Prayer.none;

  Timer? _timer;

  final ValueNotifier<DateTime> clock =
      ValueNotifier<DateTime>(DateTime.now());

  bool isLoadingLocation = false;
  bool isInitialized = false;
  String? message;

  bool _disposed = false;

  PrayerTimes? get prayerTimes => _prayerTimes;

  Prayer get nextPrayer => _nextPrayer;

  DateTime? get nextPrayerTime => _nextPrayerAt;

  /// Remaining time until the next prayer.
  Duration get remaining {
    final target = _nextPrayerAt;

    if (target == null) {
      return Duration.zero;
    }

    final difference = target.difference(clock.value);

    return difference.isNegative
        ? Duration.zero
        : difference;
  }

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  Future<void> _initialize() async {
    try {
      await _loadSettings();

      if (_disposed) return;

      _calculateSchedule();

      isInitialized = true;

      _startClock();

      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint('PrayerController initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      isInitialized = true;
      message = 'Unable to calculate prayer times.';
      _notifySafely();
    }
  }

  // --------------------------------------------------
  // SETTINGS
  // --------------------------------------------------

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_disposed) return;

      final savedLatitude = prefs.getDouble(_latitudeKey);
      final savedLongitude = prefs.getDouble(_longitudeKey);

      if (savedLatitude != null &&
          savedLongitude != null &&
          savedLatitude >= -90 &&
          savedLatitude <= 90 &&
          savedLongitude >= -180 &&
          savedLongitude <= 180) {
        latitude = savedLatitude;
        longitude = savedLongitude;
        city = 'Saved location';
      }

      final savedMethod = prefs.getString(_methodKey);

      if (savedMethod != null) {
        for (final value in CalculationMethod.values) {
          if (value.name == savedMethod) {
            method = value;
            break;
          }
        }
      }

      final savedMadhab = prefs.getString(_madhabKey);

      if (savedMadhab == 'hanafi') {
        madhab = Madhab.hanafi;
      } else if (savedMadhab == 'shafi') {
        madhab = Madhab.shafi;
      }
    } catch (error) {
      debugPrint('Prayer settings load error: $error');
      // Keep safe default settings.
    }
  }

  Future<void> _saveSettings() async {
    if (_disposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (_disposed) return;

      await prefs.setDouble(_latitudeKey, latitude);
      await prefs.setDouble(_longitudeKey, longitude);
      await prefs.setString(_methodKey, method.name);
      await prefs.setString(
        _madhabKey,
        madhab == Madhab.hanafi ? 'hanafi' : 'shafi',
      );
    } catch (error) {
      debugPrint('Prayer settings save error: $error');
    }
  }

  // --------------------------------------------------
  // PRAYER CALCULATION
  // --------------------------------------------------

  PrayerTimes _createPrayerTimes(DateTime date) {
    final coordinates = Coordinates(latitude, longitude);

    final dateComponents = DateComponents.from(date);

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

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _calculateSchedule() {
    if (_disposed) return;

    final now = DateTime.now();

    _prayerTimes = _createPrayerTimes(now);

    final tomorrow = _nextCalendarDay(now);

    _tomorrowPrayerTimes = _createPrayerTimes(tomorrow);

    _scheduleDate = now;

    _refreshNextPrayer(now);
  }

  /// Finds the next actual prayer.
  ///
  /// Sunrise is intentionally excluded because it is not
  /// one of the five obligatory daily prayers.
  void _refreshNextPrayer(DateTime now) {
    if (_prayerTimes == null) {
      _nextPrayer = Prayer.none;
      _nextPrayerAt = null;
      return;
    }

    const dailyPrayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in dailyPrayers) {
      final prayerTime = _prayerTimes!.timeForPrayer(prayer);

      if (prayerTime != null && prayerTime.isAfter(now)) {
        _nextPrayer = prayer;
        _nextPrayerAt = prayerTime;
        return;
      }
    }

    // All today's prayers have passed.
    // The next prayer is tomorrow's Fajr.
    final tomorrowFajr =
        _tomorrowPrayerTimes?.timeForPrayer(Prayer.fajr);

    if (tomorrowFajr != null) {
      _nextPrayer = Prayer.fajr;
      _nextPrayerAt = tomorrowFajr;
    } else {
      _nextPrayer = Prayer.none;
      _nextPrayerAt = null;
    }
  }

  // --------------------------------------------------
  // CLOCK
  // --------------------------------------------------

  void _startClock() {
    if (_disposed) return;

    _stopClock();

    clock.value = DateTime.now();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_disposed) return;

        final now = DateTime.now();

        // Update countdown without rebuilding the whole page.
        clock.value = now;

        // Recalculate after midnight or a calendar date change.
        if (_scheduleDate == null ||
            !_isSameDate(now, _scheduleDate!)) {
          try {
            _calculateSchedule();
            _notifySafely();
          } catch (error) {
            debugPrint('Prayer schedule refresh error: $error');
          }

          return;
        }

        // Move to the next prayer as soon as its time passes.
        if (_nextPrayerAt != null &&
            !now.isBefore(_nextPrayerAt!)) {
          _refreshNextPrayer(now);
          _notifySafely();
        }
      },
    );
  }

  void _stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  // --------------------------------------------------
  // APPLICATION LIFECYCLE
  // --------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      try {
        // Recalculate on resume to account for time changes.
        clock.value = DateTime.now();

        _calculateSchedule();

        _startClock();

        _notifySafely();
      } catch (error) {
        debugPrint('Prayer resume error: $error');
      }
    } else {
      // Stop unnecessary background timer activity.
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

      if (!newLatitude.isFinite ||
          !newLongitude.isFinite ||
          newLatitude < -90 ||
          newLatitude > 90 ||
          newLongitude < -180 ||
          newLongitude > 180) {
        throw Exception('Received invalid location coordinates.');
      }

      latitude = newLatitude;
      longitude = newLongitude;
      city = 'Current location';

      _calculateSchedule();

      await _saveSettings();

      if (_disposed) return;

      message = 'Location updated successfully.';
    } catch (error, stackTrace) {
      debugPrint('Location update error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      message = error
          .toString()
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

  void changeMethod(CalculationMethod value) {
    if (_disposed || method == value) return;

    method = value;

    _applySettingsChange();
  }

  void changeMadhab(Madhab value) {
    if (_disposed || madhab == value) return;

    madhab = value;

    _applySettingsChange();
  }

  void _applySettingsChange() {
    try {
      _calculateSchedule();

      message = null;

      unawaited(_saveSettings());

      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint('Prayer settings update error: $error');
      debugPrintStack(stackTrace: stackTrace);

      message = 'Unable to update prayer calculation settings.';
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
