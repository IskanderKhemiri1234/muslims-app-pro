
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/quran_bookmark.dart';

class QuranBookmarkLocalDataSource {
  static const String storageKey = 'quran_bookmarks';

  Future<void> _operationQueue = Future<void>.value();

  Future<T> _runQueued<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    _operationQueue = _operationQueue.then((_) async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  Future<SharedPreferences> _preferences() {
    return SharedPreferences.getInstance();
  }

  Future<List<QuranBookmark>> _readAndRepair() async {
    final preferences = await _preferences();
    final storedValues = preferences.getStringList(storageKey);

    if (storedValues == null || storedValues.isEmpty) {
      return <QuranBookmark>[];
    }

    final validBookmarks = <QuranBookmark>[];
    final seenPages = <int>{};
    var storageNeedsRepair = false;

    for (final storedValue in storedValues) {
      try {
        final bookmark = QuranBookmark.fromStorage(storedValue);

        if (seenPages.add(bookmark.pageNumber)) {
          validBookmarks.add(bookmark);
        } else {
          storageNeedsRepair = true;
        }
      } on FormatException {
        storageNeedsRepair = true;
      } on RangeError {
        storageNeedsRepair = true;
      }
    }

    if (storageNeedsRepair) {
      await _writeBookmarks(preferences, validBookmarks);
    }

    return List<QuranBookmark>.unmodifiable(validBookmarks);
  }

  Future<void> _writeBookmarks(
    SharedPreferences preferences,
    List<QuranBookmark> bookmarks,
  ) async {
    final values = bookmarks
        .map((bookmark) => bookmark.toStorage())
        .toList(growable: false);

    final saved = await preferences.setStringList(storageKey, values);

    if (!saved) {
      throw StateError(
        'Unable to save Quran bookmarks to local storage.',
      );
    }
  }

  Future<List<QuranBookmark>> getBookmarks() {
    return _runQueued<List<QuranBookmark>>(_readAndRepair);
  }

  Future<void> addBookmark(QuranBookmark bookmark) {
    return _runQueued<void>(() async {
      final preferences = await _preferences();
      final bookmarks = await _readAndRepair();

      final alreadyExists = bookmarks.any(
        (item) => item.pageNumber == bookmark.pageNumber,
      );

      if (alreadyExists) {
        return;
      }

      final updatedBookmarks = <QuranBookmark>[
        ...bookmarks,
        bookmark,
      ]..sort(
          (first, second) =>
              first.pageNumber.compareTo(second.pageNumber),
        );

      await _writeBookmarks(preferences, updatedBookmarks);
    });
  }

  Future<void> removeBookmark(int pageNumber) {
    return _runQueued<void>(() async {
      if (pageNumber < QuranBookmark.minimumPage ||
          pageNumber > QuranBookmark.maximumPage) {
        throw RangeError.range(
          pageNumber,
          QuranBookmark.minimumPage,
          QuranBookmark.maximumPage,
          'pageNumber',
        );
      }

      final preferences = await _preferences();
      final bookmarks = await _readAndRepair();

      final updatedBookmarks = bookmarks
          .where((bookmark) => bookmark.pageNumber != pageNumber)
          .toList(growable: false);

      if (updatedBookmarks.length == bookmarks.length) {
        return;
      }

      await _writeBookmarks(preferences, updatedBookmarks);
    });
  }

  Future<void> updateBookmark(QuranBookmark bookmark) {
    return _runQueued<void>(() async {
      final preferences = await _preferences();
      final bookmarks = await _readAndRepair();

      final updatedBookmarks = bookmarks
          .where(
            (item) => item.pageNumber != bookmark.pageNumber,
          )
          .toList()
        ..add(bookmark)
        ..sort(
          (first, second) =>
              first.pageNumber.compareTo(second.pageNumber),
        );

      await _writeBookmarks(preferences, updatedBookmarks);
    });
  }
}
