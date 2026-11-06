
import '../../domain/models/qibla_landmark.dart';
import '../../domain/repositories/qibla_landmark_repository.dart';
import '../datasources/qibla_landmark_local_data_source.dart';

/// Local repository for Qibla landmarks.
///
/// Search is language-aware and uses the selected language code:
/// ar, en, or fr.
///
/// The repository searches the localized:
/// - Name
/// - Description
/// - City
/// - Region
///
/// Country code is also included as a language-independent identifier.
class QiblaLandmarkRepositoryImpl
    implements QiblaLandmarkRepository {
  QiblaLandmarkRepositoryImpl({
    required QiblaLandmarkLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final QiblaLandmarkLocalDataSource _dataSource;

  Future<List<QiblaLandmark>>? _cachedFuture;

  /// Loads landmarks once and shares the pending operation
  /// between simultaneous callers.
  ///
  /// If loading fails, the cache is cleared so a later request
  /// can retry.
  Future<List<QiblaLandmark>> _getCachedLandmarks() async {
    final existingFuture = _cachedFuture;

    if (existingFuture != null) {
      return existingFuture;
    }

    final pendingFuture = _dataSource.loadLandmarks();
    _cachedFuture = pendingFuture;

    try {
      return await pendingFuture;
    } catch (_) {
      if (identical(_cachedFuture, pendingFuture)) {
        _cachedFuture = null;
      }

      rethrow;
    }
  }

  @override
  Future<List<QiblaLandmark>> getAll() async {
    final landmarks = await _getCachedLandmarks();

    return List.unmodifiable(landmarks);
  }

  @override
  Future<List<QiblaLandmark>> getFeatured() async {
    final landmarks = await _getCachedLandmarks();

    return List.unmodifiable(
      landmarks.where((landmark) => landmark.isFeatured),
    );
  }

  @override
  Future<QiblaLandmark?> getById(String id) async {
    final landmarks = await _getCachedLandmarks();

    for (final landmark in landmarks) {
      if (landmark.id == id) {
        return landmark;
      }
    }

    return null;
  }

  @override
  Future<List<QiblaLandmark>> getByCategory(
    QiblaLandmarkCategory category,
  ) async {
    final landmarks = await _getCachedLandmarks();

    return List.unmodifiable(
      landmarks.where(
        (landmark) => landmark.category == category,
      ),
    );
  }

  /// Searches landmark information in the selected language.
  ///
  /// Supported launch languages:
  /// - ar: Arabic
  /// - en: English
  /// - fr: French
  ///
  /// The model's language fallback rules are used whenever
  /// a localized field is unavailable.
  @override
  Future<List<QiblaLandmark>> search({
    required String query,
    required String languageCode,
  }) async {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final landmarks = await _getCachedLandmarks();
    final normalizedLanguageCode =
        languageCode.trim().toLowerCase().split('-').first;

    final results = landmarks.where((landmark) {
      final searchableFields = <String>[
        landmark.nameForLanguage(normalizedLanguageCode),
        landmark.descriptionForLanguage(
              normalizedLanguageCode,
            ) ??
            '',
        landmark.cityForLanguage(normalizedLanguageCode) ??
            '',
        landmark.regionForLanguage(normalizedLanguageCode) ??
            '',
        landmark.countryCode,
      ];

      final searchableText = _normalize(
        searchableFields.join(' '),
      );

      return searchableText.contains(normalizedQuery);
    });

    return List.unmodifiable(results);
  }

  /// Clears the in-memory cache.
  ///
  /// The next repository request reloads the local JSON asset.
  void clearCache() {
    _cachedFuture = null;
  }

  /// Normalizes whitespace and letter casing for search.
  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
