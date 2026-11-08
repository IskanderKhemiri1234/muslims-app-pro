
import '../models/mosque_search_request.dart';
import '../models/mosque_search_result.dart';

/// Mumin Pro — Nearby Mosque Repository Contract.
///
/// Defines the domain-facing contract for worldwide mosque discovery.
/// Implementations belong to the data layer.
///
/// The repository must:
/// - Search only within the requested geographic area.
/// - Respect the requested language and optional search query.
/// - Deduplicate records returned from overlapping geographic tiles.
/// - Report partial results when some tiles fail.
/// - Never fabricate mosque names, addresses, or coordinates.
/// - Never access device GPS automatically.
abstract interface class NearbyMosqueRepository {
  /// Searches for mosques inside the requested map area.
  ///
  /// Throws [ArgumentError] when the request is invalid.
  /// Network and data-source failures should be handled by the
  /// implementation and represented accurately in the result.
  Future<MosqueSearchResult> search(
    MosqueSearchRequest request,
  );
}
