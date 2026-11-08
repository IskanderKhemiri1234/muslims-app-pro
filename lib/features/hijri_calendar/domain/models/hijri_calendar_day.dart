import '../services/hijri_date_calculator.dart';

/// Represents one day displayed in the Mumin Pro Hijri calendar.
///
/// This model contains calendar data only.
/// It does not access device location, storage, network,
/// prayer calculations or Quran data.
final class HijriCalendarDay {
  const HijriCalendarDay({
    required this.gregorianDate,
    required this.hijriDate,
    this.isToday = false,
    this.isSelected = false,
    this.isCurrentMonth = true,
  });

  /// Gregorian date in the device's local calendar.
  final DateTime gregorianDate;

  /// Corresponding calculated Hijri date.
  final HijriDate hijriDate;

  /// Whether this day represents today.
  final bool isToday;

  /// Whether this day is currently selected by the user.
  final bool isSelected;

  /// Whether this day belongs to the displayed calendar month.
  final bool isCurrentMonth;

  /// Returns the Gregorian date without its time component.
  DateTime get dateOnly => DateTime(
        gregorianDate.year,
        gregorianDate.month,
        gregorianDate.day,
      );

  /// Stable local date key for calendar selection and comparison.
  String get dateKey {
    final date = dateOnly;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  HijriCalendarDay copyWith({
    DateTime? gregorianDate,
    HijriDate? hijriDate,
    bool? isToday,
    bool? isSelected,
    bool? isCurrentMonth,
  }) {
    return HijriCalendarDay(
      gregorianDate: gregorianDate ?? this.gregorianDate,
      hijriDate: hijriDate ?? this.hijriDate,
      isToday: isToday ?? this.isToday,
      isSelected: isSelected ?? this.isSelected,
      isCurrentMonth: isCurrentMonth ?? this.isCurrentMonth,
    );
  }
}
