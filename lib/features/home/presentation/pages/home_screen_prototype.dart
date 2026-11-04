import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';

class HomeScreenPrototype extends StatelessWidget {
  const HomeScreenPrototype({
    super.key,
    this.isArabic = true,
    this.onLanguageToggle,
    this.onSettingsTap,
    this.onNotificationsTap,
    this.onAdhkarTap,
  });

  final bool isArabic;
  final VoidCallback? onLanguageToggle;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAdhkarTap;

  String _t(String ar, String en) => isArabic ? ar : en;

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth >= 700 ? 32.0 : 20.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      28,
                    ),
                    children: [
                      _Header(
                        isArabic: isArabic,
                        onLanguageToggle: onLanguageToggle,
                        onSettingsTap: onSettingsTap,
                        onNotificationsTap: onNotificationsTap,
                        showMessage: (message) =>
                            _showMessage(context, message),
                      ),

                      const SizedBox(height: 28),

                      _Greeting(isArabic: isArabic),

                      const SizedBox(height: 22),

                      Consumer<PrayerController>(
                        builder: (context, controller, _) {
                          return _PrayerCard(
                            isArabic: isArabic,
                            controller: controller,
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      _SectionTitle(
                        title: _t(
                          'مساحتك اليومية',
                          'Your daily space',
                        ),
                        subtitle: _t('كل ما تحتاجه', 'Explore'),
                      ),

                      const SizedBox(height: 15),

                      _QuickActions(
                        isArabic: isArabic,
                        onQuran: () => _openPage(
                          context,
                          const QuranPage(),
                        ),
                        onQibla: () => _openPage(
                          context,
                          const QiblaPage(),
                        ),
                        onAdhkar: onAdhkarTap ??
                            () => _showMessage(
                                  context,
                                  _t(
                                    'قسم الأذكار قيد التطوير',
                                    'Adhkar is coming soon',
                                  ),
                                ),
                        onPrayer: () => _showMessage(
                          context,
                          _t(
                            'أنت في صفحة مواقيت الصلاة',
                            'You are viewing prayer information',
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      _SectionTitle(
                        title: _t(
                          'رحلتك مع القرآن',
                          'Your Quran journey',
                        ),
                        subtitle: _t(
                          'متابعة القراءة',
                          'Continue reading',
                        ),
                      ),

                      const SizedBox(height: 15),

                      _QuranCard(
                        isArabic: isArabic,
                        onTap: () => _openPage(
                          context,
                          const QuranPage(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      _DailyReminder(isArabic: isArabic),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isArabic,
    required this.onLanguageToggle,
    required this.onSettingsTap,
    required this.onNotificationsTap,
    required this.showMessage,
  });

  final bool isArabic;
  final VoidCallback? onLanguageToggle;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final ValueChanged<String> showMessage;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

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
              color: AppColors.gold.withValues(alpha: 0.25),
            ),
          ),
          child: const Icon(
            Icons.mosque_rounded,
            color: AppColors.goldLight,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MUSLIMS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                isArabic ? 'رفيق يومك' : 'Your daily companion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: isArabic ? 'الإشعارات' : 'Notifications',
          onPressed: onNotificationsTap ??
              () => showMessage(
                    isArabic
                        ? 'الإشعارات قيد الإعداد'
                        : 'Notifications are not configured yet',
                  ),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.gold,
          ),
        ),

        IconButton(
          tooltip: isArabic ? 'الإعدادات' : 'Settings',
          onPressed: onSettingsTap ??
              () => showMessage(
                    isArabic
                        ? 'الإعدادات قيد التطوير'
                        : 'Settings are coming soon',
                  ),
          icon: Icon(
            Icons.settings_outlined,
            color: textColor,
          ),
        ),

        if (onLanguageToggle != null)
          TextButton(
            onPressed: onLanguageToggle,
            child: Text(isArabic ? 'EN' : 'عربي'),
          ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'السلام عليكم' : 'Assalamu Alaikum',
          style: TextStyle(
            color: textColor,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          isArabic
              ? 'اجعل يومك عامرًا بالذكر والطمأنينة.'
              : 'Fill your day with remembrance and tranquility.',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.68),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.isArabic,
    required this.controller,
  });

  final bool isArabic;
  final PrayerController controller;

  String _t(String ar, String en) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final nextPrayer = controller.nextPrayer;
    final nextPrayerTime = controller.nextPrayerTime;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final remaining = nextPrayerTime == null
        ? null
        : nextPrayerTime.difference(DateTime.now());

    final hasValidRemaining =
        remaining != null && !remaining.isNegative;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1C3B2D),
            Color(0xFF102019),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.nights_stay_outlined,
                color: AppColors.gold,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _t('الصلاة القادمة', 'Next prayer'),
                  style: const TextStyle(
                    color: Color(0xFFA9B8B0),
                    fontSize: 13,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _t('المواقيت', 'Prayer times'),
                  style: const TextStyle(
                    color: Color(0xFFB3E3C7),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            controller.prayerTimes == null
                ? _t('جارٍ التحميل', 'Loading')
                : _prayerName(nextPrayer),
            style: const TextStyle(
              color: Color(0xFFF4F1E8),
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _formatTime(nextPrayerTime),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 38,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.14),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.gold,
                size: 17,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  hasValidRemaining
                      ? _remainingText(remaining)
                      : _t(
                          'سيظهر العد التنازلي عند توفر المواقيت',
                          'Countdown will appear when prayer times are available',
                        ),
                  style: const TextStyle(
                    color: Color(0xFFA9B8B0),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            controller.city,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _prayerName(Prayer? prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _t('الفجر', 'Fajr');
      case Prayer.sunrise:
        return _t('الشروق', 'Sunrise');
      case Prayer.dhuhr:
        return _t('الظهر', 'Dhuhr');
      case Prayer.asr:
        return _t('العصر', 'Asr');
      case Prayer.maghrib:
        return _t('المغرب', 'Maghrib');
      case Prayer.isha:
        return _t('العشاء', 'Isha');
      default:
        return _t('غير متاح', 'Unavailable');
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '--:--';
    }

    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _remainingText(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (isArabic) {
      return 'متبقي $hours ساعة و$minutes دقيقة و$seconds ثانية';
    }

    return '$hours hours, $minutes minutes and $seconds seconds remaining';
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
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          subtitle,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.isArabic,
    required this.onQuran,
    required this.onQibla,
    required this.onAdhkar,
    required this.onPrayer,
  });

  final bool isArabic;
  final VoidCallback onQuran;
  final VoidCallback onQibla;
  final VoidCallback onAdhkar;
  final VoidCallback onPrayer;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.menu_book_rounded,
        title: isArabic ? 'القرآن' : 'Quran',
        color: AppColors.gold,
        onTap: onQuran,
      ),
      _ActionData(
        icon: Icons.explore_outlined,
        title: isArabic ? 'القبلة' : 'Qibla',
        color: AppColors.emeraldLight,
        onTap: onQibla,
      ),
      _ActionData(
        icon: Icons.favorite_border_rounded,
        title: isArabic ? 'الأذكار' : 'Adhkar',
        color: AppColors.emeraldLight,
        onTap: onAdhkar,
      ),
      _ActionData(
        icon: Icons.calendar_month_outlined,
        title: isArabic ? 'الصلوات' : 'Prayer',
        color: AppColors.emeraldLight,
        onTap: onPrayer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 340 ? 2 : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 1.35 : 0.85,
          ),
          itemBuilder: (context, index) {
            return _QuickActionTile(
              action: actions[index],
            );
          },
        );
      },
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.action,
  });

  final _ActionData action;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 25,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranCard extends StatelessWidget {
  const _QuranCard({
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 53,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.gold,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'واصل رحلتك مع القرآن'
                          : 'Continue your Quran journey',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isArabic
                          ? 'احفظ موضع قراءتك وتابع ختمتك'
                          : 'Continue reading and track your progress',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isArabic
                    ? Icons.arrow_back_ios_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: AppColors.gold,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyReminder extends StatelessWidget {
  const _DailyReminder({
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.gold,
                size: 18,
              ),

              const SizedBox(width: 9),

              const Text(
                'تذكير اليوم',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.8,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            isArabic ? 'الرعد · 28' : 'Ar-Ra’d · 28',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
