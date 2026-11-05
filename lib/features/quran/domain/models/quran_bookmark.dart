
class QuranBookmark {
  static const int minimumPage = 1;
  static const int maximumPage = 604;

  final int pageNumber;

  const QuranBookmark({
    required this.pageNumber,
  }) : assert(
          pageNumber >= minimumPage &&
              pageNumber <= maximumPage,
          'Quran bookmark page must be between 1 and 604.',
        );

  factory QuranBookmark.fromPage(int page) {
    if (page < minimumPage || page > maximumPage) {
      throw RangeError.range(
        page,
        minimumPage,
        maximumPage,
        'page',
        'Invalid Quran bookmark page.',
      );
    }

    return QuranBookmark(pageNumber: page);
  }

  factory QuranBookmark.fromStorage(String value) {
    final page = int.tryParse(value);

    if (page == null) {
      throw FormatException(
        'Invalid Quran bookmark value: $value',
      );
    }

    return QuranBookmark.fromPage(page);
  }

  String toStorage() => pageNumber.toString();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuranBookmark &&
            other.pageNumber == pageNumber;
  }

  @override
  int get hashCode => pageNumber.hashCode;

  @override
  String toString() {
    return 'QuranBookmark(pageNumber: $pageNumber)';
  }
}
