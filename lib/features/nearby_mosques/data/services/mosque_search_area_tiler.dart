
import '../../domain/models/mosque_search_area.dart';
import '../config/nearby_mosque_data_source_config.dart';

/// Mumin Pro — Geographic Search Area Tiler.
///
/// Divides a selected geographic area into smaller non-overlapping
/// rectangular tiles. Supports areas crossing the international
/// date line without producing invalid longitude coordinates.
final class MosqueSearchAreaTiler {
  const MosqueSearchAreaTiler();

  /// Divides [area] into a bounded number of geographic tiles.
  ///
  /// The result never exceeds [maximumTileCount].
  /// Invalid areas are rejected instead of silently corrected.
  List<MosqueSearchArea> split(
    MosqueSearchArea area, {
    int? maximumTileCount,
  }) {
    if (!area.isValid) {
      throw ArgumentError.value(
        area,
        'area',
        'A valid geographic search area is required.',
      );
    }

    final tileLimit = maximumTileCount ??
        NearbyMosqueDataSourceConfig.maximumTileCount;

    if (tileLimit < 1 ||
        tileLimit > NearbyMosqueDataSourceConfig.maximumTileCount) {
      throw ArgumentError.value(
        tileLimit,
        'maximumTileCount',
        'Tile count must be between 1 and '
            '${NearbyMosqueDataSourceConfig.maximumTileCount}.',
      );
    }

    final latitudeSpan = area.latitudeSpan;
    final longitudeSpan = area.longitudeSpan;

    final rows = _calculateRows(
      latitudeSpan,
      longitudeSpan,
      tileLimit,
    );

    final columns = (tileLimit ~/ rows).clamp(1, tileLimit);

    final latitudeStep = latitudeSpan / rows;
    final longitudeStep = longitudeSpan / columns;

    final tiles = <MosqueSearchArea>[];

    for (var row = 0; row < rows; row++) {
      final south = area.south + row * latitudeStep;
      final north = row == rows - 1
          ? area.north
          : area.south + (row + 1) * latitudeStep;

      for (var column = 0; column < columns; column++) {
        final unwrappedWest =
            _unwrappedWest(area) + column * longitudeStep;

        final unwrappedEast = column == columns - 1
            ? _unwrappedWest(area) + longitudeSpan
            : unwrappedWest + longitudeStep;

        final west = _normalizeLongitude(unwrappedWest);
        final east = _normalizeLongitude(unwrappedEast);

        final tile = MosqueSearchArea(
          south: south,
          west: west,
          north: north,
          east: east,
        );

        if (tile.isValid) {
          tiles.add(tile);
        }
      }
    }

    if (tiles.isEmpty || tiles.length > tileLimit) {
      throw StateError(
        'Unable to create a valid geographic tile grid.',
      );
    }

    return List<MosqueSearchArea>.unmodifiable(tiles);
  }

  int _calculateRows(
    double latitudeSpan,
    double longitudeSpan,
    int tileLimit,
  ) {
    final aspectRatio = latitudeSpan / longitudeSpan;

    final estimatedRows =
        (tileLimit * aspectRatio).sqrtRounded();

    return estimatedRows.clamp(1, tileLimit);
  }

  double _unwrappedWest(MosqueSearchArea area) {
    return area.west;
  }

  double _normalizeLongitude(double longitude) {
    var normalized = (longitude + 180) % 360;

    if (normalized < 0) {
      normalized += 360;
    }

    return normalized - 180;
  }
}

extension on double {
  int sqrtRounded() {
    if (!isFinite || this <= 0) return 1;

    var estimate = this;
    var previous = 0.0;

    for (var iteration = 0;
        iteration < 30 && estimate != previous;
        iteration++) {
      previous = estimate;
      estimate = (estimate + this / estimate) / 2;
    }

    return estimate.round().clamp(1, 1000000);
  }
}
