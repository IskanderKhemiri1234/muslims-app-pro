
/// Mumin Pro — Worldwide Mosque Discovery.
///
/// Source-aware domain model for mosques and Muslim prayer places.
/// Independent from Flutter, GPS, networking and map rendering.
///
/// Missing information is never fabricated.
enum MosquePlaceType {
  mosque,
  prayerRoom,
  musalla,
  unknown,
}

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

  final String id;
  final String name;

  final String? nameAr;
  final String? nameEn;
  final String? nameFr;

  final double latitude;
  final double longitude;

  final MosquePlaceType placeType;
  final String source;

  final String? address;
  final String? city;
  final String? region;
  final String? countryCode;
  final String? postcode;

  final String? phone;
  final String? website;

  final String? openingHours;
  final String? wheelchair;
  final String? operator;
  final String? denomination;

  final double? distanceMeters;
  final DateTime? lastUpdated;

  /// Resolves the best available source-provided name.
  ///
  /// Returns an empty string when the source has no name.
  /// The presentation layer must then use a localized place-type label.
  String nameForLanguage(String languageCode) {
    final code = languageCode
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
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

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get hasValidIdentity =>
      id.trim().isNotEmpty && source.trim().isNotEmpty;

  /// A mosque does not need a registered name to be a valid place.
  bool get isValid =>
      hasValidIdentity &&
      hasValidCoordinates &&
      placeType != MosquePlaceType.unknown;

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

  /// Safely parses a supported OpenStreetMap Overpass element.
  ///
  /// Returns null for invalid, unsupported or non-Muslim places.
  ///
  /// Accepted coordinates:
  /// - node: lat / lon
  /// - way and relation: center.lat / center.lon
  static NearbyMosque? tryFromOpenStreetMapElement(
    Map<String, dynamic> element,
  ) {
    final type = _readString(element['type']);
    final rawId = _readIdentifier(element['id']);

    if (type == null ||
        rawId == null ||
        !const {'node', 'way', 'relation'}.contains(type)) {
      return null;
    }

    final tags = _readMap(element['tags']);

    if (tags == null) {
      return null;
    }

    final placeType = _resolvePlaceType(tags);

    if (placeType == MosquePlaceType.unknown) {
      return null;
    }

    final center = _readMap(element['center']);

    final latitude = _readDouble(
      element['lat'] ?? center?['lat'],
    );

    final longitude = _readDouble(
      element['lon'] ?? center?['lon'],
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    final defaultName = _firstValue([
      tags['name'],
      tags['official_name'],
      tags['short_name'],
      tags['name:en'],
      tags['name:ar'],
      tags['name:fr'],
    ]);

    final mosque = NearbyMosque(
      id: '$type/$rawId',
      name: defaultName ?? '',
      nameAr: _readString(tags['name:ar']),
      nameEn: _readString(tags['name:en']),
      nameFr: _readString(tags['name:fr']),
      latitude: latitude,
      longitude: longitude,
      placeType: placeType,
      source: 'openstreetmap',
      address: _buildAddress(tags),
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
      lastUpdated: _readDateTime(element['timestamp']),
    );

    return mosque.isValid ? mosque : null;
  }

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
    final amenity = _normalizedTag(tags['amenity']);
    final placeOfWorship = _normalizedTag(
      tags['place_of_worship'],
    );
    final religion = _normalizedTag(tags['religion']);

    final isMuslimReligion =
        religion == 'muslim' || religion == 'islam';

    final hasConflictingReligion =
        religion != null && !isMuslimReligion;

    if (hasConflictingReligion) {
      return MosquePlaceType.unknown;
    }

    if (placeOfWorship == 'mosque') {
      return MosquePlaceType.mosque;
    }

    if (amenity == 'place_of_worship' &&
        isMuslimReligion) {
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
      if (_readString(tags['addr:housenumber'])
          case final value?)
        value,
      if (_readString(tags['addr:street'])
          case final value?)
        value,
      if (_readString(tags['addr:suburb'])
          case final value?)
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

  static String? _firstValue(List<Object?> values) {
    for (final value in values) {
      final text = _readString(value);

      if (text != null) return text;
    }

    return null;
  }

  static String? _normalizedTag(Object? value) {
    return _readString(value)?.toLowerCase();
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;

    final normalized = value.trim();

    return normalized.isEmpty ? null : normalized;
  }

  /// Overpass element IDs are commonly numeric.
  static String? _readIdentifier(Object? value) {
    if (value is int && value > 0) {
      return value.toString();
    }

    if (value is String) {
      final normalized = value.trim();

      return normalized.isEmpty ? null : normalized;
    }

    return null;
  }

  static Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
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
}
