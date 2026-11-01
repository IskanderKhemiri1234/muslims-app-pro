
enum QiblaLandmarkCategory {
  holyMosque,
  mosque,
  historicalMosque,
  historicalSite,
  landmark,
}

class QiblaLandmark {
  const QiblaLandmark({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.countryCode,
    this.descriptionAr,
    this.descriptionEn,
    this.imageAsset,
    this.sourceName,
    this.sourceUrl,
    this.license,
    this.lastVerifiedAt,
    this.isFeatured = false,
  })  : assert(id != ''),
        assert(nameAr != ''),
        assert(nameEn != ''),
        assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  /// Stable identifier. Never use the displayed name as an ID.
  final String id;

  /// Arabic display name.
  final String nameAr;

  /// English display name.
  final String nameEn;

  /// Landmark classification.
  final QiblaLandmarkCategory category;

  /// WGS84 latitude.
  final double latitude;

  /// WGS84 longitude.
  final double longitude;

  /// ISO 3166-1 alpha-2 country code.
  final String countryCode;

  final String? descriptionAr;
  final String? descriptionEn;

  /// Local bundled image path. Never a remote URL.
  final String? imageAsset;

  /// Data provenance and image attribution.
  final String? sourceName;
  final String? sourceUrl;
  final String? license;

  /// ISO 8601 verification date.
  final String? lastVerifiedAt;

  /// Featured locations appear prominently in the atlas.
  final bool isFeatured;

  bool get hasLocalImage =>
      imageAsset != null && imageAsset!.isNotEmpty;

  bool get hasSourceAttribution =>
      sourceName != null && sourceName!.isNotEmpty;

  bool get hasVerificationDate =>
      lastVerifiedAt != null && lastVerifiedAt!.isNotEmpty;

  String nameForLocale({required bool isArabic}) =>
      isArabic ? nameAr : nameEn;

  String? descriptionForLocale({required bool isArabic}) =>
      isArabic ? descriptionAr : descriptionEn;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
