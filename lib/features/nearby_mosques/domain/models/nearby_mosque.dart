/// Mumin Pro — Worldwide Mosque Discovery.
///
/// A source-aware domain model for mosques and Muslim prayer places
/// discovered from OpenStreetMap-compatible geographic datasets.
///
/// This model contains no Flutter, map-rendering, GPS, or networking
/// dependencies. It never invents missing mosque information.
enum MosquePlaceType {
  mosque,
  prayerRoom,
  musalla,
  unknown,
}

/// A geographic mosque or Muslim prayer place.
///
/// Supported OpenStreetMap element types:
/// - node
/// - way
/// - relation
///
/// For ways and relations, coordinates may be supplied through
/// the Overpass `center` object.
final class NearbyMosque {
  const NearbyMosque({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.placeType,
    required this.source,
    this.nameAr,
    this.nameEn,
    this.nameFr,
    this.address,
    this.city,
    this.region,
    this.countryCode,
    this.postcode,
    this.phone,
    this.website,
    this.openingHours,
    this.wheelchair,
    this.distanceMeters,
    this.operator,
    this.denomination,
    this.lastUpdated,
  });

  /// Stable source identifier, for example `node/123456`.
  final String id;

  /// Default display name supplied by the source.
  final String name;

  /// Optional language-specific names.
  final String? nameAr;
  final String? nameEn;
  final String? nameFr;

  /// WGS84 latitude.
  final double latitude;

  /// WGS84 longitude.
  final double longitude;

  /// Type of Muslim prayer place.
  final MosquePlaceType placeType;

  /// Dataset identifier, normally `openstreetmap`.
  final String source;

  /// Available address information.
  final String? address;
  final String? city;
  final String? region;
  final String? countryCode;
  final String? postcode;

  /// Optional contact information.
  final String? phone;
  final String? website;

  /// Optional operational information.
  final String? openingHours;
  final String? wheelchair;
  final String? operator;
  final String? denomination;

  /// Distance from the user's selected reference point.
  ///
  /// Null means that no distance has been calculated.
  final double? distanceMeters;

  /// Source modification timestamp, when available.
  final DateTime? lastUpdated;

  /// Resolves the best available name for the selected language.
  ///
  /// Fallback order:
  /// Arabic: Arabic, default name, English, French.
  /// English: English, default name, Arabic, French.
  /// French: French, default name, English, Arabic.
  String nameForLanguage(String languageCode) {
    final code = languageCode
        .trim()
        .toLowerCase()
        .split('-')
        .first;

    final candidates = switch (code) {
      'ar' => [nameAr, name, nameEn, nameFr],
      'fr' => [nameFr, name, nameEn, nameAr],
      _ => [nameEn, name, nameAr, nameFr],
    };

    for (final candidate in candidates) {
      final value = candidate?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  /// Returns whether the coordinates are geographically valid.
  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Returns whether the source identity is usable.
  bool get hasValidIdentity =>
      id.trim().isNotEmpty &&
      source.trim().isNotEmpty;

  /// Returns whether this record can be displayed as a result.
  bool get isValid =>
      hasValidIdentity &&
      hasValidCoordinates &&
      name.trim().isNotEmpty;

  /// Returns a human-readable distance.
  ///
  /// The value is only displayed when a real distance is available.
  String? distanceLabel({
    String lessThanOneKilometer = 'Less than 1 km',
  }) {
    final distance = distanceMeters;

    if (distance == null ||
        !distance.isFinite ||
        distance < 0) {
      return null;
    }

    if (distance < 1000) {
      return '${distance.round()} m';
    }

    final kilometers = distance / 1000;

    if (kilometers < 1.05) {
      return lessThanOneKilometer;
    }

    return '${kilometers.toStringAsFixed(1)} km';
  }

  /// Creates a validated model from an OpenStreetMap Overpass element.
  ///
  /// The parser accepts:
  /// - node coordinates (`lat`, `lon`)
  /// - way/relation center coordinates (`center.lat`, `center.lon`)
  ///
  /// Invalid or unsupported records return null.
  factory NearbyMosque.fromOpenStreetMapElement(
    Map<String, dynamic> element,
  ) {
    final type = _readString(element['type']);
    final rawId = _readString(element['id']);

    if (type == null ||
        rawId == null ||
        !const {'node', 'way', 'relation'}.contains(type)) {
      return _invalidElement();
    }

    final tags = _readMap(element['tags']);

    if (tags == null) {
      return _invalidElement();
    }

    final placeType = _resolvePlaceType(tags);

    if (placeType == MosquePlaceType.unknown) {
      return _invalidElement();
    }

    final center = _readMap(element['center']);

    final latitude = _readDouble(
      element['lat'] ?? center?['lat'],
    );

    final longitude = _readDouble(
      element['lon'] ?? center?['lon'],
    );

    if (latitude == null || longitude == null) {
      return _invalidElement();
    }

    final defaultName = _firstValue([
      tags['name'],
      tags['official_name'],
      tags['short_name'],
      tags['name:en'],
      tags['name:ar'],
      tags['name:fr'],
    ]);

    if (defaultName == null) {
      return _invalidElement();
    }

    final address = _buildAddress(tags);

    final timestamp = _readDateTime(
      element['timestamp'],
    );

    final mosque = NearbyMosque(
      id: '$type/$rawId',
      name: defaultName,
      nameAr: _readString(tags['name:ar']),
      nameEn: _readString(tags['name:en']),
      nameFr: _readString(tags['name:fr']),
      latitude: latitude,
      longitude: longitude,
      placeType: placeType,
      source: 'openstreetmap',
      address: address,
      city: _firstValue([
        tags['addr:city'],
        tags['addr:town'],
        tags['addr:village'],
        tags['addr:hamlet'],
      ]),
      region: _firstValue([
        tags['addr:state'],
        tags['addr:province'],
        tags['addr:region'],
      ]),
      countryCode: _normalizeCountryCode(
        tags['addr:country'],
      ),
      postcode: _readString(tags['addr:postcode']),
      phone: _firstValue([
        tags['contact:phone'],
        tags['phone'],
      ]),
      website: _firstValue([
        tags['contact:website'],
        tags['website'],
      ]),
      openingHours: _readString(tags['opening_hours']),
      wheelchair: _readString(tags['wheelchair']),
      operator: _readString(tags['operator']),
      denomination: _readString(tags['denomination']),
      lastUpdated: timestamp,
    );

    return mosque.isValid ? mosque : _invalidElement();
  }

  /// Creates a copy with an updated calculated distance.
  NearbyMosque copyWith({
    double? distanceMeters,
  }) {
    return NearbyMosque(
      id: id,
      name: name,
      nameAr: nameAr,
      nameEn: nameEn,
      nameFr: nameFr,
      latitude: latitude,
      longitude: longitude,
      placeType: placeType,
      source: source,
      address: address,
      city: city,
      region: region,
      countryCode: countryCode,
      postcode: postcode,
      phone: phone,
      website: website,
      openingHours: openingHours,
      wheelchair: wheelchair,
      operator: operator,
      denomination: denomination,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lastUpdated: lastUpdated,
    );
  }

  static MosquePlaceType _resolvePlaceType(
    Map<String, dynamic> tags,
  ) {
    final amenity = _readString(tags['amenity']);
    final placeOfWorship = _readString(
      tags['place_of_worship'],
    );

    if (amenity == 'place_of_worship' ||
        placeOfWorship == 'mosque') {
      return MosquePlaceType.mosque;
    }

    if (amenity == 'prayer_room') {
      return MosquePlaceType.prayerRoom;
    }

    if (amenity == 'musalla') {
      return MosquePlaceType.musalla;
    }

    return MosquePlaceType.unknown;
  }

  static String? _buildAddress(
    Map<String, dynamic> tags,
  ) {
    final parts = <String>[
      if (_readString(tags['addr:housenumber']) case final value?)
        value,
      if (_readString(tags['addr:street']) case final value?)
        value,
      if (_readString(tags['addr:suburb']) case final value?)
        value,
    ];

    if (parts.isEmpty) return null;

    return parts.join(', ');
  }

  static String? _normalizeCountryCode(Object? value) {
    final country = _readString(value);

    if (country == null) return null;

    final normalized = country.toUpperCase();

    return RegExp(r'^[A-Z]{2}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  static String? _firstValue(
    List<Object?> values,
  ) {
    for (final value in values) {
      final text = _readString(value);

      if (text != null) return text;
    }

    return null;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;

    final normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  static Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          item,
        ),
      );
    }

    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      final result = value.toDouble();

      return result.isFinite ? result : null;
    }

    if (value is String) {
      final result = double.tryParse(value);

      return result != null && result.isFinite
          ? result
          : null;
    }

    return null;
  }

  static DateTime? _readDateTime(Object? value) {
    final timestamp = _readString(value);

    if (timestamp == null) return null;

    return DateTime.tryParse(timestamp);
  }

  static NearbyMosque _invalidElement() {
    return const NearbyMosque(
      id: '',
      name: '',
      latitude: double.nan,
      longitude: double.nan,
      placeType: MosquePlaceType.unknown,
      source: '',
    );
  }
}
