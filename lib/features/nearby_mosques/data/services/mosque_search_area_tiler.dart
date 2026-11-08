
import 'dart:math' as math;

import '../../domain/models/mosque_search_area.dart';
import '../config/nearby_mosque_data_source_config.dart';

/// Mumin Pro — Geographic Search Area Tiler.
///
/// Keeps small map areas as a single tile and subdivides larger
/// areas into bounded geographic rectangles.
final class MosqueSearchAreaTiler {
  const MosqueSearchAreaTiler();

  /// Approximate maximum tile width and height in degrees.
  ///
  /// A viewport smaller than this threshold is not subdivided.
  static const double maximumTileSpanDegrees = 1.0;

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
        tileLimit >
            NearbyMosqueDataSourceConfig.maximumTileCount) {
      throw ArgumentError.value(
        tileLimit,
        'maximumTileCount',
        'Tile count must be between 1 and '
            '${NearbyMosqueDataSourceConfig.maximumTileCount}.',
      );
    }

    final latitudeSpan = area.latitudeSpan;
    final longitudeSpan = area.longitudeSpan;

    if (latitudeSpan <= 0 || longitudeSpan <= 0) {
      throw ArgumentError(
        'The geographic area must have positive dimensions.',
      );
    }

    var rows = math.max(
      1,
      (latitudeSpan / maximumTileSpanDegrees).ceil(),
    );

    var columns = math.max(
      1,
      (longitudeSpan / maximumTileSpanDegrees).ceil(),
    );

    // Reduce the grid while preserving a reasonable aspect ratio.
    while (rows * columns > tileLimit) {
      if (rows >= columns && rows > 1) {
        rows--;
      } else if (columns > 1) {
        columns--;
      } else {
        break;
      }
    }

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
            area.west + column * longitudeStep;

        final unwrappedEast = column == columns - 1
            ? area.west + longitudeSpan
            : unwrappedWest + longitudeStep;

        final tile = MosqueSearchArea(
          south: south,
          west: _normalizeLongitude(unwrappedWest),
          north: north,
          east: _normalizeLongitude(unwrappedEast),
        );

        if (!tile.isValid) {
          throw StateError(
            'The generated geographic tile is invalid.',
          );
        }

        tiles.add(tile);
      }
    }

    if (tiles.isEmpty || tiles.length > tileLimit) {
      throw StateError(
        'Unable to create a valid geographic tile grid.',
      );
    }

    return List<MosqueSearchArea>.unmodifiable(tiles);
  }

  /// Keeps exact -180 and 180 boundaries unchanged.
  double _normalizeLongitude(double longitude) {
    if (longitude >= -180 && longitude <= 180) {
      return longitude;
    }

    var normalized = (longitude + 180) % 360;

    if (normalized < 0) {
      normalized += 360;
    }

    return normalized - 180;
  }
}
