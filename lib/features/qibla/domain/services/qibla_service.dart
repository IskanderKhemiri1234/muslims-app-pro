
import 'dart:math' as math;

import 'package:geomag/geomag.dart';

/// الحسابات الجغرافية والمغناطيسية الخاصة باتجاه القبلة.
///
/// جميع الزوايا بالدرجات:
/// - الاتجاه الحقيقي: من الشمال الجغرافي.
/// - الانحراف المغناطيسي: موجب شرقاً وسالب غرباً.
/// - التحويل من المغناطيسي إلى الحقيقي: إضافة الانحراف.
class QiblaService {
  QiblaService._();

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
  static const double earthRadiusKm = 6371.0088;

  static const double _degreesToRadians = math.pi / 180.0;
  static const double _radiansToDegrees = 180.0 / math.pi;
  static const double _epsilon = 1e-10;

  /// حساب اتجاه القبلة من الشمال الحقيقي.
  ///
  /// النتيجة بين 0 و360 درجة.
  /// عند الموقع المطابق للكعبة يكون الاتجاه غير معرّف.
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final userLat = latitude * _degreesToRadians;
    final userLon = longitude * _degreesToRadians;
    final targetLat = kaabaLatitude * _degreesToRadians;
    final targetLon = kaabaLongitude * _degreesToRadians;

    final deltaLon = targetLon - userLon;

    final y = math.sin(deltaLon);

    final x = math.cos(userLat) * math.tan(targetLat) -
        math.sin(userLat) * math.cos(deltaLon);

    if (x.abs() < _epsilon && y.abs() < _epsilon) {
      throw StateError(
        'اتجاه القبلة غير معرّف عند موقع الكعبة نفسها.',
      );
    }

    final bearing = math.atan2(y, x) * _radiansToDegrees;

    return normalize(bearing);
  }

  /// حساب المسافة إلى الكعبة بالكيلومترات باستخدام Haversine.
  static double calculateDistanceKm({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final lat1 = latitude * _degreesToRadians;
    final lat2 = kaabaLatitude * _degreesToRadians;

    final deltaLat = (kaabaLatitude - latitude) *
        _degreesToRadians;

    final deltaLon = (kaabaLongitude - longitude) *
        _degreesToRadians;

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

  /// حساب الانحراف المغناطيسي بالدرجات.
  ///
  /// الإشارة الموجبة تعني الشرق والسالبة تعني الغرب.
  static double calculateMagneticDeclination({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    _validateCoordinates(latitude, longitude);

    final calculationDate = date ?? DateTime.now();

    final result = GeoMag().calculate(
      latitude,
      longitude,
      0,
      calculationDate,
    );

    final declination = result.dec.toDouble();

    if (!declination.isFinite || declination.abs() > 180) {
      throw StateError(
        'تعذر حساب الانحراف المغناطيسي بصورة صحيحة.',
      );
    }

    return declination;
  }

  /// تحويل قراءة البوصلة المغناطيسية إلى اتجاه حقيقي.
  ///
  /// True heading = Magnetic heading + Declination
  static double magneticToTrueHeading({
    required double magneticHeading,
    required double declination,
  }) {
    _validateFinite(magneticHeading, 'magneticHeading');
    _validateFinite(declination, 'declination');

    return normalize(magneticHeading + declination);
  }

  /// أقصر فرق زاوي موقّع بين الهدف والاتجاه الحالي.
  ///
  /// النتيجة بين -180 و+180 درجة.
  /// الموجب يعني الدوران باتجاه عقارب الساعة.
  static double shortestAngleDifference(
    double target,
    double current,
  ) {
    _validateFinite(target, 'target');
    _validateFinite(current, 'current');

    return normalizeSigned(target - current);
  }

  /// توحيد الزاوية بين 0 و360 درجة.
  static double normalize(double degrees) {
    _validateFinite(degrees, 'degrees');

    final normalized = degrees % 360.0;

    return normalized < 0
        ? normalized + 360.0
        : normalized;
  }

  /// توحيد الزاوية بين -180 و+180 درجة.
  static double normalizeSigned(double degrees) {
    final normalized = normalize(degrees + 180.0) - 180.0;

    return normalized == -180.0 ? 180.0 : normalized;
  }

  /// إنشاء نقاط مسار كروي بين نقطتين جغرافيتين.
  ///
  /// مناسب لرسم المسار على FlutterMap.
  /// لا يحتاج إلى اتصال بالإنترنت.
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

    final points = <GeoPoint>[];

    late final _Vector3 perpendicular;

    // المسار عند النقطتين المتقابلتين تماماً غير وحيد.
    // نختار مستوىً كروياً حتمياً لتجنب القسمة على صفر.
    if ((math.pi - omega).abs() < _epsilon) {
      perpendicular = _perpendicularUnitVector(start);
    } else {
      perpendicular = const _Vector3(0, 0, 0);
    }

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;

      late final _Vector3 point;

      if (omega < _epsilon) {
        point = start;
      } else if ((math.pi - omega).abs() < _epsilon) {
        final angle = math.pi * t;

        point = (
          start * math.cos(angle) +
          perpendicular * math.sin(angle)
        ).normalized();
      } else {
        final sinOmega = math.sin(omega);

        final startWeight =
            math.sin((1 - t) * omega) / sinOmega;

        final endWeight =
            math.sin(t * omega) / sinOmega;

        point = (
          start * startWeight +
          end * endWeight
        ).normalized();
      }

      points.add(point.toGeoPoint());
    }

    return points;
  }

  /// إنشاء متجه وحدة عمودي بصورة حتمية على المتجه المعطى.
  static _Vector3 _perpendicularUnitVector(_Vector3 vector) {
    final reference = vector.x.abs() <= vector.y.abs() &&
            vector.x.abs() <= vector.z.abs()
        ? const _Vector3(1, 0, 0)
        : vector.y.abs() <= vector.z.abs()
            ? const _Vector3(0, 1, 0)
            : const _Vector3(0, 0, 1);

    return vector.cross(reference).normalized();
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
      throw ArgumentError.value(
        value,
        name,
        'يجب أن تكون قيمة رقمية صالحة.',
      );
    }
  }
}

/// نقطة جغرافية لرسم المسار.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });
}

/// متجه ثلاثي الأبعاد للحسابات الكروية.
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

  _Vector3 cross(_Vector3 other) {
    return _Vector3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  double get magnitude {
    return math.sqrt(x * x + y * y + z * z);
  }

  _Vector3 normalized() {
    final length = magnitude;

    if (!length.isFinite ||
        length < QiblaService._epsilon) {
      throw StateError(
        'تعذر تطبيع متجه المسار الجغرافي.',
      );
    }

    return _Vector3(
      x / length,
      y / length,
      z / length,
    );
  }

  GeoPoint toGeoPoint() {
    final vector = normalized();

    final latitude = math.atan2(
      vector.z,
      math.sqrt(
        vector.x * vector.x +
        vector.y * vector.y,
      ),
    );

    final longitude = math.atan2(
      vector.y,
      vector.x,
    );

    return GeoPoint(
      latitude: latitude *
          QiblaService._radiansToDegrees,
      longitude: longitude *
          QiblaService._radiansToDegrees,
    );
  }

  _Vector3 operator +(_Vector3 other) {
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
