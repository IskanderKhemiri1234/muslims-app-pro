import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muslims_app/features/nearby_mosques/data/config/nearby_mosque_data_source_config.dart';
import 'package:muslims_app/features/nearby_mosques/data/datasources/openstreetmap_overpass_client.dart';

void main() {
  group('OpenStreetMapOverpassClient', () {
    test('sends a POST request and decodes a valid response', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;

        expect(request.method, 'POST');
        expect(request.url.scheme, 'https');
        expect(request.headers['Accept'], 'application/json');
        expect(request.body, contains('place_of_worship'));

        return http.Response(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 33.5,
                'lon': -7.5,
              },
            ],
          }),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      final response = await client.execute(
        '[out:json];node["place_of_worship"="mosque"];out;',
      );

      expect(requestCount, 1);
      expect(response['elements'], isA<List>());
      expect((response['elements'] as List), hasLength(1));

      client.close();
    });

    test('tries the next endpoint after a server error', () async {
      final requestedEndpoints = <String>[];

      final mockClient = MockClient((request) async {
        requestedEndpoints.add(request.url.toString());

        if (requestedEndpoints.length <
            NearbyMosqueDataSourceConfig.endpoints.length) {
          return http.Response('Server unavailable', 503);
        }

        return http.Response(
          jsonEncode({'elements': []}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      final response = await client.execute(
        '[out:json];node["place_of_worship"="mosque"];out;',
      );

      expect(
        requestedEndpoints,
        hasLength(
          NearbyMosqueDataSourceConfig.endpoints.length,
        ),
      );
      expect(
        requestedEndpoints,
        NearbyMosqueDataSourceConfig.endpoints,
      );
      expect(response['elements'], isEmpty);

      client.close();
    });

    test('stops retrying after a non-retryable HTTP error', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('Bad request', 400);
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      await expectLater(
        client.execute('[out:json];out;'),
        throwsA(
          isA<OverpassRequestException>().having(
            (error) => error.statusCode,
            'statusCode',
            400,
          ),
        ),
      );

      expect(requestCount, 1);

      client.close();
    });

    test('tries another endpoint after invalid JSON', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;

        if (requestCount == 1) {
          return http.Response('not valid json', 200);
        }

        return http.Response(
          jsonEncode({'elements': []}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      final response = await client.execute(
        '[out:json];node["place_of_worship"="mosque"];out;',
      );

      expect(requestCount, 2);
      expect(response['elements'], isEmpty);

      client.close();
    });

    test('rejects a JSON response without an elements list', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'version': 0.6}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      await expectLater(
        client.execute('[out:json];out;'),
        throwsA(isA<OverpassRequestException>()),
      );

      client.close();
    });

    test('rejects a JSON array instead of a JSON object', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([]),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      await expectLater(
        client.execute('[out:json];out;'),
        throwsA(isA<OverpassRequestException>()),
      );

      client.close();
    });

    test('rejects an empty query before sending a request', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({'elements': []}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      expect(
        () => client.execute('   '),
        throwsArgumentError,
      );

      expect(requestCount, 0);

      client.close();
    });

    test('rejects execution after the client is closed', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'elements': []}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      client.close();

      expect(
        () => client.execute('[out:json];out;'),
        throwsStateError,
      );
    });

    test('does not close an externally owned HTTP client', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;

        return http.Response(
          jsonEncode({'elements': []}),
          200,
        );
      });

      final client = OpenStreetMapOverpassClient(
        httpClient: mockClient,
      );

      client.close();

      final response = await mockClient.get(
        Uri.parse('https://example.com/health'),
      );

      expect(response.statusCode, 200);
      expect(requestCount, 1);
    });
  });
}
