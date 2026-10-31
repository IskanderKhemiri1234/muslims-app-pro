
import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';

import 'package:muslims_app/features/prayer_times/domain/services/prayer_calculation_service.dart';

void main() {
  const service = PrayerCalculationService();

  final testDate = DateTime(2026, 10, 31);

  const method = CalculationMethod.muslim_world_league;

  const madhab = Madhab.shafi;

  group('PrayerCalculationService', () {
    test('calculates prayer times for Casablanca', () {
      final result = service.calculate(
        latitude: 33.5731,
        longitude: -7.5898,
        date: testDate,
        method: method,
        madhab: madhab,
      );

      expect(
        result.timeForPrayer(Prayer.fajr),
        isNotNull,
      );

      expect(
        result.timeForPrayer(Prayer.sunrise),
        isNotNull,
      );

      expect(
        result.timeForPrayer(Prayer.dhuhr),
        isNotNull,
      );

      expect(
        result.timeForPrayer(Prayer.asr),
        isNotNull,
      );

      expect(
        result.timeForPrayer(Prayer.maghrib),
        isNotNull,
      );

      expect(
        result.timeForPrayer(Prayer.isha),
        isNotNull,
      );
    });

    test('returns prayers in chronological order', () {
      final result = service.calculate(
        latitude: 33.5731,
        longitude: -7.5898,
        date: testDate,
        method: method,
        madhab: madhab,
      );

      final fajr = result.timeForPrayer(Prayer.fajr)!;
      final sunrise = result.timeForPrayer(Prayer.sunrise)!;
      final dhuhr = result.timeForPrayer(Prayer.dhuhr)!;
      final asr = result.timeForPrayer(Prayer.asr)!;
      final maghrib = result.timeForPrayer(Prayer.maghrib)!;
      final isha = result.timeForPrayer(Prayer.isha)!;

      expect(fajr.isBefore(sunrise), isTrue);
      expect(sunrise.isBefore(dhuhr), isTrue);
      expect(dhuhr.isBefore(asr), isTrue);
      expect(asr.isBefore(maghrib), isTrue);
      expect(maghrib.isBefore(isha), isTrue);
    });

    test('rejects latitude outside valid range', () {
      expect(
        () => service.calculate(
          latitude: 91,
          longitude: -7.5898,
          date: testDate,
          method: method,
          madhab: madhab,
        ),
        throwsArgumentError,
      );
    });

    test('rejects longitude outside valid range', () {
      expect(
        () => service.calculate(
          latitude: 33.5731,
          longitude: 181,
          date: testDate,
          method: method,
          madhab: madhab,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-finite coordinates', () {
      expect(
        () => service.calculate(
          latitude: double.nan,
          longitude: -7.5898,
          date: testDate,
          method: method,
          madhab: madhab,
        ),
        throwsArgumentError,
      );
    });

    test('accepts valid coordinates at geographical limits', () {
      expect(
        () => service.calculate(
          latitude: 90,
          longitude: 180,
          date: testDate,
          method: method,
          madhab: madhab,
        ),
        returnsNormally,
      );
    });
  });
}
