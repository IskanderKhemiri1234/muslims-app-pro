
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/prayer_controller.dart';

/// Centralized, accessible and animated prayer countdown.
///
/// Language identity and text direction are resolved through
/// MuminLanguageRegistry and MuminLocalizations.
class CountdownWidget extends StatelessWidget {
  const CountdownWidget({
    super.key,
    required this.controller,
  });

  final PrayerController controller;

  static const Duration _animationDuration =
      Duration(milliseconds: 220);

  static const double _timeUnitWidth = 68;

  MuminLocalizations _resolveLocalizations(
    BuildContext context,
  ) {
    final languageCode =
        Localizations.localeOf(context).languageCode;

    return MuminLocalizations.fromCode(languageCode);
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _localizedUnit(
    int value,
    String unit,
    MuminLocalizations localizations,
  ) {
    return localizations.plural(
      'countdown_$unit',
      value,
    );
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

    return localizations.textWith(
      'countdown_semantic_label',
      {
        'hours': '$hours $hourText',
        'minutes': '$minutes $minuteText',
        'seconds': '$seconds $secondText',
      },
    );
  }

  String _noUpcomingPrayerLabel(
    MuminLocalizations localizations,
  ) {
    return localizations.text(
      'countdown_no_upcoming_prayer',
    );
  }

  String _hourLabel(
    MuminLocalizations localizations,
  ) {
    return localizations.text('countdown_hours_label');
  }

  String _minuteLabel(
    MuminLocalizations localizations,
  ) {
    return localizations.text('countdown_minutes_label');
  }

  String _secondLabel(
    MuminLocalizations localizations,
  ) {
    return localizations.text('countdown_seconds_label');
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
    final languageCode =
        Localizations.localeOf(context).languageCode;

    final isRightToLeft =
        MuminLanguageRegistry.isRightToLeft(languageCode);

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
              textDirection: isRightToLeft
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 9,
                letterSpacing: isRightToLeft ? 0 : 0.7,
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
