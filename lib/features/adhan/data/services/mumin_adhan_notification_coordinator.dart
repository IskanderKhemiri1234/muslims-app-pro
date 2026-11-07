import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/localization/mumin_language_controller.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import 'mumin_adhan_notification_service.dart';
import 'mumin_prayer_countdown_notification_service.dart';

/// Coordinates prayer alerts and the persistent next-prayer countdown.
///
/// The countdown is synchronized only after the user explicitly enables it.
/// Android maintains the visible countdown independently of Flutter.
class MuminAdhanNotificationCoordinator with WidgetsBindingObserver {
  MuminAdhanNotificationCoordinator({
    required PrayerController prayerController,
    required MuminAdhanNotificationService notificationService,
    required MuminLanguageController languageController,
    MuminPrayerCountdownNotificationService? countdownNotificationService,
  })  : _prayerController = prayerController,
        _notificationService = notificationService,
        _languageController = languageController,
        _countdownNotificationService =
            countdownNotificationService ??
                MuminPrayerCountdownNotificationService() {
    _lastFingerprint = _buildFingerprint();

    _prayerController.addListener(_onPrayerControllerChanged);
    _languageController.addListener(_onLanguageChanged);

    WidgetsBinding.instance.addObserver(this);

    unawaited(refresh(force: true));
  }

  static const String exactPreferenceKey =
      'mumin_adhan_exact_preference';

  /// Stored only after the user explicitly accepts countdown activation.
  static const String countdownEnabledPreferenceKey =
      'mumin_prayer_countdown_enabled_v1';

  final PrayerController _prayerController;
  final MuminAdhanNotificationService _notificationService;
  final MuminLanguageController _languageController;
  final MuminPrayerCountdownNotificationService
      _countdownNotificationService;

  bool _disposed = false;
  bool _refreshing = false;
  bool _refreshRequested = false;
  bool _forceRefreshRequested = false;

  String? _lastFingerprint;
  String? _lastSuccessfulScheduleSignature;

  String _buildFingerprint() {
    final timezone = _prayerController.timezoneLocation;
    final localNow =
        timezone == null ? null : tz.TZDateTime.now(timezone);

    final localDate = localNow == null
        ? 'unknown-date'
        : '${localNow.year}-${localNow.month}-${localNow.day}';

    return <Object?>[
      _prayerController.isInitialized,
      _prayerController.hasUsableSchedule,
      _prayerController.latitude.toStringAsFixed(5),
      _prayerController.longitude.toStringAsFixed(5),
      _prayerController.timezoneId,
      timezone?.name,
      _prayerController.method.name,
      _prayerController.madhab.name,
      localDate,
      _languageController.languageCode,
    ].join('|');
  }

  void _onPrayerControllerChanged() {
    if (_disposed) return;

    final fingerprint = _buildFingerprint();

    if (fingerprint == _lastFingerprint) return;

    _lastFingerprint = fingerprint;
    unawaited(refresh());
  }

  void _onLanguageChanged() {
    if (_disposed) return;

    _lastFingerprint = _buildFingerprint();
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      _lastFingerprint = _buildFingerprint();
      unawaited(refresh(force: true));
    }
  }

  /// Serializes refresh operations and coalesces repeated requests.
  Future<void> refresh({bool force = false}) async {
    if (_disposed) return;

    _refreshRequested = true;
    _forceRefreshRequested =
        _forceRefreshRequested || force;

    if (_refreshing) return;

    _refreshing = true;

    try {
      while (_refreshRequested && !_disposed) {
        _refreshRequested = false;

        final forceCurrent = _forceRefreshRequested;
        _forceRefreshRequested = false;

        await _performRefresh(force: forceCurrent);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: notification coordinator failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _performRefresh({required bool force}) async {
    if (_disposed) return;

    if (!_prayerController.isInitialized ||
        !_prayerController.hasUsableSchedule ||
        _prayerController.timezoneLocation == null) {
      return;
    }

    final enabledPrayers =
        await _notificationService.getEnabledPrayers();

    if (_disposed) return;

    final preferences = await SharedPreferences.getInstance();

    if (_disposed) return;

    final preferExact =
        preferences.getBool(exactPreferenceKey) ?? false;

    final countdownEnabled =
        preferences.getBool(countdownEnabledPreferenceKey) ?? false;

    final signature = <Object?>[
      _buildFingerprint(),
      enabledPrayers.map((prayer) => prayer.name).toList()..sort(),
      preferExact,
      countdownEnabled,
    ].join('|');

    if (!force &&
        signature == _lastSuccessfulScheduleSignature) {
      return;
    }

    final languageCode = _languageController.languageCode;

    // Preserve the existing individual prayer notification schedule.
    await _notificationService.reschedule(
      controller: _prayerController,
      prayerName: (prayer) => _resolvePrayerName(
        prayer,
        languageCode,
      ),
      notificationBody: _notificationBody(languageCode),
      preferExact: preferExact,
    );

    if (_disposed) return;

    final notificationsEnabled =
        await _notificationService.areNotificationsEnabled();

    if (_disposed) return;

    // The persistent countdown requires BOTH explicit app consent
    // and notification permission granted by Android.
    if (countdownEnabled && notificationsEnabled) {
      await _countdownNotificationService.synchronize(
        controller: _prayerController,
        prayerName: (prayer) => _resolvePrayerName(
          prayer,
          languageCode,
        ),
        notificationTitle:
            _countdownNotificationTitle(),
        notificationDescription:
            _countdownNotificationDescription(),
      );
    } else {
      await _countdownNotificationService.cancel();
    }

    if (_disposed) return;

    _lastSuccessfulScheduleSignature = signature;
  }

  String _resolvePrayerName(
    Prayer prayer,
    String languageCode,
  ) {
    final translated =
        _languageController.prayerName(prayer.name).trim();

    if (translated.isNotEmpty) return translated;

    switch (languageCode) {
      case 'en':
        return _englishPrayerName(prayer);
      case 'fr':
        return _frenchPrayerName(prayer);
      default:
        return _arabicPrayerName(prayer);
    }
  }

  String _notificationBody(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'It is now time to pray.';
      case 'fr':
        return 'C’est maintenant l’heure de la prière.';
      default:
        return 'حان الآن وقت الصلاة.';
    }
  }

  /// Uses the central localization engine for the countdown title.
  String _countdownNotificationTitle() {
    return _languageController.text('next_prayer');
  }

  /// Uses the central localization engine for the countdown description.
  String _countdownNotificationDescription() {
    return _languageController.text('time_remaining');
  }

  String _arabicPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return prayer.name;
    }
  }

  String _englishPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }

  String _frenchPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dohr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Icha';
      default:
        return prayer.name;
    }
  }

  Future<void> cancelAll() async {
    if (_disposed) return;

    await _notificationService.cancelPreviouslyScheduled();
    await _countdownNotificationService.cancel();

    _lastSuccessfulScheduleSignature = null;
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    _prayerController.removeListener(_onPrayerControllerChanged);
    _languageController.removeListener(_onLanguageChanged);

    WidgetsBinding.instance.removeObserver(this);
  }
}
