
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/mumin_design_tokens.dart';
import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/localization/mumin_hijri_localizations.dart';
import '../../../hijri_calendar/domain/services/hijri_date_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/presentation/widgets/countdown_widget.dart';
import 'glass_container.dart';

/// Premium next-prayer experience for Mumin Pro.
///
/// All language metadata and direction decisions are resolved
/// through the centralized localization architecture.
class PrayerHeroCard extends StatelessWidget {
   const PrayerHeroCard({
    super.key,
    required this.controller,
    required this.prayerName,
    required this.formatTime,
    required this.date,
    required this.onHijriTap,
  });

  final PrayerController controller;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;
  final DateTime date;
  final VoidCallback onHijriTap; 

  MuminLocalizations _resolveLocalizations(BuildContext context) {
    final localeCode =
        Localizations.maybeLocaleOf(context)?.languageCode;

    return MuminLocalizations.fromCode(
      MuminLanguageRegistry.normalizeLanguageCode(
        localeCode ?? MuminLanguageRegistry.defaultLanguageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _resolveLocalizations(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: reduceMotion ? 1 : 0.985,
          end: 1,
        ),
        duration: reduceMotion ? Duration.zero : MuminMotion.smooth,
        curve: MuminMotion.enter,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
                        return _HeroSurface(
              nextPrayer: controller.nextPrayer,
              nextTime: controller.nextPrayerTime,
              controller: controller,
              localizations: localizations,
              prayerName: prayerName,
              formatTime: formatTime,
              reduceMotion: reduceMotion,
              date: date,
              onHijriTap: onHijriTap,
            );
          },
        ),
      ),
    );
  }
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({
    required this.nextPrayer,
    required this.nextTime,
    required this.controller,
    required this.localizations,
    required this.prayerName,
    required this.formatTime,
    required this.reduceMotion,
    required this.date,
    required this.onHijriTap,
  });

  final Prayer? nextPrayer;
  final DateTime? nextTime;
  final PrayerController controller;
  final MuminLocalizations localizations;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;
  final bool reduceMotion;
  final DateTime date;
  final VoidCallback onHijriTap;

  @override
  Widget build(BuildContext context) {
    final currentPrayer = nextPrayer;
    final currentTime = nextTime;

    final hasNextPrayer =
        currentPrayer != null && currentTime != null;

    final prayerLabel = hasNextPrayer
        ? prayerName(currentPrayer)
        : localizations.text('unavailable');

    final hijriDate = HijriDateCalculator.fromGregorian(
      DateTime(date.year, date.month, date.day),
    );

    final hijriMonth = MuminHijriLocalizations.monthName(
      localizations,
      hijriDate.month,
    );

    final hijriSuffix =
        localizations.languageCode == 'ar' ? 'هـ' : 'AH';

    final hijriLabel =
        '${hijriDate.day} $hijriMonth '
        '${hijriDate.year} $hijriSuffix';

    final compact =
        MediaQuery.sizeOf(context).width < 380;

    return Semantics(
      container: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF126C55),
                Color(0xFF084B3B),
                Color(0xFF06372E),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.42),
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF075B46)
                    .withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: _HeroAtmosphere(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.nights_stay_rounded,
                          color: AppColors.goldLight,
                          size: 17,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            localizations.nextPrayer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.goldLight,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Material(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        onTap: onHijriTap,
                        borderRadius: BorderRadius.circular(11),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.goldLight,
                                size: 17,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  hijriLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection:
                                      localizations.isRightToLeft
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Icon(
                                localizations.isRightToLeft
                                    ? Icons.chevron_left_rounded
                                    : Icons.chevron_right_rounded,
                                color: AppColors.goldLight,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localizations.text(
                                  'next_prayer_eyebrow',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.goldLight
                                      .withValues(alpha: 0.88),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 300),
                                child: Text(
                                  prayerLabel,
                                  key: ValueKey<String>(
                                    currentPrayer?.name ??
                                        'unavailable',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 22 : 24,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (hasNextPrayer)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 3),
                                  child: Text(
                                    formatTime(currentTime),
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.085),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.13),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CountdownWidget(
                          controller: controller,
                        ),
                      ),
                    ),
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

/// Lightweight decorative background painted without image assets.
class _HeroAtmosphere extends StatelessWidget {
  const _HeroAtmosphere();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _HeroAtmospherePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _HeroAtmospherePainter extends CustomPainter {
  const _HeroAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final lightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6CCFB0).withValues(alpha: 0.14),
          const Color(0xFF6CCFB0).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.9,
            size.height * 0.08,
          ),
          radius: size.width * 0.65,
        ),
      );

    canvas.drawRect(Offset.zero & size, glowPaint);

    final center = Offset(
      size.width * 0.88,
      size.height * 0.13,
    );

    for (var index = 0; index < 4; index++) {
      final radius = size.width * (0.19 + index * 0.105);
      canvas.drawCircle(
        center,
        radius,
        index.isEven ? goldPaint : lightPaint,
      );
    }

    final geometryPath = Path();
    final startX = size.width * 0.08;
    final startY = size.height * 0.76;

    for (var index = 0; index < 5; index++) {
      final x = startX + index * 24.0;
      final y = startY + (index.isEven ? 0 : 12);

      geometryPath
        ..moveTo(x, y - 7)
        ..lineTo(x + 7, y)
        ..lineTo(x, y + 7)
        ..lineTo(x - 7, y)
        ..close();
    }

    canvas.drawPath(geometryPath, lightPaint);
  }

  @override
  bool shouldRepaint(
    covariant _HeroAtmospherePainter oldDelegate,
  ) {
    return false;
  }
}

// ignore: unused_element
class _HeroTopHighlight extends StatelessWidget {
  const _HeroTopHighlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.65),
            Colors.white.withValues(alpha: 0.20),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  String get _todayLabel =>
      localizations.text('today_label');

  @override
  Widget build(BuildContext context) {
    final isRightToLeft = localizations.isRightToLeft;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.32),
            ),
          ),
          child: const Icon(
            Icons.nights_stay_rounded,
            color: AppColors.goldLight,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            localizations.nextPrayer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: isRightToLeft ? 0 : 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.18),
                AppColors.gold.withValues(alpha: 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.goldLight,
                size: 12,
              ),
              const SizedBox(width: 5),
              Text(
                _todayLabel,
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _PrayerIdentity extends StatelessWidget {
  const _PrayerIdentity({
    required this.prayerLabel,
    required this.animationKey,
    required this.hasNextPrayer,
    required this.currentTime,
    required this.formatTime,
    required this.localizations,
    required this.reduceMotion,
    required this.compact,
  });

  final String prayerLabel;
  final String animationKey;
  final bool hasNextPrayer;
  final DateTime? currentTime;
  final String Function(DateTime) formatTime;
  final MuminLocalizations localizations;
  final bool reduceMotion;
  final bool compact;

  String get _eyebrow =>
      localizations.text('next_prayer_eyebrow');

  @override
  Widget build(BuildContext context) {
    final time = currentTime;
    final isRightToLeft = localizations.isRightToLeft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _eyebrow,
          style: TextStyle(
            color: AppColors.goldLight.withValues(alpha: 0.85),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: isRightToLeft ? 0 : 1.2,
          ),
        ),
        const SizedBox(height: 9),
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.09),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey<String>(animationKey),
            width: double.infinity,
            child: Text(
              prayerLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 34 : 40,
                height: 1.13,
                fontWeight: FontWeight.w900,
                letterSpacing: isRightToLeft ? 0 : -0.7,
              ),
            ),
          ),
        ),
        if (hasNextPrayer && time != null) ...[
          const SizedBox(height: 13),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.26),
                  ),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                formatTime(time),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ignore: unused_element
class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({
    required this.controller,
    required this.localizations,
    required this.compact,
  });

  final PrayerController controller;
  final MuminLocalizations localizations;
  final bool compact;

  String get _remainingTimeLabel =>
      localizations.text('time_remaining');

  @override
  Widget build(BuildContext context) {
    final isRightToLeft = localizations.isRightToLeft;

    return GlassContainer(
      color: Colors.white.withValues(alpha: 0.085),
      borderColor: Colors.white.withValues(alpha: 0.16),
      radius: 23,
      enableBlur: false,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 17,
        vertical: compact ? 14 : 17,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _remainingTimeLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.73),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: isRightToLeft ? 0 : 0.75,
                  ),
                ),
              ),
              const Icon(
                Icons.hourglass_bottom_rounded,
                color: AppColors.goldLight,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 14),
          CountdownWidget(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _HeroFooter extends StatelessWidget {
  const _HeroFooter({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  String get _footerMessage =>
      localizations.text('countdown_auto_update');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.verified_outlined,
          color: AppColors.goldLight,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _footerMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 10,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
