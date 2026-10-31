
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
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

  String t(String ar, String en) => isArabic ? ar : en;

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
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String get dateText {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'qibla':
        _openPage(context, const QiblaPage());
        break;

      case 'quran':
        _openPage(context, const QuranPage());
        break;

      case 'adhan':
        _showMessage(context, t(
          'خدمة الأذان قيد التطوير',
          'Adhan service is under development',
        ));
        break;

      case 'adhkar':
        _showMessage(context, t(
          'قسم الأذكار قيد التطوير',
          'Adhkar section is under development',
        ));
        break;

      default:
        _showMessage(context, t(
          'هذه الميزة ستتوفر قريباً',
          'This feature will be available soon',
        ));
    }
  }

  void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Selector<PrayerController, _HomeSnapshot>(
        selector: (_, controller) => _HomeSnapshot(
          prayerTimes: controller.prayerTimes,
          nextPrayer: controller.nextPrayer,
          city: controller.city,
          isLoadingLocation: controller.isLoadingLocation,
          message: controller.message,
        ),
        builder: (context, snapshot, child) {
          if (snapshot.prayerTimes == null) {
            return _LoadingView(
              isArabic: isArabic,
              message: snapshot.message,
              onRetry: () {
                context.read<PrayerController>()
                    .retryInitialization();
              },
            );
          }

          return Scaffold(
            body: Stack(
              children: [
                const _BackgroundDecorations(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding =
                          constraints.maxWidth > 700 ? 40.0 : 19.0;

                      final contentWidth =
                          constraints.maxWidth > 900
                              ? 820.0
                              : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentWidth,
                          ),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              10,
                              horizontalPadding,
                              30,
                            ),
                            children: [
                              _TopBar(
                                isArabic: isArabic,
                                isDark: isDark,
                                city: snapshot.city,
                                date: dateText,
                                onLanguageToggle:
                                    onLanguageToggle,
                                onThemeToggle: onThemeToggle,
                              ),

                              const SizedBox(height: 23),

                              PrayerHeroCard(
                                controller:
                                    context.read<PrayerController>(),
                                isArabic: isArabic,
                                prayerName: prayerName,
                                formatTime: formatTime,
                              ),

                              const SizedBox(height: 30),

                              _SectionTitle(
                                title: t(
                                  'الوصول السريع',
                                  'Quick access',
                                ),
                                subtitle: t(
                                  'كل ما تحتاجه في مكان واحد',
                                  'Your daily essentials',
                                ),
                              ),

                              const SizedBox(height: 14),

                              QuickActions(
                                isArabic: isArabic,
                                onAction: (action) =>
                                    _handleQuickAction(
                                  context,
                                  action,
                                ),
                              ),

                              const SizedBox(height: 30),

                              PrayerScheduleSection(
                                prayerTimes: snapshot.prayerTimes!,
                                nextPrayer: snapshot.nextPrayer,
                                isArabic: isArabic,
                                prayerName: prayerName,
                                formatTime: formatTime,
                              ),

                              const SizedBox(height: 18),

                              _LocationButton(
                                isArabic: isArabic,
                                isLoading:
                                    snapshot.isLoadingLocation,
                                onPressed: () {
                                  context
                                      .read<PrayerController>()
                                      .updateLocation();
                                },
                              ),

                              if (snapshot.message != null) ...[
                                const SizedBox(height: 12),
                                _MessageCard(
                                  message: snapshot.message!,
                                ),
                              ],

                              const SizedBox(height: 24),

                              _Footer(isArabic: isArabic),
                            ],
                          ),
                        ),
                      );
                    },
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

// Only changes to these fields rebuild the main page.
// A notification from the controller every second does not,
// by itself, cause a rebuild if these values remain unchanged.
class _HomeSnapshot {
  const _HomeSnapshot({
    required this.prayerTimes,
    required this.nextPrayer,
    required this.city,
    required this.isLoadingLocation,
    required this.message,
  });

  final PrayerTimes? prayerTimes;
  final Prayer? nextPrayer;
  final String city;
  final bool isLoadingLocation;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is _HomeSnapshot &&
        identical(prayerTimes, other.prayerTimes) &&
        nextPrayer == other.nextPrayer &&
        city == other.city &&
        isLoadingLocation == other.isLoadingLocation &&
        message == other.message;
  }

  @override
  int get hashCode => Object.hash(
        identityHashCode(prayerTimes),
        nextPrayer,
        city,
        isLoadingLocation,
        message,
      );
}

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -150,
              right: -110,
              child: _GlowCircle(
                color: Color(0x1F00A878),
                size: 310,
              ),
            ),
            Positioned(
              top: 420,
              left: -160,
              child: _GlowCircle(
                color: Color(0x0CDBAD50),
                size: 300,
              ),
            ),
          ],
        ),
      ),
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
    return RepaintBoundary(
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isArabic,
    required this.isDark,
    required this.city,
    required this.date,
    required this.onLanguageToggle,
    required this.onThemeToggle,
  });

  final bool isArabic;
  final bool isDark;
  final String city;
  final String date;
  final VoidCallback onLanguageToggle;
  final VoidCallback onThemeToggle;

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
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '$city • $date',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.55),
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
            isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: AppColors.gold,
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
    final color = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: color.withValues(alpha: 0.52),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.isArabic,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isArabic;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.my_location_rounded),
        label: Text(
          isLoading
              ? (isArabic
                  ? 'جارٍ تحديد الموقع...'
                  : 'Getting location...')
              : (isArabic
                  ? 'تحديث موقعي الحالي'
                  : 'Update my location'),
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
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 15,
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: isArabic
          ? 'مسلمز برو، صلاتك نور يومك'
          : 'Muslims Pro, let prayer illuminate your day',
      child: Column(
        children: [
          const Icon(
            Icons.mosque_rounded,
            color: AppColors.gold,
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'صلاتك نور يومك'
                : 'Let prayer illuminate your day',
            style: TextStyle(
              color: color.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.isArabic,
    required this.message,
    required this.onRetry,
  });

  final bool isArabic;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.gold,
                  size: 38,
                ),
                const SizedBox(height: 22),
                const CircularProgressIndicator(
                  color: AppColors.emeraldLight,
                ),
                const SizedBox(height: 20),
                Text(
                  isArabic
                      ? 'جارٍ تجهيز مواقيت الصلاة...'
                      : 'Preparing prayer times...',
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(
                      isArabic ? 'إعادة المحاولة' : 'Retry',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
