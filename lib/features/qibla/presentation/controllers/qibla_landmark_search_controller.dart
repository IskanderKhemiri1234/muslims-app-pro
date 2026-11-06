
import 'package:flutter/foundation.dart';

import '../../../../core/localization/mumin_language_registry.dart';
import '../../domain/models/qibla_landmark.dart';
import '../../domain/repositories/qibla_landmark_repository.dart';

/// Coordinates landmark search for the Qibla experience.
///
/// Responsibilities:
/// - Uses the central Mumin language registry.
/// - Delegates filtering to the domain repository.
/// - Prevents stale asynchronous responses from replacing newer results.
/// - Exposes immutable results and a predictable loading/error state.
/// - Keeps search state independent from presentation widgets.
class QiblaLandmarkSearchController extends ChangeNotifier {
  QiblaLandmarkSearchController({
    required QiblaLandmarkRepository repository,
    String initialLanguageCode = MuminLanguageRegistry.defaultLanguageCode,
  })  : _repository = repository,
        _languageCode =
            MuminLanguageRegistry.normalizeLanguageCode(initialLanguageCode);

  final QiblaLandmarkRepository _repository;

  String _query = '';
  String _languageCode;
  List<QiblaLandmark> _results = const [];
  bool _isLoading = false;
  Object? _error;

  int _requestId = 0;
  bool _isDisposed = false;

  String get query => _query;
  String get languageCode => _languageCode;
  List<QiblaLandmark> get results => _results;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  bool get hasQuery => _query.trim().isNotEmpty;
  bool get hasResults => _results.isNotEmpty;
  bool get hasError => _error != null;
  bool get isEmpty => hasQuery && !_isLoading && !hasError && _results.isEmpty;

  /// Searches using the selected language.
  ///
  /// A newer request invalidates every older request. This prevents a slow
  /// response from overwriting results for a more recent query or language.
  Future<void> search(
    String value, {
    String? languageCode,
  }) async {
    if (_isDisposed) return;

    final normalizedQuery = value.trim();
    final selectedLanguage = MuminLanguageRegistry.normalizeLanguageCode(
      languageCode ?? _languageCode,
    );

    _query = value;
    _languageCode = selectedLanguage;

    final requestId = ++_requestId;

    if (normalizedQuery.isEmpty) {
      _results = const [];
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final found = await _repository.search(
        query: normalizedQuery,
        languageCode: selectedLanguage,
      );

      if (_isDisposed || requestId != _requestId) return;

      _results = List<QiblaLandmark>.unmodifiable(found);
      _error = null;
    } catch (exception) {
      if (_isDisposed || requestId != _requestId) return;

      _results = const [];
      _error = exception;
    } finally {
      if (!_isDisposed && requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Changes the search language and refreshes the current query.
  Future<void> setLanguageCode(String languageCode) async {
    if (_isDisposed) return;

    final normalized = MuminLanguageRegistry.normalizeLanguageCode(
      languageCode,
    );

    if (normalized == _languageCode) return;

    _languageCode = normalized;
    notifyListeners();

    if (hasQuery) {
      await search(_query, languageCode: normalized);
    } else {
      // Invalidate any pending request even when there is no visible query.
      _requestId++;
      _results = const [];
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  /// Clears the query and invalidates any pending repository response.
  void clear() {
    if (_isDisposed) return;

    _requestId++;
    _query = '';
    _results = const [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestId++;
    super.dispose();
  }
}
