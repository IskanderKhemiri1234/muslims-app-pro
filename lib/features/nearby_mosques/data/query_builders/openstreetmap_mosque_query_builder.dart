
import '../../domain/models/mosque_search_area.dart';
import '../../domain/models/mosque_search_request.dart';
import '../config/nearby_mosque_data_source_config.dart';

/// Mumin Pro — OpenStreetMap Mosque Query Builder.
///
/// Builds Overpass QL queries for explicitly identified Muslim
/// worship places. It never performs network requests.
final class OpenStreetMapMosqueQueryBuilder {
  const OpenStreetMapMosqueQueryBuilder();

  /// Builds one query for a normal area, or two queries when the
  /// requested area crosses the international date line.
  ///
  /// Large-area subdivision is handled by the search service.
  List<String> buildQueries(MosqueSearchRequest request) {
    if (!request.isValid) {
      throw ArgumentError.value(
        request,
        'request',
        'A valid mosque search request is required.',
      );
    }

    final boxes = _splitArea(request.area);

    return List<String>.unmodifiable(
      boxes.map(_buildQuery),
    );
  }

  String _buildQuery(_BoundingBox box) {
    final bounds = box.toOverpassBounds();

    final timeout =
        NearbyMosqueDataSourceConfig.overpassQueryTimeoutSeconds;

    final selectors = <String>[];

    for (final elementType in const [
      'node',
      'way',
      'relation',
    ]) {
      // Explicit mosque classification.
      selectors.add(
        '$elementType["place_of_worship"="mosque"]($bounds);',
      );

      // Muslim worship places explicitly tagged by religion.
      selectors.add(
        '$elementType'
        '["amenity"="place_of_worship"]'
        '["religion"~"^(muslim|islam)\$",i]'
        '($bounds);',
      );

      // Prayer rooms and musallas require an explicit Muslim religion tag.
      selectors.add(
        '$elementType'
        '["amenity"="prayer_room"]'
        '["religion"~"^(muslim|islam)\$",i]'
        '($bounds);',
      );

      selectors.add(
        '$elementType'
        '["amenity"="musalla"]'
        '["religion"~"^(muslim|islam)\$",i]'
        '($bounds);',
      );
    }

    return '''
[out:json][timeout:$timeout];
(
${selectors.join('\n')}
);
out center tags;
''';
  }

  List<_BoundingBox> _splitArea(MosqueSearchArea area) {
    if (!area.crossesDateLine) {
      return [
        _BoundingBox(
          south: area.south,
          west: area.west,
          north: area.north,
          east: area.east,
        ),
      ];
    }

    return [
      _BoundingBox(
        south: area.south,
        west: area.west,
        north: area.north,
        east: 180,
      ),
      _BoundingBox(
        south: area.south,
        west: -180,
        north: area.north,
        east: area.east,
      ),
    ];
  }
}

final class _BoundingBox {
  const _BoundingBox({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  String toOverpassBounds() {
    return '${_format(south)},'
        '${_format(west)},'
        '${_format(north)},'
        '${_format(east)}';
  }

  String _format(double value) {
    return value.toStringAsFixed(7);
  }
}
