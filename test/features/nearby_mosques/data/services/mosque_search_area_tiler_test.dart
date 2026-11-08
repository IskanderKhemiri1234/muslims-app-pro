import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/nearby_mosques/data/config/nearby_mosque_data_source_config.dart';
import 'package:muslims_app/features/nearby_mosques/data/services/mosque_search_area_tiler.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_area.dart';

void main() {
  const tiler = MosqueSearchAreaTiler();

  group('MosqueSearchAreaTiler', () {
    test('keeps a small viewport as one tile', () {
      const area = MosqueSearchArea(
        south: 33.55,
        west: -7.65,
        north: 33.60,
        east: -7.55,
      );

      final tiles = tiler.split(area);

      expect(tiles, hasLength(1));
      expect(tiles.single.isValid, isTrue);
      expect(tiles.single.south, area.south);
      expect(tiles.single.west, area.west);
      expect(tiles.single.north, area.north);
      expect(tiles.single.east, area.east);
    });

    test('subdivides a large area into multiple valid tiles', () {
      const area = MosqueSearchArea(
        south: 30,
        west: -10,
        north: 35,
        east: -4,
      );

      final tiles = tiler.split(area);

      expect(tiles.length, greaterThan(1));
      expect(
        tiles.length,
        lessThanOrEqualTo(
          NearbyMosqueDataSourceConfig.maximumTileCount,
        ),
      );

      for (final tile in tiles) {
        expect(tile.isValid, isTrue);
        expect(tile.latitudeSpan, greaterThan(0));
        expect(tile.longitudeSpan, greaterThan(0));
      }
    });

    test('never exceeds the configured maximum tile count', () {
      const world = MosqueSearchArea(
        south: -90,
        west: -180,
        north: 90,
        east: 180,
      );

      final tiles = tiler.split(world);

      expect(tiles, isNotEmpty);
      expect(
        tiles.length,
        lessThanOrEqualTo(
          NearbyMosqueDataSourceConfig.maximumTileCount,
        ),
      );

      for (final tile in tiles) {
        expect(tile.isValid, isTrue);
      }
    });

    test('respects a smaller caller-provided tile limit', () {
      const area = MosqueSearchArea(
        south: 20,
        west: -20,
        north: 40,
        east: 20,
      );

      final tiles = tiler.split(
        area,
        maximumTileCount: 4,
      );

      expect(tiles, isNotEmpty);
      expect(tiles.length, lessThanOrEqualTo(4));
    });

    test('rejects a tile limit below one', () {
      const area = MosqueSearchArea(
        south: 33,
        west: -8,
        north: 34,
        east: -7,
      );

      expect(
        () => tiler.split(
          area,
          maximumTileCount: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a tile limit above the configured maximum', () {
      const area = MosqueSearchArea(
        south: 33,
        west: -8,
        north: 34,
        east: -7,
      );

      expect(
        () => tiler.split(
          area,
          maximumTileCount:
              NearbyMosqueDataSourceConfig.maximumTileCount + 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid geographic areas', () {
      const invalidArea = MosqueSearchArea(
        south: 40,
        west: -8,
        north: 30,
        east: -7,
      );

      expect(
        () => tiler.split(invalidArea),
        throwsArgumentError,
      );
    });

    test('splits an area crossing the international date line', () {
      const area = MosqueSearchArea(
        south: -10,
        west: 170,
        north: 10,
        east: -170,
      );

      final tiles = tiler.split(area);

      expect(tiles, isNotEmpty);

      for (final tile in tiles) {
        expect(tile.isValid, isTrue);

        expect(
          area.contains(
            latitude: tile.centerLatitude,
            longitude: tile.centerLongitude,
          ),
          isTrue,
        );
      }
    });

    test('preserves the complete latitude range after subdivision', () {
      const area = MosqueSearchArea(
        south: 10,
        west: -5,
        north: 15,
        east: 0,
      );

      final tiles = tiler.split(area);

      final lowestSouth = tiles
          .map((tile) => tile.south)
          .reduce((a, b) => a < b ? a : b);

      final highestNorth = tiles
          .map((tile) => tile.north)
          .reduce((a, b) => a > b ? a : b);

      expect(lowestSouth, area.south);
      expect(highestNorth, area.north);
    });

    test('returns an unmodifiable tile list', () {
      const area = MosqueSearchArea(
        south: 33,
        west: -8,
        north: 34,
        east: -7,
      );

      final tiles = tiler.split(area);

      expect(
        () => tiles.add(area),
        throwsUnsupportedError,
      );
    });
  });
}
