
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

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

  // الموقع الافتراضي: الدار البيضاء
  double latitude = 33.5731;
  double longitude = -7.5898;
  String city = 'Casablanca';

  // إعدادات حساب الصلاة
  CalculationMethod method = CalculationMethod.muslimWorldLeague;
  Madhab madhab = Madhab.shafi;

  PrayerTimes? _prayerTimes;
  DateTime? _scheduleDate;

  final ValueNotifier<DateTime> clock =
      ValueNotifier<DateTime>(DateTime.now());

  Timer? _timer;

  bool isLoadingLocation = false;
  String? message;
  bool _disposed = false;

  PrayerTimes? get prayerTimes => _prayerTimes;

  void _initialize() {
    _calculateSchedule();
    _startClock();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  void _calculateSchedule() {
    if (_disposed) return;

    final now = DateTime.now();

    final coordinates = Coordinates(latitude, longitude);
    final date = DateComponents.from(now);

    final parameters = method.getParameters();
    parameters.madhab = madhab;

    _prayerTimes = PrayerTimes(
      coordinates,
      date,
      parameters,
    );

    _scheduleDate = now;
  }

  void _startClock() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_disposed) return;

        final now = DateTime.now();
        clock.value = now;

        if (_scheduleDate == null ||
            !_isSameDate(now, _scheduleDate!)) {
          _calculateSchedule();
          notifyListeners();
        }
      },
    );
  }

  void _stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        final now = DateTime.now();
        clock.value = now;

        if (_scheduleDate == null ||
            !_isSameDate(now, _scheduleDate!)) {
          _calculateSchedule();
          notifyListeners();
        }

        _startClock();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopClock();
        break;
    }
  }

  Future<void> updateLocation() async {
    if (_disposed || isLoadingLocation) return;

    isLoadingLocation = true;
    message = null;
    notifyListeners();

    try {
      final Position position =
          await _locationSource.getCurrentLocation();

      if (_disposed) return;

      latitude = position.latitude;
      longitude = position.longitude;
      city = 'موقعي الحالي';

      _calculateSchedule();

      message = 'تم تحديث الموقع بنجاح.';
    } catch (error) {
      if (_disposed) return;

      message = error
          .toString()
          .replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed) {
        isLoadingLocation = false;
        notifyListeners();
      }
    }
  }

  void changeMethod(CalculationMethod value) {
    if (_disposed) return;

    method = value;
    _calculateSchedule();
    notifyListeners();
  }

  void changeMadhab(Madhab value) {
    if (_disposed) return;

    madhab = value;
    _calculateSchedule();
    notifyListeners();
  }

  Prayer get nextPrayer {
    return _prayerTimes?.nextPrayer() ?? Prayer.none;
  }

  DateTime? get nextPrayerTime {
    final prayer = nextPrayer;

    if (prayer == Prayer.none) return null;

    return _prayerTimes?.timeForPrayer(prayer);
  }

  Duration get remaining {
    final target = nextPrayerTime;

    if (target == null) return Duration.zero;

    final difference = target.difference(clock.value);

    return difference.isNegative
        ? Duration.zero
        : difference;
  }

  @override
  void dispose() {
    _disposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _stopClock();
    clock.dispose();

    super.dispose();
  }
}
