
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../prayer_times/presentation/widgets/countdown_widget.dart';
import 'glass_container.dart';

/// Premium next-prayer hero card.
///
/// The public constructor remains backward compatible with existing
/// PrayerHomePage integrations.
class PrayerHeroCard extends StatelessWidget {
  const PrayerHeroCard({
    super.key,
    required this.controller,
    required this.isArabic,
    required this.prayerName,
    required this.formatTime,
  });

  final PrayerController controller;

  /// Retained for compatibility with existing callers.
  ///
  /// The active application locale takes precedence.
  final bool isArabic;

  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;

  MuminLocalizations _resolveLocalizations(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;

    return MuminLocalizations.fromCode(
      localeCode.isEmpty ? (isArabic ? 'ar' : 'en') : localeCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _resolveLocalizations(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: reduceMotion ? 1 : 0.97,
        end: 1,
      ),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _HeroSurface(
            nextPrayer: controller.nextPrayer,
            nextTime: controller.nextPrayerTime,
            localizations: localizations,
            prayerName: prayerName,
            formatTime: formatTime,
            controller: controller,
            reduceMotion: reduceMotion,
          );
        },
      ),
    );
  }
}

class _HeroSurface extends StatelessWidget {
  const _HeroSurface({
    required this.nextPrayer,
    required this.nextTime,
    required this.localizations,
    required this.prayerName,
    required this.formatTime,
    required this.controller,
    required this.reduceMotion,
  });

  final Prayer? nextPrayer;
  final DateTime? nextTime;
  final MuminLocalizations localizations;
  final String Function(Prayer) prayerName;
  final String Function(DateTime) formatTime;
  final PrayerController controller;
  final bool reduceMotion;

  String get _unavailableLabel {
    return localizations.text('unavailable');
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayer = nextPrayer;
    final currentTime = nextTime;

    final hasNextPrayer = currentPrayer != null && currentTime != null;

    final prayerLabel = hasNextPrayer
        ? prayerName(currentPrayer)
        : _unavailableLabel;

    final animationKey = '${currentPrayer?.name ?? 'unavailable'}_'
        '${currentTime?.millisecondsSinceEpoch ?? 'none'}';

    return Container(
      width: double.infinity,
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
              _HeroHeader(localizations: localizations),
              const SizedBox(height: 23),
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
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
                  key: ValueKey<String>(animationKey),
                  width: double.infinity,
                  child: Text(
                    prayerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 37,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              if (hasNextPrayer) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      formatTime(currentTime),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _CountdownPanel(
                controller: controller,
                localizations: localizations,
              ),
              const SizedBox(height: 16),
              _HeroFooter(localizations: localizations),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  String get _todayLabel {
    switch (localizations.languageCode) {
      case 'ar':
        return 'اليوم';
      case 'fr':
        return 'AUJOURD’HUI';
      default:
        return 'TODAY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = localizations.isArabic;

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
            localizations.nextPrayer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: isArabic ? 0 : 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
                _todayLabel,
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
    required this.localizations,
  });

  final PrayerController controller;
  final MuminLocalizations localizations;

  String get _remainingTimeLabel {
    switch (localizations.languageCode) {
      case 'ar':
        return 'الوقت المتبقي للصلاة';
      case 'fr':
        return 'TEMPS RESTANT AVANT LA PRIÈRE';
      default:
        return 'TIME REMAINING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = localizations.isArabic;

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
            _remainingTimeLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: isArabic ? 0 : 0.8,
            ),
          ),
          const SizedBox(height: 13),
          CountdownWidget(
            controller: controller,
            isArabic: isArabic,
          ),
        ],
      ),
    );
  }
}

class _HeroFooter extends StatelessWidget {
  const _HeroFooter({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  String get _footerMessage {
    switch (localizations.languageCode) {
      case 'ar':
        return 'يتم تحديث العداد تلقائيًا';
      case 'fr':
        return 'Le compte à rebours se met à jour automatiquement';
      default:
        return 'Countdown updates automatically';
    }
  }

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
            _footerMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.35,
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
