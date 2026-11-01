
import '../../domain/models/qibla_landmark.dart';
import '../../domain/repositories/qibla_landmark_repository.dart';
import '../datasources/qibla_landmark_local_data_source.dart';

class QiblaLandmarkRepositoryImpl
    implements QiblaLandmarkRepository {
  QiblaLandmarkRepositoryImpl({
    required QiblaLandmarkLocalDataSource dataSource,
  }) : _dataSource = dataSource;

  final QiblaLandmarkLocalDataSource _dataSource;

  Future<List<QiblaLandmark>>? _cachedFuture;

  /// Loads landmarks once and shares the same pending operation
  /// between simultaneous callers.
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
      // Allow a later request to retry after a failed load.
      if (identical(_cachedFuture, pendingFuture)) {
        _cachedFuture = null;
      }

      rethrow;
    }
  }

  @override
  Future<List<QiblaLandmark>> getAll() async {
    return _getCachedLandmarks();
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

  @override
  Future<List<QiblaLandmark>> search({
    required String query,
    required bool isArabic,
  }) async {
    final normalizedQuery = _normalize(query);

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final landmarks = await _getCachedLandmarks();

    final results = landmarks.where((landmark) {
      final name = landmark.nameForLocale(
        isArabic: isArabic,
      );

      final description = landmark.descriptionForLocale(
        isArabic: isArabic,
      );

      final city = isArabic
          ? landmark.cityAr
          : landmark.cityEn;

      final region = isArabic
          ? landmark.regionAr
          : landmark.regionEn;

      final searchableText = _normalize([
        name,
        description ?? '',
        city ?? '',
        region ?? '',
        landmark.countryCode,
      ].join(' '));

      return searchableText.contains(normalizedQuery);
    });

    return List.unmodifiable(results);
  }

  /// Clears the in-memory cache.
  ///
  /// The next repository request will reload the local JSON asset.
  void clearCache() {
    _cachedFuture = null;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
