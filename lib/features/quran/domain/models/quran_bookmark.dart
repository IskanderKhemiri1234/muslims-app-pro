
class QuranBookmark {
  final String id;
  final int pageNumber;
  final int? surahNumber;
  final int? ayahNumber;
  final DateTime createdAt;
  final String? note;

  QuranBookmark({
    required this.id,
    required this.pageNumber,
    required this.createdAt,
    this.surahNumber,
    this.ayahNumber,
    this.note,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Bookmark ID cannot be empty.');
    }

    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604, 'pageNumber');
    }

    if ((surahNumber == null) != (ayahNumber == null)) {
      throw ArgumentError(
        'Surah number and ayah number must either both be provided or both be null.',
      );
    }

    if (surahNumber != null &&
        (surahNumber < 1 || surahNumber > 114)) {
      throw RangeError.range(surahNumber, 1, 114, 'surahNumber');
    }

    if (ayahNumber != null && ayahNumber < 1) {
      throw RangeError.value(ayahNumber, 'ayahNumber');
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'pageNumber': pageNumber,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'note': note,
    };
  }

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    final Object? rawId = json['id'];
    final Object? rawPage = json['pageNumber'];
    final Object? rawSurah = json['surahNumber'];
    final Object? rawAyah = json['ayahNumber'];
    final Object? rawDate = json['createdAt'];
    final Object? rawNote = json['note'];

    if (rawId is! String ||
        rawPage is! int ||
        rawDate is! String) {
      throw const FormatException(
        'Invalid Quran bookmark data: required fields are missing or have incorrect types.',
      );
    }

    if (rawSurah != null && rawSurah is! int) {
      throw const FormatException(
        'Invalid Quran bookmark data: surahNumber must be an integer or null.',
      );
    }

    if (rawAyah != null && rawAyah is! int) {
      throw const FormatException(
        'Invalid Quran bookmark data: ayahNumber must be an integer or null.',
      );
    }

    if (rawNote != null && rawNote is! String) {
      throw const FormatException(
        'Invalid Quran bookmark data: note must be a string or null.',
      );
    }

    final DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(rawDate).toUtc();
    } on FormatException {
      throw const FormatException(
        'Invalid Quran bookmark data: createdAt is not a valid ISO 8601 date.',
      );
    }

    return QuranBookmark(
      id: rawId,
      pageNumber: rawPage,
      surahNumber: rawSurah as int?,
      ayahNumber: rawAyah as int?,
      createdAt: parsedDate,
      note: rawNote as String?,
    );
  }
}
