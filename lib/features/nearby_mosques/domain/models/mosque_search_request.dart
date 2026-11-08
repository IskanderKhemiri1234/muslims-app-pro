
import 'mosque_search_area.dart';

/// Mumin Pro — Nearby Mosques Search Request.
///
/// Describes a mosque search within a manually selected map area.
/// It does not access device location or perform network requests.
final class MosqueSearchRequest {
  const MosqueSearchRequest({
    required this.area,
    this.query,
    this.languageCode = 'ar',
    this.limit = 100,
  });

  /// Geographic bounds selected by the user on the map.
  final MosqueSearchArea area;

  /// Optional mosque name, city, region, or address search term.
  final String? query;

  /// Language used for localized search and presentation.
  final String languageCode;

  /// Maximum number of results requested from the data layer.
  final int limit;

  /// Supported application languages.
  static const Set<String> supportedLanguages = {
    'ar',
    'en',
    'fr',
  };

  /// Returns the normalized search term, or null when empty.
  String? get normalizedQuery {
    final value = query?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  /// Returns a normalized language code.
  String get normalizedLanguageCode {
    final value = languageCode.trim().toLowerCase();
    final separatorIndex = value.indexOf(RegExp('[-_]'));

    final baseLanguage = separatorIndex == -1
        ? value
        : value.substring(0, separatorIndex);

    return supportedLanguages.contains(baseLanguage)
        ? baseLanguage
        : 'ar';
  }

  /// Whether the request contains valid search parameters.
  bool get isValid {
    return area.isValid && limit >= 1 && limit <= 500;
  }

  /// Creates a copy with selected values changed.
  MosqueSearchRequest copyWith({
    MosqueSearchArea? area,
    String? query,
    String? languageCode,
    int? limit,
    bool clearQuery = false,
  }) {
    return MosqueSearchRequest(
      area: area ?? this.area,
      query: clearQuery ? null : query ?? this.query,
      languageCode: languageCode ?? this.languageCode,
      limit: limit ?? this.limit,
    );
  }

  @override
  String toString() {
    return 'MosqueSearchRequest('
        'area: $area, '
        'query: $normalizedQuery, '
        'languageCode: $normalizedLanguageCode, '
        'limit: $limit'
        ')';
  }
}
