import 'dart:convert';
import 'package:flutter/services.dart';

/// Bundled, offline-first source for the complete three-language Quran.
///
/// All 114 surahs are embedded in the application. The CI asset generator
/// validates every Arabic verse against the official Hafs v20 CSV and checks
/// both QuranEnc translations before the APK is built.
class QuranTrilingualDataSource {
  const QuranTrilingualDataSource();
  static const String arabicSource = 'QuranEnc.com / King Fahd Complex / Uthmanic Hafs v20';
  static const String englishTranslationInfo =
      'Translation of the meanings of the Noble Quran; Language: English; Translation ID: english_saheeh; Publisher: Saheeh International / Noor International Center; Source: QuranEnc.com; Version: 1.1.2.';
  static const String frenchTranslationInfo =
      'Traduction du sens des versets du Noble Coran; Language: French; Translation ID: french_rashid; Translator: Rachid Maach; Publisher: Rowwad Translation Center; Source: QuranEnc.com; Version: 1.0.3.';
  static const String englishKey = 'english_saheeh';
  static const String englishVersion = '1.1.2';
  static const String englishPublisher = 'Saheeh International / Noor International Center';
  static const String frenchKey = 'french_rashid';
  static const String frenchVersion = '1.0.3';
  static const String frenchPublisher = 'Rachid Maach / Rowwad Translation Center';
  static const int expectedTotalAyahs = 6236;
  static const List<int> expectedAyahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111,
    43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64,
    77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83,
    182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
    18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28,
    20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25,
    22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19,
    5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
  ];

  Future<QuranTrilingualSurah> getSurah(int surahNumber) async {
    _validateSurah(surahNumber);
    final assetPath = 'assets/quran_trilingual/data/surahs/'
        'surah_${surahNumber.toString().padLeft(3, '0')}.json';
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Bundled Quran surah $surahNumber is invalid.');
    }
    final surah = QuranTrilingualSurah.fromJson(decoded);
    if (surah.number != surahNumber ||
        surah.englishVersion != englishVersion ||
        surah.frenchVersion != frenchVersion) {
      throw FormatException(
        'Bundled Quran source/version mismatch for surah $surahNumber.',
      );
    }
    return surah;
  }

  Future<bool> isCompleteOffline() async {
    var totalAyahs = 0;
    try {
      for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
        final surah = await getSurah(surahNumber);
        totalAyahs += surah.verses.length;
      }
    } catch (_) {
      return false;
    }
    return totalAyahs == expectedTotalAyahs;
  }

  Future<void> downloadCompleteQuran({
    required void Function(int completedSurahs, int totalSurahs) onProgress,
  }) async {
    var totalAyahs = 0;
    for (var surahNumber = 1; surahNumber <= 114; surahNumber++) {
      final surah = await getSurah(surahNumber);
      totalAyahs += surah.verses.length;
      onProgress(surahNumber, 114);
    }
    if (totalAyahs != expectedTotalAyahs) {
      throw StateError('The bundled Quran dataset is incomplete.');
    }
  }

  Future<void> dispose() async {}

  void _validateSurah(int surah) {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }
  }
}

class QuranTrilingualSurah {
  const QuranTrilingualSurah({
    required this.number,
    required this.verses,
    required this.englishVersion,
    required this.frenchVersion,
  });

  final int number;
  final List<QuranTrilingualAyah> verses;
  final String englishVersion;
  final String frenchVersion;

  Map<String, dynamic> toJson() => {
        'number': number,
        'englishVersion': englishVersion,
        'frenchVersion': frenchVersion,
        'arabicSource': QuranTrilingualDataSource.arabicSource,
        'englishPublisher': QuranTrilingualDataSource.englishPublisher,
        'frenchPublisher': QuranTrilingualDataSource.frenchPublisher,
        'englishTranslationInfo': QuranTrilingualDataSource.englishTranslationInfo,
        'frenchTranslationInfo': QuranTrilingualDataSource.frenchTranslationInfo,
        'verses': verses.map((verse) => verse.toJson()).toList(),
      };

  factory QuranTrilingualSurah.fromJson(Map<String, dynamic> json) {
    final raw = json['verses'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('Bundled surah has no verses.');
    }
    final number = json['number'];
    if (number is! int || number < 1 || number > 114) {
      throw const FormatException('Bundled surah number is invalid.');
    }
    final verses = raw
        .map((item) => QuranTrilingualAyah.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList(growable: false);
    if (verses.length != QuranTrilingualDataSource.expectedAyahCounts[number - 1]) {
      throw const FormatException('Bundled surah ayah count is invalid.');
    }
    for (var i = 0; i < verses.length; i++) {
      if (verses[i].surahNumber != number || verses[i].ayahNumber != i + 1) {
        throw const FormatException('Bundled verse sequence is invalid.');
      }
    }
    return QuranTrilingualSurah(
      number: number,
      verses: List.unmodifiable(verses),
      englishVersion: json['englishVersion'] as String? ?? '',
      frenchVersion: json['frenchVersion'] as String? ?? '',
    );
  }
}

class QuranTrilingualAyah {
  const QuranTrilingualAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.english,
    required this.french,
    this.englishFootnotes = '',
    this.frenchFootnotes = '',
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String english;
  final String french;
  final String englishFootnotes;
  final String frenchFootnotes;

  Map<String, dynamic> toJson() => {
        'surah': surahNumber,
        'ayah': ayahNumber,
        'arabic': arabic,
        'english': english,
        'french': french,
        'englishFootnotes': englishFootnotes,
        'frenchFootnotes': frenchFootnotes,
      };

  factory QuranTrilingualAyah.fromJson(Map<String, dynamic> json) {
    final surah = json['surah'];
    final ayah = json['ayah'];
    final arabic = json['arabic'];
    final english = json['english'];
    final french = json['french'];
    final englishFootnotes = json['englishFootnotes'] ?? '';
    final frenchFootnotes = json['frenchFootnotes'] ?? '';
    if (surah is! int ||
        ayah is! int ||
        arabic is! String ||
        english is! String ||
        french is! String ||
        englishFootnotes is! String ||
        frenchFootnotes is! String ||
        arabic.isEmpty ||
        english.isEmpty ||
        french.isEmpty) {
      throw const FormatException('Bundled Quran verse is invalid.');
    }
    return QuranTrilingualAyah(
      surahNumber: surah,
      ayahNumber: ayah,
      arabic: arabic,
      english: english,
      french: french,
      englishFootnotes: englishFootnotes,
      frenchFootnotes: frenchFootnotes,
    );
  }
}
