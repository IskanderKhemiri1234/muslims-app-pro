
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

      for (final prayer in [
        Prayer.fajr,
        Prayer.sunrise,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        expect(result.timeForPrayer(prayer), isNotNull);
      }
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

    test('accepts valid geographical boundary coordinates', () {
      expect(
        () => PrayerCalculationService.validateCoordinates(
          latitude: 90,
          longitude: 180,
        ),
        returnsNormally,
      );

      expect(
        () => PrayerCalculationService.validateCoordinates(
          latitude: -90,
          longitude: -180,
        ),
        returnsNormally,
      );
    });
  });
}
