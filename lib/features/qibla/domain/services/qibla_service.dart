
import 'dart:math' as math;

import 'package:geomag/geomag.dart';

/// محرك الحسابات الجغرافية للقبلة.
///
/// يعتمد حساب الاتجاه والمسافة والمسار على إحداثيات WGS84
/// والهندسة الكروية، ولا يحتاج إلى الإنترنت أو مستشعر البوصلة.
///
/// ملاحظة:
/// الانحراف المغناطيسي محفوظ مؤقتاً للتوافق مع الصفحة القديمة،
/// لكنه ليس جزءاً من حساب اتجاه القبلة الأساسي.
class QiblaService {
  QiblaService._();

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  /// متوسط نصف قطر الأرض وفق نموذج IUGG بالكيلومترات.
  static const double earthRadiusKm = 6371.0088;

  static const double _degreesToRadians = math.pi / 180.0;
  static const double _radiansToDegrees = 180.0 / math.pi;

  /// سماحية حسابية للعمليات ذات القيم الصغيرة جداً.
  static const double _epsilon = 1e-12;

  /// حد معالجة المسارات القريبة جداً من التقابل.
  static const double _antipodalTolerance = 1e-7;

  /// حساب الاتجاه الابتدائي من الشمال الجغرافي إلى الكعبة.
  ///
  /// النتيجة:
  /// 0°   = شمال
  /// 90°  = شرق
  /// 180° = جنوب
  /// 270° = غرب
  ///
  /// لا يعتمد على البوصلة أو الانحراف المغناطيسي.
  ///
  /// إذا كان الموقع مطابقاً للكعبة أو مقابلاً لها تماماً،
  /// يكون اتجاه أقصر مسار غير معرّف بصورة وحيدة.
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final userLat = latitude * _degreesToRadians;
    final targetLat = kaabaLatitude * _degreesToRadians;

    final deltaLon =
        _normalizeRadians(
          (kaabaLongitude - longitude) * _degreesToRadians,
        );

    final y = math.sin(deltaLon) * math.cos(targetLat);

    final x =
        math.cos(userLat) * math.sin(targetLat) -
        math.sin(userLat) *
            math.cos(targetLat) *
            math.cos(deltaLon);

    // عندما يكون المتجه الأفقي شبه صفري، لا يمكن تحديد
    // اتجاه ابتدائي مستقر بصورة وحيدة.
    if (math.sqrt(x * x + y * y) <= _epsilon) {
      throw StateError(
        'اتجاه أقصر مسار إلى الكعبة غير معرّف عند هذه الإحداثيات.',
      );
    }

    final bearing = math.atan2(y, x) * _radiansToDegrees;

    return normalize(bearing);
  }

  /// حساب المسافة الجغرافية إلى الكعبة بالكيلومترات.
  ///
  /// يستخدم معادلة Haversine مع حماية عددية.
  /// المسافة هي مسافة سطحية كروية وليست مسافة طرق.
  static double calculateDistanceKm({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final lat1 = latitude * _degreesToRadians;
    final lat2 = kaabaLatitude * _degreesToRadians;

    final deltaLat =
        (kaabaLatitude - latitude) * _degreesToRadians;

    final deltaLon =
        _normalizeRadians(
          (kaabaLongitude - longitude) * _degreesToRadians,
        );

    final sinLat = math.sin(deltaLat / 2.0);
    final sinLon = math.sin(deltaLon / 2.0);

    final a =
        sinLat * sinLat +
        math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;

    final safeA = a.clamp(0.0, 1.0).toDouble();

    final centralAngle = 2.0 * math.atan2(
      math.sqrt(safeA),
      math.sqrt(math.max(0.0, 1.0 - safeA)),
    );

    return earthRadiusKm * centralAngle;
  }

  /// حساب الانحراف المغناطيسي.
  ///
  /// للتوافق مع الكود القديم فقط.
  ///
  /// لا تستخدم هذه الدالة لحساب اتجاه القبلة الجغرافي.
  /// كما أن دقتها مرتبطة بنموذج geomag وتاريخ صلاحيته.
  @Deprecated(
    'اتجاه القبلة الجديد جغرافي ولا يحتاج إلى الانحراف المغناطيسي.',
  )
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

    if (!declination.isFinite || declination.abs() > 180.0) {
      throw StateError(
        'تعذر حساب الانحراف المغناطيسي بصورة صحيحة.',
      );
    }

    return declination;
  }

  /// تحويل الاتجاه المغناطيسي إلى اتجاه جغرافي حقيقي.
  ///
  /// للتوافق مع الصفحة القديمة فقط.
  @Deprecated(
    'لا تستخدم هذه الدالة في نظام Qibla Atlas المستقل عن البوصلة.',
  )
  static double magneticToTrueHeading({
    required double magneticHeading,
    required double declination,
  }) {
    _validateFinite(magneticHeading, 'magneticHeading');
    _validateFinite(declination, 'declination');

    return normalize(magneticHeading + declination);
  }

  /// أقصر فرق زاوي موقّع بين الاتجاه المستهدف والاتجاه الحالي.
  ///
  /// النتيجة من -180 إلى +180 درجة.
  /// الموجب: باتجاه عقارب الساعة.
  /// السالب: عكس اتجاه عقارب الساعة.
  static double shortestAngleDifference(
    double target,
    double current,
  ) {
    _validateFinite(target, 'target');
    _validateFinite(current, 'current');

    return normalizeSigned(target - current);
  }

  /// توحيد الزاوية إلى المجال [0, 360).
  static double normalize(double degrees) {
    _validateFinite(degrees, 'degrees');

    final normalized = degrees % 360.0;

    return normalized < 0.0
        ? normalized + 360.0
        : normalized;
  }

  /// توحيد الزاوية إلى المجال (-180, 180].
  static double normalizeSigned(double degrees) {
    final normalized = normalize(degrees + 180.0) - 180.0;

    return normalized <= -180.0
        ? 180.0
        : normalized;
  }

  /// إنشاء مسار عظيم الدائرة بين نقطتين.
  ///
  /// يعمل محلياً دون إنترنت.
  ///
  /// segments:
  /// عدد المقاطع بين نقطتي البداية والنهاية.
  ///
  /// النتيجة تحتوي على segments + 1 نقطة.
  static List<GeoPoint> greatCircleRoute({
    required double startLatitude,
    required double startLongitude,
    double endLatitude = kaabaLatitude,
    double endLongitude = kaabaLongitude,
    int segments = 128,
  }) {
    _validateCoordinates(startLatitude, startLongitude);
    _validateCoordinates(endLatitude, endLongitude);

    if (segments < 1 || segments > 2048) {
      throw ArgumentError.value(
        segments,
        'segments',
        'يجب أن يكون عدد المقاطع بين 1 و2048.',
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

    final dot = start.dot(end).clamp(-1.0, 1.0).toDouble();

    final crossMagnitude = start.cross(end).magnitude;

    // atan2 أكثر استقراراً من acos وحدها قرب 0 و180 درجة.
    final omega = math.atan2(crossMagnitude, dot);

    final points = <GeoPoint>[];

    if (omega <= _epsilon) {
      return List<GeoPoint>.unmodifiable(
        List<GeoPoint>.filled(
          segments + 1,
          GeoPoint(
            latitude: startLatitude,
            longitude: startLongitude,
          ),
        ),
      );
    }

    final isNearlyAntipodal =
        (math.pi - omega).abs() <= _antipodalTolerance;

    final perpendicular = isNearlyAntipodal
        ? _perpendicularUnitVector(start)
        : null;

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;

      // نحافظ على الإحداثيات الأصلية عند الطرفين
      // لتجنب أي خطأ تقريب عددي في أول وآخر نقطة.
      if (i == 0) {
        points.add(
          GeoPoint(
            latitude: startLatitude,
            longitude: startLongitude,
          ),
        );
        continue;
      }

      if (i == segments) {
        points.add(
          GeoPoint(
            latitude: endLatitude,
            longitude: endLongitude,
          ),
        );
        continue;
      }

      late final _Vector3 interpolated;

      if (isNearlyAntipodal) {
        // عند تقابل النقطتين تقريباً توجد مسارات كبرى متعددة.
        // نختار مستوى مسار حتمياً لتجنب عدم الاستقرار العددي.
        final angle = math.pi * t;

        interpolated = (
          start * math.cos(angle) +
          perpendicular! * math.sin(angle)
        ).normalized();
      } else {
        interpolated = _slerp(
          start,
          end,
          t,
          omega,
        );
      }

      points.add(interpolated.toGeoPoint());
    }

    return List<GeoPoint>.unmodifiable(points);
  }

  /// تقسيم المسار عند خط التاريخ الدولي ±180°.
  ///
  /// مهم جداً عند رسم المسارات على الخرائط:
  /// بعض محركات الخرائط ترسم خطاً طويلاً عبر العالم
  /// إذا انتقل خط الطول مباشرة من +179 إلى -179.
  ///
  /// النتيجة قائمة من أجزاء مستقلة، بحيث ينتهي الجزء
  /// عند أحد جانبي خط التاريخ ويبدأ الجزء التالي عند الجانب الآخر.
  static List<List<GeoPoint>> splitRouteAtAntimeridian(
    List<GeoPoint> route,
  ) {
    if (route.isEmpty) {
      return const [];
    }

    if (route.length == 1) {
      return [
        List<GeoPoint>.unmodifiable(route),
      ];
    }

    final parts = <List<GeoPoint>>[];
    var currentPart = <GeoPoint>[route.first];

    for (var i = 1; i < route.length; i++) {
      final previous = route[i - 1];
      final current = route[i];

      final longitudeDifference =
          current.longitude - previous.longitude;

      if (longitudeDifference.abs() <= 180.0) {
        currentPart.add(current);
        continue;
      }

      // نفك التفاف خط الطول لاختيار نقطة العبور الصحيحة.
      final unwrappedCurrentLongitude =
          longitudeDifference > 180.0
              ? current.longitude - 360.0
              : current.longitude + 360.0;

      final boundaryLongitude =
          previous.longitude >= 0.0 ? 180.0 : -180.0;

      final t =
          (boundaryLongitude - previous.longitude) /
          (unwrappedCurrentLongitude - previous.longitude);

      final crossingLatitude = previous.latitude +
          (current.latitude - previous.latitude) * t;

      final firstBoundaryPoint = GeoPoint(
        latitude: crossingLatitude,
        longitude: boundaryLongitude,
      );

      final oppositeBoundaryPoint = GeoPoint(
        latitude: crossingLatitude,
        longitude: -boundaryLongitude,
      );

      currentPart.add(firstBoundaryPoint);

      if (currentPart.length >= 2) {
        parts.add(List<GeoPoint>.unmodifiable(currentPart));
      }

      currentPart = <GeoPoint>[
        oppositeBoundaryPoint,
        current,
      ];
    }

    if (currentPart.length >= 2) {
      parts.add(List<GeoPoint>.unmodifiable(currentPart));
    } else if (parts.isEmpty) {
      parts.add(List<GeoPoint>.unmodifiable(currentPart));
    }

    return List<List<GeoPoint>>.unmodifiable(parts);
  }

  /// استيفاء كروي بين متجهين بوحدة الزمن t.
  static _Vector3 _slerp(
    _Vector3 start,
    _Vector3 end,
    double t,
    double omega,
  ) {
    final sinOmega = math.sin(omega);

    if (sinOmega.abs() <= _epsilon) {
      return start;
    }

    final startWeight =
        math.sin((1.0 - t) * omega) / sinOmega;

    final endWeight =
        math.sin(t * omega) / sinOmega;

    return (
      start * startWeight +
      end * endWeight
    ).normalized();
  }

  /// إنشاء متجه وحدة عمودي حتمي على المتجه المدخل.
  static _Vector3 _perpendicularUnitVector(
    _Vector3 vector,
  ) {
    final reference = vector.x.abs() <= vector.y.abs() &&
            vector.x.abs() <= vector.z.abs()
        ? const _Vector3(1, 0, 0)
        : vector.y.abs() <= vector.z.abs()
            ? const _Vector3(0, 1, 0)
            : const _Vector3(0, 0, 1);

    return vector.cross(reference).normalized();
  }

  /// تطبيع فرق خط الطول إلى المجال [-π, π].
  static double _normalizeRadians(double radians) {
    final twoPi = 2.0 * math.pi;

    var normalized = radians % twoPi;

    if (normalized > math.pi) {
      normalized -= twoPi;
    } else if (normalized < -math.pi) {
      normalized += twoPi;
    }

    return normalized;
  }

  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90.0 ||
        latitude > 90.0 ||
        longitude < -180.0 ||
        longitude > 180.0) {
      throw ArgumentError(
        'إحداثيات الموقع غير صحيحة: '
        'latitude=$latitude, longitude=$longitude',
      );
    }
  }

  static void _validateFinite(
    double value,
    String name,
  ) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        name,
        'يجب أن تكون قيمة رقمية صالحة.',
      );
    }
  }
}

/// نقطة جغرافية وفق نظام WGS84.
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// متجه ثلاثي الأبعاد للحسابات الكروية.
class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  factory _Vector3.fromCoordinates(
    double latitude,
    double longitude,
  ) {
    final lat =
        latitude * QiblaService._degreesToRadians;

    final lon =
        longitude * QiblaService._degreesToRadians;

    final cosLat = math.cos(lat);

    return _Vector3(
      cosLat * math.cos(lon),
      cosLat * math.sin(lon),
      math.sin(lat),
    );
  }

  double dot(_Vector3 other) {
    return x * other.x +
        y * other.y +
        z * other.z;
  }

  _Vector3 cross(_Vector3 other) {
    return _Vector3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  double get magnitude {
    return math.sqrt(
      x * x + y * y + z * z,
    );
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
      latitude:
          latitude * QiblaService._radiansToDegrees,
      longitude:
          longitude * QiblaService._radiansToDegrees,
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
