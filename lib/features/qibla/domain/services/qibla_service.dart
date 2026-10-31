
import 'dart:math' as math;

import 'package:geomag/geomag.dart';

class QiblaService {
  QiblaService._();

  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  static const double earthRadiusKm = 6371.0088;

  /// Returns the initial great-circle bearing from the user to the Kaaba.
  /// Result is normalized to [0, 360).
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLongitude =
        _toRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLongitude) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) *
            math.cos(lat2) *
            math.cos(deltaLongitude);

    return _normalizeDegrees(
      _toDegrees(math.atan2(y, x)),
    );
  }

  /// Great-circle distance from the current position to the Kaaba.
  static double calculateDistanceKm({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude, longitude);

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLat = lat2 - lat1;
    final deltaLon =
        _toRadians(kaabaLongitude - longitude);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);

    final c = 2 * math.atan2(
      math.sqrt(a),
      math.sqrt(math.max(0.0, 1.0 - a)),
    );

    return earthRadiusKm * c;
  }

  /// WMM2025 magnetic declination in degrees.
  /// East is positive; west is negative.
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

    final declination = result.dec;

    if (!declination.isFinite) {
      throw StateError('Invalid magnetic declination.');
    }

    return declination;
  }

  /// Converts magnetic sensor heading into true-north heading.
  static double magneticToTrueHeading({
    required double magneticHeading,
    required double declination,
  }) {
    if (!magneticHeading.isFinite ||
        !declination.isFinite) {
      throw ArgumentError('Heading values must be finite.');
    }

    return _normalizeDegrees(
      magneticHeading + declination,
    );
  }

  /// Smallest signed angular difference in [-180, 180].
  static double shortestAngleDifference(
    double target,
    double current,
  ) {
    return _normalizeSignedDegrees(target - current);
  }

  /// Generates points along the great-circle route.
  /// Useful for drawing the direct route on the map.
  static List<GeoPoint> greatCircleRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    int segments = 64,
  }) {
    _validateCoordinates(startLatitude, startLongitude);
    _validateCoordinates(endLatitude, endLongitude);

    if (segments < 2 || segments > 512) {
      throw ArgumentError.value(
        segments,
        'segments',
        'Must be between 2 and 512.',
      );
    }

    final start = _toVector(startLatitude, startLongitude);
    final end = _toVector(endLatitude, endLongitude);

    final dot = (start.x * end.x +
            start.y * end.y +
            start.z * end.z)
        .clamp(-1.0, 1.0);

    final omega = math.acos(dot);
    final sinOmega = math.sin(omega);

    final points = <GeoPoint>[];

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;

      double x;
      double y;
      double z;

      if (omega < 1e-10) {
        x = start.x;
        y = start.y;
        z = start.z;
      } else if (sinOmega.abs() < 1e-10) {
        // Nearly antipodal points: use normalized linear interpolation.
        x = start.x * (1 - t) + end.x * t;
        y = start.y * (1 - t) + end.y * t;
        z = start.z * (1 - t) + end.z * t;

        final length = math.sqrt(x * x + y * y + z * z);
        if (length < 1e-12) {
          continue;
        }

        x /= length;
        y /= length;
        z /= length;
      } else {
        final a = math.sin((1 - t) * omega) / sinOmega;
        final b = math.sin(t * omega) / sinOmega;

        x = a * start.x + b * end.x;
        y = a * start.y + b * end.y;
        z = a * start.z + b * end.z;
      }

      final latitude = _toDegrees(
        math.atan2(z, math.sqrt(x * x + y * y)),
      );

      final longitude = _toDegrees(math.atan2(y, x));

      points.add(GeoPoint(latitude, longitude));
    }

    return points;
  }

  static void _validateCoordinates(
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Coordinates must be finite.');
    }

    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }

    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
  }

  static _Vector3 _toVector(double latitude, double longitude) {
    final lat = _toRadians(latitude);
    final lon = _toRadians(longitude);

    return _Vector3(
      math.cos(lat) * math.cos(lon),
      math.cos(lat) * math.sin(lon),
      math.sin(lat),
    );
  }

  static double _normalizeDegrees(double value) =>
      (value % 360 + 360) % 360;

  static double _normalizeSignedDegrees(double value) {
    final normalized = _normalizeDegrees(value);
    return normalized > 180 ? normalized - 360 : normalized;
  }

  static double _toRadians(double degrees) =>
      degrees * math.pi / 180;

  static double _toDegrees(double radians) =>
      radians * 180 / math.pi;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}
