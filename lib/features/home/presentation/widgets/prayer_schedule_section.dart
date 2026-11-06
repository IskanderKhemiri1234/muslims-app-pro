
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'glass_container.dart';

/// Displays the daily prayer schedule.
///
/// The public constructor is intentionally kept compatible with existing
/// callers. Language is resolved from the active Flutter locale, with
/// [isArabic] retained as a fallback for older integrations.
class PrayerScheduleSection extends StatelessWidget {
  const PrayerScheduleSection({
    super.key,
    required this.prayerTimes,
    required this.nextPrayer,
    required this.isArabic,
    required this.prayerName,
    required this.formatTime,
  });

  final PrayerTimes prayerTimes;
  final Prayer? nextPrayer;
  final bool isArabic;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;

  static const List<Prayer> prayers = <Prayer>[
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];


  IconData _iconFor(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.wb_twilight_rounded;
      case Prayer.sunrise:
        return Icons.wb_sunny_outlined;
      case Prayer.dhuhr:
        return Icons.light_mode_rounded;
      case Prayer.asr:
        return Icons.wb_sunny_rounded;
      case Prayer.maghrib:
        return Icons.wb_twilight_rounded;
      case Prayer.isha:
        return Icons.nights_stay_rounded;
      default:
        return Icons.mosque_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final locale = Localizations.localeOf(context);
    final localeCode = locale.languageCode.toLowerCase();
    final localizations = MuminLocalizations.fromCode(
      localeCode.isEmpty ? (isArabic ? 'ar' : 'en') : localeCode,
    );

    final entries = <_PrayerEntry>[];

    for (final prayer in prayers) {
      final time = prayerTimes.timeForPrayer(prayer);

      if (time != null) {
        entries.add(
          _PrayerEntry(
            prayer: prayer,
            time: time,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                localizations.prayerTimes,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.gold,
              size: 21,
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (entries.isEmpty)
          _EmptyScheduleState(
            message: localizations.prayerTimesUnavailable,
          )
        else
          ...entries.map((entry) {
            // Sunrise is displayed in the schedule but is not treated as
            // the next obligatory prayer.
            final isNext = nextPrayer != null &&
                entry.prayer == nextPrayer &&
                entry.prayer != Prayer.none &&
                entry.prayer != Prayer.sunrise;

            return Padding(
              key: ValueKey<Prayer>(entry.prayer),
              padding: const EdgeInsets.only(bottom: 9),
              child: _PrayerScheduleTile(
                name: prayerName(entry.prayer),
                formattedTime: formatTime(entry.time),
                isNext: isNext,
                isDark: isDark,
                icon: _iconFor(entry.prayer),
                reduceMotion: reduceMotion,
                nextPrayerLabel: localizations.nextPrayer,
                languageCode: localizations.languageCode,
              ),
            );
          }),
      ],
    );
  }
}

class _PrayerEntry {
  const _PrayerEntry({
    required this.prayer,
    required this.time,
  });

  final Prayer prayer;
  final DateTime time;
}

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: GlassContainer(
          radius: 19,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerScheduleTile extends StatelessWidget {
  const _PrayerScheduleTile({
    required this.name,
    required this.formattedTime,
    required this.isNext,
    required this.isDark,
    required this.icon,
    required this.reduceMotion,
    required this.nextPrayerLabel,
    required this.languageCode,
  });

  final String name;
  final String formattedTime;
  final bool isNext;
  final bool isDark;
  final IconData icon;
  final bool reduceMotion;
  final String nextPrayerLabel;
  final String languageCode;

  static const Duration _animationDuration = Duration(milliseconds: 250);

  String get _semanticLabel {
    if (isNext) {
      switch (languageCode) {
        case 'ar':
          return '$name، $nextPrayerLabel، $formattedTime';
        case 'fr':
          return '$name, $nextPrayerLabel, $formattedTime';
        default:
          return '$name, $nextPrayerLabel, $formattedTime';
      }
    }

    switch (languageCode) {
      case 'ar':
        return '$name، $formattedTime';
      default:
        return '$name, $formattedTime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceText = theme.colorScheme.onSurface;

    final backgroundColor = isNext
        ? primaryColor.withValues(
            alpha: isDark ? 0.22 : 0.09,
          )
        : null;

    final borderColor = isNext
        ? AppColors.gold.withValues(alpha: 0.42)
        : null;

    final animationDuration =
        reduceMotion ? Duration.zero : _animationDuration;

    return Semantics(
      container: true,
      label: _semanticLabel,
      child: ExcludeSemantics(
        child: GlassContainer(
          radius: 19,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          color: backgroundColor,
          borderColor: borderColor,
          child: Row(
            children: [
              AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeInOut,
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: isNext
                      ? primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : primaryColor.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isNext
                      ? theme.colorScheme.onPrimary
                      : AppColors.gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: surfaceText,
                        fontSize: 15,
                        fontWeight:
                            isNext ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(height: 3),
                      Text(
                        nextPrayerLabel,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isNext)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 9),
                  child: Icon(
                    Icons.radio_button_checked_rounded,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              Text(
                formattedTime,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: isNext ? AppColors.gold : surfaceText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
