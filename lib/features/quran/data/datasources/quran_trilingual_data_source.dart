import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Offline-first source for the three-column Quran reader.
///
/// Arabic text and both translations are fetched from QuranEnc and kept
/// verbatim. A complete surah is written atomically only after every verse
/// has passed alignment checks.
class QuranTrilingualDataSource {
  QuranTrilingualDataSource({http.Client? client})
      : _client = client ?? http.Client();

  static const String _baseUrl = 'https://quranenc.com/api/v1';
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

  final http.Client _client;
  Future<Map<String, String>>? _arabicTextFuture;

  Future<Directory> _cacheDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/mumin_quran_trilingual_v1');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  File _fileFor(Directory directory, int surah) =>
      File("${directory.path}/surah_${surah.toString().padLeft(3, '0')}.json");

  Future<QuranTrilingualSurah> getSurah(int surahNumber) async {
    _validateSurah(surahNumber);
    final directory = await _cacheDirectory();
    final file = _fileFor(directory, surahNumber);

    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        final cached = QuranTrilingualSurah.fromJson(
          decoded as Map<String, dynamic>,
        );
        if (cached.englishVersion == englishVersion &&
            cached.frenchVersion == frenchVersion) {
          return cached;
        }
        await file.delete();
      } catch (_) {
        // A damaged cache is removed and fetched again.
        await file.delete();
      }
    }

    final surah = await _downloadSurah(surahNumber);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(surah.toJson()),
      flush: true,
    );
    await temporary.rename(file.path);
    return surah;
  }

  Future<QuranTrilingualSurah> _downloadSurah(int surahNumber) async {
    final responses = await Future.wait([
      _getTranslation(englishKey, surahNumber),
      _getTranslation(frenchKey, surahNumber),
    ]);

    final englishRows = responses[0];
    final frenchRows = responses[1];

    if (englishRows.isEmpty || englishRows.length != frenchRows.length) {
      throw const FormatException('Quran translation verse counts do not match.');
    }

    final canonicalArabicText = await _loadCanonicalArabicText();
    final verses = <QuranTrilingualAyah>[];
    for (var index = 0; index < englishRows.length; index++) {
      final en = englishRows[index];
      final fr = frenchRows[index];

      final enSurah = _asInt(en['sura']);
      final frSurah = _asInt(fr['sura']);
      final enAyah = _asInt(en['aya']);
      final frAyah = _asInt(fr['aya']);
      final englishArabic = en['arabic_text'];
      final frenchArabic = fr['arabic_text'];
      final arabic = canonicalArabicText['$surahNumber:${index + 1}'];
      final english = en['translation'];
      final french = fr['translation'];
      final englishFootnotes = en['footnotes'] ?? '';
      final frenchFootnotes = fr['footnotes'] ?? '';

      if (enSurah != surahNumber ||
          frSurah != surahNumber ||
          enAyah != index + 1 ||
          frAyah != index + 1 ||
          arabic is! String ||
          englishArabic is! String ||
          frenchArabic is! String ||
          arabic != englishArabic ||
          arabic != frenchArabic ||
          english is! String ||
          french is! String ||
          englishFootnotes is! String ||
          frenchFootnotes is! String ||
          english.trim().isEmpty ||
          french.trim().isEmpty) {
        throw FormatException(
          'Verse alignment validation failed at $surahNumber:${index + 1}.',
        );
      }

      verses.add(QuranTrilingualAyah(
        surahNumber: surahNumber,
        ayahNumber: index + 1,
        arabic: arabic,
        english: english,
        french: french,
        englishFootnotes: englishFootnotes,
        frenchFootnotes: frenchFootnotes,
      ));
    }

    if (verses.length != expectedAyahCounts[surahNumber - 1]) {
      throw FormatException('Unexpected ayah count for surah $surahNumber.');
    }

    return QuranTrilingualSurah(
      number: surahNumber,
      verses: List.unmodifiable(verses),
      englishVersion: englishVersion,
      frenchVersion: frenchVersion,
    );
  }

  Future<Map<String, String>> _loadCanonicalArabicText() {
    return _arabicTextFuture ??= _readCanonicalArabicText();
  }

  Future<Map<String, String>> _readCanonicalArabicText() async {
    final raw = await rootBundle.loadString(
      'assets/quran_trilingual/data/Quran_text.csv',
    );
    final lines = const LineSplitter()
        .convert(raw.replaceFirst('\uFEFF', ''))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const FormatException('The bundled canonical Quran text is empty.');
    }

    final firstRow = _parseCsvLine(lines.first);
    final hasHeader = firstRow.isNotEmpty &&
        firstRow.first.trim().toLowerCase() == 'id';
    final firstDataRow = hasHeader ? 1 : 0;
    final arabicByVerse = <String, String>{};

    for (var rowIndex = firstDataRow; rowIndex < lines.length; rowIndex++) {
      final fields = _parseCsvLine(lines[rowIndex]);
      if (fields.length != 4) {
        throw FormatException('Invalid canonical Quran CSV row: ${rowIndex + 1}.');
      }
      final surah = int.tryParse(fields[1].trim());
      final ayah = int.tryParse(fields[2].trim());
      final text = fields[3];
      if (surah == null ||
          ayah == null ||
          surah < 1 ||
          surah > 114 ||
          ayah < 1 ||
          ayah > expectedAyahCounts[surah - 1] ||
          text.trim().isEmpty) {
        throw FormatException('Invalid canonical Quran verse at CSV row ${rowIndex + 1}.');
      }
      final key = '$surah:$ayah';
      if (arabicByVerse.containsKey(key)) {
        throw FormatException('Duplicate canonical Quran verse $key.');
      }
      arabicByVerse[key] = text;
    }

    if (arabicByVerse.length != expectedTotalAyahs) {
      throw FormatException(
        'Canonical Quran text contains ${arabicByVerse.length} verses; '
        'expected $expectedTotalAyahs.',
      );
    }

    for (var surah = 1; surah <= 114; surah++) {
      for (var ayah = 1; ayah <= expectedAyahCounts[surah - 1]; ayah++) {
        if (!arabicByVerse.containsKey('$surah:$ayah')) {
          throw FormatException('Canonical Quran text is missing $surah:$ayah.');
        }
      }
    }

    return Map<String, String>.unmodifiable(arabicByVerse);
  }

  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final field = StringBuffer();
    var quoted = false;

    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        fields.add(field.toString());
        field.clear();
      } else {
        field.write(character);
      }
    }

    if (quoted) {
      throw const FormatException('Unclosed quote in canonical Quran CSV.');
    }
    fields.add(field.toString());
    return fields;
  }

  Future<List<Map<String, dynamic>>> _getTranslation(
    String translationKey,
    int surahNumber,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/translation/sura/$translationKey/$surahNumber',
    );

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw HttpException(
            'QuranEnc request failed: HTTP ${response.statusCode}',
            uri: uri,
          );
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic> ||
            decoded['result'] is! List) {
          throw const FormatException('Invalid QuranEnc response.');
        }

        return (decoded['result'] as List)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 450 * attempt));
        }
      }
    }

    throw Exception('Unable to load verified Quran data: $lastError');
  }

  Future<bool> isCompleteOffline() async {
    final directory = await _cacheDirectory();
    var totalAyahs = 0;
    for (var surah = 1; surah <= 114; surah++) {
      final file = _fileFor(directory, surah);
      if (!await file.exists()) return false;
      try {
        final data = QuranTrilingualSurah.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        if (data.verses.length != expectedAyahCounts[surah - 1]) return false;
        totalAyahs += data.verses.length;
      } catch (_) {
        return false;
      }
    }
    return totalAyahs == expectedTotalAyahs;
  }

  Future<void> downloadCompleteQuran({
    required void Function(int completedSurahs, int totalSurahs) onProgress,
  }) async {
    var completed = 0;
    for (var surah = 1; surah <= 114; surah++) {
      await getSurah(surah);
      completed++;
      onProgress(completed, 114);
    }
    if (!await isCompleteOffline()) {
      throw StateError('The downloaded Quran dataset is incomplete.');
    }
  }

  Future<void> dispose() async {
    _client.close();
  }

  void _validateSurah(int surah) {
    if (surah < 1 || surah > 114) {
      throw RangeError.range(surah, 1, 114, 'surah');
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? -1;
    return -1;
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
      throw const FormatException('Cached surah has no verses.');
    }
    final number = json['number'];
    if (number is! int || number < 1 || number > 114) {
      throw const FormatException('Cached surah number is invalid.');
    }
    final verses = raw
        .map((item) => QuranTrilingualAyah.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList(growable: false);
    if (verses.length != QuranTrilingualDataSource.expectedAyahCounts[number - 1]) {
      throw const FormatException('Cached surah ayah count is invalid.');
    }
    for (var i = 0; i < verses.length; i++) {
      if (verses[i].surahNumber != number || verses[i].ayahNumber != i + 1) {
        throw const FormatException('Cached verse sequence is invalid.');
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
      throw const FormatException('Cached Quran verse is invalid.');
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
