import 'dart:math' as math;

import 'package:geomag/geomag.dart';

/// الحسابات الجغرافية والمغناطيسية الخاصة باتجاه القبلة.
///
/// جميع الزوايا الناتجة بوحدة الدرجات:
/// - الاتجاه الحقيقي: محسوب من الشمال الجغرافي.
/// - الانحراف المغناطيسي: موجب شرقاً وسالب غرباً.
/// - اتجاه البوصلة: يُصحح بإضافة الانحراف المغناطيسي.
class QiblaService {
  QiblaService._();

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
  static const double earthRadiusKm = 6371.0088;

  static const double _degreesToRadians = math.pi / 180.0;
  static const double _radiansToDegrees = 180.0 / math.pi;
  static const double _epsilon = 1e-10;

  /// حساب اتجاه القبلة من موقع المستخدم بالنسبة إلى الشمال الحقيقي.
  ///
  /// النتيجة بين 0 و360 درجة.
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final userLat = latitude * _degreesToRadians;
    final userLon = longitude * _degreesToRadians;
    final kaabaLat = kaabaLatitude * _degreesToRadians;
    final kaabaLon = kaabaLongitude * _degreesToRadians;

    final deltaLon = kaabaLon - userLon;

    final y = math.sin(deltaLon);
    final x = math.cos(userLat) * math.tan(kaabaLat) -
        math.sin(userLat) * math.cos(deltaLon);

    final bearing = math.atan2(y, x) * _radiansToDegrees;

    return normalize(bearing);
  }

  /// حساب المسافة الجغرافية إلى الكعبة بالكيلومترات.
  ///
  /// يستخدم معادلة Haversine على سطح الأرض.
  static double calculateDistanceKm({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final lat1 = latitude * _degreesToRadians;
    final lat2 = kaabaLatitude * _degreesToRadians;
    final deltaLat = (kaabaLatitude - latitude) * _degreesToRadians;
    final deltaLon = (kaabaLongitude - longitude) * _degreesToRadians;

    final sinLat = math.sin(deltaLat / 2);
    final sinLon = math.sin(deltaLon / 2);

    final a = sinLat * sinLat +
        math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;

    final safeA = a.clamp(0.0, 1.0);
    final centralAngle = 2 * math.atan2(
      math.sqrt(safeA),
      math.sqrt(1.0 - safeA),
    );

    return earthRadiusKm * centralAngle;
  }

  /// حساب الانحراف المغناطيسي من نموذج geomag المتاح في المكتبة.
  ///
  /// القيمة الموجبة تعني شرقاً والسالبة تعني غرباً.
  /// لا تفترض هذه الدالة سنة نموذج مغناطيسي بعينها؛ ذلك يعتمد
  /// على إصدار مكتبة geomag والبيانات المرفقة بها.
  static double calculateMagneticDeclination({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    _validateCoordinates(latitude, longitude);

    final result = GeoMag().calculate(
      latitude,
      longitude,
      0,
      date ?? DateTime.now(),
    );

    final declination = result.dec.toDouble();

    if (!declination.isFinite || declination.abs() > 180) {
      throw StateError('تعذر حساب الانحراف المغناطيسي بصورة صحيحة.');
    }

    return declination;
  }

  /// تحويل قراءة البوصلة المغناطيسية إلى اتجاه حقيقي.
  ///
  /// true heading = magnetic heading + declination
  static double magneticToTrueHeading({
    required double magneticHeading,
    required double declination,
  }) {
    _validateFinite(magneticHeading, 'magneticHeading');
    _validateFinite(declination, 'declination');

    return normalize(magneticHeading + declination);
  }

  /// أقصر فرق زاوي موقّع بين اتجاه الهدف والاتجاه الحالي.
  ///
  /// النتيجة بين -180 و+180 درجة.
  /// القيمة الموجبة تعني الدوران باتجاه عقارب الساعة.
  static double shortestAngleDifference(
    double target,
    double current,
  ) {
    _validateFinite(target, 'target');
    _validateFinite(current, 'current');

    return normalizeSigned(target - current);
  }

  /// توحيد الزاوية لتكون بين 0 و360 درجة.
  static double normalize(double degrees) {
    _validateFinite(degrees, 'degrees');

    final normalized = degrees % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  /// توحيد الزاوية لتكون بين -180 و+180 درجة.
  static double normalizeSigned(double degrees) {
    final normalized = normalize(degrees + 180.0) - 180.0;
    return normalized == -180.0 ? 180.0 : normalized;
  }

  /// إنشاء نقاط مسار كروي بين موقع المستخدم والكعبة.
  ///
  /// يمكن تمرير النقاط إلى FlutterMap لرسم خط المسار.
  /// هذه الدالة لا تحتاج إلى اتصال بالإنترنت.
  static List<GeoPoint> greatCircleRoute({
    required double startLatitude,
    required double startLongitude,
    double endLatitude = kaabaLatitude,
    double endLongitude = kaabaLongitude,
    int segments = 64,
  }) {
    _validateCoordinates(startLatitude, startLongitude);
    _validateCoordinates(endLatitude, endLongitude);

    if (segments < 1 || segments > 512) {
      throw ArgumentError.value(
        segments,
        'segments',
        'يجب أن يكون عدد المقاطع بين 1 و512.',
      );
    }

    final start = _Vector3.fromCoordinates(
      startLatitude,
      startLongitude,
    );

    final end = _Vector3.fromCoordinates(
      endLatitude,
      endLongitude,
    );

    final dot = start.dot(end).clamp(-1.0, 1.0);
    final omega = math.acos(dot);
    final sinOmega = math.sin(omega);

    final points = <GeoPoint>[];

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      late final _Vector3 point;

      if (omega < _epsilon) {
        // النقطتان متقاربتان جداً.
        point = start;
      } else if (sinOmega.abs() < _epsilon) {
        // حالة تقارب التعامد العكسي: نستخدم استيفاءً مستقراً
        // بدلاً من القسمة على قيمة قريبة من الصفر.
        point = _Vector3.linearInterpolate(start, end, t);
      } else {
        final startWeight = math.sin((1 - t) * omega) / sinOmega;
        final endWeight = math.sin(t * omega) / sinOmega;

        point = (start * startWeight + end * endWeight).normalized();
      }

      points.add(point.toGeoPoint());
    }

    return points;
  }

  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError(
        'إحداثيات الموقع غير صحيحة: '
        'latitude=$latitude, longitude=$longitude',
      );
    }
  }

  static void _validateFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'يجب أن تكون قيمة رقمية صالحة.');
    }
  }
}

/// نقطة جغرافية تستخدم في رسم المسار على الخريطة.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });
}

/// متجه ثلاثي الأبعاد يستخدم للحسابات الكروية.
class _Vector3 {
  final double x;
  final double y;
  final double z;

  const _Vector3(this.x, this.y, this.z);

  factory _Vector3.fromCoordinates(
    double latitude,
    double longitude,
  ) {
    final lat = latitude * QiblaService._degreesToRadians;
    final lon = longitude * QiblaService._degreesToRadians;
    final cosLat = math.cos(lat);

    return _Vector3(
      cosLat * math.cos(lon),
      cosLat * math.sin(lon),
      math.sin(lat),
    );
  }

  double dot(_Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }

  double get magnitude {
    return math.sqrt(x * x + y * y + z * z);
  }

  _Vector3 normalized() {
    final length = magnitude;

    if (length < QiblaService._epsilon) {
      throw StateError('تعذر تطبيع متجه المسار الجغرافي.');
    }

    return _Vector3(
      x / length,
      y / length,
      z / length,
    );
  }

  _Vector3 toGeoPointVector() => normalized();

  GeoPoint toGeoPoint() {
    final vector = toGeoPointVector();

    final latitude = math.atan2(
      vector.z,
      math.sqrt(vector.x * vector.x + vector.y * vector.y),
    );

    final longitude = math.atan2(vector.y, vector.x);

    return GeoPoint(
      latitude: latitude * QiblaService._radiansToDegrees,
      longitude: longitude * QiblaService._radiansToDegrees,
    );
  }

  static _Vector3 linearInterpolate(
    _Vector3 start,
    _Vector3 end,
    double t,
  ) {
    final interpolated = _Vector3(
      start.x + (end.x - start.x) * t,
      start.y + (end.y - start.y) * t,
      start.z + (end.z - start.z) * t,
    );

    if (interpolated.magnitude < QiblaService._epsilon) {
      // اختيار محور عمودي لتجنب المتجه الصفري في الحالة المضادة تماماً.
      final perpendicular = _Vector3(
        -start.y,
        start.x,
        0,
      );

      return perpendicular.normalized();
    }

    return interpolated.normalized();
  }

  _Vector3 operator +( _Vector3 other) {
    return _Vector3(
      x + other.x,
      y + other.y,
      z + other.z,
    );
  }

  _Vector3 operator *(double scalar) {
    return _Vector3(
      x * scalar,
      y * scalar,
      z * scalar,
    );
  }
}
