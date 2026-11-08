
import 'mosque_search_area.dart';
import 'nearby_mosque.dart';

/// Mumin Pro — Nearby Mosques Search Result.
///
/// Holds deduplicated mosque records and reports whether all requested
/// geographic tiles were searched successfully.
final class MosqueSearchResult {
  MosqueSearchResult({
    required this.requestedArea,
    required Iterable<NearbyMosque> mosques,
    this.searchedTileCount = 0,
    this.failedTileCount = 0,
  }) : mosques = _uniqueMosques(mosques);

  /// Geographic area originally requested by the user.
  final MosqueSearchArea requestedArea;

  /// Unique mosque records returned by the data source.
  final List<NearbyMosque> mosques;

  /// Number of geographic tiles searched successfully.
  final int searchedTileCount;

  /// Number of geographic tiles that could not be searched.
  final int failedTileCount;

  /// True when at least one tile failed or no tile was searched.
  bool get isPartial =>
      failedTileCount > 0 || searchedTileCount == 0;

  /// True when every attempted tile was searched successfully.
  bool get isComplete =>
      searchedTileCount > 0 && failedTileCount == 0;

  /// Number of unique mosque records returned.
  int get resultCount => mosques.length;

  /// Creates a result with updated values.
  MosqueSearchResult copyWith({
    MosqueSearchArea? requestedArea,
    Iterable<NearbyMosque>? mosques,
    int? searchedTileCount,
    int? failedTileCount,
  }) {
    return MosqueSearchResult(
      requestedArea: requestedArea ?? this.requestedArea,
      mosques: mosques ?? this.mosques,
      searchedTileCount: searchedTileCount ?? this.searchedTileCount,
      failedTileCount: failedTileCount ?? this.failedTileCount,
    );
  }

  static List<NearbyMosque> _uniqueMosques(
    Iterable<NearbyMosque> records,
  ) {
    final unique = <String, NearbyMosque>{};

    for (final mosque in records) {
      if (!mosque.isValid) {
        continue;
      }

      final identity = mosque.id.trim();
      if (identity.isEmpty) {
        continue;
      }

      unique.putIfAbsent(identity, () => mosque);
    }

    return List<NearbyMosque>.unmodifiable(unique.values);
  }
}
