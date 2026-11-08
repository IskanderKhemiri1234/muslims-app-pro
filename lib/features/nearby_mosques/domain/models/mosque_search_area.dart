
/// Mumin Pro — Worldwide Mosque Search Area.
///
/// Represents a geographic rectangle used to discover mosques
/// inside the currently visible map area.
///
/// This model is independent of Flutter, GPS and network services.
final class MosqueSearchArea {
  const MosqueSearchArea({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  /// Southern latitude boundary.
  final double south;

  /// Western longitude boundary.
  ///
  /// May be greater than [east] when the area crosses
  /// the international date line.
  final double west;

  /// Northern latitude boundary.
  final double north;

  /// Eastern longitude boundary.
  final double east;

  /// Whether the geographic boundaries are valid.
  bool get isValid =>
      south.isFinite &&
      north.isFinite &&
      west.isFinite &&
      east.isFinite &&
      south >= -90 &&
      north <= 90 &&
      south < north &&
      west >= -180 &&
      west <= 180 &&
      east >= -180 &&
      east <= 180 &&
      west != east;

  /// Whether this search area crosses the international date line.
  bool get crossesDateLine => west > east;

  /// Whether a geographic coordinate is inside this area.
  bool contains({
    required double latitude,
    required double longitude,
  }) {
    if (!isValid ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return false;
    }

    final insideLatitude =
        latitude >= south && latitude <= north;

    final insideLongitude = crossesDateLine
        ? longitude >= west || longitude <= east
        : longitude >= west && longitude <= east;

    return insideLatitude && insideLongitude;
  }

  /// Approximate center latitude.
  double get centerLatitude => (south + north) / 2;

  /// Center longitude, accounting for the date line.
  double get centerLongitude {
    if (!crossesDateLine) {
      return (west + east) / 2;
    }

    final adjustedEast = east + 360;
    final midpoint = (west + adjustedEast) / 2;

    return midpoint > 180 ? midpoint - 360 : midpoint;
  }

  /// Approximate area dimensions in degrees.
  double get latitudeSpan => north - south;

  double get longitudeSpan {
    if (!crossesDateLine) {
      return east - west;
    }

    return (180 - west) + (east + 180);
  }

  /// Creates a copy with selected boundaries changed.
  MosqueSearchArea copyWith({
    double? south,
    double? west,
    double? north,
    double? east,
  }) {
    return MosqueSearchArea(
      south: south ?? this.south,
      west: west ?? this.west,
      north: north ?? this.north,
      east: east ?? this.east,
    );
  }

  @override
  String toString() {
    return 'MosqueSearchArea('
        'south: $south, '
        'west: $west, '
        'north: $north, '
        'east: $east'
        ')';
  }
}
