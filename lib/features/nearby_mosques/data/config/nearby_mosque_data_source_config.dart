
/// Mumin Pro — OpenStreetMap Data Source Configuration.
///
/// Central configuration for the worldwide mosque discovery service.
/// This file does not perform network requests or access device location.
final class NearbyMosqueDataSourceConfig {
  NearbyMosqueDataSourceConfig._();

  /// Primary public OpenStreetMap Overpass API endpoint.
  ///
  /// The endpoint can be replaced without changing domain or UI code.
  static const String primaryEndpoint =
      'https://overpass-api.de/api/interpreter';

  /// Alternative public Overpass endpoints.
  ///
  /// These are fallback candidates, not a guarantee of availability.
  static const List<String> fallbackEndpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.nchc.org.tw/api/interpreter',
  ];

  /// Maximum time allowed for one network request.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum number of records requested in one search response.
  static const int defaultResultLimit = 100;

  /// Absolute maximum accepted result limit.
  static const int maximumResultLimit = 500;

  /// Maximum number of geographic subdivisions.
  ///
  /// Large map areas should be divided into smaller requests by the
  /// data layer instead of sending one oversized Overpass query.
  static const int maximumTileCount = 64;

  /// Maximum subdivision depth for a geographic search.
  static const int maximumSubdivisionDepth = 4;

  /// Minimum useful geographic tile dimension in degrees.
  static const double minimumTileSpanDegrees = 0.005;

  /// Overpass query execution timeout in seconds.
  static const int overpassQueryTimeoutSeconds = 25;

  /// HTTP request user agent.
  ///
  /// Use a descriptive application identifier.
  static const String userAgent = 'MuminPro/1.0 (OpenStreetMap data client)';

  /// Returns all configured endpoints in priority order.
  static List<String> get endpoints => List.unmodifiable([
        primaryEndpoint,
        ...fallbackEndpoints,
      ]);

  /// Validates an endpoint before a request is sent.
  static bool isValidEndpoint(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.path.endsWith('/interpreter');
  }
}
