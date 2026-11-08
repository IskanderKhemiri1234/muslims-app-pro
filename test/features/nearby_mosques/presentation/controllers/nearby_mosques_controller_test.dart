import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_area.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_request.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/mosque_search_result.dart';
import 'package:muslims_app/features/nearby_mosques/domain/models/nearby_mosque.dart';
import 'package:muslims_app/features/nearby_mosques/domain/repositories/nearby_mosque_repository.dart';
import 'package:muslims_app/features/nearby_mosques/presentation/controllers/nearby_mosques_controller.dart';

const _area = MosqueSearchArea(
  south: 33,
  west: -8,
  north: 34,
  east: -7,
);

const _mosque = NearbyMosque(
  id: 'node/123',
  name: 'Test Mosque',
  latitude: 33.5731,
  longitude: -7.5898,
  placeType: MosquePlaceType.mosque,
  source: 'openstreetmap',
);

MosqueSearchResult _result({
  List<NearbyMosque> mosques = const [_mosque],
  int searchedTiles = 1,
  int failedTiles = 0,
}) {
  return MosqueSearchResult(
    requestedArea: _area,
    mosques: mosques,
    searchedTileCount: searchedTiles,
    failedTileCount: failedTiles,
  );
}

class _FakeNearbyMosqueRepository
    implements NearbyMosqueRepository {
  _FakeNearbyMosqueRepository(this.handler);

  final Future<MosqueSearchResult> Function(
    MosqueSearchRequest request,
  ) handler;

  int callCount = 0;

  MosqueSearchRequest? lastRequest;

  @override
  Future<MosqueSearchResult> search(
    MosqueSearchRequest request,
  ) {
    callCount++;
    lastRequest = request;
    return handler(request);
  }
}

void main() {
  group('NearbyMosquesController', () {
    test('starts with an empty idle state', () {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => _result(),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.hasResults, isFalse);
      expect(controller.isEmpty, isFalse);
      expect(controller.isPartial, isFalse);
      expect(controller.resultCount, 0);
      expect(controller.mosques, isEmpty);

      controller.dispose();
    });

    test('notifies listeners while loading and after success', () async {
      final completer = Completer<MosqueSearchResult>();

      final repository = _FakeNearbyMosqueRepository(
        (_) => completer.future,
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      var notifications = 0;
      controller.addListener(() {
        notifications++;
      });

      final searchFuture = controller.search(
        area: _area,
        languageCode: 'ar',
      );

      expect(controller.isLoading, isTrue);
      expect(controller.hasError, isFalse);
      expect(repository.callCount, 1);
      expect(notifications, 1);

      completer.complete(_result());

      await searchFuture;

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.hasResults, isTrue);
      expect(controller.resultCount, 1);
      expect(controller.mosques.single.id, 'node/123');
      expect(notifications, 2);

      controller.dispose();
    });

    test('stores a stable error state when repository fails', () async {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => throw Exception('Network unavailable'),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      await controller.search(
        area: _area,
        languageCode: 'en',
      );

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, 'mosque_search_failed');
      expect(controller.hasResults, isFalse);

      controller.dispose();
    });

    test('does not call repository for an invalid search area', () async {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => _result(),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      await controller.search(
        area: const MosqueSearchArea(
          south: 40,
          west: -8,
          north: 30,
          east: -7,
        ),
        languageCode: 'ar',
      );

      expect(repository.callCount, 0);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isTrue);
      expect(
        controller.errorMessage,
        'Invalid search area or search limit.',
      );

      controller.dispose();
    });

    test('normalizes and forwards the search language and query', () async {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => _result(),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      await controller.search(
        area: _area,
        languageCode: 'fr-FR',
        query: '  Casablanca  ',
        limit: 50,
      );

      expect(repository.lastRequest, isNotNull);
      expect(
        repository.lastRequest!.normalizedLanguageCode,
        'fr',
      );
      expect(
        repository.lastRequest!.normalizedQuery,
        'Casablanca',
      );
      expect(repository.lastRequest!.limit, 50);

      controller.dispose();
    });

    test('clearResults cancels loading and clears previous state', () async {
      final completer = Completer<MosqueSearchResult>();

      final repository = _FakeNearbyMosqueRepository(
        (_) => completer.future,
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      final searchFuture = controller.search(
        area: _area,
        languageCode: 'ar',
      );

      expect(controller.isLoading, isTrue);

      controller.clearResults();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.result, isNull);
      expect(controller.mosques, isEmpty);

      completer.complete(_result());

      await searchFuture;

      expect(controller.result, isNull);
      expect(controller.mosques, isEmpty);
      expect(controller.isLoading, isFalse);

      controller.dispose();
    });

    test('newer search result replaces an older pending search', () async {
      final firstCompleter = Completer<MosqueSearchResult>();
      final secondCompleter = Completer<MosqueSearchResult>();

      var call = 0;

      final repository = _FakeNearbyMosqueRepository(
        (_) {
          call++;
          return call == 1
              ? firstCompleter.future
              : secondCompleter.future;
        },
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      final firstSearch = controller.search(
        area: _area,
        languageCode: 'ar',
      );

      final secondSearch = controller.search(
        area: _area,
        languageCode: 'fr',
      );

      secondCompleter.complete(
        _result(
          mosques: const [
            NearbyMosque(
              id: 'node/222',
              name: 'New Mosque',
              latitude: 33.6,
              longitude: -7.6,
              placeType: MosquePlaceType.mosque,
              source: 'openstreetmap',
            ),
          ],
        ),
      );

      await secondSearch;

      expect(controller.mosques.single.id, 'node/222');

      firstCompleter.complete(_result());

      await firstSearch;

      expect(controller.mosques.single.id, 'node/222');
      expect(controller.isLoading, isFalse);

      controller.dispose();
    });

    test('retry repeats the most recent valid search', () async {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => _result(),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      await controller.search(
        area: _area,
        languageCode: 'en',
        query: 'mosque',
      );

      expect(repository.callCount, 1);

      await controller.retry();

      expect(repository.callCount, 2);
      expect(
        repository.lastRequest!.normalizedQuery,
        'mosque',
      );

      controller.dispose();
    });

    test('reports partial results from the repository', () async {
      final repository = _FakeNearbyMosqueRepository(
        (_) async => _result(
          mosques: const [_mosque],
          searchedTiles: 3,
          failedTiles: 1,
        ),
      );

      final controller = NearbyMosquesController(
        repository: repository,
      );

      await controller.search(
        area: _area,
        languageCode: 'ar',
      );

      expect(controller.hasResults, isTrue);
      expect(controller.isPartial, isTrue);
      expect(controller.resultCount, 1);

      controller.dispose();
    });
  });
}
