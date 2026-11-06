
import 'package:flutter/material.dart';

import 'mumin_language_registry.dart';
import 'mumin_localizations.dart';

/// Central locale-aware formatting service for Mumin Pro.
///
/// Formatting is based on Flutter's active MaterialLocalizations,
/// while language identity and text direction come from the
/// independent MuminLanguageRegistry.
@immutable
final class MuminLocaleFormatters {
  const MuminLocaleFormatters({
    required this.locale,
    required this.materialLocalizations,
  });

  final Locale locale;
  final MaterialLocalizations materialLocalizations;

  factory MuminLocaleFormatters.of(BuildContext context) {
    return MuminLocaleFormatters(
      locale: Localizations.localeOf(context),
      materialLocalizations: MaterialLocalizations.of(context),
    );
  }

  /// The approved launch language code.
  String get languageCode =>
      MuminLanguageRegistry.normalizeLanguageCode(
        locale.languageCode,
      );

  /// Translation engine remains responsible for translated text.
  MuminLocalizations get localizations =>
      MuminLocalizations.fromCode(languageCode);

  bool get isArabic => languageCode == 'ar';

  bool get isEnglish => languageCode == 'en';

  bool get isFrench => languageCode == 'fr';

  /// Direction is resolved exclusively by the language registry.
  bool get isRightToLeft =>
      MuminLanguageRegistry.isRightToLeft(languageCode);

  bool get isLeftToRight =>
      MuminLanguageRegistry.isLeftToRight(languageCode);

  TextDirection get textDirection =>
      isRightToLeft ? TextDirection.rtl : TextDirection.ltr;

  /// Formats an integer using Flutter's active locale.
  String formatNumber(int value) {
    return materialLocalizations.formatDecimal(value);
  }

  /// Formats a prayer time.
  ///
  /// The default is 24-hour time for consistent prayer schedules.
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

  String formatTimeOfDay(
    TimeOfDay value, {
    bool alwaysUse24HourFormat = true,
  }) {
    return materialLocalizations.formatTimeOfDay(
      value,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
  }

  String formatMediumDate(DateTime value) {
    return materialLocalizations.formatMediumDate(value);
  }

  String formatFullDate(DateTime value) {
    return materialLocalizations.formatFullDate(value);
  }

  String formatShortDate(DateTime value) {
    return materialLocalizations.formatShortDate(value);
  }

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
