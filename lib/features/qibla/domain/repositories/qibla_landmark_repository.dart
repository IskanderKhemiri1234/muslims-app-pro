
import '../models/qibla_landmark.dart';

/// Contract for retrieving verified Qibla Atlas landmarks.
///
/// Implementations belong to the data layer.
/// This domain contract must not depend on Flutter, storage,
/// network clients, or map-rendering packages.
abstract interface class QiblaLandmarkRepository {
  /// Returns all available landmarks.
  ///
  /// The implementation must return only records that pass
  /// runtime data validation.
  Future<List<QiblaLandmark>> getAll();

  /// Returns featured landmarks for the atlas overview.
  Future<List<QiblaLandmark>> getFeatured();

  /// Finds a landmark using its stable identifier.
  ///
  /// Returns null when no matching landmark exists.
  Future<QiblaLandmark?> getById(String id);

  /// Returns landmarks matching the requested category.
  Future<List<QiblaLandmark>> getByCategory(
    QiblaLandmarkCategory category,
  );

  /// Searches landmark names in the requested language.
  ///
  /// Implementations should normalize whitespace and
  /// perform case-insensitive matching where applicable.
  Future<List<QiblaLandmark>> search({
    required String query,
    required bool isArabic,
  });
}
