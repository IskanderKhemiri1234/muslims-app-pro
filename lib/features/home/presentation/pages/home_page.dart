
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../widgets/glass_container.dart';
import '../widgets/prayer_hero_card.dart';
import '../widgets/prayer_schedule_section.dart';
import '../widgets/quick_actions.dart';

/// Main Mumin Pro dashboard.
///
/// The page observes only the prayer data required by its layout.
/// The one-second countdown remains isolated in PrayerHeroCard through
/// PrayerController.clockListenable.
class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({
    super.key,
    required this.isArabic,
    required this.onLanguageToggle,
    required this.isDark,
    required this.onThemeToggle,
  });

  /// Retained for compatibility with existing application callers.
  ///
  /// The active language is resolved from the Flutter application locale.
  final bool isArabic;

  /// Opens the language selector owned by the application root.
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

  MuminLocalizations get _localizations {
    final locale = Localizations.localeOf(context);
    return MuminLocalizations.fromCode(locale.languageCode);
  }

  String _t(String key) => _localizations.text(key);

  @override
  void initState() {
    super.initState();

    _currentDate = DateTime.now();

    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _refreshDate();
        _scheduleMidnightRefresh();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _cancelMidnightRefresh();
        break;
    }
  }

  void _cancelMidnightRefresh() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _refreshDate() {
    if (!mounted) return;

    final now = DateTime.now();

    if (_isSameDate(_currentDate, now)) return;

    setState(() {
      _currentDate = now;
    });
  }

  void _scheduleMidnightRefresh() {
    _cancelMidnightRefresh();

    if (!mounted) return;

    final now = DateTime.now();

    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    final delay = nextMidnight.difference(now) +
        const Duration(seconds: 1);

    _midnightTimer = Timer(delay, _handleMidnightRefresh);
  }

  void _handleMidnightRefresh() {
    if (!mounted) return;

    _refreshDate();
    _scheduleMidnightRefresh();
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _localizations.prayerName('fajr');

      case Prayer.sunrise:
        return _localizations.prayerName('sunrise');

      case Prayer.dhuhr:
        return _localizations.prayerName('dhuhr');

      case Prayer.asr:
        return _localizations.prayerName('asr');

      case Prayer.maghrib:
        return _localizations.prayerName('maghrib');

      case Prayer.isha:
        return _localizations.prayerName('isha');

      default:
        return _t('unavailable');
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying || !mounted) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await context.read<PrayerController>().retryInitialization();
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: prayer initialization retry failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    if (!mounted) return;

    try {
      await context.read<PrayerController>().updateLocation();
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: location update failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(
          context,
          _t('location_permission_required'),
        );
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
          _t('adhan_in_development'),
        );
        return;

      case 'adhkar':
        _showMessage(
          context,
          _t('adhkar_in_development'),
        );
        return;

      default:
        _showMessage(
          context,
          _t('coming_soon'),
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
    _cancelMidnightRefresh();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _localizations;

    return Directionality(
      textDirection: localizations.isRightToLeft
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Selector<PrayerController, _HomeSnapshot>(
        selector: (_, controller) {
          return _HomeSnapshot(
            prayerTimes: controller.prayerTimes,
            nextPrayer: controller.nextPrayer,
            city: controller.city,
            isLoadingLocation: controller.isLoadingLocation,
            message: controller.message,
          );
        },
        builder: (context, snapshot, _) {
          final prayerTimes = snapshot.prayerTimes;

          if (prayerTimes == null) {
            return _LoadingView(
              localizations: localizations,
              message: snapshot.message,
              isRetrying: _isRetrying,
              onRetry: _retryInitialization,
            );
          }

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

                      final contentWidth =
                          width >= 900 ? 820.0 : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentWidth,
                          ),
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              10,
                              horizontalPadding,
                              30,
                            ),
                            children: [
                              _TopBar(
                                localizations: localizations,
                                isDark: widget.isDark,
                                city: snapshot.city,
                                date: _formatDate(
                                  context,
                                  _currentDate,
                                ),
                                onLanguageToggle:
                                    widget.onLanguageToggle,
                                onThemeToggle: widget.onThemeToggle,
                              ),
                              const SizedBox(height: 23),
                              PrayerHeroCard(
                                controller:
                                    context.read<PrayerController>(),
                                isArabic: localizations.isArabic,
                                prayerName: _prayerName,
                                formatTime: _formatTime,
                              ),
                              const SizedBox(height: 30),
                              _SectionTitle(
                                title: _t('quick_access'),
                                subtitle: _t('daily_essentials'),
                              ),
                              const SizedBox(height: 14),
                              QuickActions(
                                isArabic: localizations.isArabic,
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
                                isArabic: localizations.isArabic,
                                prayerName: _prayerName,
                                formatTime: _formatTime,
                              ),
                              const SizedBox(height: 18),
                              _LocationButton(
                                localizations: localizations,
                                isLoading: snapshot.isLoadingLocation,
                                onPressed: _updateLocation,
                              ),
                              if (snapshot.message != null) ...[
                                const SizedBox(height: 12),
                                _MessageCard(
                                  message: snapshot.message!,
                                ),
                              ],
                              const SizedBox(height: 24),
                              _Footer(
                                localizations: localizations,
                              ),
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

/// Immutable projection of the controller state used by the home page.
///
/// Countdown clock ticks are deliberately excluded. They are consumed
/// directly by the hero card and must not rebuild the complete dashboard.
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
  int get hashCode {
    return Object.hash(
      identityHashCode(prayerTimes),
      nextPrayer,
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
    required this.localizations,
    required this.isDark,
    required this.city,
    required this.date,
    required this.onLanguageToggle,
    required this.onThemeToggle,
  });

  final MuminLocalizations localizations;
  final bool isDark;
  final String city;
  final String date;
  final VoidCallback onLanguageToggle;
  final VoidCallback onThemeToggle;

  String get _languageCode =>
      localizations.languageCode.toUpperCase();

  String get _languageTooltip {
    switch (localizations.languageCode) {
      case 'ar':
        return 'تغيير اللغة';
      case 'fr':
        return 'Changer de langue';
      default:
        return 'Change language';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return Row(
      children: [
        Semantics(
          image: true,
          label: localizations.appName,
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
                localizations.appName,
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
              ? localizations.lightMode
              : localizations.darkMode,
          onPressed: onThemeToggle,
          icon: Icon(
            isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: AppColors.gold,
          ),
        ),
        Semantics(
          button: true,
          label: _languageTooltip,
          value: localizations.languageNativeName,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onLanguageToggle,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 54,
                  minHeight: 42,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _languageCode,
                      style: const TextStyle(
                        color: AppColors.emeraldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 17,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
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
    required this.localizations,
    required this.isLoading,
    required this.onPressed,
  });

  final MuminLocalizations localizations;
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
              ? localizations.updatingLocation
              : localizations.updateLocation,
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
    required this.localizations,
  });

  final MuminLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final tagline = localizations.letPrayerIlluminateYourDay;

    return Semantics(
      label: '${localizations.appName}, $tagline',
      child: Column(
        children: [
          const Icon(
            Icons.mosque_rounded,
            color: AppColors.gold,
            size: 23,
          ),
          const SizedBox(height: 8),
          Text(
            tagline,
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
    required this.localizations,
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final MuminLocalizations localizations;
  final String? message;
  final bool isRetrying;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final errorMessage = message?.trim() ?? '';
    final hasError = errorMessage.isNotEmpty;

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
                        ? localizations.prayerTimesUnavailable
                        : localizations.loadingPrayerTimes,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
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
                              ? localizations.retrying
                              : localizations.retry,
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
