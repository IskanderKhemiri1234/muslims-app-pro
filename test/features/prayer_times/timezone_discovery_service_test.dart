
import 'package:flutter_test/flutter_test.dart';

import 'package:muslims_app/features/prayer_times/data/datasources/timezone_lookup_datasource.dart';
import 'package:muslims_app/features/prayer_times/domain/services/timezone_discovery_service.dart';

class FakeTimezoneDataSource
    implements TimezoneLookupDataSource {
  final TimezoneLookupResult result;
  int calls = 0;

  FakeTimezoneDataSource(this.result);

  @override
  Future<TimezoneLookupResult> lookup({
    required double latitude,
    required double longitude,
  }) async {
    calls++;

    return result;
  }
}

void main() {
  group('TimezoneDiscoveryService', () {
    test('discovers Casablanca timezone', () async {
      final source = FakeTimezoneDataSource(
        const TimezoneLookupResult(
          timezoneId: 'Africa/Casablanca',
          countryCode: 'MA',
        ),
      );

      final service = TimezoneDiscoveryService(
        dataSource: source,
      );

      final result = await service.discover(
        latitude: 33.5731,
        longitude: -7.5898,
      );

      expect(result.timezoneId, 'Africa/Casablanca');
      expect(result.countryCode, 'MA');
      expect(result.location.name, 'Africa/Casablanca');
      expect(source.calls, 1);
    });

    test('rejects invalid latitude before lookup', () async {
      final source = FakeTimezoneDataSource(
        const TimezoneLookupResult(
          timezoneId: 'Africa/Casablanca',
          countryCode: 'MA',
        ),
      );

      final service = TimezoneDiscoveryService(
        dataSource: source,
      );

      await expectLater(
        service.discover(
          latitude: 91,
          longitude: -7.5,
        ),
        throwsArgumentError,
      );

      expect(source.calls, 0);
    });

    test('rejects invalid longitude before lookup', () async {
      final source = FakeTimezoneDataSource(
        const TimezoneLookupResult(
          timezoneId: 'Africa/Casablanca',
          countryCode: 'MA',
        ),
      );

      final service = TimezoneDiscoveryService(
        dataSource: source,
      );

      await expectLater(
        service.discover(
          latitude: 33.5,
          longitude: 181,
        ),
        throwsArgumentError,
      );

      expect(source.calls, 0);
    });

    test('rejects unknown timezone IDs', () async {
      final source = FakeTimezoneDataSource(
        const TimezoneLookupResult(
          timezoneId: 'Invalid/Unknown_Zone',
        ),
      );

      final service = TimezoneDiscoveryService(
        dataSource: source,
      );

      await expectLater(
        service.discover(
          latitude: 33.5731,
          longitude: -7.5898,
        ),
        throwsFormatException,
      );
    });

    test('rejects non-finite coordinates', () async {
      final source = FakeTimezoneDataSource(
        const TimezoneLookupResult(
          timezoneId: 'Africa/Casablanca',
        ),
      );

      final service = TimezoneDiscoveryService(
        dataSource: source,
      );

      await expectLater(
        service.discover(
          latitude: double.nan,
          longitude: 0,
        ),
        throwsArgumentError,
      );

      expect(source.calls, 0);
    });
  });
}
