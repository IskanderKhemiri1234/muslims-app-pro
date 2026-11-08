import '../models/hijri_calendar_day.dart';
import 'hijri_date_calculator.dart';

/// Builds a local 42-day calendar grid for the Hijri month
/// containing the supplied Gregorian anchor date.
///
/// The first weekday is Monday.
/// Dates are calculated locally without network or GPS access.
abstract final class HijriCalendarMonthBuilder {
  static const int gridDayCount = 42;
  static const int maximumMonthStartSearchDays = 35;

  /// Builds a calendar grid containing the Hijri month of [anchorDate].
  ///
  /// [today] identifies the current local day.
  /// [selectedDate] identifies the currently selected day.
  static List<HijriCalendarDay> build({
    required DateTime anchorDate,
    DateTime? today,
    DateTime? selectedDate,
  }) {
    final anchor = _dateOnly(anchorDate);
    final currentDay = _dateOnly(today ?? DateTime.now());
    final selectedDay =
        selectedDate == null ? null : _dateOnly(selectedDate);

    final anchorHijri = HijriDateCalculator.fromGregorian(anchor);

    final firstGregorianDay = _findFirstGregorianDay(
      anchor: anchor,
      targetHijriYear: anchorHijri.year,
      targetHijriMonth: anchorHijri.month,
    );

    final weekdayOffset =
        (firstGregorianDay.weekday - DateTime.monday) % 7;

    final gridStart = DateTime(
      firstGregorianDay.year,
      firstGregorianDay.month,
      firstGregorianDay.day - weekdayOffset,
    );

    return List<HijriCalendarDay>.unmodifiable(
      List<HijriCalendarDay>.generate(
        gridDayCount,
        (index) {
          final gregorianDate = DateTime(
            gridStart.year,
            gridStart.month,
            gridStart.day + index,
          );

          final hijriDate =
              HijriDateCalculator.fromGregorian(gregorianDate);

          final isCurrentMonth =
              hijriDate.year == anchorHijri.year &&
              hijriDate.month == anchorHijri.month;

          return HijriCalendarDay(
            gregorianDate: gregorianDate,
            hijriDate: hijriDate,
            isToday: _sameDate(gregorianDate, currentDay),
            isSelected: selectedDay != null &&
                _sameDate(gregorianDate, selectedDay),
            isCurrentMonth: isCurrentMonth,
          );
        },
      ),
    );
  }

  /// Finds day 1 of the Hijri month containing [anchor].
  static DateTime _findFirstGregorianDay({
    required DateTime anchor,
    required int targetHijriYear,
    required int targetHijriMonth,
  }) {
    for (var offset = 0;
        offset <= maximumMonthStartSearchDays;
        offset++) {
      final candidate = DateTime(
        anchor.year,
        anchor.month,
        anchor.day - offset,
      );

      final hijri = HijriDateCalculator.fromGregorian(candidate);

      if (hijri.year == targetHijriYear &&
          hijri.month == targetHijriMonth &&
          hijri.day == 1) {
        return candidate;
      }
    }

    throw StateError(
      'Could not find the first Gregorian day of the '
      'requested Hijri month.',
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
