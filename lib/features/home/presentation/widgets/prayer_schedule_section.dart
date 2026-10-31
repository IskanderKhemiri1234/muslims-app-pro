
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'glass_container.dart';

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
  final Prayer nextPrayer;
  final bool isArabic;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;

  static const List<Prayer> prayers = [
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
        return Icons.wb_twilight;
      case Prayer.isha:
        return Icons.nights_stay_rounded;
      default:
        return Icons.mosque_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isArabic ? 'مواقيت الصلاة' : 'Prayer times',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              color: AppColors.gold,
              size: 21,
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...prayers.map((prayer) {
          final time = prayerTimes.timeForPrayer(prayer);

          if (time == null) {
            return const SizedBox.shrink();
          }

          final isNext = prayer == nextPrayer &&
              prayer != Prayer.none &&
              prayer != Prayer.sunrise;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              radius: 19,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              color: isNext
                  ? AppColors.emerald.withValues(
                      alpha: isDark ? 0.22 : 0.09,
                    )
                  : null,
              borderColor: isNext
                  ? AppColors.gold.withValues(alpha: 0.42)
                  : null,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: isNext
                          ? AppColors.emerald
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : AppColors.emerald.withValues(alpha: 0.08)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _iconFor(prayer),
                      color: isNext
                          ? Colors.white
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
                          prayerName(prayer),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface,
                            fontSize: 15,
                            fontWeight: isNext
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        if (isNext) ...[
                          const SizedBox(height: 3),
                          Text(
                            isArabic ? 'الصلاة القادمة' : 'Next prayer',
                            style: const TextStyle(
                              color: AppColors.emeraldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isNext)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 9),
                      child: Icon(
                        Icons.radio_button_checked_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ),
                  Text(
                    formatTime(time),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: isNext
                          ? AppColors.gold
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
