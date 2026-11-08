/// Mumin Pro — Hijri Calendar Calculation Engine.
///
/// Converts a Gregorian calendar date to the tabular Islamic
/// civil calendar.
///
/// IMPORTANT:
/// This is an arithmetic estimate, not an official moon-sighting
/// announcement. Local religious authorities may announce a date
/// that differs by one or more days.
///
/// This service:
/// - Has no external dependencies.
/// - Does not access the network or device location.
/// - Does not modify prayer calculations.
/// - Accepts a Gregorian date supplied by the caller.
/// - Can be reused by the calendar page, home card and notifications.
library;

final class HijriDate {
  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  bool get isValid =>
      year >= 1 &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= 30;

  @override
  String toString() => '$year-$month-$day';

  @override
  bool operator ==(Object other) {
    return other is HijriDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}

abstract final class HijriDateCalculator {
  /// Julian day number corresponding to 1 Muharram, 1 AH
  /// in the tabular Islamic civil calendar.
  static const int _islamicEpoch = 1948440;

  /// Converts a Gregorian date into an estimated Hijri date.
  ///
  /// The time component is intentionally ignored. The caller
  /// must supply the date in the user's local calendar timezone.
  ///
  /// Throws [ArgumentError] for invalid Gregorian dates.
  static HijriDate fromGregorian(DateTime date) {
    _validateGregorianDate(date);

    final julianDay = _gregorianToJulianDay(
      date.year,
      date.month,
      date.day,
    );

    final year = (
      (30 * (julianDay - _islamicEpoch) + 10646) / 10631
    ).floor();

    final firstDayOfYear = _islamicToJulianDay(
      year,
      1,
      1,
    );

    var month = (
      (julianDay - (29 + firstDayOfYear)) / 29.5
    ).ceil() + 1;

    if (month < 1) {
      month = 1;
    } else if (month > 12) {
      month = 12;
    }

    final firstDayOfMonth = _islamicToJulianDay(
      year,
      month,
      1,
    );

    final day = julianDay - firstDayOfMonth + 1;

    final result = HijriDate(
      year: year,
      month: month,
      day: day,
    );

    if (!result.isValid) {
      throw StateError(
        'Hijri date conversion produced an invalid date.',
      );
    }

    return result;
  }

  /// Converts a Gregorian calendar date to a Julian day number.
  static int _gregorianToJulianDay(
    int year,
    int month,
    int day,
  ) {
    final a = ((14 - month) / 12).floor();
    final adjustedYear = year + 4800 - a;
    final adjustedMonth = month + (12 * a) - 3;

    return day +
        ((153 * adjustedMonth + 2) / 5).floor() +
        (365 * adjustedYear) +
        (adjustedYear / 4).floor() -
        (adjustedYear / 100).floor() +
        (adjustedYear / 400).floor() -
        32045;
  }

  /// Converts a tabular Islamic date to a Julian day number.
  static int _islamicToJulianDay(
    int year,
    int month,
    int day,
  ) {
    final monthDays = (29.5 * (month - 1)).ceil();

    final leapDays = ((3 + 11 * year) / 30).floor();

    return day +
        monthDays +
        (year - 1) * 354 +
        leapDays +
        _islamicEpoch -
        1;
  }

  static void _validateGregorianDate(DateTime date) {
    if (date.year < 1 || date.year > 9999) {
      throw ArgumentError.value(
        date.year,
        'date.year',
        'Year must be between 1 and 9999.',
      );
    }

    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (normalized.year != date.year ||
        normalized.month != date.month ||
        normalized.day != date.day) {
      throw ArgumentError.value(
        date,
        'date',
        'A valid Gregorian calendar date is required.',
      );
    }
  }
}
