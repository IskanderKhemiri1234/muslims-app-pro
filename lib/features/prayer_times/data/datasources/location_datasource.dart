
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationDataSource {
  LocationDataSource({
    this.maximumCurrentAccuracy = 250,
    this.maximumCachedAccuracy = 500,
    this.maximumCachedAge = const Duration(hours: 24),
    this.locationTimeout = const Duration(seconds: 20),
  })  : assert(maximumCurrentAccuracy > 0),
        assert(maximumCachedAccuracy > 0),
        assert(maximumCachedAge > Duration.zero),
        assert(locationTimeout > Duration.zero);

  /// Maximum accepted GPS uncertainty for a fresh location.
  final double maximumCurrentAccuracy;

  /// Maximum accepted uncertainty for a cached location.
  final double maximumCachedAccuracy;

  /// Maximum accepted age of a cached location.
  final Duration maximumCachedAge;

  /// Maximum total time allowed for location acquisition.
  final Duration locationTimeout;

  // --------------------------------------------------
  // LOCATION SERVICE
  // --------------------------------------------------

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------
  // PERMISSIONS
  // --------------------------------------------------

  Future<LocationPermission> _checkPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw Exception(
          'لم يتم منح إذن الوصول إلى الموقع.',
        );

      case LocationPermission.deniedForever:
        throw Exception(
          'إذن الموقع مرفوض نهائياً. '
          'يرجى تفعيله من إعدادات التطبيق.',
        );

      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return permission;

      case LocationPermission.unableToDetermine:
        throw Exception(
          'تعذر تحديد حالة إذن الموقع.',
        );
    }
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  bool _hasValidCoordinates(Position position) {
    final latitude = position.latitude;
    final longitude = position.longitude;

    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool _hasValidAccuracy(
    Position position, {
    required double maximumAccuracy,
  }) {
    final accuracy = position.accuracy;

    return accuracy.isFinite &&
        accuracy > 0 &&
        accuracy <= maximumAccuracy;
  }

  bool _hasValidTimestamp(
    Position position, {
    required Duration maximumAge,
  }) {
    final age = DateTime.now().difference(
      position.timestamp,
    );

    // Reject timestamps more than two minutes in the future.
    if (age < const Duration(minutes: -2)) {
      return false;
    }

    // Reject stale location data.
    if (age > maximumAge) {
      return false;
    }

    return true;
  }

  bool _isUsablePosition(
    Position position, {
    required double maximumAccuracy,
    required Duration maximumAge,
  }) {
    return _hasValidCoordinates(position) &&
        _hasValidAccuracy(
          position,
          maximumAccuracy: maximumAccuracy,
        ) &&
        _hasValidTimestamp(
          position,
          maximumAge: maximumAge,
        );
  }

  // --------------------------------------------------
  // CACHED LOCATION
  // --------------------------------------------------

  /// Reads the last known position without requesting permission.
  ///
  /// Returns null if the cached position cannot be trusted.
  Future<Position?> getLastKnownLocation() async {
    try {
      final enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) return null;

      final permission =
          await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      final position =
          await Geolocator.getLastKnownPosition();

      if (position == null) return null;

      final isUsable = _isUsablePosition(
        position,
        maximumAccuracy: maximumCachedAccuracy,
        maximumAge: maximumCachedAge,
      );

      return isUsable ? position : null;
    } catch (_) {
      // Cached location is optional.
      return null;
    }
  }

  // --------------------------------------------------
  // CURRENT LOCATION
  // --------------------------------------------------

  Future<Position> getCurrentLocation() async {
    try {
      // The outer timeout covers service checks, permission
      // requests and the GPS acquisition operation.
      return await _acquireCurrentLocation().timeout(
        locationTimeout,
        onTimeout: () {
          throw TimeoutException(
            'انتهت مهلة تحديد الموقع. '
            'تحقق من GPS وحاول مرة أخرى.',
          );
        },
      );
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة تحديد الموقع. '
        'تحقق من GPS وحاول مرة أخرى.',
      );
    } on LocationServiceDisabledException {
      throw Exception(
        'خدمة الموقع متوقفة. يرجى تفعيل GPS.',
      );
    } on PermissionDeniedException {
      throw Exception(
        'تم رفض إذن الموقع. تحقق من إعدادات التطبيق.',
      );
    }
  }

  Future<Position> _acquireCurrentLocation() async {
    final enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception(
        'خدمة الموقع متوقفة. '
        'يرجى تفعيل GPS والمحاولة مجدداً.',
      );
    }

    await _checkPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: locationTimeout,
      ),
    );

    if (!_hasValidCoordinates(position)) {
      throw Exception(
        'الإحداثيات المستلمة غير صالحة. '
        'حاول تحديد الموقع مجدداً.',
      );
    }

    if (!_hasValidTimestamp(
      position,
      maximumAge: const Duration(minutes: 2),
    )) {
      throw Exception(
        'بيانات الموقع قديمة أو غير متزامنة. '
        'حاول مرة أخرى.',
      );
    }

    if (!_hasValidAccuracy(
      position,
      maximumAccuracy: maximumCurrentAccuracy,
    )) {
      throw Exception(
        'دقة تحديد الموقع ضعيفة. '
        'انتقل إلى مكان مفتوح وحاول مجدداً.',
      );
    }

    return position;
  }
}
