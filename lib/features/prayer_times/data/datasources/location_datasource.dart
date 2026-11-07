
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/models/location_accuracy_assessment.dart';

/// Failures that can occur while acquiring a geographic position.
enum LocationDataSourceFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  permissionUnavailable,
  acquisitionTimeout,
  invalidCoordinates,
  stalePosition,
  poorAccuracy,
  acquisitionFailed,
}

/// A typed location failure that can be handled by presentation layers.
class LocationDataSourceException implements Exception {
  const LocationDataSourceException({
    required this.failure,
    required this.message,
  });

  final LocationDataSourceFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// Acquires and validates foreground geographic positions.
///
/// Location quality is exposed separately from the Position so existing
/// consumers can continue using the original return types.
///
/// No location data is uploaded or transmitted by this class.
class LocationDataSource {
  LocationDataSource({
    this.maximumCurrentAccuracy = 150,
    this.maximumCachedAccuracy = 150,
    this.maximumCachedAge = const Duration(hours: 6),
    this.locationTimeout = const Duration(seconds: 25),
  })  : assert(maximumCurrentAccuracy > 0),
        assert(maximumCachedAccuracy > 0),
        assert(maximumCachedAge > Duration.zero),
        assert(locationTimeout > Duration.zero);

  /// Maximum accepted horizontal accuracy for a live position, in metres.
  final double maximumCurrentAccuracy;

  /// Maximum accepted horizontal accuracy for a cached position, in metres.
  final double maximumCachedAccuracy;

  /// Maximum age accepted for a cached position.
  final Duration maximumCachedAge;

  /// Maximum time allowed for a live location request.
  final Duration locationTimeout;

  LocationAccuracyAssessment? _lastAssessment;

  /// Quality assessment for the most recently accepted position.
  LocationAccuracyAssessment? get lastAssessment => _lastAssessment;

  /// Whether the most recently accepted position was cached.
  bool get lastPositionWasCached =>
      _lastAssessment?.isCached ?? false;

  // ---------------------------------------------------------------------------
  // ERROR FACTORY
  // ---------------------------------------------------------------------------

  LocationDataSourceException _failure(
    LocationDataSourceFailure failure,
    String message,
  ) {
    return LocationDataSourceException(
      failure: failure,
      message: message,
    );
  }

  // ---------------------------------------------------------------------------
  // LOCATION SERVICE
  // ---------------------------------------------------------------------------

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Opens the device location settings.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Opens this application's settings.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PERMISSIONS
  // ---------------------------------------------------------------------------

  Future<LocationPermission> _checkPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.denied:
        throw _failure(
          LocationDataSourceFailure.permissionDenied,
          'لم يتم منح إذن الوصول إلى الموقع. يرجى السماح به للمتابعة.',
        );

      case LocationPermission.deniedForever:
        throw _failure(
          LocationDataSourceFailure.permissionDeniedForever,
          'إذن الموقع مرفوض نهائياً. يرجى تفعيله من إعدادات التطبيق.',
        );

      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return permission;

      case LocationPermission.unableToDetermine:
        throw _failure(
          LocationDataSourceFailure.permissionUnavailable,
          'تعذر تحديد حالة إذن الموقع.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // POSITION ASSESSMENT
  // ---------------------------------------------------------------------------

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

  LocationAccuracyAssessment _assessPosition(
    Position position, {
    required bool isCached,
  }) {
    return LocationAccuracyAssessment.evaluate(
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
      now: DateTime.now(),
      isCached: isCached,
    );
  }

  bool _isTimestampAcceptable(
    Position position, {
    required bool isCached,
  }) {
    final age = DateTime.now().difference(position.timestamp);

    if (age.isNegative) {
      return false;
    }

    if (isCached) {
      return age <= maximumCachedAge;
    }

    return age <= LocationAccuracyAssessment.maximumLiveAge;
  }

  bool _isAssessmentWithinConfiguredLimit(
    LocationAccuracyAssessment assessment, {
    required bool isCached,
  }) {
    if (!assessment.canBeUsedForPrayerCalculation) {
      return false;
    }

    final configuredLimit = isCached
        ? maximumCachedAccuracy
        : maximumCurrentAccuracy;

    return assessment.accuracyMeters <= configuredLimit;
  }

  // ---------------------------------------------------------------------------
  // CACHED LOCATION
  // ---------------------------------------------------------------------------

  /// Reads the last known position without requesting a new permission.
  ///
  /// Returns null when location services, permission, age, coordinates,
  /// or accuracy are not acceptable.
  Future<Position?> getLastKnownLocation() async {
    _lastAssessment = null;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) return null;

      final permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();

      if (position == null || !_hasValidCoordinates(position)) {
        return null;
      }

      if (!_isTimestampAcceptable(
        position,
        isCached: true,
      )) {
        return null;
      }

      final assessment = _assessPosition(
        position,
        isCached: true,
      );

      if (!_isAssessmentWithinConfiguredLimit(
        assessment,
        isCached: true,
      )) {
        return null;
      }

      _lastAssessment = assessment;
      return position;
    } catch (_) {
      // Cached location is optional and must never block app startup.
      _lastAssessment = null;
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // CURRENT LOCATION
  // ---------------------------------------------------------------------------

  Future<Position> getCurrentLocation() async {
    _lastAssessment = null;

    try {
      return await _acquireCurrentLocation().timeout(
        locationTimeout,
        onTimeout: () {
          throw _failure(
            LocationDataSourceFailure.acquisitionTimeout,
            'انتهت مهلة تحديد الموقع. تحقق من GPS وحاول مرة أخرى.',
          );
        },
      );
    } on LocationDataSourceException {
      rethrow;
    } on LocationServiceDisabledException {
      throw _failure(
        LocationDataSourceFailure.serviceDisabled,
        'خدمة الموقع متوقفة. يرجى تفعيل GPS.',
      );
    } on PermissionDeniedException {
      throw _failure(
        LocationDataSourceFailure.permissionDenied,
        'تم رفض إذن الموقع. تحقق من إعدادات التطبيق.',
      );
    } catch (_) {
      throw _failure(
        LocationDataSourceFailure.acquisitionFailed,
        'تعذر الحصول على موقعك حالياً. يرجى المحاولة مرة أخرى.',
      );
    }
  }

  Future<Position> _acquireCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw _failure(
        LocationDataSourceFailure.serviceDisabled,
        'خدمة الموقع متوقفة. يرجى تفعيل GPS والمحاولة مجدداً.',
      );
    }

    await _checkPermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );

    if (!_hasValidCoordinates(position)) {
      throw _failure(
        LocationDataSourceFailure.invalidCoordinates,
        'الإحداثيات المستلمة غير صالحة. حاول تحديد الموقع مجدداً.',
      );
    }

    if (!_isTimestampAcceptable(
      position,
      isCached: false,
    )) {
      throw _failure(
        LocationDataSourceFailure.stalePosition,
        'بيانات الموقع قديمة أو غير متزامنة. حاول مرة أخرى.',
      );
    }

    final assessment = _assessPosition(
      position,
      isCached: false,
    );

    if (!_isAssessmentWithinConfiguredLimit(
      assessment,
      isCached: false,
    )) {
      throw _failure(
        LocationDataSourceFailure.poorAccuracy,
        'دقة تحديد الموقع غير كافية حالياً. انتقل إلى مكان مفتوح وحاول مجدداً.',
      );
    }

    _lastAssessment = assessment;
    return position;
  }
}
