import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/localization/mumin_language_controller.dart';
import '../../../notifications/data/services/mumin_connectivity_notification_service.dart';
import '../../../notifications/data/services/mumin_location_change_notification_service.dart';
import '../../../prayer_times/presentation/controllers/prayer_controller.dart';
import 'mumin_adhan_notification_service.dart';
import 'mumin_prayer_countdown_notification_service.dart';

/// Coordinates prayer alerts, the persistent countdown,
/// connectivity notifications and confirmed location changes.
class MuminAdhanNotificationCoordinator with WidgetsBindingObserver {
  MuminAdhanNotificationCoordinator({
    required PrayerController prayerController,
    required MuminAdhanNotificationService notificationService,
    required MuminLanguageController languageController,
    MuminPrayerCountdownNotificationService? countdownNotificationService,
    MuminConnectivityNotificationService? connectivityNotificationService,
    MuminLocationChangeNotificationService? locationNotificationService,
  })  : _prayerController = prayerController,
        _notificationService = notificationService,
        _languageController = languageController,
        _countdownNotificationService =
            countdownNotificationService ??
                MuminPrayerCountdownNotificationService() {
    _connectivityNotificationService =
        connectivityNotificationService ??
            MuminConnectivityNotificationService(
              languageController: languageController,
            );

    _locationNotificationService =
        locationNotificationService ??
            MuminLocationChangeNotificationService(
              languageController: languageController,
            );

    _lastFingerprint = _buildFingerprint();

    _prayerController.addListener(_onPrayerControllerChanged);
    _languageController.addListener(_onLanguageChanged);

    WidgetsBinding.instance.addObserver(this);

    unawaited(refresh(force: true));
  }

  static const String exactPreferenceKey =
      'mumin_adhan_exact_preference';

  static const String countdownEnabledPreferenceKey =
      'mumin_prayer_countdown_enabled_v1';

  final PrayerController _prayerController;
  final MuminAdhanNotificationService _notificationService;
  final MuminLanguageController _languageController;

  final MuminPrayerCountdownNotificationService
      _countdownNotificationService;

  late final MuminConnectivityNotificationService
      _connectivityNotificationService;

  late final MuminLocationChangeNotificationService
      _locationNotificationService;

  bool _disposed = false;
  Future<void> _refreshTail = Future<void>.value();

  String? _lastFingerprint;
  String? _lastSuccessfulScheduleSignature;

  String? _lastLocationFingerprint;

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

  String _buildLocationFingerprint() {
    return '${_prayerController.latitude.toStringAsFixed(4)}|'
        '${_prayerController.longitude.toStringAsFixed(4)}';
  }

  /// Establishes the initial location silently.
  ///
  /// Only a subsequent confirmed coordinate change triggers
  /// a temporary location notification.
  void _checkForLocationChange() {
    if (_disposed ||
        !_prayerController.isInitialized ||
        !_prayerController.hasUsableSchedule ||
        _prayerController.timezoneLocation == null) {
      return;
    }

    final current = _buildLocationFingerprint();
    final previous = _lastLocationFingerprint;

    if (previous == null) {
      _lastLocationFingerprint = current;
      return;
    }

    if (previous == current) return;

    _lastLocationFingerprint = current;

    unawaited(
      _locationNotificationService.showLocationChanged(),
    );
  }

  void _onPrayerControllerChanged() {
    if (_disposed) return;

    _checkForLocationChange();

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

  /// Queues every synchronization request.
  ///
  /// A caller that requests error propagation waits for its own queued
  /// synchronization to finish; it can no longer return early merely because
  /// another refresh was already running.
  Future<void> refresh({
    bool force = false,
    bool rethrowErrors = false,
  }) {
    if (_disposed) return Future<void>.value();

    final operation = _refreshTail.then((_) async {
      if (_disposed) return;
      try {
        await _performRefresh(force: force);
      } catch (error) {
        try {
          await _countdownNotificationService.saveDiagnosticFailure(error);
        } catch (diagnosticError) {
          debugPrint(
            'Mumin Pro: could not persist countdown diagnostics: $diagnosticError',
          );
        }
        rethrow;
      }
    });

    _refreshTail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Mumin Pro: notification coordinator failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      },
    );

    if (rethrowErrors) return operation;

    return operation.catchError(
      (Object error, StackTrace stackTrace) {
        debugPrint(
          'Mumin Pro: notification coordinator failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  Future<void> _performRefresh({required bool force}) async {
    if (_disposed) return;

    // The coordinator is created while the application is bootstrapping.
    // Wait for the controller's in-flight initialization instead of failing
    // the first synchronization before prayer times and timezone are ready.
    if (!_prayerController.isInitialized ||
        !_prayerController.hasUsableSchedule ||
        _prayerController.timezoneLocation == null) {
      await _prayerController.retryInitialization();
    }

    if (_disposed) return;

    if (!_prayerController.isInitialized ||
        !_prayerController.hasUsableSchedule ||
        _prayerController.timezoneLocation == null) {
      throw StateError(
        'Prayer schedule initialization completed without a usable schedule; notification synchronization was not sent.',
      );
    }

    final enabledPrayers =
        await _notificationService.getEnabledPrayers();

    if (_disposed) return;

    final preferences = await SharedPreferences.getInstance();

    if (_disposed) return;

    final preferExact =
        preferences.getBool(exactPreferenceKey) ?? false;

    var countdownEnabled =
        preferences.getBool(countdownEnabledPreferenceKey) ?? false;

    final languageCode = _languageController.languageCode;

    final notificationsEnabled =
        await _notificationService.areNotificationsEnabled();

    if (_disposed) return;

    // Default the persistent countdown on once Android notifications are
    // available. A saved false is always respected as an explicit opt-out.
    final hasSavedCountdownChoice =
        preferences.containsKey(countdownEnabledPreferenceKey);

    if (!hasSavedCountdownChoice && notificationsEnabled) {
      countdownEnabled = true;
      await preferences.setBool(
        countdownEnabledPreferenceKey,
        true,
      );
    }

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

    // Synchronize the persistent countdown first so a failure in the
    // separate scheduled-alert pipeline cannot prevent its creation.
    if (countdownEnabled && notificationsEnabled) {
      await _countdownNotificationService.synchronize(
        controller: _prayerController,
        prayerName: (prayer) => _resolvePrayerName(
          prayer,
          languageCode,
        ),
        notificationTitle: _countdownNotificationTitle(),
        notificationDescription:
            _countdownNotificationDescription(),
      );
    } else {
      await _countdownNotificationService.cancel();
    }

    if (_disposed) return;

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

  String _countdownNotificationTitle() {
    return _languageController.text('next_prayer');
  }

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

    _connectivityNotificationService.dispose();
    _locationNotificationService.dispose();
  }
}
