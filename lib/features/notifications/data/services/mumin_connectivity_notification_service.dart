
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../../../core/localization/mumin_language_controller.dart';

/// Monitors internet availability while the application is active.
///
/// Connectivity type alone is not treated as proof of internet access.
/// A lightweight HTTPS request verifies actual reachability.
///
/// This service does not create or modify the persistent prayer countdown.
class MuminConnectivityNotificationService with WidgetsBindingObserver {
  MuminConnectivityNotificationService({
    required MuminLanguageController languageController,
    Connectivity? connectivity,
    FlutterLocalNotificationsPlugin? notifications,
    http.Client? httpClient,
  })  : _languageController = languageController,
        _connectivity = connectivity ?? Connectivity(),
        _notifications =
            notifications ?? FlutterLocalNotificationsPlugin(),
        _httpClient = httpClient ?? http.Client() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  static const int _notificationId = 73105;

  static const String _channelId = 'mumin_connectivity_events';
  static const String _channelName = 'Mumin Pro Connectivity';

  static const Duration _debounceDuration =
      Duration(milliseconds: 1200);

  static const Duration _requestTimeout =
      Duration(seconds: 6);

  final MuminLanguageController _languageController;
  final Connectivity _connectivity;
  final FlutterLocalNotificationsPlugin _notifications;
  final http.Client _httpClient;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounceTimer;

  bool _initialized = false;
  bool _disposed = false;
  bool _checking = false;

  bool? _lastOnline;

  Future<void> _initialize() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
      );

      await _notifications.initialize(settings: settings);

      if (_disposed) return;

      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description:
              'Temporary notifications when internet connectivity changes.',
          importance: Importance.defaultImportance,
        ),
      );

      if (_disposed) return;

      _initialized = true;

      _subscription = _connectivity.onConnectivityChanged.listen(
        (_) => _scheduleCheck(),
        onError: (Object error, StackTrace stackTrace) {
          debugPrint(
            'Mumin Pro: connectivity stream failed: $error',
          );
        },
      );

      // Establish the initial state silently. Opening the app while
      // offline must not generate a misleading first-time alert.
      await _checkAndUpdateState(notifyTransition: false);
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: connectivity monitor initialization failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _scheduleCheck() {
    if (_disposed || !_initialized) return;

    _debounceTimer?.cancel();

    _debounceTimer = Timer(
      _debounceDuration,
      () {
        unawaited(
          _checkAndUpdateState(notifyTransition: true),
        );
      },
    );
  }

  Future<void> _checkAndUpdateState({
    required bool notifyTransition,
  }) async {
    if (_disposed || !_initialized || _checking) return;

    _checking = true;

    try {
      final results = await _connectivity.checkConnectivity();

      if (_disposed) return;

      final hasNetworkInterface = results.any(
        (result) => result != ConnectivityResult.none,
      );

      final online = hasNetworkInterface &&
          await _hasWorkingInternet();

      if (_disposed) return;

      final previous = _lastOnline;
      _lastOnline = online;

      if (!notifyTransition || previous == null) {
        return;
      }

      if (previous == online) {
        return;
      }

      await _showConnectivityNotification(online);
    } catch (error, stackTrace) {
      debugPrint(
        'Mumin Pro: internet availability check failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _hasWorkingInternet() async {
    try {
      final response = await _httpClient
          .get(
            Uri.https(
              'connectivitycheck.gstatic.com',
              '/generate_204',
            ),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showConnectivityNotification(
    bool online,
  ) async {
    if (_disposed) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final permitted = await android?.areNotificationsEnabled() ?? false;

    if (_disposed || !permitted) return;

    final language = _languageController.languageCode;

    final title = online
        ? _languageController.textOr(
            'prayer_times_ready',
            language == 'fr'
                ? 'Connexion Internet rétablie'
                : language == 'en'
                    ? 'Internet connection restored'
                    : 'تم استعادة الاتصال بالإنترنت',
          )
        : _languageController.textOr(
            'offline_mode',
            language == 'fr'
                ? 'Connexion Internet interrompue'
                : language == 'en'
                    ? 'Internet connection lost'
                    : 'انقطع الاتصال بالإنترنت',
          );

    final body = online
        ? _languageController.textOr(
            'prayer_schedule_refreshed',
            language == 'fr'
                ? 'Votre appareil est de nouveau connecté.'
                : language == 'en'
                    ? 'Your device is connected again.'
                    : 'عاد جهازك للاتصال بالإنترنت.',
          )
        : _languageController.textOr(
            'offline_mode_description',
            language == 'fr'
                ? 'Certaines fonctions en ligne peuvent être indisponibles.'
                : language == 'en'
                    ? 'Some online features may be unavailable.'
                    : 'قد لا تتوفر بعض الخدمات التي تحتاج إلى الإنترنت.',
          );

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Temporary internet connectivity status notifications.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        category: AndroidNotificationCategory.status,
        playSound: false,
        enableVibration: false,
        ongoing: false,
        autoCancel: true,
        onlyAlertOnce: true,
      ),
    );

    await _notifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: online
          ? 'mumin_connectivity:online'
          : 'mumin_connectivity:offline',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_initialized) return;

    if (state == AppLifecycleState.resumed) {
      // Android may suspend connectivity callbacks while the app
      // is in the background. Recheck when the user returns.
      _scheduleCheck();
    }
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    WidgetsBinding.instance.removeObserver(this);

    _debounceTimer?.cancel();

    unawaited(_subscription?.cancel());

    _httpClient.close();
  }
}
