
import 'package:flutter/material.dart';

import 'mumin_localizations.dart';

/// Central locale-aware formatting service for Mumin Pro.
///
/// Responsibilities:
/// - Format dates using the active Flutter locale.
/// - Format prayer times consistently.
/// - Format integer values using localized digits.
/// - Resolve text direction through the central language registry.
/// - Keep formatting independent from individual feature screens.
///
/// This service does not calculate prayer times, modify DateTime values,
/// or perform timezone conversion. It only formats values supplied to it.
@immutable
final class MuminLocaleFormatters {
  const MuminLocaleFormatters({
    required this.locale,
    required this.materialLocalizations,
  });

  /// Active application locale.
  final Locale locale;

  /// Flutter's locale-aware Material formatting implementation.
  final MaterialLocalizations materialLocalizations;

  /// Creates a formatter using the locale active in the current widget tree.
  factory MuminLocaleFormatters.of(BuildContext context) {
    return MuminLocaleFormatters(
      locale: Localizations.localeOf(context),
      materialLocalizations: MaterialLocalizations.of(context),
    );
  }

  /// Central localization model for the active locale.
  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(locale.languageCode);

  /// Active language code, such as ar, en, or fr.
  String get languageCode => localizations.languageCode;

  /// Compatibility properties for existing feature consumers.
  bool get isArabic => localizations.isArabic;

  bool get isEnglish => localizations.isEnglish;

  bool get isFrench => localizations.isFrench;

  /// Direction comes from the central language registry.
  bool get isRightToLeft => localizations.isRightToLeft;

  TextDirection get textDirection =>
      isRightToLeft ? TextDirection.rtl : TextDirection.ltr;

  /// Formats an integer using the active Flutter locale.
  ///
  /// The actual digit presentation is determined by the installed
  /// MaterialLocalizations implementation for this locale.
  String formatNumber(int value) {
    return materialLocalizations.formatDecimal(value);
  }

  /// Formats a prayer time.
  ///
  /// The default is 24-hour time to preserve the existing prayer schedule
  /// presentation. Set [alwaysUse24HourFormat] to false when a screen
  /// explicitly requires the locale's 12/24-hour convention.
  String formatTime(
    DateTime value, {
    bool alwaysUse24HourFormat = true,
  }) {
    return formatTimeOfDay(
      TimeOfDay(
        hour: value.hour,
        minute: value.minute,
      ),
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
  }

  /// Formats a Flutter TimeOfDay value using the active locale.
  String formatTimeOfDay(
    TimeOfDay value, {
    bool alwaysUse24HourFormat = true,
  }) {
    return materialLocalizations.formatTimeOfDay(
      value,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
  }

  /// Formats a date in the locale's medium presentation.
  String formatMediumDate(DateTime value) {
    return materialLocalizations.formatMediumDate(value);
  }

  /// Formats a date in the locale's full presentation.
  String formatFullDate(DateTime value) {
    return materialLocalizations.formatFullDate(value);
  }

  /// Formats a date in the locale's short presentation.
  String formatShortDate(DateTime value) {
    return materialLocalizations.formatShortDate(value);
  }

  /// Formats a date and time without changing the supplied date or time.
  String formatDateAndTime(
    DateTime value, {
    bool alwaysUse24HourFormat = true,
  }) {
    final date = formatMediumDate(value);
    final time = formatTime(
      value,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );

    return '$date • $time';
  }
}
