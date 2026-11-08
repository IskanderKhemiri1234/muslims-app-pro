import 'package:flutter/material.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_hijri_localizations.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../domain/services/hijri_date_calculator.dart';

/// Independent home card for the estimated Hijri date.
///
/// This widget:
/// - Uses the same local arithmetic Hijri calculator as the calendar page.
/// - Does not request location permission.
/// - Does not access the network.
/// - Does not modify prayer calculations or Quran data.
/// - Opens the full calendar page through [onTap].
class HijriCalendarHomeCard extends StatelessWidget {
  const HijriCalendarHomeCard({
    super.key,
    required this.localizations,
    required this.onTap,
    this.date,
  });

  final MuminLocalizations localizations;
  final VoidCallback onTap;

  /// Optional date for deterministic rendering and widget tests.
  /// Defaults to the device's current local date.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final currentDate = date ?? DateTime.now();

    final hijriDate = HijriDateCalculator.fromGregorian(
      DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      ),
    );

    final monthName = MuminHijriLocalizations.monthName(
      localizations,
      hijriDate.month,
    );

    final title = MuminHijriLocalizations.title(localizations);
    final todayLabel =
        MuminHijriLocalizations.todayLabel(localizations);
    final estimatedLabel =
        MuminHijriLocalizations.estimatedLabel(localizations);

    final foreground = MuminColors.primaryText(brightness);
    final secondary = MuminColors.secondaryText(brightness);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MuminMotion.smooth,
      curve: MuminMotion.enter,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(MuminRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MuminRadius.xl),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isDark
                  ? MuminGradients.midnight
                  : MuminGradients.lightSurface,
              borderRadius: BorderRadius.circular(MuminRadius.xl),
              border: Border.all(
                color: MuminColors.gold.withValues(
                  alpha: isDark ? 0.38 : 0.48,
                ),
              ),
              boxShadow: isDark
                  ? MuminElevation.darkCard
                  : MuminElevation.lightCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(MuminSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 330;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HijriDateEmblem(
                        day: hijriDate.day,
                        compact: compact,
                      ),
                      SizedBox(
                        width: compact
                            ? MuminSpacing.sm
                            : MuminSpacing.lg,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              todayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '$monthName ${hijriDate.year} AH',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? MuminColors.goldLight
                                    : MuminColors.deepEmerald,
                                fontSize: compact ? 13 : 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              estimatedLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 9,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        localizations.isRightToLeft
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: MuminColors.gold,
                        size: 25,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HijriDateEmblem extends StatelessWidget {
  const _HijriDateEmblem({
    required this.day,
    required this.compact,
  });

  final int day;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 62.0 : 72.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: MuminGradients.emerald,
        borderRadius: BorderRadius.circular(MuminRadius.lg),
        border: Border.all(
          color: MuminColors.gold.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: MuminElevation.emeraldGlow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            right: 9,
            child: Icon(
              Icons.star_rounded,
              size: 13,
              color: MuminColors.goldLight.withValues(alpha: 0.8),
            ),
          ),
          Text(
            '$day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MuminColors.warmWhite,
              fontSize: compact ? 27 : 31,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
