
import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _placeNameLanguageCode;
  final ScrollController _dashboardScrollController = ScrollController();
  final GlobalKey _prayerScheduleKey = GlobalKey();

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    final languageCode = _localizations.languageCode;
    if (_placeNameLanguageCode == languageCode) return;

    _placeNameLanguageCode = languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        context.read<PrayerController>().refreshPlaceName(
          languageCode: languageCode,
        ),
      );
    });
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

    final startedAt = DateTime.now();

    try {
      final controller = context.read<PrayerController>();
      await controller.refreshPrayerData();

      if (!mounted) return;

      setState(() {
        _currentDate = DateTime.now();
      });

      final message = controller.message;
      if (message != null && message.trim().isNotEmpty) {
        _showMessage(message);
      }
    } catch (error, stackTrace) {
      debugPrint('Mumin Pro: dashboard refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage(_localizations.prayerTimesUnavailable);
      }
    } finally {
      // Keep the pull-to-refresh transition perceptible even when the
      // local prayer schedule recalculates almost instantly.
      final elapsed = DateTime.now().difference(startedAt);
      const minimumIndicatorTime = Duration(milliseconds: 650);
      if (elapsed < minimumIndicatorTime) {
        await Future<void>.delayed(minimumIndicatorTime - elapsed);
      }
    }
  }

  Future<void> _updateLocation() async {
    if (!mounted) return;

    try {
      await context.read<PrayerController>().updateLocation(
        languageCode: _localizations.languageCode,
      );
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
      CupertinoPageRoute<void>(
        builder: (routeContext) => page,
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        if (_dashboardScrollController.hasClients) {
          _dashboardScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
          );
        }
        break;
      case 1:
        final targetContext = _prayerScheduleKey.currentContext;
        if (targetContext != null) {
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeInOutCubic,
            alignment: 0.08,
          );
        }
        break;
      case 2:
        _openPage(
          NearbyMosquesPage(
            languageCode: _localizations.languageCode,
          ),
        );
        break;
      case 3:
        _openPage(const QuranPage());
        break;
      case 4:
        widget.onSettingsTap();
        break;
    }
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

      case 'calendar':
        _openPage(
          HijriCalendarPage(
            localizations: _localizations,
          ),
        );
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
    _dashboardScrollController.dispose();
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
            placeName: controller.placeName,
            region: controller.region,
            country: controller.country,
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
      bottomNavigationBar: _HomeBottomNavigation(
        localizations: localizations,
        onTap: _handleBottomNavigation,
      ),
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
                      triggerMode: RefreshIndicatorTriggerMode.onEdge,
                      displacement: 64,
                      edgeOffset: 0,
                      strokeWidth: 2.6,
                      color: AppColors.gold,
                      backgroundColor: theme.colorScheme.surface,
                      notificationPredicate: (notification) =>
                          notification.depth == 0,
                      child: ListView(
                        controller: _dashboardScrollController,
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
                            placeName: snapshot.placeName,
                            region: snapshot.region,
                            country: snapshot.country,
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
                              height: 232,
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
                              key: _prayerScheduleKey,
                              schedule: snapshot.schedule!,
                              nextPrayer: snapshot.nextPrayer,
                              prayerName: _prayerName,
                              formatTime: _formatTime,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _DailyEssentialsSection(
                            title: localizations.dailyEssentials,
                            localizations: localizations,
                            onAction: _handleQuickAction,
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

class _QuranShowcasePainter extends CustomPainter {
  const _QuranShowcasePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final softGold = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final book = Paint()..color = const Color(0xFF063A2D);
    final page = Paint()..color = const Color(0xFFF0D99E);
    final stand = Paint()..color = const Color(0xFF8D642D);

    final center = Offset(size.width * 0.79, size.height * 0.52);
    canvas.drawCircle(center, size.height * 0.48, softGold);
    final arch = Path()
      ..moveTo(size.width * 0.55, size.height)
      ..lineTo(size.width * 0.55, size.height * 0.38)
      ..cubicTo(size.width * 0.56, size.height * 0.08,
          size.width * 0.95, size.height * 0.08,
          size.width * 0.98, size.height * 0.38)
      ..lineTo(size.width * 0.98, size.height)
      ..close();
    canvas.drawPath(arch, gold);

    // Open Qur'an with a gold-edged cover and luminous pages.
    final leftPage = Path()
      ..moveTo(size.width * 0.67, size.height * 0.47)
      ..quadraticBezierTo(size.width * 0.77, size.height * 0.39,
          size.width * 0.82, size.height * 0.51)
      ..lineTo(size.width * 0.82, size.height * 0.77)
      ..quadraticBezierTo(size.width * 0.74, size.height * 0.68,
          size.width * 0.67, size.height * 0.72)
      ..close();
    final rightPage = Path()
      ..moveTo(size.width * 0.82, size.height * 0.51)
      ..quadraticBezierTo(size.width * 0.89, size.height * 0.39,
          size.width * 0.96, size.height * 0.47)
      ..lineTo(size.width * 0.96, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.68,
          size.width * 0.82, size.height * 0.77)
      ..close();
    canvas.drawPath(leftPage, page);
    canvas.drawPath(rightPage, page);
    canvas.drawPath(leftPage, gold);
    canvas.drawPath(rightPage, gold);
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.53 + i * 0.045);
      canvas.drawLine(
        Offset(size.width * 0.70, y),
        Offset(size.width * 0.79, y - 1),
        Paint()
          ..color = const Color(0xFF9B793C).withValues(alpha: 0.58)
          ..strokeWidth = 0.7,
      );
      canvas.drawLine(
        Offset(size.width * 0.85, y - 1),
        Offset(size.width * 0.93, y),
        Paint()
          ..color = const Color(0xFF9B793C).withValues(alpha: 0.58)
          ..strokeWidth = 0.7,
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.51),
      Offset(size.width * 0.82, size.height * 0.77),
      gold,
    );

    // Wooden rehal silhouette beneath the book.
    final rehal = Path()
      ..moveTo(size.width * 0.68, size.height * 0.80)
      ..lineTo(size.width * 0.96, size.height * 0.80)
      ..lineTo(size.width * 0.89, size.height * 0.91)
      ..lineTo(size.width * 0.75, size.height * 0.91)
      ..close();
    canvas.drawPath(rehal, stand);
    canvas.drawPath(rehal, gold);
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.91),
      Offset(size.width * 0.88, size.height * 0.80),
      Paint()
        ..color = const Color(0xFFE4BC6D)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(size.width * 0.89, size.height * 0.91),
      Offset(size.width * 0.77, size.height * 0.80),
      Paint()
        ..color = const Color(0xFFE4BC6D)
        ..strokeWidth = 3,
    );

    for (var i = 0; i < 11; i++) {
      final x = size.width * (0.58 + i * 0.038);
      final y = size.height * (0.18 + (i % 4) * 0.12);
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.5 : 0.8, gold);
    }
  }

  @override
  bool shouldRepaint(covariant _QuranShowcasePainter oldDelegate) => false;
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
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          height: 188,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
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
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _QuranShowcasePainter(),
                  ),
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

/// A second layer of useful, working destinations below the prayer list.
class _DailyEssentialsSection extends StatelessWidget {
  const _DailyEssentialsSection({
    required this.title,
    required this.localizations,
    required this.onAction,
  });

  final String title;
  final MuminLocalizations localizations;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String id, String label, IconData icon, Color color})>[
      (
        id: 'quran',
        label: localizations.quran,
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFD8B66A),
      ),
      (
        id: 'adhkar',
        label: localizations.adhkar,
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFF72C9A5),
      ),
      (
        id: 'tasbih',
        label: localizations.tasbih,
        icon: Icons.fingerprint_rounded,
        color: const Color(0xFFB99BE8),
      ),
      (
        id: 'calendar',
        label: localizations.calendar,
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF8DB8F1),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.gold,
              size: 21,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => onAction(item.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          height: 112,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [
                                item.color.withValues(alpha: 0.13),
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.78,
                                ),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 39,
                                height: 39,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.color.withValues(alpha: 0.13),
                                  border: Border.all(
                                    color: item.color.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.color,
                                  size: 21,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Directionality.of(context) ==
                                            TextDirection.rtl
                                        ? Icons.arrow_back_ios_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: AppColors.gold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
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
    required this.placeName,
    required this.region,
    required this.country,
    required this.isLoadingLocation,
    required this.message,
  });

  final GlobalPrayerSchedule? schedule;
  final Prayer? nextPrayer;
  final String city;
  final String placeName;
  final String region;
  final String country;
  final bool isLoadingLocation;
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is _HomeSnapshot &&
        identical(schedule, other.schedule) &&
        nextPrayer == other.nextPrayer &&
        city == other.city &&
        placeName == other.placeName &&
        region == other.region &&
        country == other.country &&
        isLoadingLocation == other.isLoadingLocation &&
        message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(
      identityHashCode(schedule),
      nextPrayer,
      city,
      placeName,
      region,
      country,
      isLoadingLocation,
      message,
    );
  }
}

class _IslamicGeometryPainter extends CustomPainter {
  const _IslamicGeometryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFD8B66A).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    final starPaint = Paint()
      ..color = const Color(0xFFE8CE91).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final spacing = size.width < 500 ? 58.0 : 82.0;
    for (var row = -1; row < (size.height / spacing).ceil() + 1; row++) {
      for (var column = -1;
          column < (size.width / spacing).ceil() + 1;
          column++) {
        final center = Offset(
          column * spacing + (row.isEven ? 0 : spacing / 2),
          row * spacing,
        );
        final radius = spacing * 0.34;
        final diamond = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(diamond, line);
        canvas.drawCircle(center, 1.1, starPaint);
        if ((row + column).abs() % 4 == 0) {
          canvas.drawLine(
            Offset(center.dx - radius * 0.45, center.dy - radius * 0.45),
            Offset(center.dx + radius * 0.45, center.dy + radius * 0.45),
            line,
          );
          canvas.drawLine(
            Offset(center.dx + radius * 0.45, center.dy - radius * 0.45),
            Offset(center.dx - radius * 0.45, center.dy + radius * 0.45),
            line,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicGeometryPainter oldDelegate) => false;
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
              Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicGeometryPainter(),
                ),
              ),
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

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation({
    required this.localizations,
    required this.onTap,
  });

  final MuminLocalizations localizations;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, IconData icon})>[
      (label: localizations.text('home_tab'), icon: Icons.home_rounded),
      (label: localizations.text('prayer_tab'), icon: Icons.mosque_rounded),
      (label: localizations.text('discover_tab'), icon: Icons.explore_rounded),
      (label: localizations.quran, icon: Icons.menu_book_rounded),
      (label: localizations.settings, icon: Icons.person_rounded),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF061C16).withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.34),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00130E).withValues(alpha: 0.42),
            blurRadius: 22,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _HomeBottomNavigationItem(
                    label: items[index].label,
                    icon: items[index].icon,
                    selected: index == 0,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavigationItem extends StatelessWidget {
  const _HomeBottomNavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldLight : Colors.white70;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox.expand(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: selected ? 25 : 23,
                    color: color,
                    shadows: selected
                        ? [
                            Shadow(
                              color: AppColors.gold.withValues(alpha: 0.55),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
    required this.placeName,
    required this.region,
    required this.country,
    required this.isDark,
    required this.isLoadingLocation,
    required this.onLocationUpdate,
    required this.onSettingsTap,
    required this.onThemeToggle,
  });

  final MuminLocalizations localizations;
  final String city;
  final String placeName;
  final String region;
  final String country;
  final bool isDark;
  final bool isLoadingLocation;
  final VoidCallback onLocationUpdate;
  final VoidCallback onSettingsTap;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          _LocationRefreshButton(
            tooltip: isLoadingLocation
                ? localizations.updatingLocation
                : localizations.updateLocation,
            isLoading: isLoadingLocation,
            onPressed: onLocationUpdate,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _LocationNameSwitcher(
              city: city,
              placeName: placeName,
              region: region,
              country: country,
              color: colorScheme.onSurface,
              secondaryColor: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 7),
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

class _LocationRefreshButton extends StatefulWidget {
  const _LocationRefreshButton({
    required this.tooltip,
    required this.isLoading,
    required this.onPressed,
  });

  final String tooltip;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_LocationRefreshButton> createState() =>
      _LocationRefreshButtonState();
}

class _LocationRefreshButtonState extends State<_LocationRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    if (widget.isLoading) _rotationController.repeat();
  }

  @override
  void didUpdateWidget(covariant _LocationRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _rotationController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Tooltip(
      message: widget.tooltip,
      child: Material(
        color: AppColors.emerald.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onPressed();
                },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.48),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.10),
                  blurRadius: 13,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading && !reduceMotion
                ? RotationTransition(
                    turns: _rotationController,
                    child: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.gold,
                      size: 25,
                    ),
                  )
                : Icon(
                    widget.isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.my_location_rounded,
                    color: AppColors.gold,
                    size: 25,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LocationNameSwitcher extends StatefulWidget {
  const _LocationNameSwitcher({
    required this.city,
    required this.placeName,
    required this.region,
    required this.country,
    required this.color,
    required this.secondaryColor,
  });

  final String city;
  final String placeName;
  final String region;
  final String country;
  final Color color;
  final Color secondaryColor;

  @override
  State<_LocationNameSwitcher> createState() =>
      _LocationNameSwitcherState();
}

class _LocationNameSwitcherState extends State<_LocationNameSwitcher> {
  Timer? _cycleTimer;
  bool _showCity = true;

  bool get _hasPlaceName =>
      widget.placeName.trim().isNotEmpty &&
      widget.placeName.trim() != widget.city.trim();

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  @override
  void didUpdateWidget(covariant _LocationNameSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city ||
        oldWidget.placeName != widget.placeName) {
      _showCity = true;
      _startCycle();
    }
  }

  void _startCycle() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        if (!mounted || !_hasPlaceName) return;
        setState(() => _showCity = !_showCity);
      },
    );
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showCity = _showCity || !_hasPlaceName;
    final primary = showCity ? widget.city : widget.placeName;
    final secondary = showCity
        ? <String>[widget.region, widget.country]
            .where((value) => value.trim().isNotEmpty)
            .join(' · ')
        : widget.city;

    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 480),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.22),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey<bool>(showCity),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primary.isEmpty ? widget.city : primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.color,
                fontSize: showCity ? 15.5 : 12.5,
                fontWeight: showCity ? FontWeight.w800 : FontWeight.w700,
                height: 1.05,
              ),
            ),
            if (secondary.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.secondaryColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
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
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: AppColors.gold,
              size: 22,
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
