
class QuranReadingProgress {
  static const int minimumPage = 1;
  static const int maximumPage = 604;

  final int lastReadPage;
  final Set<int> completedPages;
  final int completedKhatmas;
  final Set<int> dailyPages;
  final String dailyDateKey;

  QuranReadingProgress({
    required this.lastReadPage,
    required Set<int> completedPages,
    required this.completedKhatmas,
    required Set<int> dailyPages,
    required this.dailyDateKey,
  })  : completedPages = Set<int>.unmodifiable(completedPages),
        dailyPages = Set<int>.unmodifiable(dailyPages) {
    _validatePage(lastReadPage, 'lastReadPage');
    _validatePages(this.completedPages, 'completedPages');
    _validatePages(this.dailyPages, 'dailyPages');

    if (completedKhatmas < 0) {
      throw RangeError.value(
        completedKhatmas,
        'completedKhatmas',
        'The completed khatmas count cannot be negative.',
      );
    }

    if (!_isValidDateKey(dailyDateKey)) {
      throw FormatException(
        'Invalid daily progress date key: $dailyDateKey',
      );
    }
  }

  factory QuranReadingProgress.empty({
    DateTime? date,
  }) {
    final currentDate = date ?? DateTime.now();

    return QuranReadingProgress(
      lastReadPage: minimumPage,
      completedPages: const <int>{},
      completedKhatmas: 0,
      dailyPages: const <int>{},
      dailyDateKey: dateKeyFor(currentDate),
    );
  }

  static String dateKeyFor(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static bool _isValidDateKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);

    if (match == null) {
      return false;
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);

    if (year == null || month == null || day == null) {
      return false;
    }

    final parsedDate = DateTime(year, month, day);

    return parsedDate.year == year &&
        parsedDate.month == month &&
        parsedDate.day == day;
  }

  static void _validatePage(int page, String field) {
    if (page < minimumPage || page > maximumPage) {
      throw RangeError.range(
        page,
        minimumPage,
        maximumPage,
        field,
        'Quran page must be between 1 and 604.',
      );
    }
  }

  static void _validatePages(Set<int> pages, String field) {
    for (final page in pages) {
      _validatePage(page, field);
    }
  }

  QuranReadingProgress copyWith({
    int? lastReadPage,
    Set<int>? completedPages,
    int? completedKhatmas,
    Set<int>? dailyPages,
    String? dailyDateKey,
  }) {
    return QuranReadingProgress(
      lastReadPage: lastReadPage ?? this.lastReadPage,
      completedPages: completedPages ?? this.completedPages,
      completedKhatmas: completedKhatmas ?? this.completedKhatmas,
      dailyPages: dailyPages ?? this.dailyPages,
      dailyDateKey: dailyDateKey ?? this.dailyDateKey,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! QuranReadingProgress ||
        other.lastReadPage != lastReadPage ||
        other.completedKhatmas != completedKhatmas ||
        other.dailyDateKey != dailyDateKey ||
        other.completedPages.length != completedPages.length ||
        other.dailyPages.length != dailyPages.length) {
      return false;
    }

    return other.completedPages.containsAll(completedPages) &&
        other.dailyPages.containsAll(dailyPages);
  }

  @override
  int get hashCode {
    return Object.hash(
      lastReadPage,
      completedKhatmas,
      dailyDateKey,
      Object.hashAll(completedPages.toList()..sort()),
      Object.hashAll(dailyPages.toList()..sort()),
    );
  }
}
