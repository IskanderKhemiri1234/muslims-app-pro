import 'dart:async';

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

class PrayerHomePage extends StatefulWidget {
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

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage>
    with WidgetsBindingObserver {
  late DateTime _currentDate;
  Timer? _midnightTimer;
  bool _isRetrying = false;

  bool get _isArabic => widget.isArabic;

  String _t(String arabic, String english) {
    return _isArabic ? arabic : english;
  }

  @override
  void initState() {
    super.initState();

    _currentDate = DateTime.now();

    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void didUpdateWidget(covariant PrayerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isArabic != widget.isArabic ||
        oldWidget.isDark != widget.isDark) {
      // The framework rebuilds this widget automatically.
      // No additional synchronization is required here.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDate();
      _scheduleMidnightRefresh();
    }
  }

  void _refreshDate() {
    if (!mounted) return;

    final now = DateTime.now();

    if (_isSameDate(_currentDate, now)) return;

    setState(() {
      _currentDate = now;
    });
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();

    final now = DateTime.now();

    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    final delay = nextMidnight.difference(now) +
        const Duration(seconds: 1);

    _midnightTimer = Timer(delay, () {
      if (!mounted) return;

      _refreshDate();
      _scheduleMidnightRefresh();
    });
  }

  String _prayerName(Prayer prayer) {
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying || !mounted) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await context.read<PrayerController>().retryInitialization();
    } catch (error, stackTrace) {
      debugPrint('Prayer initialization retry failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  void _handleQuickAction(BuildContext context, String action) {
    switch (action) {
      case 'qibla':
        _openPage(context, const QiblaPage());
        return;

      case 'quran':
        _openPage(context, const QuranPage());
        return;

      case 'adhan':
        _showMessage(
          context,
          _t(
            'خدمة الأذان قيد التطوير',
            'Adhan service is under development',
          ),
        );
        return;

      case 'adhkar':
        _showMessage(
          context,
          _t(
            'قسم الأذكار قيد التطوير',
            'Adhkar section is under development',
          ),
        );
        return;

      default:
        _showMessage(
          context,
          _t(
            'هذه الميزة ستتوفر قريباً',
            'This feature will be available soon',
          ),
        );
    }
  }

  void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Selector<PrayerController, _HomeSnapshot>(
        selector: (_, controller) {
          return _HomeSnapshot(
            prayerTimes: controller.prayerTimes,
            nextPrayer: controller.nextPrayer,
            nextPrayerTime: controller.nextPrayerTime,
            city: controller.city,
            isLoadingLocation: controller.isLoadingLocation,
            message: controller.message,
          );
        },
        builder: (context, snapshot, _) {
          final prayerTimes = snapshot.prayerTimes;

          if (prayerTimes == null) {
            return _LoadingView(
              isArabic: _isArabic,
              message: snapshot.message,
              isRetrying: _isRetrying,
              onRetry: _retryInitialization,
            );
          }

          final message = snapshot.message;

          return Scaffold(
            body: Stack(
              children: [
                const _BackgroundDecorations(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      final horizontalPadding = width >= 900
                          ? 40.0
                          : width >= 600
                              ? 28.0
                              : 19.0;

                      final contentWidth = width >= 900
                          ? 820.0
                          : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentWidth,
                          ),
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior
                                    .onDrag,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              10,
                              horizontalPadding,
                              30,
                            ),
                            children: [
                              _TopBar(
                                isArabic: _isArabic,
                                isDark: widget.isDark,
                                city: snapshot.city,
                                date: _formatDate(_currentDate),
                                onLanguageToggle:
                                    widget.onLanguageToggle,
                                onThemeToggle:
                                    widget.onThemeToggle,
                              ),

                              const SizedBox(height: 23),

                              PrayerHeroCard(
                                controller:
                                    context.read<PrayerController>(),
                                isArabic: _isArabic,
                                prayerName: _prayerName,
                                formatTime: _formatTime,
                              ),

                              const SizedBox(height: 30),

                              _SectionTitle(
                                title: _t(
                                  'الوصول السريع',
                                  'Quick access',
                                ),
                                subtitle: _t(
                                  'كل ما تحتاجه في مكان واحد',
                                  'Your daily essentials',
                                ),
                              ),

                              const SizedBox(height: 14),

                              QuickActions(
                                isArabic: _isArabic,
                                onAction: (action) {
                                  _handleQuickAction(
                                    context,
                                    action,
                                  );
                                },
                              ),

                              const SizedBox(height: 30),

                              PrayerScheduleSection(
                                prayerTimes: prayerTimes,
                                nextPrayer: snapshot.nextPrayer,
                                isArabic: _isArabic,
                                prayerName: _prayerName,
                                formatTime: _formatTime,
                              ),

                              const SizedBox(height: 18),

                              _LocationButton(
                                isArabic: _isArabic,
                                isLoading:
                                    snapshot.isLoadingLocation,
                                onPressed: () {
                                  context
                                      .read<PrayerController>()
                                      .updateLocation();
                                },
                              ),

                              if (message != null) ...[
                                const SizedBox(height: 12),
                                _MessageCard(
                                  message: message,
                                ),
                              ],

                              const SizedBox(height: 24),

                              _Footer(isArabic: _isArabic),
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

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.prayerTimes,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.city,
    required this.isLoadingLocation,
    required this.message,
  });

  final PrayerTimes? prayerTimes;
  final Prayer? nextPrayer;
  final DateTime? nextPrayerTime;
  final String city;
  final bool isLoadingLocation;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is _HomeSnapshot &&
        identical(prayerTimes, other.prayerTimes) &&
        nextPrayer == other.nextPrayer &&
        nextPrayerTime == other.nextPrayerTime &&
        city == other.city &&
        isLoadingLocation == other.isLoadingLocation &&
        message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(
      identityHashCode(prayerTimes),
      nextPrayer,
      nextPrayerTime,
      city,
      isLoadingLocation,
      message,
    );
  }
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
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Row(
      children: [
        Semantics(
          image: true,
          label: isArabic
              ? 'شعار مسجد مسلمز برو'
              : 'Muslims Pro mosque logo',
          child: Container(
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
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muslims Pro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

                  Expanded(
                    child: Text(
                      '$city • $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.65),
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
          tooltip: isDark
              ? (isArabic ? 'الوضع الفاتح' : 'Light mode')
              : (isArabic ? 'الوضع الداكن' : 'Dark mode'),
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
            color: color.withValues(alpha: 0.65),
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
      width: double.infinity,
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
          textAlign: TextAlign.center,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(55),
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
  const _MessageCard({
    required this.message,
  });

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
  const _Footer({
    required this.isArabic,
  });

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
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withValues(alpha: 0.65),
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
    required this.isRetrying,
    required this.onRetry,
  });

  final bool isArabic;
  final String? message;
  final bool isRetrying;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final displayMessage = message?.trim();
    final hasError =
        displayMessage != null && displayMessage.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mosque_rounded,
                    color: AppColors.gold,
                    size: 42,
                  ),

                  const SizedBox(height: 22),

                  if (!hasError)
                    const CircularProgressIndicator(
                      color: AppColors.emeraldLight,
                    )
                  else
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 38,
                      color: AppColors.gold,
                    ),

                  const SizedBox(height: 20),

                  Text(
                    hasError
                        ? (isArabic
                            ? 'تعذر تجهيز مواقيت الصلاة'
                            : 'Unable to prepare prayer times')
                        : (isArabic
                            ? 'جارٍ تجهيز مواقيت الصلاة...'
                            : 'Preparing prayer times...'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  if (hasError && displayMessage != null) ...[
                    const SizedBox(height: 12),

                    Text(
                      displayMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isRetrying
                            ? null
                            : () {
                                onRetry();
                              },
                        icon: isRetrying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          isRetrying
                              ? (isArabic
                                  ? 'جارٍ إعادة المحاولة...'
                                  : 'Retrying...')
                              : (isArabic
                                  ? 'إعادة المحاولة'
                                  : 'Try again'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
