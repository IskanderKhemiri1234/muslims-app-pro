import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/localization/mumin_language_controller.dart';

/// Sends a temporary notification after the prayer location changes.
///
/// This service does not request location permission, track movement,
/// or expose geographic coordinates in notifications.
class MuminLocationChangeNotificationService {
  MuminLocationChangeNotificationService({
    required MuminLanguageController languageController,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _languageController = languageController,
        _notifications =
            notifications ?? FlutterLocalNotificationsPlugin() {
    _initialization = _initialize();
  }

  static const int notificationId = 73106;

  static const String channelId = 'mumin_location_events';
  static const String channelName = 'Mumin Pro Location';

  final MuminLanguageController _languageController;
  final FlutterLocalNotificationsPlugin _notifications;

  late final Future<void> _initialization;

  bool _disposed = false;

  Future<void> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(settings: settings);

    if (_disposed) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description:
            'Notifications when the prayer calculation location changes.',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Displays a notification after a confirmed location update.
  ///
  /// The notification contains no coordinates or precise address.
  Future<void> showLocationChanged() async {
    if (_disposed) return;

    try {
      await _initialization;

      if (_disposed) return;

      final android = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final permitted =
          await android?.areNotificationsEnabled() ?? false;

      if (_disposed || !permitted) return;

      final language = _languageController.languageCode;

      final title = _languageController.textOr(
        'location_updated_title',
        language == 'fr'
            ? 'Emplacement mis à jour'
            : language == 'en'
                ? 'Location updated'
                : 'تم تحديث الموقع',
      );

      final body = _languageController.textOr(
        'location_updated_body',
        language == 'fr'
            ? 'Les horaires de prière ont été recalculés pour votre nouvel emplacement.'
            : language == 'en'
                ? 'Prayer times have been recalculated for your new location.'
                : 'تمت إعادة حساب مواقيت الصلاة حسب موقعك الجديد.',
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription:
              'Prayer location update notifications.',
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
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'mumin_location:updated',
      );
    } catch (error) {
      // A location notification failure must not interrupt
      // prayer calculations or location updates.
    }
  }

  void dispose() {
    _disposed = true;
  }
}
