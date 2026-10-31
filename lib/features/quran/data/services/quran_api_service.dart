
import 'dart:convert';

import 'package:http/http.dart' as http;

class QuranApiService {
  QuranApiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _quranBase =
      'https://api.alquran.cloud/v1';

  static const String _tafsirBase =
      'https://quranenc.com/api/v1';

  static const String tafsirKey = 'arabic_muyassar';

  Future<QuranSurah> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError.value(surahNumber, 'surahNumber');
    }

    final uri = Uri.parse(
      '$_quranBase/surah/$surahNumber/quran-uthmani',
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'تعذر تحميل السورة (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map<String, dynamic> ||
        decoded['code'] != 200 ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException(
        'استجابة القرآن غير صالحة.',
      );
    }

    final data = decoded['data'] as Map<String, dynamic>;
    final rawAyahs = data['ayahs'];

    if (rawAyahs is! List) {
      throw const FormatException(
        'لم يتم العثور على آيات السورة.',
      );
    }

    return QuranSurah(
      number: data['number'] as int,
      name: data['name'] as String,
      englishName: data['englishName'] as String,
      revelationType: data['revelationType'] as String,
      numberOfAyahs: data['numberOfAyahs'] as int,
      ayahs: rawAyahs.map((item) {
        final ayah = item as Map<String, dynamic>;

        return QuranAyah(
          number: ayah['number'] as int,
          numberInSurah: ayah['numberInSurah'] as int,
          text: ayah['text'] as String,
        );
      }).toList(),
    );
  }

  Future<String> getTafsir({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    if (surahNumber < 1 ||
        surahNumber > 114 ||
        ayahNumber < 1) {
      throw ArgumentError('رقم السورة أو الآية غير صالح.');
    }

    final uri = Uri.parse(
      '$_tafsirBase/tafsir/aya/'
      '$tafsirKey/$surahNumber/$ayahNumber',
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'تعذر تحميل التفسير (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    final text = _extractTafsirText(decoded);

    if (text.isEmpty) {
      throw const FormatException(
        'لم يتوفر نص التفسير لهذه الآية.',
      );
    }

    return text;
  }

  String _extractTafsirText(dynamic decoded) {
    final texts = <String>[];

    void collect(dynamic value) {
      if (value is List) {
        for (final item in value) {
          collect(item);
        }
        return;
      }

      if (value is Map) {
        final text = value['text'] ?? value['tafsir'];

        if (text is String && text.trim().isNotEmpty) {
          texts.add(_stripHtml(text));
        } else {
          for (final entry in value.entries) {
            if (entry.value is Map || entry.value is List) {
              collect(entry.value);
            }
          }
        }
      }
    }

    collect(decoded);

    return texts
        .where((text) => text.isNotEmpty)
        .toSet()
        .join('\n\n');
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  void dispose() {
    _client.close();
  }
}

class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int numberOfAyahs;
  final List<QuranAyah> ayahs;
}

class QuranAyah {
  const QuranAyah({
    required this.number,
    required this.numberInSurah,
    required this.text,
  });

  final int number;
  final int numberInSurah;
  final String text;
}
