
import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_area.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_request.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_result.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/nearby_mosque.dart';

void main() {
  group('NearbyMosque', () {
    test('parses a valid named mosque from an OSM node', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'node',
        'id': 12345,
        'lat': 33.5731,
        'lon': -7.5898,
        'tags': {
          'name': 'Central Mosque',
          'name:ar': 'المسجد المركزي',
          'name:fr': 'Mosquée centrale',
          'place_of_worship': 'mosque',
          'addr:city': 'Casablanca',
          'addr:country': 'MA',
        },
      });

      expect(mosque, isNotNull);
      expect(mosque!.id, 'node/12345');
      expect(mosque.name, 'Central Mosque');
      expect(mosque.nameForLanguage('ar'), 'المسجد المركزي');
      expect(mosque.nameForLanguage('fr'), 'Mosquée centrale');
      expect(mosque.city, 'Casablanca');
      expect(mosque.countryCode, 'MA');
      expect(mosque.placeType, MosquePlaceType.mosque);
      expect(mosque.isValid, isTrue);
    });

    test('accepts an unnamed mosque without inventing a name', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'node',
        'id': 12346,
        'lat': 33.6,
        'lon': -7.6,
        'tags': {
          'place_of_worship': 'mosque',
        },
      });

      expect(mosque, isNotNull);
      expect(mosque!.name, isEmpty);
      expect(mosque.nameForLanguage('ar'), isEmpty);
      expect(mosque.isValid, isTrue);
    });

    test('parses way coordinates from the center field', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'way',
        'id': 900,
        'center': {
          'lat': 34.0209,
          'lon': -6.8416,
        },
        'tags': {
          'name': 'Test Mosque',
          'place_of_worship': 'mosque',
        },
      });

      expect(mosque, isNotNull);
      expect(mosque!.latitude, 34.0209);
      expect(mosque.longitude, -6.8416);
    });

    test('rejects non-mosque places of worship', () {
      final place = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'node',
        'id': 77,
        'lat': 33.5,
        'lon': -7.5,
        'tags': {
          'amenity': 'place_of_worship',
          'religion': 'christian',
        },
      });

      expect(place, isNull);
    });

    test('rejects invalid coordinates', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'node',
        'id': 88,
        'lat': 120,
        'lon': -7.5,
        'tags': {
          'place_of_worship': 'mosque',
        },
      });

      expect(mosque, isNull);
    });

    test('rejects unsupported OSM element types', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'area',
        'id': 99,
        'lat': 33.5,
        'lon': -7.5,
        'tags': {
          'place_of_worship': 'mosque',
        },
      });

      expect(mosque, isNull);
    });

    test('rejects conflicting non-Muslim religion tags', () {
      final mosque = NearbyMosque.tryFromOpenStreetMapElement({
        'type': 'node',
        'id': 100,
        'lat': 33.5,
        'lon': -7.5,
        'tags': {
          'place_of_worship': 'mosque',
          'religion': 'christian',
        },
      });

      expect(mosque, isNull);
    });
  });

  group('MosqueSearchArea', () {
    test('validates and contains coordinates inside normal bounds', () {
      const area = MosqueSearchArea(
        south: 33,
        west: -8,
        north: 34,
        east: -7,
      );

      expect(area.isValid, isTrue);
      expect(
        area.contains(latitude: 33.5, longitude: -7.5),
        isTrue,
      );
      expect(
        area.contains(latitude: 35, longitude: -7.5),
        isFalse,
      );
    });

    test('supports areas crossing the international date line', () {
      const area = MosqueSearchArea(
        south: -10,
        west: 170,
        north: 10,
        east: -170,
      );

      expect(area.isValid, isTrue);
      expect(area.crossesDateLine, isTrue);
      expect(
        area.contains(latitude: 0, longitude: 175),
        isTrue,
      );
      expect(
        area.contains(latitude: 0, longitude: -175),
        isTrue,
      );
      expect(
        area.contains(latitude: 0, longitude: 0),
        isFalse,
      );
    });

    test('rejects invalid geographic boundaries', () {
      const area = MosqueSearchArea(
        south: 40,
        west: -8,
        north: 30,
        east: -7,
      );

      expect(area.isValid, isFalse);
      expect(
        area.contains(latitude: 35, longitude: -7.5),
        isFalse,
      );
    });
  });

  group('MosqueSearchRequest', () {
    test('normalizes language codes with region suffixes', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        languageCode: 'fr-FR',
      );

      expect(request.normalizedLanguageCode, 'fr');
      expect(request.isValid, isTrue);
    });

    test('normalizes empty search queries to null', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        query: '   ',
      );

      expect(request.normalizedQuery, isNull);
    });

    test('rejects limits outside the supported range', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        limit: 501,
      );

      expect(request.isValid, isFalse);
    });
  });

  group('MosqueSearchResult', () {
    test('removes duplicate mosque IDs', () {
      const mosque = NearbyMosque(
        id: 'node/1',
        name: 'Mosque',
        latitude: 33.5,
        longitude: -7.5,
        placeType: MosquePlaceType.mosque,
        source: 'openstreetmap',
      );

      final result = MosqueSearchResult(
        requestedArea: const MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        mosques: [mosque, mosque],
        searchedTileCount: 1,
      );

      expect(result.mosques, hasLength(1));
      expect(result.resultCount, 1);
      expect(result.isComplete, isTrue);
      expect(result.isPartial, isFalse);
    });

    test('reports partial results when a tile failed', () {
      final result = MosqueSearchResult(
        requestedArea: const MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        mosques: const [],
        searchedTileCount: 2,
        failedTileCount: 1,
      );

      expect(result.isPartial, isTrue);
      expect(result.isComplete, isFalse);
    });

    test('exposes an unmodifiable mosque list', () {
      final result = MosqueSearchResult(
        requestedArea: const MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
        mosques: const [],
      );

      expect(
        () => result.mosques.add(
          const NearbyMosque(
            id: 'node/2',
            name: 'Another Mosque',
            latitude: 33.5,
            longitude: -7.5,
            placeType: MosquePlaceType.mosque,
            source: 'openstreetmap',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
