import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/nearby_mosques/data/query_builders/openstreetmap_mosque_query_builder.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_area.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_request.dart';

void main() {
  const builder = OpenStreetMapMosqueQueryBuilder();

  group('OpenStreetMapMosqueQueryBuilder', () {
    test('builds one query for a normal geographic area', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final queries = builder.buildQueries(request);

      expect(queries, hasLength(1));
      expect(queries.single, contains('[out:json]'));
      expect(queries.single, contains('[timeout:'));
      expect(
        queries.single,
        contains('33.0000000,-8.0000000,34.0000000,-7.0000000'),
      );
      expect(queries.single, contains('out center tags;'));
    });

    test('builds two queries for an area crossing the date line', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: -10,
          west: 170,
          north: 10,
          east: -170,
        ),
      );

      final queries = builder.buildQueries(request);

      expect(queries, hasLength(2));

      expect(
        queries[0],
        contains('-10.0000000,170.0000000,10.0000000,180.0000000'),
      );

      expect(
        queries[1],
        contains('-10.0000000,-180.0000000,10.0000000,-170.0000000'),
      );
    });

    test('includes node, way and relation elements', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final query = builder.buildQueries(request).single;

      for (final elementType in const [
        'node',
        'way',
        'relation',
      ]) {
        expect(
          query,
          contains('$elementType["place_of_worship"="mosque"]'),
        );
      }
    });

    test('includes explicitly classified mosques', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final query = builder.buildQueries(request).single;

      expect(
        query,
        contains('"place_of_worship"="mosque"'),
      );
    });

    test('requires Muslim religion for generic worship places', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final query = builder.buildQueries(request).single;

      expect(
        query,
        contains('"amenity"="place_of_worship"'),
      );
      expect(query, contains('"religion"'));
      expect(query, contains('muslim|islam'));
    });

    test('requires Muslim religion for prayer rooms', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final query = builder.buildQueries(request).single;

      expect(
        query,
        contains('"amenity"="prayer_room"'),
      );
      expect(query, contains('muslim|islam'));
    });

    test('requires Muslim religion for musallas', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final query = builder.buildQueries(request).single;

      expect(
        query,
        contains('"amenity"="musalla"'),
      );
      expect(query, contains('muslim|islam'));
    });

    test('rejects invalid search requests', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 40,
          west: -8,
          north: 30,
          east: -7,
        ),
      );

      expect(
        () => builder.buildQueries(request),
        throwsArgumentError,
      );
    });

    test('returns an unmodifiable query list', () {
      const request = MosqueSearchRequest(
        area: MosqueSearchArea(
          south: 33,
          west: -8,
          north: 34,
          east: -7,
        ),
      );

      final queries = builder.buildQueries(request);

      expect(
        () => queries.add('invalid query'),
        throwsUnsupportedError,
      );
    });
  });
}
