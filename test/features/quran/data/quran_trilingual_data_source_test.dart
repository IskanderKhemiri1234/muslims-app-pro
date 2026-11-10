import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/core/localization/catalogs/mumin_quran_reader_catalog.dart';
import 'package:muslims_app/features/quran/data/datasources/quran_trilingual_data_source.dart';

void main() {
  group('QuranTrilingualDataSource integrity contract', () {
    test('reader interface catalog is complete in all supported languages', () {
      expect(MuminQuranReaderCatalog.launchCatalogIntegrity, {
        'ar': true,
        'en': true,
        'fr': true,
      });
    });
    test('canonical surah ayah counts total exactly 6236', () {
      expect(QuranTrilingualDataSource.expectedAyahCounts, hasLength(114));
      expect(
        QuranTrilingualDataSource.expectedAyahCounts.fold<int>(
          0,
          (total, count) => total + count,
        ),
        QuranTrilingualDataSource.expectedTotalAyahs,
      );
      expect(
        QuranTrilingualDataSource.expectedAyahCounts.first,
        7,
      );
      expect(
        QuranTrilingualDataSource.expectedAyahCounts.last,
        6,
      );
    });

    test('accepts a complete, ordered Al-Fatiha cache record', () {
      final verses = List.generate(
        7,
        (index) => <String, dynamic>{
          'surah': 1,
          'ayah': index + 1,
          'arabic': 'آية ${index + 1}',
          'english': 'Verse ${index + 1}',
          'french': 'Verset ${index + 1}',
        },
      );

      final surah = QuranTrilingualSurah.fromJson({
        'number': 1,
        'englishVersion': QuranTrilingualDataSource.englishVersion,
        'frenchVersion': QuranTrilingualDataSource.frenchVersion,
        'verses': verses,
      });

      expect(surah.number, 1);
      expect(surah.verses, hasLength(7));
      expect(surah.verses.last.ayahNumber, 7);
    });

    test('rejects incomplete or misordered verse data', () {
      final verses = List.generate(
        7,
        (index) => <String, dynamic>{
          'surah': 1,
          'ayah': index + 1,
          'arabic': 'آية ${index + 1}',
          'english': 'Verse ${index + 1}',
          'french': 'Verset ${index + 1}',
        },
      );
      verses[3]['ayah'] = 5;

      expect(
        () => QuranTrilingualSurah.fromJson({
          'number': 1,
          'verses': verses,
        }),
        throwsFormatException,
      );
    });
    test('ships every verified surah and all 6236 ayahs offline', () async {
      const source = QuranTrilingualDataSource();
      expect(await source.isCompleteOffline(), isTrue);

      var total = 0;
      for (var number = 1; number <= 114; number++) {
        final surah = await source.getSurah(number);
        expect(surah.number, number);
        expect(
          surah.verses,
          hasLength(QuranTrilingualDataSource.expectedAyahCounts[number - 1]),
        );
        for (var index = 0; index < surah.verses.length; index++) {
          final ayah = surah.verses[index];
          expect(ayah.surahNumber, number);
          expect(ayah.ayahNumber, index + 1);
          expect(ayah.arabic, isNotEmpty);
          expect(ayah.english, isNotEmpty);
          expect(ayah.french, isNotEmpty);
        }
        total += surah.verses.length;
      }
      expect(total, QuranTrilingualDataSource.expectedTotalAyahs);
      await source.dispose();
    });

  });
}
