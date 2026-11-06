
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

/// Localized, accessible and animated prayer countdown.
///
/// Keeps the existing public API compatible with current callers.
class CountdownWidget extends StatelessWidget {
  const CountdownWidget({
    super.key,
    required this.controller,
    this.isArabic = false,
  });

  final PrayerController controller;

  /// Backward-compatible fallback for callers that do not provide
  /// an application locale.
  final bool isArabic;

  static const Duration _animationDuration =
      Duration(milliseconds: 220);

  static const double _timeUnitWidth = 68;

  MuminLocalizations _resolveLocalizations(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return MuminLocalizations.fromCode(
      localeCode.isEmpty ? (isArabic ? 'ar' : 'en') : localeCode,
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _arabicUnit(int value, String unit) {
    if (value == 2) {
      switch (unit) {
        case 'hour':
          return 'ساعتان';
        case 'minute':
          return 'دقيقتان';
        default:
          return 'ثانيتان';
      }
    }

    if (value >= 3 && value <= 10) {
      switch (unit) {
        case 'hour':
          return 'ساعات';
        case 'minute':
          return 'دقائق';
        default:
          return 'ثوانٍ';
      }
    }

    switch (unit) {
      case 'hour':
        return 'ساعة';
      case 'minute':
        return 'دقيقة';
      default:
        return 'ثانية';
    }
  }

  String _englishUnit(int value, String unit) {
    final suffix = value == 1 ? '' : 's';

    switch (unit) {
      case 'hour':
        return 'hour$suffix';
      case 'minute':
        return 'minute$suffix';
      default:
        return 'second$suffix';
    }
  }

  String _frenchUnit(int value, String unit) {
    final suffix = value == 1 ? '' : 's';

    switch (unit) {
      case 'hour':
        return 'heure$suffix';
      case 'minute':
        return 'minute$suffix';
      default:
        return 'seconde$suffix';
    }
  }

  String _localizedUnit(
    int value,
    String unit,
    MuminLocalizations localizations,
  ) {
    switch (localizations.languageCode) {
      case 'ar':
        return _arabicUnit(value, unit);
      case 'fr':
        return _frenchUnit(value, unit);
      default:
        return _englishUnit(value, unit);
    }
  }

  String _semanticLabel(
    Duration duration,
    MuminLocalizations localizations,
  ) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hourText = _localizedUnit(
      hours,
      'hour',
      localizations,
    );

    final minuteText = _localizedUnit(
      minutes,
      'minute',
      localizations,
    );

    final secondText = _localizedUnit(
      seconds,
      'second',
      localizations,
    );

    switch (localizations.languageCode) {
      case 'ar':
        return 'الوقت المتبقي: '
            '$hours $hourText و'
            '$minutes $minuteText و'
            '$seconds $secondText';

      case 'fr':
        return 'Temps restant : '
            '$hours $hourText, '
            '$minutes $minuteText et '
            '$seconds $secondText';

      default:
        return 'Time remaining: '
            '$hours $hourText, '
            '$minutes $minuteText and '
            '$seconds $secondText';
    }
  }

  String _noUpcomingPrayerLabel(
    MuminLocalizations localizations,
  ) {
    switch (localizations.languageCode) {
      case 'ar':
        return 'لا يوجد موعد صلاة قادم متاح';
      case 'fr':
        return 'Aucun horaire de prière à venir disponible';
      default:
        return 'No upcoming prayer time available';
    }
  }

  String _hourLabel(MuminLocalizations localizations) {
    switch (localizations.languageCode) {
      case 'ar':
        return 'ساعات';
      case 'fr':
        return 'HEURES';
      default:
        return 'HOURS';
    }
  }

  String _minuteLabel(MuminLocalizations localizations) {
    switch (localizations.languageCode) {
      case 'ar':
        return 'دقائق';
      case 'fr':
        return 'MINUTES';
      default:
        return 'MINUTES';
    }
  }

  String _secondLabel(MuminLocalizations localizations) {
    switch (localizations.languageCode) {
      case 'ar':
        return 'ثوانٍ';
      case 'fr':
        return 'SECONDES';
      default:
        return 'SECONDS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _resolveLocalizations(context);

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final animationDuration = reduceMotion
        ? Duration.zero
        : _animationDuration;

    return RepaintBoundary(
      child: ValueListenableBuilder<DateTime>(
        valueListenable: controller.clockListenable,
        builder: (context, now, child) {
          final target = controller.nextPrayerTime;
          final difference = target?.difference(now);

          final duration =
              difference == null || difference.isNegative
                  ? Duration.zero
                  : difference;

          final hasTarget = target != null;

          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);
          final seconds = duration.inSeconds.remainder(60);

          final hourValue = hasTarget
              ? _twoDigits(hours)
              : '--';

          final minuteValue = hasTarget
              ? _twoDigits(minutes)
              : '--';

          final secondValue = hasTarget
              ? _twoDigits(seconds)
              : '--';

          final semanticLabel = hasTarget
              ? _semanticLabel(duration, localizations)
              : _noUpcomingPrayerLabel(localizations);

          return Semantics(
            container: true,
            liveRegion: false,
            label: semanticLabel,
            child: ExcludeSemantics(
              child: Center(
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimeUnit(
                      value: hourValue,
                      label: _hourLabel(localizations),
                      duration: animationDuration,
                    ),
                    const _TimeSeparator(),
                    _TimeUnit(
                      value: minuteValue,
                      label: _minuteLabel(localizations),
                      duration: animationDuration,
                    ),
                    const _TimeSeparator(),
                    _TimeUnit(
                      value: secondValue,
                      label: _secondLabel(localizations),
                      highlighted: true,
                      duration: animationDuration,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.duration,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final Duration duration;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return SizedBox(
      width: CountdownWidget._timeUnitWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: highlighted
                    ? AppColors.goldLight
                    : Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              textDirection: isArabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 9,
                letterSpacing: isArabic ? 0 : 0.7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 5,
        right: 5,
        bottom: 14,
      ),
      child: Text(
        ':',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          color: AppColors.gold,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
