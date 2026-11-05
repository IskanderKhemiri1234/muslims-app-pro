
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/quran_reading_progress.dart';

class QuranReadingProgressLocalDataSource {
  static const String lastReadPageKey = 'quran_last_read_page';
  static const String completedPagesKey = 'quran_completed_pages';
  static const String completedKhatmasKey = 'quran_completed_khatmas';
  static const String dailyPagesKeyPrefix = 'quran_daily_pages_';

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

  String _dailyKey(String dateKey) {
    return '$dailyPagesKeyPrefix$dateKey';
  }

  Future<int> _readInteger({
    required SharedPreferences preferences,
    required String key,
    required int defaultValue,
    required bool Function(int value) isValid,
  }) async {
    final storedValue = preferences.get(key);

    int? parsedValue;

    if (storedValue is int) {
      parsedValue = storedValue;
    } else if (storedValue is String) {
      parsedValue = int.tryParse(storedValue);
    }

    if (parsedValue != null && isValid(parsedValue)) {
      return parsedValue;
    }

    await _writeInteger(
      preferences: preferences,
      key: key,
      value: defaultValue,
    );

    return defaultValue;
  }

  Future<Set<int>> _readPageSet({
    required SharedPreferences preferences,
    required String key,
  }) async {
    final storedValue = preferences.get(key);

    if (storedValue == null) {
      return <int>{};
    }

    if (storedValue is! List) {
      await _writePageSet(
        preferences: preferences,
        key: key,
        pages: <int>{},
      );
      return <int>{};
    }

    final validPages = <int>{};
    var storageNeedsRepair = false;

    for (final item in storedValue) {
      int? page;

      if (item is String) {
        page = int.tryParse(item);
      } else if (item is int) {
        page = item;
      }

      if (page == null ||
          page < QuranReadingProgress.minimumPage ||
          page > QuranReadingProgress.maximumPage) {
        storageNeedsRepair = true;
        continue;
      }

      if (!validPages.add(page)) {
        storageNeedsRepair = true;
      }
    }

    if (storageNeedsRepair) {
      await _writePageSet(
        preferences: preferences,
        key: key,
        pages: validPages,
      );
    }

    return validPages;
  }

  Future<void> _writeInteger({
    required SharedPreferences preferences,
    required String key,
    required int value,
  }) async {
    final saved = await preferences.setInt(key, value);

    if (!saved) {
      throw StateError('Unable to save Quran progress value: $key');
    }
  }

  Future<void> _writePageSet({
    required SharedPreferences preferences,
    required String key,
    required Set<int> pages,
  }) async {
    final values = pages.toList()..sort();
    final storedValues = values
        .map((page) => page.toString())
        .toList(growable: false);

    final saved = await preferences.setStringList(key, storedValues);

    if (!saved) {
      throw StateError('Unable to save Quran progress pages: $key');
    }
  }

  Future<QuranReadingProgress> _readProgress({
    required DateTime date,
  }) async {
    final preferences = await _preferences();
    final dateKey = QuranReadingProgress.dateKeyFor(date);
    final dailyKey = _dailyKey(dateKey);

    final lastReadPage = await _readInteger(
      preferences: preferences,
      key: lastReadPageKey,
      defaultValue: QuranReadingProgress.minimumPage,
      isValid: (value) =>
          value >= QuranReadingProgress.minimumPage &&
          value <= QuranReadingProgress.maximumPage,
    );

    final completedKhatmas = await _readInteger(
      preferences: preferences,
      key: completedKhatmasKey,
      defaultValue: 0,
      isValid: (value) => value >= 0,
    );

    final completedPages = await _readPageSet(
      preferences: preferences,
      key: completedPagesKey,
    );

    final dailyPages = await _readPageSet(
      preferences: preferences,
      key: dailyKey,
    );

    return QuranReadingProgress(
      lastReadPage: lastReadPage,
      completedPages: completedPages,
      completedKhatmas: completedKhatmas,
      dailyPages: dailyPages,
      dailyDateKey: dateKey,
    );
  }

  Future<void> _saveProgress(
    QuranReadingProgress progress,
  ) async {
    final preferences = await _preferences();

    await _writeInteger(
      preferences: preferences,
      key: lastReadPageKey,
      value: progress.lastReadPage,
    );

    await _writePageSet(
      preferences: preferences,
      key: completedPagesKey,
      pages: progress.completedPages,
    );

    await _writeInteger(
      preferences: preferences,
      key: completedKhatmasKey,
      value: progress.completedKhatmas,
    );

    await _writePageSet(
      preferences: preferences,
      key: _dailyKey(progress.dailyDateKey),
      pages: progress.dailyPages,
    );
  }

  Future<QuranReadingProgress> getProgress({
    DateTime? date,
  }) {
    return _runQueued<QuranReadingProgress>(
      () => _readProgress(date: date ?? DateTime.now()),
    );
  }

  Future<void> saveProgress(QuranReadingProgress progress) {
    return _runQueued<void>(() => _saveProgress(progress));
  }
}
