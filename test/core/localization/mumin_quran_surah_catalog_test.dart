import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/core/localization/catalogs/mumin_quran_surah_catalog.dart';

void main() {
  group('MuminQuranSurahCatalog', () {
    test('contains all 114 titles in all three languages', () {
      expect(MuminQuranSurahCatalog.hasValidData, isTrue);
      expect(MuminQuranSurahCatalog.namesFor('ar'), hasLength(114));
      expect(MuminQuranSurahCatalog.namesFor('en'), hasLength(114));
      expect(MuminQuranSurahCatalog.namesFor('fr'), hasLength(114));
    });

    test('returns the correct language-specific first surah title', () {
      expect(
        MuminQuranSurahCatalog.nameFor(1, languageCode: 'ar'),
        'الفاتحة',
      );
      expect(
        MuminQuranSurahCatalog.nameFor(1, languageCode: 'en'),
        'Al-Fatihah',
      );
      expect(
        MuminQuranSurahCatalog.nameFor(1, languageCode: 'fr'),
        "L'Ouverture",
      );
    });

    test('keeps every localized title non-empty', () {
      for (final language in const ['ar', 'en', 'fr']) {
        expect(
          MuminQuranSurahCatalog.namesFor(language)
              .every((name) => name.trim().isNotEmpty),
          isTrue,
          reason: 'Every $language surah title must be present.',
        );
      }
    });

    test('returns an empty name for an invalid surah number', () {
      expect(
        MuminQuranSurahCatalog.nameFor(0, languageCode: 'ar'),
        isEmpty,
      );
      expect(
        MuminQuranSurahCatalog.nameFor(115, languageCode: 'fr'),
        isEmpty,
      );
    });
  });
}
