
import '../../domain/models/mosque_search_request.dart';
import '../../domain/models/mosque_search_result.dart';
import '../../domain/models/nearby_mosque.dart';
import '../../domain/repositories/nearby_mosque_repository.dart';
import '../datasources/openstreetmap_mosque_response_parser.dart';
import '../datasources/openstreetmap_overpass_client.dart';
import '../query_builders/openstreetmap_mosque_query_builder.dart';
import 'mosque_search_area_tiler.dart';

/// Mumin Pro — Worldwide Nearby Mosque Search Service.
///
/// Connects geographic tiling, Overpass queries, HTTP transport,
/// response parsing and result aggregation.
final class NearbyMosqueSearchService
    implements NearbyMosqueRepository {
  NearbyMosqueSearchService({
    OpenStreetMapOverpassClient? client,
    MosqueSearchAreaTiler tiler = const MosqueSearchAreaTiler(),
    OpenStreetMapMosqueQueryBuilder queryBuilder =
        const OpenStreetMapMosqueQueryBuilder(),
    OpenStreetMapMosqueResponseParser parser =
        const OpenStreetMapMosqueResponseParser(),
  })  : _client = client ?? OpenStreetMapOverpassClient(),
        _tiler = tiler,
        _queryBuilder = queryBuilder,
        _parser = parser;

  final OpenStreetMapOverpassClient _client;
  final MosqueSearchAreaTiler _tiler;
  final OpenStreetMapMosqueQueryBuilder _queryBuilder;
  final OpenStreetMapMosqueResponseParser _parser;

  bool _isClosed = false;

  @override
  Future<MosqueSearchResult> search(
    MosqueSearchRequest request,
  ) async {
    if (_isClosed) {
      throw StateError('The mosque search service is closed.');
    }

    if (!request.isValid) {
      throw ArgumentError.value(
        request,
        'request',
        'A valid mosque search request is required.',
      );
    }

    final tiles = _tiler.split(request.area);
    final uniqueMosques = <String, NearbyMosque>{};

    var searchedTileCount = 0;
    var failedTileCount = 0;

    // Requests are intentionally sequential to reduce pressure
    // on public Overpass servers.
    for (final tile in tiles) {
      var tileSucceeded = true;

      try {
        final tileRequest = request.copyWith(area: tile);
        final queries = _queryBuilder.buildQueries(tileRequest);

        if (queries.isEmpty) {
          tileSucceeded = false;
        }

        for (final query in queries) {
          try {
            final response = await _client.execute(query);
            final records = _parser.parse(response);

            for (final mosque in records) {
              if (!tile.contains(
                latitude: mosque.latitude,
                longitude: mosque.longitude,
              )) {
                continue;
              }

              uniqueMosques.putIfAbsent(
                mosque.id,
                () => mosque,
              );
            }
          } on Exception {
            tileSucceeded = false;
          }
        }
      } on Exception {
        tileSucceeded = false;
      }

      if (tileSucceeded) {
        searchedTileCount++;
      } else {
        failedTileCount++;
      }
    }

    var results = uniqueMosques.values.toList(growable: false);

    final searchTerm = request.normalizedQuery;

    if (searchTerm != null) {
      results = results
          .where(
            (mosque) => _matchesQuery(
              mosque,
              searchTerm,
              request.normalizedLanguageCode,
            ),
          )
          .toList(growable: false);
    }

    if (results.length > request.limit) {
      results = results.take(request.limit).toList(growable: false);
    }

    return MosqueSearchResult(
      requestedArea: request.area,
      mosques: results,
      searchedTileCount: searchedTileCount,
      failedTileCount: failedTileCount,
    );
  }

  bool _matchesQuery(
    NearbyMosque mosque,
    String query,
    String languageCode,
  ) {
    final normalizedQuery = _normalize(query);

    final searchableValues = <String?>[
      mosque.nameForLanguage(languageCode),
      mosque.name,
      mosque.nameAr,
      mosque.nameEn,
      mosque.nameFr,
      mosque.address,
      mosque.city,
      mosque.region,
      mosque.postcode,
      mosque.operator,
    ];

    return searchableValues.any((value) {
      if (value == null || value.trim().isEmpty) {
        return false;
      }

      return _normalize(value).contains(normalizedQuery);
    });
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  /// Releases the underlying HTTP client.
  ///
  /// Do not call this while a search is still running.
  void close() {
    if (_isClosed) return;

    _isClosed = true;
    _client.close();
  }
}
