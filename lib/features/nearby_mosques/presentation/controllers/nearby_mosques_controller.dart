
import 'package:flutter/foundation.dart';

import '../../data/services/nearby_mosque_search_service.dart';
import '../../domain/models/mosque_search_area.dart';
import '../../domain/models/mosque_search_request.dart';
import '../../domain/models/mosque_search_result.dart';
import '../../domain/repositories/nearby_mosque_repository.dart';

/// Mumin Pro — Nearby Mosques Presentation Controller.
///
/// Manages search state independently from map rendering.
/// It never requests device location or accesses GPS.
final class NearbyMosquesController extends ChangeNotifier {
  NearbyMosquesController({
    NearbyMosqueRepository? repository,
  }) : _repository =
           repository ?? NearbyMosqueSearchService();

  final NearbyMosqueRepository _repository;

  MosqueSearchResult? _result;
  MosqueSearchRequest? _lastRequest;

  bool _isLoading = false;
  bool _isDisposed = false;

  String? _errorMessage;

  int _searchGeneration = 0;

  MosqueSearchResult? get result => _result;

  List get mosques =>
      _result?.mosques ?? const [];

  bool get isLoading => _isLoading;

  bool get hasError => _errorMessage != null;

  String? get errorMessage => _errorMessage;

  bool get hasResults =>
      _result != null && _result!.mosques.isNotEmpty;

  bool get isEmpty =>
      !_isLoading &&
      _result != null &&
      _result!.mosques.isEmpty;

  bool get isPartial =>
      _result?.isPartial ?? false;

  int get resultCount =>
      _result?.resultCount ?? 0;

  /// Searches only the geographic area explicitly selected
  /// by the user on the map.
  Future<void> search({
    required MosqueSearchArea area,
    required String languageCode,
    String? query,
    int limit = 100,
  }) async {
    final request = MosqueSearchRequest(
      area: area,
      query: query,
      languageCode: languageCode,
      limit: limit,
    );

    if (!request.isValid) {
      _setError(
        'Invalid search area or search limit.',
      );
      return;
    }

    await _executeSearch(request);
  }

  /// Repeats the most recent valid search.
  Future<void> retry() async {
    final request = _lastRequest;

    if (request == null || _isDisposed) {
      return;
    }

    await _executeSearch(request);
  }

  Future<void> _executeSearch(
    MosqueSearchRequest request,
  ) async {
    if (_isDisposed) return;

    final generation = ++_searchGeneration;

    _lastRequest = request;

    _isLoading = true;
    _errorMessage = null;

    _notifySafely();

    try {
      final result = await _repository.search(request);

      if (!_isCurrentSearch(generation)) {
        return;
      }

      _result = result;
      _isLoading = false;
      _errorMessage = null;

      _notifySafely();
    } catch (error, stackTrace) {
      debugPrint(
        'Nearby mosques search failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!_isCurrentSearch(generation)) {
        return;
      }

      _isLoading = false;
      _errorMessage = 'mosque_search_failed';

      _notifySafely();
    }
  }

  /// Clears displayed results and search errors.
  void clearResults() {
    if (_isDisposed) return;

    _searchGeneration++;

    _result = null;
    _lastRequest = null;
    _errorMessage = null;
    _isLoading = false;

    _notifySafely();
  }

  void _setError(String message) {
    if (_isDisposed) return;

    _isLoading = false;
    _errorMessage = message;

    _notifySafely();
  }

  bool _isCurrentSearch(int generation) {
    return !_isDisposed &&
        generation == _searchGeneration;
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _searchGeneration++;

    final repository = _repository;

    if (repository is NearbyMosqueSearchService) {
      repository.close();
    }

    super.dispose();
  }
}
