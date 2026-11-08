
import 'dart:math' as math;

import '../../domain/models/mosque_search_area.dart';
import '../config/nearby_mosque_data_source_config.dart';

/// Mumin Pro — Geographic Search Area Tiler.
///
/// Divides a selected geographic area into bounded rectangular tiles.
/// Supports areas crossing the international date line.
final class MosqueSearchAreaTiler {
  const MosqueSearchAreaTiler();

  /// Splits [area] into non-overlapping geographic tiles.
  ///
  /// The number of returned tiles never exceeds [maximumTileCount].
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

    final aspectRatio = latitudeSpan / longitudeSpan;

    final rows = math.sqrt(
      tileLimit * aspectRatio,
    ).round().clamp(1, tileLimit);

    final columns = (tileLimit ~/ rows).clamp(1, tileLimit);

    final latitudeStep = latitudeSpan / rows;
    final longitudeStep = longitudeSpan / columns;

    final tiles = <MosqueSearchArea>[];
    final unwrappedWest = area.west;

    for (var row = 0; row < rows; row++) {
      final south = area.south + row * latitudeStep;

      final north = row == rows - 1
          ? area.north
          : area.south + (row + 1) * latitudeStep;

      for (var column = 0; column < columns; column++) {
        final tileWest =
            unwrappedWest + column * longitudeStep;

        final tileEast = column == columns - 1
            ? unwrappedWest + longitudeSpan
            : tileWest + longitudeStep;

        final tile = MosqueSearchArea(
          south: south,
          west: _normalizeLongitude(tileWest),
          north: north,
          east: _normalizeLongitude(tileEast),
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

  /// Preserves exact boundary values of -180 and 180.
  ///
  /// This is important because converting 180 to -180 would
  /// incorrectly turn a small tile into a date-line crossing area.
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
