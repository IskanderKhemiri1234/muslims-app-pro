
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/mumin_language_registry.dart';
import '../../../../core/localization/mumin_localizations.dart';
import '../../../../core/localization/mumin_locale_formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import '../../../adhan/presentation/pages/adhan_page.dart';
import '../../../adhkar/presentation/pages/adhkar_page.dart';
import '../../../tasbih/presentation/pages/tasbih_page.dart';
import '../../../prayer_times/domain/services/global_prayer_calculation_service.dart';
import '../../../qibla/presentation/pages/qibla_page_entry.dart';
import '../../../nearby_mosques/presentation/pages/nearby_mosques_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../widgets/glass_container.dart';
import '../widgets/prayer_hero_card.dart';
import '../widgets/prayer_schedule_section.dart';
import '../widgets/quick_actions.dart';
import '../../../hijri_calendar/presentation/pages/hijri_calendar_page.dart';

/// Main dashboard of Mumin Pro.
///
/// Language metadata, locale normalization and text direction
/// are controlled exclusively by the centralized language architecture.
class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({
    super.key,
    required this.onSettingsTap,
    required this.isDark,
    required this.onThemeToggle,
  });

  final VoidCallback onSettingsTap;
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
    final languageCode =
        MuminLanguageRegistry.normalizeLanguageCode(
      locale.languageCode,
    );

    return MuminLocalizations.fromCode(languageCode);
  }

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
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _cancelMidnightRefresh();
        break;
    }
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

  void _cancelMidnightRefresh() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
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

    final delay =
        nextMidnight.difference(now) + const Duration(seconds: 1);

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
        return _localizations.text('unavailable');
    }
  }

  String _formatTime(DateTime time) {
    return MuminLocaleFormatters.of(context).formatTime(
      time,
      alwaysUse24HourFormat: true,
    );
  }

  Future<void> _retryInitialization() async {
    if (_isRetrying || !mounted) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await context.read<PrayerController>().retryInitialization();
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: initialization retry failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(_localizations.prayerTimesUnavailable);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
  
    Future<void> _refreshDashboard() async {
    if (!mounted) return;

    try {
      await context.read<PrayerController>().refreshPrayerData();

      if (!mounted) return;

      final message = context.read<PrayerController>().message;
      if (message != null && message.trim().isNotEmpty) {
        _showMessage(message);
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: dashboard refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(_localizations.prayerTimesUnavailable);
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
        _showMessage(_localizations.locationPermissionRequired);
      }
    }
  }

    void _openPage(Widget page) {
    if (!mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => page,
      ),
    );
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'qibla':
        _openPage(const QiblaPageEntry());
        break;

      case 'quran':
        _openPage(const QuranPage());
        break;

      case 'mosques':
        _openPage(
          NearbyMosquesPage(
            languageCode: _localizations.languageCode,
          ),
        );
        break;

      case 'adhan':
        _openPage(const AdhanPage());
        break;

      case 'adhkar':
        _openPage(const AdhkarPage());
        break;

      case 'tasbih':
        _openPage(const TasbihPage());
        break;

      default:
        _showMessage(_localizations.comingSoon);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        selector: (context, controller) {
          return _HomeSnapshot(
            schedule: controller.globalSchedule,
            nextPrayer: controller.nextPrayer,
            city: controller.city,
            isLoadingLocation: controller.isLoadingLocation,
            message: controller.message,
          );
        },
        builder: (context, snapshot, child) {
          if (snapshot.schedule == null) {
            return _HomeLoadingView(
              localizations: localizations,
              message: snapshot.message,
              isRetrying: _isRetrying,
              onRetry: _retryInitialization,
            );
          }

          return _buildDashboard(
            context,
            snapshot,
            localizations,
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    _HomeSnapshot snapshot,
    MuminLocalizations localizations,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final horizontalPadding = width >= 900
                    ? 36.0
                    : width >= 600
                        ? 26.0
                        : 13.0;
                final maximumContentWidth =
                    width >= 900 ? 820.0 : 680.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maximumContentWidth,
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshDashboard,
                      color: AppColors.gold,
                      backgroundColor: theme.colorScheme.surface,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          34,
                        ),
                        children: [
                          _HomeHeader(
                            localizations: localizations,
                            city: snapshot.city,
                            isDark: widget.isDark,
                            isLoadingLocation:
                                snapshot.isLoadingLocation,
                            onLocationUpdate: _updateLocation,
                            onSettingsTap: widget.onSettingsTap,
                            onThemeToggle: widget.onThemeToggle,
                          ),
                          const SizedBox(height: 10),
                          RepaintBoundary(
                            child: SizedBox(
                              height: 216,
                              child: PrayerHeroCard(
                              controller:
                                  context.read<PrayerController>(),
                              prayerName: _prayerName,
                              formatTime: _formatTime,
                              date: _currentDate,
                              onHijriTap: () {
                                _openPage(
                                  HijriCalendarPage(
                                    localizations: localizations,
                                  ),
                                );
                              },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: QuickActions(
                              onAction: _handleQuickAction,
                            ),
                          ),
        
                          const SizedBox(height: 15),
                          RepaintBoundary(
                            child: _MuminQuranShowcase(
                              title: localizations.appName,
                              subtitle: localizations.quran,
                              actionLabel: localizations.quran,
                              onTap: () => _handleQuickAction('quran'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          RepaintBoundary(
  child: PrayerScheduleSection(
    schedule: snapshot.schedule!,
    nextPrayer: snapshot.nextPrayer,
    prayerName: _prayerName,
    formatTime: _formatTime,
  ),
),
                        
                          if (snapshot.message != null &&
                              snapshot.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 13),
                            _HomeStatusMessage(
                              message: snapshot.message!,
                            ),
                          ],
                          const SizedBox(height: 28),
                          _HomeFooter(localizations: localizations),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MuminQuranShowcase extends StatelessWidget {
  const _MuminQuranShowcase({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 166,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                Color(0xFF0B4A39),
                Color(0xFF063126),
                Color(0xFF071F1A),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00845F).withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -12,
                top: -24,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 174,
                  color: AppColors.goldLight.withValues(alpha: 0.075),
                ),
              ),
              PositionedDirectional(
                end: 18,
                bottom: -18,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 104,
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  18,
                  15,
                  16,
                  15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF15966D),
                                  Color(0xFF075B46),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.goldLight.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: AppColors.goldLight,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.gold.withValues(alpha: 0.28),
                                  AppColors.gold.withValues(alpha: 0.015),
                                ],
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: -0.12,
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 82,
                              color: AppColors.goldLight,
                              shadows: [
                                Shadow(
                                  color: AppColors.gold.withValues(
                                    alpha: 0.72,
                                  ),
                                  blurRadius: 22,
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 9,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            top: 7,
                            right: 13,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: AppColors.goldLight,
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
        ),
      ),
    );
  }
}

/// Immutable projection of the prayer controller state.
///
/// Clock ticks are intentionally excluded to prevent unnecessary
/// rebuilds of the complete dashboard.

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.schedule,
    required this.nextPrayer,
    required this.city,
    required this.isLoadingLocation,
    required this.message,
  });

  final GlobalPrayerSchedule? schedule;
  final Prayer? nextPrayer;
  final String city;
  final bool isLoadingLocation;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is _HomeSnapshot &&
        identical(schedule, other.schedule) &&
        nextPrayer == other.nextPrayer &&
        city == other.city &&
        isLoadingLocation == other.isLoadingLocation &&
        message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(
      identityHashCode(schedule),
      nextPrayer,
      city,
      isLoadingLocation,
      message,
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: isDark
                  ? const [
                      Color(0xFF071C17),
                      Color(0xFF09271F),
                      Color(0xFF071C17),
                    ]
                  : const [
                      Color(0xFFF4F2E9),
                      Color(0xFFEAF1EB),
                      Color(0xFFF7F4EC),
                    ],
            ),
          ),
          child: const Stack(
            children: [
              PositionedDirectional(
                top: -150,
                end: -120,
                child: _AmbientGlow(
                  size: 330,
                  color: Color(0x2600A878),
                ),
              ),
              PositionedDirectional(
                top: 390,
                start: -180,
                child: _AmbientGlow(
                  size: 310,
                  color: Color(0x16D8B66A),
                ),
              ),
              PositionedDirectional(
                bottom: -210,
                end: -150,
                child: _AmbientGlow(
                  size: 360,
                  color: Color(0x12007555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.localizations,
    required this.city,
    required this.isDark,
    required this.isLoadingLocation,
    required this.onLocationUpdate,
    required this.onSettingsTap,
    required this.onThemeToggle,
  });

  final MuminLocalizations localizations;
  final String city;
  final bool isDark;
  final bool isLoadingLocation;
  final VoidCallback onLocationUpdate;
  final VoidCallback onSettingsTap;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Tooltip(
            message: isLoadingLocation
                ? localizations.updatingLocation
                : localizations.updateLocation,
            child: InkWell(
              onTap: isLoadingLocation ? null : onLocationUpdate,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 32,
                height: 36,
                child: Center(
                  child: isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.gold,
                          size: 19,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            tooltip: isDark
                ? localizations.lightMode
                : localizations.darkMode,
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            onPressed: onThemeToggle,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            tooltip: localizations.text('settings'),
            icon: Icons.settings_rounded,
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HomeStatusMessage extends StatelessWidget {
  const _HomeStatusMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      radius: 16,
      enableBlur: false,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter({
    required this.localizations,
  });

  final MuminLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      label: '${localizations.appName}, '
          '${localizations.letPrayerIlluminateYourDay}',
      child: Column(
        children: [
          Container(
            width: 38,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Icon(
            Icons.mosque_rounded,
            color: AppColors.gold,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.letPrayerIlluminateYourDay,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            localizations.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView({
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
    final theme = Theme.of(context);
    final hasError =
        message != null && message!.trim().isNotEmpty;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GlassContainer(
                    radius: 28,
                    padding: const EdgeInsets.all(27),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.emerald,
                                AppColors.deepGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(
                              color: AppColors.gold
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            color: AppColors.goldLight,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (!hasError)
                          SizedBox(
                            width: 27,
                            height: 27,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        else
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 34,
                            color: AppColors.gold,
                          ),
                        const SizedBox(height: 20),
                        Text(
                          hasError
                              ? localizations.prayerTimesUnavailable
                              : localizations.loadingPrayerTimes,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (hasError) ...[
                          const SizedBox(height: 12),
                          Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  isRetrying ? null : onRetry,
                              icon: isRetrying
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                    ),
                              label: Text(
                                isRetrying
                                    ? localizations.retrying
                                    : localizations.retry,
                              ),
                            ),
                          ),
                        ],
                        if (!hasError && !reduceMotion) ...[
                          const SizedBox(height: 14),
                          Text(
                            localizations.appName,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
