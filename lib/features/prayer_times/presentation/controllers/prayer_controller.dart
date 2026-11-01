
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/timezone_discovery_service.dart';
import '../../data/datasources/location_datasource.dart';
import '../../domain/services/global_prayer_calculation_service.dart';
import '../../domain/services/prayer_calculation_service.dart';
import '../../domain/services/prayer_rules_service.dart';

class PrayerController extends ChangeNotifier
    with WidgetsBindingObserver {
  PrayerController({
    LocationDataSource? locationSource,
    TimezoneDiscoveryService? timezoneService,
    GlobalPrayerCalculationService? globalCalculationService,
    PrayerCalculationService? calculationService,
    PrayerRulesService? rulesService,
  })  : _locationSource = locationSource ?? LocationDataSource(),
        _timezoneService =
            timezoneService ?? TimezoneDiscoveryService(),
        _globalCalculationService =
            globalCalculationService ??
                const GlobalPrayerCalculationService(),
        _calculationService =
            calculationService ?? const PrayerCalculationService(),
        _rulesService = rulesService ??
            PrayerRulesService(
              fallbackMethod: CalculationMethod.muslim_world_league,
              fallbackMadhab: Madhab.shafi,
            ) {
    WidgetsBinding.instance.addObserver(this);

    clock.value = DateTime.now();

    unawaited(retryInitialization());
  }

  // --------------------------------------------------
  // DEPENDENCIES
  // --------------------------------------------------

  final LocationDataSource _locationSource;
  final TimezoneDiscoveryService _timezoneService;

  final GlobalPrayerCalculationService
      _globalCalculationService;

  final PrayerCalculationService _calculationService;
  final PrayerRulesService _rulesService;

  // --------------------------------------------------
  // PERSISTENCE
  // --------------------------------------------------

  static const String _latitudeKey = 'prayer_latitude';
  static const String _longitudeKey = 'prayer_longitude';
  static const String _methodKey = 'prayer_method';
  static const String _madhabKey = 'prayer_madhab';

  Future<void> _settingsWriteQueue = Future<void>.value();

  bool _hasSavedMethod = false;
  bool _hasSavedMadhab = false;

  // --------------------------------------------------
  // DEFAULT SETTINGS
  // --------------------------------------------------

  double latitude = 33.5731;
  double longitude = -7.5898;

  String city = 'Casablanca';

  CalculationMethod method =
      CalculationMethod.muslim_world_league;

  Madhab madhab = Madhab.shafi;

  // --------------------------------------------------
  // TIMEZONE
  // --------------------------------------------------

  DiscoveredTimezone? _discoveredTimezone;

  String? get timezoneId => _discoveredTimezone?.timezoneId;

  String? get countryCode => _discoveredTimezone?.countryCode;

  tz.Location? get timezoneLocation =>
      _discoveredTimezone?.location;

  // --------------------------------------------------
  // PRAYER STATE
  // --------------------------------------------------

  PrayerTimes? _prayerTimes;
  PrayerTimes? _tomorrowPrayerTimes;

  GlobalPrayerSchedule? _globalSchedule;
  GlobalPrayerSchedule? _tomorrowGlobalSchedule;

  DateTime? _scheduleDate;
  DateTime? _nextPrayerAt;

  Prayer _nextPrayer = Prayer.none;

  /// Legacy compatibility for existing widgets.
  ///
  /// New features should use [globalSchedule].
  PrayerTimes? get prayerTimes => _prayerTimes;

  PrayerTimes? get tomorrowPrayerTimes => _tomorrowPrayerTimes;

  GlobalPrayerSchedule? get globalSchedule => _globalSchedule;

  GlobalPrayerSchedule? get tomorrowGlobalSchedule =>
      _tomorrowGlobalSchedule;

  Prayer get nextPrayer => _nextPrayer;

  DateTime? get nextPrayerTime => _nextPrayerAt;

  /// Indicates whether the authoritative global schedule is available.
  bool get hasUsableSchedule =>
      _globalSchedule != null &&
      _tomorrowGlobalSchedule != null &&
      _nextPrayerAt != null &&
      _nextPrayer != Prayer.none;

  // --------------------------------------------------
  // CLOCK
  // --------------------------------------------------

  final ValueNotifier<DateTime> clock =
      ValueNotifier<DateTime>(DateTime.now());

  ValueListenable<DateTime> get clockListenable => clock;

  Timer? _timer;

  static const Duration _clockInterval = Duration(seconds: 1);

  // --------------------------------------------------
  // STATUS
  // --------------------------------------------------

  bool isLoadingLocation = false;

  /// Indicates that an initialization attempt has completed.
  ///
  /// Check [hasUsableSchedule] before relying on prayer data.
  bool isInitialized = false;

  String? message;

  bool _disposed = false;

  bool get isDisposed => _disposed;

  Future<void>? _initializationTask;

  bool _isAppActive = true;

  // --------------------------------------------------
  // COUNTDOWN
  // --------------------------------------------------

  Duration get remaining {
    final target = _nextPrayerAt;

    if (target == null) {
      return Duration.zero;
    }

    final difference = target.difference(clock.value);

    return difference.isNegative ? Duration.zero : difference;
  }

  // --------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------

  Future<void> retryInitialization() {
    if (_disposed) {
      return Future<void>.value();
    }

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

      await _discoverTimezone();

      if (_disposed) return;

      _applyRulesProfileIfNoSavedSettings();

      _calculateSchedule();

      if (_disposed) return;

      isInitialized = true;
      message = null;

      if (_isAppActive) {
        _startClock();
      }
    } catch (error, stackTrace) {
      debugPrint('Prayer initialization error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      isInitialized = true;
      message = 'Unable to initialize prayer times.';

      _stopClock();
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  bool _isValidCoordinates(double lat, double lon) {
    return lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // --------------------------------------------------
  // LOAD SETTINGS
  // --------------------------------------------------

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_disposed) return;

      final savedLatitude = prefs.getDouble(_latitudeKey);
      final savedLongitude = prefs.getDouble(_longitudeKey);

      if (savedLatitude != null &&
          savedLongitude != null &&
          _isValidCoordinates(savedLatitude, savedLongitude)) {
        latitude = savedLatitude;
        longitude = savedLongitude;
        city = 'Saved location';
      }

      final savedMethod = prefs.getString(_methodKey);

      if (savedMethod != null) {
        for (final value in CalculationMethod.values) {
          if (value.name == savedMethod) {
            method = value;
            _hasSavedMethod = true;
            break;
          }
        }
      }

      final savedMadhab = prefs.getString(_madhabKey);

      switch (savedMadhab) {
        case 'hanafi':
          madhab = Madhab.hanafi;
          _hasSavedMadhab = true;
          break;

        case 'shafi':
          madhab = Madhab.shafi;
          _hasSavedMadhab = true;
          break;
      }
    } catch (error, stackTrace) {
      debugPrint('Prayer settings load error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // --------------------------------------------------
  // SAVE SETTINGS
  // --------------------------------------------------

  Future<void> _saveSettings() {
    if (_disposed) {
      return Future<void>.value();
    }

    final savedLatitude = latitude;
    final savedLongitude = longitude;
    final savedMethod = method.name;

    final savedMadhab =
        madhab == Madhab.hanafi ? 'hanafi' : 'shafi';

    final operation = _settingsWriteQueue.then((_) async {
      if (_disposed) return;

      final prefs = await SharedPreferences.getInstance();

      if (_disposed) return;

      await prefs.setDouble(_latitudeKey, savedLatitude);
      await prefs.setDouble(_longitudeKey, savedLongitude);
      await prefs.setString(_methodKey, savedMethod);
      await prefs.setString(_madhabKey, savedMadhab);
    });

    _settingsWriteQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Prayer settings save error: $error');
      },
    );

    return operation;
  }

  // --------------------------------------------------
  // TIMEZONE DISCOVERY
  // --------------------------------------------------

  Future<void> _discoverTimezone() async {
    final result = await _timezoneService.discover(
      latitude: latitude,
      longitude: longitude,
    );

    if (_disposed) return;

    if (result == null) {
      throw StateError(
        'No timezone could be resolved for the selected coordinates.',
      );
    }

    if (result.timezoneId.isEmpty ||
        result.timezoneId != result.location.name) {
      throw StateError('Invalid discovered timezone.');
    }

    _discoveredTimezone = result;
  }

  // --------------------------------------------------
  // PRAYER RULES
  // --------------------------------------------------

  void _applyRulesProfileIfNoSavedSettings() {
    if (_hasSavedMethod && _hasSavedMadhab) {
      return;
    }

    final profile = _rulesService.resolve(
      countryCode: countryCode ?? 'GLOBAL',
    );

    if (!_hasSavedMethod) {
      method = profile.method;
    }

    if (!_hasSavedMadhab) {
      madhab = profile.madhab;
    }
  }

  /// Installs a previously fetched and validated rules configuration.
  ///
  /// The caller is responsible for fetching and authenticating
  /// the configuration before calling this method.
  void installPrayerRulesConfiguration(String jsonSource) {
    if (_disposed) return;

    _rulesService.installConfiguration(jsonSource);

    final profile = _rulesService.resolve(
      countryCode: countryCode ?? 'GLOBAL',
    );

    _applySettings(
      newMethod: profile.method,
      newMadhab: profile.madhab,
    );
  }

  // --------------------------------------------------
  // PRAYER CALCULATION
  // --------------------------------------------------

  DateTime _dateOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  DateTime _nextCalendarDay(DateTime date) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day + 1,
    );
  }

  GlobalPrayerSchedule _createGlobalSchedule(DateTime date) {
    final timezone = _discoveredTimezone?.location;

    if (timezone == null) {
      throw StateError('Timezone has not been discovered.');
    }

    return _globalCalculationService.calculate(
      latitude: latitude,
      longitude: longitude,
      localDate: _dateOnly(date),
      timezone: timezone,
      method: method,
      madhab: madhab,
    );
  }

  /// Compatibility schedule for existing widgets.
  ///
  /// The global schedule remains authoritative.
  PrayerTimes _createLegacyPrayerTimes(DateTime date) {
    return _calculationService.calculate(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: method,
      madhab: madhab,
    );
  }

  void _calculateSchedule() {
    if (_disposed) return;

    if (!_isValidCoordinates(latitude, longitude)) {
      throw StateError('Invalid prayer calculation coordinates.');
    }

    final timezone = _discoveredTimezone?.location;

    if (timezone == null) {
      throw StateError('Timezone is not available.');
    }

    final now = DateTime.now();
    final localNow = tz.TZDateTime.from(now, timezone);

    final todayDate = _dateOnly(localNow);
    final tomorrowDate = _nextCalendarDay(localNow);

    // The global engine is the authoritative calculation source.
    final todayGlobal = _createGlobalSchedule(todayDate);
    final tomorrowGlobal = _createGlobalSchedule(tomorrowDate);

    final next = _findNextPrayer(
      today: todayGlobal,
      tomorrow: tomorrowGlobal,
      now: now,
    );

    // Legacy compatibility must not invalidate a valid global schedule.
    PrayerTimes? todayLegacy;
    PrayerTimes? tomorrowLegacy;

    try {
      todayLegacy = _createLegacyPrayerTimes(localNow);

      tomorrowLegacy = _createLegacyPrayerTimes(
        DateTime(
          tomorrowDate.year,
          tomorrowDate.month,
          tomorrowDate.day,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Legacy prayer calculation error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Commit after the authoritative calculations complete.
    _globalSchedule = todayGlobal;
    _tomorrowGlobalSchedule = tomorrowGlobal;

    _prayerTimes = todayLegacy;
    _tomorrowPrayerTimes = tomorrowLegacy;

    _scheduleDate = todayDate;

    _nextPrayer = next.$1;
    _nextPrayerAt = next.$2;
  }

  // --------------------------------------------------
  // NEXT PRAYER ENGINE
  // --------------------------------------------------

  (Prayer, tz.TZDateTime?) _findNextPrayer({
    required GlobalPrayerSchedule today,
    required GlobalPrayerSchedule tomorrow,
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
      final prayerTime = today.timeForPrayer(prayer);

      if (prayerTime != null && prayerTime.isAfter(now)) {
        return (prayer, prayerTime);
      }
    }

    final tomorrowFajr = tomorrow.timeForPrayer(Prayer.fajr);

    if (tomorrowFajr != null && tomorrowFajr.isAfter(now)) {
      return (Prayer.fajr, tomorrowFajr);
    }

    return (Prayer.none, null);
  }

  void _refreshNextPrayer(DateTime now) {
    final today = _globalSchedule;
    final tomorrow = _tomorrowGlobalSchedule;

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
    if (_disposed || !_isAppActive) return;

    _stopClock();

    _synchronizeClock();

    _timer = Timer.periodic(
      _clockInterval,
      (_) {
        if (!_disposed && _isAppActive) {
          _synchronizeClock();
        }
      },
    );
  }

  void _synchronizeClock() {
    if (_disposed) return;

    final now = DateTime.now();
    final previous = clock.value;

    clock.value = now;

    final timezone = _discoveredTimezone?.location;

    if (timezone == null) return;

    final localNow = tz.TZDateTime.from(now, timezone);

    final scheduleDate = _scheduleDate;

    if (scheduleDate == null ||
        !_isSameDate(localNow, scheduleDate)) {
      _recalculateSafely();
      return;
    }

    final expectedElapsed = _clockInterval.inMilliseconds;
    final actualElapsed = now.difference(previous).inMilliseconds;

    if (actualElapsed < 0 ||
        actualElapsed > expectedElapsed * 5) {
      _recalculateSafely();
      return;
    }

    final target = _nextPrayerAt;

    if (target != null && !now.isBefore(target)) {
      _refreshNextPrayer(now);
      _notifySafely();
    }
  }

  void _recalculateSafely() {
    if (_disposed) return;

    try {
      _calculateSchedule();
      message = null;
      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint('Prayer schedule recalculation error: $error');
      debugPrintStack(stackTrace: stackTrace);

      message = 'Unable to refresh prayer times.';

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;

      _recalculateSafely();
      _startClock();

      _notifySafely();
    } else {
      _isAppActive = false;
      _stopClock();
    }
  }

  // --------------------------------------------------
  // LOCATION
  // --------------------------------------------------

  Future<void> updateLocation() async {
    if (_disposed || isLoadingLocation) return;

    // Prevent a location update from racing initialization.
    final initialization = _initializationTask;

    if (initialization != null) {
      await initialization;

      if (_disposed) return;
    }

    isLoadingLocation = true;
    message = null;
    _notifySafely();

    final oldLatitude = latitude;
    final oldLongitude = longitude;
    final oldCity = city;
    final oldTimezone = _discoveredTimezone;

    try {
      final Position position =
          await _locationSource.getCurrentLocation();

      if (_disposed) return;

      final newLatitude = position.latitude;
      final newLongitude = position.longitude;

      if (!_isValidCoordinates(newLatitude, newLongitude)) {
        throw StateError('Received invalid location coordinates.');
      }

      latitude = newLatitude;
      longitude = newLongitude;
      city = 'Current location';

      try {
        await _discoverTimezone();

        if (_disposed) return;

        _calculateSchedule();
      } catch (_) {
        if (_disposed) return;

        _restoreLocationState(
          latitude: oldLatitude,
          longitude: oldLongitude,
          city: oldCity,
          timezone: oldTimezone,
        );

        _calculateSchedule();

        rethrow;
      }

      if (_disposed) return;

      // A valid new location remains active even if persistence fails.
      try {
        await _saveSettings();
      } catch (error, stackTrace) {
        debugPrint('Location persistence error: $error');
        debugPrintStack(stackTrace: stackTrace);

        message = 'Location updated, but saving settings failed.';
      }

      if (_disposed) return;

      // Restart the clock after successful location calculation.
      if (_isAppActive) {
        _startClock();
      }

      if (message == null) {
        message = 'Location updated successfully.';
      }
    } catch (error, stackTrace) {
      debugPrint('Location update error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (_disposed) return;

      _restoreLocationState(
        latitude: oldLatitude,
        longitude: oldLongitude,
        city: oldCity,
        timezone: oldTimezone,
      );

      // Attempt to restore the previous schedule safely.
      try {
        _calculateSchedule();

        if (_isAppActive) {
          _startClock();
        }
      } catch (rollbackError, rollbackStackTrace) {
        debugPrint('Location rollback error: $rollbackError');
        debugPrintStack(stackTrace: rollbackStackTrace);
      }

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

  void _restoreLocationState({
    required double latitude,
    required double longitude,
    required String city,
    required DiscoveredTimezone? timezone,
  }) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.city = city;
    _discoveredTimezone = timezone;
  }

  // --------------------------------------------------
  // CALCULATION SETTINGS
  // --------------------------------------------------

  void changeMethod(CalculationMethod value) {
    if (_disposed || method == value) return;

    _applySettings(newMethod: value);
  }

  void changeMadhab(Madhab value) {
    if (_disposed || madhab == value) return;

    _applySettings(newMadhab: value);
  }

  void _applySettings({
    CalculationMethod? newMethod,
    Madhab? newMadhab,
  }) {
    if (_disposed) return;

    final previousMethod = method;
    final previousMadhab = madhab;
    final previousHasSavedMethod = _hasSavedMethod;
    final previousHasSavedMadhab = _hasSavedMadhab;

    try {
      if (newMethod != null) {
        method = newMethod;
        _hasSavedMethod = true;
      }

      if (newMadhab != null) {
        madhab = newMadhab;
        _hasSavedMadhab = true;
      }

      _calculateSchedule();

      message = null;

      unawaited(
        _saveSettings().catchError(
          (Object error, StackTrace stackTrace) {
            debugPrint(
              'Prayer settings persistence error: $error',
            );
          },
        ),
      );

      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint('Prayer settings update error: $error');
      debugPrintStack(stackTrace: stackTrace);

      method = previousMethod;
      madhab = previousMadhab;
      _hasSavedMethod = previousHasSavedMethod;
      _hasSavedMadhab = previousHasSavedMadhab;

      _recalculateSafely();

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
