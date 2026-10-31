
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/presentation/widgets/countdown_widget.dart';
import 'glass_container.dart';

class PrayerHeroCard extends StatelessWidget {
  const PrayerHeroCard({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.prayerName,
    required this.formatTime,
  });

  final PrayerController controller;
  final bool isArabic;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final nextPrayer = controller.nextPrayer;
    final nextTime = controller.nextPrayerTime;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.97, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF0B6149),
              Color(0xFF064333),
              Color(0xFF032B25),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.20),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const _HeroDecoration(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(isArabic: isArabic),
                const SizedBox(height: 23),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.10),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      nextTime == null
                          ? (isArabic ? 'غير متاح' : 'Unavailable')
                          : prayerName(nextPrayer),
                      key: ValueKey(nextPrayer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 37,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                if (nextTime != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: AppColors.goldLight,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        formatTime(nextTime),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                _CountdownPanel(
                  controller: controller,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 16),
                _HeroFooter(isArabic: isArabic),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.nights_stay_rounded,
          color: AppColors.goldLight,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            isArabic ? 'الصلاة القادمة' : 'NEXT PRAYER',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: isArabic ? 0 : 2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.goldLight,
                size: 12,
              ),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'مواقيت اليوم' : 'TODAY',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountdownPanel extends StatelessWidget {
  const _CountdownPanel({
    required this.controller,
    required this.isArabic,
  });

  final PrayerController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: Colors.white.withValues(alpha: 0.09),
      borderColor: Colors.white.withValues(alpha: 0.13),
      radius: 21,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الوقت المتبقي للصلاة' : 'TIME REMAINING',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: isArabic ? 0 : 1.4,
            ),
          ),
          const SizedBox(height: 13),
          CountdownWidget(controller: controller),
        ],
      ),
    );
  }
}

class _HeroFooter extends StatelessWidget {
  const _HeroFooter({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: Colors.white.withValues(alpha: 0.55),
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isArabic
                ? 'يتم تحديث العداد تلقائيًا'
                : 'Countdown updates automatically',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -55,
              right: -35,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -75,
              left: -55,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
