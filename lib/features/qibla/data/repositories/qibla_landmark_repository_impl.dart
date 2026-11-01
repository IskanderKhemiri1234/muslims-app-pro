
import '../../domain/models/qibla_landmark.dart';
import '../../domain/repositories/qibla_landmark_repository.dart';
import '../datasources/qibla_landmark_local_data_source.dart';

/// Local implementation of the Qibla landmark repository.
class QiblaLandmarkRepositoryImpl
    implements QiblaLandmarkRepository {
  QiblaLandmarkRepositoryImpl({
    required QiblaLandmarkLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final QiblaLandmarkLocalDataSource _localDataSource;

  List<QiblaLandmark>? _cachedLandmarks;

  /// Loads landmarks once and reuses the in-memory result.
  Future<List<QiblaLandmark>> _getLandmarks() async {
    return _cachedLandmarks ??= await _localDataSource.loadLandmarks();
  }

  @override
  Future<List<QiblaLandmark>> getAll() async {
    final landmarks = await _getLandmarks();

    return List<QiblaLandmark>.unmodifiable(landmarks);
  }

  @override
  Future<List<QiblaLandmark>> getFeatured() async {
    final landmarks = await _getLandmarks();

    return List<QiblaLandmark>.unmodifiable(
      landmarks.where((landmark) => landmark.isFeatured),
    );
  }

  @override
  Future<QiblaLandmark?> getById(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) return null;

    final landmarks = await _getLandmarks();

    for (final landmark in landmarks) {
      if (landmark.id == normalizedId) {
        return landmark;
      }
    }

    return null;
  }

  @override
  Future<List<QiblaLandmark>> getByCategory(
    QiblaLandmarkCategory category,
  ) async {
    final landmarks = await _getLandmarks();

    return List<QiblaLandmark>.unmodifiable(
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
    final normalizedQuery = _normalizeSearchText(query);

    if (normalizedQuery.isEmpty) {
      return const <QiblaLandmark>[];
    }

    final landmarks = await _getLandmarks();

    final results = landmarks.where((landmark) {
      final name = landmark.nameForLocale(isArabic: isArabic);
      final description =
          landmark.descriptionForLocale(isArabic: isArabic);

      final normalizedName = _normalizeSearchText(name);
      final normalizedDescription =
          _normalizeSearchText(description ?? '');

      return normalizedName.contains(normalizedQuery) ||
          normalizedDescription.contains(normalizedQuery);
    });

    return List<QiblaLandmark>.unmodifiable(results);
  }

  /// Normalizes whitespace and letter case for search.
  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Clears the in-memory cache.
  ///
  /// Useful when the local data source is replaced or refreshed.
  void clearCache() {
    _cachedLandmarks = null;
  }
}
