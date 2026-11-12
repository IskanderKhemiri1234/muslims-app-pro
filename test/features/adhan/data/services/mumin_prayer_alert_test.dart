import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/adhan/data/services/mumin_adhan_notification_service.dart';

void main() {
  group('MuminPrayerAlert.fromPayload', () {
    test('parses prayer and its scheduled local clock time', () {
      final alert = MuminPrayerAlert.fromPayload(
        'mumin_adhan:fajr:5:12',
      );

      expect(alert, isNotNull);
      expect(alert!.prayer, Prayer.fajr);
      expect(alert.prayerTime, isNotNull);
      expect(alert.prayerTime!.hour, 5);
      expect(alert.prayerTime!.minute, 12);
    });

    test('keeps compatibility with existing prayer-only payloads', () {
      final alert = MuminPrayerAlert.fromPayload(
        'mumin_adhan:maghrib',
      );

      expect(alert, isNotNull);
      expect(alert!.prayer, Prayer.maghrib);
      expect(alert.prayerTime, isNull);
    });

    test('rejects unknown prayers and invalid clock values', () {
      expect(
        MuminPrayerAlert.fromPayload('mumin_adhan:unknown:5:12'),
        isNull,
      );
      expect(
        MuminPrayerAlert.fromPayload('mumin_adhan:fajr:25:12')!
            .prayerTime,
        isNull,
      );
      expect(
        MuminPrayerAlert.fromPayload('another_notification:fajr:5:12'),
        isNull,
      );
    });
  });
}
