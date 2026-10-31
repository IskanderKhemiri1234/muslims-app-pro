import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:muslims_app/core/services/timezone_discovery_service.dart'
    as core_timezone;

import 'package:muslims_app/features/prayer_times/domain/services/timezone_discovery_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('TimezoneDiscoveryService', () {
    late TimezoneDiscoveryService service;

    setUp(() {
      service = TimezoneDiscoveryService();
    });

    test('discovers Casablanca timezone', () async {
      final result = await service.discover(
        latitude: 33.5731,
        longitude: -7.5898,
      );

      expect(result.timezoneId, 'Africa/Casablanca');
      expect(result.location.name, 'Africa/Casablanca');
      expect(result.countryCode, isNull);
    });

    test('discovers Paris timezone', () async {
      final result = await service.discover(
        latitude: 48.8566,
        longitude: 2.3522,
      );

      expect(result.timezoneId, 'Europe/Paris');
    });

    test('discovers New York timezone', () async {
      final result = await service.discover(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(result.timezoneId, 'America/New_York');
    });

    test('rejects invalid latitude', () async {
      await expectLater(
        service.discover(
          latitude: 91,
          longitude: -7.5,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid longitude', () async {
      await expectLater(
        service.discover(
          latitude: 33.5,
          longitude: 181,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-finite coordinates', () async {
      await expectLater(
        service.discover(
          latitude: double.nan,
          longitude: 0,
        ),
        throwsArgumentError,
      );
    });

    test('core service returns null for ocean coordinates', () async {
      final resolver = core_timezone.TimezoneDiscoveryService();

      final result = await resolver.discover(
        latitude: 0,
        longitude: 0,
      );

      expect(result, isNull);
    });
  });
}
