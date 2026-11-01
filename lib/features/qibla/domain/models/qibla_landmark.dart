
/// Categories supported by the Qibla Atlas.
enum QiblaLandmarkCategory {
  holyMosque,
  mosque,
  historicalMosque,
  historicalSite,
  landmark,
}

/// A locally bundled photograph associated with a landmark.
class QiblaLandmarkImage {
  const QiblaLandmarkImage({
    required this.id,
    required this.assetPath,
    required this.captionAr,
    required this.captionEn,
    required this.creator,
    required this.sourceName,
    required this.sourceUrl,
    required this.license,
    this.isPrimary = false,
    this.width,
    this.height,
  });

  /// Stable image identifier.
  final String id;

  /// Local bundled asset path. Remote image URLs are not supported.
  final String assetPath;

  final String captionAr;
  final String captionEn;

  /// Photographer, creator, or copyright holder.
  final String creator;

  /// Website or institution providing the image.
  final String sourceName;

  /// Original source page, not a direct temporary image URL.
  final String sourceUrl;

  /// Exact license identifier or rights statement.
  final String license;

  /// Whether this image is the primary landmark photograph.
  final bool isPrimary;

  /// Original image dimensions, when known.
  final int? width;
  final int? height;

  String captionForLocale({required bool isArabic}) =>
      isArabic ? captionAr : captionEn;

  bool get hasValidDimensions =>
      (width == null || width! > 0) &&
      (height == null || height! > 0);
}

/// A historical event or period associated with a landmark.
class QiblaLandmarkHistoricalEvent {
  const QiblaLandmarkHistoricalEvent({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.dateLabelAr,
    required this.dateLabelEn,
    required this.sortOrder,
    this.startYear,
    this.endYear,
    this.calendar,
    this.sourceIds = const [],
  });

  /// Stable event identifier.
  final String id;

  final String titleAr;
  final String titleEn;

  final String descriptionAr;
  final String descriptionEn;

  /// Human-readable date, for example: القرن الثاني عشر الميلادي.
  final String dateLabelAr;
  final String dateLabelEn;

  /// Numeric ordering for chronological presentation.
  final int sortOrder;

  /// Optional approximate or documented starting year.
  ///
  /// Negative values represent years BCE.
  final int? startYear;

  /// Optional ending year for a period or historical phase.
  final int? endYear;

  /// Calendar or dating system, for example Gregorian or Hijri.
  final String? calendar;

  /// IDs of sources supporting this historical event.
  final List<String> sourceIds;

  String titleForLocale({required bool isArabic}) =>
      isArabic ? titleAr : titleEn;

  String descriptionForLocale({required bool isArabic}) =>
      isArabic ? descriptionAr : descriptionEn;

  String dateForLocale({required bool isArabic}) =>
      isArabic ? dateLabelAr : dateLabelEn;

  bool get hasValidYearRange =>
      startYear == null ||
      endYear == null ||
      startYear! <= endYear!;
}

/// A verifiable information source for a landmark or historical event.
class QiblaLandmarkSource {
  const QiblaLandmarkSource({
    required this.id,
    required this.name,
    required this.url,
    required this.sourceType,
    required this.accessedAt,
    this.publisher,
    this.license,
  });

  /// Stable source identifier.
  final String id;

  final String name;
  final String url;

  /// Examples: official, academic, heritage, archive, image.
  final String sourceType;

  /// ISO 8601 date when the source was checked.
  final String accessedAt;

  final String? publisher;
  final String? license;
}

/// Geographic and historical information for a Qibla Atlas landmark.
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
    this.cityAr,
    this.cityEn,
    this.regionAr,
    this.regionEn,
    this.historicalPeriodAr,
    this.historicalPeriodEn,
    this.establishedYear,
    this.images = const [],
    this.historicalEvents = const [],
    this.sources = const [],
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

  /// General descriptions.
  final String? descriptionAr;
  final String? descriptionEn;

  /// Optional primary local image for backward compatibility.
  final String? imageAsset;

  /// Legacy single-source fields retained for compatibility.
  final String? sourceName;
  final String? sourceUrl;
  final String? license;

  /// ISO 8601 date of the last landmark verification.
  final String? lastVerifiedAt;

  /// Featured locations appear prominently in the atlas.
  final bool isFeatured;

  /// Geographic administrative information.
  final String? cityAr;
  final String? cityEn;
  final String? regionAr;
  final String? regionEn;

  /// Historical period, when reliably documented.
  final String? historicalPeriodAr;
  final String? historicalPeriodEn;

  /// Approximate or documented establishment year.
  ///
  /// Negative values represent years BCE.
  final int? establishedYear;

  /// Multiple locally stored photographs.
  final List<QiblaLandmarkImage> images;

  /// Chronological events and historical phases.
  final List<QiblaLandmarkHistoricalEvent> historicalEvents;

  /// Multiple references supporting the landmark information.
  final List<QiblaLandmarkSource> sources;

  bool get hasLocalImage =>
      (imageAsset != null && imageAsset!.isNotEmpty) ||
      images.any((image) => image.assetPath.isNotEmpty);

  bool get hasSourceAttribution =>
      (sourceName != null && sourceName!.isNotEmpty) ||
      sources.isNotEmpty;

  bool get hasVerificationDate =>
      lastVerifiedAt != null && lastVerifiedAt!.isNotEmpty;

  bool get hasHistoricalInformation =>
      historicalPeriodAr != null ||
      historicalPeriodEn != null ||
      establishedYear != null ||
      historicalEvents.isNotEmpty;

  String nameForLocale({required bool isArabic}) =>
      isArabic ? nameAr : nameEn;

  String? descriptionForLocale({required bool isArabic}) =>
      isArabic ? descriptionAr : descriptionEn;

  String? cityForLocale({required bool isArabic}) =>
      isArabic ? cityAr : cityEn;

  String? regionForLocale({required bool isArabic}) =>
      isArabic ? regionAr : regionEn;

  String? historicalPeriodForLocale({
    required bool isArabic,
  }) =>
      isArabic ? historicalPeriodAr : historicalPeriodEn;

  /// Returns the explicitly marked primary image, if available.
  QiblaLandmarkImage? get primaryImage {
    for (final image in images) {
      if (image.isPrimary) return image;
    }

    return images.isNotEmpty ? images.first : null;
  }

  /// Returns historical events in chronological display order.
  List<QiblaLandmarkHistoricalEvent> get chronologicalEvents {
    final events = List<QiblaLandmarkHistoricalEvent>.of(
      historicalEvents,
    );

    events.sort(
      (a, b) => a.sortOrder.compareTo(b.sortOrder),
    );

    return List<QiblaLandmarkHistoricalEvent>.unmodifiable(
      events,
    );
  }

  /// Validates geographic coordinates at runtime.
  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Basic runtime validation of the landmark's required fields.
  bool get hasValidBasicData =>
      id.trim().isNotEmpty &&
      nameAr.trim().isNotEmpty &&
      nameEn.trim().isNotEmpty &&
      RegExp(r'^[A-Z]{2}$').hasMatch(countryCode) &&
      hasValidCoordinates;

  /// Checks whether every bundled image has a plausible local path.
  bool get hasValidLocalImages {
    bool isValidPath(String path) {
      return path.startsWith('assets/') &&
          !path.startsWith('/') &&
          !path.contains('..') &&
          !path.contains('://');
    }

    if (imageAsset != null && !isValidPath(imageAsset!)) {
      return false;
    }

    return images.every(
      (image) =>
          isValidPath(image.assetPath) &&
          image.hasValidDimensions,
    );
  }
}
