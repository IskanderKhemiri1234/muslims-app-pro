import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslims_app/features/nearby_mosques/data/datasources/openstreetmap_overpass_client.dart';
import 'package:muslims_app/features/nearby_mosques/data/services/nearby_mosque_search_service.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_area.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_request.dart';

void main() {
  group('NearbyMosqueSearchService', () {
    const area = MosqueSearchArea(
      south: 33,
      west: -8,
      north: 34,
      east: -7,
    );

    Map<String, dynamic> mosqueElement({
      required int id,
      required String name,
      required double latitude,
      required double longitude,
      String? city,
    }) {
      return {
        'type': 'node',
        'id': id,
        'lat': latitude,
        'lon': longitude,
        'tags': {
          'name': name,
          'place_of_worship': 'mosque',
          if (city != null) 'addr:city': city,
        },
      };
    }

    http.Response successResponse(
      List<Map<String, dynamic>> elements,
    ) {
      return http.Response(
        jsonEncode({'elements': elements}),
        200,
        headers: const {
          'content-type': 'application/json',
        },
      );
    }

    test('returns valid mosques from OpenStreetMap', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.scheme, 'https');
        expect(request.url.path, '/api/interpreter');
        expect(request.body, contains('place_of_worship'));

        return successResponse([
          mosqueElement(
            id: 101,
            name: 'Central Mosque',
            latitude: 33.5,
            longitude: -7.5,
          ),
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(area: area),
      );

      expect(result.mosques, hasLength(1));
      expect(result.mosques.single.id, 'node/101');
      expect(result.mosques.single.name, 'Central Mosque');
      expect(result.searchedTileCount, 1);
      expect(result.failedTileCount, 0);
      expect(result.isComplete, isTrue);
      expect(result.isPartial, isFalse);

      service.close();
    });

    test('removes duplicate mosque records', () async {
      final element = mosqueElement(
        id: 102,
        name: 'Duplicate Mosque',
        latitude: 33.5,
        longitude: -7.5,
      );

      final mockClient = MockClient((request) async {
        return successResponse([
          element,
          element,
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(area: area),
      );

      expect(result.mosques, hasLength(1));
      expect(result.mosques.single.id, 'node/102');

      service.close();
    });

    test('excludes records outside the requested map area', () async {
      final mockClient = MockClient((request) async {
        return successResponse([
          mosqueElement(
            id: 103,
            name: 'Inside Mosque',
            latitude: 33.5,
            longitude: -7.5,
          ),
          mosqueElement(
            id: 104,
            name: 'Outside Mosque',
            latitude: 35,
            longitude: -7.5,
          ),
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(area: area),
      );

      expect(result.mosques, hasLength(1));
      expect(result.mosques.single.name, 'Inside Mosque');

      service.close();
    });

    test('filters results by mosque name without case sensitivity',
        () async {
      final mockClient = MockClient((request) async {
        return successResponse([
          mosqueElement(
            id: 105,
            name: 'Al Noor Mosque',
            latitude: 33.4,
            longitude: -7.4,
          ),
          mosqueElement(
            id: 106,
            name: 'Central Mosque',
            latitude: 33.6,
            longitude: -7.6,
          ),
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(
          area: area,
          query: 'AL NOOR',
          languageCode: 'en',
        ),
      );

      expect(result.mosques, hasLength(1));
      expect(result.mosques.single.name, 'Al Noor Mosque');

      service.close();
    });

    test('filters results using city information', () async {
      final mockClient = MockClient((request) async {
        return successResponse([
          mosqueElement(
            id: 107,
            name: 'Mosque A',
            latitude: 33.4,
            longitude: -7.4,
            city: 'Casablanca',
          ),
          mosqueElement(
            id: 108,
            name: 'Mosque B',
            latitude: 33.6,
            longitude: -7.6,
            city: 'Rabat',
          ),
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(
          area: area,
          query: 'casablanca',
          languageCode: 'en',
        ),
      );

      expect(result.mosques, hasLength(1));
      expect(result.mosques.single.city, 'Casablanca');

      service.close();
    });

    test('respects the requested maximum result count', () async {
      final mockClient = MockClient((request) async {
        return successResponse([
          mosqueElement(
            id: 109,
            name: 'Mosque One',
            latitude: 33.2,
            longitude: -7.2,
          ),
          mosqueElement(
            id: 110,
            name: 'Mosque Two',
            latitude: 33.4,
            longitude: -7.4,
          ),
          mosqueElement(
            id: 111,
            name: 'Mosque Three',
            latitude: 33.6,
            longitude: -7.6,
          ),
        ]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(
          area: area,
          limit: 2,
        ),
      );

      expect(result.mosques, hasLength(2));
      expect(result.resultCount, 2);

      service.close();
    });

    test('reports partial results when some geographic tiles fail',
        () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;

        if (requestCount == 1) {
          return successResponse([
            mosqueElement(
              id: 112,
              name: 'First Tile Mosque',
              latitude: 0.5,
              longitude: 0.5,
            ),
          ]);
        }

        return http.Response(
          'Overpass temporarily unavailable',
          503,
        );
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      final result = await service.search(
        const MosqueSearchRequest(
          area: MosqueSearchArea(
            south: 0,
            west: 0,
            north: 2,
            east: 2,
          ),
        ),
      );

      expect(result.searchedTileCount, 1);
      expect(result.failedTileCount, 3);
      expect(result.isPartial, isTrue);
      expect(result.isComplete, isFalse);
      expect(
        result.mosques.any(
          (mosque) => mosque.id == 'node/112',
        ),
        isTrue,
      );

      service.close();
    });

    test('rejects an invalid search request', () async {
      final mockClient = MockClient((request) async {
        return successResponse([]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      expect(
        () => service.search(
          const MosqueSearchRequest(
            area: MosqueSearchArea(
              south: 40,
              west: -8,
              north: 30,
              east: -7,
            ),
          ),
        ),
        throwsArgumentError,
      );

      service.close();
    });

    test('does not allow searches after the service is closed',
        () async {
      final mockClient = MockClient((request) async {
        return successResponse([]);
      });

      final service = NearbyMosqueSearchService(
        client: OpenStreetMapOverpassClient(
          httpClient: mockClient,
        ),
      );

      service.close();

      expect(
        () => service.search(
          const MosqueSearchRequest(area: area),
        ),
        throwsStateError,
      );
    });
  });
}
