
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
    final prayer = nextPrayer;
    final prayerTime = nextTime;
    final hasPrayer = prayer != null && prayerTime != null;
    final prayerLabel = hasPrayer
        ? prayerName(prayer)
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
        '${hijriMonth} ${hijriDate.day}, ${hijriDate.year} $hijriSuffix';

    final isRtl = localizations.isRightToLeft;
    final foreground = Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07966F),
              Color(0xFF087B5C),
              Color(0xFF064A3B),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.72),
            width: 1.35,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A878).withValues(alpha: 0.19),
              blurRadius: 28,
              spreadRadius: 0.5,
              offset: const Offset(0, 9),
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
            PositionedDirectional(
              end: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/home/mumin_reference_mosque.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        filterQuality: FilterQuality.high,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF087B5C),
                              Color(0x00087B5C),
                            ],
                            stops: [0.0, 0.58],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                17,
                13,
                17,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onHijriTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                hijriLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      prayerLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Icon(
                                    prayer == Prayer.fajr
                                        ? Icons.wb_twilight_rounded
                                        : prayer == Prayer.maghrib
                                            ? Icons.wb_twilight_rounded
                                            : prayer == Prayer.isha
                                                ? Icons.nights_stay_rounded
                                                : Icons.wb_sunny_rounded,
                                    color: AppColors.goldLight,
                                    size: 23,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  hasPrayer
                                      ? formatTime(prayerTime)
                                      : '--:--',
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 39,
                                    height: 1.05,
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
                        const SizedBox(width: 5),
                        const Expanded(
                          flex: 4,
                          child: SizedBox.expand(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.19),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.text('time_remaining'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.88),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CountdownWidget(
                          controller: controller,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
