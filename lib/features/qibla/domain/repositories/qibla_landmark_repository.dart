
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

  /// Searches landmark information in the requested language.
  ///
  /// The language code is expected to be one of the application's
  /// registered launch languages: ar, en, or fr.
  ///
  /// Implementations must use the model's language-aware fallback
  /// rules when a translated field is unavailable.
  ///
  /// Search normalization should trim whitespace, collapse repeated
  /// spaces, and compare case-insensitively where applicable.
  Future<List<QiblaLandmark>> search({
    required String query,
    required String languageCode,
  });
}
