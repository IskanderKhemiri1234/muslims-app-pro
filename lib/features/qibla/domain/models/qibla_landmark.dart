
/// Categories supported by the Qibla Atlas.
enum QiblaLandmarkCategory {
  holyMosque,
  mosque,
  historicalMosque,
  historicalSite,
  landmark,
}

/// Resolves a localized value without depending on Flutter or UI code.
///
/// Fallback order:
/// - Arabic: Arabic, English, French.
/// - English: English, Arabic, French.
/// - French: French, English, Arabic.
String _resolveLandmarkLanguage({
  required String languageCode,
  required String? arabic,
  required String? english,
  required String? french,
}) {
  final code = languageCode.trim().toLowerCase().split('-').first;

  final candidates = switch (code) {
    'ar' => [arabic, english, french],
    'fr' => [french, english, arabic],
    _ => [english, arabic, french],
  };

  for (final candidate in candidates) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return '';
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
    this.captionFr,
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
  final String? captionFr;

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

  String captionForLanguage(String languageCode) {
    return _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: captionAr,
      english: captionEn,
      french: captionFr,
    );
  }

  @Deprecated('Use captionForLanguage(languageCode).')
  String captionForLocale({required bool isArabic}) {
    return captionForLanguage(isArabic ? 'ar' : 'en');
  }

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
    this.titleFr,
    this.descriptionFr,
    this.dateLabelFr,
    this.startYear,
    this.endYear,
    this.calendar,
    this.sourceIds = const [],
  });

  /// Stable event identifier.
  final String id;

  final String titleAr;
  final String titleEn;
  final String? titleFr;

  final String descriptionAr;
  final String descriptionEn;
  final String? descriptionFr;

  /// Human-readable date, for example: القرن الثاني عشر الميلادي.
  final String dateLabelAr;
  final String dateLabelEn;
  final String? dateLabelFr;

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

  String titleForLanguage(String languageCode) {
    return _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: titleAr,
      english: titleEn,
      french: titleFr,
    );
  }

  String descriptionForLanguage(String languageCode) {
    return _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: descriptionAr,
      english: descriptionEn,
      french: descriptionFr,
    );
  }

  String dateForLanguage(String languageCode) {
    return _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: dateLabelAr,
      english: dateLabelEn,
      french: dateLabelFr,
    );
  }

  @Deprecated('Use titleForLanguage(languageCode).')
  String titleForLocale({required bool isArabic}) {
    return titleForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use descriptionForLanguage(languageCode).')
  String descriptionForLocale({required bool isArabic}) {
    return descriptionForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use dateForLanguage(languageCode).')
  String dateForLocale({required bool isArabic}) {
    return dateForLanguage(isArabic ? 'ar' : 'en');
  }

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
    this.nameFr,
    this.descriptionAr,
    this.descriptionEn,
    this.descriptionFr,
    this.imageAsset,
    this.sourceName,
    this.sourceUrl,
    this.license,
    this.lastVerifiedAt,
    this.isFeatured = false,
    this.cityAr,
    this.cityEn,
    this.cityFr,
    this.regionAr,
    this.regionEn,
    this.regionFr,
    this.historicalPeriodAr,
    this.historicalPeriodEn,
    this.historicalPeriodFr,
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

  /// Localized display names.
  final String nameAr;
  final String nameEn;
  final String? nameFr;

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
  final String? descriptionFr;

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
  final String? cityFr;

  final String? regionAr;
  final String? regionEn;
  final String? regionFr;

  /// Historical period, when reliably documented.
  final String? historicalPeriodAr;
  final String? historicalPeriodEn;
  final String? historicalPeriodFr;

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
      historicalPeriodFr != null ||
      establishedYear != null ||
      historicalEvents.isNotEmpty;

  String nameForLanguage(String languageCode) {
    return _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: nameAr,
      english: nameEn,
      french: nameFr,
    );
  }

  String? descriptionForLanguage(String languageCode) {
    final value = _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: descriptionAr,
      english: descriptionEn,
      french: descriptionFr,
    );
    return value.isEmpty ? null : value;
  }

  String? cityForLanguage(String languageCode) {
    final value = _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: cityAr,
      english: cityEn,
      french: cityFr,
    );
    return value.isEmpty ? null : value;
  }

  String? regionForLanguage(String languageCode) {
    final value = _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: regionAr,
      english: regionEn,
      french: regionFr,
    );
    return value.isEmpty ? null : value;
  }

  String? historicalPeriodForLanguage(String languageCode) {
    final value = _resolveLandmarkLanguage(
      languageCode: languageCode,
      arabic: historicalPeriodAr,
      english: historicalPeriodEn,
      french: historicalPeriodFr,
    );
    return value.isEmpty ? null : value;
  }

  // Temporary compatibility methods.
  // Remove these after all Qibla Atlas consumers use languageCode.

  @Deprecated('Use nameForLanguage(languageCode).')
  String nameForLocale({required bool isArabic}) {
    return nameForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use descriptionForLanguage(languageCode).')
  String? descriptionForLocale({required bool isArabic}) {
    return descriptionForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use cityForLanguage(languageCode).')
  String? cityForLocale({required bool isArabic}) {
    return cityForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use regionForLanguage(languageCode).')
  String? regionForLocale({required bool isArabic}) {
    return regionForLanguage(isArabic ? 'ar' : 'en');
  }

  @Deprecated('Use historicalPeriodForLanguage(languageCode).')
  String? historicalPeriodForLocale({
    required bool isArabic,
  }) {
    return historicalPeriodForLanguage(
      isArabic ? 'ar' : 'en',
    );
  }

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
