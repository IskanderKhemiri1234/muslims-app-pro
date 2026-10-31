
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationDataSource {
  LocationDataSource({
    this.maximumCurrentAccuracy = 250,
    this.maximumCachedAccuracy = 500,
    this.maximumCachedAge = const Duration(hours: 24),
    this.locationTimeout = const Duration(seconds: 20),
  });

  /// Maximum accepted GPS uncertainty for a fresh location, in meters.
  final double maximumCurrentAccuracy;

  /// Maximum accepted uncertainty for a cached location, in meters.
  final double maximumCachedAccuracy;

  /// A cached location older than this is rejected.
  final Duration maximumCachedAge;

  /// Maximum time allowed to obtain a fresh location.
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
  // PERMISSION
  // --------------------------------------------------

  Future<LocationPermission> _checkPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'إذن الموقع مرفوض نهائيًا. يرجى تفعيله من إعدادات التطبيق.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception('لم يتم منح إذن الوصول إلى الموقع.');
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('صلاحية الموقع غير متاحة.');
    }

    return permission;
  }

  // --------------------------------------------------
  // COORDINATE VALIDATION
  // --------------------------------------------------

  bool _hasValidCoordinates(Position position) {
    return position.latitude.isFinite &&
        position.longitude.isFinite &&
        position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180;
  }

  bool _hasValidAccuracy(
    Position position, {
    required double maximumAccuracy,
  }) {
    return position.accuracy.isFinite &&
        position.accuracy > 0 &&
        position.accuracy <= maximumAccuracy;
  }

  bool _hasValidTimestamp(
    Position position, {
    required Duration maximumAge,
  }) {
    final now = DateTime.now();
    final age = now.difference(position.timestamp);

    // Reject timestamps that are too far in the future.
    if (age < const Duration(minutes: -2)) {
      return false;
    }

    // Reject old or stale location fixes.
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
  // LAST KNOWN LOCATION
  // --------------------------------------------------

  /// Returns a previously recorded location only when:
  /// - Location services are enabled.
  /// - Permission is already granted.
  /// - Coordinates are valid.
  /// - Accuracy is acceptable.
  /// - The location is not too old.
  ///
  /// This method never requests permission.
  Future<Position?> getLastKnownLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) return null;

      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();

      if (position == null) return null;

      if (!_isUsablePosition(
        position,
        maximumAccuracy: maximumCachedAccuracy,
        maximumAge: maximumCachedAge,
      )) {
        return null;
      }

      return position;
    } catch (_) {
      // A cached location is optional.
      return null;
    }
  }

  // --------------------------------------------------
  // CURRENT LOCATION
  // --------------------------------------------------

  /// Obtains a fresh location after user permission.
  ///
  /// Throws an exception if the location cannot be trusted.
  Future<Position> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception(
        'خدمة الموقع متوقفة. يرجى تفعيل GPS والمحاولة مجددًا.',
      );
    }

    await _checkPermission();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: locationTimeout,
        ),
      );

      if (!_hasValidCoordinates(position)) {
        throw Exception(
          'الإحداثيات المستلمة غير صالحة. حاول تحديد الموقع مجددًا.',
        );
      }

      if (!_hasValidTimestamp(
        position,
        maximumAge: const Duration(minutes: 2),
      )) {
        throw Exception(
          'بيانات الموقع قديمة أو غير متزامنة. حاول مرة أخرى.',
        );
      }

      if (!_hasValidAccuracy(
        position,
        maximumAccuracy: maximumCurrentAccuracy,
      )) {
        throw Exception(
          'دقة تحديد الموقع ضعيفة. انتقل إلى مكان مفتوح وحاول مجددًا.',
        );
      }

      return position;
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة تحديد الموقع. تحقق من GPS وحاول مرة أخرى.',
      );
    } on LocationServiceDisabledException {
      throw Exception(
        'خدمة الموقع متوقفة. يرجى تفعيلها.',
      );
    } on PermissionDeniedException {
      throw Exception(
        'تم رفض إذن الموقع. تحقق من إعدادات التطبيق.',
      );
    }
  }
}
