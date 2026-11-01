
import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// أنواع الأخطاء التي يمكن أن تنتج عن عملية تحديد الموقع.
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

/// خطأ واضح يمكن للطبقات الأعلى التعامل معه.
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

  /// أقصى هامش خطأ مقبول للموقع الحالي بالمتر.
  final double maximumCurrentAccuracy;

  /// أقصى هامش خطأ مقبول للموقع المخزن بالمتر.
  final double maximumCachedAccuracy;

  /// أقصى عمر مقبول للموقع المخزن.
  final Duration maximumCachedAge;

  /// المهلة القصوى لعملية تحديد الموقع.
  final Duration locationTimeout;

  // --------------------------------------------------
  // ERROR FACTORY
  // --------------------------------------------------

  LocationDataSourceException _failure(
    LocationDataSourceFailure failure,
    String message,
  ) {
    return LocationDataSourceException(
      failure: failure,
      message: message,
    );
  }

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

  /// يفتح إعدادات خدمة الموقع في الجهاز.
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// يفتح إعدادات التطبيق لإدارة الأذونات.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
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
    final age = DateTime.now().difference(position.timestamp);

    // السماح بفارق بسيط بسبب اختلاف ساعة الجهاز.
    if (age < const Duration(minutes: -2)) {
      return false;
    }

    return age <= maximumAge;
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

  /// قراءة آخر موقع معروف دون طلب إذن جديد.
  ///
  /// يعيد null إذا لم يكن الموقع متاحاً أو غير صالح.
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
      // الموقع المخزن اختياري ولا يجب أن يمنع استمرار التطبيق.
      return null;
    }
  }

  // --------------------------------------------------
  // CURRENT LOCATION
  // --------------------------------------------------

  Future<Position> getCurrentLocation() async {
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
        accuracy: LocationAccuracy.high,
      ),
    );

    if (!_hasValidCoordinates(position)) {
      throw _failure(
        LocationDataSourceFailure.invalidCoordinates,
        'الإحداثيات المستلمة غير صالحة. حاول تحديد الموقع مجدداً.',
      );
    }

    if (!_hasValidTimestamp(
      position,
      maximumAge: const Duration(minutes: 2),
    )) {
      throw _failure(
        LocationDataSourceFailure.stalePosition,
        'بيانات الموقع قديمة أو غير متزامنة. حاول مرة أخرى.',
      );
    }

    if (!_hasValidAccuracy(
      position,
      maximumAccuracy: maximumCurrentAccuracy,
    )) {
      throw _failure(
        LocationDataSourceFailure.poorAccuracy,
        'دقة تحديد الموقع ضعيفة. انتقل إلى مكان مفتوح وحاول مجدداً.',
      );
    }

    return position;
  }
}
