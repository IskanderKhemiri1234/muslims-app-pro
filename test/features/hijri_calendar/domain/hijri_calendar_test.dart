
import 'package:flutter_test/flutter_test.dart';
import 'package:muslims_app/features/hijri_calendar/domain/models/hijri_calendar_day.dart';
import 'package:muslims_app/features/hijri_calendar/domain/services/hijri_calendar_month_builder.dart';
import 'package:muslims_app/features/hijri_calendar/domain/services/hijri_date_calculator.dart';

void main() {
  group('HijriDateCalculator', () {
    test('converts 11 March 2024 to 1 Ramadan 1445 AH', () {
      final result = HijriDateCalculator.fromGregorian(
        DateTime(2024, 3, 11),
      );

      expect(result.year, 1445);
      expect(result.month, 9);
      expect(result.day, 1);
      expect(result.isValid, isTrue);
    });

    test('converts 1 March 2025 to 1 Ramadan 1446 AH', () {
      final result = HijriDateCalculator.fromGregorian(
        DateTime(2025, 3, 1),
      );

      expect(result.year, 1446);
      expect(result.month, 9);
      expect(result.day, 1);
    });

    test('ignores the time component', () {
      final morning = HijriDateCalculator.fromGregorian(
        DateTime(2024, 3, 11, 1, 15),
      );

      final evening = HijriDateCalculator.fromGregorian(
        DateTime(2024, 3, 11, 23, 45),
      );

      expect(evening, morning);
    });

    test('rejects Gregorian year zero', () {
      expect(
        () => HijriDateCalculator.fromGregorian(
          DateTime(0, 1, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('HijriCalendarMonthBuilder', () {
    test('builds exactly 42 calendar days', () {
      final days = HijriCalendarMonthBuilder.build(
        anchorDate: DateTime(2024, 3, 20),
        today: DateTime(2024, 3, 20),
      );

      expect(days, hasLength(42));
      expect(days, isNotEmpty);
    });

    test('marks the first day of the Hijri month correctly', () {
      final days = HijriCalendarMonthBuilder.build(
        anchorDate: DateTime(2024, 3, 20),
        today: DateTime(2024, 3, 20),
      );

      final firstDay = days.firstWhere(
        (day) => day.isCurrentMonth && day.hijriDate.day == 1,
      );

      expect(firstDay.gregorianDate, DateTime(2024, 3, 11));
      expect(firstDay.hijriDate.month, 9);
      expect(firstDay.hijriDate.year, 1445);
    });

    test('marks today and selected date independently', () {
      final days = HijriCalendarMonthBuilder.build(
        anchorDate: DateTime(2024, 3, 20),
        today: DateTime(2024, 3, 20),
        selectedDate: DateTime(2024, 3, 21),
      );

      final today = days.singleWhere((day) => day.isToday);
      final selected = days.singleWhere((day) => day.isSelected);

      expect(today.gregorianDate, DateTime(2024, 3, 20));
      expect(selected.gregorianDate, DateTime(2024, 3, 21));
      expect(today.isSelected, isFalse);
      expect(selected.isToday, isFalse);
    });

    test('calendar days are consecutive', () {
      final days = HijriCalendarMonthBuilder.build(
        anchorDate: DateTime(2024, 3, 20),
        today: DateTime(2024, 3, 20),
      );

      for (var index = 1; index < days.length; index++) {
        expect(
          days[index].gregorianDate.difference(
            days[index - 1].gregorianDate,
          ),
          const Duration(days: 1),
        );
      }
    });

    test('returns an unmodifiable calendar list', () {
      final days = HijriCalendarMonthBuilder.build(
        anchorDate: DateTime(2024, 3, 20),
      );

      expect(
        () => days.add(
          HijriCalendarDay(
            gregorianDate: DateTime(2024, 3, 20),
            hijriDate: HijriDate(
              year: 1445,
              month: 9,
              day: 10,
            ),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
