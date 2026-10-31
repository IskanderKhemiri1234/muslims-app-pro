
import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:muslims_app/features/prayer_times/domain/services/global_prayer_calculation_service.dart';

void main() {
  const service = GlobalPrayerCalculationService();

  late tz.Location casablanca;
  late tz.Location newYork;

  setUpAll(() {
    tz_data.initializeTimeZones();

    casablanca = tz.getLocation('Africa/Casablanca');
    newYork = tz.getLocation('America/New_York');
  });

  group('GlobalPrayerCalculationService', () {
    test('calculates all prayer times for Casablanca', () {
      final result = service.calculate(
        latitude: 33.5731,
        longitude: -7.5898,
        localDate: DateTime(2026, 10, 31),
        timezone: casablanca,
        method: CalculationMethod.muslim_world_league,
        madhab: Madhab.shafi,
      );

      expect(result.timezoneId, 'Africa/Casablanca');

      for (final prayer in GlobalPrayerCalculationService.supportedPrayers) {
        expect(result.timeForPrayer(prayer), isNotNull);
      }
    });

    test('returns prayer times in chronological order', () {
      final result = service.calculate(
        latitude: 33.5731,
        longitude: -7.5898,
        localDate: DateTime(2026, 10, 31),
        timezone: casablanca,
        method: CalculationMethod.muslim_world_league,
        madhab: Madhab.shafi,
      );

      final prayers = GlobalPrayerCalculationService.supportedPrayers;

      for (var i = 0; i < prayers.length - 1; i++) {
        final current = result.timeForPrayer(prayers[i])!;
        final next = result.timeForPrayer(prayers[i + 1])!;

        expect(current.isBefore(next), isTrue);
      }
    });

    test('uses daylight saving offset for New York after spring transition', () {
      final result = service.calculate(
        latitude: 40.7128,
        longitude: -74.0060,
        localDate: DateTime(2026, 3, 8),
        timezone: newYork,
        method: CalculationMethod.north_america,
        madhab: Madhab.shafi,
      );

      final fajr = result.timeForPrayer(Prayer.fajr)!;
      final dhuhr = result.timeForPrayer(Prayer.dhuhr)!;

      expect(fajr.timeZoneOffset, const Duration(hours: -4));
      expect(dhuhr.timeZoneOffset, const Duration(hours: -4));
    });

    test('uses standard offset before New York spring transition', () {
      final result = service.calculate(
        latitude: 40.7128,
        longitude: -74.0060,
        localDate: DateTime(2026, 3, 7),
        timezone: newYork,
        method: CalculationMethod.north_america,
        madhab: Madhab.shafi,
      );

      final dhuhr = result.timeForPrayer(Prayer.dhuhr)!;

      expect(dhuhr.timeZoneOffset, const Duration(hours: -5));
    });

    test('rejects invalid coordinates', () {
      expect(
        () => service.calculate(
          latitude: 91,
          longitude: 0,
          localDate: DateTime(2026, 10, 31),
          timezone: casablanca,
          method: CalculationMethod.muslim_world_league,
          madhab: Madhab.shafi,
        ),
        throwsArgumentError,
      );
    });
  });
}
