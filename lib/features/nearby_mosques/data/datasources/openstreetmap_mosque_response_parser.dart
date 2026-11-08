
import '../../domain/models/nearby_mosque.dart';

/// Mumin Pro — OpenStreetMap Overpass Response Parser.
///
/// Converts raw Overpass JSON responses into validated mosque records.
/// Invalid records are skipped without interrupting the whole response.
final class OpenStreetMapMosqueResponseParser {
  const OpenStreetMapMosqueResponseParser();

  /// Parses an Overpass response and returns unique valid mosque records.
  ///
  /// Expected response structure:
  /// {
  ///   "elements": [...]
  /// }
  ///
  /// Returns an empty list when the response has no usable elements.
  List<NearbyMosque> parse(Map<String, dynamic> response) {
    final rawElements = response['elements'];

    if (rawElements is! List) {
      return const [];
    }

    final unique = <String, NearbyMosque>{};

    for (final rawElement in rawElements) {
      if (rawElement is! Map) {
        continue;
      }

      try {
        final element = Map<String, dynamic>.from(rawElement);

        final mosque =
            NearbyMosque.tryFromOpenStreetMapElement(element);

        if (mosque == null || !mosque.isValid) {
          continue;
        }

        unique.putIfAbsent(mosque.id, () => mosque);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      } on ArgumentError {
        continue;
      }
    }

    return List<NearbyMosque>.unmodifiable(unique.values);
  }
}
