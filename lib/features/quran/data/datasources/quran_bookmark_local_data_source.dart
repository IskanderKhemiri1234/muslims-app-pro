
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslims_app/features/quran/domain/models/quran_bookmark.dart';

/// Local persistence for Quran bookmarks.
///
/// Responsibilities:
/// - Read and save bookmarks using SharedPreferences.
/// - Preserve the existing storage key and serialization format.
/// - Ignore malformed bookmark entries without losing valid entries.
/// - Remove duplicate and invalid page numbers.
/// - Serialize write operations to avoid concurrent storage conflicts.
class QuranBookmarkLocalDataSource {
  static const String bookmarksKey = 'quran_bookmarks';

  Future<void> _operationQueue = Future<void>.value();

  /// Returns all valid bookmarks.
  ///
  /// Malformed entries are discarded individually.
  /// Valid entries are preserved and the stored list is repaired.
  Future<List<QuranBookmark>> getBookmarks() {
    return _serialize<List<QuranBookmark>>(() async {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final List<String>? storedValues =
          preferences.getStringList(bookmarksKey);

      if (storedValues == null || storedValues.isEmpty) {
        return <QuranBookmark>[];
      }

      final Map<int, QuranBookmark> validBookmarks =
          <int, QuranBookmark>{};

      bool requiresRepair = false;

      for (final String storedValue in storedValues) {
        try {
          final QuranBookmark bookmark =
              QuranBookmark.fromStorage(storedValue);

          final int pageNumber = bookmark.pageNumber;

          if (pageNumber < 1 || pageNumber > 604) {
            requiresRepair = true;
            continue;
          }

          if (validBookmarks.containsKey(pageNumber)) {
            requiresRepair = true;
            continue;
          }

          validBookmarks[pageNumber] = bookmark;
        } catch (_) {
          requiresRepair = true;
        }
      }

      final List<QuranBookmark> bookmarks =
          validBookmarks.values.toList()
            ..sort(
              (QuranBookmark first, QuranBookmark second) =>
                  first.pageNumber.compareTo(second.pageNumber),
            );

      if (requiresRepair) {
        await _writeBookmarks(preferences, bookmarks);
      }

      return List<QuranBookmark>.unmodifiable(bookmarks);
    });
  }

  /// Adds a bookmark if its page does not already exist.
  ///
  /// Existing bookmarks are preserved.
  Future<void> addBookmark(QuranBookmark bookmark) {
    return _serialize<void>(() async {
      _validateBookmark(bookmark);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final List<QuranBookmark> bookmarks =
          await _readValidBookmarks(preferences);

      final bool alreadyExists = bookmarks.any(
        (QuranBookmark item) =>
            item.pageNumber == bookmark.pageNumber,
      );

      if (alreadyExists) {
        return;
      }

      bookmarks.add(bookmark);

      await _writeBookmarks(preferences, bookmarks);
    });
  }

  /// Removes the bookmark associated with [pageNumber].
  ///
  /// Invalid page numbers are rejected.
  Future<void> removeBookmark(int pageNumber) {
    return _serialize<void>(() async {
      _validatePageNumber(pageNumber);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final List<QuranBookmark> bookmarks =
          await _readValidBookmarks(preferences);

      bookmarks.removeWhere(
        (QuranBookmark bookmark) =>
            bookmark.pageNumber == pageNumber,
      );

      await _writeBookmarks(preferences, bookmarks);
    });
  }

  /// Updates an existing bookmark or adds it if it does not exist.
  ///
  /// The current QuranBookmark model contains only a page number,
  /// so updating a bookmark means ensuring that its page is stored.
  Future<void> updateBookmark(QuranBookmark bookmark) {
    return _serialize<void>(() async {
      _validateBookmark(bookmark);

      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final List<QuranBookmark> bookmarks =
          await _readValidBookmarks(preferences);

      final int existingIndex = bookmarks.indexWhere(
        (QuranBookmark item) =>
            item.pageNumber == bookmark.pageNumber,
      );

      if (existingIndex == -1) {
        bookmarks.add(bookmark);
      } else {
        bookmarks[existingIndex] = bookmark;
      }

      await _writeBookmarks(preferences, bookmarks);
    });
  }

  /// Reads valid entries and repairs corrupted storage when necessary.
  Future<List<QuranBookmark>> _readValidBookmarks(
    SharedPreferences preferences,
  ) async {
    final List<String>? storedValues =
        preferences.getStringList(bookmarksKey);

    if (storedValues == null || storedValues.isEmpty) {
      return <QuranBookmark>[];
    }

    final Map<int, QuranBookmark> validBookmarks =
        <int, QuranBookmark>{};

    bool requiresRepair = false;

    for (final String storedValue in storedValues) {
      try {
        final QuranBookmark bookmark =
            QuranBookmark.fromStorage(storedValue);

        final int pageNumber = bookmark.pageNumber;

        if (pageNumber < 1 || pageNumber > 604) {
          requiresRepair = true;
          continue;
        }

        if (validBookmarks.containsKey(pageNumber)) {
          requiresRepair = true;
          continue;
        }

        validBookmarks[pageNumber] = bookmark;
      } catch (_) {
        requiresRepair = true;
      }
    }

    final List<QuranBookmark> bookmarks =
        validBookmarks.values.toList()
          ..sort(
            (QuranBookmark first, QuranBookmark second) =>
                first.pageNumber.compareTo(second.pageNumber),
          );

    if (requiresRepair) {
      await _writeBookmarks(preferences, bookmarks);
    }

    return bookmarks;
  }

  /// Writes bookmarks in a deterministic order.
  ///
  /// The existing SharedPreferences key and model serialization
  /// format are preserved.
  Future<void> _writeBookmarks(
    SharedPreferences preferences,
    List<QuranBookmark> bookmarks,
  ) async {
    final List<QuranBookmark> sortedBookmarks =
        List<QuranBookmark>.of(bookmarks)
          ..sort(
            (QuranBookmark first, QuranBookmark second) =>
                first.pageNumber.compareTo(second.pageNumber),
          );

    final Set<int> seenPages = <int>{};
    final List<String> serializedBookmarks = <String>[];

    for (final QuranBookmark bookmark in sortedBookmarks) {
      _validateBookmark(bookmark);

      if (!seenPages.add(bookmark.pageNumber)) {
        continue;
      }

      serializedBookmarks.add(bookmark.toStorage());
    }

    final bool saved = await preferences.setStringList(
      bookmarksKey,
      serializedBookmarks,
    );

    if (!saved) {
      throw StateError(
        'Failed to save Quran bookmarks to SharedPreferences.',
      );
    }
  }

  /// Validates a bookmark before saving it.
  void _validateBookmark(QuranBookmark bookmark) {
    _validatePageNumber(bookmark.pageNumber);
  }

  /// Valid Quran page numbers range from 1 to 604.
  void _validatePageNumber(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(
        pageNumber,
        1,
        604,
        'pageNumber',
        'Quran page number must be between 1 and 604.',
      );
    }
  }

  /// Serializes asynchronous operations to prevent overlapping writes.
  ///
  /// An unsuccessful operation does not block subsequent operations.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final Completer<T> completer = Completer<T>();

    _operationQueue = _operationQueue.then((_) async {
      try {
        final T result = await operation();
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }
}
