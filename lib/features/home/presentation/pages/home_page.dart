
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/prayer_hero_card.dart';
import '../widgets/prayer_schedule_section.dart';
import '../widgets/quick_actions.dart';

class PrayerHomePage extends StatelessWidget {
  const PrayerHomePage({
    super.key,
    required this.isArabic,
    required this.onLanguageToggle,
    required this.isDark,
    required this.onThemeToggle,
  });

  final bool isArabic;
  final VoidCallback onLanguageToggle;
  final bool isDark;
  final VoidCallback onThemeToggle;

  String t(String arabic, String english) {
    return isArabic ? arabic : english;
  }

  String prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return t('الفجر', 'Fajr');
      case Prayer.sunrise:
        return t('الشروق', 'Sunrise');
      case Prayer.dhuhr:
        return t('الظهر', 'Dhuhr');
      case Prayer.asr:
        return t('العصر', 'Asr');
      case Prayer.maghrib:
        return t('المغرب', 'Maghrib');
      case Prayer.isha:
        return t('العشاء', 'Isha');
      default:
        return t('غير متاح', 'Unavailable');
    }
  }

  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateText() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  void _showActionMessage(BuildContext context, String action) {
    final labels = {
      'qibla': t('ميزة القبلة قيد التجهيز', 'Qibla feature is coming soon'),
      'quran': t('قسم القرآن قيد التجهيز', 'Quran section is coming soon'),
      'adhan': t('خدمة الأذان قيد التجهيز', 'Adhan service is coming soon'),
      'adhkar': t('قسم الأذكار قيد التجهيز', 'Adhkar section is coming soon'),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(labels[action] ?? t('قريبًا', 'Coming soon')),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Consumer<PrayerController>(
        builder: (context, controller, child) {
          final prayerTimes = controller.prayerTimes;

          if (prayerTimes == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.emeraldLight,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t(
                        'جارٍ تجهيز مواقيت الصلاة...',
                        'Preparing prayer times...',
                      ),
                    ),
                    if (controller.message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        controller.message!,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: controller.retryInitialization,
                        child: Text(t('إعادة المحاولة', 'Retry')),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: -150,
                  right: -110,
                  child: _GlowCircle(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    size: 310,
                  ),
                ),
                Positioned(
                  top: 420,
                  left: -160,
                  child: _GlowCircle(
                    color: AppColors.gold.withValues(alpha: 0.045),
                    size: 300,
                  ),
                ),
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(19, 10, 19, 30),
                    children: [
                      _TopBar(
                        isArabic: isArabic,
                        isDark: isDark,
                        city: controller.city,
                        date: _dateText(),
                        onLanguageToggle: onLanguageToggle,
                        onThemeToggle: onThemeToggle,
                        isLoadingLocation: controller.isLoadingLocation,
                      ),
                      const SizedBox(height: 23),
                      PrayerHeroCard(
                        controller: controller,
                        isArabic: isArabic,
                        prayerName: prayerName,
                        formatTime: formatTime,
                      ),
                      const SizedBox(height: 30),
                      _SectionTitle(
                        title: t('الوصول السريع', 'Quick access'),
                        subtitle: t(
                          'كل ما تحتاجه في مكان واحد',
                          'Your daily essentials',
                        ),
                      ),
                      const SizedBox(height: 14),
                      QuickActions(
                        isArabic: isArabic,
                        onAction: (action) {
                          _showActionMessage(context, action);
                        },
                      ),
                      const SizedBox(height: 30),
                      PrayerScheduleSection(
                        prayerTimes: prayerTimes,
                        nextPrayer: controller.nextPrayer,
                        isArabic: isArabic,
                        prayerName: prayerName,
                        formatTime: formatTime,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoadingLocation
                              ? null
                              : controller.updateLocation,
                          icon: controller.isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: Text(
                            controller.isLoadingLocation
                                ? t('جارٍ تحديد الموقع...', 'Getting location...')
                                : t('تحديث موقعي الحالي', 'Update my location'),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emeraldLight,
                            side: BorderSide(
                              color: AppColors.emerald.withValues(alpha: 0.45),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                      ),
                      if (controller.message != null) ...[
                        const SizedBox(height: 12),
                        GlassContainer(
                          radius: 15,
                          child: Text(
                            controller.message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.mosque_rounded,
                              color: AppColors.gold,
                              size: 23,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(
                                'صلاتك نور يومك',
                                'Let prayer illuminate your day',
                              ),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isArabic,
    required this.isDark,
    required this.city,
    required this.date,
    required this.onLanguageToggle,
    required this.onThemeToggle,
    required this.isLoadingLocation,
  });

  final bool isArabic;
  final bool isDark;
  final String city;
  final String date;
  final VoidCallback onLanguageToggle;
  final VoidCallback onThemeToggle;
  final bool isLoadingLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.emerald,
                AppColors.deepGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            Icons.mosque_rounded,
            color: AppColors.goldLight,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muslims Pro',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '$city  •  $date',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onPressed: onThemeToggle,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: AppColors.gold,
            size: 21,
          ),
        ),
        TextButton(
          onPressed: onLanguageToggle,
          child: Text(
            isArabic ? 'EN' : 'عربي',
            style: const TextStyle(
              color: AppColors.emeraldLight,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.52),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
